namespace ModConductor.ArchiveInstallation

open System
open System.IO
open System.Text
open System.Security.Cryptography
open ModConductor.ArchiveInspection
open ModConductor.ModLibrary
open ModConductor.Platform

module Layout =
    let private refuse message = raise (InstallationException message)

    let private starts prefix path =
        List.length prefix <= List.length path
        && List.take (List.length prefix) path = prefix

    let private path parts =
        LogicalPath.create parts
        |> Result.defaultWith (fun _ -> refuse "Choose a relative destination within the mod.")

    let private policy =
        { TargetPolicy.windows with
            Unicode = CanonicalComposition }

    let private files (manifest: ArchiveManifest) =
        manifest.Entries |> List.filter (fun e -> not e.Directory)

    let private rootFiles manifest root =
        files manifest
        |> List.choose (fun e ->
            let parts = LogicalPath.components e.Path

            if starts root parts && parts.Length > root.Length then
                Some
                    { Index = e.Index
                      Destination = path (List.skip root.Length parts) }
            else
                None)

    let private quickRoot manifest =
        let markers =
            set
                [ "textures"
                  "meshes"
                  "scripts"
                  "interface"
                  "sound"
                  "music"
                  "strings"
                  "seq"
                  "grass"
                  "skse" ]

        let candidates =
            files manifest
            |> List.collect (fun e ->
                let parts = LogicalPath.components e.Path

                [ for i in 0 .. parts.Length - 1 do
                      let name = parts[i].ToLowerInvariant()

                      if
                          (i < parts.Length - 1 && markers.Contains name)
                          || (i = parts.Length - 1
                              && List.contains (Path.GetExtension name) [ ".esp"; ".esm"; ".esl" ])
                      then
                          yield List.take i parts

                      if i < parts.Length - 1 && name = "data" then
                          yield List.take (i + 1) parts ])
            |> List.distinct

        match candidates with
        | [ root ] -> Some root
        | _ -> None

    let private finish (draft: InstallationDraft) =
        if draft.Files.IsEmpty then
            { draft with Plan = None }
        else
            let metadata =
                InventoryPolicy.metadata
                    { Name = draft.Name
                      Version = draft.Version
                      Notes = ""
                      Comment = ""
                      Source = ""
                      Categories = [] }
                |> Result.defaultWith (fun _ ->
                    refuse "Enter a mod name and a version of at most 256 characters.")

            let entries = draft.Manifest.Entries |> List.map (fun e -> e.Index, e) |> Map.ofList

            let seen =
                System.Collections.Generic.Dictionary<string, string>(
                    StringComparer.OrdinalIgnoreCase
                )

            let selected = System.Collections.Generic.HashSet<int>()
            let mutable bytes = 0L
            let mutable destinationCharacters = 0

            for file in draft.Files do
                let entry =
                    entries
                    |> Map.tryFind file.Index
                    |> Option.defaultWith (fun () ->
                        refuse "An included file is not in this archive.")

                if entry.Directory || not (selected.Add file.Index) then
                    refuse "Choose each archive file only once."

                destinationCharacters <-
                    destinationCharacters + (LogicalPath.display file.Destination).Length

                if destinationCharacters > ArchiveLimits.Default.NameCharacters then
                    refuse "The installation contains too much destination path data."

                let parts = LogicalPath.components file.Destination

                if
                    parts.Length > ArchiveLimits.Default.Depth
                    || (LogicalPath.display file.Destination).Length > ArchiveLimits.Default.PathCharacters
                    || not (TargetPolicy.problems policy file.Destination).IsEmpty
                then
                    refuse
                        "A destination cannot be used in this mod. Choose a relative Windows-compatible path."

                for count in 1 .. parts.Length do
                    let target = path (List.take count parts)
                    let key = TargetPolicy.key policy target
                    let spelling = LogicalPath.display target

                    match seen.TryGetValue key with
                    | true, original when original <> spelling ->
                        refuse
                            "Two destinations use conflicting names. Change a destination or exclude a file."
                    | _ -> seen[key] <- spelling

                    if seen.Count > ArchiveLimits.Default.Entries then
                        refuse "The installation contains too many file and folder entries."

                bytes <- bytes + entry.Size

            let targets =
                draft.Files
                |> List.map (fun f -> TargetPolicy.key policy f.Destination)
                |> Set.ofList

            if targets.Count <> draft.Files.Length then
                refuse
                    "Two files have the same destination. Change a destination or exclude a file."

            for file in draft.Files do
                let parts = LogicalPath.components file.Destination

                for count in 1 .. parts.Length - 1 do
                    if targets.Contains(TargetPolicy.key policy (path (List.take count parts))) then
                        refuse "A destination is both a file and a folder."

            use buffer = new MemoryStream()
            use writer = new BinaryWriter(buffer, Encoding.UTF8, true)
            writer.Write(string draft.Artifact.WorkspaceId)
            writer.Write(string draft.Artifact.Id)
            writer.Write(draft.Artifact.Revision)
            writer.Write(draft.Manifest.Sha256)
            writer.Write(metadata.Name)
            writer.Write(metadata.Version)

            for file in draft.Files |> List.sortBy _.Index do
                writer.Write(file.Index)
                writer.Write(LogicalPath.display file.Destination)

            writer.Flush()
            let fingerprint = SHA256.HashData(buffer.ToArray()) |> Convert.ToHexStringLower

            { draft with
                Name = metadata.Name
                Plan =
                    Some
                        { Artifact = draft.Artifact
                          ArchiveName = draft.ArchiveName
                          Sha256 = draft.Manifest.Sha256
                          Name = metadata.Name
                          Version = metadata.Version
                          Root = draft.Root
                          Files = draft.Files
                          Bytes = bytes
                          Fingerprint = fingerprint } }

    let prepare reference name manifest =
        let root = quickRoot manifest

        { Id = Guid.NewGuid()
          Revision = 0L
          Artifact = reference
          ArchiveName = name
          Manifest = manifest
          Root = defaultArg root []
          Files = root |> Option.map (rootFiles manifest) |> Option.defaultValue []
          Name =
            (let suggested = Path.GetFileNameWithoutExtension name in

             if String.IsNullOrWhiteSpace suggested then
                 "New mod"
             else
                 suggested)
          Version = ""
          Plan = None }
        |> finish

    let change (draft: InstallationDraft) change =
        let updated =
            match change with
            | LayoutChange.Metadata(name, version) ->
                { draft with
                    Name = name
                    Version = version }
            | LayoutChange.Root root ->
                let chosen = rootFiles draft.Manifest root

                if chosen.IsEmpty then
                    refuse "Choose a folder that contains files."

                { draft with
                    Root = root
                    Files = chosen }
            | LayoutChange.Include(source, included) ->
                let matching =
                    files draft.Manifest
                    |> List.filter (fun e -> starts source (LogicalPath.components e.Path))

                if matching.IsEmpty then
                    refuse "Choose a file or folder in this archive."

                let ids = matching |> List.map _.Index |> Set.ofList
                let retained = draft.Files |> List.filter (fun f -> not (ids.Contains f.Index))

                let added =
                    if not included then
                        []
                    else
                        matching
                        |> List.map (fun e ->
                            draft.Files
                            |> List.tryFind (fun f -> f.Index = e.Index)
                            |> Option.defaultWith (fun () ->
                                let parts = LogicalPath.components e.Path

                                let target =
                                    if starts draft.Root parts then
                                        List.skip draft.Root.Length parts
                                    else
                                        parts

                                { Index = e.Index
                                  Destination = path target }))

                { draft with Files = retained @ added }
            | LayoutChange.Destination(source, destination) ->
                let affected =
                    files draft.Manifest
                    |> List.filter (fun e -> starts source (LogicalPath.components e.Path))
                    |> List.map (fun e -> e.Index, e)
                    |> Map.ofList

                if affected.IsEmpty then
                    refuse "Choose a file or folder in this archive."

                let remapped =
                    draft.Files
                    |> List.map (fun file ->
                        match affected |> Map.tryFind file.Index with
                        | None -> file
                        | Some entry ->
                            { file with
                                Destination =
                                    path (
                                        destination
                                        @ (LogicalPath.components entry.Path
                                           |> List.skip source.Length)
                                    ) })

                { draft with Files = remapped }

        { updated with
            Revision = draft.Revision + 1L }
        |> finish

    let confirm (plan: InstallationPlan) (manifest: ArchiveManifest) =
        if manifest.Sha256 <> plan.Sha256 then
            refuse "The archive changed. Read its contents and review the installation again."

        let checkedPlan =
            { Id = Guid.Empty
              Revision = 0L
              Artifact = plan.Artifact
              ArchiveName = plan.ArchiveName
              Manifest = manifest
              Root = plan.Root
              Files = plan.Files
              Name = plan.Name
              Version = plan.Version
              Plan = None }
            |> finish

        if
            checkedPlan.Plan.Value.Fingerprint <> plan.Fingerprint
            || checkedPlan.Plan.Value.Bytes <> plan.Bytes
        then
            refuse "The installation plan changed. Review it again."
