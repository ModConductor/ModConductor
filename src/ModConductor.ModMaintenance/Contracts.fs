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

[<RequireQualifiedAccess>]
type DeletionFileKind =
    | Payload
    | Archive
    | Temporary
    | GenerationLink

type DeletionFile =
    { Label: string
      Kind: DeletionFileKind
      Bytes: int64 option
      Shared: bool }

type DeletionProfile = { Id: Guid; Name: string }

type DeletionDeployment =
    { ContextId: Guid
      Id: Guid
      Name: string
      PreparedAt: DateTimeOffset option
      Active: bool }

type DeletionPreview =
    { Id: Guid
      WorkspaceId: Guid
      ModId: Guid
      Revision: int64
      Name: string
      Versions: int
      Backups: string list
      Profiles: DeletionProfile list
      Deployments: DeletionDeployment list
      Files: DeletionFile list
      External: string list
      Blocked: string option }

[<RequireQualifiedAccess>]
type DeletionPhase =
    | Running
    | Incomplete
    | Complete

type DeletionStatus =
    { Id: Guid
      WorkspaceId: Guid
      ModId: Guid
      Name: string
      Phase: DeletionPhase
      Remaining: int
      Problem: string option }
