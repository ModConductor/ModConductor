namespace ModConductor.Skse

open System
open System.IO
open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.DeploymentPlanning
open ModConductor.Platform

module SkseArchiveLayout =
    let private path parts =
        LogicalPath.create parts
        |> Result.defaultWith (fun _ -> invalidOp "The SKSE path is invalid.")

    let private startsWith (prefix: string list) (parts: string list) =
        prefix.Length <= parts.Length
        && List.forall2
            (fun expected actual -> String.Equals(expected, actual, StringComparison.OrdinalIgnoreCase))
            prefix
            (List.take prefix.Length parts)

    let review (release: SkseRelease) (manifest: ArchiveManifest) =
        let files = manifest.Entries |> List.filter (fun entry -> not entry.Directory)

        let commonRoot =
            files
            |> List.map (fun entry -> LogicalPath.components entry.Path |> List.tryHead)
            |> List.distinct

        match commonRoot with
        | [ Some root ] ->
            let selected = ResizeArray<SelectedFile>()
            let componentFiles = ResizeArray<ComponentFile>()
            let mutable loader = None
            let mutable runtimeDll = false

            for entry in files do
                let parts = LogicalPath.components entry.Path
                let relative = List.tail parts
                let name = relative |> List.tryLast |> Option.defaultValue ""

                let destination =
                    match relative with
                    | [ value ] when
                        String.Equals(value, "skse64_loader.exe", StringComparison.OrdinalIgnoreCase)
                        ->
                        loader <- Some value
                        Some(ComponentRoot.GameRoot, relative)
                    | [ value ] when
                        String.Equals(
                            value,
                            "skse64_steam_loader.dll",
                            StringComparison.OrdinalIgnoreCase
                        )
                        ->
                        Some(ComponentRoot.GameRoot, relative)
                    | [ value ] when
                        value.StartsWith("skse64_", StringComparison.OrdinalIgnoreCase)
                        && value.EndsWith(".dll", StringComparison.OrdinalIgnoreCase)
                        && not (
                            String.Equals(
                                value,
                                "skse64_steam_loader.dll",
                                StringComparison.OrdinalIgnoreCase
                            )
                        )
                        ->
                        runtimeDll <- true
                        Some(ComponentRoot.GameRoot, relative)
                    | "Data" :: rest when not rest.IsEmpty -> Some(ComponentRoot.Data, rest)
                    | _ -> None

                match destination with
                | None -> ()
                | Some(rootRole, target) ->
                    let stored =
                        match rootRole with
                        | ComponentRoot.GameRoot -> "Root" :: relative
                        | ComponentRoot.Data -> "Data" :: target

                    let storedPath = path stored
                    selected.Add({ Index = entry.Index; Destination = storedPath })

                    componentFiles.Add(
                        { Source = storedPath
                          Root = rootRole
                          Destination = path target
                          Use = ComponentFileUse.Immutable }
                    )

            if loader.IsNone || not runtimeDll then
                Error(
                    SkseProblem.InvalidArchive
                        "The archive is missing the SKSE loader or runtime DLL."
                )
            elif
                componentFiles
                |> Seq.filter (fun file -> file.Root = ComponentRoot.Data)
                |> Seq.isEmpty
            then
                Error(
                    SkseProblem.InvalidArchive
                        "The archive does not contain SKSE Data files. No files were installed."
                )
            else
                Ok
                    { Files = Seq.toList selected
                      ComponentFiles = Seq.toList componentFiles
                      Loader = loader.Value }
        | _ ->
            Error(
                SkseProblem.InvalidArchive
                    "The SKSE archive has an unexpected root layout. No files were installed."
            )
