namespace ModConductor.Fnis

open System
open ModConductor.GameContexts
open ModConductor.Nexus

module FnisCatalogue =
    [<Literal>]
    let NexusModId = 3038L

    [<Literal>]
    let SupportedVersion = "7.6"

    [<Literal>]
    let Provider = "Nexus Mods"

    [<Literal>]
    let Source = "https://www.nexusmods.com/skyrimspecialedition/mods/3038"

    [<Literal>]
    let Terms =
        "https://www.nexusmods.com/skyrimspecialedition/mods/3038?tab=description"

    [<Literal>]
    let TermsApproved = true

    [<Literal>]
    let GeneratorPath = "Data/tools/GenerateFNIS_for_Users/GenerateFNISforUsers.exe"

    let private supportedCategory (value: string) =
        String.Equals(value, "MAIN", StringComparison.OrdinalIgnoreCase)
        || String.Equals(value.Replace(" ", ""), "Mainfiles", StringComparison.OrdinalIgnoreCase)

    let release (value: NexusMod) =
        if value.Game <> "skyrimspecialedition" || value.Id <> NexusModId then
            Error(
                FnisProblem.SourceUnavailable
                    "FNIS did not match its reviewed Skyrim Special Edition source."
            )
        else
            value.Files
            |> List.filter (fun file ->
                String.Equals(
                    file.Version.Trim(),
                    SupportedVersion,
                    StringComparison.OrdinalIgnoreCase
                )
                && supportedCategory file.Category
                && file.Name.Contains("FNIS", StringComparison.OrdinalIgnoreCase)
                && file.Name.Contains("Behavior", StringComparison.OrdinalIgnoreCase)
                && file.Name.Contains("SE", StringComparison.OrdinalIgnoreCase)
                && not (file.Name.Contains("VR", StringComparison.OrdinalIgnoreCase)))
            |> List.sortByDescending _.Id
            |> List.tryHead
            |> function
                | Some file ->
                    Ok
                        { ModId = value.Id
                          File = file
                          ComponentVersion = Version(7, 6) }
                | None ->
                    Error(
                        FnisProblem.SourceUnavailable
                            "FNIS Behavior SE 7.6 is unavailable from its reviewed Nexus source."
                    )

    let eligibility (state: GameContextState) =
        match state.Binding with
        | None -> Error FnisProblem.GameUnavailable
        | Some binding when binding.NeedsCheck || not binding.Evidence.Valid ->
            Error FnisProblem.GameUnavailable
        | Some binding when
            binding.Evidence.DefinitionId <> Skyrim.definition.Id
            || Skyrim.definition.Storefront <> "Steam"
            ->
            Error FnisProblem.UnsupportedStorefront
        | Some _ -> Ok()

    let acquisition (account: Account option) =
        match account with
        | None -> Error FnisProblem.SignInRequired
        | Some account ->
            Ok(
                if account.Premium = Some true then
                    FnisAcquisition.Direct
                else
                    FnisAcquisition.NexusPage
            )
