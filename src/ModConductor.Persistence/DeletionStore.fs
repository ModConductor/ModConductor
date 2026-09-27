namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open Microsoft.Data.Sqlite
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.GeneratedOutputs
open ModConductor.ModLibrary
open ModConductor.Platform

module private DirectDeletion =
    let private row connection transaction workspace modId expected =
        match LibraryRows.find connection transaction modId with
        | None -> Error "The mod is no longer installed."
        | Some value when value.Entry.WorkspaceId <> workspace || value.Entry.Revision <> expected ->
            Error "The mod changed. Delete it again."
        | Some value when value.Entry.Kind <> ModKind.Regular ->
            Error "Choose a regular installed mod."
        | Some value -> Ok value

    let private ensureIdle connection transaction workspace targets =
        let members = Set.ofList targets

        let active =
            targets
            |> List.exists (fun target ->
                MaintenanceClaims.busy connection transaction target
                || Sqlite.number
                    connection
                    transaction
                    "SELECT count(*) FROM mod_versions WHERE mod_id=$mod AND busy=1"
                    [ "$mod", box (string target) ]
                   <> 0L)

        if active then
            Error "Finish the mod's current operation before deleting it."
        else
            let pending =
                DeletionRows.ids
                    connection
                    transaction
                    "SELECT id FROM output_actions WHERE workspace_id=$workspace AND complete=0"
                    [ "$workspace", box (string workspace) ]
                |> List.exists (fun actionId ->
                    let action =
                        OutputActionRows.find connection transaction actionId |> Option.get

                    match OutputActionRows.destination action with
                    | Some(OutputDestination.ExistingMod(id, _, _))
                    | Some(OutputDestination.NewMod(id, _, _)) -> members.Contains id
                    | _ -> false)

            if pending then
                Error "Finish the mod's pending output operation before deleting it."
            elif BundleDeletion.busy connection transaction workspace targets then
                Error "Finish the bundle operation before deleting this mod."
            else
                Ok()

    let private payloads connection transaction versions =
        let saved = Set.ofList versions

        let all =
            versions
            |> List.collect (fun version ->
                DeletionRows.ids
                    connection
                    transaction
                    "SELECT id FROM mod_payloads WHERE publication_id=$version UNION SELECT payload_id FROM mod_manifest WHERE version_id=$version"
                    [ "$version", box (string version) ])
            |> List.distinct

        let exclusive =
            all
            |> List.filter (fun id ->
                DeletionRows.ids
                    connection
                    transaction
                    "SELECT version_id FROM mod_manifest WHERE payload_id=$id"
                    [ "$id", box (string id) ]
                |> List.forall saved.Contains)

        all, exclusive

    let private installationPayloads connection transaction targets =
        targets
        |> List.collect (fun target ->
            DeletionRows.ids
                connection
                transaction
                "SELECT f.payload_id FROM installation_files f JOIN archive_installations i ON i.id=f.installation_id WHERE i.mod_id=$mod AND f.reused_payload IS NULL"
                [ "$mod", box (string target) ])
        |> List.distinct

    let private artifactIds connection transaction targets =
        targets
        |> List.collect (fun target ->
            DeletionRows.ids
                connection
                transaction
                "SELECT artifact_id FROM artifact_links WHERE mod_id=$mod UNION SELECT artifact_id FROM archive_installations WHERE mod_id=$mod UNION SELECT o.artifact_id FROM archive_version_origins o JOIN mod_versions v ON v.id=o.version_id WHERE v.mod_id=$mod"
                [ "$mod", box (string target) ])
        |> List.distinct

    let private artifacts connection transaction workspace targets =
        let members = Set.ofList targets

        let inspect id =
            use query =
                Sqlite.command
                    connection
                    transaction
                    "SELECT storage,busy FROM artifacts WHERE workspace_id=$workspace AND id=$id"
                    [ "$workspace", box (string workspace); "$id", box (string id) ]

            use reader = query.ExecuteReader()

            if not (reader.Read()) then
                Ok None
            else
                let storage, busy = reader.GetInt32 0, reader.GetBoolean 1
                reader.Close()

                let shared =
                    (DeletionRows.ids
                        connection
                        transaction
                        "SELECT mod_id FROM artifact_links WHERE artifact_id=$id"
                        [ "$id", box (string id) ]
                     |> List.exists (members.Contains >> not))
                    || (DeletionRows.ids
                            connection
                            transaction
                            "SELECT mod_id FROM archive_installations WHERE artifact_id=$id AND state IN (0,1)"
                            [ "$id", box (string id) ]
                        |> List.exists (members.Contains >> not))
                    || BundleDeletion.parentShared connection transaction id members

                if shared then
                    Ok None
                elif busy then
                    Error "An archive is in use. Finish its operation before deleting this mod."
                else
                    Ok(Some(id, storage))

        let rec collect values =
            function
            | [] -> Ok(List.rev values)
            | id :: remaining ->
                match inspect id with
                | Error error -> Error error
                | Ok None -> collect values remaining
                | Ok(Some value) -> collect (value :: values) remaining

        artifactIds connection transaction targets |> collect []

    let private generations connection transaction workspace targets =
        let members = Set.ofList targets

        let values =
            DeletionRows.generations connection transaction workspace
            |> List.filter (fun (_, generation) -> DeletionRows.includes members generation)

        let refusal =
            values
            |> List.tryPick (fun (context, generation) ->
                if context.Pending.IsSome then
                    Some "Finish the pending deployment before deleting this mod."
                elif
                    context.Active = Some generation.Id && DeletionRows.uses members generation
                then
                    Some "Deactivate game files before deleting this mod."
                else
                    None)

        match refusal with
        | Some error -> Error error
        | None -> Ok values

    let private libraryNames connection transaction workspace targets versions =
        let _, privatePayloads = payloads connection transaction versions

        let privateBundles =
            BundleDeletion.files connection transaction workspace targets
            |> List.choose (fun (source, shared) -> if shared then None else Some source.Id)

        artifacts connection transaction workspace targets
        |> Result.map (fun privateArtifacts ->
            let names =
                [ yield! privatePayloads |> List.map LibraryFiles.payloadName
                  yield!
                      installationPayloads connection transaction targets
                      |> List.map LibraryFiles.payloadName
                  yield! privateBundles |> List.map BundleFiles.name

                  for id, storage in privateArtifacts do
                      if storage = 1 then
                          yield ArtifactFiles.final id
                          yield ArtifactFiles.stage id ]
                |> List.distinct

            privatePayloads, privateArtifacts |> List.map fst, names)

    let private ownedPaths connection transaction workspace modId expected =
        row connection transaction workspace modId expected
        |> Result.bind (fun _ ->
            let targets = DeletionRows.targets connection transaction modId

            ensureIdle connection transaction workspace targets
            |> Result.bind (fun () ->
                let versions = DeletionRows.versions connection transaction targets

                libraryNames connection transaction workspace targets versions
                |> Result.bind (fun (privatePayloads, _, names) ->
                    let library = LibraryRows.library connection transaction workspace

                    match library with
                    | _ when names.IsEmpty -> Ok(privatePayloads, names, library, targets)
                    | Some stored when stored.Phase = 2 && stored.Identity.IsSome ->
                        Ok(privatePayloads, names, library, targets)
                    | _ -> Error "The owned mod library is unavailable.")))
        |> Result.bind (fun (privatePayloads, names, library, targets) ->
            match library with
            | Some stored when stored.Identity.IsSome ->
                generations connection transaction workspace targets
                |> Result.map (fun values ->
                    let privateNames =
                        privatePayloads |> List.map LibraryFiles.payloadName |> Set.ofList

                    let links =
                        [ for _, generation in values do
                              for file in generation.Files do
                                  if
                                      file.Backing
                                      |> Option.exists (fun backing ->
                                          backing.Directory.Identity = stored.Identity.Value
                                          && (match LogicalPath.components backing.Path with
                                              | [ name ] -> privateNames.Contains name
                                              | _ -> false))
                                  then
                                      yield generation.Directory, file.Path ]

                    library, names, links)
            | _ -> Ok(library, names, []))

    let readOwnedPaths (database: StateDatabase) workspace modId expected =
        database.Enqueue(fun () ->
            let connection = database.Connection
            use transaction = connection.BeginTransaction(deferred = true)
            let result = ownedPaths connection transaction workspace modId expected

            if Result.isOk result then
                transaction.Commit()

            result)

    let private unlink (directory: Location) path =
        if Directory.Exists(HostPath.value directory.Path) then
            try
                use root = HeldDirectory.Open(directory.Path, directory.Identity)

                let rec atParent (parent: HeldDirectory) (host: HostPath) parts =
                    match parts with
                    | [] -> invalidOp "An owned deployment link needs a file name."
                    | [ name ] ->
                        GenerationStorage.allowDirectoryChanges host parent.Identity

                        try
                            let unlocked = GenerationStorage.allowOwnedLinkDeletion parent name

                            try
                                parent.UnlinkOwned name
                            with _ ->
                                if unlocked then
                                    GenerationStorage.protectOwnedLink parent name |> ignore

                                reraise ()
                        finally
                            GenerationStorage.protectDirectory host parent.Identity
                    | name :: tail ->
                        use child = parent.Directory(name, None)

                        let childPath =
                            HostPath.create (Path.Combine(HostPath.value host, name))
                            |> Result.defaultWith invalidOp

                        atParent child childPath tail

                atParent root directory.Path (LogicalPath.components path)
            with :? FileNotFoundException ->
                ()

    let removeOwnedPaths
        (root: WorkspaceRoot option)
        (library: StoredLibrary option)
        (names: string list)
        (links: (Location * LogicalPath) list)
        checkpoint
        =
        checkpoint "before-deletion-files"

        match root, library with
        | Some root, Some stored when not names.IsEmpty ->
            try
                use workspace = HeldDirectory.Open(root.Path, root.Identity)
                use directory = workspace.Directory(stored.Name, stored.Identity)

                for name in names do
                    directory.UnlinkOwned name
            with :? FileNotFoundException ->
                ()
        | _ -> ()

        for directory, path in links do
            unlink directory path

    let private profiles connection transaction targets =
        targets
        |> List.collect (fun target ->
            DeletionRows.ids
                connection
                transaction
                "SELECT profile_id FROM profile_mods WHERE mod_id=$mod ORDER BY profile_id"
                [ "$mod", box (string target) ])
        |> List.distinct

    let private finishApproved
        (connection: SqliteConnection)
        transaction
        workspace
        targets
        versions
        allPayloads
        privatePayloads
        privateArtifacts
        affectedGenerations
        =
        let members, saved = Set.ofList targets, Set.ofList versions

        for payload in allPayloads do
            match
                DeletionRows.ids
                    connection
                    transaction
                    "SELECT version_id FROM mod_manifest WHERE payload_id=$id ORDER BY version_id"
                    [ "$id", box (string payload) ]
                |> List.filter (saved.Contains >> not)
            with
            | first :: _ ->
                Sqlite.execute
                    connection
                    transaction
                    "UPDATE mod_payloads SET publication_id=$version WHERE id=$id"
                    [ "$version", box (string first); "$id", box (string payload) ]
            | [] -> ()

        for profile in profiles connection transaction targets do
            let remaining =
                SelectionRows.all connection transaction profile
                |> List.filter (fun entry -> not (members.Contains entry.Id))
                |> List.mapi (fun index entry -> { entry with Priority = index })

            for target in targets do
                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM profile_mods WHERE profile_id=$profile AND mod_id=$mod"
                    [ "$profile", box (string profile); "$mod", box (string target) ]

            SelectionRows.apply connection transaction profile remaining

        let privateNames =
            privatePayloads |> List.map LibraryFiles.payloadName |> Set.ofList

        let library = LibraryRows.library connection transaction workspace

        for context, generation in affectedGenerations do
            let files =
                generation.Files
                |> List.filter (fun file ->
                    not (
                        file.Backing
                        |> Option.exists (fun backing ->
                            (library
                             |> Option.exists (fun stored ->
                                 stored.Identity = Some backing.Directory.Identity))
                            && (match LogicalPath.components backing.Path with
                                | [ name ] -> privateNames.Contains name
                                | _ -> false))
                    ))

            let references =
                generation.References
                |> List.filter (function
                    | SourcePin.Mod(id, _, _) -> not (members.Contains id)
                    | _ -> true)

            let provenance =
                generation.Provenance
                |> Option.map (fun value ->
                    let profile =
                        value.Profile
                        |> Option.map (fun profile ->
                            { profile with
                                Mods =
                                    profile.Mods
                                    |> List.filter (fun entry ->
                                        not (members.Contains entry.ModId))
                                Hidden =
                                    profile.Hidden
                                    |> Set.filter (fun file -> not (members.Contains file.ModId)) })

                    { value with Profile = profile })

            let oldTargets = generation.Files |> List.map _.Target |> Set.ofList
            let retainedTargets = files |> List.map _.Target |> Set.ofList

            let changed =
                { generation with
                    Files = files
                    References = references
                    Provenance = provenance
                    NativeTargets =
                        generation.NativeTargets
                        |> Map.filter (fun target _ ->
                            not (oldTargets.Contains target) || retainedTargets.Contains target)
                    PlanFingerprint = "" }

            let body = DeploymentEncoding.generationBytes changed

            Sqlite.execute
                connection
                transaction
                "UPDATE deployment_generations SET body=$body,digest=$digest,unavailable='Unavailable after mod deletion' WHERE context_id=$context AND id=$generation"
                [ "$body", box body
                  "$digest", box (DeploymentEncoding.hash body)
                  "$context", box (string context.Id)
                  "$generation", box (string generation.Id) ]

            Sqlite.execute
                connection
                transaction
                "DELETE FROM deployment_receipts WHERE context_id=$context AND phase IN (2,3) AND (proposed_id=$generation OR previous_id=$generation)"
                [ "$context", box (string context.Id)
                  "$generation", box (string generation.Id) ]

        BundleDeletion.complete connection transaction workspace targets

        for actionId in
            DeletionRows.ids
                connection
                transaction
                "SELECT id FROM output_actions WHERE workspace_id=$workspace AND complete=1"
                [ "$workspace", box (string workspace) ] do
            let action = OutputActionRows.find connection transaction actionId |> Option.get

            match OutputActionRows.destination action with
            | Some(OutputDestination.ExistingMod(id, _, _))
            | Some(OutputDestination.NewMod(id, _, _)) when members.Contains id ->
                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM output_actions WHERE id=$id"
                    [ "$id", box (string actionId) ]
            | _ -> ()

        for target in targets do
            let args = [ "$mod", box (string target) ]

            Sqlite.execute
                connection
                transaction
                "DELETE FROM skse_loader_selections WHERE mod_id=$mod; DELETE FROM skse_replacement_intents WHERE mod_id=$mod OR previous_mod_id=$mod; DELETE FROM artifact_links WHERE mod_id=$mod; DELETE FROM mod_categories WHERE mod_id=$mod; DELETE FROM hidden_mod_files WHERE mod_id=$mod; DELETE FROM file_visibility_changes WHERE mod_id=$mod; DELETE FROM profile_mods WHERE mod_id=$mod; UPDATE mods SET current_version=NULL WHERE id=$mod"
                args

            for installation in
                DeletionRows.ids
                    connection
                    transaction
                    "SELECT id FROM archive_installations WHERE mod_id=$mod"
                    args do
                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM installation_files WHERE installation_id=$id; DELETE FROM installation_reuse WHERE installation_id=$id; DELETE FROM archive_installations WHERE id=$id"
                    [ "$id", box (string installation) ]

        for version in versions do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM bundle_version_origins WHERE version_id=$version; DELETE FROM archive_version_origins WHERE version_id=$version; DELETE FROM mod_version_origins WHERE version_id=$version; UPDATE mod_version_origins SET source_version=NULL WHERE source_version=$version; DELETE FROM mod_manifest WHERE version_id=$version"
                [ "$version", box (string version) ]

        for payload in privatePayloads do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM mod_payloads WHERE id=$id"
                [ "$id", box (string payload) ]

        for version in versions do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM mod_versions WHERE id=$id"
                [ "$id", box (string version) ]

        for target in targets do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM mods WHERE id=$id"
                [ "$id", box (string target) ]

        for artifact in privateArtifacts do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM artifacts WHERE id=$id"
                [ "$id", box (string artifact) ]

        Sqlite.execute
            connection
            transaction
            "UPDATE profiles SET selection_revision=selection_revision+1 WHERE workspace_id=$workspace; UPDATE file_visibility_state SET revision=revision+1 WHERE workspace_id=$workspace"
            [ "$workspace", box (string workspace) ]

        transaction.Commit()

    let finish (connection: SqliteConnection) workspace modId expected =
        use transaction = connection.BeginTransaction(deferred = false)

        let admission =
            row connection transaction workspace modId expected
            |> Result.bind (fun _ ->
                let targets = DeletionRows.targets connection transaction modId

                ensureIdle connection transaction workspace targets
                |> Result.bind (fun () ->
                    let versions = DeletionRows.versions connection transaction targets
                    let allPayloads, privatePayloads = payloads connection transaction versions

                    artifacts connection transaction workspace targets
                    |> Result.bind (fun privateArtifacts ->
                        generations connection transaction workspace targets
                        |> Result.map (fun affectedGenerations ->
                            targets,
                            versions,
                            allPayloads,
                            privatePayloads,
                            privateArtifacts |> List.map fst,
                            affectedGenerations))))

        admission
        |> Result.map
            (fun
                (targets,
                 versions,
                 allPayloads,
                 privatePayloads,
                 privateArtifacts,
                 affectedGenerations) ->
                finishApproved
                    connection
                    transaction
                    workspace
                    targets
                    versions
                    allPayloads
                    privatePayloads
                    privateArtifacts
                    affectedGenerations)


