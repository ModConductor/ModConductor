namespace ModConductor.Native.Fixtures

open System
open ModConductor.Persistence
open ModConductor.ModLibrary

module LibraryWorker =
    let run mode directory (modText: string) (versionText: string) =
        use store = new OperationStore(directory)
        let modId, version = Guid.Parse modText, Guid.Parse versionText
        let pause = StorageWorker.pause

        if mode = "initialize" then
            let root =
                store.ModLibrary.Access.Root modId |> StorageWorker.wait |> StorageWorker.result

            store.ModLibrary.Access.PrepareLibrary(root, pause)
            |> StorageWorker.wait
            |> StorageWorker.result
            |> ignore
        elif mode = "rename-before" || mode = "rename-after" then
            store.ModLibrary.EditAtCheckpoint(
                modId,
                0L,
                { Name = "Renamed"
                  Notes = "After"
                  Comment = ""
                  Version = ""
                  Source = ""
                  Categories = [] },
                if mode = "rename-before" then pause else ignore
            )
            |> StorageWorker.wait
            |> StorageWorker.result
            |> ignore

            if mode = "rename-after" then
                pause ()
        else
            let outcome =
                store.ModLibrary.PublishAtCheckpoint(
                    modId,
                    0L,
                    version,
                    (if mode = "effect" then pause else ignore),
                    (if mode = "observed" then pause else ignore)
                )
                |> StorageWorker.wait

            Console.WriteLine(
                match outcome with
                | Ok _ -> "complete"
                | Error LibraryError.Cancelled -> "cancelled"
                | Error LibraryError.SourceChanged -> "source-changed"
                | Error _ -> "refused"
            )
