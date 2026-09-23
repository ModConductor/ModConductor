namespace ModConductor.Bethesda

[<StructuralEquality; NoComparison>]
type PluginSetting =
    { Name: string
      Enabled: bool option
      LockedIndex: int option }

[<StructuralEquality; NoComparison>]
type PluginOrder =
    { Document: byte array
      Entries: PluginSetting list }

[<RequireQualifiedAccess>]
type PluginRequirement =
    | Engine
    | SkyrimIni

type PluginOrderFacts =
    { Early: string list
      DefaultEnabled: string list
      Required: (string * PluginRequirement) list
      Implicit: string list }

type PluginOrderIssue = { Name: string option; Detail: string }

type PluginOrderView =
    { Order: PluginOrder
      Issues: PluginOrderIssue list
      Full: int
      Light: int
      FullLimit: int }

[<RequireQualifiedAccess>]
type PluginOrderChange =
    | Enable of names: string list * enabled: bool
    | Move of names: string list * up: bool
    | Lock of names: string list * locked: bool
    | Replace of names: string list
