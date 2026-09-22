namespace ModConductor.ModMaintenance

open System
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.ArchiveInstallation

[<RequireQualifiedAccess>]
type UpdateMode =
    | Merge
    | Replace

[<RequireQualifiedAccess>]
type FileChange =
    | Add
    | Replace
    | Remove
    | Keep

type UpdateFile =
    { Path: LogicalPath
      Change: FileChange
      Existing: ManifestEntry list
      Incoming: SelectedFile option
      IncomingBytes: int64 option }

type UpdatePreview =
    { Id: Guid
      DraftId: Guid
      DraftRevision: int64
      Target: ModEntry
      Previous: ModVersion
      Mode: UpdateMode
      Keep: Set<LogicalPath>
      Files: UpdateFile list
      Plan: InstallationPlan
      SourceNotices: string list }
