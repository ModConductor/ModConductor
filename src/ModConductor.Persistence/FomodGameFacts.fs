namespace ModConductor.Persistence

open System
open System.IO
open System.Collections.Generic
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.Fomod

module internal FomodGameFacts =
    let observe (binding: GameBinding option) paths =
        let unknown path =
            Fact.Unknown(
                "The game file cannot be checked: "
                + LogicalPath.display path
                + ". Refresh the game context or use the manual layout."
            )

        match binding with
        | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
            let evidence = binding.Evidence
            let names = Dictionary<FileIdentity, Map<string, string list>>()
            let key (value: string) = value.Normalize().ToUpperInvariant()

            let read (root: HeldDirectory) path =
                let rec at (directory: HeldDirectory) parts =
                    match parts with
                    | [] -> unknown path
                    | name :: tail ->
                        let lookup =
                            match names.TryGetValue directory.Identity with
                            | true, lookup -> lookup
                            | _ ->
                                let lookup =
                                    directory.Names
                                    |> Seq.groupBy key
                                    |> Seq.map (fun (name, values) -> name, List.ofSeq values)
                                    |> Map.ofSeq

                                names[directory.Identity] <- lookup
                                lookup

                        match lookup |> Map.tryFind (key name) with
                        | None -> Fact.Known FileState.Missing
                        | Some [ name ] ->
                            match directory.InspectEntry name, tail with
                            | Some entry, [] when entry.Kind = EntryKind.RegularFile ->
                                Fact.Known FileState.Active
                            | Some entry, _ :: _ when entry.Kind = EntryKind.Directory ->
                                use child = directory.Directory(name, Some entry.Identity)
                                at child tail
                            | _ -> unknown path
                        | Some _ -> unknown path

                try
                    at root (LogicalPath.components path)
                with
                | :? IOException
                | :? UnauthorizedAccessException -> unknown path

            try
                let host =
                    HostPath.create evidence.DataPath.Value
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid checked game path")

                use root = HeldDirectory.Open(host, evidence.DataIdentity.Value)
                paths |> List.map (fun path -> path, read root path) |> Map.ofList
            with
            | :? IOException
            | :? UnauthorizedAccessException ->
                paths |> List.map (fun path -> path, unknown path) |> Map.ofList
        | _ -> paths |> List.map (fun path -> path, unknown path) |> Map.ofList
