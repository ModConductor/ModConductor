namespace ModConductor.Migration

open System
open System.Collections.Generic
open System.IO
open ModConductor.Platform

module internal ModOrganizerDownloads =
    open ModOrganizerInput
    open ModOrganizerSettings
    open MigrationResult

    let private safeSource (value: string) =
        match Uri.TryCreate(value, UriKind.Absolute) with
        | true, uri when
            (uri.Scheme = Uri.UriSchemeHttp || uri.Scheme = Uri.UriSchemeHttps)
            && String.IsNullOrEmpty uri.UserInfo
            ->
            let builder = UriBuilder uri
            builder.Query <- ""
            builder.Fragment <- ""
            Some(builder.Uri.AbsoluteUri)
        | _ -> None

    let readArtifacts
        root
        entries
        (installationFiles: Dictionary<string, Guid>)
        (installedIds: Dictionary<string, Guid option>)
        =
        result {
            let extensions =
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

            let byName = Dictionary<string, PathEntry>(StringComparer.OrdinalIgnoreCase)

            for entry in entries do
                match components entry with
                | [ name ] -> byName[name] <- entry
                | _ -> ()

            let artifacts = ResizeArray<SourceArtifact>()
            let stamps = ResizeArray<Stamp>()

            for entry in entries do
                match components entry with
                | [ name ] when
                    entry.TargetKind = EntryKind.RegularFile
                    && not (name.EndsWith(".meta", StringComparison.OrdinalIgnoreCase))
                    ->
                    let unfinished =
                        name.EndsWith(".unfinished", StringComparison.OrdinalIgnoreCase)

                    let originalName =
                        if unfinished then
                            name.Substring(0, name.Length - ".unfinished".Length)
                        else
                            name

                    let extension =
                        Path.GetExtension originalName |> fun value -> value.ToLowerInvariant()

                    if extensions.Contains extension then
                        let! fileStamp = stamp root entry
                        stamps.Add fileStamp

                        let! sources, installed, paused, providerMod, providerFile =
                            match byName.TryGetValue(name + ".meta") with
                            | true, sidecar ->
                                result {
                                    let! sidecarStamp = stamp root sidecar
                                    stamps.Add sidecarStamp
                                    let! content = text sidecarStamp
                                    let values = ini content

                                    let urls =
                                        (setting "General" "url" "" values)
                                            .Split(
                                                ';',
                                                StringSplitOptions.RemoveEmptyEntries
                                                ||| StringSplitOptions.TrimEntries
                                            )
                                        |> Array.choose safeSource
                                        |> Array.distinct
                                        |> Array.toList

                                    let installed = boolSetting "installed" values
                                    let paused = boolSetting "paused" values

                                    let number name =
                                        match Int32.TryParse(setting "General" name "0" values) with
                                        | true, parsed -> parsed
                                        | _ -> 0

                                    return urls, installed, paused, number "modID", number "fileID"
                                }
                            | _ -> Ok([], false, false, 0, 0)

                        let partial = unfinished || paused

                        if partial && sources.IsEmpty then
                            return!
                                Error(
                                    Error.UnsupportedData(
                                        "The paused download "
                                        + originalName
                                        + " has no safe download address."
                                    )
                                )

                        let installedMod =
                            let byProvider =
                                let key = string providerMod + ":" + string providerFile

                                match installedIds.TryGetValue key with
                                | true, value -> value
                                | _ -> None

                            if byProvider.IsSome then
                                byProvider
                            elif installed then
                                match installationFiles.TryGetValue originalName with
                                | true, id -> Some id
                                | _ -> None
                            else
                                None

                        let! logical =
                            LogicalPath.create [ originalName ]
                            |> Result.mapError (fun _ ->
                                Error.InvalidSource "A download file name is invalid.")

                        artifacts.Add
                            { Id = Guid.NewGuid()
                              OriginalName = originalName
                              OriginalPath = HostPath.value entry.Resolved
                              File = { Stamp = fileStamp; Path = logical }
                              Partial = partial
                              Sources = sources
                              InstalledMod = installedMod }
                | _ -> ()

            return List.ofSeq artifacts, List.ofSeq stamps
        }
