namespace ModConductor.Fnis

open System
open ModConductor.ArchiveInstallation
open ModConductor.DeploymentPlanning
open ModConductor.Nexus

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
