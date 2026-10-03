namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.DeploymentRecovery
open ModConductor.GameContexts
open ModConductor.Platform

module internal DeploymentRemoval =
    let private removeLink (context: Context) (link: ActiveLink) =
        match RecoveryFiles.observe context link.Target with
        | None -> ()
        | Some entry when entry = link.Entry -> RecoveryFiles.remove context link.Target link.Entry
        | Some entry when
            context.Originals
            |> List.exists (fun original -> original.Target = link.Target && original.Entry = entry)
            ->
            ()
        | Some _ -> RecoveryFiles.fail "A recorded game link changed. It was not removed."

    let private removeDirectory (context: Context) (directory: OwnedDirectory) =
        match RecoveryFiles.observe context directory.Target with
        | None -> ()
        | Some entry when entry.Kind = EntryKind.Directory && entry.Identity = directory.Identity ->
            let root = RecoveryFiles.binding context directory.Target

            RecoveryFiles.withParent root.Directory directory.Target.Path (fun parent name ->
                use child = parent.Directory(name, Some directory.Identity)

                if Seq.isEmpty child.Names then
                    parent.RemoveDirectory(name, directory.Identity))
        | Some _ -> RecoveryFiles.fail "A recorded game folder changed. It was not removed."

    let private remove (context: Context) (token: CancellationToken) =
        for link in context.Links do
            token.ThrowIfCancellationRequested()
            removeLink context link

        for original in context.Originals do
            token.ThrowIfCancellationRequested()
            RecoveryFiles.restoreOriginal token context original

        context.Directories
        |> List.sortByDescending (fun directory ->
            LogicalPath.components directory.Target.Path |> List.length)
        |> List.iter (removeDirectory context)

    let ownedContexts (database: StateDatabase) workspace profile =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command database.Connection null "SELECT id FROM deployment_contexts" []

            use reader = query.ExecuteReader()

            let ids =
                [ while reader.Read() do
                      yield Guid.Parse(reader.GetString 0) ]

            reader.Close()

            ids
            |> List.choose (fun id ->
                DeploymentRows.context database.Connection null id
                |> Option.filter (fun context ->
                    DeploymentContextId.create workspace profile context.Fingerprint = id)))

    let idle (database: StateDatabase) workspace (contexts: Context list) =
        database.Enqueue(fun () ->
            if
                contexts |> List.exists (fun context -> context.Pending.IsSome)
                || OutputRows.active database.Connection null workspace
            then
                Error RecoveryError.Busy
            else
                Ok())

    let stopped (game: GameContextState) runnableRoot (contexts: Context list) =
        match game.Binding with
        | None when contexts.IsEmpty -> Ok()
        | None -> Error "The deployed game's installation is unavailable."
        | Some binding ->
            let roots =
                runnableRoot
                :: (contexts
                    |> List.collect _.Roots
                    |> List.map (fun root ->
                        let path = HostPath.value root.Directory.Path

                        if
                            Path
                                .GetFileName(path)
                                .Equals("Data", StringComparison.OrdinalIgnoreCase)
                        then
                            Path.GetDirectoryName path
                        else
                            path))
                |> List.distinct

            roots
            |> List.tryPick (fun root ->
                match GameProcesses.checkWithRoot binding.Evidence (Some root) with
                | Ok() -> None
                | Error detail -> Some detail)
            |> function
                | Some error -> Error error
                | None -> Ok()

    let removeContexts (database: StateDatabase) (contexts: Context list) token =
        task {
            for context in contexts do
                do! Task.Run(fun () -> remove context token)

                do!
                    database.Enqueue(fun () ->
                        DeploymentRows.writeContext
                            database.Connection
                            null
                            { context with
                                Revision = context.Revision + 1L
                                Active = None
                                Links = []
                                Directories = []
                                Originals = [] })
        }

    let deactivate
        (database: StateDatabase)
        (access: LibraryAccess)
        workspace
        profile
        generation
        token
        =
        task {
            let! contexts = ownedContexts database workspace profile

            if contexts |> List.forall (fun context -> context.Active <> Some generation) then
                return Error RecoveryError.Stale
            else
                let! ready = idle database workspace contexts

                match ready with
                | Error error -> return Error error
                | Ok() ->
                    let! root = access.Root workspace

                    let! game =
                        database.Enqueue(fun () ->
                            GameContextRows.read
                                database.Connection
                                null
                                database.OwnerId
                                workspace
                                profile)

                    match root, game with
                    | Error _, _
                    | _, Error _ -> return Error RecoveryError.NotFound
                    | Ok root, Ok game ->
                        let! checkedGame =
                            Task.Run(fun () ->
                                stopped game (GameViews.rootPath root.Path profile) contexts)

                        match checkedGame with
                        | Error detail -> return Error(RecoveryError.Unavailable detail)
                        | Ok() ->
                            do! removeContexts database contexts token
                            return Ok()
        }
