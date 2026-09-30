namespace ModConductor.Persistence

open System
open ModConductor.Platform
open ModConductor.ProfileGameData
open ModConductor.DeploymentRecovery
open ModConductor.Workspaces

type internal WorkspaceDeletionState =
    { Receipt: RootCreationReceipt
      Workspace: Workspace
      Profiles: Guid list
      Data: (ProfileDataContext * PrivateProfileData list) list
      DeploymentContexts: Context list
      Deployments: (Context * Generation) list
      Folders: (string * FileIdentity) list }

module internal WorkspaceDeletionRows =
    let private ids connection sql workspace =
        DeletionRows.ids connection null sql [ "$workspace", box (string workspace) ]

    let private data connection workspace =
        ids
            connection
            "SELECT id FROM profile_data_contexts WHERE workspace_id=$workspace"
            workspace
        |> List.map (fun id ->
            let profiles =
                DeletionRows.ids
                    connection
                    null
                    "SELECT profile_id FROM profile_data_profiles WHERE context_id=$id"
                    [ "$id", box (string id) ]
                |> List.choose (ProfileDataRows.profile connection null id)

            ProfileDataRows.context connection null id |> Option.get, profiles)

    let private folders connection workspace =
        use query =
            Sqlite.command
                connection
                null
                "SELECT root_name,root_identity FROM output_locations WHERE workspace_id=$workspace AND root_identity IS NOT NULL"
                [ "$workspace", box (string workspace) ]

        use reader = query.ExecuteReader()

        let outputs =
            [ while reader.Read() do
                  yield reader.GetString 0, LibraryEncoding.readIdentity (reader.GetString 1) ]

        reader.Close()

        let library =
            LibraryRows.library connection null workspace
            |> Option.bind (fun row ->
                row.Identity |> Option.map (fun identity -> row.Name, identity))

        outputs @ Option.toList library

    let private deploymentContexts connection workspace profiles =
        DeletionRows.ids connection null "SELECT id FROM deployment_contexts" []
        |> List.choose (DeploymentRows.context connection null)
        |> List.filter (fun context ->
            (context.Roots |> List.exists (fun root -> root.Root.Id = workspace))
            || (profiles
                |> List.exists (fun profile ->
                    ModConductor.Deployment.DeploymentContextId.create
                        workspace
                        profile
                        context.Fingerprint = context.Id)))

    let read (database: StateDatabase) workspace =
        database.Enqueue(fun () ->
            let connection = database.Connection

            match WorkspaceRows.find connection null workspace with
            | None -> Error WorkspaceError.NotFound
            | Some row ->
                match WorkspaceProfiles.summary connection null row.Receipt with
                | None -> Error WorkspaceError.NotFound
                | Some value ->
                    let profiles =
                        ids
                            connection
                            "SELECT id FROM profiles WHERE workspace_id=$workspace"
                            workspace

                    let contexts = deploymentContexts connection workspace profiles

                    let deployments =
                        contexts
                        |> List.collect (fun context ->
                            DeletionRows.ids
                                connection
                                null
                                "SELECT id FROM deployment_generations WHERE context_id=$id"
                                [ "$id", box (string context.Id) ]
                            |> List.choose (DeploymentRows.generation connection null context.Id)
                            |> List.map (fun generation -> context, generation))

                    Ok
                        { Receipt = row.Receipt
                          Workspace = value
                          Profiles = profiles
                          Data = data connection workspace
                          DeploymentContexts = contexts
                          Deployments = deployments
                          Folders = folders connection workspace })

    let idle (database: StateDatabase) (state: WorkspaceDeletionState) =
        database.Enqueue(fun () ->
            let workspace = state.Workspace.Id

            let count sql =
                Sqlite.number database.Connection null sql [ "$workspace", box (string workspace) ]

            let busy =
                [ "SELECT count(*) FROM artifacts WHERE workspace_id=$workspace AND busy=1"
                  "SELECT count(*) FROM archive_installations WHERE workspace_id=$workspace AND (busy=1 OR state=0)"
                  "SELECT count(*) FROM mod_versions WHERE mod_id IN (SELECT id FROM mods WHERE workspace_id=$workspace) AND busy=1"
                  "SELECT count(*) FROM bundle_work WHERE workspace_id=$workspace AND busy=1"
                  "SELECT count(*) FROM output_actions WHERE workspace_id=$workspace AND complete=0"
                  "SELECT count(*) FROM fnis_runs WHERE workspace_id=$workspace AND busy=1"
                  "SELECT count(*) FROM executable_runs WHERE workspace_id=$workspace AND phase IN (0,1,2)"
                  "SELECT count(*) FROM skyrim_setup_intents WHERE workspace_id=$workspace AND completed=0" ]
                |> List.exists (fun sql -> count sql <> 0L)

            if
                busy
                || (state.Data |> List.exists (fun (context, _) -> context.Pending.IsSome))
                || (state.DeploymentContexts |> List.exists (fun context -> context.Pending.IsSome))
            then
                Error WorkspaceError.Busy
            else
                Ok())

    let remove (database: StateDatabase) (state: WorkspaceDeletionState) =
        database.Enqueue(fun () ->
            let connection = database.Connection
            use transaction = connection.BeginTransaction(deferred = false)
            Sqlite.execute connection transaction "PRAGMA defer_foreign_keys=ON" []
            let args = [ "$workspace", box (string state.Workspace.Id) ]

            let delete table predicate =
                Sqlite.execute
                    connection
                    transaction
                    ("DELETE FROM " + table + " WHERE " + predicate)
                    args

            let mods = "SELECT id FROM mods WHERE workspace_id=$workspace"
            let versions = "SELECT id FROM mod_versions WHERE mod_id IN (" + mods + ")"

            let installations =
                "SELECT id FROM archive_installations WHERE workspace_id=$workspace"

            for table in
                [ "installation_destinations"; "installation_reuse"; "installation_files" ] do
                delete table ("installation_id IN (" + installations + ")")

            for table in
                [ "mod_edit_origins"
                  "mod_manifest"
                  "mod_version_origins"
                  "version_nexus_origins"
                  "archive_version_origins"
                  "bundle_version_origins" ] do
                delete table ("version_id IN (" + versions + ")")

            delete
                "artifact_links"
                ("artifact_id IN (SELECT id FROM artifacts WHERE workspace_id=$workspace) OR mod_id IN ("
                 + mods
                 + ")")

            delete "mod_categories" ("mod_id IN (" + mods + ")")

            for table in [ "bundle_mods"; "bundle_sources" ] do
                delete
                    table
                    "bundle_id IN (SELECT id FROM bundle_work WHERE workspace_id=$workspace)"

            for table in [ "profile_data_actions"; "profile_data_profiles" ] do
                delete
                    table
                    "context_id IN (SELECT id FROM profile_data_contexts WHERE workspace_id=$workspace)"

            delete
                "output_observations"
                "location_id IN (SELECT id FROM output_locations WHERE workspace_id=$workspace)"

            for context in state.DeploymentContexts |> List.map _.Id do
                let args = [ "$context", box (string context) ]

                for table in [ "deployment_receipts"; "deployment_generations" ] do
                    Sqlite.execute
                        connection
                        transaction
                        ("DELETE FROM " + table + " WHERE context_id=$context")
                        args

                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM deployment_contexts WHERE id=$context"
                    args

            delete
                "profile_mods"
                "profile_id IN (SELECT id FROM profiles WHERE workspace_id=$workspace)"

            for table in
                [ "enb_configuration_operations"
                  "enb_generation_components"
                  "enb_launch_plans"
                  "enb_pending_sources"
                  "enb_profile_status"
                  "enb_selection_intents"
                  "fnis_artifact_selections"
                  "fnis_generators"
                  "fnis_outputs"
                  "fnis_pending_handoffs"
                  "fnis_profile_status"
                  "fnis_publication_intents"
                  "fnis_runs"
                  "skse_artifact_selections"
                  "skse_loader_selections"
                  "skse_pending_handoffs"
                  "skse_profile_status"
                  "skse_replacement_intents"
                  "skyrim_setup_intents"
                  "executable_runs"
                  "executable_presets"
                  "file_visibility_changes"
                  "file_visibility_state"
                  "hidden_mod_files"
                  "game_contexts"
                  "archive_installations"
                  "bundle_work"
                  "artifacts"
                  "categories"
                  "mod_libraries"
                  "mod_payloads"
                  "output_actions"
                  "output_locations"
                  "output_contexts"
                  "profile_data_contexts" ] do
                delete table "workspace_id=$workspace"

            delete "mod_versions" ("mod_id IN (" + mods + ")")
            delete "mods" "workspace_id=$workspace"
            delete "profiles" "workspace_id=$workspace"
            delete "root_creation_receipts" "id=$workspace"
            delete "workspaces" "id=$workspace"
            delete "workspace_roots" "id=$workspace"
            transaction.Commit())
