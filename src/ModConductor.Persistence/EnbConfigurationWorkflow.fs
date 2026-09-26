namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Operations

module internal EnbConfigurationEncoding =
    let values (prior: Map<string * string * string, string option>) =
        prior
        |> Map.toList
        |> List.map (fun ((file, section, key), value) ->
            String.concat "|" [ file; section; key; "0"; value |> Option.defaultValue "<missing>" ])
        |> String.concat "\n"

    let parse (text: string) =
        text.Split('\n', StringSplitOptions.RemoveEmptyEntries)
        |> Array.choose (fun line ->
            match line.Split('|') with
            | [| _; _; key; applied; "<missing>" |] -> Some(key, (applied, None))
            | [| _; _; key; applied; prior |] -> Some(key, (applied, Some prior))
            | [| _; _; key; "<missing>" |] -> Some(key, ("0", None))
            | [| _; _; key; prior |] -> Some(key, ("0", Some prior))
            | _ -> None)
        |> Map.ofArray

module internal EnbProfile =
    let error =
        function
        | ModConductor.ProfileGameData.ProfileDataError.Invalid detail
        | ModConductor.ProfileGameData.ProfileDataError.Unavailable detail
        | ModConductor.ProfileGameData.ProfileDataError.Conflict detail -> detail
        | ModConductor.ProfileGameData.ProfileDataError.Busy ->
            "Wait for the current profile settings change."
        | ModConductor.ProfileGameData.ProfileDataError.Stale ->
            "The profile settings changed. Try again."
        | ModConductor.ProfileGameData.ProfileDataError.Cancelled ->
            "The profile settings change was cancelled."
        | ModConductor.ProfileGameData.ProfileDataError.NotFound ->
            "The profile settings are unavailable."

