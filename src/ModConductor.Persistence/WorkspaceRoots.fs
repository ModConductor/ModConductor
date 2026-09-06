namespace ModConductor.Persistence

open System
open ModConductor.Platform

[<RequireQualifiedAccess>]
type RootCreationPhase =
    | Intent
    | Observed
    | Complete
    | Unresolved

[<RequireQualifiedAccess>]
type WorkspaceFailure =
    | NotFound
    | StaleRevision
    | IdentityConflict
    | Busy
    | InvalidRoot

type WorkspaceRoot =
    { Id: Guid
      Path: HostPath
      Identity: FileIdentity
      Revision: int64 }

type RootCreationReceipt =
    { Workspace: WorkspaceRoot
      Revision: int64
      Phase: RootCreationPhase
      MarkerIdentity: FileIdentity option
      Detail: string }

type internal RootCreationRow =
    { Receipt: RootCreationReceipt
      Owner: string
      Busy: bool
      Abandoned: bool
      Marker: Guid }
