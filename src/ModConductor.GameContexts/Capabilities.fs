namespace ModConductor.GameContexts

[<RequireQualifiedAccess>]
type CapabilityId =
    | GameInstallationValidation
    | SkyrimSpecialEdition
    | ArchiveInspection
    | IndividualSaveEditing
    | LegacyExtensionAbi

module CapabilityId =
    let value =
        function
        | CapabilityId.GameInstallationValidation -> "game-installation-validation"
        | CapabilityId.SkyrimSpecialEdition -> "skyrim-special-edition"
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

type CapabilityContext =
    { DefinitionId: string
      Platforms: ContextPlatform list }

type CompiledCapability =
    { Id: CapabilityId
      Revision: int
      Name: string
      Kind: CapabilityKind
      Contexts: CapabilityContext list
      Disposition: CapabilityDisposition }

module CapabilityPolicy =
    let private skyrimBothPlatforms =
        [ { DefinitionId = Skyrim.definition.Id
            Platforms = [ ContextPlatform.Windows; ContextPlatform.Proton ] } ]

    let private catalog =
        [ { Id = CapabilityId.GameInstallationValidation
            Revision = 1
            Name = "Game installation checks"
            Kind = CapabilityKind.CoreOutcome
            Contexts = skyrimBothPlatforms
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.SkyrimSpecialEdition
            Revision = 1
            Name = "Skyrim Special Edition support"
            Kind = CapabilityKind.GameAdapter
            Contexts = skyrimBothPlatforms
            Disposition = CapabilityDisposition.Available }
          { Id = CapabilityId.ArchiveInspection
            Revision = 1
            Name = "Game archive inspection"
            Kind = CapabilityKind.OptionalLegacy
            Contexts = skyrimBothPlatforms
            Disposition =
              CapabilityDisposition.Unavailable "Game archive contents are not available." }
          { Id = CapabilityId.IndividualSaveEditing
            Revision = 1
            Name = "Individual save editing"
            Kind = CapabilityKind.OptionalLegacy
            Contexts = skyrimBothPlatforms
            Disposition =
              CapabilityDisposition.Unavailable "Individual save editing is not available." }
          { Id = CapabilityId.LegacyExtensionAbi
            Revision = 1
            Name = "Old extension loading"
            Kind = CapabilityKind.ObsoleteMechanism
            Contexts = skyrimBothPlatforms
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

    let supports definitionId platform capability =
        capability.Contexts
        |> List.exists (fun context ->
            context.DefinitionId = definitionId && List.contains platform context.Platforms)