type internal EnbConfigurationWorkflow
    (
        enbSetups: EnbStore,
        profileGameData: ModConductor.ProfileGameData.ProfileGameDataSession,
        deployment: ModConductor.DeploymentRecovery.Recovery,
        enbCheckpoint: string -> int -> unit
    ) =
    member internal _.EnbConfigurationDeploymentState(receipt: Guid) =
        task {
            let! value = deployment.Read receipt

            return
                value
                |> Option.map (fun receipt ->
                    match receipt.Phase with
                    | ModConductor.DeploymentRecovery.ReceiptPhase.Complete -> "complete"
                    | ModConductor.DeploymentRecovery.ReceiptPhase.Restored -> "restored"
                    | _ -> "pending")
        }

    member internal _.RecoverEnbConfigurationAction
        (operation: StoredEnbConfigurationOperation, token: Threading.CancellationToken)
        =
        task {
            match operation.ActionId with
            | Some action ->
                let profiles = profileGameData :> ModConductor.ProfileGameData.IProfileGameData
                let! restored = profiles.RestoreConfiguration(operation.WorkspaceId, action, token)

                return
                    match restored with
                    | Ok _
                    | Error ModConductor.ProfileGameData.ProfileDataError.NotFound -> Ok()
                    | Error _ ->
                        Error "The interrupted Skyrim settings change still needs recovery."
            | _ -> return Ok()
        }

    member internal _.RestoreEnbConfiguration
        (operation: StoredEnbConfigurationOperation, token: Threading.CancellationToken)
        =
        task {
            let fail detail = Error detail
            let profiles = profileGameData :> ModConductor.ProfileGameData.IProfileGameData

            let! state = profiles.Read(operation.WorkspaceId, operation.ProfileId)

            match state with
            | Error _ ->
                let detail = "The previous Skyrim settings could not be read."

                do!
                    enbSetups.UpdateConfiguration(
                        operation.ReceiptId,
                        "restore_pending",
                        None,
                        detail
                    )

                return fail detail
            | Ok state ->
                let! document =
                    profiles.ReadConfiguration(state.Reference, "SkyrimPrefs.ini", token)

                match document with
                | Error _ ->
                    let detail = "The previous Skyrim settings could not be read."

                    do!
                        enbSetups.UpdateConfiguration(
                            operation.ReceiptId,
                            "restore_pending",
                            None,
                            detail
                        )

                    return fail detail
                | Ok document ->
                    let restored, conflicts =
                        ModConductor.Enb.EnbSetupPlanning.restoreSkyrimPrefs
                            document.Document.Content
                            (EnbConfigurationEncoding.parse operation.Values)

                    match conflicts with
                    | _ :: _ ->
                        let detail =
                            "SkyrimPrefs.ini changed after MC applied ENB settings. MC preserved: "
                            + String.concat ", " conflicts

                        do!
                            enbSetups.UpdateConfiguration(
                                operation.ReceiptId,
                                "conflict",
                                None,
                                detail
                            )

                        return fail detail
                    | [] when restored = document.Document.Content ->
                        do! enbSetups.RemoveConfiguration operation.ReceiptId
                        return Ok()
                    | [] ->
                        let action = Guid.NewGuid()

                        do!
                            enbSetups.UpdateConfiguration(
                                operation.ReceiptId,
                                "restore_pending",
                                Some action,
                                "Restoring previous Skyrim settings."
                            )

                        enbCheckpoint "configuration-restore" -1

                        let! saved =
                            profiles.SaveConfiguration(
                                { Id = action
                                  PreviewId = document.PreviewId
                                  Expected = document.Expected
                                  Name = document.Name
                                  Content = restored },
                                ignore,
                                token
                            )

                        match saved with
                        | Ok _ ->
                            do! enbSetups.RemoveConfiguration operation.ReceiptId
                            return Ok()
                        | Error _ ->
                            let detail = "The previous Skyrim settings still need recovery."

                            do!
                                enbSetups.UpdateConfiguration(
                                    operation.ReceiptId,
                                    "restore_pending",
                                    None,
                                    detail
                                )

                            return fail detail
        }

    member internal _.StageEnbConfiguration
        (
            workspace,
            profile,
            active,
            deploymentId,
            previousAction: Guid option,
            markStaged: unit -> unit,
            token
        ) =
        task {
            let profiles = profileGameData :> ModConductor.ProfileGameData.IProfileGameData

            if previousAction.IsNone then
                let! state = profiles.Read(workspace, profile)

                match state with
                | Error problem -> return Error(EnbProfile.error problem)
                | Ok state ->
                    let! document =
                        profiles.ReadConfiguration(state.Reference, "SkyrimPrefs.ini", token)

                    match document with
                    | Error problem -> return Error(EnbProfile.error problem)
                    | Ok document ->

                        let content, previous =
                            ModConductor.Enb.EnbSetupPlanning.configureSkyrimPrefs
                                document.Document.Content

                        let values = EnbConfigurationEncoding.values previous

                        do!
                            enbSetups.StageConfiguration
                                { ReceiptId = deploymentId
                                  WorkspaceId = workspace
                                  ProfileId = profile
                                  GenerationId = active
                                  Kind = "install"
                                  Phase = "configuration_pending"
                                  Values = values
                                  ActionId = None
                                  Detail = "" }

                        markStaged ()
                        let action = Guid.NewGuid()

                        do!
                            enbSetups.UpdateConfiguration(
                                deploymentId,
                                "configuration_pending",
                                Some action,
                                "Applying Skyrim graphics settings."
                            )

                        let! saved =
                            profiles.SaveConfiguration(
                                { Id = action
                                  PreviewId = document.PreviewId
                                  Expected = document.Expected
                                  Name = document.Name
                                  Content = content },
                                ignore,
                                token
                            )

                        match saved with
                        | Error _ -> return Error "Skyrim graphics settings could not be applied."
                        | Ok _ ->

                            do!
                                enbSetups.UpdateConfiguration(
                                    deploymentId,
                                    "configuration_applied",
                                    Some action,
                                    ""
                                )

                            return Ok(previous, Some action)

            else
                return Ok(Map.empty, previousAction)
        }

    member internal this.RestoreFailedEnbInstall
        (workspace, profile, deploymentId, configurationStaged, detail: string)
        =
        task {
            let mutable restorationFailure = None
            do! enbSetups.RemoveSelection deploymentId

            if configurationStaged then
                let! operation = enbSetups.ConfigurationOperation(workspace, profile)

                match operation with
                | Some operation when operation.ReceiptId = deploymentId ->
                    do! enbSetups.UpdateConfiguration(deploymentId, "restore_pending", None, detail)

                    let! actionRecovered =
                        this.RecoverEnbConfigurationAction(
                            operation,
                            Threading.CancellationToken.None
                        )

                    let! restored =
                        match actionRecovered with
                        | Ok() ->
                            this.RestoreEnbConfiguration(
                                operation,
                                Threading.CancellationToken.None
                            )
                        | Error detail -> Threading.Tasks.Task.FromResult(Error detail)

                    match restored with
                    | Error detail -> restorationFailure <- Some detail
                    | Ok() -> ()
                | _ -> ()

            return restorationFailure
        }
