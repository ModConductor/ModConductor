namespace ModConductor.Migration

open System
open System.Collections.Generic
open System.IO
open System.Text.Json
open ModConductor.Platform

module internal VortexDownloads =
    open VortexSource
    open VortexJson
    open VortexMods

    let private safeUrls value =
        match tryProperty "urls" value with
        | None -> []
        | Some urls ->
            arrayItems "download addresses" urls
            |> List.choose (fun item ->
                if item.ValueKind <> JsonValueKind.String then
                    invalid "A Vortex download address is invalid."

                let address = item.GetString()

                match Uri.TryCreate(address, UriKind.Absolute) with
                | true, uri when
                    (uri.Scheme = Uri.UriSchemeHttp || uri.Scheme = Uri.UriSchemeHttps)
                    && String.IsNullOrEmpty uri.UserInfo
                    ->
                    let builder = UriBuilder uri
                    builder.Query <- ""
                    builder.Fragment <- ""
                    Some(builder.Uri.AbsoluteUri)
                | _ -> None)
            |> List.distinct

    let private downloadApplies (gameId: string) (value: JsonElement) =
        property "game" value
        |> arrayItems "download games"
        |> List.map (fun item ->
            if item.ValueKind <> JsonValueKind.String then
                invalid "A Vortex download has an invalid game ID."

            item.GetString())
        |> List.contains gameId

    let private archiveExtension (name: string) =
        set
            [ ".001"
              ".7z"
              ".zip"
              ".rar"
              ".omod"
              ".fomod"
              ".tar"
              ".gz"
              ".bz2"
              ".xz" ]
        |> Set.contains (Path.GetExtension(name).ToLowerInvariant())

    let private downloadFile (entries: PathEntry list) (name: string) =
        entries
        |> List.tryFind (fun entry ->
            match components entry with
            | [ file ] -> file = name && entry.TargetKind = EntryKind.RegularFile
            | _ -> false)
        |> Option.defaultWith (fun () -> invalid ("The download file is missing: " + name + "."))

    let private readArtifact
        (downloadRoot: SelectedRoot)
        (entries: PathEntry list)
        (installed: IDictionary<string, Guid>)
        id
        (value: JsonElement)
        =
        if text "state" value <> "finished" then
            unsupported ("The Vortex download " + id + " is not finished.")

        let name = text "localPath" value

        if
            name.Contains('/')
            || name.Contains('\\')
            || Path.GetFileName name <> name
            || not (archiveExtension name)
        then
            unsupported ("The Vortex download " + id + " is not a supported archive.")

        let expectedLength = int64Value "size" value
        let expectedMd5 = text "fileMD5" value

        if expectedMd5.Length <> 32 || not (expectedMd5 |> Seq.forall Uri.IsHexDigit) then
            invalid ("The Vortex download " + id + " has an invalid digest.")

        let file = downloadFile entries name

        let identity =
            match file.Facts.File with
            | Known value -> value
            | Unknown detail -> refuse (Error.UnsafeSource detail)

        let stamp = observe downloadRoot file.Logical identity

        if
            stamp.Length <> expectedLength
            || not (stamp.Md5.Equals(expectedMd5, StringComparison.OrdinalIgnoreCase))
        then
            invalid ("The Vortex download " + id + " does not match its backup data.")

        let logical =
            LogicalPath.create [ name ]
            |> Result.defaultWith (fun _ -> invalid "A download file name is invalid.")

        let artifact: Direct.Artifact =
            { Id = Guid.NewGuid()
              OriginalName = name
              OriginalPath = HostPath.value file.Resolved
              File = transferFile logical stamp
              Partial = false
              Sources = safeUrls value
              InstalledMod =
                match installed.TryGetValue id with
                | true, modId -> Some modId
                | _ -> None }

        artifact, stamp

    let private archiveReferences (mods: (ParsedMod * bool) list) =
        let references =
            mods
            |> List.choose (fun (item, _) -> item.ArchiveId |> Option.map (fun id -> id, item.Id))

        references
        |> List.countBy fst
        |> List.tryFind (fun (_, count) -> count > 1)
        |> Option.iter (fun (id, _) ->
            unsupported ("More than one mod uses the Vortex download " + id + "."))

        references

    let artifacts
        (persistent: JsonElement)
        (gameId: string)
        (downloadRoot: SelectedRoot)
        (entries: PathEntry list)
        (mods: (ParsedMod * bool) list)
        =
        let references = archiveReferences mods
        let installed = references |> dict
        let required = references |> List.map fst |> Set.ofList
        let found = HashSet<string>(StringComparer.Ordinal)
        let stamps = ResizeArray<Stamp>()
        let downloads = property "downloads" persistent
        let files = property "files" downloads |> objectEntries "downloads"

        let artifacts =
            files
            |> List.choose (fun entry ->
                let value = entry.Value
                let id = text "id" value

                if id <> entry.Name then
                    invalid "A Vortex download ID does not match its backup key."

                let appliesToGame = downloadApplies gameId value

                if not (required.Contains id || appliesToGame) then
                    None
                else
                    found.Add id |> ignore
                    let artifact, stamp = readArtifact downloadRoot entries installed id value
                    stamps.Add stamp
                    Some artifact)

        required
        |> Set.iter (fun id ->
            if not (found.Contains id) then
                invalid ("The backup is missing the download used by mod " + id + "."))

        artifacts, List.ofSeq stamps
