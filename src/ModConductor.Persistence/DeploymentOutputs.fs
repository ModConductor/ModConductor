namespace ModConductor.Persistence

open ModConductor.Platform
open ModConductor.FilePlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations

module internal DeploymentOutputs =
    let read (database: StateDatabase) (workspace: WorkspaceRoot) (sources: PlanSources) =
        database.Enqueue(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = true)

            if
                FilePlanRows.stamp database.Connection transaction sources.Stamp.ProfileId
                <> Some sources.Stamp
            then
                Error RecoveryError.Stale
            elif OutputRows.active database.Connection transaction workspace.Id then
                Error RecoveryError.Busy
            else
                let context =
                    OutputRows.contextId workspace.Id sources.Stamp.ProfileId sources.Context

                let rows = OutputRows.locations database.Connection transaction workspace context

                let working =
                    sources.Writable
                    |> List.map (fun declaration ->
                        let row =
                            rows
                            |> List.find (fun row -> row.View.Id = declaration.Id && row.Enabled)

                        let backing =
                            OutputRows.backing workspace row
                            |> Option.defaultWith (fun () ->
                                RecoveryFiles.fail
                                    "The writable file storage has no confirmed directory identity.")

                        { Declaration = declaration.Id
                          Initialized = row.Initialized
                          Root =
                            { Path = backing.Root
                              Identity = backing.RootIdentity }
                          Path = backing.Path.Value })

                transaction.Commit()
                Ok working)

    let initialized (database: StateDatabase) (stamp: SourceStamp) (working: WorkingLocation list) =
        database.Enqueue(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = false)

            if
                FilePlanRows.stamp database.Connection transaction stamp.ProfileId <> Some stamp
            then
                Error RecoveryError.Stale
            else
                for location in working do
                    Sqlite.execute
                        database.Connection
                        transaction
                        "UPDATE output_locations SET initialized=1 WHERE id=$id AND purpose=1"
                        [ "$id", box (string location.Declaration) ]

                transaction.Commit()
                Ok())
