namespace ModConductor.Bain

open System
open ModConductor.ArchiveInstallation
open ModConductor.Platform

module Selection =
    let private winner (state: PackageSelection) key =
        let candidates =
            state.Definition.Candidates[key]
            |> List.filter (fun c -> state.Selected.Contains c.Package)

        match List.tryLast candidates with
        | None -> state.Files.Remove key
        | Some candidate ->
            state.Files.Add(
                key,
                { File = candidate.File
                  Source = candidate.Source
                  Choice = candidate.Name
                  Replaces = candidates |> List.take (candidates.Length - 1) |> List.map _.Source }
            )

    let choose index selected (state: PackageSelection) =
        let package =
            state.Definition.Packages
            |> List.tryFind (fun p -> p.Index = index)
            |> Option.defaultWith (fun () ->
                raise (InstallationException "Choose a folder from this package."))

        let mutable next =
            { state with
                Selected =
                    (if selected then
                         state.Selected.Add index
                     else
                         state.Selected.Remove index)
                Reviewing = false }

        for key in
            package.Files
            |> List.map (fun f -> Destinations.key f.Destination)
            |> List.distinct do
            next <- { next with Files = winner next key }

        next

    let private rebuild selected (state: PackageSelection) =
        let mutable next =
            { state with
                Selected = selected
                Reviewing = false }

        for key in state.Definition.Candidates.Keys do
            next <- { next with Files = winner next key }

        next

    let chooseAll selected (state: PackageSelection) =
        let chosen =
            if selected then
                state.Definition.Packages |> List.map _.Index |> Set.ofList
            else
                Set.empty

        rebuild chosen state

    let create definition =
        let initial =
            { Definition = definition
              Selected = Set.empty
              Excluded = Set.empty
              Files = Map.empty
              Reviewing = false }

        let chosen =
            definition.Packages
            |> List.filter (fun p -> p.Name.StartsWith("00", StringComparison.Ordinal))
            |> List.map _.Index
            |> Set.ofList

        rebuild chosen initial

    let includeFile path included (state: PackageSelection) =
        let path =
            LogicalPath.create path
            |> Result.defaultWith (fun _ ->
                raise (InstallationException "Choose a file from the package review."))

        let key = Destinations.key path

        if not state.Reviewing || not (state.Files.ContainsKey key) then
            raise (
                InstallationException "Review the package files before changing their selection."
            )

        { state with
            Excluded =
                (if included then
                     state.Excluded.Remove key
                 else
                     state.Excluded.Add key) }

    let files (state: PackageSelection) =
        state.Files
        |> Map.toList
        |> List.choose (fun (key, value) ->
            if state.Excluded.Contains key then
                None
            else
                Some value.File)
