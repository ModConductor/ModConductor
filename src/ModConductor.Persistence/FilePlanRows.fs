namespace ModConductor.Persistence

open System
open System.Text
open ModConductor.ModLibrary
open ModConductor.GameContexts
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning

module internal FilePlanRows =
    let revision connection transaction workspace =
        Sqlite.number
            connection
            transaction
            "SELECT COALESCE((SELECT revision FROM file_visibility_state WHERE workspace_id=$workspace),0)"
            [ "$workspace", box (string workspace) ]

    let versions connection transaction workspace profile =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT m.id,m.current_version FROM mods m WHERE m.workspace_id=$workspace AND (m.kind=1 OR (m.kind=5 AND EXISTS(SELECT 1 FROM fnis_outputs f WHERE f.profile_id=$profile AND f.mod_id=m.id))) ORDER BY m.id LIMIT $limit"
                [ "$workspace", box (string workspace)
                  "$profile", box (string profile)
                  "$limit", box (Limits.entries + 1) ]

        use reader = command.ExecuteReader()

        [ while reader.Read() do
              yield
                  Guid.Parse(reader.GetString 0),
                  (if reader.IsDBNull 1 then
                       None
                   else
                       Some(Guid.Parse(reader.GetString 1))) ]

    let stamp connection transaction profile =
        SelectionRows.profile connection transaction profile
        |> Option.map (fun (workspace, selection) ->
            { WorkspaceId = workspace
              ProfileId = profile
              SelectionRevision = selection
              ContextRevision =
                Sqlite.number
                    connection
                    transaction
                    "SELECT COALESCE((SELECT revision FROM game_contexts WHERE workspace_id=$workspace AND profile_id=$profile),0)"
                    [ "$workspace", box (string workspace); "$profile", box (string profile) ]
              ExclusionRevision = revision connection transaction workspace
              OutputRevision =
                Sqlite.number
                    connection
                    transaction
                    "SELECT COALESCE(SUM(revision),0) FROM output_contexts WHERE workspace_id=$workspace"
                    [ "$workspace", box (string workspace) ]
              Versions = versions connection transaction workspace profile
              Deployment =
                match GameContextRows.read connection transaction "" workspace profile with
                | Ok state ->
                    state.Binding
                    |> Option.bind (fun binding ->
                        let id =
                            ModConductor.Deployment.DeploymentContextId.create
                                workspace
                                profile
                                (ModConductor.Deployment.DeploymentContextId.fingerprint
                                    binding.Evidence)

                        use command =
                            Sqlite.command
                                connection
                                transaction
                                "SELECT digest FROM deployment_contexts WHERE id=$id"
                                [ "$id", box (string id) ]

                        match command.ExecuteScalar() with
                        | :? string as value -> Some value
                        | _ -> None)
                | Error _ -> None })

    let hidden connection transaction workspace =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT h.mod_id,h.version_id,h.path FROM hidden_mod_files h JOIN mods m ON m.id=h.mod_id AND m.current_version=h.version_id WHERE h.workspace_id=$workspace AND h.hidden=1"
                [ "$workspace", box (string workspace) ]

        use reader = command.ExecuteReader()

        [ while reader.Read() do
              yield
                  { ModId = Guid.Parse(reader.GetString 0)
                    VersionId = Guid.Parse(reader.GetString 1)
                    Path = LibraryEncoding.readPath (reader.GetString 2) } ]
        |> Set.ofList

    let read connection transaction owner profile =
        match stamp connection transaction profile with
        | None -> Error FilePlanError.NotFound
        | Some stamp when stamp.Versions.Length > Limits.entries ->
            Error(FilePlanError.LimitExceeded "The mod inventory exceeds the entry limit.")
        | Some stamp ->
            match GameContextRows.read connection transaction owner stamp.WorkspaceId profile with
            | Error _ -> Error FilePlanError.NotFound
            | Ok context ->
                let selection =
                    SelectionRows.all connection transaction profile
                    |> List.map (fun row -> row.Id, row)
                    |> Map.ofList

                let generatedOutput =
                    use command =
                        Sqlite.command
                            connection
                            transaction
                            "SELECT mod_id FROM fnis_outputs WHERE profile_id=$profile"
                            [ "$profile", box (string profile) ]

                    match command.ExecuteScalar() with
                    | :? string as value -> Some(Guid.Parse value)
                    | _ -> None

                let mutable remaining = Limits.entries
                let mutable bytes = 0L
                let mutable limited = false
                let mods = ResizeArray<ModLabel>()
                let selected = ResizeArray<SelectedMod>()

                for id, versionId in stamp.Versions do
                    if not limited then
                        match LibraryRows.find connection transaction id with
                        | None -> limited <- true
                        | Some row ->
                            let label =
                                { Id = id
                                  Name = row.Entry.Metadata.Name
                                  Version = row.Entry.Metadata.Version
                                  Revision = row.Entry.Revision }

                            bytes <-
                                bytes
                                + int64 (
                                    Encoding.UTF8.GetByteCount label.Name
                                    + Encoding.UTF8.GetByteCount label.Version
                                    + 128
                                )

                            mods.Add label

                            let version =
                                versionId
                                |> Option.bind (fun version ->
                                    use header =
                                        Sqlite.command
                                            connection
                                            transaction
                                            "SELECT mod_id FROM mod_versions WHERE id=$id AND phase=3"
                                            [ "$id", box (string version) ]

                                    let modId = header.ExecuteScalar()

                                    if isNull modId then
                                        None
                                    else
                                        use command =
                                            Sqlite.command
                                                connection
                                                transaction
                                                "SELECT m.path,p.id,p.length,p.digest FROM mod_manifest m JOIN mod_payloads p ON m.payload_id=p.id WHERE m.version_id=$id ORDER BY m.path"
                                                [ "$id", box (string version) ]

                                        use reader = command.ExecuteReader()
                                        let entries = ResizeArray<ManifestEntry>()

                                        while not limited && reader.Read() do
                                            let encoded = reader.GetString 0
                                            remaining <- remaining - 1

                                            bytes <-
                                                bytes
                                                + int64 (Encoding.UTF8.GetByteCount encoded + 256)

                                            if remaining < 0 || bytes > Limits.snapshotBytes then
                                                limited <- true
                                            else
                                                entries.Add
                                                    { Path = LibraryEncoding.readPath encoded
                                                      Payload =
                                                        { Id = Guid.Parse(reader.GetString 1)
                                                          Length = reader.GetInt64 2
                                                          Sha256 = reader.GetString 3 } }

                                        Some
                                            { Id = version
                                              ModId = Guid.Parse(string modId)
                                              Origin =
                                                LibraryRows.origin connection transaction version
                                              Entries = List.ofSeq entries
                                              NextOffset = None })

                            if bytes > Limits.snapshotBytes then
                                limited <- true

                            let position = selection.TryFind id
                            let selectedGenerated = generatedOutput = Some id

                            selected.Add
                                { ModId = id
                                  Priority =
                                    if selectedGenerated then selection.Count else
                                        position |> Option.map _.Priority |> Option.defaultValue 0
                                  Enabled =
                                    selectedGenerated
                                    || (position |> Option.bind _.Enabled |> Option.defaultValue false)
                                  Version = version
                                  Mappings =
                                    [ { SourcePrefix = PlanPath.Root
                                        TargetRoot = stamp.WorkspaceId
                                        TargetPrefix = PlanPath.Root } ]
                                  Archives = [] }

                if limited then
                    Error(
                        FilePlanError.LimitExceeded
                            "The immutable manifests exceed the file planning limit."
                    )
                else
                    Ok
                        { Stamp = stamp
                          Context = context
                          Profile =
                            { ProfileId = profile
                              Revision = stamp.SelectionRevision
                              Complete = true
                              Mods = List.ofSeq selected }
                          Mods = List.ofSeq mods
                          Hidden = hidden connection transaction stamp.WorkspaceId
                          Writable =
                            match context.Binding with
                            | None -> []
                            | Some _ ->
                                let id =
                                    OutputRows.contextId
                                        stamp.WorkspaceId
                                        stamp.ProfileId
                                        context

                                use query =
                                    Sqlite.command
                                        connection
                                        transaction
                                        "SELECT id,target FROM output_locations WHERE workspace_id=$workspace AND context_id=$context AND enabled=1 AND purpose=1 ORDER BY id LIMIT 65"
                                        [ "$workspace", box (string stamp.WorkspaceId)
                                          "$context", box (string id) ]

                                use reader = query.ExecuteReader()

                                let declarations =
                                    [ while reader.Read() do
                                          yield
                                              { Id = Guid.Parse(reader.GetString 0)
                                                Target =
                                                  WritableTarget.File(
                                                      stamp.WorkspaceId,
                                                      LibraryEncoding.readPath (reader.GetString 1)
                                                  ) } ]

                                if declarations.Length > 64 then
                                    raise (
                                        ModConductor.DeploymentRecovery.RecoveryException
                                            ModConductor.DeploymentRecovery.RecoveryError.Limit
                                    )

                                declarations }

    let savedCopy connection transaction workspace (copy: ModFile) =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT m.name,m.version_text,m.current_version,p.id,p.length,p.digest,COALESCE(h.hidden,0) FROM mods m JOIN mod_versions v ON v.mod_id=m.id JOIN mod_manifest f ON f.version_id=v.id JOIN mod_payloads p ON p.id=f.payload_id LEFT JOIN hidden_mod_files h ON h.workspace_id=m.workspace_id AND h.mod_id=m.id AND h.version_id=v.id AND h.path=f.path WHERE m.workspace_id=$workspace AND m.id=$mod AND v.id=$version AND v.phase=3 AND f.path=$path"
                [ "$workspace", box (string workspace)
                  "$mod", box (string copy.ModId)
                  "$version", box (string copy.VersionId)
                  "$path", box (LibraryEncoding.path copy.Path) ]

        use reader = command.ExecuteReader()

        if not (reader.Read()) then
            Error FilePlanError.InvalidCopy
        else
            let current =
                not (reader.IsDBNull 2) && Guid.Parse(reader.GetString 2) = copy.VersionId

            Ok
                { Copy = copy
                  Name = reader.GetString 0
                  VersionLabel = if current then reader.GetString 1 else ""
                  Current = current
                  Hidden = reader.GetInt64 6 <> 0L
                  Entry =
                    { Path = copy.Path
                      Payload =
                        { Id = Guid.Parse(reader.GetString 3)
                          Length = reader.GetInt64 4
                          Sha256 = reader.GetString 5 } } }

    let exactCopy connection transaction workspace (copy: ModFile) =
        Sqlite.number
            connection
            transaction
            "SELECT count(*) FROM mods m JOIN mod_versions v ON v.id=m.current_version JOIN mod_manifest f ON f.version_id=v.id WHERE m.workspace_id=$workspace AND m.id=$mod AND m.kind=1 AND v.id=$version AND v.phase=3 AND f.path=$path"
            [ "$workspace", box (string workspace)
              "$mod", box (string copy.ModId)
              "$version", box (string copy.VersionId)
              "$path", box (LibraryEncoding.path copy.Path) ] = 1L

    let setHidden
        connection
        transaction
        (expected: SourceStamp)
        (copy: ModFile)
        isHidden
        beforeFingerprint
        afterFingerprint
        =
        match stamp connection transaction expected.ProfileId with
        | None -> Error FilePlanError.NotFound
        | Some current when current <> expected -> Error FilePlanError.Stale
        | Some current when not (exactCopy connection transaction current.WorkspaceId copy) ->
            Error FilePlanError.InvalidCopy
        | Some current ->
            let parameters =
                [ "$workspace", box (string current.WorkspaceId)
                  "$mod", box (string copy.ModId)
                  "$version", box (string copy.VersionId)
                  "$path", box (LibraryEncoding.path copy.Path) ]

            let before =
                Sqlite.number
                    connection
                    transaction
                    "SELECT COALESCE((SELECT hidden FROM hidden_mod_files WHERE workspace_id=$workspace AND mod_id=$mod AND version_id=$version AND path=$path),0)"
                    parameters
                <> 0L

            Sqlite.execute
                connection
                transaction
                "INSERT INTO hidden_mod_files(workspace_id,mod_id,version_id,path,hidden) VALUES($workspace,$mod,$version,$path,$hidden) ON CONFLICT(workspace_id,mod_id,version_id,path) DO UPDATE SET hidden=excluded.hidden"
                (parameters @ [ "$hidden", box (if isHidden then 1 else 0) ])

            Sqlite.execute
                connection
                transaction
                "INSERT INTO file_visibility_state(workspace_id,revision) VALUES($workspace,1) ON CONFLICT(workspace_id) DO UPDATE SET revision=revision+1"
                [ "$workspace", box (string current.WorkspaceId) ]

            Sqlite.execute
                connection
                transaction
                "INSERT INTO file_visibility_changes(workspace_id,mod_id,version_id,path,hidden,before_hidden,profile_id,before_fingerprint,after_fingerprint,recorded_at) VALUES($workspace,$mod,$version,$path,$hidden,$before,$profile,$beforeFingerprint,$afterFingerprint,$time)"
                (parameters
                 @ [ "$hidden", box (if isHidden then 1 else 0)
                     "$before", box (if before then 1 else 0)
                     "$profile", box (string current.ProfileId)
                     "$beforeFingerprint", box beforeFingerprint
                     "$afterFingerprint", box afterFingerprint
                     "$time", box (DateTimeOffset.UtcNow.ToString "O") ])

            Ok
                { current with
                    ExclusionRevision = current.ExclusionRevision + 1L }

    let history connection transaction workspace (copy: ModFile) after =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT id,hidden,before_hidden,profile_id,before_fingerprint,after_fingerprint,recorded_at FROM file_visibility_changes WHERE workspace_id=$workspace AND mod_id=$mod AND version_id=$version AND path=$path AND id<$after ORDER BY id DESC LIMIT 32"
                [ "$workspace", box (string workspace)
                  "$mod", box (string copy.ModId)
                  "$version", box (string copy.VersionId)
                  "$path", box (LibraryEncoding.path copy.Path)
                  "$after", box (defaultArg after Int64.MaxValue) ]

        use reader = command.ExecuteReader()

        [ while reader.Read() do
              yield
                  { Id = reader.GetInt64 0
                    Copy = copy
                    Hidden = reader.GetInt64 1 <> 0L
                    BeforeHidden = reader.GetInt64 2 <> 0L
                    ProfileId = Guid.Parse(reader.GetString 3)
                    BeforeFingerprint = reader.GetString 4
                    AfterFingerprint = reader.GetString 5
                    RecordedAt = DateTimeOffset.Parse(reader.GetString 6) } ]
