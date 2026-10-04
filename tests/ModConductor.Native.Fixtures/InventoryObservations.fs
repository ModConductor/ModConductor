namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.Cryptography
open System.Text
open Microsoft.Data.Sqlite
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning
open ModConductor.Platform
open ModConductor.ModOrganization
open ModConductor.Persistence

module InventoryObservations =
    let query =
        { Text = ""
          Mode = FilterMode.All
          Filters = []
          View = OrganizationView.Flat
          Sort = OrganizationSort.Priority }

    let read (store: OperationStore) profile =
        (store.ModOrganization :> IModOrganization).Query(profile, query, None, None)
        |> StorageWorker.wait
        |> StorageWorker.result

    let internal fileSelection state profile =
        use connection =
            new SqliteConnection(
                "Data Source=" + Path.Combine(state, "state.db") + ";Pooling=False"
            )

        connection.Open()

        SelectionRows.all connection null profile,
        FilePlanRows.read connection null "" profile |> StorageWorker.result

    let internal fileWinner (sources: PlanSources) path modId content =
        let input =
            { Profile = sources.Profile
              Roots =
                [ { Id = sources.Stamp.WorkspaceId
                    Policy = TargetPolicy.windows } ]
              ReadOnly = []
              Writable = [] }

        match Planner.compute input with
        | PlanningResult.Blocked _ -> false
        | PlanningResult.Ready plan ->
            (Planner.view plan).ReadOnlyFiles
            |> List.exists (fun file ->
                LogicalPath.display file.Target.Path = path
                && match file.Winner.Source with
                   | SourcePin.Mod(id, _, entry) ->
                       id = modId
                       && entry.Payload.Sha256 = Convert.ToHexStringLower(
                           SHA256.HashData(Encoding.UTF8.GetBytes(content: string))
                       )
                   | SourcePin.Snapshot _ -> false)
