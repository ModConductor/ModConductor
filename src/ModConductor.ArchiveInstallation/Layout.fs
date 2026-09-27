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
        |> Result.mapError (fun _ -> "Choose a relative destination within the mod.")

    let private files (manifest: ArchiveManifest) =
        manifest.Entries |> List.filter (fun e -> not e.Directory)

    let private rootFiles manifest root =
        files manifest
        |> List.fold
            (fun outcome e ->
                outcome
                |> Result.bind (fun selected ->
                    let parts = LogicalPath.components e.Path

                    if starts root parts && parts.Length > root.Length then
                        path (List.skip root.Length parts)
                        |> Result.map (fun destination ->
                            { Index = e.Index
                              Destination = destination }
                            :: selected)
                    else
                        Ok selected))
            (Ok [])
        |> Result.map List.rev

    let private quickRoot manifest =
        let markers = DataLayout.directories

        let candidates =
            files manifest
            |> List.collect (fun e ->
                let parts = LogicalPath.components e.Path

                let markerRoot index =
                    let leading = List.take index parts

                    match
                        leading
                        |> List.tryFindIndex (fun part ->
                            part.Equals("Data", StringComparison.OrdinalIgnoreCase))
                    with
                    | Some data -> List.take (data + 1) leading
                    | None -> leading

                [ for i in 0 .. parts.Length - 1 do
                      let name = parts[i].ToLowerInvariant()

                      if
                          (i < parts.Length - 1 && markers.Contains name)
                          || (i = parts.Length - 1
                              && List.contains (Path.GetExtension name) [ ".esp"; ".esm"; ".esl" ])
                      then
                          yield markerRoot i

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
        (nested: NestedArchiveRef option)
        (bundle: BundleDestination option)
        =
        use buffer = new MemoryStream()
        use writer = new BinaryWriter(buffer, Encoding.UTF8, true)
        writer.Write(string reference.WorkspaceId)
        writer.Write(string reference.Id)
        writer.Write(reference.Revision)
        writer.Write(sha: string)
        writer.Write(name: string)
        writer.Write(version: string)

        match nested with
        | None -> ()
        | Some input ->
            writer.Write(string input.BundleId)
            writer.Write(string input.SourceId)
            writer.Write(input.Sha256)

        match bundle with
        | None -> ()
        | Some destination ->
            writer.Write(string destination.BundleId)
            writer.Write(string destination.ItemId)
            writer.Write(string destination.ModId)

        for file in files |> List.sortBy (fun file -> file.Index, file.Destination) do
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
            Ok { draft with Plan = None }
        else
            let metadata =
                InventoryPolicy.metadata
                    { Name = draft.Name
                      Version = draft.Version
                      Notes = ""
                      Comment = ""
                      Source = ""
                      Categories = [] }
                |> Result.mapError (fun _ ->
                    "Enter a mod name and a version of at most 256 characters.")

            metadata
            |> Result.bind (fun metadata ->
                let entries =
                    draft.Manifest.Entries |> List.map (fun e -> e.Index, e) |> Map.ofList

                let selected = System.Collections.Generic.HashSet<int>()

                let bytes =
                    draft.Files
                    |> List.fold
                        (fun outcome file ->
                            outcome
                            |> Result.bind (fun bytes ->
                                match entries |> Map.tryFind file.Index with
                                | None -> Error "An included file is not in this archive."
                                | Some entry when entry.Directory ->
                                    Error "Choose a file rather than a folder entry."
                                | Some entry ->
                                    Ok(
                                        if selected.Add file.Index then
                                            bytes + entry.Size
                                        else
                                            bytes
                                    )))
                        (Ok 0L)

                bytes
                |> Result.bind (fun bytes ->
                    Destinations.validate (draft.Files |> List.map _.Destination)
                    |> Result.map (fun () ->
                        let fingerprint =
                            fingerprint
                                draft.Artifact
                                draft.Manifest.Sha256
                                metadata.Name
                                metadata.Version
                                draft.Files
                                None
                                draft.Nested
                                draft.Bundle

                        { draft with
                            Name = metadata.Name
                            Plan =
                                Some
                                    { Artifact = draft.Artifact
                                      ArchiveName = draft.ArchiveName
                                      Nested = draft.Nested
                                      Bundle = draft.Bundle
                                      Sha256 = draft.Manifest.Sha256
                                      Name = metadata.Name
                                      Version = metadata.Version
                                      Root = draft.Root
                                      Files = draft.Files
                                      Bytes = bytes
                                      Fingerprint = fingerprint
                                      Target = None } })))

    let prepare reference name manifest =
        let root = quickRoot manifest

        let selected =
            root |> Option.map (rootFiles manifest) |> Option.defaultValue (Ok [])

        selected
        |> Result.bind (fun selected ->
            { Id = Guid.NewGuid()
              Revision = 0L
              Artifact = reference
              ArchiveName = name
              Nested = None
              Bundle = None
              Manifest = manifest
              Root = defaultArg root []
              Files = selected
              Name =
                (let suggested = Path.GetFileNameWithoutExtension name in

                 if String.IsNullOrWhiteSpace suggested then
                     "New mod"
                 else
                     suggested)
              Version = ""
              Plan = None
              Installer = InstallationMode.Manual
              AvailableInstallers = [ InstallationMode.Manual ]
              WizardScripts = [] }
            |> finish)

    let forBundle (draft: InstallationDraft) nested destination name =
        { draft with
            Nested = Some nested
            Bundle = Some destination
            Name = name }
        |> finish

    let change (draft: InstallationDraft) change =
        let updated =
            match change with
            | LayoutChange.Metadata(name, version) ->
                Ok
                    { draft with
                        Name = name
                        Version = version }
            | LayoutChange.Root root ->
                rootFiles draft.Manifest root
                |> Result.bind (fun chosen ->
                    if chosen.IsEmpty then
                        Error "Choose a folder that contains files."
                    else
                        Ok
                            { draft with
                                Root = root
                                Files = chosen })
            | LayoutChange.Include(source, included) ->
                let matching =
                    files draft.Manifest
                    |> List.filter (fun e -> starts source (LogicalPath.components e.Path))

                if matching.IsEmpty then
                    Error "Choose a file or folder in this archive."
                else
                    let ids = matching |> List.map _.Index |> Set.ofList
                    let retained = draft.Files |> List.filter (fun f -> not (ids.Contains f.Index))

                    let added =
                        if not included then
                            Ok []
                        else
                            matching
                            |> List.fold
                                (fun outcome entry ->
                                    outcome
                                    |> Result.bind (fun selected ->
                                        match
                                            draft.Files
                                            |> List.tryFind (fun f -> f.Index = entry.Index)
                                        with
                                        | Some file -> Ok(file :: selected)
                                        | None ->
                                            let parts = LogicalPath.components entry.Path

                                            let target =
                                                if starts draft.Root parts then
                                                    List.skip draft.Root.Length parts
                                                else
                                                    parts

                                            path target
                                            |> Result.map (fun destination ->
                                                { Index = entry.Index
                                                  Destination = destination }
                                                :: selected)))
                                (Ok [])
                            |> Result.map List.rev

                    added
                    |> Result.map (fun selected ->
                        { draft with
                            Files = retained @ selected })
            | LayoutChange.Destination(source, destination) ->
                let affected =
                    files draft.Manifest
                    |> List.filter (fun e -> starts source (LogicalPath.components e.Path))
                    |> List.map (fun e -> e.Index, e)
                    |> Map.ofList

                if affected.IsEmpty then
                    Error "Choose a file or folder in this archive."
                else
                    draft.Files
                    |> List.fold
                        (fun outcome file ->
                            outcome
                            |> Result.bind (fun selected ->
                                match affected |> Map.tryFind file.Index with
                                | None -> Ok(file :: selected)
                                | Some entry ->
                                    path (
                                        destination
                                        @ (LogicalPath.components entry.Path
                                           |> List.skip source.Length)
                                    )
                                    |> Result.map (fun destination ->
                                        { file with Destination = destination } :: selected)))
                        (Ok [])
                    |> Result.map (fun reversed -> { draft with Files = List.rev reversed })

        updated
        |> Result.bind (fun updated ->
            { updated with
                Revision = draft.Revision + 1L }
            |> finish)

    let selectFiles (draft: InstallationDraft) name version files =
        { draft with
            Revision = draft.Revision + 1L
            Root = []
            Files = files
            Name =
                if draft.Bundle.IsSome || String.IsNullOrWhiteSpace name then
                    draft.Name
                else
                    name
            Version = version }
        |> finish

    let private updatePlan
        (draft: InstallationDraft)
        name
        version
        (target: InstallationTarget)
        (selected: SelectedFile list)
        (source: InstallationPlan)
        =
        let sizes =
            draft.Manifest.Entries
            |> List.map (fun entry -> entry.Index, entry.Size)
            |> Map.ofList

        { source with
            Name = name
            Version = version
            Files = selected
            Bytes =
                selected
                |> List.distinctBy _.Index
                |> List.sumBy (fun file -> sizes[file.Index])
            Target = Some target
            Fingerprint =
                fingerprint
                    source.Artifact
                    source.Sha256
                    name
                    version
                    selected
                    (Some target)
                    source.Nested
                    source.Bundle }

    let forUpdate
        (draft: InstallationDraft)
        name
        version
        (target: InstallationTarget)
        (selected: SelectedFile list)
        =
        match draft.Plan with
        | None -> Error "Review the archive layout first."
        | Some source ->
            InventoryPolicy.metadata
                { Name = name
                  Version = version
                  Notes = ""
                  Comment = ""
                  Source = ""
                  Categories = [] }
            |> Result.mapError (fun _ -> "Enter a version of at most 256 characters.")
            |> Result.bind (fun _ ->
                if selected |> List.exists (fun file -> not (List.contains file draft.Files)) then
                    Error "The archive selection changed. Review the layout again."
                else
                    Destinations.validate (
                        (selected |> List.map _.Destination) @ (target.Existing |> List.map _.Path)
                    )
                    |> Result.map (fun () -> updatePlan draft name version target selected source))

    let confirm (plan: InstallationPlan) (manifest: ArchiveManifest) =
        if manifest.Sha256 <> plan.Sha256 then
            refuse "The archive changed. Read its contents and review the installation again."

        let entries =
            manifest.Entries |> List.map (fun entry -> entry.Index, entry) |> Map.ofList

        let mutable bytes = 0L
        let selected = System.Collections.Generic.HashSet<int>()

        for file in plan.Files do
            match entries |> Map.tryFind file.Index with
            | Some entry when not entry.Directory ->
                if selected.Add file.Index then
                    bytes <- bytes + entry.Size
            | _ -> refuse "The installation plan changed. Review it again."

        let existing =
            plan.Target
            |> Option.map (fun target -> target.Existing |> List.map _.Path)
            |> Option.defaultValue []

        match Destinations.validate ((plan.Files |> List.map _.Destination) @ existing) with
        | Error message -> refuse message
        | Ok() -> ()

        if
            bytes <> plan.Bytes
            || fingerprint
                plan.Artifact
                plan.Sha256
                plan.Name
                plan.Version
                plan.Files
                plan.Target
                plan.Nested
                plan.Bundle
               <> plan.Fingerprint
        then
            refuse "The installation plan changed. Review it again."
