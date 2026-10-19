namespace ModConductor.DeploymentRecovery

open System.IO
open ModConductor.Platform

// Refresh completed ownership evidence only when starting a new operation. Pending
// contexts and destructive receipts keep the identities captured by their operation.
module internal CompletedState =
    let location (value: Location) =
        use directory = HeldDirectory.Open value.Path

        { value with
            Identity = directory.Identity }

    let retiredGeneration (value: Generation) =
        if Directory.Exists(HostPath.value value.Directory.Path) then
            { value with
                Directory = location value.Directory }
        else
            value

    let context (value: Context) =
        if value.Pending.IsSome then
            value
        else
            let backups =
                value.Originals
                |> List.map (fun original ->
                    let root = RecoveryFiles.binding value original.Target
                    root.Originals.Path, original.Backup)

            if (backups |> List.distinct |> List.length) <> backups.Length then
                RecoveryFiles.fail "A recorded original location is not unique."

            let observed =
                { value with
                    Roots =
                        value.Roots
                        |> List.map (fun root ->
                            { root with
                                Directory = location root.Directory
                                Originals = location root.Originals }) }

            { observed with
                Originals =
                    value.Originals
                    |> List.map (fun original ->
                        let root = RecoveryFiles.binding observed original.Target

                        use backup =
                            HeldDirectory.Open(root.Originals.Path, root.Originals.Identity)

                        let current =
                            match backup.InspectEntry original.Backup with
                            | Some entry -> Some entry
                            | None ->
                                let covered =
                                    observed.Links
                                    |> List.exists (fun link ->
                                        let parent = LogicalPath.components link.Target.Path
                                        let child = LogicalPath.components original.Target.Path
                                        link.Target.Root = original.Target.Root
                                        && List.truncate parent.Length child = parent)

                                if covered then
                                    None
                                else
                                    RecoveryFiles.observe observed original.Target

                        match current with
                        | Some entry when
                            entry.Kind = original.Entry.Kind
                            && (entry.Kind = EntryKind.RegularFile
                                || entry.Kind = EntryKind.Directory)
                            ->
                            { original with Entry = entry }
                        | _ ->
                            RecoveryFiles.fail
                                "The recorded original is missing or has an unsupported kind.")
                Links =
                    value.Links
                    |> List.map (fun link ->
                        match RecoveryFiles.observe observed link.Target with
                        | Some entry when RecoveryFiles.linkMatches link.Spec entry ->
                            { link with Entry = entry }
                        | _ -> RecoveryFiles.fail "An active deployment link changed.")
                Directories =
                    value.Directories
                    |> List.map (fun directory ->
                        match RecoveryFiles.observe observed directory.Target with
                        | Some entry when entry.Kind = EntryKind.Directory ->
                            { directory with
                                Identity = entry.Identity }
                        | _ -> RecoveryFiles.fail "An owned deployment directory changed.") }

    let generation (context: Context) (value: Generation) =
        let directory = location value.Directory

        let metadata root path length =
            RecoveryFiles.withParent root path (fun parent name ->
                let observed = parent.InspectFile(name, None)

                if observed.Length <> length then
                    RecoveryFiles.fail "A saved generation file changed."

                observed.Identity)

        let files =
            value.Files
            |> List.map (fun file ->
                match file.Backing with
                | None ->
                    { file with
                        Identity = metadata directory file.Path file.Length }
                | Some stored ->
                    let backing =
                        { stored with
                            Directory = location stored.Directory }

                    let identity = metadata backing.Directory backing.Path file.Length

                    let entry =
                        RecoveryFiles.withParent directory file.Path (fun parent name ->
                            match parent.InspectEntry name with
                            | Some entry when
                                RecoveryFiles.linkMatches
                                    { Generation = value.Id
                                      Target = RecoveryFiles.path backing.Directory backing.Path
                                      Directory = false }
                                    entry
                                ->
                                entry
                            | _ -> RecoveryFiles.fail "A saved generation link changed.")

                    { file with
                        Identity = entry.Identity
                        Backing = Some { backing with Identity = identity } })

        { value with
            Directory = directory
            Files = files
            Observed =
                value.Observed
                |> List.map (fun observed ->
                    let target = RecoveryFiles.nativeTarget value observed.Target
                    let root = RecoveryFiles.binding context target

                    let check (parent: HeldDirectory) name =
                        let current = parent.InspectFile(name, None)

                        if
                            current.Length <> observed.Length
                            || observed.Modified |> Option.exists ((<>) current.Modified)
                        then
                            RecoveryFiles.fail "An observed game file changed."

                        { observed with Identity = current.Identity }

                    match
                        context.Originals
                        |> List.tryFind (fun original -> original.Target = target)
                    with
                    | Some original ->
                        use originals =
                            HeldDirectory.Open(root.Originals.Path, root.Originals.Identity)

                        match originals.InspectEntry original.Backup with
                        | Some _ -> check originals original.Backup
                        | None -> RecoveryFiles.withParent root.Directory target.Path check
                    | None -> RecoveryFiles.withParent root.Directory target.Path check)
            Working =
                value.Working
                |> List.map (fun working ->
                    let root = location working.Root

                    let identity =
                        RecoveryFiles.withParent root working.Path (fun parent name ->
                            match parent.InspectEntry name with
                            | Some entry when
                                working.Directory && entry.Kind = EntryKind.Directory
                                ->
                                Some entry.Identity
                            | Some entry when
                                not working.Directory && entry.Kind = EntryKind.RegularFile
                                ->
                                Some entry.Identity
                            | None when not working.Directory -> None
                            | _ -> RecoveryFiles.fail "A saved working location changed.")

                    { working with
                        Root = root
                        Identity = identity }) }
