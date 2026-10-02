namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.BepInEx
open ModConductor.GameContexts
open ModConductor.Thunderstore
open ModConductor.ModSelection

/// Derives the loader selection from the existing package provenance and profile selections.
type BepInExStore
    internal (database: StateDatabase, access: LibraryAccess, selection: ModSelectionStore) =
    let scope workspace profile =
        database.Enqueue(fun () ->
            GameContextRows.read database.Connection null database.OwnerId workspace profile
            |> Result.mapError (fun _ -> "The profile installation is unavailable.")
            |> Result.bind (fun state ->
                match state.Binding with
                | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
                    GameClient.unity
                        (binding.Evidence.Platform = ContextPlatform.NativeLinux)
                        (GameCatalog.forGame binding.GameId)
                    |> Option.map (fun client -> Ok(state, client))
                    |> Option.defaultValue (Error "This game does not declare a Unity loader.")
                | _ -> Error "Select and refresh the game installation first."))

    let role client source version =
        use query =
            Sqlite.command
                database.Connection
                null
                "SELECT path FROM mod_manifest WHERE version_id=$version"
                [ "$version", box (string version) ]

        use reader = query.ExecuteReader()

        let paths =
            seq {
                while reader.Read() do
                    yield LibraryEncoding.readPath (reader.GetString 0)
            }

        LoaderPackage.role client source paths

    let packages profile client =
        SelectionRows.all database.Connection null profile
        |> List.choose (fun item ->
            LibraryRows.find database.Connection null item.Id
            |> Option.bind (fun row ->
                row.Entry.CurrentVersion
                |> Option.bind (fun id ->
                    match role client row.Entry.Metadata.Source id with
                    | PackageRole.Loader _ ->
                        Some(item, VersionReference.tryDecode row.Entry.Metadata.Source)
                    | PackageRole.Plugin -> None)))

    let inventory workspace profile client =
        database.Enqueue(fun () ->
            match SelectionRows.profile database.Connection null profile with
            | Some(owner, revision) when owner = workspace ->
                let reference = LoaderPackage.reference client

                let current =
                    packages profile client
                    |> List.sortByDescending (fun (item, package) ->
                        item.Enabled = Some true, item.Priority, package = reference)
                    |> List.tryHead

                Ok(revision, reference, current)
            | _ -> Error "The profile selection is unavailable.")

    let files workspace action =
        task {
            let! result =
                access.Run(fun () ->
                    task {
                        let! root = access.Root workspace
                        return root |> Result.map (fun root -> action root)
                    })

            return
                result
                |> Result.mapError (fun _ -> "The owned workspace folder is unavailable.")
                |> Result.bind id
        }

    let read workspace profile =
        task {
            let! checkedScope = scope workspace profile

            match checkedScope with
            | Error detail -> return Error detail
            | Ok(context, client) ->
                let! installed = inventory workspace profile client

                match installed with
                | Error detail -> return Error detail
                | Ok(revision, reference, current) ->
                    return!
                        files workspace (fun root ->
                            let state =
                                { Workspace = workspace
                                  Profile = profile
                                  ContextRevision = context.Revision
                                  SelectionRevision = revision
                                  GameSha256 =
                                    context.Binding.Value.Evidence.Executable.Value.Sha256
                                  Package =
                                    match current with
                                    | Some(_, package) -> package
                                    | None -> reference
                                  Mod = current |> Option.map (fst >> _.Id)
                                  Enabled =
                                    current
                                    |> Option.exists (fun (item, _) -> item.Enabled = Some true)
                                  SettingsAvailable =
                                    BepInExWorkingStorage.available
                                        root
                                        profile
                                        WorkingPaths.config
                                        true
                                  LogAvailable =
                                    BepInExWorkingStorage.available
                                        root
                                        profile
                                        WorkingPaths.log
                                        false }

                            Ok(state, client))
        }

    member _.Read(workspace, profile) =
        task {
            let! result = read workspace profile
            return result |> Result.map fst
        }

    member this.Change(workspace, profile, contextRevision, selectionRevision, enabled) =
        task {
            let! current = read workspace profile

            match current with
            | Error detail -> return Error detail
            | Ok(current, _) when
                current.ContextRevision <> contextRevision
                || current.SelectionRevision <> selectionRevision
                ->
                return Error "The profile or installation changed. Read its loader selection again."
            | Ok(current, _) when current.Mod.IsNone ->
                return
                    Error
                        "Install a compatible loader archive or acquire the declared package first."
            | Ok(current, client) ->
                let! mods =
                    database.Enqueue(fun () ->
                        if enabled then
                            [ current.Mod.Value ]
                        else
                            packages profile client |> List.map (fst >> _.Id))

                let! changed =
                    (selection :> IModSelection)
                        .Change(profile, selectionRevision, mods, SelectionEdit.Enable enabled)

                match changed with
                | Error _ ->
                    return
                        Error
                            "The loader selection changed before the request completed. Read it again."
                | Ok _ -> return! this.Read(workspace, profile)
        }

    member _.ReadSettings(workspace, profile) =
        task {
            let! checkedScope = scope workspace profile

            match checkedScope with
            | Error detail -> return Error detail
            | Ok _ ->
                return! files workspace (fun root -> BepInExWorkingStorage.readConfig root profile)
        }

    member _.SaveSettings(workspace, profile, original, content) =
        task {
            let! checkedScope = scope workspace profile

            match checkedScope with
            | Error detail -> return Error detail
            | Ok(context, _) ->
                match ModConductor.Deployment.GameProcesses.validate context with
                | Error detail -> return Error detail
                | Ok _ ->
                    return!
                        files workspace (fun root ->
                            BepInExWorkingStorage.saveConfig root profile original content)
        }

    member _.ReadLog(workspace, profile) =
        task {
            let! checkedScope = scope workspace profile

            match checkedScope with
            | Error detail -> return Error detail
            | Ok _ ->
                return! files workspace (fun root -> BepInExWorkingStorage.readLog root profile)
        }

    interface ILoaderSelection with
        member this.Read(workspace, profile) = this.Read(workspace, profile)
