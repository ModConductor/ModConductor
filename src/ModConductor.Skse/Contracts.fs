namespace ModConductor.Skse

open System
open ModConductor.ArchiveInstallation
open ModConductor.DeploymentPlanning
open ModConductor.Nexus

[<RequireQualifiedAccess>]
type SkseProblem =
    | GameUnavailable
    | UnsupportedStorefront
    | UnknownCompatibility
    | SelectionChanged
    | SourceUnavailable of string
    | SignInRequired
    | EntitlementRequired
    | HandoffExpired
    | TransferFailed of string
    | InvalidArchive of string
    | InstallationFailed of string
    | StaleGame

type SkseRelease =
    { ModId: int64
      File: NexusFile
      ComponentVersion: Version
      RuntimeVersion: Version }

type SkseAuthorRelease =
    { ModId: int64
      File: NexusFile
      ComponentVersion: Version
      DeclaredRuntimeVersion: Version option }

type SkseReview =
    { GameVersion: string
      GameSha256: string
      RuntimeVersion: Version
      Release: SkseAuthorRelease
      Compatible: bool }

type SkseReleaseChoice =
    { FileId: int64
      ComponentVersion: string
      GameVersion: string
      GameSha256: string
      AllowIncompatible: bool }

[<RequireQualifiedAccess>]
type SkseAcquisition =
    | Direct
    | NexusPage

type SkseSelection =
    { Release: SkseRelease
      Acquisition: SkseAcquisition }

type SkseArchivePlan =
    { Files: SelectedFile list
      ComponentFiles: ComponentFile list
      Loader: string }

module SkseProblem =
    let message =
        function
        | SkseProblem.GameUnavailable -> "Select and refresh the Skyrim installation."
        | SkseProblem.UnsupportedStorefront ->
            "SKSE setup supports Skyrim Special Edition from Steam."
        | SkseProblem.UnknownCompatibility ->
            "No SKSE release declares support for this Skyrim version. No files were changed."
        | SkseProblem.SelectionChanged ->
            "The reviewed SKSE release or Skyrim installation changed. Review SKSE again."
        | SkseProblem.SourceUnavailable detail -> detail
        | SkseProblem.SignInRequired -> "Sign in to Nexus Mods."
        | SkseProblem.EntitlementRequired ->
            "Open Nexus Mods, then select Mod Manager Download for the matching SKSE file."
        | SkseProblem.HandoffExpired ->
            "The Nexus download link expired. Select Mod Manager Download again."
        | SkseProblem.TransferFailed detail -> detail
        | SkseProblem.InvalidArchive detail -> detail
        | SkseProblem.InstallationFailed detail -> detail
        | SkseProblem.StaleGame ->
            "Skyrim changed after the compatibility check. Check SKSE again before installation or Play."
