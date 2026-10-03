namespace ModConductor.Persistence

open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.DeploymentRecovery
open ModConductor.Platform
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module internal WorkspaceDeploymentRemoval =
    let private roots (state: WorkspaceDeletionState) profile =
        GameViews.rootPath state.Receipt.Workspace.Path profile
        :: (state.DeploymentContexts
            |> List.collect _.Roots
            |> List.map (fun root ->
                let path = HostPath.value root.Directory.Path

                if
                    Path
                        .GetFileName(path)
                        .Equals("Data", System.StringComparison.OrdinalIgnoreCase)
                then
                    Path.GetDirectoryName path
                else
                    path))
        |> List.distinct

    let private affected (state: WorkspaceDeletionState) profile =
        (state.Data
         |> List.exists (fun (context, _) ->
             context.Applied |> Option.exists (fun applied -> applied.ProfileId = profile)))
        || (state.DeploymentContexts
            |> List.exists (fun context ->
                (context.Active.IsSome
                 || not context.Links.IsEmpty
                 || not context.Originals.IsEmpty)
                && DeploymentContextId.create state.Workspace.Id profile context.Fingerprint = context.Id))
        || (state.Deployments
            |> List.exists (fun (context, generation) ->
                context.Active = Some generation.Id
                && generation.Provenance
                   |> Option.bind _.Profile
                   |> Option.exists (fun saved -> saved.Id = profile)))

    let private check
        (state: WorkspaceDeletionState)
        profile
        (game: ModConductor.GameContexts.GameContextState)
        =
        match game.Binding with
        | None ->
            Error(WorkspaceError.ProfileData "The deployed game's installation is unavailable.")
        | Some binding ->
            roots state profile
            |> ProfileDataResultFlow.traverse (Some >> GameProcesses.checkWithRoot binding.Evidence)
            |> Result.map ignore
            |> Result.mapError WorkspaceError.ProfileData

    let private stopped (database: StateDatabase) (state: WorkspaceDeletionState) =
        task {
            let! games =
                database.Enqueue(fun () ->
                    state.Profiles
                    |> List.filter (affected state)
                    |> ProfileDataResultFlow.traverse (fun profile ->
                        GameContextRows.read
                            database.Connection
                            null
                            database.OwnerId
                            state.Workspace.Id
                            profile
                        |> Result.map (fun game -> profile, game)
                        |> Result.mapError (fun _ -> WorkspaceError.NotFound)))

            return!
                Task.Run(fun () ->
                    games
                    |> Result.bind (
                        ProfileDataResultFlow.traverse (fun (profile, game) ->
                            check state profile game)
                    )
                    |> Result.map ignore)
        }

    let private ready (database: StateDatabase) (expected: WorkspaceDeletionState) =
        task {
            let! latest = WorkspaceDeletionRows.read database expected.Workspace.Id

            match latest with
            | Error error -> return Error error
            | Ok state when state.Workspace.Revision <> expected.Workspace.Revision ->
                return Error WorkspaceError.StaleRevision
            | Ok state ->
                let! idle = WorkspaceDeletionRows.idle database state
                return idle |> Result.map (fun () -> state)
        }

    let deactivate
        (database: StateDatabase)
        (enter: System.Guid -> System.IDisposable option)
        (expected: WorkspaceDeletionState)
        token
        =
        task {
            match enter expected.Workspace.Id with
            | None -> return Error WorkspaceError.Busy
            | Some lease ->
                use lease = lease
                let! latest = ready database expected

                match latest with
                | Error error -> return Error error
                | Ok state ->
                    let! stoppedResult = stopped database state

                    match stoppedResult with
                    | Error error -> return Error error
                    | Ok() ->
                        do! DeploymentRemoval.removeContexts database state.DeploymentContexts token
                        return Ok()
        }
