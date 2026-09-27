namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.FilePlanning
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations
open ModConductor.Deployment

module internal DeploymentRetirement =
    let clearOwnedLinks
        (recovery: Recovery)
        (workspace: Location)
        workspaceId
        profileId
        fingerprint
        token
        =
        task {
            let contextId = DeploymentContextId.create workspaceId profileId fingerprint

            let! legacy = recovery.Context contextId

            match legacy with
            | None -> return Ok()
            | Some context when context.Pending.IsSome -> return Error RecoveryError.Busy
            | Some context when context.Links.IsEmpty -> return Ok()
            | Some context ->
                // Switch the old owned in-place generation to an empty one through the
                // existing recovery journal, restoring only its recorded originals.
                let id = Guid.NewGuid()

                let directory =
                    DeploymentWorkspaceStorage.child
                        workspace
                        (".mc-generation-" + id.ToString("N"))

                let empty: Generation =
                    { Id = id
                      PlanFingerprint = "mc-legacy-game-view-cutover"
                      Directory = directory
                      Files = []
                      References = []
                      Writable = []
                      Roots = context.Roots |> List.map _.Root
                      Observed = []
                      Working = []
                      NativeTargets = Map.empty
                      Provenance = None }

                let request: SwitchRequest =
                    { Id = id
                      ContextId = contextId
                      ContextFingerprint = fingerprint
                      ExpectedRevision = context.Revision
                      Roots = context.Roots
                      Generation = empty
                      DirectoryBoundaries = []
                      PreserveOriginals = []
                      ExpectedSources = None }

                let! started = recovery.Start(request, cancellation = token)

                match started with
                | Error error -> return Error error
                | Ok receipt ->
                    let! completed =
                        recovery.Run(id, receipt.Revision, false, token, (fun _ _ -> ()))

                    return completed |> Result.map ignore
        }

    let clearPreviousViews
        (database: StateDatabase)
        (recovery: Recovery)
        (workspace: Location)
        workspaceId
        profileId
        currentId
        token
        =
        task {
            let gamePath = GameViews.rootPath workspace.Path profileId

            let! previous =
                database.Enqueue(fun () ->
                    use query =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT id FROM deployment_contexts WHERE id<>$current"
                            [ "$current", box (string currentId) ]

                    use reader = query.ExecuteReader()

                    let ids =
                        [ while reader.Read() do
                              yield Guid.Parse(reader.GetString 0) ]

                    reader.Close()

                    ids
                    |> List.choose (fun id ->
                        DeploymentRows.context database.Connection null id
                        |> Option.filter (fun context ->
                            context.Roots
                            |> List.exists (fun root ->
                                String.Equals(
                                    HostPath.value root.Directory.Path,
                                    gamePath,
                                    StringComparison.OrdinalIgnoreCase
                                )))
                        |> Option.map _.Fingerprint))

            let rec clear =
                function
                | [] -> task { return Ok() }
                | fingerprint :: remaining ->
                    task {
                        let! cleared =
                            clearOwnedLinks
                                recovery
                                workspace
                                workspaceId
                                profileId
                                fingerprint
                                token

                        match cleared with
                        | Error error -> return Error error
                        | Ok() -> return! clear remaining
                    }

            return! clear previous
        }

    let retireProfile
        (database: StateDatabase)
        (recovery: Recovery)
        (workspace: Location)
        workspaceId
        profileId
        (evidence: ModConductor.GameContexts.InstallationEvidence)
        token
        =
        task {
            let retirementError error =
                "The profile game folder could not be retired: " + string error

            match
                GameProcesses.checkWithRoot
                    evidence
                    (Some(GameViews.rootPath workspace.Path profileId))
            with
            | Error detail -> return Error detail
            | Ok() ->
                let! owned =
                    database.Enqueue(fun () ->
                        use query =
                            Sqlite.command
                                database.Connection
                                null
                                "SELECT id FROM deployment_contexts"
                                []

                        use reader = query.ExecuteReader()

                        let ids =
                            [ while reader.Read() do
                                  yield Guid.Parse(reader.GetString 0) ]

                        reader.Close()

                        ids
                        |> List.choose (fun id ->
                            DeploymentRows.context database.Connection null id
                            |> Option.filter (fun context ->
                                let expected =
                                    DeploymentContextId.create
                                        workspaceId
                                        profileId
                                        context.Fingerprint

                                expected = id)))

                let checkRoots (context: Context) =
                    context.Roots
                    |> List.tryPick (fun root ->
                        let path = HostPath.value root.Directory.Path

                        let gameRoot =
                            if
                                String.Equals(
                                    System.IO.Path.GetFileName path,
                                    "Data",
                                    StringComparison.OrdinalIgnoreCase
                                )
                            then
                                System.IO.Path.GetDirectoryName path
                            else
                                path

                        match GameProcesses.checkWithRoot evidence (Some gameRoot) with
                        | Error detail -> Some detail
                        | Ok() -> None)

                let rec retireOwned =
                    function
                    | [] -> task { return Ok() }
                    | context :: remaining ->
                        task {
                            match checkRoots context with
                            | Some detail -> return Error detail
                            | None ->
                                let! cleared =
                                    clearOwnedLinks
                                        recovery
                                        workspace
                                        workspaceId
                                        profileId
                                        context.Fingerprint
                                        token

                                match cleared with
                                | Error error -> return Error(retirementError error)
                                | Ok() -> return! retireOwned remaining
                        }

                let! retired = retireOwned owned

                match retired with
                | Error detail -> return Error detail
                | Ok() ->
                    GameViews.removeOwned workspace profileId
                    return Ok()
        }
