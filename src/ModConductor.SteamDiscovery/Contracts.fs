namespace ModConductor.SteamDiscovery

open System.Globalization
open ModConductor.Platform

type SearchRoot = { Path: string; Origin: string }

type ObservedDirectory =
    { DeclaredPath: string
      CanonicalPath: string
      Identity: FileIdentity option }

type ManifestEvidence =
    { Path: string
      Identity: FileIdentity
      Sha256: string
      AppId: uint32
      InstallDirectory: string
      Name: string option
      BuildId: string option
      StateFlags: uint64 option }

type InstallationOrigin =
    { Root: SearchRoot
      SteamRoot: ObservedDirectory
      Library: ObservedDirectory
      LibraryEntry: string option
      Manifest: ManifestEvidence }

type InstallationCandidate =
    { Id: string
      Directory: ObservedDirectory
      Origins: InstallationOrigin list }

[<RequireQualifiedAccess>]
type DiagnosticKind =
    | RootUnavailable
    | LibrariesUnreadable
    | LibrariesMalformed
    | LibraryPathInvalid
    | ManifestUnreadable
    | ManifestMalformed
    | StaleEntry
    | AppIdMismatch
    | UnsafeInstallDirectory
    | InstallationUnavailable
    | LimitReached

type DiscoveryDiagnostic =
    { RootPath: string
      Path: string
      Kind: DiagnosticKind
      Detail: string }

type DiscoveryReport =
    { AppId: uint32
      Roots: SearchRoot list
      Candidates: InstallationCandidate list
      Diagnostics: DiscoveryDiagnostic list
      Complete: bool }

module NativeIdentity =
    let value id =
        let device =
            match id.Device with
            | LinuxDevice(major, minor) ->
                "linux:"
                + major.ToString(CultureInfo.InvariantCulture)
                + ":"
                + minor.ToString(CultureInfo.InvariantCulture)
            | WindowsVolume serial -> "windows:" + serial.ToString(CultureInfo.InvariantCulture)

        device
        + ":"
        + id.High.ToString(CultureInfo.InvariantCulture)
        + ":"
        + id.Low.ToString(CultureInfo.InvariantCulture)
