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

    let private tryRuntimeVersion (value: string) =
        match tryVersion value with
        | Some parsed when parsed.Build >= 0 ->
            Some(Version(parsed.Major, parsed.Minor, parsed.Build, max 0 parsed.Revision))
        | _ -> None

    let private declaredRuntime (file: NexusFile) =
        let description = file.Description

        if String.IsNullOrWhiteSpace description then
            None
        elif
            [ file.Name; description ]
            |> List.exists (fun text ->
                text.Contains("GOG", StringComparison.OrdinalIgnoreCase)
                || text.Contains("VR", StringComparison.OrdinalIgnoreCase))
        then
            None
        else
            let parseAfter (marker: string) (requiredSuffix: string option) =
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

                    let suffix = tail.Substring(value.Length).Trim()

                    if
                        requiredSuffix
                        |> Option.exists (fun expected ->
                            not (String.Equals(suffix, expected, StringComparison.OrdinalIgnoreCase)))
                    then
                        None
                    else
                        tryRuntimeVersion value

            parseAfter "Compatible with Skyrim Special Edition " (Some "from Steam")
            |> Option.orElseWith (fun () -> parseAfter "game version" (Some "from Steam"))

    let releases (value: NexusMod) =
        if value.Game <> "skyrimspecialedition" || value.Id <> NexusModId then
            []
        else
            value.Files
            |> List.choose (fun file ->
                match tryVersion file.Version, declaredRuntime file with
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
            match tryRuntimeVersion binding.Evidence.Executable.Value.FileVersion with
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
