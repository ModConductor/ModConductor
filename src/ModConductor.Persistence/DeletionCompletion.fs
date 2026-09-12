namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ModMaintenance
open ModConductor.ArchiveInstallation
open ModConductor.GeneratedOutputs
open ModConductor.DeploymentPlanning
open ModConductor.Platform

module internal DeletionCompletion =
    let finish (connection: SqliteConnection) owner workspace id =
        use transaction = connection.BeginTransaction(deferred = false)

        let status =
            DeletionRows.find connection transaction workspace id
            |> Option.defaultWith (fun () ->
                raise (InstallationException "The deletion is no longer pending."))

        if status.Remaining <> 0 then
            raise (InstallationException "There are still owned files to delete.")

        if
            Sqlite.number
                connection
                transaction
                "SELECT count(*) FROM mod_deletions WHERE id=$id AND owner=$owner AND busy=1"
                [ "$id", box (string id); "$owner", box owner ]
            <> 1L
        then
            raise (InstallationException "The deletion belongs to another operation.")

        let targets =
            DeletionQueries.ids
                connection
                transaction
                "SELECT mod_id FROM mod_deletion_targets WHERE deletion_id=$id"
                [ "$id", box (string id) ]

        let members = Set.ofList targets
        let versions = DeletionQueries.versions connection transaction targets
        let saved = Set.ofList versions

        let payloads =
            versions
            |> List.collect (fun version ->
                DeletionQueries.ids
                    connection
                    transaction
                    "SELECT id FROM mod_payloads WHERE publication_id=$version UNION SELECT payload_id FROM mod_manifest WHERE version_id=$version"
                    [ "$version", box (string version) ])
            |> List.distinct

        let privatePayloads = ResizeArray<Guid>()

        for payload in payloads do
            let retained =
                DeletionQueries.ids
                    connection
                    transaction
                    "SELECT version_id FROM mod_manifest WHERE payload_id=$id ORDER BY version_id"
                    [ "$id", box (string payload) ]
                |> List.filter (fun version -> not (saved.Contains version))

            match retained with
            | [] -> privatePayloads.Add payload
            | first :: _ ->
                Sqlite.execute
                    connection
                    transaction
                    "UPDATE mod_payloads SET publication_id=$version WHERE id=$id"
                    [ "$version", box (string first); "$id", box (string payload) ]

        let privateNames = privatePayloads |> Seq.map LibraryFiles.payloadName |> Set.ofSeq
        let library = LibraryRows.library connection transaction workspace

        for context, generation in DeletionQueries.generations connection transaction workspace do
            if DeletionQueries.includes members generation then
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
                        | SourcePin.Mod(modId, _, _) -> not (members.Contains modId)
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
                                        |> Set.filter (fun file ->
                                            not (members.Contains file.ModId)) })

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

        let outputActions =
            DeletionQueries.ids
                connection
                transaction
                "SELECT id FROM output_actions WHERE workspace_id=$workspace AND complete=1"
                [ "$workspace", box (string workspace) ]

        for actionId in outputActions do
            let action = OutputActionRows.find connection transaction actionId |> Option.get

            match OutputActionRows.destination action with
            | Some(OutputDestination.ExistingMod(modId, _, _))
            | Some(OutputDestination.NewMod(modId, _, _)) when members.Contains modId ->
                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM output_actions WHERE id=$id"
                    [ "$id", box (string actionId) ]
            | _ -> ()

        for modId in targets do
            let args = [ "$mod", box (string modId) ]

            Sqlite.execute
                connection
                transaction
                "DELETE FROM artifact_links WHERE mod_id=$mod; DELETE FROM mod_categories WHERE mod_id=$mod; DELETE FROM hidden_mod_files WHERE mod_id=$mod; DELETE FROM file_visibility_changes WHERE mod_id=$mod; DELETE FROM profile_mods WHERE mod_id=$mod; UPDATE mods SET current_version=NULL WHERE id=$mod"
                args

            let installations =
                DeletionQueries.ids
                    connection
                    transaction
                    "SELECT id FROM archive_installations WHERE mod_id=$mod"
                    args

            for install in installations do
                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM installation_files WHERE installation_id=$id; DELETE FROM installation_reuse WHERE installation_id=$id; DELETE FROM archive_installations WHERE id=$id"
                    [ "$id", box (string install) ]

        for version in versions do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM archive_version_origins WHERE version_id=$version; DELETE FROM mod_version_origins WHERE version_id=$version; UPDATE mod_version_origins SET source_version=NULL WHERE source_version=$version; DELETE FROM mod_manifest WHERE version_id=$version"
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

        for modId in targets do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM mods WHERE id=$id"
                [ "$id", box (string modId) ]

        for artifact in
            DeletionQueries.ids
                connection
                transaction
                "SELECT artifact_id FROM mod_deletion_artifacts WHERE deletion_id=$id"
                [ "$id", box (string id) ] do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM artifacts WHERE id=$id"
                [ "$id", box (string artifact) ]

        Sqlite.execute
            connection
            transaction
            "UPDATE profiles SET selection_revision=selection_revision+1 WHERE workspace_id=$workspace; UPDATE file_visibility_state SET revision=revision+1 WHERE workspace_id=$workspace; DELETE FROM mod_deletion_artifacts WHERE deletion_id=$id; DELETE FROM mod_deletion_targets WHERE deletion_id=$id; DELETE FROM mod_deletions WHERE id=$id"
            [ "$workspace", box (string workspace); "$id", box (string id) ]

        transaction.Commit()

        { status with
            Phase = DeletionPhase.Complete
            Remaining = 0
            Problem = None }
