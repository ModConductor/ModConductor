namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Platform
open ModConductor.ModMaintenance

module internal DeletionFiles =
    let remove (effect: DeletionEffect) =
        use root = HeldDirectory.Open(effect.Root, effect.RootIdentity)

        let rec atParent (parent: HeldDirectory) (host: HostPath) parts =
            match parts with
            | [] -> invalidOp "A deletion effect requires a file."
            | [ name ] ->
                match parent.InspectEntry name with
                | None -> ()
                | Some entry when Some entry.Identity <> effect.Identity ->
                    raise (IOException("The stored entry was replaced: " + effect.Label))
                | Some entry when
                    effect.Kind = DeletionFileKind.GenerationLink && entry.Kind = EntryKind.Link
                    ->
                    GenerationStorage.allowDirectoryChanges host parent.Identity

                    try
                        GenerationStorage.allowLinkDeletion parent name entry

                        try
                            parent.RemoveLink(name, entry)
                        with error ->
                            if parent.InspectEntry name = Some entry then
                                GenerationStorage.protectLink parent name entry

                            reraise ()
                    finally
                        GenerationStorage.protectDirectory host parent.Identity
                | Some entry when
                    effect.Kind <> DeletionFileKind.GenerationLink
                    && entry.Kind = EntryKind.RegularFile
                    ->
                    parent.RemoveFile(name, entry.Identity)
                | Some _ ->
                    raise (IOException("The stored entry has a different type: " + effect.Label))
            | name :: tail ->
                use child = parent.Directory(name, None)

                let path =
                    HostPath.create (Path.Combine(HostPath.value host, name))
                    |> Result.defaultWith invalidOp

                atParent child path tail

        atParent root effect.Root (LogicalPath.components effect.Path)
