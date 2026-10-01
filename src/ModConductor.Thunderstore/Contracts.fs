namespace ModConductor.Thunderstore

open System
open System.Threading
open System.Threading.Tasks

type PackageReference = { Community: string; Namespace: string; Name: string }
type VersionReference = { Package: PackageReference; Version: string }
type PackagePreview =
    { Package: PackageReference
      Description: string
      Icon: Uri option
      Deprecated: bool }
type Dependency = { Reference: VersionReference; Available: bool; Icon: Uri option }
type PackageDetails =
    { Reference: VersionReference
      Description: string
      Icon: Uri option
      Deprecated: bool
      Categories: string list
      Download: Uri
      Bytes: int64
      Dependencies: Dependency list
      DependencyCount: int }
type PackagePage = { Entries: PackagePreview list; Count: int; Next: int option }

[<RequireQualifiedAccess>]
type Problem =
    | InvalidRequest
    | NotFound of string
    | Requirements of string
    | Forbidden
    | RateLimited of DateTimeOffset option
    | Offline
    | TimedOut
    | InvalidResponse
    | Cancelled
    | Busy
    | Acquisition of string

type IPackageReader =
    abstract Search: string * string * string * int * CancellationToken -> Task<Result<PackagePage, Problem>>
    abstract Details: PackageReference * string option * CancellationToken -> Task<Result<PackageDetails, Problem>>
    abstract Versions: PackageReference * CancellationToken -> Task<Result<string list, Problem>>

module PackageReference =
    let private partValid (value: string) =
        not (String.IsNullOrWhiteSpace value)
        && (value |> Seq.forall (fun c -> Char.IsAsciiLetterOrDigit c || c = '_' || c = '-'))
    let valid value = partValid value.Community && partValid value.Namespace && partValid value.Name
    let label value = value.Namespace + "-" + value.Name
    let key value = value.Community + "/" + value.Namespace + "/" + value.Name

module VersionReference =
    let valid (value: VersionReference) =
        PackageReference.valid value.Package
        && not (String.IsNullOrWhiteSpace value.Version)
        && (value.Version |> Seq.forall (fun c -> Char.IsAsciiLetterOrDigit c || c = '.' || c = '-' || c = '_'))
    let label (value: VersionReference) = PackageReference.label value.Package + "-" + value.Version
    let encode (value: VersionReference) = "thunderstore:/" + PackageReference.key value.Package + "/" + value.Version
    let tryDecode (value: string) =
        let parts = value.Split('/')
        if parts.Length <> 5 || parts[0] <> "thunderstore:" then None
        else
            let parsed = { Package = { Community = parts[1]; Namespace = parts[2]; Name = parts[3] }; Version = parts[4] }
            if valid parsed then Some parsed else None

module Problem =
    let message = function
        | Problem.InvalidRequest -> "Choose an available Thunderstore package and version."
        | Problem.NotFound package -> package + " is not available on Thunderstore."
        | Problem.Requirements message | Problem.Acquisition message -> message
        | Problem.Forbidden -> "Thunderstore refused this request."
        | Problem.RateLimited _ -> "Thunderstore request limit reached. Try again later."
        | Problem.Offline -> "Thunderstore is not available."
        | Problem.TimedOut -> "The Thunderstore request timed out."
        | Problem.InvalidResponse -> "Thunderstore returned an unexpected response."
        | Problem.Cancelled -> "Acquisition cancelled. Completed packages remain in the library."
        | Problem.Busy -> "Another package acquisition is in progress."
