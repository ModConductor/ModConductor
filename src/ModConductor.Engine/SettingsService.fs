namespace ModConductor.Engine

open System
open System.Threading.Tasks
open Grpc.Core
open ModConductor.Protocol.V1
open ModConductor.Settings
open ModConductor.Workspaces

module private SettingsWire =
    let appearance =
        function
        | Appearance.System -> AppearancePreference.System
        | Appearance.Light -> AppearancePreference.Light
        | Appearance.Dark -> AppearancePreference.Dark

    let contrast =
        function
        | Contrast.System -> ContrastPreference.System
        | Contrast.Standard -> ContrastPreference.Standard
        | Contrast.High -> ContrastPreference.High

    let snapshot (value: ModConductor.Settings.SettingsSnapshot) =
        SettingsSnapshot(
            Presentation =
                PresentationSettings(
                    Appearance = appearance value.Presentation.Appearance,
                    TextScale = value.Presentation.TextScale,
                    Contrast = contrast value.Presentation.Contrast
                ),
            InheritsApplication = value.InheritsApplication
        )

    let fault code detail =
        SettingsReply(Fault = SettingsFault(Code = code, Detail = detail))

    let error =
        function
        | SettingsError.InvalidDocument detail -> fault SettingsFaultCode.InvalidDocument detail
        | SettingsError.UnsupportedVersion version ->
            fault
                SettingsFaultCode.UnsupportedVersion
                ("Settings version " + string version + " is not supported.")
        | SettingsError.InvalidValue detail -> fault SettingsFaultCode.InvalidValue detail
        | SettingsError.Unavailable ->
            fault SettingsFaultCode.Unavailable "The settings file is unavailable."

    let decodeAppearance =
        function
        | AppearancePreference.System -> Ok Appearance.System
        | AppearancePreference.Light -> Ok Appearance.Light
        | AppearancePreference.Dark -> Ok Appearance.Dark
        | _ -> Error "Select a supported appearance."

    let decodeContrast =
        function
        | ContrastPreference.System -> Ok Contrast.System
        | ContrastPreference.Standard -> Ok Contrast.Standard
        | ContrastPreference.High -> Ok Contrast.High
        | _ -> Error "Select a supported contrast."

    let decodeSnapshot (value: ModConductor.Protocol.V1.SettingsSnapshot) =
        if isNull value || isNull value.Presentation then
            Error "Settings are required."
        else
            match
                decodeAppearance value.Presentation.Appearance,
                decodeContrast value.Presentation.Contrast
            with
            | Ok appearance, Ok contrast ->
                Ok
                    { Presentation =
                        { Appearance = appearance
                          TextScale = value.Presentation.TextScale
                          Contrast = contrast }
                      InheritsApplication = value.InheritsApplication }
            | Error detail, _
            | _, Error detail -> Error detail

type SettingsService(owner: SettingsOwner, workspaces: IWorkspaceState) =
    inherit SettingsOperations.SettingsOperationsBase()

    member private _.Scope(target: SettingsTarget) =
        task {
            if isNull target then
                return
                    Error(
                        SettingsWire.fault SettingsFaultCode.InvalidScope "Select a settings scope."
                    )
            else
                match target.TargetCase with
                | SettingsTarget.TargetOneofCase.Application when target.Application ->
                    return Ok SettingsScope.Application
                | SettingsTarget.TargetOneofCase.WorkspaceId ->
                    match Guid.TryParseExact(target.WorkspaceId, "N") with
                    | false, _ ->
                        return
                            Error(
                                SettingsWire.fault
                                    SettingsFaultCode.InvalidScope
                                    "Select a valid workspace."
                            )
                    | true, id ->
                        let! workspace = workspaces.Read(id, None)

                        return
                            match workspace with
                            | Ok value ->
                                Ok(
                                    SettingsScope.Workspace(
                                        ModConductor.Platform.HostPath.value value.Workspace.Path
                                    )
                                )
                            | Error WorkspaceError.NotFound ->
                                Error(
                                    SettingsWire.fault
                                        SettingsFaultCode.WorkspaceNotFound
                                        "The workspace was not found."
                                )
                            | Error _ ->
                                Error(
                                    SettingsWire.fault
                                        SettingsFaultCode.Unavailable
                                        "The workspace settings are unavailable."
                                )
                | _ ->
                    return
                        Error(
                            SettingsWire.fault
                                SettingsFaultCode.InvalidScope
                                "Select a settings scope."
                        )
        }

    override this.ReadSettings(request, _context) =
        task {
            let! scope = this.Scope request.Target

            return
                match scope with
                | Error reply -> reply
                | Ok scope ->
                    match owner.Read scope with
                    | Ok value -> SettingsReply(Settings = SettingsWire.snapshot value)
                    | Error error -> SettingsWire.error error
        }

    override this.SaveSettings(request, context) =
        task {
            let! scope = this.Scope request.Target

            match scope with
            | Error reply -> return reply
            | Ok scope ->
                match SettingsWire.decodeSnapshot request.Settings with
                | Error detail -> return SettingsWire.fault SettingsFaultCode.InvalidValue detail
                | Ok value ->
                    let! saved = owner.Save(scope, value, context.CancellationToken)

                    return
                        match saved with
                        | Ok result -> SettingsReply(Settings = SettingsWire.snapshot result)
                        | Error error -> SettingsWire.error error
        }
