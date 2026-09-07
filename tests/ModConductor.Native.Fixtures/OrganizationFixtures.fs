namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.ModOrganization
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces

module OrganizationFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private metadata name =
        { Name = name
          Notes = ""
          Comment = ""
          Version = "1.0"
          Source = ""
          Categories = [] }

    let private query =
        { Text = ""
          Mode = FilterMode.All
          Filters = []
          View = OrganizationView.Flat
          Sort = OrganizationSort.Priority }

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "organization")).FullName
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let root = Directory.CreateDirectory(Path.Combine(area, "root")).FullName
        use store = new OperationStore(state)
        let workspaces = store.Workspaces :> IWorkspaceState
        let library = store.ModLibrary :> IModLibrary
        let organization = store.ModOrganization :> IModOrganization
        let selection = store.ModSelection :> IModSelection

        let workspace, profile, otherProfile =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let created =
            workspaces.Create(workspace, "Categories", StorageWorker.select root)
            |> wait
            |> result

        let first =
            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "One" }
            )
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            first.Workspace.Revision,
            ProfileEdit.Create { Id = otherProfile; Name = "Two" }
        )
        |> wait
        |> result
        |> ignore

        let categories parent =
            organization.Categories(workspace, parent, None, None) |> wait |> result

        let edit command =
            organization.EditCategory(workspace, (categories None).Revision, command)
            |> wait
            |> result

        let cat, child, other = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        edit (CategoryEdit.Create(cat, None, "Textures")) |> ignore
        edit (CategoryEdit.Create(child, Some cat, "Stone")) |> ignore
        edit (CategoryEdit.Create(other, None, "textures")) |> ignore

        let reference id label =
            { Id = id
              Label = label
              Missing = false }

        let add name kind refs =
            let id = Guid.NewGuid()

            let registration =
                if kind = ModKind.Separator then
                    Registration.Separator
                else
                    Directory.CreateDirectory(Path.Combine(root, name)) |> ignore
                    Registration.Directory(kind, LogicalPath.create [ name ] |> result)

            library.Register(workspace, id, { metadata name with Categories = refs }, registration)
            |> wait
            |> result

        let leading = add "Leading" ModKind.Regular []
        let group = add "Visual" ModKind.Separator []
        let stone = add "Stonework" ModKind.Regular [ reference child "outdated" ]
        let colors = add "Colors" ModKind.Regular [ reference other "textures" ]
        let empty = add "Empty" ModKind.Separator []

        let read filter =
            organization.Query(profile, filter, None, Some colors.Id) |> wait |> result

        let initial = read query

        let changed =
            selection.Change(
                profile,
                initial.SelectionRevision,
                [ stone.Id ],
                SelectionEdit.Enable true
            )
            |> wait
            |> result

        let categoryFilter = ModFilter.Category(reference cat "Textures", true)

        let combined =
            { query with
                View = OrganizationView.Groups
                Text = "STONE"
                Filters = [ categoryFilter; ModFilter.Enabled(Some true) ] }

        let filtered = read combined
        writer.WriteStartObject("organization")

        writer.WriteBoolean(
            "combinedAndContext",
            filtered.Entries |> List.map (fun row -> row.Entry.Mod.Id) = [ stone.Id ]
            && filtered.Context |> List.map (fun row -> row.Entry.Mod.Id) = [ group.Id ]
            && filtered.MatchingMods = 1
            && filtered.MatchingSeparators = 0
            && filtered.Inspected.Value.Entry.Mod.Id = colors.Id
        )

        writer.WriteBoolean(
            "filterPreservesSelection",
            filtered.SelectionRevision = changed.Revision
            && (read query).SelectionRevision = changed.Revision
        )

        let any =
            read
                { query with
                    Mode = FilterMode.Any
                    Filters =
                        [ categoryFilter; ModFilter.Category(reference other "textures", false) ] }

        writer.WriteBoolean(
            "anyCategoryMembership",
            any.Entries |> List.map (fun row -> row.Entry.Mod.Id) |> Set.ofList =
                Set.ofList [ stone.Id; colors.Id ]
        )

        let emptyGroups =
            read
                { query with
                    View = OrganizationView.Groups
                    Text = "Empty" }

        writer.WriteBoolean(
            "trailingEmptyGroup",
            emptyGroups.Entries |> List.map (fun row -> row.Entry.Mod.Id) = [ empty.Id ]
            && emptyGroups.MatchingSeparators = 1
        )

        let before = (categories None).Revision

        let cycle =
            organization.EditCategory(
                workspace,
                before,
                CategoryEdit.Update(cat, Some child, "Textures")
            )
            |> wait

        let deletion =
            organization.EditCategory(workspace, before, CategoryEdit.Delete cat) |> wait

        writer.WriteBoolean(
            "treeAtomic",
            cycle = Error LibraryError.InvalidMetadata
            && deletion = Error LibraryError.UnsupportedAction
            && (categories None).Revision = before
        )

        let canonical =
            (read query).Entries
            |> List.find (fun row -> row.Entry.Mod.Id = stone.Id)
            |> _.Entry.Mod

        writer.WriteBoolean("canonicalLabel", canonical.Metadata.Categories.Head.Label = "Stone")
        edit (CategoryEdit.Update(child, Some cat, "Stone surfaces")) |> ignore

        let stale =
            library.Edit(
                stone.Id,
                canonical.Revision,
                { canonical.Metadata with
                    Notes = "old draft" }
            )
            |> wait

        let renamed =
            (read query).Entries
            |> List.find (fun row -> row.Entry.Mod.Id = stone.Id)
            |> _.Entry.Mod

        edit (CategoryEdit.Delete child) |> ignore

        let missing =
            (read
                { query with
                    Filters = [ ModFilter.MissingCategory ] })
                .Entries
            |> List.exactlyOne
            |> _.Entry.Mod

        let preserved =
            library.Edit(
                missing.Id,
                missing.Revision,
                { missing.Metadata with
                    Comment = "keep unresolved" }
            )
            |> wait
            |> result

        writer.WriteBoolean(
            "draftAndMissingPreservation",
            stale = Error LibraryError.StaleRevision
            && renamed.Metadata.Categories.Head.Label = "Stone surfaces"
            && preserved.Metadata.Categories.Head.Id = child
            && preserved.Metadata.Categories.Head.Missing
            && preserved.Metadata.Categories.Head.Label = "Stone surfaces"
        )

        let otherSnapshot =
            organization.Query(
                otherProfile,
                { query with
                    Filters = [ ModFilter.MissingCategory ] },
                None,
                None
            )
            |> wait
            |> result

        writer.WriteBoolean(
            "workspaceSharedProfileIndependent",
            otherSnapshot.Entries.Head.Entry.Mod.Id = stone.Id
            && otherSnapshot.EnabledCount = 0
        )

        for index in 1..36 do
            add ("More " + string index) ModKind.Regular [] |> ignore

        let firstPage = read query
        let next = firstPage.Next |> Option.get

        let otherBefore =
            organization.Query(otherProfile, query, None, None) |> wait |> result

        selection.Change(
            otherProfile,
            otherBefore.SelectionRevision,
            [ leading.Id ],
            SelectionEdit.MoveUp
        )
        |> wait
        |> result
        |> ignore

        let crossProfile = organization.Query(otherProfile, query, Some next, None) |> wait

        let otherSynced =
            organization.Query(otherProfile, query, None, None) |> wait |> result

        writer.WriteBoolean(
            "profileCursorIsolated",
            otherSynced.SelectionRevision = firstPage.SelectionRevision
            && crossProfile = Error LibraryError.StaleRevision
        )

        let secondPage =
            organization.Query(profile, query, Some next, None) |> wait |> result

        let allIds =
            firstPage.Entries @ secondPage.Entries |> List.map (fun row -> row.Entry.Mod.Id)

        writer.WriteBoolean(
            "boundedContinuation",
            firstPage.Entries.Length < allIds.Length
            && Set.count (Set.ofList allIds) = allIds.Length
            && secondPage.Next.IsNone
        )

        let wrongQuery =
            organization.Query(profile, { query with Mode = FilterMode.Any }, Some next, None)
            |> wait

        let metadataPage = read query

        let currentLeading =
            metadataPage.Entries
            |> List.find (fun row -> row.Entry.Mod.Id = leading.Id)
            |> _.Entry.Mod

        library.Edit(
            currentLeading.Id,
            currentLeading.Revision,
            { currentLeading.Metadata with
                Notes = "changed by another metadata editor" }
        )
        |> wait
        |> result
        |> ignore

        let metadataStale =
            organization.Query(profile, query, metadataPage.Next, None) |> wait

        let inventoryPage = read query

        writer.WriteBoolean(
            "metadataInvalidatesWithoutSelectionChange",
            metadataStale = Error LibraryError.StaleRevision
            && inventoryPage.SelectionRevision = metadataPage.SelectionRevision
        )

        add "Unmanaged" ModKind.Unmanaged [] |> ignore
        let stalePage = organization.Query(profile, query, inventoryPage.Next, None) |> wait

        let orderedFirst = read query

        let orderedRest =
            organization.Query(profile, query, orderedFirst.Next, None) |> wait |> result

        let priorities =
            orderedFirst.Entries @ orderedRest.Entries
            |> List.map (fun row ->
                match row.Entry.Selection with
                | SelectionState.Managed(priority, _)
                | SelectionState.Separator priority -> Some priority
                | SelectionState.Locked _ -> None)

        writer.WriteBoolean(
            "lockedRowsFollowSavedOrder",
            priorities |> List.take (priorities.Length - 1) |> List.forall Option.isSome
            && (priorities |> List.last).IsNone
        )

        writer.WriteBoolean(
            "queryAndInventoryInvalidate",
            wrongQuery = Error LibraryError.StaleRevision
            && stalePage = Error LibraryError.StaleRevision
        )

        let removed =
            library.Edit(
                preserved.Id,
                preserved.Revision,
                { preserved.Metadata with
                    Categories = [] }
            )
            |> wait
            |> result

        writer.WriteBoolean("explicitReferenceRemoval", removed.Metadata.Categories.IsEmpty)
        writer.WriteEndObject()
