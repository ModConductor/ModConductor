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
        match exactChild directory entries "meta.ini" with
        | Some entry when entry.TargetKind = EntryKind.RegularFile ->
            let observed = stamp root entry
            stamps.Add observed
            ini (text observed)
        | Some _ -> refuse (Error.UnsafeSource "A mod metadata file is not a regular file.")
        | None -> Dictionary<string * string, string>()

    let private installedFiles meta =
        qsettingsArray "installedFiles" meta
        |> List.map (fun item ->
            let number key =
                match item |> Map.tryFind key with
                | Some value ->
                    match Int32.TryParse value with
                    | true, parsed -> parsed
                    | _ -> 0
                | None -> 0

            number "modid", number "fileid")

    let private files root directory entries (stamps: ResizeArray<Stamp>) =
        entries
        |> List.choose (fun entry ->
            match components entry with
            | first :: rest when
                String.Equals(first, directory, StringComparison.Ordinal)
                && entry.TargetKind = EntryKind.RegularFile
                && not (
                    rest.Length = 1
                    && String.Equals(rest[0], "meta.ini", StringComparison.OrdinalIgnoreCase)
                )
                ->
                let logical =
                    LogicalPath.create rest
                    |> Result.defaultWith (fun _ ->
                        refuse (Error.InvalidSource "A mod file path is invalid."))

                let observed = stamp root entry
                stamps.Add observed
                Some { Stamp = observed; Path = logical }
            | _ -> None)

    let private readMod
        root
        entries
        directory
        (stamps: ResizeArray<Stamp>)
        (installationFiles: Dictionary<string, Guid>)
        =
        let id, versionId = Guid.NewGuid(), Guid.NewGuid()
        let kind = modKind directory
        let meta = metadata root directory entries stamps
        let get name = setting "General" name "" meta
        let categories = get "category" |> categoryIds
        let installationFile = get "installationFile"
        let installed = installedFiles meta

        if installationFile <> "" then
            installationFiles[Path.GetFileName installationFile] <- id

        let details =
            { Name = modName directory kind
              Notes = get "notes"
              Comment = get "comments"
              Version = get "version"
              Source = installationFile
              Categories = [] }

        InventoryPolicy.metadata details
        |> Result.defaultWith (fun _ ->
            refuse (Error.InvalidSource("The metadata is invalid for mod " + directory + ".")))
        |> ignore

        { Id = id
          VersionId = versionId
          Name = directory
          Kind = kind
          Metadata = details
          CategorySourceIds = categories
          InstalledFiles = installed
          Files = files root directory entries stamps }

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
        let stamps = ResizeArray<Stamp>()
        let installationFiles = Dictionary<string, Guid>(StringComparer.OrdinalIgnoreCase)

        let mods =
            rootDirectories entries
            |> List.map (fun directory -> readMod root entries directory stamps installationFiles)

        mods, List.ofSeq stamps, installationFiles, installedIds mods
