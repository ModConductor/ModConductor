namespace ModConductor.Persistence

open System
open System.IO
open System.Security.Cryptography
open System.Text
open System.Threading
open ModConductor.Bethesda
open ModConductor.DeploymentGenerations
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.Platform
open ModConductor.ProfileGameData

/// The selected installation supplies bytes; these owned directories are the runnable target.
module internal GameViews =
    let private path parts =
        LogicalPath.create parts
        |> Result.defaultWith (fun _ ->
            raise (IOException "The game installation contains an invalid file name."))

    let private child (parent: Location) name : Location =
        use held = HeldDirectory.Open(parent.Path, parent.Identity)

        use directory =
            match held.InspectEntry name with
            | None -> held.CreateDirectory name
            | Some entry when entry.Kind = EntryKind.Directory ->
                held.Directory(name, Some entry.Identity)
            | _ -> raise (IOException "The profile game folder is not a directory.")

        { Path =
            HostPath.create (Path.Combine(HostPath.value parent.Path, name))
            |> Result.defaultWith invalidOp
          Identity = directory.Identity }

    let rootPath (workspace: HostPath) (profile: Guid) =
        Path.Combine(HostPath.value workspace, ".mc-game-views", profile.ToString("N"), "game")

    let ensure (workspace: Location) (profile: Guid) =
        let views = child workspace ".mc-game-views"
        let owned = child views (profile.ToString "N")
        let root = child owned "game"
        let data = child root "Data"
        let originals = child owned "originals"
        root, data, originals

    let removeOwned (workspace: Location) (profile: Guid) =
        let rec removeEntries (directory: HeldDirectory) =
            for name in directory.Names |> Seq.toList do
                match directory.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.Directory ->
                    let identity =
                        use child = directory.Directory(name, Some entry.Identity)
                        removeEntries child
                        child.Identity

                    directory.RemoveDirectory(name, identity)
                | Some entry when entry.Kind = EntryKind.RegularFile ->
                    directory.RemoveFile(name, entry.Identity)
                | Some entry when entry.Kind = EntryKind.Link -> directory.RemoveLink(name, entry)
                | Some _ ->
                    raise (IOException "The owned profile game folder has an unsupported entry.")
                | None -> raise (IOException "The owned profile game folder changed.")

        use root = HeldDirectory.Open(workspace.Path, workspace.Identity)

        match root.InspectEntry ".mc-game-views" with
        | None -> ()
        | Some viewsEntry when viewsEntry.Kind = EntryKind.Directory ->
            let viewsIdentity, empty =
                use views = root.Directory(".mc-game-views", Some viewsEntry.Identity)
                let profileName = profile.ToString "N"

                match views.InspectEntry profileName with
                | None -> ()
                | Some profileEntry when profileEntry.Kind = EntryKind.Directory ->
                    let profileIdentity =
                        use owned = views.Directory(profileName, Some profileEntry.Identity)
                        removeEntries owned
                        owned.Identity

                    views.RemoveDirectory(profileName, profileIdentity)
                | Some _ -> raise (IOException "The owned profile game folder changed.")

                views.Identity, (views.Names |> Seq.isEmpty)

            if empty then
                root.RemoveDirectory(".mc-game-views", viewsIdentity)
        | Some _ -> raise (IOException "The owned profile game folder changed.")

    let private rootEntries (source: Location) (token: CancellationToken) =
        let files = ResizeArray<SnapshotFile>()
        let identities = ResizeArray<LogicalPath * FileIdentity>()
        let mutable count = 0

        let rec walk (directory: HeldDirectory) (prefix: string list) depth =
            if depth > 128 then
                raise (IOException "The game root exceeds the directory depth limit.")

            for name in directory.Names do
                token.ThrowIfCancellationRequested()

                let reserved =
                    prefix.IsEmpty
                    && (name.Equals("Data", StringComparison.OrdinalIgnoreCase)
                        || name.Equals("Skyrim.ccc", StringComparison.OrdinalIgnoreCase)
                        || name.StartsWith(
                            ".modconductor-originals-",
                            StringComparison.OrdinalIgnoreCase
                        ))

                if not reserved then
                    count <- count + 1

                    if count > 1000000 then
                        raise (IOException "The game root exceeds the file limit.")

                    let parts = prefix @ [ name ]
                    let logical = path parts

                    match directory.InspectEntry name with
                    | Some entry when entry.Kind = EntryKind.Directory ->
                        identities.Add(logical, entry.Identity)
                        use next = directory.Directory(name, Some entry.Identity)
                        walk next parts (depth + 1)
                    | Some entry when entry.Kind = EntryKind.RegularFile ->
                        let metadata = directory.InspectFile(name, Some entry.Identity)
                        identities.Add(logical, metadata.Identity)

                        files.Add
                            { Path = logical
                              Identity =
                                SnapshotFileIdentity.Metadata
                                    { Identity = metadata.Identity
                                      Length = metadata.Length
                                      Modified = metadata.Modified } }
                    | _ ->
                        raise (
                            IOException
                                "The game root contains an unowned link or unavailable entry."
                        )

        use held = HeldDirectory.Open(source.Path, source.Identity)
        walk held [] 0

        let stamp =
            use stream = new MemoryStream()
            use writer = new BinaryWriter(stream, Encoding.UTF8, true)
            writer.Write "mc-profile-game-root-v1"

            for logical, identity in identities |> Seq.sortBy fst do
                writer.Write(LogicalPath.display logical)
                writer.Write(identity.Low)
                writer.Write(identity.High)

            for file in files |> Seq.sortBy _.Path do
                let metadata = (SnapshotFile.metadata file).Value
                writer.Write(LogicalPath.display file.Path)
                writer.Write(metadata.Length)
                writer.Write(metadata.Modified.Ticks)

            writer.Flush()
            SHA256.HashData(stream.ToArray()) |> Convert.ToHexStringLower

        List.ofSeq files, stamp

    let rootSource source rootId token : SnapshotSource =
        let files, stamp = rootEntries source token

        { Snapshot =
            { Id = rootId
              Generation = stamp
              Kind = ReadOnlyLayerKind.Base
              Priority = 0
              Complete = true
              Files = files
              Mappings =
                [ { SourcePrefix = PlanPath.Root
                    TargetRoot = rootId
                    TargetPrefix = PlanPath.Root } ]
              Archives = [] }
          Directory = source
          Files =
            files
            |> List.map (fun file -> file.Path, (SnapshotFile.metadata file).Value.Identity)
            |> Map.ofList
          Originals = Map.empty }

    let selection
        (source: Location)
        (dataFiles: SnapshotFile list)
        (saved: PluginOrder option)
        dataRootId
        gameRootId
        (token: CancellationToken)
        =
        let gameSource: DataRoot =
            { Path = source.Path
              Identity = source.Identity }

        let _, _, bytes = PluginInputs.readFile gameSource "Skyrim.ccc" token

        let available =
            dataFiles |> List.map (fun file -> LogicalPath.display file.Path) |> Set.ofList

        let installed name =
            available
            |> Seq.exists (fun value -> value.Equals(name, StringComparison.OrdinalIgnoreCase))

        let creation =
            (UTF8Encoding(false, true).GetString bytes)
                .Split([| '\r'; '\n' |], StringSplitOptions.RemoveEmptyEntries)
            |> Array.map _.Trim()
            |> Array.filter (fun name -> installed name && OrderDocument.canWriteName name)
            |> Array.distinctBy _.ToUpperInvariant()
            |> Array.toList

        let selected name =
            saved
            |> Option.bind (fun order ->
                order.Entries
                |> List.tryFind (fun row ->
                    row.Name.Equals(name, StringComparison.OrdinalIgnoreCase)))
            |> Option.bind _.Enabled
            |> Option.defaultValue true

        let optional = (OrderRules.baseFiles |> List.skip 2) @ creation

        let disabled = optional |> List.filter (selected >> not) |> List.filter installed

        let excluded =
            dataFiles
            |> List.choose (fun file ->
                let name = LogicalPath.display file.Path

                if
                    disabled
                    |> List.exists (fun value ->
                        value.Equals(name, StringComparison.OrdinalIgnoreCase))
                then
                    Some { Root = dataRootId; Path = file.Path }
                else
                    None)
            |> Set.ofList

        let ccc =
            creation
            |> List.filter selected
            |> fun lines ->
                if lines.IsEmpty then
                    [||]
                else
                    Encoding.UTF8.GetBytes(String.concat "\r\n" lines + "\r\n")

        excluded,
        [ { Root = gameRootId
            Path = path [ "Skyrim.ccc" ] },
          ccc ]
