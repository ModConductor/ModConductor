namespace ModConductor.Migration

open System
open System.Collections.Generic
open System.IO
open System.Security.Cryptography
open System.Text.Json
open System.Threading
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform

module Vortex =
    let private maxBackupBytes = 64L * 1024L * 1024L
    let private maxEntries = 100000
    let private maxDepth = 64

    type ProfileChoice =
        { Id: string
          Name: string
          GameId: string }

    type Request =
        { WorkspaceId: Guid
          BackupFile: string
          ProfileId: string
          StagingRoot: string
          DownloadRoot: string }

    type private Stamp =
        { Root: SelectedRoot
          Path: LogicalPath
          Identity: FileIdentity
          Length: int64
          Sha256: string
          Md5: string }

    type private Manifest =
        { Path: string
          RootIdentity: FileIdentity
          Entries: (string * EntryKind * EntryKind * Observation<FileIdentity>) list
          Diagnostics: PathDiagnostic list }

    type private ParsedMod =
        { SourceId: string
          Id: Guid
          VersionId: Guid
          InstallationPath: string
          ArchiveId: string option
          Metadata: ModMetadata
          CategorySourceIds: int list
          Rules: JsonElement option
          Files: Direct.File list }

    exception private Refused of Error

    let private refuse error = raise (Refused error)

    let private invalid detail = refuse (Error.InvalidSource detail)

    let private unsupported detail = refuse (Error.UnsupportedData detail)

    let private rootIdentity root =
        match (RootSelection.facts root).File with
        | Known identity -> identity
        | Unknown detail -> refuse (Error.UnsafeSource detail)

    let private selectedRoot (path: string) label =
        if String.IsNullOrWhiteSpace path then
            invalid ("Choose the " + label + ".")

        let full = Path.GetFullPath path

        match HostPath.create full with
        | Error _ -> invalid ("The " + label + " is unavailable.")
        | Ok value ->
            RootSelection.select value
            |> Result.defaultWith (fun _ -> invalid ("The " + label + " is unavailable."))

    let private openEntry root path expected =
        let components = LogicalPath.components path
        let mutable current = HeldDirectory.Open(RootSelection.path root, rootIdentity root)
        let parents = ResizeArray<HeldDirectory>()

        try
            for name in components |> List.take (components.Length - 1) do
                let next = current.Directory(name, None)
                parents.Add current
                current <- next

            current.Read(List.last components, Some expected)
        finally
            (current :> IDisposable).Dispose()

            for parent in parents do
                (parent :> IDisposable).Dispose()

    let private digest (stream: Stream) =
        use sha = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        use md5 = IncrementalHash.CreateHash HashAlgorithmName.MD5
        let buffer = Array.zeroCreate<byte> 65536
        let mutable length = 0L
        let mutable reading = true

        while reading do
            let count = stream.Read(buffer, 0, buffer.Length)

            if count = 0 then
                reading <- false
            else
                length <- length + int64 count
                sha.AppendData(buffer, 0, count)
                md5.AppendData(buffer, 0, count)

        length,
        Convert.ToHexStringLower(sha.GetHashAndReset()),
        Convert.ToHexStringLower(md5.GetHashAndReset())

    let private observe root path identity =
        let stream, actual = openEntry root path identity
        use stream = stream
        let length, sha, md5 = digest stream

        { Root = root
          Path = path
          Identity = actual
          Length = length
          Sha256 = sha
          Md5 = md5 }

    let private directFile path label =
        let full = Path.GetFullPath path
        let parent = Path.GetDirectoryName full
        let root = selectedRoot parent label
        let name = Path.GetFileName full

        let logical =
            LogicalPath.create [ name ]
            |> Result.defaultWith (fun _ -> invalid ("The " + label + " name is invalid."))

        let entry =
            use directory = HeldDirectory.Open(RootSelection.path root, rootIdentity root)

            match directory.InspectEntry name with
            | Some value when value.Kind = EntryKind.RegularFile -> value
            | Some _ ->
                refuse (Error.UnsafeSource("The " + label + " is a link or unsupported file."))
            | None -> invalid ("The " + label + " is missing.")

        observe root logical entry.Identity

    let private inspectRoot path label =
        let root = selectedRoot path label

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
                |> List.sortBy (fun (name, _, _, _) -> name)
              Diagnostics = result.Diagnostics |> List.sortBy _.Path }

        root, result, manifest

    let private scanRoot path label =
        let root, result, manifest = inspectRoot path label

        result.Diagnostics
        |> List.tryFind (fun item ->
            item.Problem = TargetCollision || item.Problem = FileDirectoryConflict)
        |> Option.iter (fun item -> refuse (Error.CaseCollision item.Path))

        result.Diagnostics
        |> List.tryHead
        |> Option.iter (fun item ->
            refuse (Error.UnsafeSource("The " + label + " contains an unsafe entry: " + item.Path)))

        result.Entries
        |> List.tryFind (fun item -> item.Kind = EntryKind.Link || item.Kind = EntryKind.Other)
        |> Option.iter (fun item ->
            refuse (
                Error.UnsafeSource(
                    "The "
                    + label
                    + " contains a link or unsupported file: "
                    + LogicalPath.display item.Logical
                )
            ))

        root, result.Entries, manifest

    let private verifyManifest expected label =
        let current =
            try
                let _, _, value = inspectRoot expected.Path label
                Some value
            with
            | :? IOException
            | :? UnauthorizedAccessException
            | Refused _ -> None

        if current <> Some expected then
            refuse Error.SourceChanged

    let private verify stamp =
        let current =
            try
                Some(observe stamp.Root stamp.Path stamp.Identity)
            with
            | :? IOException
            | :? UnauthorizedAccessException
            | Refused _ -> None

        if
            current
            |> Option.forall (fun value ->
                value.Identity <> stamp.Identity
                || value.Length <> stamp.Length
                || value.Sha256 <> stamp.Sha256)
        then
            refuse Error.SourceChanged

    let private copy stamp (destination: FileStream) (token: CancellationToken) =
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

    let private transferFile path stamp : Direct.File =
        { Path = path
          Read =
            fun destination token ->
                try
                    Ok(copy stamp destination token)
                with Refused error ->
                    Error error }

    let private property (name: string) (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Object then
            invalid ("The Vortex backup has invalid " + name + " data.")

        let mutable result = Unchecked.defaultof<JsonElement>

        if value.TryGetProperty(name, &result) then
            result
        else
            invalid ("The Vortex backup is missing " + name + ".")

    let private tryProperty (name: string) (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Object then
            None
        else
            let mutable result = Unchecked.defaultof<JsonElement>

            if value.TryGetProperty(name, &result) then
                Some result
            else
                None

    let private text (name: string) (value: JsonElement) =
        let item = property name value

        if item.ValueKind <> JsonValueKind.String then
            invalid ("The Vortex backup has an invalid " + name + ".")

        let result = item.GetString()

        if String.IsNullOrWhiteSpace result then
            invalid ("The Vortex backup has an empty " + name + ".")

        result

    let private tryText (name: string) (value: JsonElement) =
        match tryProperty name value with
        | None -> None
        | Some item when item.ValueKind = JsonValueKind.Null -> None
        | Some item when item.ValueKind = JsonValueKind.String ->
            let result = item.GetString()

            if String.IsNullOrWhiteSpace result then
                None
            else
                Some result
        | Some _ -> invalid ("The Vortex backup has an invalid " + name + ".")

    let private boolean (name: string) (value: JsonElement) =
        match (property name value).ValueKind with
        | JsonValueKind.True -> true
        | JsonValueKind.False -> false
        | _ -> invalid ("The Vortex backup has an invalid " + name + ".")

    let private tryBoolean (name: string) (value: JsonElement) =
        match tryProperty name value with
        | None -> None
        | Some item when item.ValueKind = JsonValueKind.True -> Some true
        | Some item when item.ValueKind = JsonValueKind.False -> Some false
        | Some _ -> invalid ("The Vortex backup has an invalid " + name + ".")

    let private int64Value (name: string) (value: JsonElement) =
        let item = property name value
        let mutable result = 0L

        if
            item.ValueKind <> JsonValueKind.Number
            || not (item.TryGetInt64(&result))
            || result < 0L
        then
            invalid ("The Vortex backup has an invalid " + name + ".")

        result

    let private objectEntries name (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Object then
            invalid ("The Vortex backup has invalid " + name + " data.")

        let entries = value.EnumerateObject() |> Seq.toList

        if entries.Length > maxEntries then
            invalid ("The Vortex backup contains too many " + name + " entries.")

        entries

    let private arrayItems name (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Array then
            invalid ("The Vortex backup has invalid " + name + " data.")

        let items = value.EnumerateArray() |> Seq.toList

        if items.Length > maxEntries then
            invalid ("The Vortex backup contains too many " + name + " entries.")

        items

    let private document stamp =
        if stamp.Length > maxBackupBytes then
            invalid "The Vortex backup is too large."

        let stream, identity = openEntry stamp.Root stamp.Path stamp.Identity
        use stream = stream

        if identity <> stamp.Identity || stream.Length <> stamp.Length then
            refuse Error.SourceChanged

        try
            JsonDocument.Parse(
                stream,
                JsonDocumentOptions(
                    AllowTrailingCommas = false,
                    CommentHandling = JsonCommentHandling.Disallow,
                    MaxDepth = maxDepth
                )
            )
        with :? JsonException ->
            invalid "The Vortex backup is not valid JSON."

    let private backupVersion root =
        property "settings" root |> objectEntries "settings" |> ignore
        property "user" root |> objectEntries "user" |> ignore
        let app = property "app" root
        let version = text "appVersion" app

        if version <> "2.6.3" then
            unsupported "Choose a full-state backup made by Vortex 2.6.3."

    let private profileEntries root =
        let persistent = property "persistent" root
        property "profiles" persistent |> objectEntries "profiles"

    let private profileName value =
        let name = text "name" value

        if name.Length > 256 || name.Contains '\000' then
            invalid "A Vortex profile has an invalid name."

        name.Trim()

    let private readProfiles backup =
        let stamp = directFile backup "Vortex backup file"
        use parsed = document stamp
        backupVersion parsed.RootElement

        profileEntries parsed.RootElement
        |> List.map (fun entry ->
            let value = entry.Value
            let id = text "id" value

            if id <> entry.Name then
                invalid "A Vortex profile ID does not match its backup key."

            { Id = id
              Name = profileName value
              GameId = text "gameId" value })
        |> List.sortWith (fun left right ->
            let name = StringComparer.OrdinalIgnoreCase.Compare(left.Name, right.Name)

            if name <> 0 then
                name
            else
                StringComparer.Ordinal.Compare(left.Id, right.Id))

    let profiles backup =
        try
            Ok(readProfiles backup)
        with
        | Refused error -> Error error
        | :? IOException as error -> Error(Error.Unavailable error.Message)
        | :? UnauthorizedAccessException ->
            Error(Error.Unavailable "The Vortex backup file is unavailable.")

    let private components (entry: PathEntry) = LogicalPath.components entry.Logical

    let private categoryId (value: string) =
        let mutable parsed = 0

        if Int32.TryParse(value, &parsed) && parsed > 0 then
            parsed
        else
            invalid "The Vortex backup has an invalid category ID."

    let private categories (persistent: JsonElement) (gameId: string) =
        let result =
            match tryProperty "categories" persistent with
            | None -> []
            | Some all ->
                match tryProperty gameId all with
                | None -> []
                | Some values ->
                    values
                    |> objectEntries "categories"
                    |> List.map (fun entry ->
                        let value = entry.Value
                        let parent = tryText "parentCategory" value
                        let label = text "name" value

                        if label.Length > 256 || label.Contains '\000' then
                            invalid "A Vortex category has an invalid name."

                        { SourceId = categoryId entry.Name
                          Label = label.Trim()
                          ParentSourceId =
                            parent
                            |> Option.bind (fun item ->
                                if item = "" || item = "0" then
                                    None
                                else
                                    Some(categoryId item)) })

        let ids = result |> List.map _.SourceId

        if ids.Length <> (ids |> Set.ofList |> Set.count) then
            invalid "The Vortex categories contain duplicate IDs."

        let known = Set.ofList ids

        result
        |> List.choose _.ParentSourceId
        |> List.tryFind (fun id -> not (known.Contains id))
        |> Option.iter (fun _ -> invalid "A Vortex category has a missing parent.")

        let mutable mapped = Set.empty
        let mutable remaining = result
        let mutable changed = true

        while not remaining.IsEmpty && changed do
            let ready, blocked =
                remaining
                |> List.partition (fun item ->
                    item.ParentSourceId |> Option.forall (fun parent -> mapped.Contains parent))

            mapped <- ready |> List.fold (fun state item -> state.Add item.SourceId) mapped
            remaining <- blocked
            changed <- not ready.IsEmpty

        if not remaining.IsEmpty then
            invalid "The Vortex categories contain a parent cycle."

        let byId = result |> Seq.map (fun item -> item.SourceId, item) |> dict

        for item in result do
            let mutable depth = 1
            let mutable parent = item.ParentSourceId

            while parent.IsSome do
                if depth >= 16 then
                    invalid "The Vortex categories are nested too deeply."

                depth <- depth + 1
                parent <- byId[parent.Value].ParentSourceId

        result

    let private attributeText (names: string list) (value: JsonElement) =
        names |> List.tryPick (fun name -> tryText name value)

    let private safeSource (value: string) =
        match Uri.TryCreate(value, UriKind.Absolute) with
        | true, uri when
            (uri.Scheme = Uri.UriSchemeHttp || uri.Scheme = Uri.UriSchemeHttps)
            && String.IsNullOrEmpty uri.UserInfo
            ->
            let builder = UriBuilder uri
            builder.Query <- ""
            builder.Fragment <- ""
            builder.Uri.AbsoluteUri
        | true, _ -> ""
        | false, _ -> value

    let private categoryReferences (attributes: JsonElement) =
        match tryProperty "category" attributes with
        | None -> []
        | Some item when item.ValueKind = JsonValueKind.Null -> []
        | Some item when item.ValueKind = JsonValueKind.Number ->
            let mutable value = 0

            if item.TryGetInt32(&value) && value > 0 then
                [ value ]
            else
                invalid "A mod has an invalid category."
        | Some item when item.ValueKind = JsonValueKind.String ->
            let value = item.GetString()

            if String.IsNullOrWhiteSpace value then
                []
            else
                [ categoryId value ]
        | Some _ -> invalid "A mod has an invalid category."

    let private exactDirectory (entries: PathEntry list) (name: string) =
        entries
        |> List.tryFind (fun entry ->
            match components entry with
            | [ first ] ->
                entry.TargetKind = EntryKind.Directory
                && String.Equals(first, name, StringComparison.Ordinal)
            | _ -> false)

    let private modFiles (root: SelectedRoot) (entries: PathEntry list) (installationPath: string) =
        if
            installationPath.IndexOfAny(
                [| Path.DirectorySeparatorChar; Path.AltDirectorySeparatorChar; '\\'; '/' |]
            )
            >= 0
        then
            unsupported "A Vortex mod uses a nested staging path."

        exactDirectory entries installationPath
        |> Option.defaultWith (fun () ->
            invalid ("The staging folder is missing the mod " + installationPath + "."))
        |> ignore

        entries
        |> List.choose (fun entry ->
            match components entry with
            | first :: rest when
                first = installationPath
                && entry.TargetKind = EntryKind.RegularFile
                && not rest.IsEmpty
                ->
                let identity =
                    match entry.Facts.File with
                    | Known value -> value
                    | Unknown detail -> refuse (Error.UnsafeSource detail)

                let logical =
                    LogicalPath.create rest
                    |> Result.defaultWith (fun _ -> invalid "A staged mod file path is invalid.")

                let stamp = observe root entry.Logical identity
                Some(transferFile logical stamp, stamp)
            | _ -> None)

    let private nonEmptyArray name value =
        match tryProperty name value with
        | None -> false
        | Some item -> not (arrayItems name item).IsEmpty

    let private parseMods persistent profile stagingRoot stagingEntries =
        let gameId = text "gameId" profile
        let states = property "modState" profile |> objectEntries "profile mods"
        let allGames = property "mods" persistent
        let gameMods = property gameId allGames

        let modEntries =
            objectEntries "mods" gameMods
            |> Seq.map (fun item -> item.Name, item.Value)
            |> dict

        let stamps = ResizeArray<Stamp>()

        let mods =
            states
            |> List.map (fun state ->
                let sourceId = state.Name
                let enabled = boolean "enabled" state.Value

                let value =
                    match modEntries.TryGetValue sourceId with
                    | true, item -> item
                    | _ ->
                        invalid ("The selected profile refers to a missing mod: " + sourceId + ".")

                if text "id" value <> sourceId then
                    invalid "A Vortex mod ID does not match its backup key."

                if text "state" value <> "installed" then
                    unsupported ("The mod " + sourceId + " is not fully installed.")

                let kind = tryText "type" value |> Option.defaultValue ""

                if kind <> "" then
                    unsupported ("The mod " + sourceId + " uses an unsupported Vortex mod type.")

                if nonEmptyArray "enabledINITweaks" value then
                    unsupported (
                        "The mod " + sourceId + " uses profile settings that cannot be moved."
                    )

                if nonEmptyArray "fileOverrides" value then
                    unsupported (
                        "The mod " + sourceId + " uses file overrides that cannot be moved."
                    )

                let installationPath = text "installationPath" value

                let attributes =
                    match tryProperty "attributes" value with
                    | None ->
                        use empty = JsonDocument.Parse("{}")
                        empty.RootElement.Clone()
                    | Some item when item.ValueKind = JsonValueKind.Object -> item
                    | Some _ -> invalid ("The mod " + sourceId + " has invalid attributes.")

                let name =
                    attributeText [ "name"; "modName" ] attributes |> Option.defaultValue sourceId

                let metadata =
                    { Name = name
                      Notes =
                        attributeText [ "description"; "shortDescription" ] attributes
                        |> Option.defaultValue ""
                      Comment = attributeText [ "author" ] attributes |> Option.defaultValue ""
                      Version =
                        attributeText [ "version"; "modVersion" ] attributes
                        |> Option.defaultValue ""
                      Source =
                        attributeText [ "source"; "fileName" ] attributes
                        |> Option.map safeSource
                        |> Option.defaultValue ""
                      Categories = [] }

                InventoryPolicy.metadata metadata
                |> Result.defaultWith (fun _ ->
                    invalid ("The metadata is invalid for mod " + name + "."))
                |> ignore

                let files, observed =
                    modFiles stagingRoot stagingEntries installationPath |> List.unzip

                stamps.AddRange observed

                { SourceId = sourceId
                  Id = Guid.NewGuid()
                  VersionId = Guid.NewGuid()
                  InstallationPath = installationPath
                  ArchiveId = tryText "archiveId" value
                  Metadata = metadata
                  CategorySourceIds = categoryReferences attributes
                  Rules = tryProperty "rules" value |> Option.map _.Clone()
                  Files = files },
                enabled)

        mods, List.ofSeq stamps, gameId

    let private validateRules (mods: (ParsedMod * bool) list) =
        let known = mods |> List.map (fun (item, _) -> item.SourceId) |> Set.ofList
        let edges = ResizeArray<string * string>()

        for item, _ in mods do
            match item.Rules with
            | None -> ()
            | Some rules ->
                for rule in arrayItems "mod rules" rules do
                    let relation = text "type" rule

                    if relation <> "before" && relation <> "after" then
                        unsupported ("The mod " + item.Metadata.Name + " uses an unsupported rule.")

                    if tryBoolean "ignored" rule = Some true then
                        unsupported (
                            "The mod " + item.Metadata.Name + " has an ignored ordering rule."
                        )

                    let reference = property "reference" rule
                    let target = text "id" reference

                    if not (known.Contains target) then
                        unsupported (
                            "The mod " + item.Metadata.Name + " has a rule for a missing mod."
                        )

                    if target = item.SourceId then
                        unsupported ("The mod " + item.Metadata.Name + " has a rule cycle.")

                    if relation = "before" then
                        edges.Add(item.SourceId, target)
                    else
                        edges.Add(target, item.SourceId)

        List.ofSeq edges

    let private explicitOrder (persistent: JsonElement) (profileId: string) (known: Set<string>) =
        match tryProperty "loadOrder" persistent with
        | None -> None
        | Some all ->
            match tryProperty profileId all with
            | None -> None
            | Some value when value.ValueKind = JsonValueKind.Object ->
                let positions =
                    objectEntries "load order" value
                    |> List.map (fun entry ->
                        if not (known.Contains entry.Name) then
                            unsupported "The Vortex load order contains an unknown mod."

                        if tryBoolean "external" entry.Value = Some true then
                            unsupported "The Vortex load order contains an externally managed mod."

                        let position = int64Value "pos" entry.Value
                        entry.Name, position)

                if positions |> List.map snd |> Set.ofList |> Set.count <> positions.Length then
                    invalid "The Vortex load order contains duplicate positions."

                Some(positions |> List.sortBy (fun (id, position) -> position, id) |> List.map fst)
            | Some value when value.ValueKind = JsonValueKind.Array ->
                let ids =
                    arrayItems "load order" value
                    |> List.map (fun entry ->
                        match tryText "modId" entry with
                        | Some id when known.Contains id -> id
                        | Some _ -> unsupported "The Vortex load order contains an unknown mod."
                        | None -> unsupported "The Vortex load order contains an unmanaged entry.")

                if ids |> Set.ofList |> Set.count <> ids.Length then
                    invalid "The Vortex load order contains a mod more than once."

                Some ids
            | Some _ -> invalid "The Vortex load order is invalid."

    let private ruleOrder (ids: string list) (edges: (string * string) list) =
        let outgoing = Dictionary<string, ResizeArray<string>>(StringComparer.Ordinal)
        let incoming = Dictionary<string, int>(StringComparer.Ordinal)

        for id in ids do
            outgoing.Add(id, ResizeArray())
            incoming.Add(id, 0)

        for before, after in edges |> List.distinct do
            outgoing[before].Add after
            incoming[after] <- incoming[after] + 1

        let ready = SortedSet<string>(StringComparer.Ordinal)

        for id in ids do
            if incoming[id] = 0 then
                ready.Add id |> ignore

        let ordered = ResizeArray<string>()

        while ready.Count > 0 do
            let current = ready.Min
            ready.Remove current |> ignore
            ordered.Add current

            for next in
                outgoing[current]
                |> Seq.sortWith (fun left right -> StringComparer.Ordinal.Compare(left, right)) do
                incoming[next] <- incoming[next] - 1

                if incoming[next] = 0 then
                    ready.Add next |> ignore

        if ordered.Count <> ids.Length then
            unsupported "The Vortex mod rules contain a cycle."

        List.ofSeq ordered

    let private orderedMods
        (persistent: JsonElement)
        (profileId: string)
        (mods: (ParsedMod * bool) list)
        =
        let edges = validateRules mods
        let ids = mods |> List.map (fun (item, _) -> item.SourceId)
        let known = Set.ofList ids
        let rules = ruleOrder ids edges

        let order =
            match explicitOrder persistent profileId known with
            | Some listed ->
                listed
                @ (ids |> List.filter (fun id -> not (List.contains id listed)) |> List.sort)
            | None -> rules

        let byId =
            mods |> Seq.map (fun (item, enabled) -> item.SourceId, (item, enabled)) |> dict

        order
        |> List.mapi (fun priority id ->
            let item, enabled = byId[id]

            { Id = item.Id
              Priority = priority
              Enabled = Some enabled })

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

    let private artifacts
        (persistent: JsonElement)
        (gameId: string)
        (downloadRoot: SelectedRoot)
        (entries: PathEntry list)
        (mods: (ParsedMod * bool) list)
        =
        let references =
            mods
            |> List.choose (fun (item, _) -> item.ArchiveId |> Option.map (fun id -> id, item.Id))

        let duplicate =
            references |> List.countBy fst |> List.tryFind (fun (_, count) -> count > 1)

        duplicate
        |> Option.iter (fun (id, _) ->
            unsupported ("More than one mod uses the Vortex download " + id + "."))

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
                let applies = required.Contains id || appliesToGame

                if not applies then
                    None
                else
                    found.Add id |> ignore

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

                    if
                        expectedMd5.Length <> 32 || not (expectedMd5 |> Seq.forall Uri.IsHexDigit)
                    then
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

                    stamps.Add stamp

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

                    Some artifact)

        required
        |> Set.iter (fun id ->
            if not (found.Contains id) then
                invalid ("The backup is missing the download used by mod " + id + "."))

        artifacts, List.ofSeq stamps

    let private readSource (request: Request) =
        let backup = directFile request.BackupFile "Vortex backup file"
        use parsed = document backup
        let root = parsed.RootElement
        backupVersion root
        let persistent = property "persistent" root

        let profile =
            profileEntries root
            |> List.tryFind (fun item -> item.Name = request.ProfileId)
            |> Option.map _.Value
            |> Option.defaultWith (fun () ->
                invalid "Choose a profile from the selected Vortex backup.")

        if tryBoolean "pendingRemove" profile = Some true then
            unsupported "The selected Vortex profile is being removed."

        let profileId = text "id" profile

        if profileId <> request.ProfileId then
            invalid "The selected Vortex profile ID does not match its backup key."

        let stagingRoot, stagingEntries, stagingManifest =
            scanRoot request.StagingRoot "Vortex staging folder"

        let downloadRoot, downloadEntries, downloadManifest =
            scanRoot request.DownloadRoot "Vortex download folder"

        let parsedMods, modStamps, gameId =
            parseMods persistent profile stagingRoot stagingEntries

        let categories = categories persistent gameId
        let knownCategories = categories |> List.map _.SourceId |> Set.ofList

        parsedMods
        |> List.collect (fun (item, _) -> item.CategorySourceIds)
        |> List.tryFind (fun id -> not (knownCategories.Contains id))
        |> Option.iter (fun id -> invalid ("A mod uses missing category " + string id + "."))

        let positions = orderedMods persistent profileId parsedMods

        let artifacts, artifactStamps =
            artifacts persistent gameId downloadRoot downloadEntries parsedMods

        let directMods: Direct.Mod list =
            parsedMods
            |> List.map (fun (item, _) ->
                { Id = item.Id
                  VersionId = item.VersionId
                  Kind = ModKind.Regular
                  Metadata = item.Metadata
                  CategorySourceIds = item.CategorySourceIds
                  Files = item.Files })

        let profileGuid = Guid.NewGuid()

        let verifySource (token: CancellationToken) =
            try
                token.ThrowIfCancellationRequested()
                verify backup
                verifyManifest stagingManifest "Vortex staging folder"
                token.ThrowIfCancellationRequested()
                verifyManifest downloadManifest "Vortex download folder"

                for stamp in modStamps @ artifactStamps do
                    token.ThrowIfCancellationRequested()
                    verify stamp

                Ok()
            with Refused error ->
                Error error

        let source: Direct.Input =
            { Categories = categories
              Mods = directMods
              Profiles =
                [ { Id = profileGuid
                    Name = profileName profile
                    Mods = positions } ]
              SelectedProfile = profileGuid
              Artifacts = artifacts
              Verify = verifySource }

        source

    let private directSource request =
        try
            Ok(readSource request)
        with Refused error ->
            Error error

    let internal migrateAtCheckpoint
        (store: IStore)
        (request: Request)
        (progress: Progress -> unit)
        (token: CancellationToken)
        checkpoint
        =
        Direct.migrateAtCheckpoint
            store
            request.WorkspaceId
            (fun () -> directSource request)
            progress
            token
            checkpoint

    let migrate store request progress token =
        migrateAtCheckpoint store request progress token ignore
