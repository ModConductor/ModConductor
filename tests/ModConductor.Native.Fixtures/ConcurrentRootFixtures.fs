namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.Persistence

module ConcurrentRootFixtures =
    let observe (writer: Utf8JsonWriter) primary =
        let wait = StorageWorker.wait
        let result = StorageWorker.result

        let area =
            Directory.CreateDirectory(Path.Combine(primary, "concurrent-roots")).FullName

        use database =
            new StateDatabase(Directory.CreateDirectory(Path.Combine(area, "state")).FullName)

        let roots = OwnedWorkspaceRootStore(database)

        let prepare name =
            let path = Directory.CreateDirectory(Path.Combine(area, name)).FullName
            let id = Guid.NewGuid()
            let prepared = roots.Prepare(id, 0L, StorageWorker.select path) |> wait |> result
            id, path, prepared

        let complete (id, path, prepared: RootCreationReceipt) =
            let observed = roots.Apply(id, prepared.Revision) |> wait |> result
            let completed = roots.Complete(id, observed.Revision) |> wait |> result
            id, path, completed

        let first, firstPath, firstReceipt = prepare "first" |> complete
        let second, _, _ = prepare "second" |> complete
        let third, _, thirdReceipt = prepare "third"
        use entered = new ManualResetEventSlim()
        use release = new ManualResetEventSlim()

        let held =
            database.Enqueue(fun () ->
                entered.Set()
                release.Wait())

        if not (entered.Wait(TimeSpan.FromSeconds 5.)) then
            invalidOp "The fixture queue did not start."

        let firstRead = roots.Validate first
        let sharedRead = roots.Validate first
        let secondRead = roots.Validate second
        let thirdRead = roots.Validate third
        let mutable busy = false

        try
            busy <-
                roots.Apply(first, firstReceipt.Revision) |> wait = Error WorkspaceFailure.Busy
                && roots.Complete(first, firstReceipt.Revision) |> wait = Error
                    WorkspaceFailure.Busy
                && not (roots.TryClose())
        finally
            release.Set()

        held |> wait

        let firstResult, sharedResult, secondResult, thirdResult =
            firstRead |> wait, sharedRead |> wait, secondRead |> wait, thirdRead |> wait

        writer.WriteStartObject("concurrentRoots")

        writer.WriteBoolean(
            "sharedReadsKeepWriteAndCloseExclusion",
            busy
            && Result.isOk firstResult
            && firstResult = sharedResult
            && Result.isOk secondResult
            && Result.isOk thirdResult
        )

        let moved = firstPath + "-moved"
        Directory.Move(firstPath, moved)
        let missing = roots.Validate first |> wait
        Directory.Move(moved, firstPath)
        let restored = roots.Validate first |> wait

        writer.WriteBoolean(
            "completedAndFailedReadsAreNotCached",
            Result.isError missing && Result.isOk restored
        )

        entered.Reset()
        release.Reset()

        let write =
            roots.ApplyAtCheckpoint(
                third,
                thirdReceipt.Revision,
                fun () ->
                    entered.Set()
                    release.Wait()
            )

        let mutable writeBusy = false

        try
            if not (entered.Wait(TimeSpan.FromSeconds 5.)) then
                invalidOp "The fixture root write did not start."

            writeBusy <-
                roots.Validate third |> wait = Error WorkspaceFailure.Busy
                && not (roots.TryClose())
        finally
            release.Set()

        write |> wait |> result |> ignore
        let closed = roots.TryClose()

        writer.WriteBoolean(
            "writesRemainExclusiveAndClosedRootsRefuseReads",
            writeBusy
            && closed
            && roots.Validate first |> wait = Error WorkspaceFailure.Busy
        )

        writer.WriteEndObject()
