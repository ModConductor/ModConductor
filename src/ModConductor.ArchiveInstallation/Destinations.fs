namespace ModConductor.ArchiveInstallation

open System.Collections.Generic
open ModConductor.Platform

module Destinations =
    let private policy =
        { TargetPolicy.windows with
            Unicode = CanonicalComposition }

    let key path =
        (TargetPolicy.key policy path).ToUpperInvariant()

    let private prefixes path =
        let parts = LogicalPath.components path

        [ for count in 1 .. parts.Length - 1 ->
              LogicalPath.create (List.take count parts)
              |> Result.defaultWith (string >> invalidOp) ]

    let merge getPath values =
        let winners = Dictionary<string, int>()
        let descendants = Dictionary<string, HashSet<string>>()

        for index, value in values |> List.indexed do
            let path = getPath value
            let name = key path

            match descendants.TryGetValue name with
            | true, children ->
                for child in children do
                    winners.Remove child |> ignore
            | _ -> ()

            for parent in prefixes path do
                let parent = key parent
                winners.Remove parent |> ignore

                match descendants.TryGetValue parent with
                | true, children -> children.Add name |> ignore
                | _ -> descendants[parent] <- HashSet<string>([ name ])

            winners[name] <- index

        values
        |> List.indexed
        |> List.choose (fun (index, value) ->
            match winners.TryGetValue(key (getPath value)) with
            | true, winner when winner = index -> Some value
            | _ -> None)

    let normalize (paths: LogicalPath list) =
        let directories = Dictionary<string, string>()

        [ for path in paths do
              let parts = LogicalPath.components path

              let folders =
                  [ for count in 1 .. parts.Length - 1 do
                        let parent =
                            LogicalPath.create (List.take count parts)
                            |> Result.defaultWith (string >> invalidOp)

                        let name = key parent

                        match directories.TryGetValue name with
                        | true, spelling -> yield spelling
                        | _ ->
                            let spelling = parts[count - 1]
                            directories[name] <- spelling
                            yield spelling ]

              yield
                  LogicalPath.create (folders @ [ List.last parts ])
                  |> Result.defaultWith (string >> invalidOp) ]

    let validate (paths: LogicalPath list) =
        let targets = paths |> List.map key |> Set.ofList

        if targets.Count <> paths.Length then
            Error "The installation plan contains repeated file destinations. Review it again."
        elif
            paths
            |> List.exists (fun path ->
                prefixes path |> List.exists (fun parent -> targets.Contains(key parent)))
        then
            Error "The installation plan contains a file in place of a folder. Review it again."
        else
            Ok()
