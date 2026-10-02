namespace ModConductor.GameContexts

[<RequireQualifiedAccess>]
type CapabilityId =
    | GameInstallationValidation
    | SkyrimSpecialEdition
    | BethesdaGame
    | UnityMono
    | UnityIl2Cpp
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
        | CapabilityId.UnityIl2Cpp -> "unity-il2cpp"
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
    let private bothPlatforms (definitions: GameDefinition list) =
        [ for definition in definitions do
              yield
                  { DefinitionId = definition.Id
                    Platforms =
                      if GameClient.nativeLinux definition then
                          [ ContextPlatform.Windows; ContextPlatform.NativeLinux ]
                      elif definition.SteamAppId <> 0u then
                          [ ContextPlatform.Windows; ContextPlatform.Proton ]
                      else
                          [ ContextPlatform.Windows; ContextPlatform.Wine ] } ]

    let private bethesda (definitions: GameDefinition list) =
        bothPlatforms definitions
        |> List.filter (fun row ->
            (definitions |> List.find (fun d -> d.Id = row.DefinitionId)).Client = GameClient.Bethesda)

    let private catalog (definitions: GameDefinition list) =
        [ { Id = CapabilityId.GameInstallationValidation
            Revision = 1
            Name = "Game installation checks"
            Kind = CapabilityKind.CoreOutcome
            Audience = CapabilityAudience.User
            Contexts = bothPlatforms definitions
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.BethesdaGame
            Revision = 1
            Name = "Bethesda game support"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts = bethesda definitions
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.UnityMono
            Revision = 1
            Name = "Native Unity Mono client support"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts =
              bothPlatforms definitions
              |> List.filter (fun row ->
                  (GameClient.mono (definitions |> List.find (fun d -> d.Id = row.DefinitionId)))
                      .IsSome)
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.UnityIl2Cpp
            Revision = 1
            Name = "Declared x64 Unity IL2CPP client support"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts =
              bothPlatforms definitions
              |> List.filter (fun row ->
                  (GameClient.il2cpp (definitions |> List.find (fun d -> d.Id = row.DefinitionId)))
                      .IsSome)
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.Unreal
            Revision = 1
            Name = "Declared Unreal mod workflows"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts =
              bothPlatforms definitions
              |> List.filter (fun row ->
                  (GameClient.unreal (definitions |> List.find (fun d -> d.Id = row.DefinitionId)))
                      .IsSome)
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.SkyrimSpecialEdition
            Revision = 1
            Name = "Skyrim Special Edition support"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts =
              bothPlatforms definitions
              |> List.filter (fun context ->
                  context.DefinitionId = GameId.SkyrimSpecialEditionSteam
                  || context.DefinitionId = GameId.SkyrimSpecialEditionGog
                  || context.DefinitionId = GameId.SkyrimSpecialEditionDirect)
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.ArchiveInspection
            Revision = 1
            Name = "Game archive inspection"
            Kind = CapabilityKind.GameAdapter
            Audience = CapabilityAudience.User
            Contexts = bethesda definitions
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.IndividualSaveEditing
            Revision = 1
            Name = "Individual save editing"
            Kind = CapabilityKind.OptionalLegacy
            Audience = CapabilityAudience.User
            Contexts = bothPlatforms definitions
            Disposition =
              CapabilityDisposition.Unavailable "Individual save editing is not available." }
          { Id = CapabilityId.LegacyExtensionAbi
            Revision = 1
            Name = "Old extension loading"
            Kind = CapabilityKind.ObsoleteMechanism
            Audience = CapabilityAudience.PolicyOnly
            Contexts = bothPlatforms definitions
            Disposition =
              CapabilityDisposition.Unsupported(
                  "Mod Conductor cannot load extensions that require Qt widgets, Windows handles, or a Python ABI."
              ) } ]

    let forDefinition definitionId =
        catalog (GameCatalog.all ())
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

    let forDeclaration (definition: GameDefinition) =
        catalog (
            definition
            :: (GameCatalog.all () |> List.filter (fun row -> row.Id <> definition.Id))
        )
        |> List.filter (fun capability ->
            capability.Audience = CapabilityAudience.User
            && capability.Contexts
               |> List.exists (fun context -> context.DefinitionId = definition.Id))
