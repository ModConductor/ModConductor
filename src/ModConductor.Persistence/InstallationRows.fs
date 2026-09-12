namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ArchiveInstallation
open ModConductor.ModLibrary
open ModConductor.Platform

type internal InstallationFile =
    { Index: int
      Destination: LogicalPath
      PayloadId: Guid
      Identity: FileIdentity option
      Length: int64 option
      Digest: string option }

module internal InstallationRows =
    let private refuse message = raise (InstallationException message)

    let files connection transaction id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT entry_index,destination,payload_id,identity,length,digest FROM installation_files WHERE installation_id=$id ORDER BY entry_index"
                [ "$id", box (string id) ]

        use reader = query.ExecuteReader()

        [ while reader.Read() do
              yield
                  { Index = reader.GetInt32 0
                    Destination = LibraryEncoding.readPath (reader.GetString 1)
                    PayloadId = Guid.Parse(reader.GetString 2)
                    Identity =
                      if reader.IsDBNull 3 then
                          None
                      else
                          Some(LibraryEncoding.readIdentity (reader.GetString 3))
                    Length = if reader.IsDBNull 4 then None else Some(reader.GetInt64 4)
                    Digest = if reader.IsDBNull 5 then None else Some(reader.GetString 5) } ]

    let find connection transaction workspace id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT artifact_id,archive_name,name,version_label,state,total_bytes,problem,mod_id,version_id,total_files FROM archive_installations WHERE workspace_id=$workspace AND id=$id"
                [ "$workspace", box (string workspace); "$id", box (string id) ]

        use reader = query.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let state =
                match reader.GetInt32 4 with
                | 0 -> InstallationState.Running
                | 1 -> InstallationState.Stopped
                | 2 -> InstallationState.Complete
                | 3 -> InstallationState.Discarded
                | _ -> invalidOp "Unknown installation state."

            let value =
                { Id = id
                  WorkspaceId = workspace
                  ArtifactId = Guid.Parse(reader.GetString 0)
                  ArchiveName = reader.GetString 1
                  Name = reader.GetString 2
                  Version = reader.GetString 3
                  State = state
                  Files = 0
                  Bytes = 0L
                  TotalFiles = reader.GetInt32 9
                  TotalBytes = reader.GetInt64 5
                  TemporaryBytes = None
                  Problem = if reader.IsDBNull 6 then None else Some(reader.GetString 6)
                  ModId =
                    if state = InstallationState.Complete then
                        Some(Guid.Parse(reader.GetString 7))
                    else
                        None
                  VersionId =
                    if state = InstallationState.Complete then
                        Some(Guid.Parse(reader.GetString 8))
                    else
                        None }

            reader.Close()
            let observed = files connection transaction id

            let temporaryBytes =
                if
                    observed |> List.exists (fun file -> file.Identity.IsSome && file.Length.IsNone)
                then
                    None
                else
                    Some(observed |> List.sumBy (fun file -> defaultArg file.Length 0L))

            Some
                { value with
                    TemporaryBytes = temporaryBytes
                    Files =
                        if state = InstallationState.Complete then
                            value.TotalFiles
                        else
                            observed |> List.filter (fun f -> f.Identity.IsSome) |> List.length
                    Bytes =
                        if state = InstallationState.Complete then
                            value.TotalBytes
                        else
                            observed |> List.sumBy (fun f -> defaultArg f.Length 0L) }

    let reserve (connection: SqliteConnection) owner id (plan: InstallationPlan) =
        use transaction = connection.BeginTransaction(deferred = false)
        let existing = find connection transaction plan.Artifact.WorkspaceId id

        let fresh =
            match existing with
            | Some _ ->
                use query =
                    Sqlite.command
                        connection
                        transaction
                        "SELECT fingerprint FROM archive_installations WHERE id=$id"
                        [ "$id", box (string id) ]

                if string (query.ExecuteScalar()) <> plan.Fingerprint then
                    refuse "This installation request already has a different plan."

                false
            | None ->
                if
                    Sqlite.number
                        connection
                        transaction
                        "SELECT count(*) FROM archive_installations WHERE workspace_id=$workspace AND state IN (0,1)"
                        [ "$workspace", box (string plan.Artifact.WorkspaceId) ]
                    <> 0L
                then
                    refuse "Finish the current installation or delete its temporary files first."

                Sqlite.execute
                    connection
                    transaction
                    "INSERT INTO archive_installations(id,workspace_id,artifact_id,owner,state,busy,fingerprint,archive_name,name,version_label,source_digest,source_revision,root,mod_id,version_id,total_bytes,total_files) VALUES($id,$workspace,$artifact,$owner,0,1,$fingerprint,$archive,$name,$label,$digest,$revision,$root,$mod,$version,$bytes,$files)"
                    [ "$id", box (string id)
                      "$workspace", box (string plan.Artifact.WorkspaceId)
                      "$artifact", box (string plan.Artifact.Id)
                      "$owner", box owner
                      "$fingerprint", box plan.Fingerprint
                      "$archive", box plan.ArchiveName
                      "$name", box plan.Name
                      "$label", box plan.Version
                      "$digest", box plan.Sha256
                      "$revision", box plan.Artifact.Revision
                      "$root", box (String.concat "/" plan.Root)
                      "$mod", box (string (Guid.NewGuid()))
                      "$version", box (string (Guid.NewGuid()))
                      "$bytes", box plan.Bytes
                      "$files", box plan.Files.Length ]

                for file in plan.Files do
                    Sqlite.execute
                        connection
                        transaction
                        "INSERT INTO installation_files(installation_id,entry_index,destination,payload_id) VALUES($id,$index,$path,$payload)"
                        [ "$id", box (string id)
                          "$index", box file.Index
                          "$path", box (LibraryEncoding.path file.Destination)
                          "$payload", box (string (Guid.NewGuid())) ]

                true

        let snapshot =
            find connection transaction plan.Artifact.WorkspaceId id |> Option.get

        transaction.Commit()
        snapshot, fresh

    let stopped connection owner id problem =
        Sqlite.execute
            connection
            null
            "UPDATE archive_installations SET state=1,busy=0,problem=$problem WHERE id=$id AND owner=$owner AND state=0"
            [ "$id", box (string id); "$owner", box owner; "$problem", box problem ]

    let publish (connection: SqliteConnection) owner id (plan: InstallationPlan) =
        use transaction = connection.BeginTransaction(deferred = false)

        use query =
            Sqlite.command
                connection
                transaction
                "SELECT mod_id,version_id,cancelled,state FROM archive_installations WHERE id=$id AND owner=$owner"
                [ "$id", box (string id); "$owner", box owner ]

        use reader = query.ExecuteReader()

        if not (reader.Read()) then
            refuse "This installation is no longer available."

        let modId, version = Guid.Parse(reader.GetString 0), Guid.Parse(reader.GetString 1)

        if reader.GetBoolean 2 || reader.GetInt32 3 <> 0 then
            raise (OperationCanceledException())

        reader.Close()
        let observed = files connection transaction id

        if
            observed.Length <> plan.Files.Length
            || observed
               |> List.exists (fun f -> f.Digest.IsNone || f.Identity.IsNone || f.Length.IsNone)
        then
            invalidOp "Installation payload observations are incomplete."

        Sqlite.execute
            connection
            transaction
            "INSERT INTO mods(id,workspace_id,kind,name,notes,comment,version_text,source_text,revision,source_path,source_identity,current_version,status) VALUES($mod,$workspace,1,$name,'','',$label,'',0,NULL,NULL,NULL,5)"
            [ "$mod", box (string modId)
              "$workspace", box (string plan.Artifact.WorkspaceId)
              "$name", box plan.Name
              "$label", box plan.Version ]

        Sqlite.execute
            connection
            transaction
            "INSERT INTO mod_versions(id,mod_id,expected_revision,owner,phase,busy) VALUES($version,$mod,0,$owner,2,1)"
            [ "$version", box (string version)
              "$mod", box (string modId)
              "$owner", box owner ]

        for file in observed do
            Sqlite.execute
                connection
                transaction
                "INSERT INTO mod_payloads(id,workspace_id,publication_id,identity,length,digest) VALUES($id,$workspace,$version,$identity,$length,$digest)"
                [ "$id", box (string file.PayloadId)
                  "$workspace", box (string plan.Artifact.WorkspaceId)
                  "$version", box (string version)
                  "$identity", box (LibraryEncoding.identity file.Identity.Value)
                  "$length", box file.Length.Value
                  "$digest", box file.Digest.Value ]

            Sqlite.execute
                connection
                transaction
                "INSERT INTO mod_manifest(version_id,path,payload_id) VALUES($version,$path,$payload)"
                [ "$version", box (string version)
                  "$path", box (LibraryEncoding.path file.Destination)
                  "$payload", box (string file.PayloadId) ]

        Sqlite.execute
            connection
            transaction
            "INSERT INTO archive_version_origins VALUES($version,$artifact)"
            [ "$version", box (string version); "$artifact", box (string plan.Artifact.Id) ]

        PublicationRows.completeIn connection transaction owner version
        |> Result.defaultWith (fun _ ->
            invalidOp "The installation publication could not complete.")
        |> ignore

        SelectionRows.registered
            connection
            transaction
            plan.Artifact.WorkspaceId
            modId
            ModKind.Regular

        Sqlite.execute
            connection
            transaction
            "INSERT INTO artifact_links(artifact_id,mod_id,version_id,mod_name,version_label,installed) VALUES($artifact,$mod,$version,$name,$label,1)"
            [ "$artifact", box (string plan.Artifact.Id)
              "$mod", box (string modId)
              "$version", box (string version)
              "$name", box plan.Name
              "$label", box plan.Version ]

        Sqlite.execute
            connection
            transaction
            "UPDATE artifacts SET revision=revision+1 WHERE id=$artifact; UPDATE archive_installations SET state=2,busy=0 WHERE id=$id; DELETE FROM installation_files WHERE installation_id=$id"
            [ "$artifact", box (string plan.Artifact.Id); "$id", box (string id) ]

        transaction.Commit()