type DeletionStore internal (database: StateDatabase, access: LibraryAccess) =
    let run action =
        task {
            let! guarded =
                access.Run(fun () ->
                    task {
                        let! outcome = action ()
                        return Ok outcome
                    })

            return
                guarded
                |> Result.mapError (fun _ -> "The mod library is unavailable.")
                |> Result.bind id
        }

    member internal _.DeleteAtCheckpoint(workspace, modId, revision, checkpoint) =
        run (fun () ->
            task {
                let! owned = DirectDeletion.readOwnedPaths database workspace modId revision

                match owned with
                | Error error -> return Error error
                | Ok(library, names, links) ->
                    let! rootResult =
                        if names.IsEmpty then
                            Task.FromResult(Ok None)
                        else
                            task {
                                let! value = access.Root workspace

                                return
                                    value
                                    |> Result.map Some
                                    |> Result.mapError (fun _ -> "The workspace is unavailable.")
                            }

                    match rootResult with
                    | Error error -> return Error error
                    | Ok root ->
                        do!
                            Task.Run(fun () ->
                                DirectDeletion.removeOwnedPaths
                                    root
                                    library
                                    names
                                    links
                                    checkpoint)

                        checkpoint "before-deletion-completion"

                        let! finished =
                            database.EnqueueInternal(fun () ->
                                DirectDeletion.finish database.Connection workspace modId revision)

                        match finished with
                        | Error error -> return Error error
                        | Ok() ->
                            checkpoint "after-deletion-completion"
                            return Ok()
            })

    member this.Delete(workspace, modId, revision) =
        this.DeleteAtCheckpoint(workspace, modId, revision, ignore)
