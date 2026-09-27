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

    let private otherStorefront (file: NexusFile) =
        [ file.Name; file.Description ]
        |> List.exists (fun text ->
            text.Contains("GOG", StringComparison.OrdinalIgnoreCase)
            || text.Contains("VR", StringComparison.OrdinalIgnoreCase))

    let private declaredRuntime (file: NexusFile) =
        let description = file.Description

        if String.IsNullOrWhiteSpace description then
            None
        else
            let parseAfter (marker: string) =
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
                        not (suffix.StartsWith("from Steam", StringComparison.OrdinalIgnoreCase))
                    then
                        None
                    else
                        tryRuntimeVersion value

            parseAfter "Compatible with Skyrim Special Edition "
            |> Option.orElseWith (fun () -> parseAfter "game version")

    let private applicable (file: NexusFile) =
        not (otherStorefront file)
        && (declaredRuntime file |> Option.isSome
            || [ file.Name; file.Description ]
               |> List.exists (fun text ->
                   text.Contains("Steam", StringComparison.OrdinalIgnoreCase)))

    let releases (value: NexusMod) =
        if value.Game <> "skyrimspecialedition" || value.Id <> NexusModId then
            []
        else
            value.Files
            |> List.choose (fun file ->
                match tryVersion file.Version with
                | Some releaseVersion when applicable file ->
                    Some
                        { ModId = value.Id
                          File = file
                          ComponentVersion = releaseVersion
                          DeclaredRuntimeVersion = declaredRuntime file }
                | _ -> None)

    let review (state: GameContextState) (available: SkseAuthorRelease list) =
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
            let executable = binding.Evidence.Executable.Value

            match tryRuntimeVersion executable.FileVersion with
            | None -> Error SkseProblem.UnknownCompatibility
            | Some runtime ->
                let ordered =
                    available
                    |> List.sortByDescending (fun release ->
                        release.ComponentVersion, release.File.Id)

                let exact =
                    ordered
                    |> List.tryFind (fun release -> release.DeclaredRuntimeVersion = Some runtime)

                match exact |> Option.orElseWith (fun () -> ordered |> List.tryHead) with
                | None -> Error SkseProblem.UnknownCompatibility
                | Some release ->
                    Ok
                        { GameVersion = executable.FileVersion
                          GameSha256 = executable.Sha256
                          RuntimeVersion = runtime
                          Release = release
                          Compatible = exact.IsSome }

    let private selected (review: SkseReview) =
        { ModId = review.Release.ModId
          File = review.Release.File
          ComponentVersion = review.Release.ComponentVersion
          RuntimeVersion = review.RuntimeVersion }

    let resolve state available =
        review state available
        |> Result.bind (fun value ->
            if value.Compatible then
                Ok(selected value)
            else
                Error SkseProblem.UnknownCompatibility)

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

    let selectReviewed state files account fileId version gameVersion gameSha256 allowIncompatible =
        review state files
        |> Result.bind (fun value ->
            if
                value.Compatible = allowIncompatible
                || value.Release.File.Id <> fileId
                || string value.Release.ComponentVersion <> version
                || value.GameVersion <> gameVersion
                || value.GameSha256 <> gameSha256
            then
                Error SkseProblem.SelectionChanged
            else
                acquisition account
                |> Result.map (fun route ->
                    { Release = selected value
                      Acquisition = route }))
