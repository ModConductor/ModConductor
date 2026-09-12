namespace ModConductor.ArchiveInstallation

open System
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.Platform

type SelectedFile =
    { Index: int; Destination: LogicalPath }

type InstallationPlan =
    { Artifact: ArtifactRef
      ArchiveName: string
      Sha256: string
      Name: string
      Version: string
      Root: string list
      Files: SelectedFile list
      Bytes: int64
      Fingerprint: string }

type InstallationDraft =
    { Id: Guid
      Revision: int64
      Artifact: ArtifactRef
      ArchiveName: string
      Manifest: ArchiveManifest
      Root: string list
      Files: SelectedFile list
      Name: string
      Version: string
      Plan: InstallationPlan option }

[<RequireQualifiedAccess>]
type LayoutChange =
    | Root of string list
    | Include of path: string list * included: bool
    | Destination of source: string list * destination: string list
    | Metadata of name: string * version: string

[<RequireQualifiedAccess>]
type InstallationState =
    | Running
    | Stopped
    | Complete
    | Discarded

type Installation =
    { Id: Guid
      WorkspaceId: Guid
      ArtifactId: Guid
      ArchiveName: string
      Name: string
      Version: string
      State: InstallationState
      Files: int
      TotalFiles: int
      Bytes: int64
      TotalBytes: int64
      TemporaryBytes: int64 option
      Problem: string option
      ModId: Guid option
      VersionId: Guid option }

type InstallationException(message: string) =
    inherit Exception(message)
