namespace ModConductor.Engine

open ModConductor.ModOrganization
open ModConductor.Protocol.V1

type ModOrganizationService(organization: IModOrganization) =
    inherit ModOrganizationOperations.ModOrganizationOperationsBase()

    override _.ReadLoadOrderLayout(request, _) =
        task {
            let! result = organization.LoadOrderLayout(ModLibraryWire.id request.ProfileId)

            return
                match result with
                | Error error -> LoadOrderLayoutReply(Fault = OrganizationWire.fault error)
                | Ok entries ->
                    let layout = LoadOrderLayout()
                    layout.Entries.AddRange entries
                    LoadOrderLayoutReply(Layout = layout)
        }

    override _.SaveLoadOrderLayout(request, _) =
        task {
            let! result =
                organization.SaveLoadOrderLayout(
                    ModLibraryWire.id request.ProfileId,
                    request.Entries |> Seq.toList
                )

            return OrganizationWire.changed (result |> Result.map (fun () -> 0L))
        }

    override _.ChangeModOrganization(request, _) =
        task {
            let edit =
                match request.EditCase with
                | ChangeModOrganizationRequest.EditOneofCase.Move ->
                    match request.Move with
                    | ProfileModMove.Up -> OrganizationEdit.MoveUp
                    | ProfileModMove.Down -> OrganizationEdit.MoveDown
                    | _ -> ModLibraryWire.reject "Choose a move direction."
                | ChangeModOrganizationRequest.EditOneofCase.GroupId ->
                    OrganizationEdit.Group(ModLibraryWire.id request.GroupId)
                | _ -> ModLibraryWire.reject "Choose an organization action."

            let! result =
                organization.Change(
                    ModLibraryWire.id request.ProfileId,
                    ModLibraryWire.number request.ExpectedRevision,
                    request.ModIds |> Seq.map ModLibraryWire.id |> Seq.toList,
                    edit
                )

            return OrganizationWire.changed result
        }

    override _.ReadCategories(request, _) =
        task {
            let! result =
                organization.Categories(
                    ModLibraryWire.id request.WorkspaceId,
                    (if request.HasParentId then
                         Some(ModLibraryWire.id request.ParentId)
                     else
                         None),
                    (if request.HasAfterId then
                         Some(ModLibraryWire.id request.AfterId)
                     else
                         None),
                    (if request.HasExpectedRevision then
                         Some(ModLibraryWire.number request.ExpectedRevision)
                     else
                         None)
                )

            return
                match result with
                | Error error -> CategoriesReply(Fault = OrganizationWire.fault error)
                | Ok value ->
                    let page = CategoriesPage(Revision = uint64 value.Revision)
                    page.Entries.AddRange(value.Entries |> Seq.map OrganizationWire.category)
                    page.Ancestors.AddRange(value.Ancestors |> Seq.map OrganizationWire.category)
                    value.NextId |> Option.iter (fun id -> page.NextId <- id.ToString("N"))
                    CategoriesReply(Page = page)
        }

    override _.EditCategory(request, _) =
        task {
            let! result =
                organization.EditCategory(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.number request.ExpectedRevision,
                    OrganizationWire.edit request
                )

            return OrganizationWire.changed result
        }

    override _.QueryMods(request, _) =
        task {
            let! result =
                organization.Query(
                    ModLibraryWire.id request.ProfileId,
                    OrganizationWire.query request.Query,
                    OrganizationWire.cursor request.Cursor,
                    (if request.HasInspectedModId then
                         Some(ModLibraryWire.id request.InspectedModId)
                     else
                         None)
                )

            return
                match result with
                | Error error -> ModQueryReply(Fault = OrganizationWire.fault error)
                | Ok value ->
                    let page =
                        ModQueryPage(
                            CatalogueRevision = uint64 value.CatalogueRevision,
                            SelectionRevision = uint64 value.SelectionRevision,
                            QueryIdentity = value.QueryIdentity,
                            MatchingMods = uint32 value.MatchingMods,
                            MatchingSeparators = uint32 value.MatchingSeparators,
                            MatchingGroups = uint32 value.MatchingGroups,
                            TotalMods = uint32 value.TotalMods,
                            EnabledCount = uint32 value.EnabledCount
                        )

                    page.Entries.AddRange(value.Entries |> Seq.map OrganizationWire.row)
                    page.Context.AddRange(value.Context |> Seq.map OrganizationWire.row)

                    value.Inspected
                    |> Option.iter (fun row -> page.Inspected <- OrganizationWire.row row)

                    value.Next
                    |> Option.iter (fun cursor -> page.Next <- OrganizationWire.next cursor)

                    ModQueryReply(Page = page)
        }
