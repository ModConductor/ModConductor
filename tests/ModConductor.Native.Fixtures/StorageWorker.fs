namespace ModConductor.Native.Fixtures

open System
open System.Threading
open ModConductor.Platform
open ModConductor.Persistence
open ModConductor.Operations
open ModConductor.Workspaces

module StorageWorker =
    let result value =
        value
        |> Result.defaultWith (fun error ->
            invalidOp ("The storage fixture request failed: " + error.ToString()))

    let wait (value: System.Threading.Tasks.Task<'a>) = value.GetAwaiter().GetResult()

    let select path =
        HostPath.create path
        |> Result.defaultWith invalidOp
        |> RootSelection.select
        |> Result.defaultWith (fun _ -> invalidOp "The fixture root could not be selected.")

    let pause () =
        Console.WriteLine "ready"
        Console.Out.Flush()
        Console.ReadLine() |> ignore

    let runtime (store: OperationStore) id expected =
        let operations = store :> IOperationStore

        let request =
            { Id = id
              ExpectedRevision = expected
              Count = 1 }

        let begun, _ = operations.Begin request |> wait |> result

        if begun.Phase = Running then
            operations.Advance(
                id,
                1,
                { Architecture = "fixture"
                  NativeAot = true
                  SqliteVersion = store.SqliteVersion }
            )
            |> wait
        else
            begun

    let run mode state root (id: string) =
        use store = new OperationStore(state)
        let workspace = store.WorkspaceRoots
        let prepared = workspace.Prepare(Guid.Parse id, 0L, select root) |> wait |> result

        if mode = "intent" then
            pause ()
        elif mode = "effect" then
            workspace.ApplyAtCheckpoint(Guid.Parse id, prepared.Revision, pause)
            |> wait
            |> ignore
        elif mode = "slow" then
            use arrived = new ManualResetEventSlim(false)
            use release = new ManualResetEventSlim(false)

            let pending =
                workspace.ApplyAtCheckpoint(
                    Guid.Parse id,
                    prepared.Revision,
                    fun () ->
                        arrived.Set()
                        release.Wait()
                )

            if not (arrived.Wait 10000) then
                invalidOp "The file checkpoint was not reached."

            let operation = runtime store (Guid.NewGuid().ToString()) 0L

            let refused =
                try
                    (store :> IDisposable).Dispose()
                    false
                with :? InvalidOperationException ->
                    true

            let listed = workspace.Recoverable None |> wait |> List.contains (Guid.Parse id)

            let featureAvailable =
                (store.Workspaces :> IWorkspaceState).Read(Guid.NewGuid(), None) |> wait = Error
                    WorkspaceError.NotFound

            Console.WriteLine(
                string operation.ResultRevision
                + ":"
                + string refused
                + ":"
                + string listed
                + ":"
                + string featureAvailable
            )

            Console.Out.Flush()
            Console.ReadLine() |> ignore
            release.Set()
            let applied = pending |> wait |> result
            workspace.Complete(Guid.Parse id, applied.Revision) |> wait |> result |> ignore
        else
            let applied = workspace.Apply(Guid.Parse id, prepared.Revision) |> wait |> result

            if mode = "observed" then
                pause ()
            elif mode = "live" then
                pause ()
                workspace.Complete(Guid.Parse id, applied.Revision) |> wait |> result |> ignore
            else
                invalidArg "mode" "Unknown storage fixture mode."
