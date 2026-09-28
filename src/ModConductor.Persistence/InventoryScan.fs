namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.ModLibrary

module internal InventoryScan =
    let private snapshot (database: StateDatabase) workspace limit =
        database.Enqueue(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = true)
            let count = min 32 limit
            let ids = LibraryRows.ids database.Connection transaction workspace "" (count + 1)

            let rows =
                ids
                |> List.truncate count
                |> List.choose (LibraryRows.find database.Connection transaction)

            let library = LibraryRows.library database.Connection transaction workspace

            use sources =
                Sqlite.command
                    database.Connection
                    transaction
                    "SELECT source_path FROM mods WHERE workspace_id=$workspace AND source_path IS NOT NULL"
                    [ "$workspace", box (string workspace) ]

            use sourceReader = sources.ExecuteReader()

            let known =
                [ while sourceReader.Read() do
                      yield sourceReader.GetString 0 ]
                |> List.map (LibraryEncoding.readPath >> LogicalPath.components >> List.head)
                |> Set.ofList

            sourceReader.Close()

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
            rows, known, library, outputRoots, ids.Length > count)

    let private unmanaged
        (root: WorkspaceRoot)
        (known: Set<string>)
        (library: StoredLibrary option)
        (outputRoots: Set<string>)
        limit
        =
        Task.Run(fun () ->
            use directory = HeldDirectory.Open(root.Path, root.Identity)

            let entries = ResizeArray<UnmanagedEntry>()
            let mutable visited = 0
            let mutable limited = false
            use names = directory.Names.GetEnumerator()

            while visited < limit && names.MoveNext() do
                visited <- visited + 1
                let name = names.Current

                if
                    name <> RootIdentityFile.name
                    && not (known.Contains name)
                    && not (outputRoots.Contains name)
                    && not (library |> Option.exists (fun value -> value.Name = name))
                then
                    let kind =
                        try
                            directory.InspectEntry name |> Option.map _.Kind
                        with
                        | :? IOException
                        | :? UnauthorizedAccessException -> Some EntryKind.Other

                    match kind with
                    | None -> ()
                    | Some kind when entries.Count < 32 ->
                        entries.Add
                            { Path =
                                LogicalPath.create [ name ]
                                |> Result.defaultWith (fun _ -> invalidOp "Invalid native name.")
                              Kind = kind }
                    | Some _ -> limited <- true

            if names.MoveNext() then
                limited <- true

            entries |> Seq.toList, limited)

    let run (database: StateDatabase) (access: LibraryAccess) workspace limit =
        task {
            if limit < 1 || limit > 100000 then
                return Error LibraryError.LimitExceeded
            else
                let! root = access.Root workspace

                match root with
                | Error error -> return Error error
                | Ok root ->
                    let! rows, known, library, outputRoots, moreMods =
                        snapshot database workspace limit

                    let! unknown, moreUnknown = unmanaged root known library outputRoots limit
                    let entries = rows |> List.map _.Entry |> InventoryPolicy.inventoryWindow

                    return
                        Ok
                            { Entries = entries
                              Unmanaged = unknown
                              Limited = moreMods || moreUnknown || rows.Length > entries.Length }
        }
