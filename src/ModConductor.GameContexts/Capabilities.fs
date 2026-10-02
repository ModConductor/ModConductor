namespace ModConductor.GameContexts

[<RequireQualifiedAccess>]
type CapabilityId =
    | GameInstallationValidation
    | SkyrimSpecialEdition
    | BethesdaGame
    | UnityMono
    | Unreal
    | ArchiveInspection
    | IndividualSaveEditing
    | LegacyExtensionAbi

module CapabilityId =
    let value =
        function
        | CapabilityId.GameInstallationValidation -> "game-installation-validation"
        | CapabilityId.SkyrimSpecialEdition -> "skyrim-special-edition"
        | CapabilityId.BethesdaGame -> "bethesda-game"
        | CapabilityId.UnityMono -> "unity-mono"
        | CapabilityId.Unreal -> "unreal"
        | CapabilityId.ArchiveInspection -> "archive-inspection"
        | CapabilityId.IndividualSaveEditing -> "individual-save-editing"
        | CapabilityId.LegacyExtensionAbi -> "legacy-extension-abi"

[<RequireQualifiedAccess>]
type CapabilityKind =
    | CoreOutcome
    | GameAdapter
    | OptionalLegacy
    | ObsoleteMechanism

[<RequireQualifiedAccess>]
type CapabilityDisposition =
    | Available
    | Unavailable of reason: string
    | Unsupported of reason: string

[<RequireQualifiedAccess>]
type CapabilityAudience =
    | User
    | PolicyOnly

type CapabilityContext =
    { DefinitionId: GameId
      Platforms: ContextPlatform list }

type CompiledCapability =
    { Id: CapabilityId
      Revision: int
      Name: string
      Kind: CapabilityKind
      Audience: CapabilityAudience
      Contexts: CapabilityContext list
      Disposition: CapabilityDisposition }

module CapabilityPolicy =
    let private bothPlatforms =
        [ for definition in GameCatalog.definitions do
              yield
                  { DefinitionId = definition.Id
                    Platforms =
                      if (GameClient.mono definition).IsSome then
                          [ ContextPlatform.Windows; ContextPlatform.NativeLinux ]
                      elif GameCatalog.steam definition.Id then
                          [ ContextPlatform.Windows; ContextPlatform.Proton ]
                      else
                          [ ContextPlatform.Windows; ContextPlatform.Wine ] } ]

    let private bethesda =
        bothPlatforms
        |> List.filter (fun row -> GameCatalog.isBethesda row.DefinitionId)

    let private catalog =
        [ { Id = CapabilityId.GameInstallationValidation
            Revision = 1
            Name = "Game installation checks"
            Kind = CapabilityKind.CoreOutcome
            Audience = CapabilityAudience.User
            Contexts = bothPlatforms
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.BethesdaGame
            Revision = 1
            Name = "Bethesda game support"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts = bethesda
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.UnityMono
            Revision = 1
            Name = "Native Unity Mono client support"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts =
              bothPlatforms
              |> List.filter (fun row ->
                  (GameClient.mono (GameCatalog.forGame row.DefinitionId)).IsSome)
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.Unreal
            Revision = 1
            Name = "Declared Unreal mod workflows"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts =
              bothPlatforms
              |> List.filter (fun row ->
                  (GameClient.unreal (GameCatalog.forGame row.DefinitionId)).IsSome)
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.SkyrimSpecialEdition
            Revision = 1
            Name = "Skyrim Special Edition support"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts =
              bothPlatforms
              |> List.filter (fun context -> GameCatalog.isSkyrimSE context.DefinitionId)
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.ArchiveInspection
            Revision = 1
            Name = "Game archive inspection"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts = bethesda
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.IndividualSaveEditing
            Revision = 1
            Name = "Individual save editing"
            Kind = CapabilityKind.OptionalLegacy
            Audience = CapabilityAudience.User
            Contexts = bothPlatforms
            Disposition =
              CapabilityDisposition.Unavailable "Individual save editing is not available." }
          { Id = CapabilityId.LegacyExtensionAbi
            Revision = 1
            Name = "Old extension loading"
            Kind = CapabilityKind.ObsoleteMechanism
            Audience = CapabilityAudience.PolicyOnly
            Contexts = bothPlatforms
            Disposition =
              CapabilityDisposition.Unsupported(
                  "Mod Conductor cannot load extensions that require Qt widgets, Windows handles, or a Python ABI."
              ) } ]

    let forDefinition definitionId =
        catalog
        |> List.filter (fun capability ->
            capability.Contexts
            |> List.exists (fun context -> context.DefinitionId = definitionId))

    let tryFind definitionId capabilityId =
        forDefinition definitionId
        |> List.tryFind (fun capability -> capability.Id = capabilityId)

    let forUsers definitionId =
        forDefinition definitionId
        |> List.filter (fun capability -> capability.Audience = CapabilityAudience.User)

    let supports definitionId platform capability =
        capability.Contexts
        |> List.exists (fun context ->
            context.DefinitionId = definitionId && List.contains platform context.Platforms)
