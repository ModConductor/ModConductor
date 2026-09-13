namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.ModMaintenance
open ModConductor.ArchiveInstallation
open ModConductor.ArtifactLibrary
open ModConductor.Platform
open ModConductor.GeneratedOutputs

module internal DeletionSnapshot =
    let private refuse message = raise (InstallationException message)

    let read (database: StateDatabase) workspace modId expected =
        database.Enqueue(fun () ->
            let connection = database.Connection
            use transaction = connection.BeginTransaction(deferred = true)

            let row =
                LibraryRows.find connection transaction modId
                |> Option.defaultWith (fun () -> refuse "The mod is no longer installed.")

            if row.Entry.WorkspaceId <> workspace || row.Entry.Revision <> expected then
                refuse "The mod changed. Review deletion again."

            if row.Entry.Kind <> ModKind.Regular then
                refuse "Choose a regular installed mod."

            let targets = DeletionQueries.targets connection transaction modId
            let members = Set.ofList targets
            let versions = DeletionQueries.versions connection transaction targets
            let saved = Set.ofList versions
            let mutable blocked = None

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
                    blocked <- Some "Finish the mod's current operation before deleting it."

            for actionId in
                DeletionQueries.ids
                    connection
                    transaction
                    "SELECT id FROM output_actions WHERE workspace_id=$workspace AND complete=0"
                    [ "$workspace", box (string workspace) ] do
                let action = OutputActionRows.find connection transaction actionId |> Option.get

                match OutputActionRows.destination action with
                | Some(OutputDestination.ExistingMod(id, _, _))
                | Some(OutputDestination.NewMod(id, _, _)) when members.Contains id ->
                    blocked <- Some "Finish the mod's pending output operation before deleting it."
                | _ -> ()

            let payloadIds =
                versions
                |> List.collect (fun version ->
                    DeletionQueries.ids
                        connection
                        transaction
                        "SELECT id FROM mod_payloads WHERE publication_id=$version UNION SELECT payload_id FROM mod_manifest WHERE version_id=$version"
                        [ "$version", box (string version) ])
                |> List.distinct

            let payloads =
                payloadIds
                |> List.map (fun id ->
                    let owners =
                        DeletionQueries.ids
                            connection
                            transaction
                            "SELECT version_id FROM mod_manifest WHERE payload_id=$id"
                            [ "$id", box (string id) ]

                    let shared =
                        owners |> List.exists (fun version -> not (saved.Contains version))

                    use query =
                        Sqlite.command
                            connection
                            transaction
                            "SELECT identity,length,COALESCE((SELECT path FROM mod_manifest WHERE payload_id=$id ORDER BY version_id LIMIT 1),'') FROM mod_payloads WHERE id=$id"
                            [ "$id", box (string id) ]

                    use reader = query.ExecuteReader()

                    if not (reader.Read()) then
                        refuse "A stored payload record is unavailable."

                    let identity =
                        if reader.IsDBNull 0 then
                            None
                        else
                            Some(LibraryEncoding.readIdentity (reader.GetString 0))

                    let bytes = if reader.IsDBNull 1 then None else Some(reader.GetInt64 1)

                    let label =
                        if reader.GetString 2 = "" then
                            "Unfinished saved mod file"
                        else
                            reader.GetString 2 |> LibraryEncoding.readPath |> LogicalPath.display

                    id, identity, bytes, label, shared)

            let installations =
                targets
                |> List.collect (fun target ->
                    DeletionQueries.ids
                        connection
                        transaction
                        "SELECT id FROM archive_installations WHERE mod_id=$mod"
                        [ "$mod", box (string target) ])

            let temporary =
                installations
                |> List.collect (fun id -> InstallationRows.files connection transaction id)
                |> List.filter (fun file -> file.Reused.IsNone)

            let bundleSources = BundleDeletion.files connection transaction workspace targets

            if BundleDeletion.busy connection transaction workspace targets then
                blocked <- Some "Finish the bundle operation before deleting this mod."

            let artifactIds =
                [ for target in targets do
                      yield!
                          DeletionQueries.ids
                              connection
                              transaction
                              "SELECT artifact_id FROM artifact_links WHERE mod_id=$mod UNION SELECT artifact_id FROM archive_installations WHERE mod_id=$mod UNION SELECT o.artifact_id FROM archive_version_origins o JOIN mod_versions v ON v.id=o.version_id WHERE v.mod_id=$mod"
                              [ "$mod", box (string target) ] ]
                |> List.distinct

            let artifacts =
                artifactIds
                |> List.choose (fun id -> ArtifactRows.find connection transaction workspace id)
                |> List.map (fun artifact ->
                    let usedElsewhere =
                        artifact.Artifact.Links
                        |> List.exists (fun link -> not (members.Contains link.ModId))

                    let otherInstalls =
                        DeletionQueries.ids
                            connection
                            transaction
                            "SELECT mod_id FROM archive_installations WHERE artifact_id=$id AND state IN (0,1)"
                            [ "$id", box (string artifact.Artifact.Id) ]
                        |> List.exists (fun id -> not (members.Contains id))

                    let shared =
                        usedElsewhere
                        || otherInstalls
                        || BundleDeletion.parentShared
                            connection
                            transaction
                            artifact.Artifact.Id
                            members

                    if not shared && artifact.Busy then
                        blocked <-
                            Some
                                "An archive is in use. Finish its operation before deleting this mod."

                    artifact, shared)

            let generations =
                DeletionQueries.generations connection transaction workspace
                |> List.filter (fun (_, generation) -> DeletionQueries.includes members generation)

            for context, generation in generations do
                if context.Pending.IsSome then
                    blocked <- Some "Finish the pending deployment before deleting this mod."
                elif
                    context.Active = Some generation.Id && DeletionQueries.uses members generation
                then
                    blocked <- Some "Deactivate game files before deleting this mod."

            let profiles =
                [ for target in targets do
                      use query =
                          Sqlite.command
                              connection
                              transaction
                              "SELECT p.id,p.name FROM profile_mods m JOIN profiles p ON p.id=m.profile_id WHERE m.mod_id=$mod ORDER BY p.id"
                              [ "$mod", box (string target) ]

                      use reader = query.ExecuteReader()

                      while reader.Read() do
                          yield
                              { DeletionProfile.Id = Guid.Parse(reader.GetString 0)
                                Name = reader.GetString 1 } ]
                |> List.distinctBy _.Id

            let backups =
                targets
                |> List.filter ((<>) modId)
                |> List.choose (LibraryRows.find connection transaction)
                |> List.map _.Entry.Metadata.Name

            let library = LibraryRows.library connection transaction workspace
            transaction.Commit()

            row,
            targets,
            versions,
            payloads,
            temporary,
            bundleSources,
            artifacts,
            generations,
            profiles,
            backups,
            library,
            blocked)
