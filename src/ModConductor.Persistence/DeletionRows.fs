namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ModMaintenance
open ModConductor.ArchiveInstallation
open ModConductor.Platform
open ModConductor.GeneratedOutputs

module internal DeletionRows =
    let private refuse message = raise (InstallationException message)

    let kind =
        function
        | DeletionFileKind.Payload -> 0
        | DeletionFileKind.Archive -> 1
        | DeletionFileKind.Temporary -> 2
        | DeletionFileKind.GenerationLink -> 3

    let readKind =
        function
        | 0 -> DeletionFileKind.Payload
        | 1 -> DeletionFileKind.Archive
        | 2 -> DeletionFileKind.Temporary
        | 3 -> DeletionFileKind.GenerationLink
        | _ -> invalidOp "Unknown deletion effect."

    let effects connection transaction id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT sequence,kind,root,root_identity,path,identity,label,bytes FROM mod_deletion_effects WHERE deletion_id=$id ORDER BY CASE WHEN kind=3 THEN 0 ELSE 1 END,sequence"
                [ "$id", box (string id) ]

        use reader = query.ExecuteReader()

        [ while reader.Read() do
              yield
                  { Sequence = reader.GetInt32 0
                    Kind = readKind (reader.GetInt32 1)
                    Root = HostPath.create (reader.GetString 2) |> Result.defaultWith invalidOp
                    RootIdentity = LibraryEncoding.readIdentity (reader.GetString 3)
                    Path = LibraryEncoding.readPath (reader.GetString 4)
                    Identity =
                      if reader.IsDBNull 5 then
                          None
                      else
                          Some(LibraryEncoding.readIdentity (reader.GetString 5))
                    Label = reader.GetString 6
                    Bytes = if reader.IsDBNull 7 then None else Some(reader.GetInt64 7) } ]

    let find connection transaction workspace id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT mod_id,name,busy,problem FROM mod_deletions WHERE id=$id AND workspace_id=$workspace"
                [ "$id", box (string id); "$workspace", box (string workspace) ]

        use reader = query.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let modId, name, busy =
                Guid.Parse(reader.GetString 0), reader.GetString 1, reader.GetBoolean 2

            let problem = if reader.IsDBNull 3 then None else Some(reader.GetString 3)
            reader.Close()

            Some
                { Id = id
                  WorkspaceId = workspace
                  ModId = modId
                  Name = name
                  Phase =
                    if busy then
                        DeletionPhase.Running
                    else
                        DeletionPhase.Incomplete
                  Remaining =
                    Sqlite.number
                        connection
                        transaction
                        "SELECT count(*) FROM mod_deletion_effects WHERE deletion_id=$id"
                        [ "$id", box (string id) ]
                    |> int
                  Problem = problem }

    let beginDelete (connection: SqliteConnection) owner id (plan: DeletionPlan) =
        use transaction = connection.BeginTransaction(deferred = false)

        match find connection transaction plan.View.WorkspaceId id with
        | Some status when status.ModId = plan.View.ModId ->
            transaction.Commit()
            status, false
        | Some _ -> refuse "This deletion request belongs to another mod."
        | None ->
            if plan.View.Blocked.IsSome then
                refuse plan.View.Blocked.Value

            if
                Sqlite.number
                    connection
                    transaction
                    "SELECT count(*) FROM mod_deletions WHERE workspace_id=$workspace"
                    [ "$workspace", box (string plan.View.WorkspaceId) ]
                <> 0L
            then
                refuse "Finish the current mod deletion first."

            let targets = DeletionQueries.targets connection transaction plan.View.ModId
            let versions = DeletionQueries.versions connection transaction targets
            let members, saved = Set.ofList targets, Set.ofList versions

            match LibraryRows.find connection transaction plan.View.ModId with
            | Some row when
                row.Entry.Revision = plan.View.Revision
                && targets = plan.Targets
                && versions = plan.Versions
                ->
                ()
            | _ -> refuse "The mod changed. Review deletion again."

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
                    refuse "The mod is busy. Finish its current operation first."

            for actionId in
                DeletionQueries.ids
                    connection
                    transaction
                    "SELECT id FROM output_actions WHERE workspace_id=$workspace AND complete=0"
                    [ "$workspace", box (string plan.View.WorkspaceId) ] do
                let action = OutputActionRows.find connection transaction actionId |> Option.get

                match OutputActionRows.destination action with
                | Some(OutputDestination.ExistingMod(modId, _, _))
                | Some(OutputDestination.NewMod(modId, _, _)) when members.Contains modId ->
                    refuse "Finish the pending output action before deleting this mod."
                | _ -> ()

            let profileIds =
                targets
                |> List.collect (fun target ->
                    DeletionQueries.ids
                        connection
                        transaction
                        "SELECT profile_id FROM profile_mods WHERE mod_id=$mod"
                        [ "$mod", box (string target) ])
                |> Set.ofList

            if profileIds <> (plan.View.Profiles |> List.map _.Id |> Set.ofList) then
                refuse "Profile references changed. Review deletion again."

            let privatePayloads =
                plan.Payloads
                |> List.filter (fun id ->
                    DeletionQueries.ids
                        connection
                        transaction
                        "SELECT version_id FROM mod_manifest WHERE payload_id=$id"
                        [ "$id", box (string id) ]
                    |> List.forall saved.Contains)

            if Set.ofList privatePayloads <> Set.ofList plan.PrivatePayloads then
                refuse "Shared file references changed. Review deletion again."

            if BundleDeletion.busy connection transaction plan.View.WorkspaceId targets then
                refuse "Finish the bundle operation before deleting this mod."

            let bundleSources =
                BundleDeletion.files connection transaction plan.View.WorkspaceId targets
                |> List.choose (fun (s, shared) -> if shared then None else Some(s.BundleId, s.Id))
                |> Set.ofList

            if bundleSources <> Set.ofList plan.BundleSources then
                refuse "Bundle archive references changed. Review deletion again."

            let related =
                [ for target in targets do
                      yield!
                          DeletionQueries.ids
                              connection
                              transaction
                              "SELECT artifact_id FROM artifact_links WHERE mod_id=$mod UNION SELECT artifact_id FROM archive_installations WHERE mod_id=$mod UNION SELECT o.artifact_id FROM archive_version_origins o JOIN mod_versions v ON v.id=o.version_id WHERE v.mod_id=$mod"
                              [ "$mod", box (string target) ] ]
                |> List.distinct
                |> List.choose (ArtifactRows.find connection transaction plan.View.WorkspaceId)

            if
                (related |> List.map _.Artifact.Id |> Set.ofList)
                <> Set.ofList plan.RelatedArtifacts
            then
                refuse "Archive references changed. Review deletion again."

            let privateArtifacts =
                related
                |> List.filter (fun artifact ->
                    let links =
                        artifact.Artifact.Links
                        |> List.forall (fun link -> members.Contains link.ModId)

                    let installs =
                        DeletionQueries.ids
                            connection
                            transaction
                            "SELECT mod_id FROM archive_installations WHERE artifact_id=$id AND state IN (0,1)"
                            [ "$id", box (string artifact.Artifact.Id) ]
                        |> List.forall members.Contains

                    links
                    && installs
                    && not (
                        BundleDeletion.parentShared
                            connection
                            transaction
                            artifact.Artifact.Id
                            members
                    ))

            if
                (privateArtifacts |> List.map _.Artifact.Id |> Set.ofList)
                <> Set.ofList plan.Artifacts
            then
                refuse "Shared archive references changed. Review deletion again."

            if privateArtifacts |> List.exists _.Busy then
                refuse "An archive is in use. Finish its operation first."

            let generations =
                DeletionQueries.generations connection transaction plan.View.WorkspaceId
                |> List.filter (fun (_, generation) -> DeletionQueries.includes members generation)

            if
                (generations
                 |> List.map (fun (context, generation) -> context.Id, generation.Id)
                 |> Set.ofList)
                <> (plan.Generations
                    |> List.map (fun (context, generation) -> context, generation.Id)
                    |> Set.ofList)
            then
                refuse "Saved deployments changed. Review deletion again."

            for context, generation in generations do
                if context.Pending.IsSome then
                    refuse "Finish the pending deployment before deleting this mod."

                if
                    context.Active = Some generation.Id && DeletionQueries.uses members generation
                then
                    refuse "Deactivate game files before deleting this mod."

            Sqlite.execute
                connection
                transaction
                "INSERT INTO mod_deletions VALUES($id,$workspace,$mod,$name,$owner,1,NULL)"
                [ "$id", box (string id)
                  "$workspace", box (string plan.View.WorkspaceId)
                  "$mod", box (string plan.View.ModId)
                  "$name", box plan.View.Name
                  "$owner", box owner ]

            for target in targets do
                Sqlite.execute
                    connection
                    transaction
                    "INSERT INTO mod_deletion_targets VALUES($id,$mod); UPDATE mods SET revision=revision+1,status=6 WHERE id=$mod"
                    [ "$id", box (string id); "$mod", box (string target) ]

            for artifact in plan.Artifacts do
                Sqlite.execute
                    connection
                    transaction
                    "INSERT INTO mod_deletion_artifacts VALUES($id,$artifact); UPDATE artifacts SET busy=1,owner=$owner,revision=revision+1 WHERE id=$artifact"
                    [ "$id", box (string id)
                      "$artifact", box (string artifact)
                      "$owner", box owner ]

            for effect in plan.Effects do
                Sqlite.execute
                    connection
                    transaction
                    "INSERT INTO mod_deletion_effects VALUES($id,$sequence,$kind,$root,$rootIdentity,$path,$identity,$label,$bytes)"
                    [ "$id", box (string id)
                      "$sequence", box effect.Sequence
                      "$kind", box (kind effect.Kind)
                      "$root", box (HostPath.value effect.Root)
                      "$rootIdentity", box (LibraryEncoding.identity effect.RootIdentity)
                      "$path", box (LibraryEncoding.path effect.Path)
                      "$identity",
                      effect.Identity
                      |> Option.map (LibraryEncoding.identity >> box)
                      |> Option.defaultValue (box DBNull.Value)
                      "$label", box effect.Label
                      "$bytes",
                      effect.Bytes |> Option.map box |> Option.defaultValue (box DBNull.Value) ]

            for context, generation in generations do
                Sqlite.execute
                    connection
                    transaction
                    "UPDATE deployment_generations SET unavailable='Unavailable after mod deletion' WHERE context_id=$context AND id=$generation"
                    [ "$context", box (string context.Id)
                      "$generation", box (string generation.Id) ]

            for profile in plan.View.Profiles do
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

            let status = find connection transaction plan.View.WorkspaceId id |> Option.get
            transaction.Commit()
            status, true
