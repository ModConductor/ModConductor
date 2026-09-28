namespace ModConductor.Persistence

type internal PortableSelection =
    { ArchiveIndex: int
      Destination: string list }

type internal PortableNexusSource =
    { Game: string
      ModId: int64
      FileId: int64
      FileVersion: string }

type internal PortableArchiveBase =
    { ArchiveName: string
      ArchiveSha256: string
      ArchiveLength: int64
      Root: string list
      Selected: PortableSelection list }

[<RequireQualifiedAccess>]
type internal PortableContent =
    | Payload of memberName: string * sha256: string * length: int64
    | Patch of memberName: string * baseSha256: string * sha256: string * length: int64

type internal PortableFile =
    { Path: string list
      Content: PortableContent }

type internal PortableMod =
    { Kind: string
      Name: string
      Version: string
      Notes: string
      Comment: string
      Categories: string list
      Source: PortableNexusSource option
      Base: PortableArchiveBase option
      Priority: int
      Enabled: bool option
      Files: PortableFile list
      Deleted: string list list
      Hidden: string list list }

type internal PortablePlugin =
    { Name: string
      Enabled: bool option
      LockedIndex: int option }

type internal PortableProfile =
    { Name: string
      Game: string
      Mods: PortableMod list
      PluginOrder: PortablePlugin list
      SettingsEnabled: bool
      SavesEnabled: bool
      Settings: PortableFile list
      Saves: PortableFile list
      Artwork: PortableFile option }
