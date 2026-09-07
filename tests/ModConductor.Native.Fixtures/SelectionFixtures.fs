namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open Microsoft.Data.Sqlite
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.ModOrganization
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces

module SelectionFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private id (number: int) =
        Guid.Parse("00000000-0000-0000-0000-" + number.ToString("D12"))

    let private metadata name =
        { Name = name
          Notes = ""
          Comment = ""
          Version = "1.0"
          Source = ""
          Categories = [] }

    type private Snapshot =
        { Revision: int64
          Entries: ProfileMod list
          EnabledCount: int
          Cursor: QueryCursor }

    let private read (store: OperationStore) profile =
        let page = InventoryObservations.read store profile

        { Revision = page.SelectionRevision
          Entries = page.Entries |> List.map _.Entry
          EnabledCount = page.EnabledCount
          Cursor =
            { CatalogueRevision = page.CatalogueRevision
              SelectionRevision = page.SelectionRevision
              QueryIdentity = page.QueryIdentity
              Offset = 1 } }

    let private positions (page: Snapshot) =
        page.Entries
        |> List.choose (fun row ->
            match row.Selection with
            | SelectionState.Managed(priority, enabled) -> Some(priority, row.Mod.Id, Some enabled)
            | SelectionState.Separator priority -> Some(priority, row.Mod.Id, None)
            | SelectionState.Locked _ -> None)
        |> List.sortBy (fun (priority, _, _) -> priority)

    let private number state sql =
        use connection =
            new SqliteConnection(
                "Data Source=" + Path.Combine(state, "state.db") + ";Pooling=False"
            )

        connection.Open()
        Sqlite.number connection null sql []

    let worker mode state (profileText: string) (modText: string) =
        use store = new OperationStore(state)
        let profile, target = Guid.Parse profileText, Guid.Parse modText
        let page = read store profile

        store.ModSelection.ChangeAtCheckpoint(
            profile,
            page.Revision,
            [ target ],
            SelectionEdit.Enable true,
            if mode = "before" then StorageWorker.pause else ignore
        )
        |> wait
        |> result
        |> ignore

        if mode = "after" then
            StorageWorker.pause ()

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "selection")).FullName
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let root = Directory.CreateDirectory(Path.Combine(area, "root")).FullName

        let workspace, first, second, copy =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        writer.WriteStartObject("selection")
        let mutable persisted = []
        let mutable persistedRevision = 0L

        do
            use store = new OperationStore(state)
            let workspaces = store.Workspaces :> IWorkspaceState
            let library = store.ModLibrary :> IModLibrary
            let selections = store.ModSelection :> IModSelection

            let created =
                workspaces.Create(workspace, "Order fixture", StorageWorker.select root)
                |> wait
                |> result

            let profile =
                workspaces.Edit(
                    workspace,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = first; Name = "First" }
                )
                |> wait
                |> result

            let other =
                workspaces.Edit(
                    workspace,
                    profile.Workspace.Revision,
                    ProfileEdit.Create { Id = second; Name = "Second" }
                )
                |> wait
                |> result

            for index in 1..7 do
                let folder = "mod-" + string index
                Directory.CreateDirectory(Path.Combine(root, folder)) |> ignore

                library.Register(
                    workspace,
                    id index,
                    metadata folder,
                    Registration.Directory(ModKind.Regular, LogicalPath.create [ folder ] |> result)
                )
                |> wait
                |> result
                |> ignore

            library.Register(workspace, id 8, metadata "Divider", Registration.Separator)
            |> wait
            |> result
            |> ignore

            Directory.CreateDirectory(Path.Combine(root, "local")) |> ignore
            let beforeLocked = read store first

            library.Register(
                workspace,
                id 9,
                metadata "Local",
                Registration.Directory(ModKind.Unmanaged, LogicalPath.create [ "local" ] |> result)
            )
            |> wait
            |> result
            |> ignore

            writer.WriteBoolean(
                "membershipInvalidates",
                (store.ModOrganization :> IModOrganization)
                    .Query(first, InventoryObservations.query, Some beforeLocked.Cursor, None)
                |> wait =
                    Error LibraryError.StaleRevision
            )

            let initial = read store first
            let initialPositions = positions initial

            writer.WriteBoolean(
                "disabledAndContiguous",
                initialPositions
                |> List.mapi (fun index (priority, _, enabled) ->
                    priority = index && enabled <> Some true)
                |> List.forall (fun value -> value)
            )

            let enabled =
                selections.Change(
                    first,
                    initial.Revision,
                    [ id 3; id 4; id 7 ],
                    SelectionEdit.Enable true
                )
                |> wait
                |> result

            let moved =
                selections.Change(
                    first,
                    enabled.Revision,
                    [ id 7; id 4; id 3 ],
                    SelectionEdit.MoveUp
                )
                |> wait
                |> result

            let ordered = read store first

            writer.WriteBoolean(
                "stableRuns",
                positions ordered |> List.map (fun (_, id, _) -> id) =
                    [ id 1; id 3; id 4; id 2; id 5; id 7; id 6; id 8 ]
            )

            writer.WriteBoolean(
                "coherentRevision",
                ordered.Revision = initial.Revision + 2L
                && moved.Revision = ordered.Revision
                && ordered.EnabledCount = 3
            )

            let stale =
                selections.Change(
                    first,
                    enabled.Revision,
                    [ id 1; id 2 ],
                    SelectionEdit.Enable true
                )
                |> wait

            writer.WriteBoolean(
                "staleAtomic",
                stale = Error LibraryError.StaleRevision
                && positions (read store first) = positions ordered
            )

            let unsupported =
                selections.Change(first, moved.Revision, [ id 1; id 8 ], SelectionEdit.Enable true)
                |> wait

            let locked =
                selections.Change(first, moved.Revision, [ id 1; id 9 ], SelectionEdit.MoveDown)
                |> wait

            let unchanged = read store first

            writer.WriteBoolean(
                "constraintsAtomic",
                unsupported = Error LibraryError.UnsupportedAction
                && locked = Error LibraryError.UnsupportedAction
                && unchanged.Revision = moved.Revision
                && positions unchanged = positions ordered
            )

            let returned =
                selections.Change(
                    first,
                    moved.Revision,
                    [ id 7; id 3; id 4 ],
                    SelectionEdit.MoveDown
                )
                |> wait
                |> result

            writer.WriteBoolean(
                "downRestoresOrder",
                positions (read store first) |> List.map (fun (_, id, _) -> id) =
                    [ for i in 1..8 -> id i ]
            )

            selections.Change(first, returned.Revision, [ id 8 ], SelectionEdit.MoveUp)
            |> wait
            |> result
            |> ignore

            let source = read store first

            writer.WriteBoolean(
                "separatorMoves",
                positions source |> List.map (fun (_, id, _) -> id) =
                    [ id 1; id 2; id 3; id 4; id 5; id 6; id 8; id 7 ]
            )

            writer.WriteBoolean(
                "profileIsolation",
                positions (read store second) = initialPositions
            )

            let cloned =
                workspaces.Edit(
                    workspace,
                    other.Workspace.Revision,
                    ProfileEdit.Clone(first, { Id = copy; Name = "Copy" })
                )
                |> wait
                |> result

            writer.WriteBoolean("cloneCopies", positions (read store copy) = positions source)

            workspaces.Edit(workspace, cloned.Workspace.Revision, ProfileEdit.Delete copy)
            |> wait
            |> result
            |> ignore

            writer.WriteBoolean(
                "deleteCleans",
                number
                    state
                    ("SELECT count(*) FROM profile_mods WHERE profile_id='" + string copy + "'") = 0L
                && ((store.ModOrganization :> IModOrganization)
                        .Query(copy, InventoryObservations.query, None, None)
                    |> wait = Error LibraryError.NotFound)
            )

            let current = workspaces.Read(workspace, None) |> wait |> result

            writer.WriteBoolean(
                "currentDeleteRefused",
                workspaces.Edit(workspace, current.Workspace.Revision, ProfileEdit.Delete first)
                |> wait =
                    Error WorkspaceError.SelectedProfile
            )

            persisted <- positions source
            persistedRevision <- source.Revision

        do
            use store = new OperationStore(state)
            let restored = read store first

            writer.WriteBoolean(
                "restartPreserves",
                positions restored = persisted && restored.Revision = persistedRevision
            )

        for mode in [ "before"; "after" ] do
            use child =
                new NativeChild(
                    Environment.ProcessPath,
                    [ "--selection-worker"; mode; state; string first; string (id 1) ]
                )

            if child.Line() <> "ready" then
                invalidOp "The selection checkpoint was not reached."

            child.Terminate()
            use store = new OperationStore(state)
            let restored = read store first

            writer.WriteBoolean(
                mode + "Commit",
                if mode = "before" then
                    positions restored = persisted && restored.Revision = persistedRevision
                else
                    restored.Revision = persistedRevision + 1L && restored.EnabledCount = 4
            )

        let migration = Directory.CreateDirectory(Path.Combine(area, "migration")).FullName

        File.Copy(
            Path.Combine(AppContext.BaseDirectory, "fixtures", "state-v4.db"),
            Path.Combine(migration, "state.db")
        )

        do
            use child =
                new NativeChild(
                    Environment.ProcessPath,
                    [ "--storage-worker"; "migration"; migration; root; string workspace ]
                )

            if child.Line() <> "ready" then
                invalidOp "The migration checkpoint was not reached."

            child.Terminate()

        writer.WriteBoolean(
            "migrationRollback",
            number migration "PRAGMA user_version" = 4L
            && number migration "SELECT count(*) FROM profiles" = 2L
        )

        do
            use upgraded = new OperationStore(migration)

            writer.WriteBoolean(
                "migrationPreserves",
                number migration "SELECT count(*) FROM profile_mods" = 8L
                && number migration "SELECT count(*) FROM profile_mods WHERE enabled=1" = 0L
                && number migration "SELECT count(*) FROM profile_mods WHERE enabled IS NULL" = 2L
                && number migration "SELECT count(*) FROM profiles WHERE selection_revision=0" = 2L
                && number migration "SELECT count(*) FROM profiles WHERE name IN ('First','Second')" = 2L
            )

        writer.WriteEndObject()
