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

    let private fingerprint
        (reference: ModConductor.ArtifactLibrary.ArtifactRef)
        sha
        name
        version
        (files: SelectedFile list)
        (target: InstallationTarget option)
        =
        use buffer = new MemoryStream()
        use writer = new BinaryWriter(buffer, Encoding.UTF8, true)
        writer.Write(string reference.WorkspaceId)
        writer.Write(string reference.Id)
        writer.Write(reference.Revision)
        writer.Write(sha: string)
        writer.Write(name: string)
        writer.Write(version: string)

        for file in files |> List.sortBy _.Index do
            writer.Write(file.Index)
            writer.Write(LogicalPath.display file.Destination)

        match target with
        | None -> ()
        | Some target ->
            writer.Write(string target.ModId)
            writer.Write(target.Revision)
            writer.Write(string target.PreviousVersion)

            for file in target.Existing |> List.sortBy _.Path do
                writer.Write(LogicalPath.display file.Path)
                writer.Write(string file.Payload.Id)
                writer.Write(file.Payload.Length)
                writer.Write(file.Payload.Sha256)

        writer.Flush()
        SHA256.HashData(buffer.ToArray()) |> Convert.ToHexStringLower

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

            let selected = System.Collections.Generic.HashSet<int>()
            let mutable bytes = 0L

            for file in draft.Files do
                let entry =
                    entries
                    |> Map.tryFind file.Index
                    |> Option.defaultWith (fun () ->
                        refuse "An included file is not in this archive.")

                if entry.Directory || not (selected.Add file.Index) then
                    refuse "Choose each archive file only once."

                bytes <- bytes + entry.Size

            Destinations.validate (draft.Files |> List.map _.Destination)

            let fingerprint =
                fingerprint
                    draft.Artifact
                    draft.Manifest.Sha256
                    metadata.Name
                    metadata.Version
                    draft.Files
                    None

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
                          Fingerprint = fingerprint
                          Target = None } }

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

    let forUpdate
        (draft: InstallationDraft)
        name
        version
        (target: InstallationTarget)
        (selected: SelectedFile list)
        =
        let source =
            draft.Plan
            |> Option.defaultWith (fun () -> refuse "Review the archive layout first.")

        InventoryPolicy.metadata
            { Name = name
              Version = version
              Notes = ""
              Comment = ""
              Source = ""
              Categories = [] }
        |> Result.defaultWith (fun _ -> refuse "Enter a version of at most 256 characters.")
        |> ignore

        if selected |> List.exists (fun file -> not (List.contains file draft.Files)) then
            refuse "The archive selection changed. Review the layout again."

        Destinations.validate (
            (selected |> List.map _.Destination) @ (target.Existing |> List.map _.Path)
        )

        let sizes =
            draft.Manifest.Entries
            |> List.map (fun entry -> entry.Index, entry.Size)
            |> Map.ofList

        { source with
            Name = name
            Version = version
            Files = selected
            Bytes = selected |> List.sumBy (fun file -> sizes[file.Index])
            Target = Some target
            Fingerprint =
                fingerprint source.Artifact source.Sha256 name version selected (Some target) }

    let confirm (plan: InstallationPlan) (manifest: ArchiveManifest) =
        if manifest.Sha256 <> plan.Sha256 then
            refuse "The archive changed. Read its contents and review the installation again."

        let entries =
            manifest.Entries |> List.map (fun entry -> entry.Index, entry) |> Map.ofList

        let mutable bytes = 0L
        let selected = System.Collections.Generic.HashSet<int>()

        for file in plan.Files do
            match entries |> Map.tryFind file.Index with
            | Some entry when not entry.Directory && selected.Add file.Index ->
                bytes <- bytes + entry.Size
            | _ -> refuse "The installation plan changed. Review it again."

        let existing =
            plan.Target
            |> Option.map (fun target -> target.Existing |> List.map _.Path)
            |> Option.defaultValue []

        Destinations.validate ((plan.Files |> List.map _.Destination) @ existing)

        if
            bytes <> plan.Bytes
            || fingerprint plan.Artifact plan.Sha256 plan.Name plan.Version plan.Files plan.Target
               <> plan.Fingerprint
        then
            refuse "The installation plan changed. Review it again."
