namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.Platform

module internal FnisViewFiles =
    let private child (location: Location) name identity =
        { Path =
            HostPath.create (Path.Combine(HostPath.value location.Path, name))
            |> Result.defaultWith invalidOp
          Identity = identity }

    let private withParent protect created (location: Location) path action =
        let rec walk (location: Location) parts =
            use parent = HeldDirectory.Open(location.Path, location.Identity)

            if protect then
                GenerationStorage.allowDirectoryChanges location.Path location.Identity

            try
                match parts with
                | [ name ] -> action parent name
                | name :: rest ->
                    use next =
                        match parent.InspectEntry name with
                        | None ->
                            let next = parent.CreateDirectory name
                            created location name next.Identity
                            next
                        | Some entry when entry.Kind = EntryKind.Directory ->
                            parent.Directory(name, Some entry.Identity)
                        | Some _ -> RecoveryFiles.fail "An FNIS output parent is occupied."

                    walk (child location name next.Identity) rest
                | [] -> invalidOp "An FNIS output path is empty."
            finally
                if protect then
                    GenerationStorage.protectDirectory location.Path location.Identity

        walk location (LogicalPath.components path)

    let private removeDirectory protect (location: Location) name identity =
        use parent = HeldDirectory.Open(location.Path, location.Identity)

        if protect then
            GenerationStorage.allowDirectoryChanges location.Path location.Identity

        try
            parent.RemoveDirectory(name, identity)
        finally
            if protect then
                GenerationStorage.protectDirectory location.Path location.Identity

    let private replace
        (undo: ResizeArray<unit -> unit>)
        (complete: ResizeArray<unit -> unit>)
        protect
        location
        path
        expected
        target
        =
        let created location name identity =
            undo.Add(fun () -> removeDirectory protect location name identity)

        withParent protect created location path (fun parent name ->
            if parent.InspectEntry name <> expected then
                RecoveryFiles.fail "An FNIS output link changed."

            let backup = ".mc-fnis-" + Guid.NewGuid().ToString("N")

            expected
            |> Option.iter (fun entry ->
                GenerationStorage.allowLinkDeletion parent name entry
                parent.MoveOriginal(name, entry, parent, backup))

            let mutable installed = None

            undo.Add(fun () ->
                withParent protect (fun _ _ _ -> ()) location path (fun parent name ->
                    installed
                    |> Option.iter (fun entry ->
                        GenerationStorage.allowLinkDeletion parent name entry
                        parent.RemoveLink(name, entry))

                    expected
                    |> Option.iter (fun entry ->
                        parent.MoveOriginal(backup, entry, parent, name)

                        if protect then
                            GenerationStorage.protectLink parent name entry)))

            complete.Add(fun () ->
                withParent protect (fun _ _ _ -> ()) location path (fun parent _ ->
                    expected |> Option.iter (fun entry -> parent.RemoveLink(backup, entry))))

            installed <-
                target |> Option.map (fun target -> parent.CreateLink(name, target, false))

            if protect then
                installed |> Option.iter (GenerationStorage.protectLink parent name)

            installed)

    let private existing (generation: Generation) target =
        generation.Files |> List.tryFind (fun file -> file.Target = target)

    let private entry (generation: Generation) (file: GenerationFile option) =
        file
        |> Option.bind (fun file ->
            RecoveryFiles.withParent generation.Directory file.Path (fun parent name ->
                parent.InspectEntry name))

    let private covered (context: Context) (target: TargetFile) =
        context.Links
        |> List.exists (fun link ->
            let parent, path =
                LogicalPath.components link.Target.Path, LogicalPath.components target.Path

            link.Spec.Directory
            && link.Target.Root = target.Root
            && List.truncate parent.Length path = parent)

    let private applyChanges
        undo
        complete
        (context: Context)
        (generation: Generation)
        (changes: (TargetFile * SourcePin option * FileBacking option) list)
        =
        let mutable files = generation.Files
        let mutable links = context.Links

        for target, pin, backing in changes do
            let previous = existing generation target

            let path =
                previous
                |> Option.map _.Path
                |> Option.defaultWith (fun () ->
                    LogicalPath.create (
                        target.Root.ToString("N") :: LogicalPath.components target.Path
                    )
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid FNIS output path."))

            let before = entry generation previous

            if
                previous.IsSome
                && (before |> Option.map _.Identity) <> (previous |> Option.map _.Identity)
            then
                RecoveryFiles.fail "An FNIS output link changed."

            let destination =
                backing
                |> Option.map (fun source -> RecoveryFiles.path source.Directory source.Path)

            let installed =
                replace undo complete true generation.Directory path before destination

            files <- files |> List.filter (fun file -> file.Target <> target)

            match pin, backing, installed with
            | Some(SourcePin.Mod(_, _, manifest)), Some backing, Some installed ->
                files <-
                    { Target = target
                      Path = path
                      Identity = installed.Identity
                      Length = manifest.Payload.Length
                      Sha256 = Some manifest.Payload.Sha256
                      Backing = Some backing }
                    :: files
            | None, None, None -> ()
            | _ -> invalidOp "The FNIS output selection is inconsistent."

            let native = RecoveryFiles.nativeTarget generation target

            if not (covered context native) then
                let prior = links |> List.tryFind (fun link -> link.Target = native)
                let gameRoot = (RecoveryFiles.binding context native).Directory

                let targetPath =
                    destination
                    |> Option.map (fun _ -> RecoveryFiles.path generation.Directory path)

                let linked =
                    replace
                        undo
                        complete
                        false
                        gameRoot
                        native.Path
                        (prior |> Option.map _.Entry)
                        targetPath

                links <- links |> List.filter (fun link -> link.Target <> native)

                linked
                |> Option.iter (fun entry ->
                    links <-
                        { Target = native
                          Spec =
                            { Generation = generation.Id
                              Target = targetPath.Value
                              Directory = false }
                          Entry = entry }
                        :: links)

        files, links

    let apply context generation changes =
        let undo, complete = ResizeArray(), ResizeArray()

        let rollback () =
            undo |> Seq.rev |> Seq.iter (fun action -> action ())

        try
            let files, links = applyChanges undo complete context generation changes
            files, links, rollback, (fun () -> complete |> Seq.iter (fun action -> action ()))
        with _ ->
            rollback ()
            reraise ()
