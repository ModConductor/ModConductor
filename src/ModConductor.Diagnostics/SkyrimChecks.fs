namespace ModConductor.Diagnostics

open System
open System.IO
open System.Threading
open ModConductor.Bethesda
open ModConductor.DeploymentPlanning

[<RequireQualifiedAccess>]
type internal SksePluginProblem =
    | Failed
    | Incompatible

type internal SksePluginIssue =
    { Name: string
      Problem: SksePluginProblem }

[<RequireQualifiedAccess>]
type internal SkseLogResult =
    | Missing
    | Stale of DateTimeOffset
    | Malformed of string
    | Current of SksePluginIssue list

type internal OldPluginFormat =
    { Name: string
      FormVersion: uint16
      Owner: string option }

module internal SkyrimChecks =
    let private maxLogBytes = 2L * 1024L * 1024L
    let private maxLineChars = 64 * 1024
    let private maxIssues = 64

    let private dllName (line: string) =
        let finish = line.IndexOf(".dll", StringComparison.OrdinalIgnoreCase)

        if finish < 0 then
            None
        else
            let before = line.Substring(0, finish + 4)
            let slash = max (before.LastIndexOf('/')) (before.LastIndexOf('\\'))
            let quote = before.LastIndexOf('"')
            let plugin = before.LastIndexOf("plugin ", StringComparison.OrdinalIgnoreCase)

            let start =
                if slash >= 0 then
                    slash + 1
                elif quote >= 0 then
                    quote + 1
                elif plugin >= 0 then
                    plugin + 7
                else
                    let whitespace = before.LastIndexOfAny([| ' '; '\t'; ':'; '['; '(' |])
                    whitespace + 1

            let name = before.Substring(start).Trim([| ' '; '\t'; '"'; '\''; ')'; ']'; ':' |])

            if
                name.Length > 0
                && name.Length <= 260
                && name.EndsWith(".dll", StringComparison.OrdinalIgnoreCase)
                && name.IndexOfAny([| '/'; '\\'; '\000' |]) < 0
            then
                Some name
            else
                None

    let private decodeLog (bytes: byte array) =
        let cp1252 value =
            match value with
            | 0x80uy -> '€'
            | 0x82uy -> '‚'
            | 0x83uy -> 'ƒ'
            | 0x84uy -> '„'
            | 0x85uy -> '…'
            | 0x86uy -> '†'
            | 0x87uy -> '‡'
            | 0x88uy -> 'ˆ'
            | 0x89uy -> '‰'
            | 0x8auy -> 'Š'
            | 0x8buy -> '‹'
            | 0x8cuy -> 'Œ'
            | 0x8euy -> 'Ž'
            | 0x91uy -> '‘'
            | 0x92uy -> '’'
            | 0x93uy -> '“'
            | 0x94uy -> '”'
            | 0x95uy -> '•'
            | 0x96uy -> '–'
            | 0x97uy -> '—'
            | 0x98uy -> '˜'
            | 0x99uy -> '™'
            | 0x9auy -> 'š'
            | 0x9buy -> '›'
            | 0x9cuy -> 'œ'
            | 0x9euy -> 'ž'
            | 0x9fuy -> 'Ÿ'
            | byte -> char byte

        bytes |> Array.map cp1252 |> String

    let parseLog (text: string) =
        if String.IsNullOrWhiteSpace text then
            Error "The SKSE log is empty."
        else
            let lines = text.Split([| "\r\n"; "\n"; "\r" |], StringSplitOptions.None)

            if lines |> Array.exists (fun line -> line.Length > maxLineChars) then
                Error "An SKSE log line exceeds the 64 KiB read limit."
            else
                let issues = ResizeArray<SksePluginIssue>()
                let seen = Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase)

                for line in lines do
                    let lower = line.ToLowerInvariant()

                    let problem =
                        if
                            lower.Contains "incompatible"
                            || lower.Contains "address library needs to be updated"
                            || lower.Contains "bad version data"
                            || lower.Contains "unsupported version independence method"
                            || lower.Contains "requires newer script extender"
                        then
                            Some SksePluginProblem.Incompatible
                        elif
                            lower.Contains "couldn't load"
                            || lower.Contains "could not load"
                            || lower.Contains "failed to load"
                            || lower.Contains "disabled,"
                            || lower.Contains "does not appear to be an"
                        then
                            Some SksePluginProblem.Failed
                        else
                            None

                    match problem, dllName line with
                    | Some problem, Some name when seen.Add name ->
                        issues.Add { Name = name; Problem = problem }
                    | _ -> ()

                if issues.Count > maxIssues then
                    Error "The SKSE log contains more than 64 plugin problems."
                else
                    Ok(List.ofSeq issues)

    let readLog documents launchedAt (token: CancellationToken) =
        let path = Path.Combine(documents, "SKSE", "skse64.log")

        try
            use stream =
                File.Open(
                    path,
                    FileMode.Open,
                    FileAccess.Read,
                    FileShare.ReadWrite ||| FileShare.Delete
                )

            if stream.Length > maxLogBytes then
                SkseLogResult.Malformed "The SKSE log exceeds the 2 MiB read limit."
            else
                let length = stream.Length
                let modified = File.GetLastWriteTimeUtc stream.SafeFileHandle
                let bytes = Array.zeroCreate<byte> (int length)
                stream.ReadExactly bytes
                token.ThrowIfCancellationRequested()

                if
                    stream.Length <> length
                    || File.GetLastWriteTimeUtc stream.SafeFileHandle <> modified
                then
                    SkseLogResult.Malformed "The SKSE log changed during the check."
                else
                    match launchedAt with
                    | Some launched when DateTimeOffset modified < launched ->
                        SkseLogResult.Stale(DateTimeOffset modified)
                    | _ ->
                        decodeLog bytes
                        |> parseLog
                        |> function
                            | Ok issues -> SkseLogResult.Current issues
                            | Error detail -> SkseLogResult.Malformed detail
        with
        | :? FileNotFoundException
        | :? DirectoryNotFoundException -> SkseLogResult.Missing
        | :? IOException -> SkseLogResult.Malformed "The SKSE log cannot be read."
        | :? UnauthorizedAccessException -> SkseLogResult.Malformed "The SKSE log cannot be read."

    let oldPluginFormats (snapshot: PluginSnapshot) (settings: PluginSetting list) =
        let enabled =
            Collections.Generic.HashSet<string>(
                settings
                |> List.choose (fun setting ->
                    if setting.Enabled = Some true then
                        Some setting.Name
                    else
                        None),
                StringComparer.OrdinalIgnoreCase
            )

        snapshot.Entries
        |> List.choose (fun entry ->
            let extension = Path.GetExtension(entry.Name)

            match entry.Header with
            | Ok header when
                enabled.Contains entry.Name
                && (extension.Equals(".esm", StringComparison.OrdinalIgnoreCase)
                    || extension.Equals(".esp", StringComparison.OrdinalIgnoreCase))
                && header.FormVersion < 44us
                ->
                let owner =
                    entry.Winner
                    |> Option.bind (fun source ->
                        match source.Source with
                        | CandidateSource.Pinned(SourcePin.Mod _) -> Some source.Name
                        | _ -> None)

                Some
                    { Name = entry.Name
                      FormVersion = header.FormVersion
                      Owner = owner }
            | _ -> None)
