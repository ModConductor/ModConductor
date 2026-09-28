namespace ModConductor.Fnis

open System
open ModConductor.ArchiveInstallation
open ModConductor.DeploymentPlanning
open ModConductor.Platform

module FnisArchiveLayout =
    let private path parts =
        LogicalPath.create parts
        |> Result.defaultWith (fun _ -> invalidOp "The reviewed FNIS path is invalid.")

    let private equals left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let review (draft: InstallationDraft) =
        let mapped =
            draft.Files
            |> List.map (fun selected ->
                let relative = LogicalPath.components selected.Destination
                let stored = path ("Data" :: relative)

                { selected with Destination = stored },
                { Source = stored
                  Root = ComponentRoot.Data
                  Destination = selected.Destination
                  Use = ComponentFileUse.Immutable },
                relative)

        let generator =
            mapped
            |> List.tryFind (fun (_, _, relative) ->
                relative |> List.last |> equals "GenerateFNISforUsers.exe")

        match generator with
        | None ->
            Error(
                FnisProblem.InvalidArchive
                    "The selected FNIS files do not contain GenerateFNISforUsers.exe. No files were installed."
            )
        | Some(selectedGenerator, _, _) ->
            Ok
                { Files = mapped |> List.map (fun (selected, _, _) -> selected)
                  ComponentFiles =
                    mapped
                    |> List.map (fun (_, componentFile, _) ->
                        if componentFile.Source = selectedGenerator.Destination then
                            { componentFile with
                                Use = ComponentFileUse.WritableContainingDirectory }
                        else
                            componentFile)
                  Generator = LogicalPath.display selectedGenerator.Destination }
