namespace ModConductor.ModOrganization

open System
open System.Collections.Generic
open System.Globalization
open System.IO
open System.Text
open System.Threading
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform
open ModConductor.Workspaces

[<RequireQualifiedAccess>]
type InventoryExportScope =
    | Selected
    | Enabled
    | CurrentQuery
    | All

[<RequireQualifiedAccess>]
type InventoryExportField =
    | ModId
    | Name
    | Kind
    | Status
    | Priority
    | Enabled
    | Version
    | Source
    | SourcePath
    | Notes
    | Comment
    | Categories

type InventoryExportCapture =
    { WorkspaceId: Guid
      WorkspaceRevision: int64
      ProfileId: Guid
      Scope: InventoryExportScope
      SelectedModIds: Guid list
      Query: ModQuery
      QueryIdentity: string
      CatalogueRevision: int64
      SelectionRevision: int64
      Fields: InventoryExportField list }

type PreparedInventoryExport =
    { Id: Guid
      RowCount: int
      Fields: InventoryExportField list }

type InventoryExportDestination =
    { Id: Guid
      FileName: string
      Exists: bool }

type InventoryExportProgress = { Written: int; Total: int }

type InventoryExportResult =
    { FileName: string
      RowCount: int
      Length: int64 }

[<RequireQualifiedAccess>]
type InventoryExportError =
    | InvalidRequest
    | NotFound
    | Stale
    | Busy
    | LimitExceeded
    | DestinationUnavailable
    | DestinationChanged
    | ReplacementRequired
    | Cancelled
    | WriteFailed
