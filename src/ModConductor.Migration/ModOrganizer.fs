namespace ModConductor.Migration

open System
open System.Collections.Generic
open System.Globalization
open System.IO
open System.Security.Cryptography
open System.Text
open System.Text.RegularExpressions
open System.Threading
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform

module ModOrganizer =
    let private maxEntries = 100000
    let private maxDepth = 64
    let private maxTextBytes = 4 * 1024 * 1024

    type private Stamp =
        { Root: SelectedRoot
          Path: LogicalPath
          Identity: FileIdentity
          Length: int64
          Sha256: string }

    type private Manifest =
        { Path: string
          RootIdentity: FileIdentity
          Entries: (string * EntryKind * EntryKind * Observation<FileIdentity>) list
          Diagnostics: PathDiagnostic list }

    type private SourceFile = { Stamp: Stamp; Path: LogicalPath }

    type private SourceMod =
        { Id: Guid
          VersionId: Guid
          Name: string
          Kind: ModKind
          Metadata: ModMetadata
          CategorySourceIds: int list
          InstalledFiles: (int * int) list
          Files: SourceFile list }

    type private SourceProfile =
        { Id: Guid
          Name: string
          Mods: OrderedMod list }

    type private SourceArtifact =
        { Id: Guid
          OriginalName: string
          OriginalPath: string
          File: SourceFile
          Partial: bool
          Sources: string list
          InstalledMod: Guid option }

    type private Source =
        { Categories: Category list
          Mods: SourceMod list
          Profiles: SourceProfile list
          SelectedProfile: Guid
          Artifacts: SourceArtifact list
          Stamps: Stamp list
          Manifests: Manifest list
          AbsentPaths: string list }

    exception private Refused of Error

    let private refuse error = raise (Refused error)

    let private rootIdentity root =
        match (RootSelection.facts root).File with
        | Known identity -> identity
        | Unknown detail -> refuse (Error.UnsafeSource detail)

    let private digest (stream: Stream) =
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        let buffer = Array.zeroCreate<byte> 65536
        let mutable length = 0L
        let mutable reading = true

        while reading do
            let count = stream.Read(buffer, 0, buffer.Length)

            if count = 0 then
                reading <- false
            else
                length <- length + int64 count
                hash.AppendData(buffer, 0, count)

        length, Convert.ToHexStringLower(hash.GetHashAndReset())

    let private openEntry root path expected =
        let components = LogicalPath.components path
        let mutable current = HeldDirectory.Open(RootSelection.path root, rootIdentity root)
        let parents = ResizeArray<HeldDirectory>()

        try
            for name in components |> List.take (components.Length - 1) do
                let next = current.Directory(name, None)
                parents.Add current
                current <- next

            let stream, identity = current.Read(List.last components, Some expected)
            stream, identity
        finally
            (current :> IDisposable).Dispose()

            for parent in parents do
                (parent :> IDisposable).Dispose()

    let private observe root path identity =
        let stream, actual = openEntry root path identity
        use stream = stream
        let length, sha = digest stream

        { Root = root
          Path = path
          Identity = actual
          Length = length
          Sha256 = sha }

    let private selectedRoot (path: string) =
        match HostPath.create path with
        | Error _ -> refuse (Error.InvalidSource "The selected source folder is unavailable.")
        | Ok value ->
            RootSelection.select value
            |> Result.defaultWith (fun _ ->
                refuse (Error.InvalidSource "The selected source folder is unavailable."))

    let private directFile (path: string) =
        let parent = Path.GetDirectoryName path
        let root = selectedRoot parent

        let logical =
            LogicalPath.create [ Path.GetFileName path ]
            |> Result.defaultWith (fun _ ->
                refuse (Error.InvalidSource "A source file name is invalid."))

        let entry =
            use directory = HeldDirectory.Open(RootSelection.path root, rootIdentity root)

            match directory.InspectEntry(Path.GetFileName path) with
            | Some value when value.Kind = EntryKind.RegularFile -> value
            | Some _ ->
                refuse (Error.UnsafeSource "A source file is a link or unsupported file type.")
            | None -> refuse (Error.InvalidSource "A required source file is missing.")

        observe root logical entry.Identity

    let private bytes stamp =
        if stamp.Length > int64 maxTextBytes then
            refuse (Error.InvalidSource "A Mod Organizer settings file is too large.")

        let stream, _ = openEntry stamp.Root stamp.Path stamp.Identity
        use stream = stream
        let content = Array.zeroCreate<byte> (int stamp.Length)
        stream.ReadExactly content
        content

    let private text stamp =
        try
            let value = bytes stamp

            let offset =
                if value.Length >= 3 && value[0..2] = [| 0xEFuy; 0xBBuy; 0xBFuy |] then
                    3
                else
                    0

            UTF8Encoding(false, true).GetString(value, offset, value.Length - offset)
        with :? DecoderFallbackException ->
            refuse (Error.InvalidSource "A Mod Organizer text file is not valid UTF-8.")

    let private unescape (value: string) =
        let result = StringBuilder(value.Length)
        let mutable index = 0

        while index < value.Length do
            if value[index] <> '\\' || index + 1 >= value.Length then
                result.Append(value[index]) |> ignore
                index <- index + 1
            else
                let next = value[index + 1]

                match next with
                | '\\' ->
                    result.Append('\\') |> ignore
                    index <- index + 2
                | 'n' ->
                    result.Append('\n') |> ignore
                    index <- index + 2
                | 'r' ->
                    result.Append('\r') |> ignore
                    index <- index + 2
                | 't' ->
                    result.Append('\t') |> ignore
                    index <- index + 2
                | 'x' when index + 3 < value.Length ->
                    let mutable finish = index + 2

                    while finish < value.Length
                          && finish < index + 6
                          && Uri.IsHexDigit value[finish] do
                        finish <- finish + 1

                    if finish = index + 2 then
                        result.Append('x') |> ignore
                        index <- index + 2
                    else
                        let number =
                            Int32.Parse(
                                value.Substring(index + 2, finish - index - 2),
                                NumberStyles.HexNumber
                            )

                        result.Append(char number) |> ignore
                        index <- finish
                | other ->
                    result.Append(other) |> ignore
                    index <- index + 2

        result.ToString()

    let private settingValue (value: string) =
        let trimmed = value.Trim()

        if
            trimmed.StartsWith("@ByteArray(", StringComparison.Ordinal)
            && trimmed.EndsWith(')')
        then
            unescape (trimmed.Substring(11, trimmed.Length - 12))
        else
            unescape trimmed

    let private ini (content: string) =
        let values = Dictionary<string * string, string>()
        let mutable section = ""

        for raw in content.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n') do
            let line = raw.Trim()

            if line.StartsWith('[') && line.EndsWith(']') && line.Length > 2 then
                section <- line.Substring(1, line.Length - 2)
            elif line <> "" && not (line.StartsWith(';')) && not (line.StartsWith('#')) then
                let split = line.IndexOf('=')

                if split > 0 then
                    values[(section, line.Substring(0, split).Trim())] <-
                        settingValue (line.Substring(split + 1))

        values

    let private qsettingsArray section (values: Dictionary<string * string, string>) =
        let size =
            match values.TryGetValue((section, "size")) with
            | false, _ -> 0
            | true, value ->
                match Int32.TryParse value with
                | true, count when count >= 0 && count <= maxEntries -> count
                | _ ->
                    refuse (
                        Error.InvalidSource("A Mod Organizer metadata array has an invalid size.")
                    )

        [ for index in 1..size do
              let prefix = string index + "\\"

              yield
                  values
                  |> Seq.choose (fun item ->
                      let itemSection, key = item.Key

                      if
                          itemSection = section && key.StartsWith(prefix, StringComparison.Ordinal)
                      then
                          Some(key.Substring(prefix.Length), item.Value)
                      else
                          None)
                  |> Map.ofSeq ]

    let private trySetting section name (values: Dictionary<string * string, string>) =
        match values.TryGetValue((section, name)) with
        | true, value -> Some value
        | _ when section = "General" ->
            match values.TryGetValue(("", name)) with
            | true, value -> Some value
            | _ -> None
        | _ -> None

    let private setting section name fallback values =
        trySetting section name values |> Option.defaultValue fallback

    let private path basePath fallback key values =
        let value = setting "Settings" key fallback values

        let expanded =
            value.Replace("%BASE_DIR%", basePath, StringComparison.OrdinalIgnoreCase)

        let normalized = expanded.Replace('/', Path.DirectorySeparatorChar)

        if Path.IsPathFullyQualified normalized then
            Path.GetFullPath normalized
        else
            Path.GetFullPath(Path.Combine(basePath, normalized))

    let private inspectRoot path =
        let root = selectedRoot path

        let result =
            PathPreflight.inspect
                { Candidates = maxEntries
                  Depth = maxDepth
                  Diagnostics = 64 }
                TargetPolicy.windows
                root

        let manifest =
            { Path = Path.GetFullPath path
              RootIdentity = rootIdentity root
              Entries =
                result.Entries
                |> List.map (fun entry ->
                    LogicalPath.display entry.Logical,
                    entry.Kind,
                    entry.TargetKind,
                    entry.Facts.File)
                |> List.sortBy (fun (path, _, _, _) -> path)
              Diagnostics = result.Diagnostics |> List.sortBy (fun item -> item.Path) }

        root, result, manifest

    let private scanRoot path =
        let root, result, manifest = inspectRoot path

        result.Diagnostics
        |> List.tryFind (fun item ->
            item.Problem = TargetCollision || item.Problem = FileDirectoryConflict)
        |> Option.iter (fun item -> refuse (Error.CaseCollision item.Path))

        result.Diagnostics
        |> List.tryHead
        |> Option.iter (fun item ->
            refuse (Error.UnsafeSource("The source entry is unsafe: " + item.Path)))

        result.Entries
        |> List.tryFind (fun item -> item.Kind = EntryKind.Link || item.Kind = EntryKind.Other)
        |> Option.iter (fun item ->
            refuse (
                Error.UnsafeSource(
                    "The source entry is a link or unsupported file: "
                    + LogicalPath.display item.Logical
                )
            ))

        root, result.Entries, manifest

    let private verifyManifest (expected: Manifest) =
        let current =
            try
                let _, _, value = inspectRoot expected.Path
                Some value
            with
            | :? IOException
            | :? UnauthorizedAccessException
            | Refused _ -> None

        if current <> Some expected then
            refuse Error.SourceChanged

    let private pathExists (path: string) =
        try
            File.GetAttributes path |> ignore
            true
        with
        | :? FileNotFoundException
        | :? DirectoryNotFoundException -> false

    let private stamp root (entry: PathEntry) =
        match entry.Facts.File with
        | Known identity -> observe root entry.Logical identity
        | Unknown detail -> refuse (Error.UnsafeSource detail)

    let private components (entry: PathEntry) = LogicalPath.components entry.Logical

    let private exactChild parent (entries: PathEntry list) name =
        entries
        |> List.tryFind (fun entry ->
            match components entry with
            | [ first; second ] ->
                String.Equals(first, parent, StringComparison.Ordinal)
                && String.Equals(second, name, StringComparison.OrdinalIgnoreCase)
            | _ -> false)

    let private boolSetting name values =
        trySetting "General" name values
        |> Option.exists (fun value ->
            value = "1" || value.Equals("true", StringComparison.OrdinalIgnoreCase))

    let private meaningfulLines (content: string) =
        content.Replace("\r\n", "\n").Split('\n')
        |> Array.exists (fun line ->
            let value = line.Trim()
            value <> "" && not (value.StartsWith('#')) && not (value.StartsWith(';')))

    let private categoryPaths (sourceFolder: string) (basePath: string) =
        [ Path.Combine(sourceFolder, "categories.dat")
          Path.Combine(basePath, "categories.dat") ]
        |> List.distinct

    let private readCategories (sourceFolder: string) (basePath: string) =
        let candidates = categoryPaths sourceFolder basePath

        match candidates |> List.tryFind File.Exists with
        | None -> [], [], candidates
        | Some path ->
            let categoryStamp = directFile path
            let mutable categories = []
            let ids = HashSet<int>()

            for raw in (text categoryStamp).Replace("\r\n", "\n").Split('\n') do
                let line = raw.Trim()

                if line <> "" && not (line.StartsWith('#')) then
                    let cells = line.Split('|')

                    if cells.Length <> 3 && cells.Length <> 4 then
                        refuse (Error.InvalidSource "categories.dat contains an invalid row.")

                    let mutable id = 0
                    let parentCell = cells[if cells.Length = 3 then 2 else 3]
                    let mutable parent = 0

                    if not (Int32.TryParse(cells[0], &id)) || id <= 0 || not (ids.Add id) then
                        refuse (
                            Error.InvalidSource "categories.dat contains an invalid category ID."
                        )

                    let parentId =
                        if parentCell = "" || parentCell = "0" then
                            None
                        elif Int32.TryParse(parentCell, &parent) && parent > 0 then
                            Some parent
                        else
                            refuse (
                                Error.InvalidSource
                                    "categories.dat contains an invalid parent category."
                            )

                    categories <-
                        { SourceId = id
                          Label = cells[1].Trim()
                          ParentSourceId = parentId }
                        :: categories

            let mapping = Path.Combine(Path.GetDirectoryName path, "nexuscatmap.dat")
            let stamps = ResizeArray<Stamp>()
            stamps.Add categoryStamp

            let absent =
                candidates
                |> List.filter (fun candidate -> not (pathExists candidate))
                |> fun values -> if pathExists mapping then values else mapping :: values

            if File.Exists mapping then
                let mappingStamp = directFile mapping
                stamps.Add mappingStamp

                for raw in (text mappingStamp).Replace("\r\n", "\n").Split('\n') do
                    let line = raw.Trim()

                    if line <> "" && not (line.StartsWith('#')) then
                        let cells = line.Split('|')
                        let mutable category = 0
                        let mutable provider = 0

                        if
                            cells.Length <> 3
                            || not (Int32.TryParse(cells[0], &category))
                            || not (Int32.TryParse(cells[2], &provider))
                        then
                            refuse (Error.InvalidSource "nexuscatmap.dat contains an invalid row.")

            List.rev categories, List.ofSeq stamps, absent

    let private categoryIds (value: string) =
        value.Split(',', StringSplitOptions.RemoveEmptyEntries ||| StringSplitOptions.TrimEntries)
        |> Array.choose (fun item ->
            let mutable id = 0

            if Int32.TryParse(item, &id) && id > 0 then
                Some id
            else
                None)
        |> Array.distinct
        |> Array.toList

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

    let private readMods root entries =
        let directories =
            entries
            |> List.choose (fun entry ->
                match components entry with
                | [ name ] when entry.TargetKind = EntryKind.Directory -> Some name
                | _ -> None)
            |> List.sortWith (fun left right ->
                StringComparer.OrdinalIgnoreCase.Compare(left, right))

        let mods = ResizeArray<SourceMod>()
        let stamps = ResizeArray<Stamp>()
        let installationFiles = Dictionary<string, Guid>(StringComparer.OrdinalIgnoreCase)

        for directory in directories do
            let id, versionId = Guid.NewGuid(), Guid.NewGuid()
            let kind = modKind directory

            let meta, metaStamp =
                match exactChild directory entries "meta.ini" with
                | Some entry when entry.TargetKind = EntryKind.RegularFile ->
                    let observed = stamp root entry
                    stamps.Add observed
                    ini (text observed), Some observed
                | Some _ -> refuse (Error.UnsafeSource "A mod metadata file is not a regular file.")
                | None -> Dictionary<string * string, string>(), None

            let get name = setting "General" name "" meta
            let categories = get "category" |> categoryIds
            let installationFile = get "installationFile"

            let installedFiles =
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

            if installationFile <> "" then
                installationFiles[Path.GetFileName installationFile] <- id

            let metadata =
                { Name = modName directory kind
                  Notes = get "notes"
                  Comment = get "comments"
                  Version = get "version"
                  Source = installationFile
                  Categories = [] }

            InventoryPolicy.metadata metadata
            |> Result.defaultWith (fun _ ->
                refuse (Error.InvalidSource("The metadata is invalid for mod " + directory + ".")))
            |> ignore

            let files =
                entries
                |> List.choose (fun entry ->
                    match components entry with
                    | first :: rest when
                        String.Equals(first, directory, StringComparison.Ordinal)
                        && entry.TargetKind = EntryKind.RegularFile
                        && not (
                            rest.Length = 1
                            && String.Equals(
                                rest[0],
                                "meta.ini",
                                StringComparison.OrdinalIgnoreCase
                            )
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

            mods.Add
                { Id = id
                  VersionId = versionId
                  Name = directory
                  Kind = kind
                  Metadata = metadata
                  CategorySourceIds = categories
                  InstalledFiles = installedFiles
                  Files = files }

        let installedIds = Dictionary<string, Guid option>(StringComparer.Ordinal)

        for item in mods do
            for modId, fileId in item.InstalledFiles do
                if modId > 0 && fileId > 0 then
                    let key = string modId + ":" + string fileId

                    match installedIds.TryGetValue key with
                    | true, Some existing when existing <> item.Id -> installedIds[key] <- None
                    | true, _ -> ()
                    | false, _ -> installedIds.Add(key, Some item.Id)

        List.ofSeq mods, List.ofSeq stamps, installationFiles, installedIds

    let private readProfiles root entries (mods: SourceMod list) selectedName =
        let directories =
            entries
            |> List.choose (fun entry ->
                match components entry with
                | [ name ] when entry.TargetKind = EntryKind.Directory -> Some name
                | _ -> None)
            |> List.sortWith (fun left right ->
                StringComparer.OrdinalIgnoreCase.Compare(left, right))

        if directories.IsEmpty then
            refuse (Error.InvalidSource "The Mod Organizer workspace has no profiles.")

        let names = Dictionary<string, SourceMod>(StringComparer.OrdinalIgnoreCase)

        for item in mods do
            names[item.Name] <- item

        let profiles = ResizeArray<SourceProfile>()
        let stamps = ResizeArray<Stamp>()

        for directory in directories do
            let profileFiles =
                entries
                |> List.filter (fun entry ->
                    match components entry with
                    | first :: _ -> String.Equals(first, directory, StringComparison.Ordinal)
                    | _ -> false)

            let unsupported detail =
                refuse (Error.UnsupportedData("The profile " + directory + " " + detail))

            profileFiles
            |> List.tryFind (fun entry ->
                match components entry with
                | [ _; saves; _rest ] when
                    String.Equals(saves, "saves", StringComparison.OrdinalIgnoreCase)
                    ->
                    true
                | _ -> false)
            |> Option.iter (fun _ ->
                unsupported
                    "contains local saves. Turn off local saves in Mod Organizer, then try again.")

            let settings =
                match exactChild directory entries "settings.ini" with
                | None -> None
                | Some entry ->
                    let observed = stamp root entry
                    stamps.Add observed
                    let values = ini (text observed)

                    if boolSetting "LocalSaves" values || boolSetting "LocalSettings" values then
                        unsupported
                            "uses local game files. Move those files back to the game profile, then try again."

                    Some observed

            let blocked =
                set
                    [ "plugins.txt"
                      "loadorder.txt"
                      "lockedorder.txt"
                      "archives.txt"
                      "profile_tweaks.ini" ]

            for entry in profileFiles do
                match components entry with
                | [ _; name ] when
                    blocked.Contains(name.ToLowerInvariant())
                    && entry.TargetKind = EntryKind.RegularFile
                    ->
                    let observed = stamp root entry
                    stamps.Add observed

                    if meaningfulLines (text observed) then
                        unsupported
                            "contains game plug-in or profile settings that this migration cannot move safely."
                | [ _; name ] when
                    name.EndsWith(".ini", StringComparison.OrdinalIgnoreCase)
                    && not (name.Equals("settings.ini", StringComparison.OrdinalIgnoreCase))
                    && entry.TargetKind = EntryKind.RegularFile
                    ->
                    let observed = stamp root entry
                    stamps.Add observed

                    if observed.Length > 0L then
                        unsupported
                            "contains local game settings that this migration cannot move safely."
                | _ -> ()

            let modlistEntry =
                exactChild directory entries "modlist.txt"
                |> Option.defaultWith (fun () ->
                    refuse (
                        Error.InvalidSource("The profile " + directory + " has no modlist.txt.")
                    ))

            let modlistStamp = stamp root modlistEntry
            stamps.Add modlistStamp
            let seen = HashSet<string>(StringComparer.OrdinalIgnoreCase)
            let listed = ResizeArray<SourceMod * bool>()

            for raw in (text modlistStamp).Replace("\r\n", "\n").Split('\n') do
                let line = raw.Trim()

                if line <> "" && not (line.StartsWith('#')) then
                    let enabled, name =
                        if line[0] = '-' then
                            false, line.Substring(1).Trim()
                        elif line[0] = '+' || line[0] = '*' then
                            true, line.Substring(1).Trim()
                        else
                            true, line

                    if name <> "" && seen.Add name then
                        match names.TryGetValue name with
                        | true, item when item.Kind <> ModKind.Backup -> listed.Add(item, enabled)
                        | true, _ -> ()
                        | _ ->
                            refuse (
                                Error.InvalidSource(
                                    "The profile "
                                    + directory
                                    + " refers to a missing mod: "
                                    + name
                                    + "."
                                )
                            )

            let known = List.ofSeq listed |> List.rev

            let omitted =
                mods
                |> List.filter (fun item ->
                    item.Kind <> ModKind.Backup && not (seen.Contains item.Name))
                |> List.sortWith (fun left right ->
                    StringComparer.OrdinalIgnoreCase.Compare(left.Name, right.Name))

            let ordered = known @ (omitted |> List.map (fun item -> item, false))

            let positions =
                ordered
                |> List.mapi (fun priority (item, enabled) ->
                    { Id = item.Id
                      Priority = priority
                      Enabled = if item.Kind = ModKind.Separator then None else Some enabled })

            profiles.Add
                { Id = Guid.NewGuid()
                  Name = directory
                  Mods = positions }

        let selected =
            profiles
            |> Seq.filter (fun profile ->
                profile.Name.Equals(selectedName, StringComparison.OrdinalIgnoreCase))
            |> Seq.toList

        match selected with
        | [ profile ] -> List.ofSeq profiles, profile.Id, List.ofSeq stamps
        | [] -> refuse (Error.InvalidSource "The selected Mod Organizer profile is missing.")
        | _ -> refuse (Error.CaseCollision selectedName)

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

    let private readArtifacts
        root
        entries
        (installationFiles: Dictionary<string, Guid>)
        (installedIds: Dictionary<string, Guid option>)
        =
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
                let unfinished = name.EndsWith(".unfinished", StringComparison.OrdinalIgnoreCase)

                let originalName =
                    if unfinished then
                        name.Substring(0, name.Length - ".unfinished".Length)
                    else
                        name

                let extension =
                    Path.GetExtension originalName |> fun value -> value.ToLowerInvariant()

                if extensions.Contains extension then
                    let fileStamp = stamp root entry
                    stamps.Add fileStamp

                    let sources, installed, paused, providerMod, providerFile =
                        match byName.TryGetValue(name + ".meta") with
                        | true, sidecar ->
                            let sidecarStamp = stamp root sidecar
                            stamps.Add sidecarStamp
                            let values = ini (text sidecarStamp)

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

                            urls, installed, paused, number "modID", number "fileID"
                        | _ -> [], false, false, 0, 0

                    let partial = unfinished || paused

                    if partial && sources.IsEmpty then
                        refuse (
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

                    let logical =
                        LogicalPath.create [ originalName ]
                        |> Result.defaultWith (fun _ ->
                            refuse (Error.InvalidSource "A download file name is invalid."))

                    artifacts.Add
                        { Id = Guid.NewGuid()
                          OriginalName = originalName
                          OriginalPath = HostPath.value entry.Resolved
                          File = { Stamp = fileStamp; Path = logical }
                          Partial = partial
                          Sources = sources
                          InstalledMod = installedMod }
            | _ -> ()

        List.ofSeq artifacts, List.ofSeq stamps

    let private readSource folder =
        let sourceFolder = Path.GetFullPath folder
        let iniPath = Path.Combine(sourceFolder, "ModOrganizer.ini")

        if not (File.Exists iniPath) then
            refuse (
                Error.InvalidSource "Choose a Mod Organizer folder that contains ModOrganizer.ini."
            )

        let iniStamp = directFile iniPath
        let settings = ini (text iniStamp)
        let basePath = path sourceFolder sourceFolder "base_directory" settings

        let modsPath = path basePath "mods" "mod_directory" settings
        let profilesPath = path basePath "profiles" "profiles_directory" settings
        let downloadsPath = path basePath "downloads" "download_directory" settings
        let selected = setting "General" "selected_profile" "" settings

        if String.IsNullOrWhiteSpace selected then
            refuse (Error.InvalidSource "ModOrganizer.ini does not select a profile.")

        let categories, categoryStamps, categoryAbsent =
            readCategories sourceFolder basePath

        let modsRoot, modEntries, modsManifest = scanRoot modsPath
        let mods, modStamps, installationFiles, installedIds = readMods modsRoot modEntries
        let profileRoot, profileEntries, profilesManifest = scanRoot profilesPath

        let profiles, selectedProfile, profileStamps =
            readProfiles profileRoot profileEntries mods selected

        let artifacts, artifactStamps, downloadManifest, downloadAbsent =
            if pathExists downloadsPath then
                let downloadRoot, downloadEntries, manifest = scanRoot downloadsPath

                let artifacts, stamps =
                    readArtifacts downloadRoot downloadEntries installationFiles installedIds

                artifacts, stamps, Some manifest, []
            else
                [], [], None, [ downloadsPath ]

        let knownCategories = categories |> List.map _.SourceId |> Set.ofList

        mods
        |> List.collect _.CategorySourceIds
        |> List.tryFind (fun id -> not (knownCategories.Contains id))
        |> Option.iter (fun id ->
            refuse (Error.InvalidSource("A mod uses missing category " + string id + ".")))

        { Categories = categories
          Mods = mods
          Profiles = profiles
          SelectedProfile = selectedProfile
          Artifacts = artifacts
          Stamps = iniStamp :: (categoryStamps @ modStamps @ profileStamps @ artifactStamps)
          Manifests = modsManifest :: profilesManifest :: (downloadManifest |> Option.toList)
          AbsentPaths = categoryAbsent @ downloadAbsent }

    let private copy (stamp: Stamp) (destination: FileStream) (token: CancellationToken) =
        let source, identity = openEntry stamp.Root stamp.Path stamp.Identity
        use source = source

        if identity <> stamp.Identity || source.Length <> stamp.Length then
            refuse Error.SourceChanged

        let buffer = Array.zeroCreate<byte> 65536
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        let mutable read = 0L

        while read < stamp.Length do
            token.ThrowIfCancellationRequested()

            let count =
                source.Read(buffer, 0, int (min (int64 buffer.Length) (stamp.Length - read)))

            if count = 0 then
                refuse Error.SourceChanged

            destination.Write(buffer, 0, count)
            hash.AppendData(buffer, 0, count)
            read <- read + int64 count

        if source.ReadByte() <> -1 || source.Length <> stamp.Length then
            refuse Error.SourceChanged

        let sha = Convert.ToHexStringLower(hash.GetHashAndReset())

        if sha <> stamp.Sha256 then
            refuse Error.SourceChanged

        destination.Flush true
        read, sha

    let private verify stamp =
        let observed =
            try
                Some(observe stamp.Root stamp.Path stamp.Identity)
            with
            | :? IOException
            | :? UnauthorizedAccessException
            | Refused _ -> None

        if
            observed
            |> Option.forall (fun value ->
                value.Length <> stamp.Length || value.Sha256 <> stamp.Sha256)
        then
            refuse Error.SourceChanged

    let private remove path =
        if Directory.Exists path then
            Directory.Delete(path, true)

    let internal migrateAtCheckpoint
        (store: IStore)
        (request: Request)
        (progress: Progress -> unit)
        (token: CancellationToken)
        checkpoint
        =
        task {
            let mutable target = None
            let mutable published = false
            let mutable committed = false

            try
                try
                    let! source = Task.Run((fun () -> readSource request.SourceFolder), token)
                    token.ThrowIfCancellationRequested()
                    let action = Guid.NewGuid()
                    let staged = ".mod-conductor-migration-" + action.ToString("N") + ".partial"
                    let final = ".mod-conductor-library-" + Guid.NewGuid().ToString("N")
                    let! begun = store.Begin(request.WorkspaceId, action, staged, final)

                    let targetValue = begun |> Result.defaultWith (fun error -> refuse error)

                    target <- Some targetValue

                    let total =
                        source.Mods
                        |> List.sumBy (fun item -> item.Files.Length)
                        |> (+) source.Artifacts.Length

                    let mutable completed = 0

                    use root =
                        HeldDirectory.Open(targetValue.WorkspacePath, targetValue.WorkspaceIdentity)

                    use stage = root.CreateDirectory staged
                    let preparedMods = ResizeArray<Mod>()

                    for item in source.Mods do
                        let files = ResizeArray<ModConductor.Migration.File>()

                        for file in item.Files do
                            token.ThrowIfCancellationRequested()
                            let id = Guid.NewGuid()
                            let output, identity = stage.Create(id.ToString("N") + ".payload")
                            use output = output
                            let length, sha = copy file.Stamp output token

                            files.Add
                                { Id = id
                                  Path = file.Path
                                  Length = length
                                  Sha256 = sha
                                  Identity = identity }

                            completed <- completed + 1

                            progress
                                { Completed = completed
                                  Total = total
                                  Message = "Copying mods" }

                        preparedMods.Add
                            { Id = item.Id
                              VersionId = item.VersionId
                              Kind = item.Kind
                              Metadata = item.Metadata
                              CategorySourceIds = item.CategorySourceIds
                              Files = List.ofSeq files }

                    let preparedArtifacts = ResizeArray<Artifact>()

                    for item in source.Artifacts do
                        token.ThrowIfCancellationRequested()

                        let fileName =
                            "artifact-"
                            + item.Id.ToString("N")
                            + if item.Partial then ".partial" else ".archive"

                        let output, identity = stage.Create fileName
                        use output = output
                        let length, sha = copy item.File.Stamp output token

                        preparedArtifacts.Add
                            { Id = item.Id
                              OriginalName = item.OriginalName
                              OriginalPath = item.OriginalPath
                              FileName = fileName
                              File =
                                { Id = item.Id
                                  Path = item.File.Path
                                  Length = length
                                  Sha256 = sha
                                  Identity = identity }
                              Partial = item.Partial
                              Sources = item.Sources
                              InstalledMod = item.InstalledMod }

                        completed <- completed + 1

                        progress
                            { Completed = completed
                              Total = total
                              Message = "Copying downloads" }

                    checkpoint "before-source-recheck"

                    for manifest in source.Manifests do
                        token.ThrowIfCancellationRequested()
                        verifyManifest manifest

                    for path in source.AbsentPaths do
                        token.ThrowIfCancellationRequested()

                        if pathExists path then
                            refuse Error.SourceChanged

                    for stamp in source.Stamps do
                        token.ThrowIfCancellationRequested()
                        verify stamp

                    checkpoint "before-publication"
                    token.ThrowIfCancellationRequested()

                    let! ready = store.Ready targetValue
                    ready |> Result.defaultWith (fun error -> refuse error)
                    token.ThrowIfCancellationRequested()

                    let stagedEntry =
                        match root.InspectEntry staged with
                        | Some entry when
                            entry.Kind = EntryKind.Directory && entry.Identity = stage.Identity
                            ->
                            entry
                        | _ -> refuse Error.SourceChanged

                    root.MoveOriginal(staged, stagedEntry, root, final)
                    published <- true
                    checkpoint "after-publication"
                    token.ThrowIfCancellationRequested()

                    let! result =
                        store.Complete
                            { Target = targetValue
                              LibraryIdentity = stagedEntry.Identity
                              Categories = source.Categories
                              Mods = List.ofSeq preparedMods
                              Profiles =
                                source.Profiles
                                |> List.map (fun value ->
                                    { Id = value.Id
                                      Name = value.Name
                                      Mods = value.Mods })
                              SelectedProfile = source.SelectedProfile
                              Artifacts = List.ofSeq preparedArtifacts }

                    match result with
                    | Ok value ->
                        committed <- true

                        progress
                            { Completed = total
                              Total = total
                              Message = "Migration complete" }

                        return Ok value
                    | Error error -> return Error error
                with
                | :? OperationCanceledException -> return Error Error.Cancelled
                | :? IOException as error -> return Error(Error.Unavailable error.Message)
                | :? UnauthorizedAccessException ->
                    return Error(Error.Unavailable "A source or workspace file is unavailable.")
                | Refused error -> return Error error
            finally
                match target with
                | Some value when not committed ->
                    let rootPath = HostPath.value value.WorkspacePath

                    try
                        remove (Path.Combine(rootPath, value.StagedName))

                        if published then
                            remove (Path.Combine(rootPath, value.FinalName))
                    with _ ->
                        ()

                    try
                        store.Abandon(value).GetAwaiter().GetResult()
                    with _ ->
                        ()
                | _ -> ()
        }

    let migrate store request progress token =
        migrateAtCheckpoint store request progress token ignore
