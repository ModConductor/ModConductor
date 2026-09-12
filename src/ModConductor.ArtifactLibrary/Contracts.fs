namespace ModConductor.ArtifactLibrary

open System
open System.Threading
open System.Threading.Tasks

[<RequireQualifiedAccess>]
type ArtifactStorage =
    | Reference
    | Copy

[<RequireQualifiedAccess>]
type ArtifactState =
    | Incomplete
    | Ready
    | Detached
    | Installed

type ArtifactLink =
    { ModId: Guid
      VersionId: Guid
      ModName: string
      VersionLabel: string }

type ArtifactLinkPage =
    { Entries: ArtifactLink list
      Next: Guid option }

type Artifact =
    { Id: Guid
      WorkspaceId: Guid
      Revision: int64
      OriginalName: string
      OriginalPath: string
      Path: string
      Storage: ArtifactStorage
      State: ArtifactState
      Length: int64 option
      Sha256: string option
      Problem: string option
      Links: ArtifactLink list
      CanRetry: bool
      CanLocate: bool
      CanDeleteCopy: bool
      CanRemove: bool }

type ArtifactPage =
    { Entries: Artifact list
      Next: Guid option }

[<RequireQualifiedAccess>]
type ArtifactError =
    | NotFound
    | Stale
    | Busy
    | Conflict
    | InvalidLink
    | Linked
    | Unavailable
    | Cancelled

type ArtifactRegistration =
    { Id: Guid
      WorkspaceId: Guid
      Path: string
      Storage: ArtifactStorage }

type ArtifactRef =
    { WorkspaceId: Guid
      Id: Guid
      Revision: int64 }

type IArtifactLibrary =
    abstract List:
        Guid * Guid option * bool * CancellationToken -> Task<Result<ArtifactPage, ArtifactError>>

    abstract LinkOptions: Guid * Guid option -> Task<Result<ArtifactLinkPage, ArtifactError>>
    abstract Read: Guid * Guid -> Task<Result<Artifact, ArtifactError>>
    abstract Add: ArtifactRegistration * CancellationToken -> Task<Result<Artifact, ArtifactError>>
    abstract Retry: ArtifactRef * CancellationToken -> Task<Result<Artifact, ArtifactError>>

    abstract Locate:
        ArtifactRef * string * CancellationToken -> Task<Result<Artifact, ArtifactError>>

    abstract Link: ArtifactRef * Guid * Guid * bool -> Task<Result<Artifact, ArtifactError>>
    abstract DeleteCopy: ArtifactRef -> Task<Result<Artifact, ArtifactError>>
    abstract Remove: ArtifactRef -> Task<Result<unit, ArtifactError>>
