namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open Microsoft.Data.Sqlite
open ModConductor.ArchiveInstallation
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.GeneratedOutputs
open ModConductor.ModLibrary
open ModConductor.Platform

module private DirectDeletion =
    let refuse message = raise (InstallationException message)

    let private row connection transaction workspace modId expected =
        let value =
            LibraryRows.find connection transaction modId
            |> Option.defaultWith (fun () -> refuse "The mod is no longer installed.")

        if value.Entry.WorkspaceId <> workspace || value.Entry.Revision <> expected then
            refuse "The mod changed. Delete it again."

        if value.Entry.Kind <> ModKind.Regular then
            refuse "Choose a regular installed mod."

        value

    let private ensureIdle connection transaction workspace targets =
        let members = Set.ofList targets

        for target in targets do
            if
                MaintenanceClaims.busy connection transaction target
                || Sqlite.number
                    connection
                    transaction
                    "SELECT count(*) FROM mod_versions WHERE mod_id=$mod AND busy=1"
                    [ "$mod", box (string target) ]
                   <> 0L
            then
                refuse "Finish the mod's current operation before deleting it."

        for actionId in
            DeletionRows.ids
                connection
                transaction
                "SELECT id FROM output_actions WHERE workspace_id=$workspace AND complete=0"
                [ "$workspace", box (string workspace) ] do
            let action = OutputActionRows.find connection transaction actionId |> Option.get

            match OutputActionRows.destination action with
            | Some(OutputDestination.ExistingMod(id, _, _))
            | Some(OutputDestination.NewMod(id, _, _)) when members.Contains id ->
                refuse "Finish the mod's pending output operation before deleting it."
            | _ -> ()

        if BundleDeletion.busy connection transaction workspace targets then
            refuse "Finish the bundle operation before deleting this mod."

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

        artifactIds connection transaction targets
        |> List.choose (fun id ->
            use query =
                Sqlite.command
                    connection
                    transaction
                    "SELECT storage,busy FROM artifacts WHERE workspace_id=$workspace AND id=$id"
                    [ "$workspace", box (string workspace); "$id", box (string id) ]

            use reader = query.ExecuteReader()

            if not (reader.Read()) then
                None
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
                    None
                else
                    if busy then
                        refuse
                            "An archive is in use. Finish its operation before deleting this mod."

                    Some(id, storage))

    let private generations connection transaction workspace targets =
        let members = Set.ofList targets

        let values =
            DeletionRows.generations connection transaction workspace
            |> List.filter (fun (_, generation) -> DeletionRows.includes members generation)

        for context, generation in values do
            if context.Pending.IsSome then
                refuse "Finish the pending deployment before deleting this mod."
            elif context.Active = Some generation.Id && DeletionRows.uses members generation then
                refuse "Deactivate game files before deleting this mod."

        values

    let private libraryNames connection transaction workspace targets versions =
        let _, privatePayloads = payloads connection transaction versions

        let privateBundles =
            BundleDeletion.files connection transaction workspace targets
            |> List.choose (fun (source, shared) -> if shared then None else Some source.Id)

        let privateArtifacts = artifacts connection transaction workspace targets

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

        privatePayloads, privateArtifacts |> List.map fst, names

    let readOwnedPaths (database: StateDatabase) workspace modId expected =
        database.Enqueue(fun () ->
            let connection = database.Connection
            use transaction = connection.BeginTransaction(deferred = true)
            row connection transaction workspace modId expected |> ignore
            let targets = DeletionRows.targets connection transaction modId
            ensureIdle connection transaction workspace targets
            let versions = DeletionRows.versions connection transaction targets

            let privatePayloads, _, names =
                libraryNames connection transaction workspace targets versions

            let library = LibraryRows.library connection transaction workspace

            if not names.IsEmpty then
                match library with
                | Some stored when stored.Phase = 2 && stored.Identity.IsSome -> ()
                | _ -> refuse "The owned mod library is unavailable."

            let privateNames =
                privatePayloads |> List.map LibraryFiles.payloadName |> Set.ofList

            let links =
                match library with
                | Some stored when stored.Identity.IsSome ->
                    [ for _, generation in generations connection transaction workspace targets do
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
                | _ -> []

            transaction.Commit()
            library, names, links)

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

    let finish (connection: SqliteConnection) workspace modId expected =
        use transaction = connection.BeginTransaction(deferred = false)
        row connection transaction workspace modId expected |> ignore
        let targets = DeletionRows.targets connection transaction modId
        ensureIdle connection transaction workspace targets
        let versions = DeletionRows.versions connection transaction targets
        let members, saved = Set.ofList targets, Set.ofList versions
        let allPayloads, privatePayloads = payloads connection transaction versions

        let privateArtifacts =
            artifacts connection transaction workspace targets |> List.map fst

        let affectedGenerations = generations connection transaction workspace targets

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


type DeletionStore internal (database: StateDatabase, access: LibraryAccess) =
    let refuse message = raise (InstallationException message)

    let run action =
        task {
            let! result = access.Run action
            return result |> Result.defaultWith (fun _ -> refuse "The mod library is unavailable.")
        }

    member internal _.DeleteAtCheckpoint(workspace, modId, revision, checkpoint) =
        run (fun () ->
            task {
                let! library, names, links =
                    DirectDeletion.readOwnedPaths database workspace modId revision

                let! (root: WorkspaceRoot option) =
                    if names.IsEmpty then
                        Task.FromResult None
                    else
                        task {
                            let! value = access.Root workspace

                            return
                                value
                                |> Result.map Some
                                |> Result.defaultWith (fun _ ->
                                    refuse "The workspace is unavailable.")
                        }

                do!
                    Task.Run(fun () ->
                        DirectDeletion.removeOwnedPaths root library names links checkpoint)

                checkpoint "before-deletion-completion"

                do!
                    database.EnqueueInternal(fun () ->
                        DirectDeletion.finish database.Connection workspace modId revision)

                checkpoint "after-deletion-completion"
                return Ok()
            })

    member this.Delete(workspace, modId, revision) =
        this.DeleteAtCheckpoint(workspace, modId, revision, ignore)
