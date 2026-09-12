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
      Digest: string option
      Reused: Guid option }

module internal InstallationRows =
    let private refuse message = raise (InstallationException message)

    let files connection transaction id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT entry_index,destination,payload_id,identity,length,digest,reused_payload FROM installation_files WHERE installation_id=$id ORDER BY entry_index"
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
                    Digest = if reader.IsDBNull 5 then None else Some(reader.GetString 5)
                    Reused =
                      if reader.IsDBNull 6 then
                          None
                      else
                          Some(Guid.Parse(reader.GetString 6)) } ]

    let find connection transaction workspace id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT artifact_id,archive_name,name,version_label,state,total_bytes,problem,mod_id,version_id,total_files,target_revision FROM archive_installations WHERE workspace_id=$workspace AND id=$id"
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
                  IsUpdate = not (reader.IsDBNull 10)
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
                    Some(
                        observed
                        |> List.filter (fun file -> file.Identity.IsSome)
                        |> List.sumBy (fun file -> defaultArg file.Length 0L)
                    )

            let retainedFiles =
                Sqlite.number
                    connection
                    transaction
                    "SELECT count(*) FROM installation_reuse WHERE installation_id=$id"
                    [ "$id", box (string id) ]
                |> int

            let retainedBytes =
                Sqlite.number
                    connection
                    transaction
                    "SELECT COALESCE(sum(p.length),0) FROM installation_reuse r JOIN mod_payloads p ON p.id=r.payload_id WHERE r.installation_id=$id"
                    [ "$id", box (string id) ]

            Some
                { value with
                    TemporaryBytes = temporaryBytes
                    Files =
                        if state = InstallationState.Complete then
                            value.TotalFiles
                        elif state = InstallationState.Running then
                            retainedFiles
                            + (observed
                               |> List.filter (fun f -> f.Identity.IsSome || f.Reused.IsSome)
                               |> List.length)
                        else
                            observed |> List.filter (fun f -> f.Identity.IsSome) |> List.length
                    Bytes =
                        if state = InstallationState.Complete then
                            value.TotalBytes
                        elif state = InstallationState.Running then
                            retainedBytes
                            + (observed |> List.sumBy (fun f -> defaultArg f.Length 0L))
                        else
                            observed
                            |> List.filter (fun f -> f.Identity.IsSome)
                            |> List.sumBy (fun f -> defaultArg f.Length 0L) }

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
                match plan.Target with
                | Some target ->
                    match LibraryRows.find connection transaction target.ModId with
                    | Some row when
                        row.Entry.WorkspaceId = plan.Artifact.WorkspaceId
                        && row.Entry.Revision = target.Revision
                        && row.Entry.CurrentVersion = Some target.PreviousVersion
                        ->
                        ()
                    | _ -> refuse "The installed mod changed. Review the update again."

                    if
                        MaintenanceClaims.busy connection transaction target.ModId
                        || Sqlite.number
                            connection
                            transaction
                            "SELECT count(*) FROM mod_versions WHERE mod_id=$mod AND busy=1"
                            [ "$mod", box (string target.ModId) ]
                           <> 0L
                    then
                        refuse "The mod has another operation in progress."
                | None -> ()

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
                    "INSERT INTO archive_installations(id,workspace_id,artifact_id,owner,state,busy,fingerprint,archive_name,name,version_label,source_digest,source_revision,root,mod_id,version_id,total_bytes,total_files,target_revision,previous_version) VALUES($id,$workspace,$artifact,$owner,0,1,$fingerprint,$archive,$name,$label,$digest,$revision,$root,$mod,$version,$bytes,$files,$targetRevision,$previousVersion)"
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
                      "$mod",
                      box (
                          string (
                              plan.Target |> Option.map _.ModId |> Option.defaultWith Guid.NewGuid
                          )
                      )
                      "$version", box (string (Guid.NewGuid()))
                      "$bytes",
                      box (
                          plan.Bytes
                          + (plan.Target
                             |> Option.map (fun target ->
                                 target.Existing |> List.sumBy (fun file -> file.Payload.Length))
                             |> Option.defaultValue 0L)
                      )
                      "$files",
                      box (
                          plan.Files.Length
                          + (plan.Target
                             |> Option.map (fun target -> target.Existing.Length)
                             |> Option.defaultValue 0)
                      )
                      "$targetRevision",
                      plan.Target
                      |> Option.map (fun target -> box target.Revision)
                      |> Option.defaultValue (box DBNull.Value)
                      "$previousVersion",
                      plan.Target
                      |> Option.map (fun target -> box (string target.PreviousVersion))
                      |> Option.defaultValue (box DBNull.Value) ]

                for file in plan.Files do
                    Sqlite.execute
                        connection
                        transaction
                        "INSERT INTO installation_files(installation_id,entry_index,destination,payload_id) VALUES($id,$index,$path,$payload)"
                        [ "$id", box (string id)
                          "$index", box file.Index
                          "$path", box (LibraryEncoding.path file.Destination)
                          "$payload", box (string (Guid.NewGuid())) ]

                for file in plan.Target |> Option.map _.Existing |> Option.defaultValue [] do
                    Sqlite.execute
                        connection
                        transaction
                        "INSERT INTO installation_reuse VALUES($id,$path,$payload)"
                        [ "$id", box (string id)
                          "$path", box (LibraryEncoding.path file.Path)
                          "$payload", box (string file.Payload.Id) ]

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
               |> List.exists (fun f ->
                   f.Digest.IsNone || (f.Identity.IsNone && f.Reused.IsNone) || f.Length.IsNone)
        then
            invalidOp "Installation payload observations are incomplete."

        let expected =
            match plan.Target with
            | None ->
                Sqlite.execute
                    connection
                    transaction
                    "INSERT INTO mods(id,workspace_id,kind,name,notes,comment,version_text,source_text,revision,source_path,source_identity,current_version,status) VALUES($mod,$workspace,1,$name,'','',$label,'',0,NULL,NULL,NULL,5)"
                    [ "$mod", box (string modId)
                      "$workspace", box (string plan.Artifact.WorkspaceId)
                      "$name", box plan.Name
                      "$label", box plan.Version ]

                0L
            | Some target ->
                match LibraryRows.find connection transaction modId with
                | Some row when
                    row.Entry.Revision = target.Revision
                    && row.Entry.CurrentVersion = Some target.PreviousVersion
                    && not (MaintenanceClaims.deleting connection transaction modId)
                    ->
                    target.Revision
                | _ -> refuse "The installed mod changed. The update was not published."

        Sqlite.execute
            connection
            transaction
            "INSERT INTO mod_versions(id,mod_id,expected_revision,owner,phase,busy) VALUES($version,$mod,$expected,$owner,2,1)"
            [ "$version", box (string version)
              "$mod", box (string modId)
              "$owner", box owner
              "$expected", box expected ]

        for file in observed do
            let payloadId = defaultArg file.Reused file.PayloadId

            if file.Reused.IsNone then
                Sqlite.execute
                    connection
                    transaction
                    "INSERT INTO mod_payloads(id,workspace_id,publication_id,identity,length,digest) VALUES($id,$workspace,$version,$identity,$length,$digest)"
                    [ "$id", box (string payloadId)
                      "$workspace", box (string plan.Artifact.WorkspaceId)
                      "$version", box (string version)
                      "$identity", box (LibraryEncoding.identity file.Identity.Value)
                      "$length", box file.Length.Value
                      "$digest", box file.Digest.Value ]

            Sqlite.execute
                connection
                transaction
                "INSERT INTO mod_manifest VALUES($version,$path,$payload)"
                [ "$version", box (string version)
                  "$path", box (LibraryEncoding.path file.Destination)
                  "$payload", box (string payloadId) ]

        Sqlite.execute
            connection
            transaction
            "INSERT INTO mod_manifest SELECT $version,path,payload_id FROM installation_reuse WHERE installation_id=$id"
            [ "$version", box (string version); "$id", box (string id) ]

        Sqlite.execute
            connection
            transaction
            "INSERT INTO archive_version_origins VALUES($version,$artifact)"
            [ "$version", box (string version); "$artifact", box (string plan.Artifact.Id) ]

        PublicationRows.completeIn connection transaction owner version
        |> Result.defaultWith (fun _ ->
            invalidOp "The installation publication could not complete.")
        |> ignore

        match plan.Target with
        | None ->
            SelectionRows.registered
                connection
                transaction
                plan.Artifact.WorkspaceId
                modId
                ModKind.Regular
        | Some _ ->
            Sqlite.execute
                connection
                transaction
                "UPDATE mods SET version_text=$label WHERE id=$mod; UPDATE profiles SET selection_revision=selection_revision+1 WHERE workspace_id=$workspace"
                [ "$label", box plan.Version
                  "$mod", box (string modId)
                  "$workspace", box (string plan.Artifact.WorkspaceId) ]

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
            "UPDATE artifacts SET revision=revision+1 WHERE id=$artifact; UPDATE archive_installations SET state=2,busy=0 WHERE id=$id; DELETE FROM installation_files WHERE installation_id=$id; DELETE FROM installation_reuse WHERE installation_id=$id"
            [ "$artifact", box (string plan.Artifact.Id); "$id", box (string id) ]

        transaction.Commit()
