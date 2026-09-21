namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Security.Cryptography
open ModConductor.Platform
open ModConductor.DeploymentRecovery
open ModConductor.Persistence
open DeploymentFixtureData

module internal DeploymentBoundaryFixtures =
    let private flag (writer: Utf8JsonWriter) (name: string) condition =
        check condition name
        writer.WriteBoolean(name, condition)

    let private content (generation: Generation) =
        generation.Files
        |> List.map (fun file ->
            let native = RecoveryFiles.path generation.Directory file.Path
            use stream = File.OpenRead native
            file.Target, Convert.ToHexStringLower(SHA256.HashData stream))

    let private separation root =
        let inside = create (Path.Combine(root, "target-in-generation"))

        let generationTarget =
            location (
                Path.Combine(HostPath.value inside.First.Directory.Path, rootId.ToString("N"))
            )

        let requestInside =
            { request inside (id 1800) 0L inside.First with
                Roots =
                    [ { inside.Bindings.Head with
                          Directory = generationTarget } ]
                PreserveOriginals = [ target "shared.txt"; target "removed.txt"; target "folder" ] }

        let same = create (Path.Combine(root, "originals-in-generation"))
        File.WriteAllText(Path.Combine(same.Game, "shared.txt"), "original")

        let requestSame =
            { request same (id 1801) 0L same.First with
                Roots =
                    [ { same.Bindings.Head with
                          Originals = same.First.Directory } ]
                PreserveOriginals = [ target "shared.txt" ] }

        let parent = create (Path.Combine(root, "target-in-originals"))

        let requestParent =
            { request parent (id 1802) 0L parent.First with
                Roots =
                    [ { parent.Bindings.Head with
                          Originals = location parent.Root } ] }

        for area, value in [ inside, requestInside; same, requestSame; parent, requestParent ] do
            use store = new OperationStore(area.State)
            let before = content area.First
            let result = get (store.Deployment.Start value)
            check (Result.isError result) "overlapping storage refuses preparation"

            check
                (get (store.Deployment.Read value.Id) |> Option.isNone)
                "invalid preparation has no receipt"

            check
                (get (store.Deployment.Context value.ContextId) |> Option.isNone)
                "invalid preparation has no context"

            check
                (get (store.Deployment.Generation(value.ContextId, value.Generation.Id))
                 |> Option.isNone)
                "invalid preparation has no generation row"

            check (content area.First = before) "retained generation unchanged"

        check
            (File.ReadAllText(Path.Combine(same.Game, "shared.txt")) = "original")
            "original unchanged"

    let private sharedOriginals root =
        let first = create (Path.Combine(root, "shared-originals-first"))
        let second = create (Path.Combine(root, "shared-originals-second"))
        File.WriteAllText(Path.Combine(first.Game, "shared.txt"), "original-first")
        File.WriteAllText(Path.Combine(second.Game, "shared.txt"), "original-second")
        use store = new OperationStore(first.State)

        let a =
            { request first (id 1810) 0L first.First with
                PreserveOriginals = [ target "shared.txt" ] }

        let b =
            { request second (id 1811) 0L second.First with
                ContextId = id 1812
                Roots =
                    [ { second.Bindings.Head with
                          Originals = first.Bindings.Head.Originals } ]
                PreserveOriginals = [ target "shared.txt" ] }

        let activeA = get (store.Deployment.Start a) |> ok |> apply store
        let activeB = get (store.Deployment.Start b) |> ok |> apply store

        check
            (activeA.Phase = ReceiptPhase.Complete && activeB.Phase = ReceiptPhase.Complete)
            "disjoint target activations complete"

        let original (value: Receipt) =
            File.ReadAllText(Path.Combine(first.Originals, value.Originals.Head.Backup))

        check
            (original activeA = "original-first" && original activeB = "original-second")
            "shared storage retains separate originals"

    let private activationAmbiguity root =
        let area = create (Path.Combine(root, "ambiguous-activation"))
        use store = new OperationStore(area.State)
        let receipt = start store area (id 1820) 0L area.First
        stopped (fun () -> run store receipt false (interrupt "install-intent"))
        let pending = read store receipt.Id
        let change = pending.Changes.Head

        let spec =
            match change.After with
            | EntryState.Link(spec, None) -> spec
            | _ -> invalidOp "Expected pending link."

        use targetRoot =
            HeldDirectory.Open(
                area.Bindings.Head.Directory.Path,
                area.Bindings.Head.Directory.Identity
            )

        let name = LogicalPath.display change.Target.Path
        let foreign = targetRoot.CreateLink(name, spec.Target, spec.Directory)
        let result = run store pending false (fun _ _ -> ())

        check
            (Result.isError result && targetRoot.InspectEntry name = Some foreign)
            "unrecorded same-text activation link preserved"

        check
            ((read store receipt.Id).Changes.Head.Observed.IsNone
             && (context store).Active.IsNone)
            "foreign activation link is not adopted"

    let private restoreAmbiguity root =
        let area = create (Path.Combine(root, "ambiguous-restore"))
        use store = new OperationStore(area.State)
        start store area (id 1830) 0L area.First |> apply store |> ignore

        let owned =
            (context store).Links
            |> List.find (fun link -> link.Target = target "shared.txt")

        let foreignPath = Path.Combine(area.Root, "foreign-copy")
        File.CreateSymbolicLink(foreignPath, owned.Spec.Target) |> ignore

        use parent =
            HeldDirectory.Open((location area.Root).Path, (location area.Root).Identity)

        let foreign = (parent.InspectEntry "foreign-copy").Value
        check (foreign.Identity <> owned.Entry.Identity) "foreign link is a distinct native entry"
        let receipt = start store area (id 1831) 1L area.Second
        stopped (fun () -> run store receipt false (interrupt "verified"))
        let pending = read store receipt.Id

        let index =
            pending.Changes |> List.findIndex (fun change -> change.Target = owned.Target)

        stopped (fun () ->
            run store pending true (fun phase current ->
                if phase = "restore-intent" && current = index then
                    raise Interrupted))

        use targetRoot =
            HeldDirectory.Open(
                area.Bindings.Head.Directory.Path,
                area.Bindings.Head.Directory.Identity
            )

        targetRoot.RemoveLink("shared.txt", (targetRoot.InspectEntry "shared.txt").Value)
        File.Move(foreignPath, Path.Combine(area.Game, "shared.txt"), false)
        let interrupted = read store receipt.Id
        let result = run store interrupted true (fun _ _ -> ())

        check
            (Result.isError result && targetRoot.InspectEntry "shared.txt" = Some foreign)
            "same-text foreign restore link preserved"

        check
            ((read store receipt.Id).Changes[index].RestoredEntry.IsNone
             && (context store).Pending = Some receipt.Id)
            "foreign restore link is not adopted"

    let private knownOwnerLoss root =
        let area = create (Path.Combine(root, "recorded-owner-loss"))
        let receiptId = id 1840

        do
            use before = new OperationStore(area.State)
            start before area receiptId 0L area.First |> ignore

        use child =
            new NativeChild(
                Environment.ProcessPath,
                [ "--deployment-worker"; area.Root; string receiptId; "verified"; "resume" ]
            )

        check (child.Line() = "effect-reached") "native child saved link identities"
        child.Terminate()
        use after = new OperationStore(area.State)
        let pending = read after receiptId
        let result = run after pending false (fun _ _ -> ()) |> ok

        check
            (result.Phase = ReceiptPhase.Complete && contents area "shared.txt" = "shared")
            "durably recorded links resume after process loss"

    let private metadataOnlyOriginalLifecycle root =
        let area = create (Path.Combine(root, "metadata-only-original"))
        let originalPath = Path.Combine(area.Game, "shared.txt")
        File.WriteAllText(originalPath, "unreadable original")
        use store = new OperationStore(area.State)

        let mode =
            if OperatingSystem.IsLinux() then
                let value = File.GetUnixFileMode originalPath
                File.SetUnixFileMode(originalPath, enum<UnixFileMode> 0)
                Some value
            else
                None

        let refused =
            if OperatingSystem.IsLinux() then
                try
                    use _ = File.OpenRead originalPath
                    false
                with :? UnauthorizedAccessException ->
                    true
            else
                true

        let receipt =
            get (
                store.Deployment.Start(
                    { request area (id 1850) 0L area.First with
                        PreserveOriginals = [ target "shared.txt" ] }
                )
            )
            |> ok

        let index =
            receipt.Changes
            |> List.findIndex (fun change -> change.Target = target "shared.txt")

        stopped (fun () ->
            run store receipt false (fun phase current ->
                if phase = "removed" && current = index then
                    raise Interrupted))

        let pending = read store receipt.Id
        let restored = run store pending true (fun _ _ -> ()) |> ok

        mode |> Option.iter (fun value -> File.SetUnixFileMode(originalPath, value))

        check
            (refused
             && restored.Phase = ReceiptPhase.Restored
             && File.ReadAllText originalPath = "unreadable original")
            "original lifecycle uses metadata identity"

    let observe writer root =
        separation root
        flag writer "overlappingStorageRefusedBeforeRows" true
        sharedOriginals root
        flag writer "disjointTargetsMayShareOriginals" true
        activationAmbiguity root
        flag writer "unrecordedActivationLinkPreserved" true
        restoreAmbiguity root
        flag writer "unrecordedRestoreLinkPreserved" true
        knownOwnerLoss root
        flag writer "recordedIdentitySurvivesOwnerLoss" true
        metadataOnlyOriginalLifecycle root
        flag writer "originalPreservationAndRestorationDoNotReadContent" true
