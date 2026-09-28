namespace ModConductor.DeploymentGenerations

open System
open System.IO
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

module internal GenerationRetirement =
    let protect (root: Location) =
        let rec walk (location: Location) =
            use held = HeldDirectory.Open(location.Path, location.Identity)

            for name in held.Names do
                match held.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.Directory ->
                    walk
                        { Path =
                            HostPath.create (Path.Combine(HostPath.value location.Path, name))
                            |> Result.defaultWith (fun _ -> invalidOp "Invalid child.")
                          Identity = entry.Identity }
                | Some entry when entry.Kind = EntryKind.Link ->
                    GenerationStorage.protectLink held name entry
                | _ -> ()

            GenerationStorage.protectDirectory location.Path location.Identity

        walk root

    /// Removes a retired generation's derived link tree, never following payload links.
    let removeOwned (generation: Generation) =
        let path = HostPath.value generation.Directory.Path
        let name = generation.Id.ToString("N")

        let outer, nested =
            if Path.GetFileName path = name then
                Path.GetDirectoryName path, true
            else
                path, false

        let workspace = Path.GetDirectoryName outer

        if
            Path.GetFileName outer <> ".mc-generation-" + name
            || String.IsNullOrWhiteSpace workspace
        then
            raise (IOException "The derived generation folder has an invalid location.")

        let openCanonical path =
            let host = HostPath.create path |> Result.defaultWith invalidOp

            let selected =
                RootSelection.select host
                |> Result.defaultWith (fun _ ->
                    raise (IOException "The derived generation parent is unavailable."))

            let identity =
                match (RootSelection.facts selected).File with
                | Known value -> value
                | Unknown detail -> raise (IOException detail)

            HeldDirectory.Open(host, identity)

        let rec remove (location: Location) =
            GenerationStorage.allowDirectoryChanges location.Path location.Identity
            use held = HeldDirectory.Open(location.Path, location.Identity)

            for name in held.Names |> Seq.toList do
                match held.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.Directory ->
                    let child =
                        { Path =
                            HostPath.create (Path.Combine(HostPath.value location.Path, name))
                            |> Result.defaultWith invalidOp
                          Identity = entry.Identity }

                    remove child
                    held.RemoveDirectory(name, entry.Identity)
                | Some entry when entry.Kind = EntryKind.Link ->
                    GenerationStorage.allowLinkDeletion held name entry
                    held.RemoveLink(name, entry)
                | Some entry when entry.Kind = EntryKind.RegularFile ->
                    held.RemoveFile(name, entry.Identity)
                | Some _ -> raise (IOException "The derived generation has an unsupported entry.")
                | None -> raise (IOException "The derived generation changed.")

        if Directory.Exists outer && nested then
            let identity, empty =
                use parent = openCanonical outer

                match parent.InspectEntry name with
                | None -> ()
                | Some entry when
                    entry.Kind = EntryKind.Directory
                    && entry.Identity = generation.Directory.Identity
                    ->
                    remove generation.Directory
                    parent.RemoveDirectory(name, entry.Identity)
                | Some _ -> raise (IOException "The derived generation changed.")

                parent.Identity, (parent.Names |> Seq.isEmpty)

            if empty then
                let outerName = Path.GetFileName outer
                use workspaceRoot = openCanonical workspace
                workspaceRoot.RemoveDirectory(outerName, identity)
        elif Directory.Exists outer then
            use workspaceRoot = openCanonical workspace

            match workspaceRoot.InspectEntry(Path.GetFileName outer) with
            | Some entry when
                entry.Kind = EntryKind.Directory
                && entry.Identity = generation.Directory.Identity
                ->
                remove generation.Directory
                workspaceRoot.RemoveDirectory(Path.GetFileName outer, entry.Identity)
            | _ -> raise (IOException "The derived generation changed.")
