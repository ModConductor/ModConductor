namespace ModConductor.Skse

open System
open ModConductor.GameContexts
open ModConductor.Nexus

module SkseResolver =
    [<Literal>]
    let NexusModId = 30379L

    let private tryVersion (value: string) =
        match Version.TryParse(value.Trim()) with
        | true, parsed when parsed.Major >= 0 && parsed.Minor >= 0 -> Some parsed
        | _ -> None

    let private declaredRuntime (description: string) =
        if String.IsNullOrWhiteSpace description then
            None
        else
            let marker = "game version"
            let at = description.IndexOf(marker, StringComparison.OrdinalIgnoreCase)

            if at < 0 then
                None
            else
                let tail = description.Substring(at + marker.Length).TrimStart()

                let value =
                    tail
                    |> Seq.takeWhile (fun c -> Char.IsDigit c || c = '.')
                    |> Seq.toArray
                    |> String

                tryVersion value

    let releases (value: NexusMod) =
        if value.Game <> "skyrimspecialedition" || value.Id <> NexusModId then
            []
        else
            value.Files
            |> List.choose (fun file ->
                match tryVersion file.Version, declaredRuntime file.Description with
                | Some releaseVersion, Some runtime ->
                    Some
                        { ModId = value.Id
                          File = file
                          ComponentVersion = releaseVersion
                          RuntimeVersion = runtime }
                | _ -> None)

    let resolve (state: GameContextState) (available: SkseRelease list) =
        match state.Binding with
        | None -> Error SkseProblem.GameUnavailable
        | Some binding when
            binding.NeedsCheck
            || not binding.Evidence.Valid
            || binding.Evidence.Executable.IsNone
            ->
            Error SkseProblem.GameUnavailable
        | Some binding when
            binding.Evidence.DefinitionId <> Skyrim.definition.Id
            || Skyrim.definition.Storefront <> "Steam"
            ->
            Error SkseProblem.UnsupportedStorefront
        | Some binding ->
            match tryVersion binding.Evidence.Executable.Value.FileVersion with
            | None -> Error SkseProblem.UnknownCompatibility
            | Some runtime ->
                match
                    available
                    |> List.filter (fun release -> release.RuntimeVersion = runtime)
                    |> List.sortByDescending (fun release ->
                        release.ComponentVersion, release.File.Id)
                    |> List.tryHead
                with
                | Some release -> Ok release
                | None -> Error SkseProblem.UnknownCompatibility

    let acquisition (account: Account option) =
        match account with
        | None -> Error SkseProblem.SignInRequired
        | Some account ->
            Ok(
                if account.Premium = Some true then
                    SkseAcquisition.Direct
                else
                    SkseAcquisition.NexusPage
            )

    let select state files account =
        resolve state files
        |> Result.bind (fun release ->
            acquisition account
            |> Result.map (fun route ->
                { Release = release
                  Acquisition = route }))
