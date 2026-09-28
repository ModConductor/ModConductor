namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform
open ModConductor.ProfileGameData

type internal ProfileArchiveBase =
    { ArtifactId: Guid
      VersionId: Guid
      ArchiveName: string
      ArchiveSha256: string
      ArchiveLength: int64
      Root: string list
      Files: ManifestEntry list }

type internal ProfileModSnapshot =
    { Entry: ModEntry
      Selection: OrderedMod
      Version: ModVersion option
      Base: ProfileArchiveBase option
      Nexus: PortableNexusSource option
      Hidden: string list list }

type internal ProfileSnapshot =
    { WorkspaceId: Guid
      ProfileId: Guid
      Name: string
      Game: string
      SelectionRevision: int64
      Mods: ProfileModSnapshot list
      Settings: DataRoot option
      Saves: DataRoot option
      SettingsEnabled: bool
      SavesEnabled: bool
      PluginOrder: PortablePlugin list }

module internal ProfileTransportSnapshot =
    let private queryOne connection transaction sql parameters =
        use query = Sqlite.command connection transaction sql parameters
        query.ExecuteScalar()

    let private installation connection transaction (entry: ModEntry) current =
        let rec sourceVersion version depth =
            if depth > 128 then
                None
            else
                match
                    queryOne
                        connection
                        transaction
                        "SELECT source_version FROM mod_edit_origins WHERE version_id=$version"
                        [ "$version", box (string version) ]
                with
                | :? string as previous -> sourceVersion (Guid.Parse previous) (depth + 1)
                | _ ->
                    match
                        queryOne
                            connection
                            transaction
                            "SELECT source_version FROM mod_version_origins WHERE version_id=$version"
                            [ "$version", box (string version) ]
                    with
                    | :? string as previous -> sourceVersion (Guid.Parse previous) (depth + 1)
                    | _ ->
                        match LibraryRows.origin connection transaction version with
                        | VersionOrigin.Archive artifact -> Some(version, artifact)
                        | _ -> None

        match sourceVersion current 0 with
        | None -> None
        | Some(sourceVersion, artifact) ->
            use query =
                Sqlite.command
                    connection
                    transaction
                    "SELECT version_id,archive_name,source_digest,root,previous_version FROM archive_installations WHERE mod_id=$mod AND artifact_id=$artifact AND state=2 ORDER BY version_id"
                    [ "$mod", box (string entry.Id)
                      "$artifact", box (string artifact) ]

            use reader = query.ExecuteReader()

            let rows =
                [ while reader.Read() do
                      yield
                          Guid.Parse(reader.GetString 0),
                          reader.GetString 1,
                          reader.GetString 2,
                          reader.GetString 3,
                          reader.IsDBNull 4 ]

            reader.Close()

            let candidates =
                match rows |> List.filter (fun (id, _, _, _, _) -> id = sourceVersion) with
                | [ exact ] -> [ exact ]
                | [] -> rows
                | _ -> []

            match candidates with
            | [ (baseId, name, digest, root, fresh) ] when fresh ->
                match
                    LibraryRows.version connection transaction baseId 0 100001,
                    ArtifactRows.find connection transaction entry.WorkspaceId artifact
                with
                | Some version, Some stored when
                    stored.Artifact.Sha256 = Some digest
                    && stored.Artifact.Length.IsSome
                    && version.Entries.Length <= 100000
                    ->
                    Some
                        { ArtifactId = artifact
                          VersionId = baseId
                          ArchiveName = name
                          ArchiveSha256 = digest
                          ArchiveLength = stored.Artifact.Length.Value
                          Root = if root = "" then [] else root.Split('/') |> Array.toList
                          Files = version.Entries }
                | _ -> None
            | _ -> None

    let private nexus connection transaction current baseVersion =
        let version = baseVersion |> Option.map _.VersionId |> Option.defaultValue current

        NexusOriginRows.origins connection transaction version
        |> List.tryFind (fun (_, file) -> not file.Manual)
        |> Option.orElseWith (fun () ->
            NexusOriginRows.origins connection transaction current |> List.tryHead)
        |> Option.map (fun (identity, file) ->
            { Game = identity.Game
              ModId = identity.Mod
              FileId = file.Id
              FileVersion = file.Version })

    let private hidden connection transaction workspace modId version =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT path FROM hidden_mod_files WHERE workspace_id=$workspace AND mod_id=$mod AND version_id=$version AND hidden=1 ORDER BY path"
                [ "$workspace", box (string workspace)
                  "$mod", box (string modId)
                  "$version", box (string version) ]

        use reader = query.ExecuteReader()

        [ while reader.Read() do
              yield LibraryEncoding.readPath (reader.GetString 0) |> LogicalPath.components ]

    let read connection transaction workspace profile =
        let profileRow =
            use query =
                Sqlite.command
                    connection
                    transaction
                    "SELECT name,selection_revision FROM profiles WHERE id=$profile AND workspace_id=$workspace"
                    [ "$profile", box (string profile)
                      "$workspace", box (string workspace) ]

            use reader = query.ExecuteReader()

            if reader.Read() then Some(reader.GetString 0, reader.GetInt64 1) else None

        let game =
            queryOne
                connection
                transaction
                "SELECT game_id FROM game_contexts WHERE workspace_id=$workspace AND profile_id=$profile"
                [ "$workspace", box (string workspace)
                  "$profile", box (string profile) ]

        let privateData =
            use query =
                Sqlite.command
                    connection
                    transaction
                    "SELECT p.body FROM profile_data_profiles p JOIN profile_data_contexts c ON c.id=p.context_id WHERE c.workspace_id=$workspace AND p.profile_id=$profile"
                    [ "$workspace", box (string workspace)
                      "$profile", box (string profile) ]

            use reader = query.ExecuteReader()

            [ while reader.Read() do
                  yield ProfileDataEncoding.readProfile (reader.GetFieldValue<byte array> 0) ]

        if privateData.Length > 1 then
            raise (InvalidDataException "The profile has multiple private settings locations.")

        let data = privateData |> List.tryHead

        match profileRow, game with
        | Some(name, revision), (:? string as game) ->
            let selectedMods =
                SelectionRows.all connection transaction profile
                |> List.map (fun selection ->
                    let row = LibraryRows.find connection transaction selection.Id

                    match row with
                    | None -> raise (InvalidDataException "A selected mod is unavailable.")
                    | Some row when row.Entry.WorkspaceId <> workspace ->
                        raise (InvalidDataException "A selected mod belongs to another workspace.")
                    | Some row ->
                        let version =
                            row.Entry.CurrentVersion
                            |> Option.map (fun id ->
                                LibraryRows.version connection transaction id 0 100001
                                |> Option.defaultWith (fun () ->
                                    raise (InvalidDataException "A selected mod version is unavailable.")))

                        if version |> Option.exists (fun value -> value.Entries.Length > 100000) then
                            raise (InvalidDataException "A selected mod exceeds the file limit.")

                        let baseVersion =
                            version
                            |> Option.bind (fun value ->
                                installation connection transaction row.Entry value.Id)

                        { Entry = row.Entry
                          Selection = selection
                          Version = version
                          Base = baseVersion
                          Nexus =
                            version
                            |> Option.bind (fun value ->
                                nexus connection transaction value.Id baseVersion)
                          Hidden =
                            version
                            |> Option.map (fun value ->
                                hidden connection transaction workspace row.Entry.Id value.Id)
                            |> Option.defaultValue [] })

            let generated =
                let id = FnisRunRows.outputId profile

                match LibraryRows.find connection transaction id with
                | Some row when row.Entry.WorkspaceId = workspace && row.Entry.Kind = ModKind.GeneratedOutput ->
                    let version =
                        row.Entry.CurrentVersion
                        |> Option.bind (fun id -> LibraryRows.version connection transaction id 0 100001)

                    version
                    |> Option.map (fun version ->
                        { Entry = row.Entry
                          Selection =
                            { Id = id
                              Priority = selectedMods.Length
                              Enabled = Some true }
                          Version = Some version
                          Base = None
                          Nexus = None
                          Hidden = hidden connection transaction workspace id version.Id })
                | _ -> None

            { WorkspaceId = workspace
              ProfileId = profile
              Name = name
              Game = game
              SelectionRevision = revision
              Mods = selectedMods @ (generated |> Option.toList)
              Settings = data |> Option.bind _.Settings
              Saves = data |> Option.bind _.Saves
              SettingsEnabled = data |> Option.exists _.Options.Settings
              SavesEnabled = data |> Option.exists _.Options.Saves
              PluginOrder =
                data
                |> Option.bind _.PluginOrder
                |> Option.map (fun order ->
                    order.Entries
                    |> List.map (fun entry ->
                        { Name = entry.Name
                          Enabled = entry.Enabled
                          LockedIndex = entry.LockedIndex }))
                |> Option.defaultValue [] }
            |> Ok
        | _ -> Error "Select a profile with a game installation."
