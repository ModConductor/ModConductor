namespace ModConductor.Native.Fixtures

open System
open ModConductor.Persistence
open ModConductor.Workspaces

module WorkspaceWorker =
    let run mode directory path (textId: string) =
        use store = new OperationStore(directory)
        let state = store.Workspaces :> IWorkspaceState
        let id = Guid.Parse textId
        let root = StorageWorker.select path
        let wait = StorageWorker.wait
        let result = StorageWorker.result
        let pause = StorageWorker.pause

        match mode with
        | "intent"
        | "effect"
        | "observed"
        | "live" ->
            store.Workspaces.CreateAtCheckpoint(
                id,
                "Travel",
                root,
                (if mode = "intent" || mode = "live" then pause else ignore),
                (if mode = "effect" then pause else ignore),
                (if mode = "observed" then pause else ignore)
            )
            |> wait
            |> result
            |> ignore
        | "before-commit"
        | "after-commit" ->
            let current = state.Open root |> wait |> result
            let edit = ProfileEdit.Create { Id = id; Name = "Committed profile" }

            store.Workspaces.EditAtCheckpoint(
                current.Workspace.Id,
                current.Workspace.Revision,
                edit,
                if mode = "before-commit" then pause else ignore
            )
            |> wait
            |> result
            |> ignore

            if mode = "after-commit" then
                pause ()
        | _ -> invalidArg "mode" "Unknown workspace checkpoint."
