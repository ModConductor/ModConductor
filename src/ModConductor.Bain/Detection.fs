namespace ModConductor.Bain

open System
open System.IO
open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.Platform

module Detection =
    let private key (value: string) = value.Normalize().ToUpperInvariant()
    let private same a b = key a = key b

    let private metadataDirectory (name: string) =
        name.StartsWith("--", StringComparison.Ordinal)
        || Set.contains
            (name.ToLowerInvariant())
            (set [ "fomod"; "omod conversion data"; "images"; "screenshots"; "docs" ])

    let private dataFile name =
        List.contains
            (Path.GetExtension(name: string).ToLowerInvariant())
            [ ".esp"; ".esm"; ".esl"; ".bsa" ]

    let private noteFile name =
        List.contains
            (Path.GetExtension(name: string).ToLowerInvariant())
            [ ".txt"; ".md"; ".rtf"; ".pdf"; ".png"; ".jpg"; ".jpeg" ]

    let private dataDirectory (name: string) =
        DataLayout.directories.Contains(name.ToLowerInvariant())

    let private folderGroups (values: (ArchiveEntry * string list) list) =
        values
        |> List.filter (fun (_, parts) -> List.length parts > 1)
        |> List.groupBy (fun (_, parts) -> key (List.head parts))
        |> List.map (fun (_, files) ->
            let name = files |> List.head |> snd |> List.head
            name, (files |> List.map (fun (entry, parts) -> entry, List.tail parts)))
        |> List.sortWith (fun (a, _) (b, _) -> String.CompareOrdinal(key a, key b))

    let private package root index name (values: (ArchiveEntry * string list) list) =
        let groups = folderGroups values
        let loose = values |> List.filter (fun (_, parts) -> parts.Length = 1)

        let wrapped =
            match groups with
            | [ folder, nested ] when
                same folder "Data" && loose |> List.forall (fun (_, p) -> noteFile p.Head)
                ->
                Some(folder, nested)
            | _ -> None

        let root, values =
            match wrapped with
            | Some(folder, nested) -> root @ [ name; folder ], nested
            | None -> root @ [ name ], values

        let groups = folderGroups values
        let loose = values |> List.filter (fun (_, parts) -> parts.Length = 1)

        let recognized =
            groups |> List.exists (fst >> dataDirectory)
            || loose |> List.exists (fun (_, p) -> dataFile p.Head)

        let ambiguous = groups |> List.exists (fun (name, _) -> same name "Data")

        if not recognized || ambiguous then
            None
        else
            let files =
                values
                |> List.filter (fun (_, p) ->
                    p.Length <> 1 || not (same p.Head "wizard.txt" || same p.Head "package.txt"))
                |> List.map (fun (entry, parts) ->
                    { Index = entry.Index
                      Destination =
                        LogicalPath.create parts
                        |> Result.defaultWith (fun _ ->
                            raise (
                                InstallationException
                                    "The package destination is unsafe. Use the manual layout."
                            )) })

            let selected = files |> List.map _.Index |> Set.ofList

            Some
                { Index = index
                  Name = name
                  Root = root
                  Files = files
                  Bytes =
                    values
                    |> List.filter (fun (entry, _) -> selected.Contains entry.Index)
                    |> List.sumBy (fun (e, _) -> e.Size) }

    let inspect (manifest: ArchiveManifest) =
        let values =
            manifest.Entries
            |> List.filter (fun e -> not e.Directory)
            |> List.map (fun e -> e, LogicalPath.components e.Path)

        let wizardRoots =
            values
            |> List.filter (fun (_, parts) -> same (List.last parts) "wizard.txt")
            |> List.groupBy (fun (_, parts) ->
                parts |> List.take (parts.Length - 1) |> List.map key)
            |> List.map (fun (root, entries) ->
                root, entries |> List.map (fun (entry, _) -> entry.Path))
            |> Map.ofList

        let rec at root (values: (ArchiveEntry * string list) list) allowWrapper =
            let groups = folderGroups values |> List.filter (fst >> metadataDirectory >> not)
            let loose = values |> List.filter (fun (_, parts) -> parts.Length = 1)

            let scripts =
                values
                |> List.choose (fun (entry, p) ->
                    if p.Length <= 2 && same (List.last p) "wizard.txt" then
                        Some entry.Path
                    else
                        None)

            let notes =
                loose
                |> List.tryPick (fun (entry, p) ->
                    if same p.Head "package.txt" then Some entry else None)

            let candidates =
                groups
                |> List.mapi (fun index (name, values) -> name, package root index name values)

            let valid = candidates |> List.choose snd

            let scripts =
                scripts
                @ (valid
                   |> List.collect (fun package ->
                       wizardRoots
                       |> Map.tryFind (package.Root |> List.map key)
                       |> Option.defaultValue []))
                |> List.distinct

            let direct =
                groups |> List.exists (fun (name, _) -> dataDirectory name || same name "Data")
                || loose |> List.exists (fun (_, p) -> dataFile p.Head)

            let unknownLoose = loose |> List.exists (fun (_, p) -> not (noteFile p.Head))

            let ambiguous =
                candidates
                |> List.tryPick (fun (name, value) -> if value.IsNone then Some name else None)

            let offered =
                valid.Length >= 2
                || (not valid.IsEmpty && groups.Length > 1)
                || (groups.Length > 1
                    && groups |> List.exists (fun (name, _) -> Char.IsDigit name[0]))

            if allowWrapper && groups.Length = 1 && not direct && not unknownLoose then
                let name, nested = groups.Head
                let input = at (root @ [ name ]) nested false

                { input with
                    Scripts = List.distinct (scripts @ input.Scripts) }
            elif offered then
                let problem =
                    if direct || unknownLoose then
                        Some
                            "The archive mixes package folders with other files. Use the manual layout."
                    else
                        ambiguous
                        |> Option.map (fun name ->
                            name + " is not a recognized data folder. Use the manual layout.")

                let definition =
                    if problem.IsSome then
                        None
                    else
                        let entries =
                            manifest.Entries |> List.map (fun e -> e.Index, e) |> Map.ofList

                        let sources =
                            valid
                            |> List.collect (fun p ->
                                p.Files
                                |> List.map (fun file ->
                                    { Package = p.Index
                                      Name = p.Name
                                      File = file
                                      Source = entries[file.Index].Path }))
                            |> List.groupBy (fun c -> Destinations.key c.File.Destination)
                            |> Map.ofList

                        Some
                            { Root = root
                              Packages = valid
                              Candidates = sources
                              Notes = notes }

                { Definition = definition
                  Problem = problem
                  Scripts = scripts }
            elif not scripts.IsEmpty && not direct && valid.IsEmpty then
                { Definition = None
                  Problem = Some "No package folders were found. Use the manual layout."
                  Scripts = scripts }
            else
                { Definition = None
                  Problem = None
                  Scripts = scripts }

        at [] values true
