namespace ModConductor.Fnis

open System
open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.DeploymentPlanning
open ModConductor.Platform

module FnisArchiveLayout =
    let private path parts =
        LogicalPath.create parts
        |> Result.defaultWith (fun _ -> invalidOp "The reviewed FNIS path is invalid.")

    let private equals left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private dataRelative (entry: ArchiveEntry) =
        let parts = LogicalPath.components entry.Path

        match parts |> List.tryFindIndex (equals "Data") with
        | Some index when index <= 1 && index + 1 < parts.Length ->
            Some(parts |> List.skip (index + 1))
        | _ -> None

    let review (manifest: ArchiveManifest) =
        let files = manifest.Entries |> List.filter (fun entry -> not entry.Directory)

        let mapped =
            files
            |> List.choose (fun entry ->
                dataRelative entry
                |> Option.map (fun relative ->
                    let stored = path ("Data" :: relative)

                    { Index = entry.Index
                      Destination = stored },
                    { Source = stored
                      Root = ComponentRoot.Data
                      Destination = path relative
                      Use = ComponentFileUse.Immutable },
                    relative,
                    entry.Size))

        let expected = [ "tools"; "GenerateFNIS_for_Users"; "GenerateFNISforUsers.exe" ]

        let generator =
            mapped
            |> List.tryFind (fun (_, _, relative, size) ->
                size > 0L
                && relative.Length = expected.Length
                && List.forall2 equals relative expected)

        let behavior =
            mapped
            |> List.exists (fun (_, _, relative, size) ->
                size > 0L
                && relative |> List.exists (fun part -> equals part "behaviors")
                && (relative |> List.last).EndsWith(".hkx", StringComparison.OrdinalIgnoreCase))

        if generator.IsNone || not behavior then
            Error(
                FnisProblem.InvalidArchive
                    "The archive does not contain the reviewed FNIS Behavior SE generator and behavior files. No files were installed."
            )
        elif mapped.Length <> files.Length then
            Error(
                FnisProblem.InvalidArchive
                    "The FNIS archive contains files outside its reviewed Skyrim Data layout. No files were installed."
            )
        else
            Ok
                { Files = mapped |> List.map (fun (selected, _, _, _) -> selected)
                  ComponentFiles =
                    mapped |> List.map (fun (_, componentFile, _, _) -> componentFile)
                  Generator = FnisCatalogue.GeneratorPath }
