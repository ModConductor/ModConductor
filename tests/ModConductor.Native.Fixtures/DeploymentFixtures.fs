namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Runtime.CompilerServices
open System.Threading
open System.Threading.Tasks
open Microsoft.Data.Sqlite
open ModConductor.Platform
open ModConductor.DeploymentRecovery
open ModConductor.Persistence
open DeploymentFixtureData

module DeploymentFixtures =
    let private flag (writer: Utf8JsonWriter) name condition =
        check condition name
        writer.WriteBoolean((name: string), condition)

    let worker root (receipt: string) phase mode =
        use store = new OperationStore(Path.Combine(root, "state"))
        let value = read store (Guid.Parse receipt)

        let result =
            run store value (mode = "restore") (fun name index ->
                if name = phase && (index = 0 || index = -1) then
                    Console.WriteLine "effect-reached"
                    Console.Out.Flush()
                    Console.ReadLine() |> ignore)

        if mode = "claim" then
            match result with
            | Error RecoveryError.Busy -> Console.WriteLine "owner-busy"
            | _ -> invalidOp "A second process acquired a live receipt."
        else
            result |> ok |> ignore

    let observe (writer: Utf8JsonWriter) root =
        writer.WriteStartObject("deployment")
        let area = create (Path.Combine(root, "normal"))

        let capability =
            try
                use directory =
                    HeldDirectory.Open(
                        area.Bindings.Head.Directory.Path,
                        area.Bindings.Head.Directory.Identity
                    )

                let file =
                    directory.CreateLink(
                        "file-probe",
                        Path.Combine(
                            area.First.Directory.Path |> HostPath.value,
                            rootId.ToString("N"),
                            "shared.txt"
                        ),
                        false
                    )

                let folder =
                    directory.CreateLink(
                        "directory-probe",
                        Path.Combine(
                            area.First.Directory.Path |> HostPath.value,
                            rootId.ToString("N"),
                            "folder"
                        ),
                        true
                    )

                check (file.LinkTarget.IsSome && folder.LinkTarget.IsSome) "real symbolic links"
                directory.RemoveLink("file-probe", file)
                directory.RemoveLink("directory-probe", folder)
                Ok()
            with :? IOException as error ->
                Error error.Message

        match capability with
        | Error reason ->
            writer.WriteBoolean("symlinks", false)
            writer.WriteString("refusal", reason)
        | Ok() ->
            writer.WriteBoolean("symlinks", true)
            use store = new OperationStore(area.State)
            let first = start store area (id 1001) 0L area.First |> apply store

            flag
                writer
                "fileAndDirectoryLinks"
                (contents area "shared.txt" = "shared"
                 && contents area "folder/file.txt" = "directory-old")

            use game =
                HeldDirectory.Open(
                    area.Bindings.Head.Directory.Path,
                    area.Bindings.Head.Directory.Identity
                )

            flag
                writer
                "entriesSeparateFromTargets"
                ((game.InspectEntry "folder").Value.Kind = EntryKind.Link
                 && (game.InspectEntry "shared.txt").Value.Kind = EntryKind.Link)

            let second = start store area (id 1002) 1L area.Second |> apply store

            flag
                writer
                "addedAndRemovedPaths"
                (not (File.Exists(Path.Combine(area.Game, "removed.txt")))
                 && contents area "added.txt" = "new"
                 && contents area "folder/file.txt" = "directory-new")

            flag
                writer
                "exactGenerationsAndVersions"
                (second.Previous = Some area.First.Id
                 && second.Proposed = area.Second.Id
                 && (get (store.Deployment.Generation(contextId, area.First.Id))).Value = area.First)

            File.WriteAllText(Path.Combine(area.Game, "outputs/save.dat"), "save-two")
            let rollback = start store area (id 1003) 2L area.First |> apply store

            flag
                writer
                "rollbackKeepsMutableOutputs"
                (rollback.Previous = Some area.Second.Id
                 && contents area "outputs/save.dat" = "save-two"
                 && contents area "removed.txt" = "old")

            flag
                writer
                "sharedPayloadSurvives"
                (File.ReadAllText(Path.Combine(area.Root, "payloads/shared.payload")) = "shared"
                 && File.Exists(
                     Path.Combine(
                         HostPath.value area.Second.Directory.Path,
                         rootId.ToString("N"),
                         "added.txt"
                     )
                 ))

            flag
                writer
                "staleActivationRefused"
                (match get (store.Deployment.Start(request area (id 1004) 0L area.Second)) with
                 | Error RecoveryError.Stale -> true
                 | _ -> false)

            let current = context store
            let invalidRequest =
                { request area (id 1006) current.Revision area.Second with
                    ContextFingerprint = "" }

            flag
                writer
                "invalidRequestHasNoReceipt"
                (match get (store.Deployment.Start invalidRequest) with
                 | Error RecoveryError.InvalidPlan ->
                     get (store.Deployment.Read invalidRequest.Id) |> Option.isNone
                 | _ -> false)

            let pending = start store area (id 1005) current.Revision area.Second

            flag
                writer
                "liveOwnerExcluded"
                (use other =
                    new NativeChild(
                        Environment.ProcessPath,
                        [ "--deployment-worker"; area.Root; string pending.Id; "unused"; "claim" ]
                    )

                 let result = other.Line() = "owner-busy"
                 other.Finish()
                 result)

            let entered = new ManualResetEventSlim(false)
            let release = new ManualResetEventSlim(false)

            let running =
                Task.Run(fun () ->
                    run store pending false (fun phase _ ->
                        if phase = "intent" then
                            entered.Set()
                            release.Wait()))

            check (entered.Wait(10000)) "held operation entered"
            flag writer "closeExcludedDuringEffects" (not (store.Deployment.TryClose()))
            release.Set()
            get running |> ok |> ignore
            entered.Dispose()
            release.Dispose()

            let originals = create (Path.Combine(root, "originals-case"))
            File.WriteAllText(Path.Combine(originals.Game, "shared.txt"), "original")
            Directory.CreateDirectory(Path.Combine(originals.Game, "folder")) |> ignore

            File.WriteAllText(
                Path.Combine(originals.Game, "folder/original.txt"),
                "original-directory"
            )

            use originalStore = new OperationStore(originals.State)

            let explicit =
                { request originals (id 1100) 0L originals.First with
                    PreserveOriginals = [ target "shared.txt"; target "folder" ] }

            let receipt = get (originalStore.Deployment.Start explicit) |> ok
            stopped (fun () -> run originalStore receipt false (interrupt "install-intent"))
            let partial = read originalStore receipt.Id

            flag
                writer
                "originalsRecordedBeforeEffects"
                (partial.Originals.Length = 2
                 && (partial.Changes
                     |> List.exists (fun change -> change.Phase = EntryPhase.InstallIntent)))

            let restored = run originalStore partial true (fun _ _ -> ()) |> ok

            flag
                writer
                "explicitOriginalsRestored"
                (restored.Phase = ReceiptPhase.Restored
                 && contents originals "shared.txt" = "original"
                 && contents originals "folder/original.txt" = "original-directory")

            let mismatch = create (Path.Combine(root, "mismatch"))
            use mismatchStore = new OperationStore(mismatch.State)

            start mismatchStore mismatch (id 1200) 0L mismatch.First
            |> apply mismatchStore
            |> ignore

            let changing = start mismatchStore mismatch (id 1201) 1L mismatch.Second
            stopped (fun () -> run mismatchStore changing false (interrupt "removed"))
            let interrupted = read mismatchStore changing.Id
            let changed = interrupted.Changes.Head.Target.Path |> LogicalPath.display
            File.WriteAllText(Path.Combine(mismatch.Game, changed), "new-foreign")

            flag
                writer
                "foreignFileBeforeResumePreserved"
                (match run mismatchStore interrupted false (fun _ _ -> ()) with
                 | Error _ -> File.ReadAllText(Path.Combine(mismatch.Game, changed)) = "new-foreign"
                 | _ -> false)

            let marked = read mismatchStore changing.Id

            flag
                writer
                "partialReceiptDiscoverable"
                (marked.Phase = ReceiptPhase.Blocked
                 && (get (mismatchStore.Deployment.Pending 0L)
                     |> List.exists (fun (_, value) -> value.Id = marked.Id)))

            let foreignLink = create (Path.Combine(root, "foreign-link"))
            use linkStore = new OperationStore(foreignLink.State)

            start linkStore foreignLink (id 1250) 0L foreignLink.First
            |> apply linkStore
            |> ignore

            let planned = start linkStore foreignLink (id 1251) 1L foreignLink.Second

            use directory =
                HeldDirectory.Open(
                    foreignLink.Bindings.Head.Directory.Path,
                    foreignLink.Bindings.Head.Directory.Identity
                )

            let existing = (directory.InspectEntry "shared.txt").Value
            directory.RemoveLink("shared.txt", existing)

            let foreign =
                directory.CreateLink(
                    "shared.txt",
                    Path.Combine(foreignLink.Root, "payloads/shared.payload"),
                    false
                )

            flag
                writer
                "foreignLinkBeforeRetryPreserved"
                (match run linkStore planned false (fun _ _ -> ()) with
                 | Error _ -> directory.InspectEntry "shared.txt" = Some foreign
                 | _ -> false)

            let phases =
                [ "intent"
                  "remove-intent"
                  "removed"
                  "install-intent"
                  "verified"
                  "committed" ]

            let mutable resumeCount = 0

            for phase in phases do
                let item = create (Path.Combine(root, "resume-" + phase))
                let receiptId = Guid.NewGuid()

                let pending =
                    use before = new OperationStore(item.State)
                    start before item (id 1300) 0L item.First |> apply before |> ignore
                    let value = start before item receiptId 1L item.Second
                    stopped (fun () -> run before value false (interrupt phase))
                    read before receiptId

                use after = new OperationStore(item.State)
                run after pending false (fun _ _ -> ()) |> ok |> ignore

                check
                    (contents item "added.txt" = "new"
                     && not (File.Exists(Path.Combine(item.Game, "removed.txt"))))
                    ("resume " + phase)

                resumeCount <- resumeCount + 1

            flag writer "recordedActivationPhasesRecover" (resumeCount = phases.Length)

            for phase in [ "restore-intent"; "restored"; "verified"; "committed" ] do
                let item = create (Path.Combine(root, "restore-" + phase))
                File.WriteAllText(Path.Combine(item.Game, "shared.txt"), "original")
                let receiptId = Guid.NewGuid()

                let pending =
                    use before = new OperationStore(item.State)

                    let requested =
                        { request item receiptId 0L item.First with
                            PreserveOriginals = [ target "shared.txt" ] }

                    let value = get (before.Deployment.Start requested) |> ok
                    stopped (fun () -> run before value false (interrupt "verified"))
                    stopped (fun () -> run before (read before receiptId) true (interrupt phase))
                    read before receiptId

                use after = new OperationStore(item.State)
                let result = run after pending true (fun _ _ -> ()) |> ok

                check
                    (result.Phase = ReceiptPhase.Restored
                     && contents item "shared.txt" = "original"
                     && not (Directory.Exists(Path.Combine(item.Game, "folder"))))
                    ("restore " + phase)

            flag writer "interruptedRestoreRecovers" true

            let occupied = create (Path.Combine(root, "restore-occupied"))
            File.WriteAllText(Path.Combine(occupied.Game, "shared.txt"), "original")
            use occupiedStore = new OperationStore(occupied.State)

            let preserve =
                { request occupied (id 1500) 0L occupied.First with
                    PreserveOriginals = [ target "shared.txt" ] }

            let preserving = get (occupiedStore.Deployment.Start preserve) |> ok
            stopped (fun () -> run occupiedStore preserving false (interrupt "verified"))

            use destination =
                HeldDirectory.Open(
                    occupied.Bindings.Head.Directory.Path,
                    occupied.Bindings.Head.Directory.Identity
                )

            destination.RemoveLink("shared.txt", (destination.InspectEntry "shared.txt").Value)
            File.WriteAllText(Path.Combine(occupied.Game, "shared.txt"), "foreign")
            let beforeRestore = read occupiedStore preserving.Id

            flag
                writer
                "originalRestoreNeverOverwrites"
                (match run occupiedStore beforeRestore true (fun _ _ -> ()) with
                 | Error _ ->
                     contents occupied "shared.txt" = "foreign"
                     && File.ReadAllText(
                         Path.Combine(occupied.Originals, beforeRestore.Originals.Head.Backup)
                     ) = "original"
                 | _ -> false)

            let changedGeneration = create (Path.Combine(root, "changed-generation"))
            use generationStore = new OperationStore(changedGeneration.State)

            let beforeChange =
                start generationStore changedGeneration (id 1600) 0L changedGeneration.First

            let changedPath =
                Path.Combine(
                    HostPath.value changedGeneration.First.Directory.Path,
                    rootId.ToString("N"),
                    "removed.txt"
                )

            File.WriteAllText(changedPath, "changed pinned data")

            flag
                writer
                "changedGenerationRefusesBeforeEffects"
                (match run generationStore beforeChange false (fun _ _ -> ()) with
                 | Error _ ->
                     not (File.Exists(Path.Combine(changedGeneration.Game, "shared.txt")))
                     && (context generationStore).Active.IsNone
                 | _ -> false)

            let cancelled = create (Path.Combine(root, "cancelled-effect"))
            use cancelStore = new OperationStore(cancelled.State)
            let cancellable = start cancelStore cancelled (id 1650) 0L cancelled.First
            use cancellation = new CancellationTokenSource()

            let result =
                get (
                    cancelStore.Deployment.Run(
                        cancellable.Id,
                        cancellable.Revision,
                        false,
                        cancellation.Token,
                        fun phase index ->
                            if phase = "remove-intent" && index = 1 then
                                cancellation.Cancel()
                    )
                )

            check (Result.isError result) "cancellation returns an interrupted outcome"
            let recorded = read cancelStore cancellable.Id
            let resumed = run cancelStore recorded false (fun _ _ -> ()) |> ok

            flag
                writer
                "cancelledEffectRemainsRecoverable"
                (resumed.Phase = ReceiptPhase.Complete
                 && contents cancelled "shared.txt" = "shared")

            let owners = create (Path.Combine(root, "target-owners"))
            use ownershipStore = new OperationStore(owners.State)
            let requestA = request owners (id 1700) 0L owners.First

            let requestB =
                { request owners (id 1701) 0L owners.First with
                    ContextId = id 1702 }

            let calls =
                [ ownershipStore.Deployment.Start requestA
                  ownershipStore.Deployment.Start requestB ]

            let results = calls |> List.map get

            let accepted =
                results
                |> List.choose (function
                    | Ok receipt -> Some receipt
                    | Error _ -> None)

            let rejected =
                results
                |> List.filter (function
                    | Error(RecoveryError.Mismatch _) -> true
                    | _ -> false)

            check (accepted.Length = 1 && rejected.Length = 1) "one context wins target ownership"
            let winner = accepted.Head
            let loser = if winner.Id = requestA.Id then requestB else requestA

            check
                (get (ownershipStore.Deployment.Read loser.Id) |> Option.isNone)
                "no rejected receipt"

            check
                (get (ownershipStore.Deployment.Context loser.ContextId) |> Option.isNone)
                "no rejected context"

            apply ownershipStore winner |> ignore

            flag
                writer
                "overlappingContextHasNoRowsOrEffects"
                (contents owners "shared.txt" = "shared")

            let crash = create (Path.Combine(root, "process-crash"))
            let crashId = Guid.NewGuid()

            do
                use before = new OperationStore(crash.State)
                start before crash (id 1400) 0L crash.First |> apply before |> ignore
                start before crash crashId 1L crash.Second |> ignore

            let executable = Environment.ProcessPath

            use child =
                new NativeChild(
                    executable,
                    [ "--deployment-worker"; crash.Root; string crashId; "installed"; "resume" ]
                )

            check (child.Line() = "effect-reached") "native child reached effect"
            child.Terminate()
            use recovered = new OperationStore(crash.State)
            let abandoned = read recovered crashId

            let ambiguous =
                RecoveryFiles.observe abandoned.Context abandoned.Changes.Head.Target

            let outcome = run recovered abandoned false (fun _ _ -> ())

            flag
                writer
                "unrecordedCreateRequiresReviewAfterProcessLoss"
                (match outcome with
                 | Error(RecoveryError.Mismatch _) ->
                     RecoveryFiles.observe abandoned.Context abandoned.Changes.Head.Target = ambiguous
                     && ambiguous.IsSome
                     && (read recovered crashId).Phase = ReceiptPhase.Blocked
                     && (context recovered).Active = Some crash.First.Id
                 | _ -> false)

            DeploymentBoundaryFixtures.observe writer root

            let corrupt = create (Path.Combine(root, "corrupt"))
            let corruptId = Guid.NewGuid()

            do
                use before = new OperationStore(corrupt.State)
                start before corrupt corruptId 0L corrupt.First |> ignore

            use connection =
                new SqliteConnection(
                    "Data Source=" + Path.Combine(corrupt.State, "state.db") + ";Pooling=False"
                )

            connection.Open()
            use command = connection.CreateCommand()
            command.CommandText <- "UPDATE deployment_receipts SET digest='invalid' WHERE id=$id"
            command.Parameters.AddWithValue("$id", string corruptId) |> ignore
            command.ExecuteNonQuery() |> ignore
            connection.Close()
            use invalid = new OperationStore(corrupt.State)

            flag
                writer
                "corruptReceiptHasNoEffects"
                (match
                    get (
                        invalid.Deployment.Run(
                            corruptId,
                            0L,
                            false,
                            CancellationToken.None,
                            fun _ _ -> ()
                        )
                    )
                 with
                 | Error(RecoveryError.Corrupt _) ->
                     Directory.GetFileSystemEntries(corrupt.Game).Length = 1
                 | _ -> false)

        writer.WriteEndObject()

    let run root =
        use output = Console.OpenStandardOutput()
        use writer = new Utf8JsonWriter(output, JsonWriterOptions(Indented = true))
        writer.WriteStartObject()
        writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
        writer.WriteString("os", if OperatingSystem.IsWindows() then "windows" else "linux")
        observe writer root
        writer.WriteEndObject()
        writer.Flush()
