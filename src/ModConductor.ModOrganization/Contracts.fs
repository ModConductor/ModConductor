namespace ModConductor.ModOrganization

open System
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.ModSelection

type Category =
    { Id: Guid
      WorkspaceId: Guid
      ParentId: Guid option
      Label: string
      Missing: bool
      AssignedCount: int
      HasChildren: bool }

type CategoryPage =
    { Revision: int64
      Entries: Category list
      Ancestors: Category list
      NextId: Guid option }

[<RequireQualifiedAccess>]
type CategoryEdit =
    | Create of Guid * Guid option * string
    | Update of Guid * Guid option * string
    | Delete of Guid

[<RequireQualifiedAccess>]
type ModFilter =
    | Category of CategoryReference * descendants: bool
    | Kind of ModKind
    | Status of InventoryStatus
    | Enabled of bool option
    | Uncategorized
    | MissingCategory

[<RequireQualifiedAccess>]
type FilterMode =
    | All
    | Any

[<RequireQualifiedAccess>]
type OrganizationView =
    | Flat
    | Groups

[<RequireQualifiedAccess>]
type OrganizationSort =
    | Priority
    | Name

type ModQuery =
    { Text: string
      Mode: FilterMode
      Filters: ModFilter list
      View: OrganizationView
      Sort: OrganizationSort }

type QueryCursor =
    { CatalogueRevision: int64
      SelectionRevision: int64
      QueryIdentity: string
      Offset: int }

type GroupSize = { Matching: int; Total: int }

type OrganizedMod =
    { Entry: ProfileMod
      GroupId: Guid option
      GroupSize: GroupSize option }

type ModQueryPage =
    { CatalogueRevision: int64
      SelectionRevision: int64
      QueryIdentity: string
      Entries: OrganizedMod list
      Context: OrganizedMod list
      Inspected: OrganizedMod option
      Next: QueryCursor option
      MatchingMods: int
      MatchingSeparators: int
      MatchingGroups: int
      TotalMods: int
      EnabledCount: int }

type IModOrganization =
    abstract Categories:
        Guid * Guid option * Guid option * int64 option -> Task<Result<CategoryPage, LibraryError>>

    abstract EditCategory: Guid * int64 * CategoryEdit -> Task<Result<int64, LibraryError>>

    abstract Query:
        Guid * ModQuery * QueryCursor option * Guid option ->
            Task<Result<ModQueryPage, LibraryError>>
