namespace ModConductor.Engine

open ModConductor.ModOrganization
open ModConductor.Protocol.V1

type ModOrganizationService(organization: IModOrganization) =
    inherit ModOrganizationOperations.ModOrganizationOperationsBase()

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
