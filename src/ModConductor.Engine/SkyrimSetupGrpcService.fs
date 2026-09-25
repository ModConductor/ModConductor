namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal SkyrimSetupService(coordinator: SkyrimSetupCoordinator) =
    inherit SkyrimSetupOperations.SkyrimSetupOperationsBase()

    let ids workspace profile =
        ModLibraryWire.id workspace, ModLibraryWire.id profile

    let selectionFromWire (value: ModConductor.Protocol.V1.SkyrimSetupSelection) =
        let choice (action: ModConductor.Protocol.V1.SkyrimSetupAction) =
            match action with
            | ModConductor.Protocol.V1.SkyrimSetupAction.Install -> SetupAction.Install
            | ModConductor.Protocol.V1.SkyrimSetupAction.Remove -> SetupAction.Remove
            | ModConductor.Protocol.V1.SkyrimSetupAction.Update -> SetupAction.Update
            | _ -> SetupAction.Unchanged

        if isNull value then ModConductor.Persistence.SetupSelection.none
        else
            { Skse = choice value.Skse
              Enb = choice value.Enb
              Fnis = choice value.Fnis
              EnbArchive = if String.IsNullOrWhiteSpace value.EnbArchivePath then None else Some value.EnbArchivePath }

    let selectionWire (value: ModConductor.Persistence.SetupSelection) =
        ModConductor.Protocol.V1.SkyrimSetupSelection(
            Skse = enum<ModConductor.Protocol.V1.SkyrimSetupAction> (int value.Skse),
            Enb = enum<ModConductor.Protocol.V1.SkyrimSetupAction> (int value.Enb),
            Fnis = enum<ModConductor.Protocol.V1.SkyrimSetupAction> (int value.Fnis),
            EnbArchivePath = (value.EnbArchive |> Option.defaultValue "")
        )

    let wire (value: SkyrimSetupView) =
        let result =
            SkyrimSetupState(
                Phase = value.Phase,
                Status = value.Status,
                Detail = value.Detail,
                Selection = selectionWire value.Selection,
                CanStart = value.CanStart,
                CanContinue = value.CanContinue,
                Active = value.Active,
                CanCancel = value.CanCancel,
                Ready = value.Ready
            )

        result.Components.AddRange(
            value.Components
            |> Seq.map (fun item ->
                SkyrimSetupComponent(
                    Id = item.Id,
                    Name = item.Name,
                    Status = item.Status,
                    Detail = item.Detail,
                    UpdateVersion = (item.UpdateVersion |> Option.defaultValue ""),
                    Installed = item.Installed,
                    Ready = item.Ready,
                    Active = item.Active,
                    Blocked = item.Blocked
                ))
        )

        result

    override _.ReadSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value =
                coordinator.Read(workspace, profile, selectionFromWire request.Selection, context.CancellationToken)

            return wire value
        }

    override _.WatchSkyrimSetup(request, stream, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId
        task {
            while not context.CancellationToken.IsCancellationRequested do
                let revision = coordinator.CurrentRevision(workspace, profile)
                let! value =
                    coordinator.Read(
                        workspace,
                        profile,
                        selectionFromWire request.Selection,
                        context.CancellationToken
                    )
                do! stream.WriteAsync(wire value, context.CancellationToken)
                do! coordinator.WaitForChange(workspace, profile, revision, context.CancellationToken)
        } :> Task

    override _.StartSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value =
                coordinator.Start(
                    workspace,
                    profile,
                    selectionFromWire request.Selection,
                    context.CancellationToken
                )

            return wire value
        }

    override _.ContinueSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value = coordinator.Continue(workspace, profile, context.CancellationToken)
            return wire value
        }

    override _.CancelSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value = coordinator.Cancel(workspace, profile, context.CancellationToken)
            return wire value
        }

    override _.OpenSkyrimSetupPage(request, context) =
        task {
            let address =
                match request.ComponentId with
                | "skse" -> "https://skse.silverlock.org/"
                | "enb" -> ModConductor.Enb.EnbCatalogue.OfficialPage
                | "fnis" -> ModConductor.Fnis.FnisCatalogue.Source
                | _ -> invalidArg "component_id" "The selected component is unavailable."

            do! ModConductor.Desktop.WebLink.openBrowser(Uri address, context.CancellationToken)
            return SkyrimSetupPageReply(Opened = true)
        }
