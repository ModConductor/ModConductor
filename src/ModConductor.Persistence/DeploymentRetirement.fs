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
    let private clearContext (recovery: Recovery) (workspace: Location) (context: Context) token =
        task {
            if context.Pending.IsSome then
                return Error RecoveryError.Busy
            elif context.Links.IsEmpty then
                return Ok()
            else
                // Empty the tracked generation through existing recovery and restore originals.
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
                      ContextId = context.Id
                      ContextFingerprint = context.Fingerprint
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

    let clearOwnedLinks (recovery: Recovery) workspace workspaceId profileId fingerprint token =
        task {
            let! context =
                recovery.Context(DeploymentContextId.create workspaceId profileId fingerprint)

            match context with
            | None -> return Ok()
            | Some context -> return! clearContext recovery workspace context token
        }

    let clearPreviousViews
        (database: StateDatabase)
        (recovery: Recovery)
        (workspace: Location)
        workspaceId
        profileId
        currentId
        (sharedPath: string option)
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
                                )
                                || sharedPath
                                   |> Option.exists (fun shared ->
                                       String.Equals(
                                           HostPath.value root.Directory.Path,
                                           shared,
                                           StringComparison.OrdinalIgnoreCase
                                       ))))))

            let mutable refusal = None

            for context in previous do
                if refusal.IsNone then
                    let! cleared = clearContext recovery workspace context token

                    match cleared with
                    | Error error -> refusal <- Some error
                    | Ok() -> ()

            match refusal with
            | Some error -> return Error error
            | None -> return Ok()
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

                let mutable refusal = None

                for context in owned do
                    if refusal.IsNone then
                        match checkRoots context with
                        | Some detail -> refusal <- Some detail
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
                            | Error error -> refusal <- Some(retirementError error)
                            | Ok() -> ()

                match refusal with
                | Some detail -> return Error detail
                | None ->
                    GameViews.removeOwned workspace profileId
                    return Ok()
        }
