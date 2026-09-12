namespace ModConductor.HttpDownloads

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary

type DownloadRequest =
    { Id: Guid
      WorkspaceId: Guid
      Name: string
      Sources: string list
      ExpectedLength: int64 option
      ExpectedSha256: string option }

[<RequireQualifiedAccess>]
type DownloadAction =
    | Pause
    | Resume
    | Restart

type DownloadWork =
    { Request: DownloadRequest
      SourceIndex: int
      Bytes: int64
      Total: int64 option
      EntityTag: string option
      EffectiveUrl: string option
      Attempt: int }

type DownloadObservation =
    { Total: int64 option
      EntityTag: string option
      EffectiveUrl: string }

[<RequireQualifiedAccess>]
type DownloadOutcome =
    | Paused
    | Retry of at: DateTimeOffset * sourceIndex: int
    | Failed of message: string * restartRequired: bool * retryAt: DateTimeOffset option

type IDownloadTarget =
    inherit IDisposable
    abstract Stream: FileStream
    abstract Observe: DownloadObservation -> Task
    abstract Checkpoint: int64 -> Task
    abstract Publish: int64 * string -> Task

type IDownloadRepository =
    abstract Read: Guid * Guid -> Task<Result<Artifact, ArtifactError>>
    abstract Start: DownloadRequest -> Task<Result<Artifact, ArtifactError>>
    abstract Control: Guid * Guid * DownloadAction -> Task<Result<Artifact, ArtifactError>>
    abstract Take: unit -> Task<DownloadWork option>
    abstract NextDue: unit -> Task<DateTimeOffset option>
    abstract Open: DownloadWork -> Task<IDownloadTarget>
    abstract Finish: DownloadWork * DownloadOutcome -> Task

type DownloadPolicy =
    { Workers: int
      Attempts: int
      ConnectTimeout: TimeSpan
      HeaderTimeout: TimeSpan
      ReadTimeout: TimeSpan
      RetryDelay: TimeSpan
      CheckpointBytes: int64 }

    static member Default =
        { Workers = 2
          Attempts = 3
          ConnectTimeout = TimeSpan.FromSeconds 10.
          HeaderTimeout = TimeSpan.FromSeconds 30.
          ReadTimeout = TimeSpan.FromSeconds 30.
          RetryDelay = TimeSpan.FromSeconds 1.
          CheckpointBytes = 1024L * 1024L }

module DownloadSource =
    let display (source: string) =
        match Uri.TryCreate(source, UriKind.Absolute) with
        | true, uri -> uri.GetLeftPart(UriPartial.Path)
        | _ -> "Download source"

    let valid (source: string) =
        match Uri.TryCreate(source, UriKind.Absolute) with
        | true, uri ->
            (uri.Scheme = "http" || uri.Scheme = "https")
            && String.IsNullOrEmpty uri.UserInfo
            && String.IsNullOrEmpty uri.Fragment
        | _ -> false
