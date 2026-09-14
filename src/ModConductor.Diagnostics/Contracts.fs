namespace ModConductor.Diagnostics

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.DeploymentPlanning

module Limits =
    let findings = 64
    let evidence = 16
    let previews = 16
    let previewMinutes = 5.
    let recoveryPaths = 256
    let recoveryBytes = 128 * 1024
    let exportBytes = 256 * 1024

[<RequireQualifiedAccess>]
type DiagnosticError =
    | NotFound
    | Expired
    | Stale
    | Foreign
    | NotOwned
    | Busy
    | Oversized
    | Unsupported
    | Cancelled

[<RequireQualifiedAccess>]
type DiagnosticSeverity =
    | Information
    | Warning
    | Error

[<RequireQualifiedAccess>]
type Fixability =
    | NotFixable
    | PreviewAvailable
    | Ready
    | Refused

[<RequireQualifiedAccess>]
type CorrelationKind =
    | Launch
    | ModFiles
    | GameSetup
    | Deployment
    | Profile
    | Action

[<RequireQualifiedAccess>]
type DiagnosticAction =
    | NavigateGame
    | CheckAgain
    | HideFileCopy of snapshot: Guid * copy: ModFile
    | RecoverDeployment of receipt: Guid * revision: int64
    | ResumeProfileData of action: Guid
    | None

type DiagnosticEvidence = { Label: string; Value: string }

type DiagnosticCorrelation =
    { Kind: CorrelationKind
      Id: string
      Revision: int64 option }

type DiagnosticFinding =
    { Id: string
      Code: string
      Severity: DiagnosticSeverity
      WorkspaceId: Guid
      ProfileId: Guid
      WorkspaceName: string
      ProfileName: string
      GameName: string
      Title: string
      Summary: string
      Detail: string option
      Area: string
      Evidence: DiagnosticEvidence list
      NextAction: string
      Fixability: Fixability
      FixDetail: string
      Correlations: DiagnosticCorrelation list
      Action: DiagnosticAction }

type DiagnosticRequest =
    { WorkspaceId: Guid
      ProfileId: Guid
      FileSnapshotId: Guid option
      DeploymentReceipt: (Guid * int64) option
      OperationId: string option }

type DiagnosticSnapshot =
    { Id: Guid
      WorkspaceId: Guid
      ProfileId: Guid
      CapturedAt: DateTimeOffset
      Findings: DiagnosticFinding list }

type RemediationPreview =
    { Id: Guid
      SnapshotId: Guid
      FindingId: string
      WorkspaceId: Guid
      ProfileId: Guid
      ExpiresAt: DateTimeOffset
      Paths: string list
      Result: string }

type RemediationResult =
    { PreviewId: Guid
      Complete: bool
      Result: string
      Detail: string option }

type SupportReport =
    { FileName: string
      Content: byte array }

type IDiagnostics =
    abstract Check: DiagnosticRequest * CancellationToken -> Task<Result<DiagnosticSnapshot, DiagnosticError>>
    abstract Preview: Guid * string * CancellationToken -> Task<Result<RemediationPreview, DiagnosticError>>
    abstract Apply: Guid * Guid * CancellationToken -> Task<Result<RemediationResult, DiagnosticError>>
    abstract Export: Guid * CancellationToken -> Task<Result<SupportReport, DiagnosticError>>
