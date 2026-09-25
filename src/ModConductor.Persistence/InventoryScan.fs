namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.ModLibrary

module internal InventoryScan =
    let run (database: StateDatabase) (access: LibraryAccess) workspace limit =
        task {
            if limit < 1 || limit > 100000 then
                return Error LibraryError.LimitExceeded
            else
                let! rootResult = access.Root workspace

                match rootResult with
                | Error error -> return Error error
                | Ok root ->
                    let! snapshot =
                        database.Enqueue(fun () ->
                            use transaction = database.Connection.BeginTransaction(deferred = true)

                            let ids =
                                LibraryRows.ids
                                    database.Connection
                                    transaction
                                    workspace
                                    ""
                                    (limit + 1)

                            let rows =
                                List.truncate limit ids
                                |> List.choose (LibraryRows.find database.Connection transaction)

                            let library =
                                LibraryRows.library database.Connection transaction workspace

                            use query =
                                Sqlite.command
                                    database.Connection
                                    transaction
                                    "SELECT root_name FROM output_locations WHERE workspace_id=$workspace"
                                    [ "$workspace", box (string workspace) ]

                            use reader = query.ExecuteReader()

                            let outputRoots =
                                [ while reader.Read() do
                                      yield reader.GetString 0 ]
                                |> Set.ofList

                            transaction.Commit()
                            rows, library, outputRoots, ids.Length > limit)

                    let rows, library, outputRoots, limited = snapshot

                    let! observations =
                        Task.Run(fun () ->
                            use directory = HeldDirectory.Open(root.Path, root.Identity)

                            let excluded =
                                rows
                                |> List.choose (fun row ->
                                    row.Entry.SourcePath
                                    |> Option.map (LogicalPath.components >> List.head))
                                |> Set.ofList

                            let unknown = ResizeArray<UnmanagedEntry>()
                            let mutable scanned = 0
                            let mutable truncated = limited
                            use names = directory.Names.GetEnumerator()

                            while scanned < limit && names.MoveNext() do
                                scanned <- scanned + 1
                                let name = names.Current

                                if
                                    name <> RootIdentityFile.name
                                    && not (Set.contains name excluded)
                                    && not (Set.contains name outputRoots)
                                    && not (
                                        library |> Option.exists (fun value -> value.Name = name)
                                    )
                                then
                                    let kind =
                                        try
                                            use folder = directory.Directory(name, None)
                                            EntryKind.Directory
                                        with :? IOException ->
                                            try
                                                let stream, _ = directory.Read(name, None)
                                                use stream = stream
                                                EntryKind.RegularFile
                                            with
                                            | :? IOException
                                            | :? UnauthorizedAccessException -> EntryKind.Other

                                    if unknown.Count < 32 then
                                        unknown.Add
                                            { Path =
                                                LogicalPath.create [ name ]
                                                |> Result.defaultWith (fun _ ->
                                                    invalidOp "Invalid native name.")
                                              Kind = kind }
                                    else
                                        truncated <- true

                            if names.MoveNext() then
                                truncated <- true

                            unknown |> Seq.toList, truncated, scanned)

                    let unknown, truncated, visited = observations
                    let mutable remaining = limit - visited
                    let mutable truncated = truncated

                    for row in rows do
                        if
                            row.Entry.Status <> InventoryStatus.Publishing
                            && row.Entry.Kind <> ModKind.Separator
                        then
                            if remaining <= 0 then
                                truncated <- true
                            else
                                let! previous, stored =
                                    database.Enqueue(fun () ->
                                        let previous =
                                            row.Entry.CurrentVersion
                                            |> Option.bind (fun id ->
                                                LibraryRows.version
                                                    database.Connection
                                                    null
                                                    id
                                                    0
                                                    (remaining + 1))

                                        let stored =
                                            previous
                                            |> Option.map (fun version ->
                                                version.Entries
                                                |> List.map (fun entry ->
                                                    LibraryRows.payload
                                                        database.Connection
                                                        null
                                                        entry.Payload.Id
                                                    |> Option.get))
                                            |> Option.defaultValue []

                                        previous, stored)

                                let! status, count, hitLimit =
                                    Task.Run(fun () ->
                                        try
                                            match row.Entry.Kind, library with
                                            | (ModKind.Regular | ModKind.Backup), Some library when
                                                library.Phase = 2
                                                ->
                                                if stored.Length >= remaining then
                                                    raise (SourceLimitException())

                                                use payloads =
                                                    LibraryFiles.openLibrary root library

                                                for payload in stored do
                                                    LibraryFiles.verify payloads payload

                                                if
                                                    row.Entry.Kind = ModKind.Backup
                                                    || row.Entry.SourcePath.IsNone
                                                then
                                                    InventoryStatus.Ready,
                                                    max 1 stored.Length,
                                                    false
                                                else
                                                    use source =
                                                        LibraryFiles.openSource
                                                            root
                                                            row
                                                            (Set.singleton payloads.Identity)

                                                    let files, candidates =
                                                        SourceFiles.scan
                                                            source
                                                            (Set.singleton payloads.Identity)
                                                            (remaining - stored.Length)
                                                            ignore

                                                    let unchanged =
                                                        previous
                                                        |> Option.exists (fun version ->
                                                            (version.Entries
                                                             |> List.map (fun entry ->
                                                                 entry.Path,
                                                                 entry.Payload.Length,
                                                                 entry.Payload.Sha256)
                                                             |> List.sortBy (fun (path, _, _) ->
                                                                 LogicalPath.components path)) = (files
                                                                                                  |> List.map
                                                                                                      (fun
                                                                                                          file ->
                                                                                                          file.Path,
                                                                                                          file.Length,
                                                                                                          file.Sha256)))

                                                    (if previous.IsNone || unchanged then
                                                         InventoryStatus.Ready
                                                     else
                                                         InventoryStatus.Changed),
                                                    max 1 (candidates + stored.Length),
                                                    false
                                            | ModKind.Regular, _
                                            | ModKind.Backup, _ ->
                                                InventoryStatus.Unproved, 1, false
                                            | ModKind.GeneratedOutput, _ when row.Entry.SourcePath.IsNone ->
                                                row.Entry.Status, 1, false
                                            | ModKind.Unmanaged, _
                                            | ModKind.GeneratedOutput, _ ->
                                                use source =
                                                    LibraryFiles.openSource
                                                        root
                                                        row
                                                        (library
                                                         |> Option.bind _.Identity
                                                         |> Option.toList
                                                         |> Set.ofList)

                                                InventoryStatus.Ready, 1, false
                                            | ModKind.Separator, _ ->
                                                InventoryStatus.Ready, 1, false
                                        with
                                        | :? SourceLimitException ->
                                            InventoryStatus.Unproved, remaining, true
                                        | :? FileNotFoundException
                                        | :? DirectoryNotFoundException ->
                                            InventoryStatus.Detached, 1, false
                                        | :? IOException
                                        | :? UnauthorizedAccessException ->
                                            InventoryStatus.Unproved, remaining, false)

                                remaining <- remaining - count
                                truncated <- truncated || hitLimit

                                do!
                                    database.EnqueueInternal(fun () ->
                                        // A scan never overwrites a concurrent publication or a newer metadata edit.
                                        Sqlite.execute
                                            database.Connection
                                            null
                                            "UPDATE mods SET status=$status WHERE id=$id AND revision=$revision AND status NOT IN (5,6)"
                                            [ "$status", box (LibraryEncoding.status status)
                                              "$id", box (string row.Entry.Id)
                                              "$revision", box row.Entry.Revision ])

                    let! entries =
                        database.Enqueue(fun () ->
                            rows
                            |> List.truncate 32
                            |> List.choose (fun row ->
                                LibraryRows.find database.Connection null row.Entry.Id
                                |> Option.map _.Entry)
                            |> InventoryPolicy.inventoryWindow)

                    return
                        Ok
                            { Entries = entries
                              Unmanaged = unknown
                              Limited = truncated || rows.Length > entries.Length }
        }
