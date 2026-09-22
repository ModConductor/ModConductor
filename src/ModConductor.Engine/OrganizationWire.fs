namespace ModConductor.Engine

open ModConductor.ModLibrary
open ModConductor.ModOrganization
open ModConductor.Protocol.V1

module internal OrganizationWire =
    let category (value: Category) =
        let result =
            ModCategory(
                CategoryId = value.Id.ToString("N"),
                WorkspaceId = value.WorkspaceId.ToString("N"),
                Label = value.Label,
                Missing = value.Missing,
                AssignedCount = uint32 value.AssignedCount,
                HasChildren = value.HasChildren
            )

        value.ParentId |> Option.iter (fun id -> result.ParentId <- id.ToString("N"))
        result

    let definition (value: CategoryDefinition) =
        ModLibraryWire.id value.CategoryId,
        (if value.HasParentId then
             Some(ModLibraryWire.id value.ParentId)
         else
             None),
        value.Label

    let edit (value: EditCategoryRequest) =
        match value.EditCase with
        | EditCategoryRequest.EditOneofCase.Create -> CategoryEdit.Create(definition value.Create)
        | EditCategoryRequest.EditOneofCase.Update -> CategoryEdit.Update(definition value.Update)
        | EditCategoryRequest.EditOneofCase.DeleteId ->
            CategoryEdit.Delete(ModLibraryWire.id value.DeleteId)
        | _ -> ModLibraryWire.reject "Choose a category change."

    let fault error =
        let result = ModLibraryWire.fault error

        match error with
        | LibraryError.StaleRevision ->
            result.Detail <- "The mods or categories changed. Reload them."
        | LibraryError.NotFound ->
            result.Detail <- "The workspace, profile or category was not found."
        | LibraryError.IdentityConflict ->
            result.Detail <- "This name or ID already belongs to another item."
        | LibraryError.UnsupportedAction ->
            result.Detail <- "Move or delete the child categories first."
        | LibraryError.InvalidMetadata
        | LibraryError.InvalidSource
        | LibraryError.UnprovedOwnership
        | LibraryError.SourceChanged
        | LibraryError.Busy _
        | LibraryError.LimitExceeded
        | LibraryError.FileUnavailable
        | LibraryError.Cancelled -> ()

        result

    let changed (result: Result<int64, LibraryError>) =
        match result with
        | Error error -> OrganizationChangeReply(Fault = fault error)
        | Ok revision ->
            OrganizationChangeReply(Changed = OrganizationRevision(Revision = uint64 revision))

    let predicate (value: ModFilterPredicate) =
        match value.PredicateCase with
        | ModFilterPredicate.PredicateOneofCase.Category ->
            if isNull value.Category.Category then
                ModLibraryWire.reject "Choose a category."

            ModFilter.Category(
                ModLibraryWire.categoryReference value.Category.Category,
                value.Category.Descendants
            )
        | ModFilterPredicate.PredicateOneofCase.Kind ->
            ModFilter.Kind(
                match value.Kind with
                | InventoryModKind.Regular -> ModKind.Regular
                | InventoryModKind.Separator -> ModKind.Separator
                | InventoryModKind.Backup -> ModKind.Backup
                | InventoryModKind.Unmanaged -> ModKind.Unmanaged
                | InventoryModKind.GeneratedOutput -> ModKind.GeneratedOutput
                | _ -> ModLibraryWire.reject "Choose a mod kind."
            )
        | ModFilterPredicate.PredicateOneofCase.Status ->
            ModFilter.Status(
                match value.Status with
                | ModInventoryStatus.Ready -> InventoryStatus.Ready
                | ModInventoryStatus.Detached -> InventoryStatus.Detached
                | ModInventoryStatus.Changed -> InventoryStatus.Changed
                | ModInventoryStatus.Unproved -> InventoryStatus.Unproved
                | ModInventoryStatus.Publishing -> InventoryStatus.Publishing
                | ModInventoryStatus.Deleting -> InventoryStatus.Deleting
                | _ -> ModLibraryWire.reject "Choose a mod status."
            )
        | ModFilterPredicate.PredicateOneofCase.Enabled ->
            ModFilter.Enabled(
                match value.Enabled with
                | ModEnabledFilter.Yes -> Some true
                | ModEnabledFilter.No -> Some false
                | ModEnabledFilter.NotApplicable -> None
                | _ -> ModLibraryWire.reject "Choose an enabled filter."
            )
        | ModFilterPredicate.PredicateOneofCase.Uncategorized when value.Uncategorized ->
            ModFilter.Uncategorized
        | ModFilterPredicate.PredicateOneofCase.MissingCategory when value.MissingCategory ->
            ModFilter.MissingCategory
        | _ -> ModLibraryWire.reject "Choose a filter."

    let query (value: ModQueryDefinition) =
        if isNull value then
            ModLibraryWire.reject "Choose how to show mods."

        { Text = value.Text
          Mode =
            match value.Mode with
            | ModFilterMode.All -> FilterMode.All
            | ModFilterMode.Any -> FilterMode.Any
            | _ -> ModLibraryWire.reject "Choose All or Any filters."
          Filters = value.Filters |> Seq.map predicate |> Seq.toList
          View =
            match value.View with
            | ModQueryView.Flat -> OrganizationView.Flat
            | ModQueryView.Groups -> OrganizationView.Groups
            | _ -> ModLibraryWire.reject "Choose a view."
          Sort =
            match value.Sort with
            | ModQuerySort.Priority -> OrganizationSort.Priority
            | ModQuerySort.Name -> OrganizationSort.Name
            | _ -> ModLibraryWire.reject "Choose a sort order." }

    let cursor (value: ModQueryCursor) : QueryCursor option =
        if isNull value then
            None
        else
            Some
                { CatalogueRevision = ModLibraryWire.number value.CatalogueRevision
                  SelectionRevision = ModLibraryWire.number value.SelectionRevision
                  QueryIdentity = value.QueryIdentity
                  Offset = ModLibraryWire.count value.Offset }

    let next (value: QueryCursor) =
        ModQueryCursor(
            CatalogueRevision = uint64 value.CatalogueRevision,
            SelectionRevision = uint64 value.SelectionRevision,
            QueryIdentity = value.QueryIdentity,
            Offset = uint32 value.Offset
        )

    let row (value: OrganizedMod) =
        let result =
            OrganizedModView(
                Entry =
                    ProfileModView(
                        Mod = ModLibraryWire.entry value.Entry.Mod,
                        Selection =
                            ProfileModWire.selection value.Entry.Mod.Id value.Entry.Selection
                    )
            )

        value.GroupId |> Option.iter (fun id -> result.GroupId <- id.ToString("N"))

        value.GroupSize
        |> Option.iter (fun size ->
            result.GroupSize <-
                SeparatorGroupSize(Matching = uint32 size.Matching, Total = uint32 size.Total))

        result
