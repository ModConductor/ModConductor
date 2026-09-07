namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open Microsoft.Data.Sqlite
open ModConductor.Persistence

module OrganizationMigration =
    let observe (writer: Utf8JsonWriter) primary =
        let area =
            Directory.CreateDirectory(Path.Combine(primary, "organization-migration")).FullName

        let database = Path.Combine(area, "state.db")
        File.Copy(Path.Combine(AppContext.BaseDirectory, "fixtures", "state-v5.db"), database)
        use connection = new SqliteConnection("Data Source=" + database + ";Pooling=False")
        connection.Open()
        let number sql = Sqlite.number connection null sql []

        let rows sql =
            use command = Sqlite.command connection null sql []
            use reader = command.ExecuteReader()

            [ while reader.Read() do
                  yield [ for column in 0 .. reader.FieldCount - 1 -> reader.GetValue column ] ]

        let metadataSql =
            "SELECT id,workspace_id,kind,name,notes,comment,version_text,source_text,revision,source_path,source_identity,current_version,status FROM mods ORDER BY id"

        let selectionSql =
            "SELECT profile_id,mod_id,priority,enabled FROM profile_mods ORDER BY profile_id,priority"

        let profilesSql =
            "SELECT id,workspace_id,name,selection_revision FROM profiles ORDER BY id"

        let workspacesSql =
            "SELECT id,name,revision,selected_profile FROM workspaces ORDER BY id"

        let workspaces = rows workspacesSql

        let metadata, selection, profiles =
            rows metadataSql, rows selectionSql, rows profilesSql

        let legacy =
            rows "SELECT id,workspace_id,category FROM mods WHERE category<>'' ORDER BY id"

        let mutable interrupted = false

        try
            Sqlite.migrateAtCommit connection (fun () -> invalidOp "Fixture commit interruption.")
        with :? InvalidOperationException ->
            interrupted <- true

        writer.WriteStartObject("categoryMigration")

        writer.WriteBoolean(
            "rollback",
            interrupted
            && number "PRAGMA user_version" = 5L
            && rows metadataSql = metadata
            && rows selectionSql = selection
            && rows profilesSql = profiles
            && rows workspacesSql = workspaces
            && rows "SELECT id,workspace_id,category FROM mods WHERE category<>'' ORDER BY id" = legacy
        )

        Sqlite.migrate connection

        let referencesSql =
            "SELECT m.id,m.workspace_id,c.label FROM mods m JOIN mod_categories r ON r.mod_id=m.id JOIN categories c ON c.id=r.category_id ORDER BY m.id"

        let references =
            rows "SELECT mod_id,category_id,label FROM mod_categories ORDER BY mod_id"

        let expectedDefinitions =
            legacy
            |> List.map (fun row -> string row[1], string row[2])
            |> Set.ofList
            |> Set.count

        writer.WriteBoolean(
            "exactLabelsAndIsolation",
            rows referencesSql = legacy
            && number "SELECT count(*) FROM categories" = int64 expectedDefinitions
            && number "SELECT count(*) FROM categories WHERE parent_id IS NOT NULL OR missing<>0" = 0L
        )

        writer.WriteBoolean(
            "metadataAndProfiles",
            rows metadataSql = metadata
            && rows selectionSql = selection
            && rows profilesSql = profiles
            && rows workspacesSql = workspaces
        )

        connection.Close()
        connection.Open()
        Sqlite.migrate connection

        writer.WriteBoolean(
            "stableAfterRestart",
            number "PRAGMA user_version" = 6L
            && rows "SELECT mod_id,category_id,label FROM mod_categories ORDER BY mod_id" = references
            && rows selectionSql = selection
        )

        writer.WriteEndObject()
