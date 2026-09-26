namespace ModConductor.Fnis

open System
open System.Threading
open ModConductor.ArchiveInstallation
open ModConductor.DeploymentPlanning
open ModConductor.Nexus
open ModConductor.Platform

[<RequireQualifiedAccess>]
type FnisProblem =
    | GameUnavailable
    | UnsupportedStorefront
    | SignInRequired
    | EntitlementRequired
    | HandoffExpired
    | SourceUnavailable of string
    | InvalidArchive of string
    | TransferFailed of string
    | InstallationFailed of string

type FnisRelease =
    { ModId: int64
      File: NexusFile
      ComponentVersion: Version }

[<RequireQualifiedAccess>]
type FnisAcquisition =
    | Direct
    | NexusPage

type FnisSelection =
    { Release: FnisRelease
      Acquisition: FnisAcquisition }

type FnisArchivePlan =
    { Files: SelectedFile list
      ComponentFiles: ComponentFile list
      Generator: string }

[<RequireQualifiedAccess>]
type FnisOutputPhase =
    | Unavailable
    | Missing
    | Stale
    | Current
    | Running
    | Failed
    | Cancelled
    | Abandoned

type FnisInputFile =
    { Path: LogicalPath
      Length: int64
      Sha256: string }

type FnisInspection =
    { WorkspaceId: Guid
      ProfileId: Guid
      GenerationId: Guid
      Generator: string
      Fingerprint: string
      Phase: FnisOutputPhase
      Status: string
      Detail: string
      LatestRunId: Guid option
      ExitCode: int option
      StandardOutput: string
      StandardError: string
      RunLog: string }

type FnisRunRequest =
    { Id: Guid
      WorkspaceId: Guid
      ProfileId: Guid }

type FnisRunStage =
    { Request: FnisRunRequest
      GenerationId: Guid
      Generator: string
      Fingerprint: string
      Directory: string }

[<RequireQualifiedAccess>]
type FnisExecutionError =
    | NotFound
    | Busy
    | IdentityConflict
    | Stale
    | Cancelled
    | Invalid of string
    | Unavailable of string
    | SourceInspectionFailed of string

type IFnisInspection =
    abstract Inspect:
        workspace: Guid * profile: Guid * cancellation: CancellationToken ->
            System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>

type IFnisExecution =
    inherit IFnisInspection

    abstract Run:
        request: FnisRunRequest * cancellation: CancellationToken ->
            System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>

    abstract WaitForRun:
        request: FnisRunRequest * cancellation: CancellationToken ->
            System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>

    abstract Cancel:
        workspace: Guid * profile: Guid ->
            System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>

module FnisProblem =
    let message =
        function
        | FnisProblem.GameUnavailable -> "Select and refresh the Skyrim installation."
        | FnisProblem.UnsupportedStorefront ->
            "FNIS setup supports Skyrim Special Edition from Steam."
        | FnisProblem.SignInRequired -> "Sign in to Nexus Mods."
        | FnisProblem.EntitlementRequired ->
            "Open Nexus Mods, then select Mod Manager Download for FNIS Behavior SE 7.6."
        | FnisProblem.HandoffExpired ->
            "The Nexus download link expired. Select Mod Manager Download again."
        | FnisProblem.SourceUnavailable detail -> detail
        | FnisProblem.InvalidArchive detail -> detail
        | FnisProblem.TransferFailed detail -> detail
        | FnisProblem.InstallationFailed detail -> detail
