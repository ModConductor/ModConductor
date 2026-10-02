namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Unreal
open ModConductor.GameContexts
open ModConductor.ModSelection
open ModConductor.Platform

type UnrealStore
    internal (database: StateDatabase, access: LibraryAccess, selection: ModSelectionStore) =
    let scope workspace profile =
        database.Enqueue(fun () ->
            GameContextRows.read database.Connection null database.OwnerId workspace profile
            |> Result.mapError (fun _ -> "The profile installation is unavailable.")
            |> Result.bind (fun context ->
                match context.Binding with
                | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
                    let definition = GameCatalog.forGame binding.GameId

                    GameClient.unreal definition
                    |> Option.map (fun client -> Ok(context, definition, client))
                    |> Option.defaultValue (
                        Error "This game does not declare an Unreal mod workflow."
                    )
                | _ -> Error "Select and refresh the game installation first."))

    let files workspace action =
        task {
            let! result =
                access.Run(fun () ->
                    task {
                        let! root = access.Root workspace
                        return root |> Result.map action
                    })

            return
                result
                |> Result.mapError (fun _ -> "The owned loader files are unavailable.")
                |> Result.bind id
        }

    member _.Read(workspace, profile) =
        task {
            let! scoped = scope workspace profile

            match scoped with
            | Error detail -> return Error detail
            | Ok(context, definition, client) ->
                let! inventory =
                    database.Enqueue(fun () ->
                        match SelectionRows.profile database.Connection null profile with
                        | Some(owner, revision) when owner = workspace ->
                            let packages =
                                SelectionRows.all database.Connection null profile
                                |> List.choose (fun selected ->
                                    LibraryRows.find database.Connection null selected.Id
                                    |> Option.filter (fun row ->
                                        row.Entry.CurrentVersion.IsSome
                                        && LoaderSource.matches
                                            client.Loader
                                            row.Entry.Metadata.Source)
                                    |> Option.map (fun row ->
                                        selected, row.Entry.Metadata.Version))

                            Ok(
                                revision,
                                packages
                                |> List.sortByDescending (fun (item, _) ->
                                    item.Enabled = Some true, item.Priority)
                                |> List.tryHead
                            )
                        | _ -> Error "The profile selection is unavailable.")

                match inventory with
                | Error detail -> return Error detail
                | Ok(revision, current) ->
                    return!
                        files workspace (fun root ->
                            let settings, directory = WorkingPaths.settings definition client
                            let log = WorkingPaths.log definition client

                            let logId, directoryLog =
                                match client.Loader.Mechanism with
                                | UnrealModMechanism.CookedPlugins _ ->
                                    WorkingPaths.id client.Loader client.LogDirectory, true
                                | UnrealModMechanism.UE4SS _ ->
                                    WorkingPaths.id client.Loader log, false

                            Ok
                                { Workspace = workspace
                                  Profile = profile
                                  ContextRevision = context.Revision
                                  SelectionRevision = revision
                                  GameSha256 =
                                    context.Binding.Value.Evidence.Executable.Value.Sha256
                                  Declaration = client.Loader
                                  Mod = current |> Option.map (fst >> _.Id)
                                  Version =
                                    current
                                    |> Option.map snd
                                    |> Option.defaultValue client.Loader.Version
                                  Enabled =
                                    current
                                    |> Option.exists (fun (item, _) -> item.Enabled = Some true)
                                  SettingsAvailable =
                                    LoaderWorkingStorage.available
                                        root
                                        profile
                                        (WorkingPaths.id client.Loader settings)
                                        directory
                                  LogAvailable =
                                    LoaderWorkingStorage.available root profile logId directoryLog })
        }

    member this.Change(workspace, profile, contextRevision, selectionRevision, enabled) =
        task {
            let! result = this.Read(workspace, profile)

            match result with
            | Error detail -> return Error detail
            | Ok state when
                state.ContextRevision <> contextRevision
                || state.SelectionRevision <> selectionRevision
                ->
                return Error "The profile or installation changed. Read its loader selection again."
            | Ok state when state.Mod.IsNone ->
                return Error "Acquire the declared loader archive first."
            | Ok state ->
                let! mods =
                    database.Enqueue(fun () ->
                        SelectionRows.all database.Connection null profile
                        |> List.filter (fun item ->
                            LibraryRows.find database.Connection null item.Id
                            |> Option.exists (fun row ->
                                LoaderSource.matches state.Declaration row.Entry.Metadata.Source))
                        |> List.map _.Id)

                let! changed =
                    if enabled then
                        selection.SelectOne(profile, selectionRevision, mods, state.Mod.Value)
                    else
                        (selection :> IModSelection)
                            .Change(profile, selectionRevision, mods, SelectionEdit.Enable false)

                match changed with
                | Error _ ->
                    return
                        Error
                            "The loader selection changed before the request completed. Read it again."
                | Ok _ -> return! this.Read(workspace, profile)
        }

    member this.Select(workspace, profile, contextRevision, modId) =
        task {
            let! result = this.Read(workspace, profile)

            match result with
            | Error detail -> return Error detail
            | Ok state when state.ContextRevision <> contextRevision ->
                return
                    Error
                        "The loader is in the library. The game installation changed before enablement."
            | Ok state ->
                let! mods =
                    database.Enqueue(fun () ->
                        SelectionRows.all database.Connection null profile
                        |> List.filter (fun item ->
                            LibraryRows.find database.Connection null item.Id
                            |> Option.exists (fun row ->
                                LoaderSource.matches state.Declaration row.Entry.Metadata.Source))
                        |> List.map _.Id)

                let! changed = selection.SelectOne(profile, state.SelectionRevision, mods, modId)

                match changed with
                | Error _ ->
                    return
                        Error
                            "The loader selection changed before enablement. The package remains in Mods."
                | Ok _ -> return! this.Read(workspace, profile)
        }

    member _.SettingsFiles(workspace, profile) =
        task {
            let! scoped = scope workspace profile

            match scoped with
            | Error detail -> return Error detail
            | Ok(_, definition, client) ->
                let relative, directory = WorkingPaths.settings definition client

                return!
                    files workspace (fun root ->
                        LoaderWorkingStorage.within
                            root
                            profile
                            (WorkingPaths.id client.Loader relative)
                            directory
                            (fun held direct ->
                                match direct with
                                | Some name ->
                                    Ok(
                                        if
                                            held.InspectEntry name
                                            |> Option.exists (fun entry ->
                                                entry.Kind = EntryKind.RegularFile)
                                        then
                                            [ Path.GetFileName relative ]
                                        else
                                            []
                                    )
                                | None ->
                                    Ok(
                                        held.Names
                                        |> Seq.filter (fun name ->
                                            held.InspectEntry name
                                            |> Option.exists (fun entry ->
                                                entry.Kind = EntryKind.RegularFile))
                                        |> Seq.sort
                                        |> Seq.toList
                                    )))
        }

    member _.Text(workspace, profile, name, edit: (byte array * string) option, log) =
        task {
            let! scoped = scope workspace profile

            match scoped with
            | Error detail -> return Error detail
            | Ok(context, definition, client) ->
                let relative, directory =
                    if log then
                        match client.Loader.Mechanism with
                        | UnrealModMechanism.CookedPlugins _ -> client.LogDirectory, true
                        | UnrealModMechanism.UE4SS _ -> WorkingPaths.log definition client, false
                    else
                        WorkingPaths.settings definition client

                match
                    edit
                    |> Option.map (fun _ ->
                        ModConductor.Deployment.GameProcesses.validate context |> Result.map ignore)
                    |> Option.defaultValue (Ok())
                with
                | Error detail -> return Error detail
                | Ok _ ->
                    return!
                        files workspace (fun root ->
                            LoaderWorkingStorage.within
                                root
                                profile
                                (WorkingPaths.id client.Loader relative)
                                directory
                                (fun held direct ->
                                    let selected =
                                        direct
                                        |> Option.defaultValue (if log then "game.log" else name)

                                    if
                                        selected = ""
                                        || Path.GetFileName(selected) <> selected
                                        || selected = "."
                                        || selected = ".."
                                    then
                                        Error "Select one loader settings file."
                                    else
                                        match edit with
                                        | None ->
                                            LoaderWorkingStorage.read held selected
                                            |> Result.map fst
                                        | Some(original, content) ->
                                            LoaderWorkingStorage.save
                                                held
                                                selected
                                                original
                                                content
                                            |> Result.bind (fun () ->
                                                LoaderWorkingStorage.read held selected
                                                |> Result.map fst)))
        }

    interface ILoaderSelection with
        member this.Read(workspace, profile) = this.Read(workspace, profile)
