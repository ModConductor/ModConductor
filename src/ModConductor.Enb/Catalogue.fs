namespace ModConductor.Enb

open System
open ModConductor.Nexus

module EnbCatalogue =
    [<Literal>]
    let OfficialPage = "https://enbdev.com/download_mod_tesskyrimse.html"

    [<Literal>]
    let OfficialTerms = "https://enbdev.com/license_en.htm"

    [<Literal>]
    let LeanModId = 68542L

    [<Literal>]
    let CathedralModId = 24791L

    let private pin kind name version source terms nexus hash =
        { Kind = kind
          Name = name
          Version = version
          Source = Uri source
          Terms = Uri terms
          NexusModId = nexus
          ExpectedSha256 = hash }

    let lean =
        { Id = "lean-enb-1.0.0-enbseries-0.505-cathedral-2.50"
          Runtime =
            pin
                EnbComponentKind.Runtime
                "ENBSeries for Skyrim SE"
                "0.505"
                OfficialPage
                OfficialTerms
                None
                None
          Preset =
            pin
                EnbComponentKind.Preset
                "Lean ENB"
                "1.0.0"
                "https://www.nexusmods.com/skyrimspecialedition/mods/68542"
                "https://www.nexusmods.com/skyrimspecialedition/mods/68542?tab=description"
                (Some LeanModId)
                None
          Companions =
            [ pin
                  EnbComponentKind.Companion
                  "Cathedral Weathers and Seasons"
                  "2.50"
                  "https://www.nexusmods.com/skyrimspecialedition/mods/24791"
                  "https://www.nexusmods.com/skyrimspecialedition/mods/24791?tab=description"
                  (Some CathedralModId)
                  None ]
          DllOverrides = "d3d11=n,b" }

    let withHash hash pin = { pin with ExpectedSha256 = Some hash }

    let resolveNexusFile (pin: EnbComponentPin) (value: NexusMod) =
        match pin.NexusModId with
        | Some expected when value.Game = "skyrimspecialedition" && value.Id = expected ->
            value.Files
            |> List.filter (fun file ->
                String.Equals(file.Version.Trim(), pin.Version, StringComparison.OrdinalIgnoreCase)
                && (String.Equals(file.Category, "MAIN", StringComparison.OrdinalIgnoreCase)
                    || String.Equals(
                        file.Category.Replace(" ", ""),
                        "Mainfiles",
                        StringComparison.OrdinalIgnoreCase
                    )))
            |> List.sortByDescending _.Id
            |> List.tryHead
            |> function
                | Some file -> Ok file
                | None ->
                    Error(
                        EnbProblem.SourceUnavailable(
                            pin.Name + " " + pin.Version + " is unavailable from its pinned source."
                        )
                    )
        | _ ->
            Error(
                EnbProblem.SourceUnavailable(
                    pin.Name + " did not match its pinned Skyrim Special Edition source."
                )
            )

    let validateHash (pin: EnbComponentPin) actual =
        match pin.ExpectedSha256 with
        | Some expected when String.Equals(expected, actual, StringComparison.OrdinalIgnoreCase) ->
            Ok()
        | None -> Ok()
        | _ -> Error EnbProblem.WrongArchiveHash
