namespace ModConductor.Migration

open System
open System.Collections.Generic
open System.IO
open System.Text.RegularExpressions
open ModConductor.ModLibrary
open ModConductor.Platform

module internal ModOrganizerMods =
    open ModOrganizerInput
    open ModOrganizerSettings
    open MigrationResult

    let private modKind (name: string) =
        if name.EndsWith("_separator", StringComparison.OrdinalIgnoreCase) then
            ModKind.Separator
        elif
            Regex.IsMatch(
                name,
                "backup[0-9]*$",
                RegexOptions.IgnoreCase ||| RegexOptions.CultureInvariant
            )
        then
            ModKind.Backup
        else
            ModKind.Regular

    let private modName (name: string) kind =
        if
            kind = ModKind.Separator
            && name.EndsWith("_separator", StringComparison.OrdinalIgnoreCase)
        then
            name.Substring(0, name.Length - "_separator".Length)
        else
            name

    let private metadata root directory entries (stamps: ResizeArray<Stamp>) =
        result {
            match exactChild directory entries "meta.ini" with
            | Some entry when entry.TargetKind = EntryKind.RegularFile ->
                let! observed = stamp root entry
                stamps.Add observed
                let! content = text observed
                return ini content
            | Some _ ->
                return! Error(Error.UnsafeSource "A mod metadata file is not a regular file.")
            | None -> return Dictionary<string * string, string>()
        }

    let private installedFiles meta =
        result {
            let! values = qsettingsArray "installedFiles" meta

            return
                values
                |> List.map (fun item ->
                    let number key =
                        match item |> Map.tryFind key with
                        | Some value ->
                            match Int32.TryParse value with
                            | true, parsed -> parsed
                            | _ -> 0
                        | None -> 0

                    number "modid", number "fileid")
        }

    let private files root directory entries (stamps: ResizeArray<Stamp>) =
        result {
            let files = ResizeArray<SourceFile>()

            for entry in entries do
                match components entry with
                | first :: rest when
                    String.Equals(first, directory, StringComparison.Ordinal)
                    && entry.TargetKind = EntryKind.RegularFile
                    && not (
                        rest.Length = 1
                        && String.Equals(rest[0], "meta.ini", StringComparison.OrdinalIgnoreCase)
                    )
                    ->
                    let! logical =
                        LogicalPath.create rest
                        |> Result.mapError (fun _ ->
                            Error.InvalidSource "A mod file path is invalid.")

                    let! observed = stamp root entry
                    stamps.Add observed
                    files.Add { Stamp = observed; Path = logical }
                | _ -> ()

            return List.ofSeq files
        }

    let private readMod
        root
        entries
        directory
        (stamps: ResizeArray<Stamp>)
        (installationFiles: Dictionary<string, Guid>)
        =
        result {
            let id, versionId = Guid.NewGuid(), Guid.NewGuid()
            let kind = modKind directory
            let! meta = metadata root directory entries stamps
            let get name = setting "General" name "" meta
            let categories = get "category" |> categoryIds
            let installationFile = get "installationFile"
            let! installed = installedFiles meta

            if installationFile <> "" then
                installationFiles[Path.GetFileName installationFile] <- id

            let details =
                { Name = modName directory kind
                  Notes = get "notes"
                  Comment = get "comments"
                  Version = get "version"
                  Source = installationFile
                  Categories = [] }

            do!
                InventoryPolicy.metadata details
                |> Result.mapError (fun _ ->
                    Error.InvalidSource("The metadata is invalid for mod " + directory + "."))
                |> Result.map ignore

            let! modFiles = files root directory entries stamps

            return
                { Id = id
                  VersionId = versionId
                  Name = directory
                  Kind = kind
                  Metadata = details
                  CategorySourceIds = categories
                  InstalledFiles = installed
                  Files = modFiles }
        }

    let private installedIds (mods: SourceMod list) =
        let installedIds = Dictionary<string, Guid option>(StringComparer.Ordinal)

        for item in mods do
            for modId, fileId in item.InstalledFiles do
                if modId > 0 && fileId > 0 then
                    let key = string modId + ":" + string fileId

                    match installedIds.TryGetValue key with
                    | true, Some existing when existing <> item.Id -> installedIds[key] <- None
                    | true, _ -> ()
                    | false, _ -> installedIds.Add(key, Some item.Id)

        installedIds

    let readMods root entries =
        result {
            let stamps = ResizeArray<Stamp>()
            let installationFiles = Dictionary<string, Guid>(StringComparer.OrdinalIgnoreCase)

            let! mods =
                rootDirectories entries
                |> traverse (fun directory ->
                    readMod root entries directory stamps installationFiles)

            return mods, List.ofSeq stamps, installationFiles, installedIds mods
        }
