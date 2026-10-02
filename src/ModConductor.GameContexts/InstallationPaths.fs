namespace ModConductor.GameContexts

open System
open ModConductor.Platform

module internal InstallationPaths =
    let read (root: HeldDirectory) (relative: string) identity =
        let rec read (parent: HeldDirectory) prefix =
            function
            | [ expected ] ->
                let actual =
                    parent.Names
                    |> Seq.filter (fun name ->
                        name.Equals(expected, StringComparison.OrdinalIgnoreCase))
                    |> Seq.toList

                match actual with
                | [ name ] ->
                    let stream, identity = parent.Read(name, identity) in
                    Ok(stream, identity, String.concat "/" (prefix @ [ name ]))
                | _ -> Error(relative + " was not found or has ambiguous names.")
            | expected :: rest ->
                let actual =
                    parent.Names
                    |> Seq.filter (fun name ->
                        name.Equals(expected, StringComparison.OrdinalIgnoreCase))
                    |> Seq.toList

                match actual with
                | [ name ] ->
                    use child = parent.Directory(name, None)
                    read child (prefix @ [ name ]) rest
                | _ -> Error(relative + " was not found or has ambiguous names.")
            | [] -> Error "The declared executable path is empty."

        relative.Split([| '/'; '\\' |], StringSplitOptions.RemoveEmptyEntries)
        |> Array.toList
        |> read root []
