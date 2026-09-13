namespace ModConductor.ArchiveInstallation

open System
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.Platform
open ModConductor.ModLibrary

type SelectedFile =
    { Index: int; Destination: LogicalPath }

type ReviewedFile =
    { File: SelectedFile
      Source: LogicalPath
      Choice: string
      Replaces: LogicalPath list }

[<RequireQualifiedAccess>]
type InstallationMode =
    | Manual
    | Fomod
    | Bain

type BundleDestination =
    { BundleId: Guid
      ItemId: Guid
      ModId: Guid }

type InstallationTarget =
    { ModId: Guid
      Revision: int64
      PreviousVersion: Guid
      Existing: ManifestEntry list }

type InstallationPlan =
    { Artifact: ArtifactRef
      ArchiveName: string
      Nested: NestedArchiveRef option
      Bundle: BundleDestination option
      Sha256: string
      Name: string
      Version: string
      Root: string list
      Files: SelectedFile list
      Bytes: int64
      Fingerprint: string
      Target: InstallationTarget option }

type InstallationDraft =
    { Id: Guid
      Revision: int64
      Artifact: ArtifactRef
      ArchiveName: string
      Nested: NestedArchiveRef option
      Bundle: BundleDestination option
      Manifest: ArchiveManifest
      Root: string list
      Files: SelectedFile list
      Name: string
      Version: string
      Plan: InstallationPlan option
      Installer: InstallationMode
      AvailableInstallers: InstallationMode list
      WizardScripts: LogicalPath list }

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
      IsUpdate: bool
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
