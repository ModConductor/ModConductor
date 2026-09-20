namespace ModConductor.Enb

open System
open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.DeploymentPlanning
open ModConductor.Platform

module EnbArchiveLayouts =
    type private Mapping =
        { File: SelectedFile
          Component: ComponentFile }

    let private path parts =
        LogicalPath.create parts
        |> Result.defaultWith (fun _ -> invalidOp "The reviewed ENB path is invalid.")

    let private equals left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private selected root destination useValue (entry: ArchiveEntry) : Mapping =
        let source = path destination

        { File =
            { Index = entry.Index
              Destination = source }
          Component =
            { Source = source
              Root = root
              Destination = path destination
              Use = useValue } }

    let runtime (pin: EnbComponentPin) (manifest: ArchiveManifest) =
        EnbCatalogue.validateHash pin manifest.Sha256
        |> Result.bind (fun () ->
            let files = manifest.Entries |> List.filter (fun entry -> not entry.Directory)

            let find name =
                files
                |> List.tryFind (fun entry ->
                    match LogicalPath.components entry.Path with
                    | [ folder; value ] -> equals folder "WrapperVersion" && equals value name
                    | _ -> false)

            match find "d3d11.dll", find "d3dcompiler_46e.dll" with
            | Some proxy, Some compiler when proxy.Size > 0L && compiler.Size > 0L ->
                let mappings =
                    [ selected
                          ComponentRoot.GameRoot
                          [ "d3d11.dll" ]
                          ComponentFileUse.Immutable
                          proxy
                      selected
                          ComponentRoot.GameRoot
                          [ "d3dcompiler_46e.dll" ]
                          ComponentFileUse.Immutable
                          compiler ]

                Ok
                    { Files = mappings |> List.map _.File
                      ComponentFiles = mappings |> List.map _.Component }
            | _ ->
                Error(
                    EnbProblem.InvalidArchive
                        "The archive does not contain the complete ENBSeries wrapper files. No files were installed."
                ))

    let leanPreset (pin: EnbComponentPin) (manifest: ArchiveManifest) =
        EnbCatalogue.validateHash pin manifest.Sha256
        |> Result.bind (fun () ->
            let files = manifest.Entries |> List.filter (fun entry -> not entry.Directory)

            let root =
                files
                |> List.choose (fun entry ->
                    match LogicalPath.components entry.Path with
                    | first :: _ when equals first "Lean ENB" -> Some first
                    | _ -> None)
                |> List.distinct

            match root with
            | [ root ] ->
                let mappings =
                    files
                    |> List.choose (fun entry ->
                        match LogicalPath.components entry.Path with
                        | first :: relative when equals first root && not relative.IsEmpty ->
                            let name = relative |> List.last

                            if
                                equals name "enbseries.ini"
                                || equals name "enblocal.ini"
                                || equals (List.head relative) "enbseries"
                            then
                                Some(
                                    selected
                                        ComponentRoot.GameRoot
                                        relative
                                        (if equals name "enblocal.ini" then
                                             ComponentFileUse.WritableConfiguration
                                         else
                                             ComponentFileUse.Immutable)
                                        entry
                                )
                            else
                                None
                        | _ -> None)

                let names =
                    mappings
                    |> List.map (fun value -> LogicalPath.display value.Component.Destination)

                if
                    names |> List.exists (equals "enbseries.ini")
                    && names |> List.exists (equals "enblocal.ini")
                    && mappings.Length >= 3
                then
                    Ok
                        { Files = mappings |> List.map _.File
                          ComponentFiles = mappings |> List.map _.Component }
                else
                    Error(
                        EnbProblem.InvalidArchive
                            "The Lean ENB archive is incomplete. No files were installed."
                    )
            | _ ->
                Error(
                    EnbProblem.InvalidArchive
                        "The archive does not have the reviewed Lean ENB layout. No files were installed."
                ))

    let dataCompanion (pin: EnbComponentPin) (manifest: ArchiveManifest) =
        EnbCatalogue.validateHash pin manifest.Sha256
        |> Result.bind (fun () ->
            let files = manifest.Entries |> List.filter (fun entry -> not entry.Directory)

            let roots =
                files
                |> List.choose (fun entry ->
                    match LogicalPath.components entry.Path with
                    | first :: "Data" :: _ -> Some(Some first)
                    | "Data" :: _ -> Some None
                    | _ -> None)
                |> List.distinct

            match roots with
            | [ root ] ->
                let mappings =
                    files
                    |> List.choose (fun entry ->
                        let parts = LogicalPath.components entry.Path

                        let relative =
                            match root, parts with
                            | None, "Data" :: rest -> Some rest
                            | Some folder, first :: "Data" :: rest when equals folder first ->
                                Some rest
                            | _ -> None

                        relative
                        |> Option.filter (not << List.isEmpty)
                        |> Option.map (fun destination ->
                            selected
                                ComponentRoot.Data
                                destination
                                ComponentFileUse.Immutable
                                entry))

                if mappings.IsEmpty then
                    Error(
                        EnbProblem.InvalidArchive(
                            pin.Name
                            + " does not contain reviewed Data files. No files were installed."
                        )
                    )
                else
                    Ok
                        { Files = mappings |> List.map _.File
                          ComponentFiles = mappings |> List.map _.Component }
            | _ ->
                Error(
                    EnbProblem.InvalidArchive(
                        pin.Name + " has an unexpected archive layout. No files were installed."
                    )
                ))
