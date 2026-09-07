namespace ModConductor.ModSelection

open System
open System.Threading.Tasks
open ModConductor.ModLibrary

[<RequireQualifiedAccess>]
type SelectionRestriction =
    | Backup
    | Unmanaged
    | Automatic

[<RequireQualifiedAccess>]
type SelectionState =
    | Managed of priority: int * enabled: bool
    | Separator of priority: int
    | Locked of SelectionRestriction

type OrderedMod =
    { Id: Guid
      Priority: int
      Enabled: bool option }

type ProfileMod =
    { Mod: ModEntry
      Selection: SelectionState }

type ProfileModPage =
    { Revision: int64
      Entries: ProfileMod list
      NextMod: Guid option
      Total: int
      EnabledCount: int }

type ProfileModDetail = { Revision: int64; Entry: ProfileMod }

[<RequireQualifiedAccess>]
type SelectionEdit =
    | Enable of bool
    | MoveUp
    | MoveDown

type SelectionDelta =
    { Revision: int64
      Changed: OrderedMod list
      EnabledCount: int }

type IModSelection =
    abstract Read: Guid * Guid option * int64 option -> Task<Result<ProfileModPage, LibraryError>>
    abstract Find: Guid * Guid * int64 option -> Task<Result<ProfileModDetail, LibraryError>>

    abstract Change:
        Guid * int64 * Guid list * SelectionEdit -> Task<Result<SelectionDelta, LibraryError>>
