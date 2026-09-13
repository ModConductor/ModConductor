namespace ModConductor.Nexus

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Credentials

[<RequireQualifiedAccess>]
type NexusProblem =
    | NotConfigured
    | SignInRequired
    | Cancelled
    | InvalidCallback
    | AccountChanged
    | DownloadAccount
    | DownloadLinkNeeded
    | Storage of StorageProblem
    | Entitlement
    | Forbidden
    | NotFound
    | RateLimited of DateTimeOffset
    | TimedOut
    | Offline
    | InvalidResponse
    | Failed

type internal NexusException(problem) =
    inherit Exception("The Nexus request failed.")
    member _.Problem: NexusProblem = problem

type Account =
    { Subject: string
      Name: string
      Premium: bool option }

type NexusStatus =
    { Configured: bool
      Waiting: bool
      Account: Account option
      Problem: NexusProblem option }

/// Supplied only by an approved build composition or an isolated fixture host.
type NexusRegistration =
    { Issuer: Uri
      Authorize: Uri
      Token: Uri
      UserInfo: Uri
      Api: Uri
      ClientId: string
      Scopes: string list
      RedirectPath: string
      RedirectPort: int
      DownloadOrigins: Uri list }

type OAuthCallback =
    { Code: string
      State: string
      Issuer: string option }

type IOAuthListener =
    inherit IAsyncDisposable
    abstract Redirect: Uri
    abstract Wait: CancellationToken -> Task<Result<OAuthCallback, NexusProblem>>

type IOAuthHandoff =
    abstract Listen: NexusRegistration * CancellationToken -> Task<IOAuthListener>
    abstract Open: Uri * CancellationToken -> Task

type NexusFile =
    { Id: int64
      Name: string
      Version: string
      Category: string
      Description: string
      Bytes: int64 option }

type NexusMod =
    { Game: string
      Id: int64
      Name: string
      Summary: string
      Files: NexusFile list }

type DownloadLease = { Url: Uri; Expires: DateTimeOffset }

module NexusProblem =
    let message =
        function
        | NexusProblem.NotConfigured -> "Sign-in is not configured in this build."
        | NexusProblem.SignInRequired -> "Sign in to Nexus Mods again."
        | NexusProblem.Cancelled -> "The Nexus request was cancelled."
        | NexusProblem.InvalidCallback -> "The sign-in response did not match this request."
        | NexusProblem.AccountChanged ->
            "Nexus Mods returned a different account. Disconnect before changing accounts."
        | NexusProblem.DownloadLinkNeeded ->
            "A new download link is needed. Use Mod Manager Download on Nexus Mods again."
        | NexusProblem.DownloadAccount -> "Use the Nexus account that started this download."
        | NexusProblem.Storage StorageProblem.Locked ->
            "Unlock the system keyring or choose This session only, then sign in again."
        | NexusProblem.Storage _ ->
            "Sign-in details were not saved. Check sign-in storage and try again."
        | NexusProblem.Entitlement -> "Start this download on Nexus Mods."
        | NexusProblem.Forbidden -> "Nexus Mods refused this request."
        | NexusProblem.NotFound -> "This mod or file is not available on Nexus Mods."
        | NexusProblem.RateLimited _ -> "Nexus request limit reached."
        | NexusProblem.TimedOut -> "The Nexus request timed out."
        | NexusProblem.Offline -> "Nexus Mods is not available."
        | NexusProblem.InvalidResponse -> "Nexus Mods returned an unexpected response."
        | NexusProblem.Failed -> "The Nexus request could not be completed."

module internal Registration =
    let validate (value: NexusRegistration) =
        let allowed (uri: Uri) =
            uri.IsAbsoluteUri
            && uri.UserInfo = ""
            && uri.Fragment = ""
            && (uri.Scheme = "https" || (uri.Scheme = "http" && uri.Host = "127.0.0.1"))

        let origin (uri: Uri) = uri.GetLeftPart(UriPartial.Authority)

        if
            ([ value.Issuer; value.Authorize; value.Token; value.UserInfo; value.Api ]
             @ value.DownloadOrigins
             |> List.exists (allowed >> not))
            || ([ value.Authorize; value.Token; value.UserInfo ]
                |> List.exists (fun uri -> origin uri <> origin value.Issuer))
            || String.IsNullOrWhiteSpace value.ClientId
            || value.Scopes.IsEmpty
            || value.DownloadOrigins.IsEmpty
            || not (value.RedirectPath.StartsWith("/", StringComparison.Ordinal))
            || value.RedirectPath.Contains('?')
            || value.RedirectPath.Contains('#')
            || value.RedirectPort < 0
            || value.RedirectPort > 65535
        then
            invalidArg
                "registration"
                "The approved Nexus endpoint or redirect configuration is invalid."
