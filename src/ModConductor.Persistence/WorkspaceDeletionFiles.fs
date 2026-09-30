namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Platform
open ModConductor.ProfileGameData
open ModConductor.DeploymentGenerations
open ModConductor.DeploymentRecovery

module internal WorkspaceDeletionFiles =
    let private directoryExists (path: string) =
        try
            (File.GetAttributes path).HasFlag FileAttributes.Directory
        with
        | :? FileNotFoundException
        | :? DirectoryNotFoundException -> false

    let rec private clear (directory: HeldDirectory) =
        for name in directory.Names |> Seq.toList do
            match directory.InspectEntry name with
            | None -> ()
            | Some entry when entry.Kind = EntryKind.Directory ->
                let identity =
                    use child = directory.Directory(name, Some entry.Identity)
                    clear child
                    child.Identity

                directory.RemoveDirectory(name, identity)
            | Some entry when entry.Kind = EntryKind.RegularFile ->
                directory.RemoveFile(name, entry.Identity)
            | Some entry when entry.Kind = EntryKind.Link -> directory.RemoveLink(name, entry)
            | Some _ -> raise (IOException "An owned workspace folder has an unsupported entry.")

    let private removeChild (parent: HeldDirectory) name identity =
        match parent.InspectEntry name with
        | None -> ()
        | Some entry when entry.Kind = EntryKind.Directory && entry.Identity = identity ->
            use child = parent.Directory(name, Some identity)
            clear child
            parent.RemoveDirectory(name, identity)
        | Some _ -> raise (IOException "An owned workspace folder changed. It was left untouched.")

    let private removeRoot (root: DataRoot) =
        let path = HostPath.value root.Path

        if directoryExists path then
            let parent =
                DataLocations.root (Path.GetDirectoryName path)
                |> Result.defaultWith (fun _ ->
                    raise (IOException "The owned folder's parent is unavailable."))

            use held = HeldDirectory.Open(parent.Path, parent.Identity)
            removeChild held (Path.GetFileName path) root.Identity

    let private removeSecondary (root: WorkspaceRoot) (generation: Generation) =
        let rec clearProtected (location: Location) =
            GenerationStorage.allowDirectoryChanges location.Path location.Identity
            use held = HeldDirectory.Open(location.Path, location.Identity)

            for name in held.Names |> Seq.toList do
                match held.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.Directory ->
                    clearProtected
                        { Path =
                            HostPath.create (Path.Combine(HostPath.value location.Path, name))
                            |> Result.defaultWith invalidOp
                          Identity = entry.Identity }

                    held.RemoveDirectory(name, entry.Identity)
                | Some entry when entry.Kind = EntryKind.RegularFile ->
                    held.RemoveFile(name, entry.Identity)
                | Some entry when entry.Kind = EntryKind.Link ->
                    GenerationStorage.allowLinkDeletion held name entry
                    held.RemoveLink(name, entry)
                | None -> ()
                | Some _ ->
                    raise (IOException "A secondary generation folder has an unsupported entry.")

        if directoryExists (HostPath.value root.Path) then
            use held = HeldDirectory.Open(root.Path, root.Identity)
            let name = ".mc-secondary-" + generation.Id.ToString "N"

            match held.InspectEntry name with
            | None -> ()
            | Some entry when entry.Kind = EntryKind.Directory ->
                clearProtected
                    { Path =
                        HostPath.create (Path.Combine(HostPath.value root.Path, name))
                        |> Result.defaultWith invalidOp
                      Identity = entry.Identity }

                held.RemoveDirectory(name, entry.Identity)
            | Some _ -> raise (IOException "The secondary generation folder changed.")

    let validate (state: WorkspaceDeletionState) =
        let root = state.Receipt.Workspace

        if directoryExists (HostPath.value root.Path) then
            use held = HeldDirectory.Open(root.Path, root.Identity)

            match held.InspectEntry RootIdentityFile.name with
            | Some entry when Some entry.Identity <> state.Receipt.MarkerIdentity ->
                raise (IOException "The workspace identity file changed. It was left untouched.")
            | _ -> ()

    let remove (state: WorkspaceDeletionState) imageFolder =
        for _, generation in state.Deployments |> List.distinctBy (snd >> _.Id) do
            GenerationFiles.removeOwned generation
            removeSecondary state.Receipt.Workspace generation

        for context, _ in state.Data do
            context.PluginOriginals |> Option.iter removeRoot
            context.OriginalsRoot |> Option.iter removeRoot
            context.Storage |> Option.iter removeRoot

        let root = state.Receipt.Workspace

        if directoryExists (HostPath.value root.Path) then
            use held = HeldDirectory.Open(root.Path, root.Identity)

            for name, identity in state.Folders do
                removeChild held name identity

            let location: Location =
                { Path = root.Path
                  Identity = root.Identity }

            for profile in state.Profiles do
                GameViews.removeOwned location profile

            match held.InspectEntry ".mc-component-working" with
            | Some entry when entry.Kind = EntryKind.Directory ->
                use working = held.Directory(".mc-component-working", Some entry.Identity)

                for profile in state.Profiles do
                    let name = profile.ToString "N"

                    match working.InspectEntry name with
                    | Some child when child.Kind = EntryKind.Directory ->
                        removeChild working name child.Identity
                    | None -> ()
                    | Some _ -> raise (IOException "The component working folder changed.")

                if working.Names |> Seq.isEmpty then
                    held.RemoveDirectory(".mc-component-working", entry.Identity)
            | None -> ()
            | Some _ -> raise (IOException "The component working folder changed.")

        if directoryExists imageFolder then
            DataLocations.root imageFolder
            |> Result.defaultWith (fun _ ->
                raise (IOException "The profile image folder is unavailable."))
            |> removeRoot

    let finishRoot (state: WorkspaceDeletionState) =
        let root = state.Receipt.Workspace
        let path = HostPath.value root.Path

        if directoryExists path then
            let empty =
                use held = HeldDirectory.Open(root.Path, root.Identity)

                match held.InspectEntry RootIdentityFile.name with
                | None -> ()
                | Some entry when Some entry.Identity = state.Receipt.MarkerIdentity ->
                    held.RemoveFile(RootIdentityFile.name, entry.Identity)
                | Some _ ->
                    raise (
                        IOException "The workspace identity file changed. It was left untouched."
                    )

                held.Names |> Seq.isEmpty

            if empty then
                let parent =
                    DataLocations.root (Path.GetDirectoryName path)
                    |> Result.defaultWith (fun _ ->
                        raise (IOException "The workspace parent is unavailable."))

                use held = HeldDirectory.Open(parent.Path, parent.Identity)
                held.RemoveDirectory(Path.GetFileName path, root.Identity)
