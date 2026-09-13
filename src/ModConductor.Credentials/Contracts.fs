namespace ModConductor.Credentials

open System
open System.Threading

[<RequireQualifiedAccess>]
type StorageKind =
    | SecretService
    | CredentialManager
    | Unavailable

[<RequireQualifiedAccess>]
type StorageMode =
    | Secure
    | SessionOnly

[<RequireQualifiedAccess>]
type StorageProblem =
    | Unavailable
    | Locked
    | Denied
    | TimedOut
    | Cancelled
    | TooLarge
    | Failed

[<RequireQualifiedAccess>]
type SavedPresence =
    | Present
    | Absent
    | Unknown

type StoreStatus =
    { Saved: SavedPresence
      Problem: StorageProblem option }

type CredentialStatus =
    { Storage: StorageKind
      Mode: StorageMode
      Saved: SavedPresence
      HasSession: bool
      Problem: StorageProblem option
      RemovalProblem: StorageProblem option }

type ICredentialStore =
    abstract Kind: StorageKind
    abstract Inspect: CancellationToken -> StoreStatus
    abstract Save: byte[] * CancellationToken -> Result<unit, StorageProblem>
    /// The caller owns and clears the returned buffer.
    abstract Read: CancellationToken -> Result<byte[] option, StorageProblem>
    abstract Delete: CancellationToken -> Result<unit, StorageProblem>

module CredentialDiagnostics =
    let problem =
        function
        | StorageProblem.Unavailable -> "Unavailable"
        | StorageProblem.Locked -> "Locked"
        | StorageProblem.Denied -> "Access denied"
        | StorageProblem.TimedOut -> "Timed out"
        | StorageProblem.Cancelled -> "Cancelled"
        | StorageProblem.TooLarge -> "Value exceeds the storage limit"
        | StorageProblem.Failed -> "Storage operation failed"

    let report status =
        String.concat
            "\n"
            [ "Provider: Nexus Mods"
              "Storage: "
              + (match status.Storage with
                 | StorageKind.SecretService -> "Secret Service"
                 | StorageKind.CredentialManager -> "Windows Credential Manager"
                 | StorageKind.Unavailable -> "Unavailable")
              "Secure storage: "
              + (status.Problem |> Option.map problem |> Option.defaultValue "Available")
              "Saved sign-in: "
              + (match status.Saved with
                 | SavedPresence.Present -> "Present"
                 | SavedPresence.Absent -> "None"
                 | SavedPresence.Unknown -> "Unknown")
              "Session details: " + (if status.HasSession then "Present" else "None")
              "New sign-ins: "
              + (match status.Mode with
                 | StorageMode.Secure -> "Secure storage"
                 | StorageMode.SessionOnly -> "This session only")
              match status.RemovalProblem with
              | Some value -> "Removal: " + problem value
              | None -> () ]
