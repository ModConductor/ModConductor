namespace ModConductor.Fomod

open ModConductor.Platform
open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation

type FomodException(message: string) =
    inherit System.Exception(message)

[<RequireQualifiedAccess>]
type Fact<'a> =
    | Known of 'a
    | Unknown of string

[<RequireQualifiedAccess>]
type FileState =
    | Missing
    | Inactive
    | Active

type Facts =
    { GameVersion: Fact<string>
      Files: Map<string, Fact<FileState>>
      FommVersion: Fact<string>
      ExtenderVersion: Fact<string> }

[<RequireQualifiedAccess>]
type Condition =
    | All of Condition list
    | Any of Condition list
    | Flag of name: string * value: string
    | File of path: LogicalPath * state: FileState
    | GameVersion of string
    | FommVersion of string
    | ExtenderVersion of string

[<RequireQualifiedAccess>]
type OptionType =
    | Required
    | Recommended
    | Optional
    | NotUsable
    | CouldBeUsable

[<RequireQualifiedAccess>]
type TypeDescriptor =
    | Fixed of OptionType
    | Dependent of fallback: OptionType * patterns: (Condition * OptionType) list

[<RequireQualifiedAccess>]
type GroupType =
    | Any
    | All
    | AtLeastOne
    | AtMostOne
    | ExactlyOne

type FileMapping =
    { Order: int
      Source: string list
      Destination: string list
      AppendName: bool
      Folder: bool
      Priority: int
      Always: bool
      IfUsable: bool }

type ChoiceOption =
    { Id: int
      Name: string
      Description: string
      Image: string list option
      Files: FileMapping list
      Flags: (string * string) list
      Type: TypeDescriptor }

type ChoiceGroup =
    { Name: string
      Kind: GroupType
      Options: ChoiceOption list }

type InstallStep =
    { Index: int
      Name: string
      Visible: Condition
      Groups: ChoiceGroup list }

type Definition =
    { Name: string
      Version: string
      Root: string list
      Image: string list option
      Dependency: Condition
      Required: FileMapping list
      Steps: InstallStep list
      Conditional: (Condition * FileMapping list) list
      Manifest: ArchiveManifest }

[<RequireQualifiedAccess>]
type InstallerInput =
    | Absent
    | Xml of Definition
    | Unavailable of string

type OptionState =
    { Option: ChoiceOption
      Type: Fact<OptionType> }

type GroupState =
    { Group: ChoiceGroup
      Options: OptionState list }

type Page =
    { Step: InstallStep
      Groups: GroupState list
      Selected: Set<int>
      FlagsBefore: Map<string, string> }

type Wizard =
    { Past: Page list
      Current: Page option
      Future: Page list
      Problem: string option }

type PlannedFile =
    { File: SelectedFile
      Source: LogicalPath
      Choice: string
      Replaces: LogicalPath list }

type PlannedChoices =
    { Files: PlannedFile list
      Name: string
      Version: string }

type InstallerChoices =
    { Draft: InstallationDraft
      ProfileId: System.Guid
      Definition: Definition option
      Wizard: Wizard option
      Planned: PlannedChoices option
      VisibleSteps: int
      Problem: string option }
