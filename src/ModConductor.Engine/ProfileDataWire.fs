namespace ModConductor.Engine

open ModConductor
open ModConductor.ProfileGameData

module internal ProfileDataWire =
    let reference (value: ProfileDataRef) =
        Protocol.V1.ProfileDataRef(
            WorkspaceId = value.WorkspaceId.ToString("N"),
            ProfileId = value.ProfileId.ToString("N"),
            ContextId = value.ContextId.ToString("N"),
            Revision = uint64 value.Revision
        )

    let readReference (value: Protocol.V1.ProfileDataRef) =
        if isNull value then
            ModLibraryWire.reject "Read the profile settings first."

        { WorkspaceId = ModLibraryWire.id value.WorkspaceId
          ProfileId = ModLibraryWire.id value.ProfileId
          ContextId = ModLibraryWire.id value.ContextId
          Revision = ModLibraryWire.number value.Revision }
        : ProfileDataRef

    let state (value: ProfileDataState) =
        let result =
            Protocol.V1.ProfileDataState(
                Reference = reference value.Reference,
                Options =
                    Protocol.V1.ProfileDataOptions(
                        Settings = value.Options.Settings,
                        Saves = value.Options.Saves
                    ),
                SettingsPath = value.SettingsPath,
                SavesPath = value.SavesPath,
                SettingsFiles = uint32 value.SettingsFiles,
                SaveFiles = uint32 value.SaveFiles,
                SettingsInitialized = value.SettingsInitialized,
                SavesInitialized = value.SavesInitialized,
                PendingProfileChange = value.PendingProfileChange
            )

        value.InUse |> Option.iter (fun id -> result.InUseProfileId <- id.ToString("N"))

        value.Pending
        |> Option.iter (fun id -> result.PendingActionId <- id.ToString("N"))

        value.PendingConfiguration
        |> Option.iter (fun name -> result.PendingConfiguration <- name)

        value.Problem |> Option.iter (fun text -> result.Problem <- text)
        result

    let textDocument = FilePlanWire.textDocument

    let problem value =
        let kind, detail =
            match value with
            | ProfileDataError.NotFound ->
                Protocol.V1.ProfileDataProblemKind.ProfileDataProblemNotFound,
                "The profile was not found."
            | ProfileDataError.Busy ->
                Protocol.V1.ProfileDataProblemKind.ProfileDataProblemBusy,
                "Wait for the current operation."
            | ProfileDataError.Stale ->
                Protocol.V1.ProfileDataProblemKind.ProfileDataProblemStale,
                "The profile settings changed. Read them again."
            | ProfileDataError.Cancelled ->
                Protocol.V1.ProfileDataProblemKind.ProfileDataProblemCancelled,
                "The operation was cancelled."
            | ProfileDataError.Invalid text ->
                Protocol.V1.ProfileDataProblemKind.ProfileDataProblemInvalid, text
            | ProfileDataError.Unavailable text ->
                Protocol.V1.ProfileDataProblemKind.ProfileDataProblemUnavailable, text
            | ProfileDataError.Conflict text ->
                Protocol.V1.ProfileDataProblemKind.ProfileDataProblemConflict, text

        Protocol.V1.ProfileDataProblem(Kind = kind, Detail = detail)

    let reply =
        function
        | Ok value -> Protocol.V1.ProfileDataReply(State = state value)
        | Error error -> Protocol.V1.ProfileDataReply(Problem = problem error)

    let finished =
        function
        | Ok(value: ProfileDataResult) ->
            let result =
                Protocol.V1.ProfileDataActionResult(
                    Id = value.Id.ToString("N"),
                    State = state value.State,
                    Complete = value.Complete,
                    CompletedFiles = uint32 value.CompletedFiles
                )

            value.Problem |> Option.iter (fun detail -> result.Problem <- detail)
            Protocol.V1.ProfileDataEvent(Result = result)
        | Error error -> Protocol.V1.ProfileDataEvent(Problem = problem error)
