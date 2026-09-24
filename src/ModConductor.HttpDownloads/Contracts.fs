namespace ModConductor.HttpDownloads

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary

type NexusFileReference =
    { Account: string
      Game: string
      ModId: int64
      FileId: int64
      Keyed: bool
      Version: string option }

[<RequireQualifiedAccess>]
type DownloadSource =
    | Url of string
    | Nexus of NexusFileReference

type PrivateDownload = { Url: Uri; Expires: DateTimeOffset }

type INexusDownloadLinks =
    abstract Reject: NexusFileReference * Uri -> unit

    abstract Resolve:
        NexusFileReference * CancellationToken -> Task<Result<PrivateDownload, string>>

type DownloadRequest =
    { Id: Guid
      WorkspaceId: Guid
      Name: string
      Sources: DownloadSource list
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
    abstract FindNexus: Guid * NexusFileReference -> Task<Artifact option>
    abstract AccountDownloads: string -> Task<(Guid * Guid) list>
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
    let encode =
        function
        | DownloadSource.Url value -> value
        | DownloadSource.Nexus value ->
            String.concat
                "/"
                [ (if value.Keyed then "nexus-link:" else "nexus:")
                  Uri.EscapeDataString value.Account
                  value.Game
                  string value.ModId
                  string value.FileId ]

    let decode (source: string) =
        if
            source.StartsWith("nexus:/", StringComparison.Ordinal)
            || source.StartsWith("nexus-link:/", StringComparison.Ordinal)
        then
            let parts = source.Split('/')

            if parts.Length <> 5 then
                invalidOp "The saved Nexus file reference is invalid."

            DownloadSource.Nexus
                { Account = Uri.UnescapeDataString parts[1]
                  Game = parts[2]
                  ModId = Int64.Parse parts[3]
                  FileId = Int64.Parse parts[4]
                  Keyed = parts[0] = "nexus-link:"
                  Version = None }
        else
            DownloadSource.Url source

    let display =
        function
        | DownloadSource.Nexus _ -> "Nexus Mods"
        | DownloadSource.Url source ->
            match Uri.TryCreate(source, UriKind.Absolute) with
            | true, uri -> uri.GetLeftPart(UriPartial.Path)
            | _ -> "Download source"

    let valid =
        function
        | DownloadSource.Nexus value ->
            not (String.IsNullOrWhiteSpace value.Account)
            && value.Account.Length <= 256
            && value.Game = "skyrimspecialedition"
            && value.ModId > 0L
            && value.FileId > 0L
        | DownloadSource.Url source ->
            match Uri.TryCreate(source, UriKind.Absolute) with
            | true, uri ->
                (uri.Scheme = "http" || uri.Scheme = "https")
                && String.IsNullOrEmpty uri.UserInfo
                && String.IsNullOrEmpty uri.Fragment
                && source.Length <= 8192
                && not (source.Contains '\n')
                && not (source.Contains '\r')
            | _ -> false
