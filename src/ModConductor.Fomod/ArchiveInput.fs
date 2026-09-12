namespace ModConductor.Fomod

open System
open System.IO
open System.Xml
open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.Platform

module ArchiveInput =
    let private same (a: string) b =
        String.Equals(a, b, StringComparison.OrdinalIgnoreCase)

    let private named name (entry: ArchiveEntry) =
        match LogicalPath.components entry.Path |> List.rev with
        | file :: folder :: _ -> not entry.Directory && same name file && same "fomod" folder
        | _ -> false

    let private bytes limit (contents: ArchiveContents) indices =
        let selected =
            contents.Manifest.Entries
            |> List.filter (fun e -> List.contains e.Index indices)

        if selected |> List.exists (fun e -> e.Size > limit e.Index) then
            raise (
                FomodException
                    "The installer configuration exceeds its size limit. Use the manual layout."
            )

        let mutable values = Map.empty

        contents.ReadEntries(
            indices,
            fun (index, input) ->
                use output = new MemoryStream()
                input.CopyTo output
                values <- values.Add(index, output.ToArray())
        )

        values

    let read (contents: ArchiveContents) =
        let entries = contents.Manifest.Entries
        let configs = entries |> List.filter (named "ModuleConfig.xml")

        match configs with
        | [] when entries |> List.exists (named "script.cs") ->
            InstallerInput.Unavailable
                "This archive needs a C# installer. Executable scripts are not supported. Use the manual layout."
        | [] -> InstallerInput.Absent
        | [ config ] when LogicalPath.components config.Path |> List.length <= 3 ->
            try
                let root =
                    LogicalPath.components config.Path
                    |> List.take (
                        LogicalPath.components config.Path |> List.length |> (fun n -> n - 2)
                    )

                let info =
                    entries
                    |> List.tryFind (fun e ->
                        named "info.xml" e
                        && (LogicalPath.components e.Path |> List.take root.Length) = root
                        && (LogicalPath.components e.Path).Length = root.Length + 2)

                let selected =
                    config.Index
                    :: (info |> Option.map (fun e -> [ e.Index ]) |> Option.defaultValue [])

                let data =
                    bytes
                        (fun index ->
                            if index = config.Index then
                                4L * 1024L * 1024L
                            else
                                256L * 1024L)
                        contents
                        selected

                use input = new MemoryStream(data[config.Index], false)

                let definition =
                    XmlModel.read
                        root
                        contents.Manifest
                        (XmlValues.document (4L * 1024L * 1024L) input)

                let definition =
                    match info with
                    | None -> definition
                    | Some info ->
                        use input = new MemoryStream(data[info.Index], false)
                        let metadata = XmlValues.document (256L * 1024L) input

                        { definition with
                            Name =
                                if definition.Name <> "" then
                                    definition.Name
                                else
                                    XmlValues.text "Name" "" metadata
                            Version = XmlValues.text "Version" "" metadata }

                InstallerInput.Xml definition
            with
            | :? XmlException ->
                InstallerInput.Unavailable
                    "The installer XML cannot be read. Download a fresh copy or use the manual layout."
            | :? FomodException as error -> InstallerInput.Unavailable error.Message
        | _ ->
            InstallerInput.Unavailable
                "The archive has an ambiguous or unsupported installer folder. Use the manual layout."

    let image (definition: Definition) path =
        let expected =
            XmlValues.logical (String.concat "/" (definition.Root @ path))
            |> Destinations.key

        definition.Manifest.Entries
        |> List.tryFind (fun e -> not e.Directory && Destinations.key e.Path = expected)
        |> Option.filter (fun e ->
            e.Size <= 4L * 1024L * 1024L
            && [ ".png"; ".jpg"; ".jpeg" ]
               |> List.contains (Path.GetExtension(LogicalPath.display e.Path).ToLowerInvariant()))
