namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.Bethesda
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning
open ModConductor.Persistence
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.GameContexts
open ModConductor.Workspaces

module BethesdaFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private path name = LogicalPath.create [ name ] |> result
    let private token = CancellationToken.None

    let private metadata name =
        { Name = name
          Version = "1.5"
          Notes = ""
          Comment = ""
          Source = ""
          Categories = [] }

    let private sample = BethesdaSamples.header

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject "bethesda"

        let check (name: string) (value: bool) =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                invalidOp ("The Bethesda fixture failed: " + name)

        let read name bytes =
            use stream = new MemoryStream(bytes: byte array)
            HeaderReader.read name stream token

        let light = read "Light.esp" (sample 0x280u 1.71f [ "Skyrim.esm" ] true) |> result
        let master = read "Master.esp" (sample 1u 1.7f [] false) |> result
        let extension = read "Implicit.esl" (sample 0u 1.7f [] false) |> result

        check
            "titleFlagsExtensionsAndExtendedHeader"
            (light.Kind = PluginKind.LightPlugin
             && light.Localized
             && light.Masters = [ "Skyrim.esm" ]
             && master.Kind = PluginKind.Master
             && extension.Kind = PluginKind.LightMaster)

        let header = sample 0u 1.7f [] false
        use bounded = new MemoryStream(Array.append header [| 0xffuy; 0x01uy |])
        let observed = HeaderReader.read "Metadata.esp" bounded token
        check "recordBodiesNotRead" (Result.isOk observed && bounded.Position = int64 header.Length)

        check
            "ordinaryTruncationAndUnsupportedStayDistinct"
            (match
                read "Bad.esp" header[.. header.Length - 2],
                read "Other.esp" (sample 0u 1.0f [] false)
             with
             | Error(HeaderError.Malformed _), Error(HeaderError.Unsupported _) -> true
             | _ -> false)

        let area = Directory.CreateDirectory(Path.Combine(primary, "bethesda")).FullName
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
        let data = Path.Combine(game, "Data")
        let original = sample 1u 1.7f [] false
        File.WriteAllBytes(Path.Combine(data, "Skyrim.esm"), sample 1u 1.7f [] false)
        File.WriteAllBytes(Path.Combine(data, "QuietRivers.esp"), original)

        let workspace, profile, low, high =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let lowVersion, highVersion = Guid.NewGuid(), Guid.NewGuid()
        use store = new OperationStore(Path.Combine(area, "state"))
        let ws = store.Workspaces :> IWorkspaceState

        let created =
            ws.Create(workspace, "Plugin fixture", StorageWorker.select root)
            |> wait
            |> result

        ws.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Everyday" }
        )
        |> wait
        |> result
        |> ignore

        let library = store.ModLibrary :> IModLibrary

        for id, version, name, flags in
            [ low, lowVersion, "Low", 1u; high, highVersion, "High", 0x200u ] do
            let folder = Directory.CreateDirectory(Path.Combine(root, name)).FullName

            File.WriteAllBytes(
                Path.Combine(folder, "QuietRivers.esp"),
                sample flags 1.71f [ "Skyrim.esm" ] false
            )

            if id = high then
                for file, bytes in
                    [ "Missing.esp", sample 0u 1.7f [ "NotHere.esm" ] false
                      "CycleA.esp", sample 0u 1.7f [ "CycleB.esp" ] false
                      "CycleB.esp", sample 0u 1.7f [ "CycleA.esp" ] false
                      "Other.esp", sample 0u 1.0f [] false
                      "Bad.esp", header[.. header.Length - 2] ] do
                    File.WriteAllBytes(Path.Combine(folder, file), bytes)

            let registered =
                library.Register(
                    workspace,
                    id,
                    metadata name,
                    Registration.Directory(ModKind.Regular, path name)
                )
                |> wait
                |> result

            library.Publish(id, registered.Revision, version) |> wait |> result |> ignore

        let select ids enabled =
            let selected = InventoryObservations.read store profile

            (store.ModSelection :> IModSelection)
                .Change(profile, selected.SelectionRevision, ids, SelectionEdit.Enable enabled)
            |> wait
            |> result
            |> ignore

        select [ low; high ] true

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                0L,
                { Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
        |> wait
        |> result
        |> ignore

        let scan () =
            store.Plugins.Scan(profile, token) |> wait |> result

        let initial = scan ()

        let entry name (snapshot: PluginSnapshot) =
            snapshot.Entries |> List.find (fun row -> row.Name = name)

        let river = entry "QuietRivers.esp" initial

        check
            "effectiveWinnerRetainsExactModVersion"
            ((river.Header |> result).Kind = PluginKind.LightPlugin
             && (match river.Winner.Value.Source with
                 | CandidateSource.Pinned(SourcePin.Mod(id, version, _)) ->
                     id = high && version = highVersion
                 | _ -> false)
             && river.Alternatives.Length = 2)

        check
            "missingAndCycleDiagnosedFromObservedHeaders"
            ((entry "Missing.esp" initial).Masters.Head.State = MasterState.Missing
             && (entry "CycleA.esp" initial).Masters.Head.State = MasterState.Cyclic
             && (entry "CycleB.esp" initial).Masters.Head.State = MasterState.Cyclic)

        check
            "badHeaderDoesNotHideIndependentPlugin"
            (Result.isError (entry "Bad.esp" initial).Header && Result.isOk river.Header)

        let before = File.ReadAllBytes(Path.Combine(root, "High", "QuietRivers.esp"))

        let payloadId =
            match river.Winner.Value.Source with
            | CandidateSource.Pinned(SourcePin.Mod(_, _, file)) -> file.Payload.Id
            | _ -> invalidOp "The fixture winner is not a managed payload."

        let payload =
            Path.Combine(
                Directory.GetDirectories(root, ".mod-conductor-library-*") |> Array.exactlyOne,
                payloadId.ToString("N") + ".payload"
            )

        let backend = store.Deployments
        let state = backend.Read profile |> wait |> result

        let prepared =
            backend.Prepare(Guid.NewGuid(), state.Sources, ignore, token) |> wait |> result

        backend.Activate(prepared.Id, prepared.Sources, ignore, token)
        |> wait
        |> result
        |> ignore

        let deployed = scan ()

        check
            "activeLinkIsExcludedAndOriginalSourceRetained"
            ((entry "QuietRivers.esp" deployed).Alternatives
             |> List.exists (fun source ->
                 match source.Source with
                 | CandidateSource.Observed source ->
                     HostPath.value source.Root <> data && source.Path <> path "QuietRivers.esp"
                 | _ -> false))

        let deployedPath = Path.Combine(data, "QuietRivers.esp")
        let retainedLink = Path.Combine(area, "owned-link")
        File.Move(deployedPath, retainedLink)
        File.WriteAllText(deployedPath, "unexpected fixture replacement")

        try
            check
                "changedRelevantLinkIsRefusedWithoutTouchingReplacement"
                (store.Plugins.Scan(profile, token) |> wait = Error FilePlanError.Blocked
                 && File.ReadAllText(deployedPath) = "unexpected fixture replacement")
        finally
            File.Delete deployedPath
            File.Move(retainedLink, deployedPath)

        let plans = store.FilePlans :> IFilePlans
        let files = plans.Acquire(profile, true, ignore, token) |> wait |> result

        plans.Change(
            files.Id,
            { ModId = high
              VersionId = highVersion
              Path = path "QuietRivers.esp" },
            true,
            token
        )
        |> wait
        |> result
        |> ignore

        let hidden = scan ()

        check
            "hiddenWinnerUsesExistingPrecedence"
            ((match (entry "QuietRivers.esp" hidden).Winner.Value.Source with
              | CandidateSource.Pinned(SourcePin.Mod(id, _, _)) -> id = low
              | _ -> false)
             && (store.Plugins.Read deployed.Id |> wait = Error FilePlanError.Expired))

        select [ low; high ] false
        let stale = store.Plugins.Read hidden.Id |> wait |> result
        check "changedSelectionMarksPreviousSnapshotStale" stale.Stale
        let mutable originalUnchanged = false
        let unrelated = Path.Combine(data, "unrelated.txt")
        File.WriteAllText(unrelated, "Not a plugin")
        File.SetUnixFileMode(unrelated, enum<UnixFileMode> 0)

        try
            let baseline = scan ()
            let restored = entry "QuietRivers.esp" baseline

            match restored.Winner.Value.Source with
            | CandidateSource.Observed location ->
                use input = CandidateFiles.openObserved location
                use bytes = new MemoryStream()
                input.CopyTo bytes
                originalUnchanged <- bytes.ToArray() = original
            | _ -> ()

            check
                "candidateOnlyReadUsesPreservedOriginal"
                ((restored.Header |> result).Kind = PluginKind.Master
                 && (match restored.Winner.Value.Source with
                     | CandidateSource.Observed _ -> true
                     | _ -> false))
        finally
            File.SetUnixFileMode(unrelated, UnixFileMode.UserRead ||| UnixFileMode.UserWrite)

        check
            "scanPreservesSourceBytes"
            (File.ReadAllBytes(Path.Combine(root, "High", "QuietRivers.esp")) = before
             && File.ReadAllBytes(payload) = before
             && originalUnchanged)
        // Ambiguity is a real candidate-plan outcome; no second resolver is used by the fixture.
        let ambiguous = Directory.CreateDirectory(Path.Combine(root, "Ambiguous")).FullName
        File.WriteAllBytes(Path.Combine(ambiguous, "Twin.esm"), sample 1u 1.7f [] false)
        File.WriteAllBytes(Path.Combine(ambiguous, "twin.esm"), sample 1u 1.7f [] false)

        File.WriteAllBytes(
            Path.Combine(ambiguous, "UsesTwin.esp"),
            sample 0u 1.7f [ "Twin.esm" ] false
        )

        let modId = Guid.NewGuid()

        let registered =
            library.Register(
                workspace,
                modId,
                metadata "Ambiguous",
                Registration.Directory(ModKind.Regular, path "Ambiguous")
            )
            |> wait
            |> result

        library.Publish(modId, registered.Revision, Guid.NewGuid())
        |> wait
        |> result
        |> ignore

        select [ modId ] true
        let ambiguous = scan ()

        check
            "ambiguousMasterNeverPicksAnAlias"
            ((entry "UsesTwin.esp" ambiguous).Masters.Head.State = MasterState.Ambiguous)

        store.DrainDeployments() |> wait
        writer.WriteEndObject()
