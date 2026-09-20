namespace ModConductor.Enb

open System
open ModConductor.ArchiveInstallation
open ModConductor.DeploymentPlanning

[<RequireQualifiedAccess>]
type EnbComponentKind =
    | Runtime
    | Preset
    | Companion

type EnbComponentPin =
    { Kind: EnbComponentKind
      Name: string
      Version: string
      Source: Uri
      Terms: Uri
      NexusModId: int64 option
      ExpectedSha256: string option }

type EnbCompatibilityRow =
    { Id: string
      Runtime: EnbComponentPin
      Preset: EnbComponentPin
      Companions: EnbComponentPin list
      DllOverrides: string }

[<RequireQualifiedAccess>]
type EnbProblem =
    | GameUnavailable
    | UnsupportedStorefront
    | SignInRequired
    | SourceUnavailable of string
    | InvalidArchive of string
    | WrongArchiveHash
    | ProfileConflict of string
    | ForeignDllConflict of string
    | IncompatibleRuntime of string
    | ConfigurationUnavailable of string

type EnbArchivePlan =
    { Files: SelectedFile list
      ComponentFiles: ComponentFile list }

type EnbConfigurationValue =
    { File: string
      Section: string
      Key: string
      RequiredValue: string
      PreviousValue: string option }

type EnbRuntimePlan =
    { GenerationId: Guid
      GameSha256: string
      Environment: (string * string option) list
      Configuration: EnbConfigurationValue list
      PreservedRuntime: string
      SteamOptionsChanged: bool
      ExternalTools: string list }

type EnbOwnership =
    { ProfileId: Guid
      GenerationId: Guid
      Renderer: string
      Preset: string }

module EnbProblem =
    let message =
        function
        | EnbProblem.GameUnavailable -> "Select and refresh the Skyrim installation."
        | EnbProblem.UnsupportedStorefront ->
            "ENB setup supports Skyrim Special Edition from Steam."
        | EnbProblem.SignInRequired -> "Sign in to Nexus Mods to obtain Lean ENB and its companion."
        | EnbProblem.SourceUnavailable detail -> detail
        | EnbProblem.InvalidArchive detail -> detail
        | EnbProblem.WrongArchiveHash ->
            "This is not the approved ENBSeries archive. No files were changed."
        | EnbProblem.ProfileConflict detail -> detail
        | EnbProblem.ForeignDllConflict name ->
            "The game folder already contains an unmanaged "
            + name
            + ". Review the setup plan before replacing it."
        | EnbProblem.IncompatibleRuntime detail -> detail
        | EnbProblem.ConfigurationUnavailable detail -> detail
