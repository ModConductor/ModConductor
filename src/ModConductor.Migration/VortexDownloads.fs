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
    open MigrationResult

    let private safeUrls value =
        result {
            match tryProperty "urls" value with
            | None -> return []
            | Some urls ->
                let! items = arrayItems "download addresses" urls

                let! addresses =
                    items
                    |> traverse (fun item ->
                        if item.ValueKind <> JsonValueKind.String then
                            invalid "A Vortex download address is invalid."
                        else
                            let address = item.GetString()

                            match Uri.TryCreate(address, UriKind.Absolute) with
                            | true, uri when
                                (uri.Scheme = Uri.UriSchemeHttp || uri.Scheme = Uri.UriSchemeHttps)
                                && String.IsNullOrEmpty uri.UserInfo
                                ->
                                let builder = UriBuilder uri
                                builder.Query <- ""
                                builder.Fragment <- ""
                                Ok(Some(builder.Uri.AbsoluteUri))
                            | _ -> Ok None)

                return addresses |> List.choose id |> List.distinct
        }

    let private downloadApplies (gameId: string) (value: JsonElement) =
        result {
            let! game = property "game" value
            let! items = arrayItems "download games" game

            let! ids =
                items
                |> traverse (fun item ->
                    if item.ValueKind <> JsonValueKind.String then
                        invalid "A Vortex download has an invalid game ID."
                    else
                        Ok(item.GetString()))

            return List.contains gameId ids
        }

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
        match
            entries
            |> List.tryFind (fun entry ->
                match components entry with
                | [ file ] -> file = name && entry.TargetKind = EntryKind.RegularFile
                | _ -> false)
        with
        | Some file -> Ok file
        | None -> invalid ("The download file is missing: " + name + ".")

    let private readArtifact
        (downloadRoot: SelectedRoot)
        (entries: PathEntry list)
        (installed: IDictionary<string, Guid>)
        id
        (value: JsonElement)
        =
        result {
            let! state = text "state" value

            if state <> "finished" then
                return! unsupported ("The Vortex download " + id + " is not finished.")

            let! name = text "localPath" value

            if
                name.Contains('/')
                || name.Contains('\\')
                || Path.GetFileName name <> name
                || not (archiveExtension name)
            then
                return! unsupported ("The Vortex download " + id + " is not a supported archive.")

            let! expectedLength = int64Value "size" value
            let! expectedMd5 = text "fileMD5" value

            if expectedMd5.Length <> 32 || not (expectedMd5 |> Seq.forall Uri.IsHexDigit) then
                return! invalid ("The Vortex download " + id + " has an invalid digest.")

            let! file = downloadFile entries name

            let! identity =
                match file.Facts.File with
                | Known value -> Ok value
                | Unknown detail -> Error(Error.UnsafeSource detail)

            let! stamp = observe downloadRoot file.Logical identity

            if
                stamp.Length <> expectedLength
                || not (stamp.Md5.Equals(expectedMd5, StringComparison.OrdinalIgnoreCase))
            then
                return! invalid ("The Vortex download " + id + " does not match its backup data.")

            let! logical =
                LogicalPath.create [ name ]
                |> Result.mapError (fun _ -> Error.InvalidSource "A download file name is invalid.")

            let! urls = safeUrls value

            let artifact: Direct.Artifact =
                { Id = Guid.NewGuid()
                  OriginalName = name
                  OriginalPath = HostPath.value file.Resolved
                  File = transferFile logical stamp
                  Partial = false
                  Sources = urls
                  InstalledMod =
                    match installed.TryGetValue id with
                    | true, modId -> Some modId
                    | _ -> None }

            return artifact, stamp
        }

    let private archiveReferences (mods: (ParsedMod * bool) list) =
        let references =
            mods
            |> List.choose (fun (item, _) -> item.ArchiveId |> Option.map (fun id -> id, item.Id))

        match references |> List.countBy fst |> List.tryFind (fun (_, count) -> count > 1) with
        | Some(id, _) -> unsupported ("More than one mod uses the Vortex download " + id + ".")
        | None -> Ok references

    let artifacts
        (persistent: JsonElement)
        (gameId: string)
        (downloadRoot: SelectedRoot)
        (entries: PathEntry list)
        (mods: (ParsedMod * bool) list)
        =
        result {
            let! references = archiveReferences mods
            let installed = references |> dict
            let required = references |> List.map fst |> Set.ofList
            let found = HashSet<string>(StringComparer.Ordinal)
            let stamps = ResizeArray<Stamp>()
            let! downloads = property "downloads" persistent
            let! downloadFiles = property "files" downloads
            let! files = objectEntries "downloads" downloadFiles

            let! artifacts =
                files
                |> traverse (fun entry ->
                    result {
                        let value = entry.Value
                        let! id = text "id" value

                        if id <> entry.Name then
                            return! invalid "A Vortex download ID does not match its backup key."

                        let! appliesToGame = downloadApplies gameId value

                        if not (required.Contains id || appliesToGame) then
                            return None
                        else
                            found.Add id |> ignore

                            let! artifact, stamp =
                                readArtifact downloadRoot entries installed id value

                            stamps.Add stamp
                            return Some artifact
                    })

            for id in required do
                if not (found.Contains id) then
                    return! invalid ("The backup is missing the download used by mod " + id + ".")

            return List.choose id artifacts, List.ofSeq stamps
        }
