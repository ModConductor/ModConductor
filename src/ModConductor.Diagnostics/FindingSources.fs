namespace ModConductor.Diagnostics

open System
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module internal FindingSources =
    let fnisFindings
        (workspace: Workspace)
        (profile: Profile)
        (state: SkyrimComponentDiagnosticState)
        =
        match state.FnisOutput with
        | Some value when state.Applicable.Contains SkyrimComponent.Fnis && value.Stale ->
            [ { Id = "fnis-output"
                Code = "fnis-output-stale"
                Severity = DiagnosticSeverity.Warning
                WorkspaceId = workspace.Id
                ProfileId = profile.Id
                WorkspaceName = workspace.Name
                ProfileName = profile.Name
                GameName = "Skyrim Special Edition"
                Title = value.Status
                Summary = value.Detail
                Detail = None
                Area = "FNIS"
                Evidence =
                  [ { Label = "Input fingerprint"
                      Value = value.Fingerprint } ]
                NextAction = "Run FNIS"
                Fixability = Fixability.NotFixable
                FixDetail = "Run FNIS from Skyrim setup or the Play check."
                Correlations =
                  [ { Kind = CorrelationKind.Profile
                      Id = profile.Id
                      Revision = None } ]
                Action = DiagnosticAction.None } ]
        | _ -> []

    let skseFindings
        (plans: IFilePlans)
        (request: DiagnosticRequest)
        (workspace: Workspace)
        (profile: Profile)
        (launch: Result<GameLaunchState, ModConductor.Executables.ExecutableError>)
        (state: GameContextState)
        (binding: GameBinding)
        token
        =
        task {
            let log =
                match binding.Evidence.Locations.Documents with
                | Location.Located(documents, _) ->
                    let launchedAt = DiagnosticAdmission.qualifiedLaunchTime state binding launch

                    SkyrimChecks.readLog documents launchedAt token
                | Location.Unavailable _ ->
                    SkseLogResult.Malformed "The SKSE log folder is unavailable."

            let mutable owners = Map.empty

            match log, request.FileSnapshotId with
            | SkseLogResult.Current issues, Some snapshotId ->
                for issue in issues do
                    let target =
                        ModConductor.Platform.LogicalPath.create [ "SKSE"; "Plugins"; issue.Name ]

                    match target with
                    | Error _ -> ()
                    | Ok target ->
                        let! inspected = plans.Inspect(snapshotId, target, None)

                        inspected
                        |> Result.toOption
                        |> Option.bind (fun value ->
                            value.Copies
                            |> List.tryFind (fun copy -> copy.Winner && copy.Enabled)
                            |> Option.bind (fun copy ->
                                match copy.Source with
                                | FilePreviewSource.ManagedCopy _ -> Some copy.Name
                                | _ -> None))
                        |> Option.iter (fun owner ->
                            owners <- owners.Add(issue.Name.ToLowerInvariant(), owner))
            | _ -> ()

            return Checks.skseLog workspace profile binding.Id state.Revision log owners
        }

    let oldFormFindings
        (pluginOrders: IProfilePluginOrders)
        (workspace: Workspace)
        (profile: Profile)
        (state: GameContextState)
        (binding: GameBinding)
        snapshotId
        =
        task {
            let! order = pluginOrders.Read(workspace.Id, profile.Id, snapshotId)

            return
                order
                |> Result.mapError DiagnosticErrors.profile
                |> Result.bind (fun order ->
                    if
                        order.Reference.WorkspaceId <> workspace.Id
                        || order.Reference.ProfileId <> profile.Id
                        || order.Headers.Id <> snapshotId
                        || order.Headers.Stale
                    then
                        Error DiagnosticError.Foreign
                    else
                        SkyrimChecks.oldPluginFormats order.Headers order.View.Order.Entries
                        |> Checks.oldPluginFormats
                            workspace
                            profile
                            binding.Id
                            state.Revision
                            snapshotId
                        |> Ok)
        }

    let fileFindings (plans: IFilePlans) (workspace: Workspace) (profile: Profile) snapshotId =
        task {
            let! summary = plans.Read snapshotId

            match summary with
            | Error error -> return Error(DiagnosticErrors.file error)
            | Ok summary when summary.WorkspaceId <> workspace.Id || summary.ProfileId <> profile.Id ->
                return Error DiagnosticError.Foreign
            | Ok summary ->
                let! problems = plans.DiagnosticProblems snapshotId

                return
                    problems
                    |> Result.map (Checks.fileProblems workspace profile summary)
                    |> Result.mapError DiagnosticErrors.file
        }

    let profileFindings
        (profileData: IProfileGameData)
        (workspace: Workspace)
        (profile: Profile)
        game
        =
        task {
            let! value = profileData.Read(workspace.Id, profile.Id)

            return
                match value with
                | Ok state when state.WorkspaceId = workspace.Id && state.ProfileId = profile.Id ->
                    Checks.profileData workspace profile game state
                | _ -> []
        }

    let helperFindings helperDiagnostic (workspace: Workspace) (profile: Profile) game =
        match helperDiagnostic with
        | Some diagnostic ->
            match diagnostic () with
            | Some detail ->
                [ { Id = "loot-helper:" + profile.Id.ToString "N"
                    Code = "loot-helper-unavailable"
                    Severity = DiagnosticSeverity.Error
                    WorkspaceId = workspace.Id
                    ProfileId = profile.Id
                    WorkspaceName = workspace.Name
                    ProfileName = profile.Name
                    GameName = game
                    Title = "LOOT sorting is unavailable"
                    Summary = "The package helper is missing or incompatible."
                    Detail = None
                    Area = "Plugin order"
                    Evidence =
                      [ { Label = "Package details"
                          Value = detail } ]
                    NextAction = "Install a complete package, then select Check again."
                    Fixability = Fixability.NotFixable
                    FixDetail = "The package needs repair."
                    Correlations = []
                    Action = DiagnosticAction.CheckAgain } ]
            | None -> []
        | None -> []
