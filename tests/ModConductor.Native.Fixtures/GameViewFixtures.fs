namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open Microsoft.Data.Sqlite
open ModConductor.Bethesda
open ModConductor.Deployment
open ModConductor.DeploymentRecovery
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module GameViewFixtures =
    let private wait = StorageWorker.wait

    let private result value =
        value
        |> Result.defaultWith (fun error ->
            let detail =
                match box error with
                | :? ProfileDataError as value ->
                    match value with
                    | ProfileDataError.Invalid text
                    | ProfileDataError.Unavailable text
                    | ProfileDataError.Conflict text -> text
                    | _ -> string value
                | :? DeploymentError as value ->
                    match value with
                    | DeploymentError.Blocked text
                    | DeploymentError.Unavailable text -> text
                    | DeploymentError.Stale -> "Deployment stale"
                    | DeploymentError.Busy -> "Deployment busy"
                    | DeploymentError.NotFound -> "Deployment not found"
                    | DeploymentError.Cancelled -> "Deployment cancelled"
                | :? WorkspaceError as value ->
                    match value with
                    | WorkspaceError.ProfileData detail -> detail
                    | _ -> string value
                | _ -> string error

            invalidOp detail)

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "game-view")).FullName

        let workspacePath =
            Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

        let game, proton = ProtonFixtures.create (Path.Combine(area, "installation"))
        let data = Path.Combine(game, "Data")
        let baseHeader = BethesdaSamples.header 1u 1.7f [] false

        for name in OrderRules.baseFiles @ [ "ccBGSSSE001-Fish.esm" ] do
            File.WriteAllBytes(Path.Combine(data, name), baseHeader)

        File.WriteAllText(Path.Combine(game, "Skyrim.ccc"), "ccBGSSSE001-Fish.esm\r\n")
        let originalExecutable = File.ReadAllBytes(Path.Combine(game, "SkyrimSE.exe"))
        let workspace, first, second = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        use store = new OperationStore(Path.Combine(area, "state"))
        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "Game view", StorageWorker.select workspacePath)
            |> wait
            |> result

        let mutable revision = created.Workspace.Revision

        for id, name in [ first, "Off"; second, "On" ] do
            let changed =
                workspaces.Edit(workspace, revision, ProfileEdit.Create { Id = id; Name = name })
                |> wait
                |> result

            revision <- changed.Workspace.Revision

            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    id,
                    0L,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Proton = if OperatingSystem.IsLinux() then Some proton else None }
                )
            |> wait
            |> result
            |> ignore

        let selected =
            (store.GameContexts :> IGameContexts).Read(workspace, first) |> wait |> result

        for location in
            [ selected.Binding.Value.Evidence.Locations.Documents
              selected.Binding.Value.Evidence.Locations.LocalAppData ] do
            match location with
            | Location.Located(path, _) -> Directory.CreateDirectory path |> ignore
            | Location.Unavailable reason -> invalidOp reason

        let headers = store.Plugins.Scan(first, CancellationToken.None) |> wait |> result
        let orders = store.PluginOrders
        let mutable off = orders.Read(workspace, first, headers.Id) |> wait |> result

        for name in [ "Dawnguard.esm"; "ccBGSSSE001-Fish.esm" ] do
            off <-
                orders.Change(off.Reference, headers.Id, PluginOrderChange.Enable([ name ], false))
                |> wait
                |> result

        let backend = store.Deployments

        let deploy profile =
            let state = backend.Read profile |> wait |> result

            let prepared =
                backend.Prepare(Guid.NewGuid(), state.Sources, ignore, CancellationToken.None)
                |> wait
                |> result

            let active =
                backend.Activate(prepared.Id, prepared.Sources, ignore, CancellationToken.None)
                |> wait
                |> result

            if active.Phase <> DeploymentPhase.Complete then
                invalidOp "The profile game view did not activate."

            state.RunnableRoot

        let offRoot = deploy first
        let offData = Path.Combine(offRoot, "Data")

        let offExcludes =
            not (File.Exists(Path.Combine(offData, "Dawnguard.esm")))
            && not (File.Exists(Path.Combine(offData, "ccBGSSSE001-Fish.esm")))
            && File.Exists(Path.Combine(offData, "Skyrim.esm"))
            && File.ReadAllText(Path.Combine(offRoot, "Skyrim.ccc")) = ""

        let onRoot = deploy second
        let onData = Path.Combine(onRoot, "Data")

        let onIncludes =
            File.Exists(Path.Combine(onData, "Dawnguard.esm"))
            && File.Exists(Path.Combine(onData, "ccBGSSSE001-Fish.esm"))
            && File.ReadAllText(Path.Combine(onRoot, "Skyrim.ccc")) = "ccBGSSSE001-Fish.esm\r\n"

        let onHeaders = store.Plugins.Scan(second, CancellationToken.None) |> wait |> result
        let onOrder = orders.Read(workspace, second, onHeaders.Id) |> wait |> result

        let projected order =
            store.LootProjectionForFixture(order, CancellationToken.None)
            |> Async.StartAsTask
            |> wait
            |> result

        let offStage, offGame, _ = projected off
        let onStage, onGame, _ = projected onOrder

        let lootProjectionMatchesView =
            not (File.Exists(Path.Combine(offGame, "Data", "Dawnguard.esm")))
            && not (File.Exists(Path.Combine(offGame, "Data", "ccBGSSSE001-Fish.esm")))
            && File.Exists(Path.Combine(offGame, "Data", "Skyrim.esm"))
            && File.ReadAllText(Path.Combine(offGame, "Skyrim.ccc")) = ""
            && File.Exists(Path.Combine(onGame, "Data", "Dawnguard.esm"))
            && File.Exists(Path.Combine(onGame, "Data", "ccBGSSSE001-Fish.esm"))
            && File.ReadAllText(Path.Combine(onGame, "Skyrim.ccc")) = "ccBGSSSE001-Fish.esm\r\n"

        Directory.Delete(offStage, true)
        Directory.Delete(onStage, true)

        let contextId =
            DeploymentContextId.create
                workspace
                first
                (DeploymentContextId.fingerprint selected.Binding.Value.Evidence)

        let active = (store.Deployment.Context contextId |> wait).Value

        let generation =
            (store.Deployment.Generation(contextId, active.Active.Value) |> wait).Value

        let sample = generation.Files.Head

        let logical parts =
            LogicalPath.create parts
            |> Result.defaultWith (fun _ -> invalidOp "Invalid scale path.")

        let synthetic nested =
            { generation with
                Files =
                    [ for index in 1..4200 ->
                          let target =
                              if nested then
                                  logical [ "Scripts"; "file" + index.ToString("D4") + ".txt" ]
                              else
                                  logical [ "file" + index.ToString("D4") + ".txt" ]

                          { sample with
                              Target = { sample.Target with Path = target } } ]
                Observed = []
                Working = []
                Writable = [] }

        let direct = synthetic false
        let nested = synthetic true

        let directBoundaries =
            PhysicalTargets.boundaries TargetPolicy.windows [] [] direct CancellationToken.None

        let nestedBoundaries =
            PhysicalTargets.boundaries TargetPolicy.windows [] [] nested CancellationToken.None

        let scaleBound =
            directBoundaries.IsEmpty
            && direct.Files.Length > 4096
            && nestedBoundaries.Length = 1
            && LogicalPath.display nestedBoundaries.Head.Path = "Scripts"

        let local =
            let state =
                (store.GameContexts :> IGameContexts).Read(workspace, first) |> wait |> result

            match state.Binding.Value.Evidence.Locations.LocalAppData with
            | Location.Located(path, _) -> path
            | Location.Unavailable reason -> invalidOp reason

        Directory.CreateDirectory local |> ignore
        File.WriteAllText(Path.Combine(local, "Plugins.txt"), "# Skyrim.esm\r\n# Update.esm\r\n")
        let fresh = store.Plugins.Scan(first, CancellationToken.None) |> wait |> result
        let retained = orders.Read(workspace, first, fresh.Id) |> wait |> result

        let stillOff =
            retained.View.Order.Entries
            |> List.filter (fun row ->
                row.Name = "Dawnguard.esm" || row.Name = "ccBGSSSE001-Fish.esm")
            |> List.forall (fun row -> row.Enabled = Some false)

        let switched =
            workspaces.Edit(workspace, revision, ProfileEdit.Select second)
            |> wait
            |> result

        let unowned = Path.Combine(offRoot, "unowned.log")
        File.WriteAllText(unowned, "disposable game log")

        let deleted =
            workspaces.Edit(workspace, switched.Workspace.Revision, ProfileEdit.Delete first)
            |> wait
            |> result

        let deletionRetiresOwnedView =
            deleted.Deleted = Some first
            && not (Directory.Exists offRoot)
            && not (File.Exists unowned)
            && Directory.Exists onRoot
            && File.Exists(Path.Combine(data, "Dawnguard.esm"))

        use db =
            new SqliteConnection(
                "Data Source=" + Path.Combine(area, "state", "state.db") + ";Pooling=False"
            )

        db.Open()

        let remaining table predicate =
            use query = db.CreateCommand()

            query.CommandText <-
                "SELECT COUNT(*) FROM " + table + " WHERE " + predicate + "=$context"

            query.Parameters.AddWithValue("$context", string contextId) |> ignore
            query.ExecuteScalar() :?> int64

        let deletionRemovesOwnedHistory =
            remaining "deployment_contexts" "id" = 0L
            && remaining "deployment_generations" "context_id" = 0L
            && remaining "deployment_receipts" "context_id" = 0L
            && not (
                Directory.Exists(Path.GetDirectoryName(HostPath.value generation.Directory.Path))
            )

        writer.WriteStartObject("gameView")
        writer.WriteBoolean("offExcludesDlcAndCreation", offExcludes)
        writer.WriteBoolean("otherProfileIncludesDlcAndCreation", onIncludes)
        writer.WriteBoolean("gameListRewriteKeepsSelection", stillOff)
        writer.WriteBoolean("lootProjectionMatchesView", lootProjectionMatchesView)
        writer.WriteBoolean("nestedLayoutAggregatesButDirectRootLimitRemains", scaleBound)
        writer.WriteBoolean("derivedViewFileRemovedOnDeletion", not (File.Exists unowned))
        writer.WriteBoolean("deletionRetiresOwnedView", deletionRetiresOwnedView)
        writer.WriteBoolean("deletionRemovesOwnedHistoryAndTree", deletionRemovesOwnedHistory)

        writer.WriteBoolean(
            "originalInstallationUntouched",
            File.ReadAllBytes(Path.Combine(game, "SkyrimSE.exe")) = originalExecutable
            && File.Exists(Path.Combine(data, "Dawnguard.esm"))
        )

        writer.WriteEndObject()
