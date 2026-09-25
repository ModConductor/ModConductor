namespace ModConductor.Persistence

open System
open ModConductor.Deployment
open ModConductor.DeploymentRecovery

module internal SavedDeployments =
    let profile (value: SavedProfile) : DeploymentProfile =
        { Id = value.Id
          Name = value.Name
          Revision = value.Revision
          EnabledMods = value.Mods |> List.filter _.Enabled |> List.length }

    let describe active (unavailable: string option) (generation: Generation) : SavedDeployment =
        { Id = generation.Id
          PreparedAt = generation.Provenance |> Option.map _.PreparedAt
          Profile = generation.Provenance |> Option.bind _.Profile |> Option.map profile
          Known = generation.Provenance.IsSome
          Active = active = Some generation.Id
          Fingerprint = generation.PlanFingerprint
          CanRestore = generation.Provenance.IsSome && unavailable.IsNone
          Unavailable = unavailable }

    let page (connection: Microsoft.Data.Sqlite.SqliteConnection) context active before =
        use transaction = connection.BeginTransaction(deferred = true)

        use query =
            Sqlite.command
                connection
                transaction
                "SELECT rowid,id FROM deployment_generations WHERE context_id=$context AND saved=1 AND ($before IS NULL OR rowid<$before) ORDER BY rowid DESC LIMIT 33"
                [ "$context", box (string context)
                  "$before", before |> Option.map box |> Option.defaultValue (box DBNull.Value) ]

        use reader = query.ExecuteReader()

        let ids =
            [ while reader.Read() do
                  yield reader.GetInt64 0, Guid.Parse(reader.GetString 1) ]

        reader.Close()

        let entries =
            ids
            |> List.truncate 32
            |> List.map (fun (_, id) ->
                DeploymentRows.generation connection transaction context id
                |> Option.defaultWith (fun () -> raise (RecoveryException RecoveryError.NotFound))
                |> describe
                    active
                    (MaintenanceClaims.unavailable connection transaction context id))

        transaction.Commit()

        { Entries = entries
          NextBefore = if ids.Length > 32 then Some(fst ids[31]) else None }
