namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.GameContexts
open ModConductor.Bethesda
open ModConductor.Deployment
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module NewVegasViewFixtures =
    let private get task =
        task |> StorageWorker.wait |> StorageWorker.result

    let private modified path =
        match File.ResolveLinkTarget(path, true) with
        | null -> File.GetLastWriteTimeUtc path
        | target -> File.GetLastWriteTimeUtc target.FullName

    let private saveBytes () =
        use stream = new MemoryStream()
        use writer = new BinaryWriter(stream)

        let number (value: uint32) =
            writer.Write value
            writer.Write 0x7Cuy

        let text (value: string) =
            let bytes = System.Text.Encoding.UTF8.GetBytes value
            writer.Write(byte bytes.Length)
            writer.Write 0x7Cuy
            writer.Write 0x7Cuy
            writer.Write bytes
            writer.Write 0x7Cuy

        writer.Write(System.Text.Encoding.ASCII.GetBytes "FO3SAVEGAME")
        writer.Write 100u
        number 1u
        writer.Write 0x7Cuy
        number 1u
        number 1u
        number 42u
        text "Courier"
        text "Human"
        number 12u
        text "Goodsprings"
        text "001.02.03"
        writer.Write [| 0uy; 0uy; 0uy |]
        writer.Write(Array.zeroCreate<byte> 5)
        writer.Write 1uy
        writer.Write 0x7Cuy
        text "FalloutNV.esm"
        stream.ToArray()

    let private saves (store: OperationStore) workspace profile (evidence: InstallationEvidence) =
        let globalRoot =
            match evidence.Locations.Saves with
            | Location.Located(path, _) -> path
            | Location.Unavailable reason -> invalidOp reason

        let bytes = saveBytes ()
        File.WriteAllBytes(Path.Combine(globalRoot, "Courier.fos"), bytes)
        File.WriteAllText(Path.Combine(globalRoot, "Courier.nvse"), "companion")
        File.WriteAllText(Path.Combine(globalRoot, "notes.txt"), "unrelated")
        let api = store.ProfileGameData
        let current = api.Read(workspace, profile) |> get

        api.Edit(
            { Id = Guid.NewGuid()
              Expected = current.Reference
              Options = { Settings = true; Saves = true }
              InitialSaves = InitialSaves.Empty
              DisabledFiles = DisabledFiles.Keep },
            ignore,
            CancellationToken.None
        )
        |> get
        |> ignore

        let current = api.Read(workspace, profile) |> get

        let groups =
            api.SaveGroups(workspace, profile, ProfileSaveSource.Global, None) |> get

        let inspected =
            api.InspectSave(
                workspace,
                profile,
                ProfileSaveSource.Global,
                "Courier.fos",
                None,
                CancellationToken.None
            )
            |> get

        let preview =
            api.PreviewSaveAction(
                current.Reference,
                ProfileSaveAction.CopyToProfile,
                [ "Courier.fos" ],
                CancellationToken.None
            )
            |> get

        api.ApplySaveAction(
            Guid.NewGuid(),
            preview.Id,
            current.Reference,
            ignore,
            CancellationToken.None
        )
        |> get
        |> ignore

        (groups.Entries
         |> List.filter (fun entry -> entry.Kind = ProfileSaveEntryKind.Save)
         |> List.exists (fun entry ->
             entry.Name = "Courier.fos" && entry.Companion = Some "Courier.nvse"))
        && (inspected.Metadata
            |> Option.exists (fun value ->
                value.Character = "Courier" && value.FullPlugins = [ "FalloutNV.esm" ]))
        && File.ReadAllBytes(Path.Combine(current.SavesPath, "Courier.fos")) = bytes
        && File.ReadAllText(Path.Combine(current.SavesPath, "Courier.nvse")) = "companion"
        && File.ReadAllBytes(Path.Combine(globalRoot, "Courier.fos")) = bytes

    let observe (writer: Utf8JsonWriter) primary =
        let area =
            Directory.CreateDirectory(Path.Combine(primary, "new-vegas-view")).FullName

        let game, proton =
            ProtonFixtures.createFor NewVegas.definition true (Path.Combine(area, "installation"))

        let data = Path.Combine(game, "Data")
        let names = [ "FalloutNV.esm"; "DeadMoney.esm"; "First.esp"; "Second.esp" ]

        for name in names do
            File.WriteAllBytes(
                Path.Combine(data, name),
                BethesdaSamples.header (if name.EndsWith ".esm" then 1u else 0u) 1.34f [] false
            )

        File.SetLastWriteTimeUtc(
            Path.Combine(data, "First.esp"),
            DateTime(2005, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        )

        File.SetLastWriteTimeUtc(
            Path.Combine(data, "Second.esp"),
            DateTime(2010, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        )

        File.WriteAllText(Path.Combine(data, "untouched.txt"), "linked asset")

        let original =
            names
            |> List.map (fun name ->
                name,
                File.ReadAllBytes(Path.Combine(data, name)),
                modified (Path.Combine(data, name)))

        let workspace, first, second = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        use store = new OperationStore(Path.Combine(area, "state"))
        let ws = store.Workspaces :> IWorkspaceState

        let created =
            ws.Create(
                workspace,
                "New Vegas",
                StorageWorker.select (
                    Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
                )
            )
            |> get

        let mutable revision = created.Workspace.Revision

        for profile in [ first; second ] do
            let changed =
                ws.Edit(
                    workspace,
                    revision,
                    ProfileEdit.Create { Id = profile; Name = string profile }
                )
                |> get

            revision <- changed.Workspace.Revision

            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    profile,
                    0L,
                    { GameId = NewVegas.definition.Id
                      Path = game
                      Proton = Some proton
                      Wine = None }
                )
            |> get
            |> ignore

        let context = (store.GameContexts :> IGameContexts).Read(workspace, first) |> get

        let local =
            match context.Binding.Value.Evidence.Locations.LocalAppData with
            | Location.Located(path, _) -> path
            | Location.Unavailable reason -> invalidOp reason

        let docs =
            match context.Binding.Value.Evidence.Locations.Documents with
            | Location.Located(path, _) -> path
            | Location.Unavailable reason -> invalidOp reason

        Directory.CreateDirectory local |> ignore
        Directory.CreateDirectory docs |> ignore
        File.WriteAllText(Path.Combine(local, "plugins.txt"), "Second.esp\r\nFirst.esp\r\n")

        File.WriteAllText(
            Path.Combine(local, "loadorder.txt"),
            "FalloutNV.esm\r\nDeadMoney.esm\r\nSecond.esp\r\nFirst.esp\r\n"
        )

        File.WriteAllText(
            Path.Combine(docs, "Fallout.ini"),
            "[Archive]\r\nSArchiveList=Fallout - Invalidation.bsa\r\nbInvalidateOlderFiles=1\r\nSInvalidationFile=\r\n"
        )

        let saveCheck = saves store workspace first context.Binding.Value.Evidence

        let headers profile =
            store.Plugins.Scan(profile, CancellationToken.None) |> get

        let fresh = headers first
        let current = store.PluginOrders.Read(workspace, first, fresh.Id) |> get

        let changed =
            store.PluginOrders.Change(
                current.Reference,
                fresh.Id,
                PluginOrderChange.Replace
                    [ "FalloutNV.esm"; "DeadMoney.esm"; "Second.esp"; "First.esp" ]
            )
            |> get

        let deploy profile =
            let status = store.Deployments.Read profile |> get

            let prepared =
                store.Deployments.Prepare(
                    Guid.NewGuid(),
                    status.Sources,
                    ignore,
                    CancellationToken.None
                )
                |> get

            let active =
                store.Deployments.Activate(
                    prepared.Id,
                    prepared.Sources,
                    ignore,
                    CancellationToken.None
                )
                |> get

            if active.Phase <> DeploymentPhase.Complete then
                invalidOp "New Vegas deployment did not finish."

            status.RunnableRoot, prepared

        let firstRoot, firstPrepared = deploy first
        let firstFile = Path.Combine(firstRoot, "Data", "First.esp")
        let secondFile = Path.Combine(firstRoot, "Data", "Second.esp")
        let firstTime = modified firstFile
        let secondTime = modified secondFile
        let firstBacking = File.ResolveLinkTarget(firstFile, true).FullName
        let _, repeatPrepared = deploy first
        let reused = File.ResolveLinkTarget(firstFile, true).FullName = firstBacking
        let secondRoot, _ = deploy second
        let secondFirst = modified (Path.Combine(secondRoot, "Data", "First.esp"))
        let secondSecond = modified (Path.Combine(secondRoot, "Data", "Second.esp"))
        let laterHeaders = headers first
        let later = store.PluginOrders.Read(workspace, first, laterHeaders.Id) |> get

        store.PluginOrders.Change(
            later.Reference,
            laterHeaders.Id,
            PluginOrderChange.Replace
                [ "FalloutNV.esm"; "DeadMoney.esm"; "First.esp"; "Second.esp" ]
        )
        |> get
        |> ignore

        deploy first |> ignore
        writer.WriteStartObject "newVegasView"

        let check (name: string) (condition: bool) =
            writer.WriteBoolean(name, condition)

            if not condition then
                invalidOp ("New Vegas fixture failed: " + name)

        check "nvSaveAndCompanionRoundtrip" saveCheck
        check "pe32Installation" context.Binding.Value.Evidence.Valid

        check
            "plainActivation"
            (current.View.Order.Entries
             |> List.filter (fun row -> row.Name.EndsWith ".esp")
             |> List.forall (fun row -> row.Enabled = Some true))

        check
            "sourceTimestampsOverrideTextOrder"
            ((current.View.Order.Entries
              |> List.filter (fun row -> row.Name.EndsWith ".esp")
              |> List.map _.Name) = [ "First.esp"; "Second.esp" ])

        check "profileTimestampOrder" (secondTime < firstTime && secondFirst < secondSecond)

        check
            "unchangedBackingReused"
            (reused && repeatPrepared.CopiedBytes = 0L && firstPrepared.CopiedBytes > 0L)

        check
            "previousBackingNotRetimestamped"
            (modified firstBacking = firstTime
             && File.ResolveLinkTarget(firstFile, true).FullName <> firstBacking)

        check
            "otherProfileUnchanged"
            (modified (Path.Combine(secondRoot, "Data", "First.esp")) = secondFirst)

        check
            "sourcesUnchanged"
            (original
             |> List.forall (fun (name, bytes, time) ->
                 bytes = File.ReadAllBytes(Path.Combine(data, name))
                 && time = modified (Path.Combine(data, name))))

        check
            "otherAssetsLinked"
            (File.ResolveLinkTarget(Path.Combine(firstRoot, "Data", "untouched.txt"), true).FullName = Path
                .Combine(data, "untouched.txt"))

        check
            "invalidationOwned"
            (File.Exists(Path.Combine(firstRoot, "Data", "Fallout - Invalidation.bsa"))
             && not (File.Exists(Path.Combine(data, "Fallout - Invalidation.bsa"))))

        use stop = new CancellationTokenSource()
        stop.Cancel()
        let state = store.Deployments.Read first |> get

        check
            "cancelledBeforeCopy"
            (store.Deployments.Prepare(Guid.NewGuid(), state.Sources, ignore, stop.Token)
             |> StorageWorker.wait = Error DeploymentError.Cancelled)

        writer.WriteEndObject()
