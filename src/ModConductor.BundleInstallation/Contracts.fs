namespace ModConductor.BundleInstallation

open System
open ModConductor.Platform
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInspection

[<RequireQualifiedAccess>]
type ModState =
    | NeedsReview
    | Installed
    | Failed
    | Installing

type BundleRef =
    { WorkspaceId: Guid
      Id: Guid
      Revision: int64 }

type Candidate =
    { Index: int
      Path: LogicalPath
      Length: int64 }

type BundleMod =
    { Id: Guid
      SourceId: Guid
      ModId: Guid
      Name: string
      Order: int
      Path: LogicalPath list
      Length: int64
      State: ModState
      IncompleteArchive: bool
      Attempt: Guid option
      Problem: string option }

type Bundle =
    { Reference: BundleRef
      Artifact: ArtifactRef
      ArchiveName: string
      Mods: BundleMod list
      TemporaryBytes: int64
      Problem: string option }

type BundleException(message: string) =
    inherit Exception(message)

module Budgets =
    let nesting = 3
    let sources = 32
    let entries = 20000
    let expansion = 64L * 1024L * 1024L * 1024L

    let check depth count entryCount bytes =
        if depth > nesting then
            raise (BundleException "This bundle exceeds 3 nested archive levels.")

        if count > sources then
            raise (BundleException "This bundle exceeds 32 archives.")

        if entryCount > entries then
            raise (BundleException "This bundle exceeds 20,000 file entries.")

        if bytes > expansion then
            raise (BundleException "This bundle exceeds 64 GB of total expansion.")
