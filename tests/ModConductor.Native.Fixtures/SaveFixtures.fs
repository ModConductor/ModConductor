namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Text.Json
open System.Threading
open K4os.Compression.LZ4
open ModConductor.Bethesda
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module SaveFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private writeString (writer: BinaryWriter) (value: string) =
        let bytes = Encoding.UTF8.GetBytes value
        writer.Write(uint16 bytes.Length)
        writer.Write bytes

    let private pluginInfo (full: string list) (light: string list) =
        use stream = new MemoryStream()
        use writer = new BinaryWriter(stream, Encoding.UTF8, true)
        writer.Write(byte full.Length)
        full |> List.iter (writeString writer)
        writer.Write(uint16 light.Length)
        light |> List.iter (writeString writer)
        stream.ToArray()

    let private body (full: string list) (light: string list) =
        let info = pluginInfo full light
        use stream = new MemoryStream()
        use writer = new BinaryWriter(stream, Encoding.UTF8, true)
        writer.Write(78uy)
        writer.Write(uint32 info.Length)
        writer.Write info
        // The reader intentionally stops at the qualified metadata prefix.
        writer.Write(Array.create 64 0x5Auy)
        stream.ToArray()

    let private encoded compression (bytes: byte array) =
        match compression with
        | SkyrimSaveCompression.Uncompressed -> bytes
        | SkyrimSaveCompression.Zlib ->
            use stream = new MemoryStream()
            use compressed = new ZLibStream(stream, CompressionLevel.SmallestSize, true)
            compressed.Write bytes
            compressed.Dispose()
            stream.ToArray()
        | SkyrimSaveCompression.Lz4 ->
            let target = Array.zeroCreate<byte> (LZ4Codec.MaximumOutputSize bytes.Length)
            let length = LZ4Codec.Encode(bytes.AsSpan(), target.AsSpan())
            target[.. length - 1]

    let private save compression (full: string list) (light: string list) =
        let body = body full light
        let encoded = encoded compression body
        use header = new MemoryStream()
        use fields = new BinaryWriter(header, Encoding.UTF8, true)
        fields.Write 12u
        fields.Write 42u
        writeString fields "Aela"
        fields.Write 37u
        writeString fields "Whiterun"
        writeString fields "12.34.56"
        writeString fields "NordRace"
        fields.Write 1us
        fields.Write 120u
        fields.Write 200u
        fields.Write 0UL
        fields.Write 0u
        fields.Write 0u

        fields.Write(
            match compression with
            | SkyrimSaveCompression.Uncompressed -> 0us
            | SkyrimSaveCompression.Zlib -> 1us
            | SkyrimSaveCompression.Lz4 -> 2us
        )

        let headerBytes = header.ToArray()
        use stream = new MemoryStream()
        use writer = new BinaryWriter(stream, Encoding.UTF8, true)
        writer.Write(Encoding.ASCII.GetBytes "TESV_SAVEGAME")
        writer.Write(uint32 headerBytes.Length)
        writer.Write headerBytes

        if compression <> SkyrimSaveCompression.Uncompressed then
            writer.Write(uint32 body.Length)
            writer.Write(uint32 encoded.Length)

        writer.Write encoded
        stream.ToArray()

    let private metadata bytes =
        use stream = new MemoryStream(bytes, false)
        SkyrimSaveReader.read stream token

    let samples (writer: Utf8JsonWriter) directory =
        writer.WriteStartObject "publicSaveSamples"

        for name, compression in
            [ "uncompressed.ess", SkyrimSaveCompression.Uncompressed
              "zlib.ess", SkyrimSaveCompression.Zlib
              "lz4.ess", SkyrimSaveCompression.Lz4 ] do
            use stream = File.OpenRead(Path.Combine(directory, name))

            match SkyrimSaveReader.read stream token with
            | Error error -> invalidOp (name + " failed: " + error.ToString())
            | Ok value ->
                writer.WriteStartObject(name)
                writer.WriteBoolean("matchedCompression", value.Compression = compression)
                writer.WriteNumber("headerVersion", value.HeaderVersion)
                writer.WriteNumber("formVersion", uint32 value.FormVersion)
                writer.WriteNumber("fullPlugins", value.FullPlugins.Length)
                writer.WriteNumber("lightPlugins", value.LightPlugins.Length)
                writer.WriteEndObject()

        writer.WriteEndObject()

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject "saveManagement"

        let check (name: string) (condition: bool) =
            writer.WriteBoolean(name, condition)
            writer.Flush()

            if not condition then
                invalidOp ("Save fixture failed: " + name)

        let plugins = [ "Skyrim.esm"; "Inactive.esp"; "Missing.esp" ]
        let light = [ "Light.esl" ]

        for compression in
            [ SkyrimSaveCompression.Uncompressed
              SkyrimSaveCompression.Zlib
              SkyrimSaveCompression.Lz4 ] do
            match metadata (save compression plugins light) with
            | Ok value ->
                let name =
                    match compression with
                    | SkyrimSaveCompression.Uncompressed -> "parserUncompressed"
                    | SkyrimSaveCompression.Zlib -> "parserZlib"
                    | SkyrimSaveCompression.Lz4 -> "parserLz4"

                check
                    name
                    (value.HeaderVersion = 12u
                     && value.FormVersion = 78uy
                     && value.Compression = compression
                     && value.Character = "Aela"
                     && value.Level = 37u
                     && value.Location = "Whiterun"
                     && value.FullPlugins = plugins
                     && value.LightPlugins = light)
            | Error error -> invalidOp ("Synthetic save parse failed: " + error.ToString())

        let malformed = save SkyrimSaveCompression.Lz4 plugins light
        malformed[0] <- byte 'X'

        check
            "malformedMetadataIsBounded"
            (match metadata malformed with
             | Error(SkyrimSaveError.Malformed _) -> true
             | _ -> false)

        let area =
            Directory.CreateDirectory(Path.Combine(primary, "save-management")).FullName

        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
        let data = Path.Combine(game, "Data")

        for name in OrderRules.baseFiles do
            File.WriteAllBytes(Path.Combine(data, name), BethesdaSamples.header 1u 1.7f [] false)

        File.WriteAllBytes(
            Path.Combine(data, "Inactive.esp"),
            BethesdaSamples.header 0u 1.7f [ "Skyrim.esm" ] false
        )

        File.WriteAllBytes(
            Path.Combine(data, "Light.esl"),
            BethesdaSamples.header 0x200u 1.7f [ "Skyrim.esm" ] false
        )

        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let mutable store = new OperationStore(Path.Combine(area, "state"))

        use lifetime =
            { new IDisposable with
                member _.Dispose() = (store :> IDisposable).Dispose() }

        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "Save management", StorageWorker.select root)
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Private" }
        )
        |> wait
        |> result
        |> ignore

        let context =
            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    profile,
                    0L,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Proton = Some proton }
                )
            |> wait
            |> result

        let documents =
            match context.Binding.Value.Evidence.Locations.Documents with
            | Location.Located(path, _) -> path
            | Location.Unavailable problem -> invalidOp problem

        let globalPath =
            Directory.CreateDirectory(Path.Combine(documents, "Saves")).FullName

        let local =
            match context.Binding.Value.Evidence.Locations.LocalAppData with
            | Location.Located(path, _) -> Directory.CreateDirectory(path).FullName
            | Location.Unavailable problem -> invalidOp problem

        File.WriteAllText(Path.Combine(local, "plugins.txt"), "Inactive.esp\n")
        let saveBytes = save SkyrimSaveCompression.Lz4 plugins light
        let companionBytes = Encoding.UTF8.GetBytes "grouped extender data"
        File.WriteAllBytes(Path.Combine(globalPath, "transfer.ess"), saveBytes)
        File.WriteAllBytes(Path.Combine(globalPath, "transfer.skse"), companionBytes)
        File.WriteAllText(Path.Combine(globalPath, "broken.ess"), "not a save")
        File.WriteAllText(Path.Combine(globalPath, "notes.txt"), "unknown file")
        File.WriteAllText(Path.Combine(globalPath, "steam_autocloud.vdf"), "cloud marker")
        File.WriteAllBytes(Path.Combine(globalPath, "unsafe.ess"), saveBytes)
        Directory.CreateDirectory(Path.Combine(globalPath, "unsafe.skse")) |> ignore

        let mutable api = store.ProfileGameData
        let initial = api.Read(workspace, profile) |> wait |> result

        let enabled =
            api.Edit(
                { Id = Guid.NewGuid()
                  Expected = initial.Reference
                  Options = { Settings = false; Saves = true }
                  InitialSaves = InitialSaves.Empty
                  DisabledFiles = DisabledFiles.Keep },
                ignore,
                token
            )
            |> wait
            |> result

        let page =
            api.SaveGroups(workspace, profile, ProfileSaveSource.Global, None)
            |> wait
            |> result

        let transfer = page.Entries |> List.find (fun row -> row.Name = "transfer.ess")
        let broken = page.Entries |> List.find (fun row -> row.Name = "broken.ess")
        let unsafe = page.Entries |> List.find (fun row -> row.Name = "unsafe.ess")

        check
            "listingGroupsCompanionAndKeepsOpaqueRows"
            (transfer.Companion = Some "transfer.skse"
             && transfer.Actionable
             && broken.Actionable
             && page.Entries |> List.exists (fun row -> row.Name = "notes.txt")
             && page.Entries |> List.exists (fun row -> row.Name = "steam_autocloud.vdf"))

        check
            "nonFileCompanionMakesGroupUnactionable"
            (not unsafe.Actionable
             && unsafe.Companion.IsNone
             && unsafe.Problem.IsSome
             && page.Entries |> List.exists (fun row -> row.Name = "unsafe.skse"))

        let brokenInspection =
            api.InspectSave(workspace, profile, ProfileSaveSource.Global, broken.Name, None, token)
            |> wait
            |> result

        check
            "parseFailureDoesNotHideSave"
            (brokenInspection.Metadata.IsNone && brokenInspection.MetadataProblem.IsSome)

        let headers = store.Plugins.Scan(profile, token) |> wait |> result

        let inspection =
            api.InspectSave(
                workspace,
                profile,
                ProfileSaveSource.Global,
                transfer.Name,
                Some headers.Id,
                token
            )
            |> wait
            |> result

        check
            "qualifiedSnapshotReportsMissingAndInactivePlugins"
            (inspection.Metadata.IsSome
             && inspection.PluginCheckProblem.IsNone
             && inspection.PluginIssues
                |> List.exists (fun issue ->
                    issue.Name = "Missing.esp" && issue.State = SavePluginState.Missing)
             && inspection.PluginIssues
                |> List.exists (fun issue ->
                    issue.Name = "Inactive.esp" && issue.State = SavePluginState.Inactive))

        let order =
            store.PluginOrders.Read(workspace, profile, headers.Id) |> wait |> result

        let parsedMetadata =
            match metadata saveBytes with
            | Ok value -> value
            | Error error -> invalidOp ("Synthetic save parse failed: " + error.ToString())

        let ambiguousOrder =
            { order with
                Headers =
                    { order.Headers with
                        Entries =
                            order.Headers.Entries
                            |> List.map (fun entry ->
                                if
                                    entry.Name.Equals(
                                        "Inactive.esp",
                                        StringComparison.OrdinalIgnoreCase
                                    )
                                then
                                    { entry with
                                        Winner = None
                                        Ambiguity = Some "The selected source is ambiguous." }
                                else
                                    entry) } }

        let ambiguousIssues, ambiguousProblem =
            SaveDiagnostics.check ambiguousOrder parsedMetadata

        check
            "ambiguousRelevantPluginSuppressesDiagnostics"
            (ambiguousIssues.IsEmpty && ambiguousProblem.IsSome)

        let indeterminateOrder =
            { order with
                View =
                    { order.View with
                        Order =
                            { order.View.Order with
                                Entries =
                                    order.View.Order.Entries
                                    |> List.map (fun entry ->
                                        if
                                            entry.Name.Equals(
                                                "Inactive.esp",
                                                StringComparison.OrdinalIgnoreCase
                                            )
                                        then
                                            { entry with Enabled = None }
                                        else
                                            entry) } } }

        let indeterminateIssues, indeterminateProblem =
            SaveDiagnostics.check indeterminateOrder parsedMetadata

        check
            "indeterminateRelevantPluginSuppressesDiagnostics"
            (indeterminateIssues.IsEmpty && indeterminateProblem.IsSome)

        let preview action names expected =
            api.PreviewSaveAction(expected, action, names, token) |> wait |> result

        let apply (preview: ProfileSaveActionPreview) expected =
            api.ApplySaveAction(Guid.NewGuid(), preview.Id, expected, ignore, token) |> wait

        let first =
            preview ProfileSaveAction.CopyToProfile [ transfer.Name ] enabled.State.Reference

        File.WriteAllText(Path.Combine(globalPath, "transfer.skse"), "changed after preview")
        let refused = apply first enabled.State.Reference

        check
            "changedCompanionRefusesWholeTransfer"
            (refused = Error(ProfileDataError.Conflict "transfer.skse changed.")
             && not (File.Exists(Path.Combine(enabled.State.SavesPath, "transfer.ess")))
             && not (File.Exists(Path.Combine(enabled.State.SavesPath, "transfer.skse"))))

        File.WriteAllBytes(Path.Combine(globalPath, "transfer.skse"), companionBytes)

        let copy =
            preview ProfileSaveAction.CopyToProfile [ transfer.Name ] enabled.State.Reference

        let copied = apply copy enabled.State.Reference |> result

        check
            "explicitTransferCopiesWholeGroupOnly"
            (copied.Complete
             && File.ReadAllBytes(Path.Combine(copied.State.SavesPath, "transfer.ess")) = saveBytes
             && File.ReadAllBytes(Path.Combine(copied.State.SavesPath, "transfer.skse")) = companionBytes
             && File.ReadAllBytes(Path.Combine(globalPath, "transfer.ess")) = saveBytes
             && File.ReadAllText(Path.Combine(globalPath, "steam_autocloud.vdf")) = "cloud marker")

        File.WriteAllText(Path.Combine(copied.State.SavesPath, "profile-note.txt"), "keep")

        File.WriteAllText(
            Path.Combine(copied.State.SavesPath, "steam_autocloud.vdf"),
            "keep cloud marker"
        )

        let interrupted =
            preview ProfileSaveAction.DeleteFromProfile [ transfer.Name ] copied.State.Reference

        let interruptedId = Guid.NewGuid()
        use cancellation = new CancellationTokenSource()

        let interruptedResult =
            api.ApplySaveAction(
                interruptedId,
                interrupted.Id,
                copied.State.Reference,
                (fun progress ->
                    if progress.Files = 1 then
                        cancellation.Cancel()),
                cancellation.Token
            )
            |> wait
            |> result

        check
            "cancelledGroupDeleteRetainsRecoverableReceipt"
            (not interruptedResult.Complete
             && interruptedResult.State.Pending = Some interruptedId
             && not (File.Exists(Path.Combine(copied.State.SavesPath, "transfer.ess")))
             && File.Exists(Path.Combine(copied.State.SavesPath, "transfer.skse")))

        (store :> IDisposable).Dispose()
        store <- new OperationStore(Path.Combine(area, "state"))
        api <- store.ProfileGameData
        let contexts = store.GameContexts :> IGameContexts
        let currentContext = contexts.Read(workspace, profile) |> wait |> result

        contexts.Refresh(workspace, profile, currentContext.Revision)
        |> wait
        |> result
        |> ignore

        let resumed = api.Resume(workspace, interruptedId, token) |> wait |> result

        check
            "restartResumesWholeGroupDelete"
            (resumed.Complete
             && resumed.State.Pending.IsNone
             && not (File.Exists(Path.Combine(resumed.State.SavesPath, "transfer.skse"))))

        let replacement =
            preview ProfileSaveAction.CopyToProfile [ transfer.Name ] resumed.State.Reference

        let copied = apply replacement resumed.State.Reference |> result

        let deletion =
            preview ProfileSaveAction.DeleteFromProfile [ transfer.Name ] copied.State.Reference

        File.WriteAllText(
            Path.Combine(copied.State.SavesPath, "transfer.ess"),
            "changed after preview"
        )

        let refusedDelete = apply deletion copied.State.Reference

        check
            "changedSaveRefusesWholeDelete"
            (match refusedDelete with
             | Error(ProfileDataError.Conflict _) ->
                 File.Exists(Path.Combine(copied.State.SavesPath, "transfer.ess"))
                 && File.Exists(Path.Combine(copied.State.SavesPath, "transfer.skse"))
             | _ -> false)

        File.WriteAllBytes(Path.Combine(copied.State.SavesPath, "transfer.ess"), saveBytes)

        let deletion =
            preview ProfileSaveAction.DeleteFromProfile [ transfer.Name ] copied.State.Reference

        let deleted = apply deletion copied.State.Reference |> result

        check
            "explicitDeleteRemovesOnlyProfileGroup"
            (deleted.Complete
             && not (File.Exists(Path.Combine(deleted.State.SavesPath, "transfer.ess")))
             && not (File.Exists(Path.Combine(deleted.State.SavesPath, "transfer.skse")))
             && File.ReadAllText(Path.Combine(deleted.State.SavesPath, "profile-note.txt")) = "keep"
             && File.ReadAllText(Path.Combine(deleted.State.SavesPath, "steam_autocloud.vdf")) = "keep cloud marker"
             && File.ReadAllBytes(Path.Combine(globalPath, "transfer.ess")) = saveBytes)

        let superseded =
            preview ProfileSaveAction.CopyToProfile [ transfer.Name ] deleted.State.Reference

        let current =
            preview ProfileSaveAction.CopyToProfile [ transfer.Name ] deleted.State.Reference

        let supersededResult = apply superseded deleted.State.Reference
        let currentResult = apply current deleted.State.Reference |> result

        check
            "secondPreviewStalesFirstAndApplies"
            (supersededResult = Error ProfileDataError.Stale
             && currentResult.Complete
             && File.ReadAllBytes(Path.Combine(currentResult.State.SavesPath, "transfer.ess")) = saveBytes
             && store.RetainedProfileSavePreviewCount = 0)

        let mutable repeated = currentResult

        for index in 1..66 do
            let action =
                if index % 2 = 1 then
                    ProfileSaveAction.DeleteFromProfile
                else
                    ProfileSaveAction.CopyToProfile

            let next = preview action [ transfer.Name ] repeated.State.Reference
            repeated <- apply next repeated.State.Reference |> result

            if not repeated.Complete then
                invalidOp "A repeated save action did not complete."

        check
            "repeatedCompletionKeepsPreviewStateBounded"
            (store.RetainedProfileSavePreviewCount = 0)

        writer.WriteEndObject()
