namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ArchiveInstallation
open ModConductor.GeneratedOutputs
open ModConductor.DeploymentPlanning
open ModConductor.Platform

module internal DeletionCompletion =
    let finish (connection: SqliteConnection) (state: DeletionState) =
        use transaction = connection.BeginTransaction(deferred = false)
        let workspace = state.View.WorkspaceId
        let targets, versions = state.Targets, state.Versions
        let members, saved = Set.ofList targets, Set.ofList versions
        let privatePayloads = state.PrivatePayloads
        let generations = state.Generations

        for payload in state.Payloads do
            match
                DeletionQueries.ids
                    connection
                    transaction
                    "SELECT version_id FROM mod_manifest WHERE payload_id=$id ORDER BY version_id"
                    [ "$id", box (string payload) ]
                |> List.filter (fun version -> not (saved.Contains version))
            with
            | first :: _ ->
                Sqlite.execute
                    connection
                    transaction
                    "UPDATE mod_payloads SET publication_id=$version WHERE id=$id"
                    [ "$version", box (string first); "$id", box (string payload) ]
            | [] -> ()

        for profile in state.View.Profiles do
            let remaining =
                SelectionRows.all connection transaction profile.Id
                |> List.filter (fun entry -> not (members.Contains entry.Id))
                |> List.mapi (fun index entry -> { entry with Priority = index })

            for target in targets do
                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM profile_mods WHERE profile_id=$profile AND mod_id=$mod"
                    [ "$profile", box (string profile.Id); "$mod", box (string target) ]

            SelectionRows.apply connection transaction profile.Id remaining

        let privateNames =
            privatePayloads |> List.map LibraryFiles.payloadName |> Set.ofList

        let library = LibraryRows.library connection transaction workspace

        for context, generation in generations do
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
                  "$context", box (string context)
                  "$generation", box (string generation.Id) ]

            Sqlite.execute
                connection
                transaction
                "DELETE FROM deployment_receipts WHERE context_id=$context AND phase IN (2,3) AND (proposed_id=$generation OR previous_id=$generation)"
                [ "$context", box (string context); "$generation", box (string generation.Id) ]

        BundleDeletion.complete connection transaction workspace targets

        for actionId in
            DeletionQueries.ids
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
                "DELETE FROM artifact_links WHERE mod_id=$mod; DELETE FROM mod_categories WHERE mod_id=$mod; DELETE FROM hidden_mod_files WHERE mod_id=$mod; DELETE FROM file_visibility_changes WHERE mod_id=$mod; DELETE FROM profile_mods WHERE mod_id=$mod; UPDATE mods SET current_version=NULL WHERE id=$mod"
                args

            for installation in
                DeletionQueries.ids
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

        for artifact in state.Artifacts do
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
