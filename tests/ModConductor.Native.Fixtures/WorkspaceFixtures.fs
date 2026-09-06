namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open ModConductor.Persistence
open ModConductor.Workspaces

module WorkspaceFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private select = StorageWorker.select

    let observe (writer: Utf8JsonWriter) primary =
        let directory =
            Directory.CreateDirectory(Path.Combine(primary, "workspaces")).FullName

        let area name =
            let parent = Directory.CreateDirectory(Path.Combine(directory, name)).FullName
            let state = Directory.CreateDirectory(Path.Combine(parent, "state")).FullName
            let root = Directory.CreateDirectory(Path.Combine(parent, "root")).FullName
            state, root, Guid.NewGuid()

        let worker mode state root (id: Guid) =
            new NativeChild(
                Environment.ProcessPath,
                [ "--workspace-worker"; mode; state; root; string id ]
            )

        writer.WriteStartObject("workspaces")
        let statePath, root, id = area "lifecycle"
        let sibling = Directory.CreateDirectory(root + "-other").FullName
        File.WriteAllText(Path.Combine(root, "foreign.txt"), "keep root")
        File.WriteAllText(Path.Combine(sibling, "foreign.txt"), "keep sibling")
        let firstId, copyId = Guid.NewGuid(), Guid.NewGuid()

        do
            use store = new OperationStore(statePath)
            let state = store.Workspaces :> IWorkspaceState
            let created = state.Create(id, "Weekend", select root) |> wait |> result

            writer.WriteBoolean(
                "emptyAtCreation",
                created.Profiles.IsEmpty && created.Workspace.SelectedProfile.IsNone
            )

            let first =
                state.Edit(
                    id,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = firstId; Name = "Everyday" }
                )
                |> wait
                |> result

            let copied =
                state.Edit(
                    id,
                    first.Workspace.Revision,
                    ProfileEdit.Clone(firstId, { Id = copyId; Name = "Everyday copy" })
                )
                |> wait
                |> result

            writer.WriteBoolean(
                "cloneKeepsSelection",
                copied.Workspace.SelectedProfile.Value.Id = firstId
            )

            let renamed =
                state.Edit(id, copied.Workspace.Revision, ProfileEdit.Rename(firstId, "Daily"))
                |> wait
                |> result

            writer.WriteBoolean(
                "selectedRename",
                renamed.Workspace.SelectedProfile.Value.Name = "Daily"
            )

            writer.WriteBoolean(
                "staleRefused",
                state.Edit(id, copied.Workspace.Revision, ProfileEdit.Rename(firstId, "Stale"))
                |> wait =
                    Error WorkspaceError.StaleRevision
            )

            writer.WriteBoolean(
                "selectedDeleteRefused",
                state.Edit(id, renamed.Workspace.Revision, ProfileEdit.Delete firstId) |> wait =
                    Error WorkspaceError.SelectedProfile
            )

            let selected =
                state.Edit(id, renamed.Workspace.Revision, ProfileEdit.Select copyId)
                |> wait
                |> result

            let deleted =
                state.Edit(id, selected.Workspace.Revision, ProfileEdit.Delete firstId)
                |> wait
                |> result

            writer.WriteNumber("finalRevision", deleted.Workspace.Revision)
            writer.WriteBoolean("selectedCopy", deleted.Workspace.SelectedProfile.Value.Id = copyId)

            let otherRoot =
                Directory.CreateDirectory(Path.Combine(directory, "other-workspace")).FullName

            let other =
                state.Create(Guid.NewGuid(), "Other", select otherRoot) |> wait |> result

            writer.WriteBoolean(
                "crossWorkspaceDeleteRefused",
                state.Edit(other.Workspace.Id, other.Workspace.Revision, ProfileEdit.Delete copyId)
                |> wait =
                    Error WorkspaceError.NotFound
            )

            writer.WriteBoolean(
                "crossWorkspaceCloneRefused",
                state.Edit(
                    other.Workspace.Id,
                    other.Workspace.Revision,
                    ProfileEdit.Clone(copyId, { Id = Guid.NewGuid(); Name = "Wrong" })
                )
                |> wait =
                    Error WorkspaceError.NotFound
            )

            writer.WriteBoolean(
                "profileFilesAbsent",
                Directory.GetDirectories(root).Length = 0 && Directory.GetFiles(root).Length = 2
            )

        do
            use store = new OperationStore(statePath)
            let state = store.Workspaces :> IWorkspaceState
            let reopened = state.Open(select root) |> wait |> result

            writer.WriteBoolean(
                "restartSelection",
                reopened.Workspace.Id = id
                && reopened.Workspace.SelectedProfile.Value.Id = copyId
                && reopened.Workspace.Revision = 5L
            )

            writer.WriteBoolean(
                "restartContents",
                reopened.Profiles = [ { Id = copyId; Name = "Everyday copy" } ]
            )

            writer.WriteBoolean(
                "foreignPreserved",
                File.ReadAllText(Path.Combine(root, "foreign.txt")) = "keep root"
                && File.ReadAllText(Path.Combine(sibling, "foreign.txt")) = "keep sibling"
            )

            let original = root + "-original"
            Directory.Move(root, original)
            Directory.CreateDirectory root |> ignore
            File.WriteAllText(Path.Combine(root, "foreign.txt"), "replacement")

            let changedRoot = state.Read(id, None) |> wait

            writer.WriteBoolean(
                "changedRootRefused",
                match changedRoot with
                | Error(WorkspaceError.InvalidRoot _)
                | Error WorkspaceError.IdentityConflict -> true
                | _ -> false
            )

            writer.WriteBoolean(
                "replacementPreserved",
                Directory.GetFiles(root).Length = 1
                && File.ReadAllText(Path.Combine(root, "foreign.txt")) = "replacement"
            )

            Directory.Delete(root, true)
            Directory.Move(original, root)

            let marker =
                Directory.GetFiles(root)
                |> Array.find (fun path -> Path.GetFileName path <> "foreign.txt")

            File.Move(marker, marker + ".original")
            File.Copy(marker + ".original", marker)

            writer.WriteBoolean(
                "changedMarkerRefused",
                state.Read(id, None) |> wait = Error WorkspaceError.IdentityConflict
            )

            writer.WriteBoolean(
                "markerReplacementPreserved",
                File.ReadAllBytes(marker) = File.ReadAllBytes(marker + ".original")
            )

        let freshState =
            Directory.CreateDirectory(Path.Combine(directory, "unregistered-state")).FullName

        do
            use store = new OperationStore(freshState)
            let state = store.Workspaces :> IWorkspaceState

            let refused =
                match state.Open(select root) |> wait with
                | Error(WorkspaceError.InvalidRoot _) -> true
                | _ -> false

            writer.WriteBoolean("unregisteredRefused", refused)

        writer.WriteStartArray("creationWindows")

        for mode in [ "intent"; "effect"; "observed"; "live" ] do
            let statePath, root, id = area mode
            use child = worker mode statePath root id
            child.Line() |> ignore
            writer.WriteStartObject()
            writer.WriteString("window", mode)

            if mode = "live" then
                use other = new OperationStore(statePath)
                let state = other.Workspaces :> IWorkspaceState
                let page = state.Open(select root) |> wait |> result

                writer.WriteBoolean(
                    "liveRecoveryRefused",
                    state.Check(id, page.Workspace.PendingRoot.Value.ReceiptRevision) |> wait =
                        Error WorkspaceError.Busy
                )

                child.Send "continue"
                child.Finish()
                let page = state.Read(id, None) |> wait |> result
                writer.WriteBoolean("ready", page.Workspace.PendingRoot.IsNone)
            else
                child.Terminate()
                use restarted = new OperationStore(statePath)
                let state = restarted.Workspaces :> IWorkspaceState
                let page = state.Open(select root) |> wait |> result
                writer.WriteBoolean("nameRetained", page.Workspace.Name = "Travel")

                let recovered =
                    state.Check(id, page.Workspace.PendingRoot.Value.ReceiptRevision)
                    |> wait
                    |> result

                writer.WriteBoolean("ready", recovered.Workspace.PendingRoot.IsNone)
                writer.WriteNumber("files", Directory.GetFiles(root).Length)

            writer.WriteEndObject()

        writer.WriteEndArray()
        writer.WriteStartArray("metadataWindows")

        for mode in [ "before-commit"; "after-commit" ] do
            let statePath, root, id = area mode

            do
                use initial = new OperationStore(statePath)

                (initial.Workspaces :> IWorkspaceState).Create(id, "Atomic", select root)
                |> wait
                |> result
                |> ignore

            use child = worker mode statePath root (Guid.NewGuid())
            child.Line() |> ignore
            child.Terminate()
            use restarted = new OperationStore(statePath)

            let page =
                (restarted.Workspaces :> IWorkspaceState).Open(select root) |> wait |> result

            writer.WriteStartObject()
            writer.WriteString("window", mode)
            writer.WriteNumber("revision", page.Workspace.Revision)
            writer.WriteNumber("profiles", page.Profiles.Length)

            writer.WriteBoolean(
                "selectionMatches",
                page.Profiles.IsEmpty = page.Workspace.SelectedProfile.IsNone
            )

            writer.WriteNumber("files", Directory.GetFiles(root).Length)
            writer.WriteEndObject()

        writer.WriteEndArray()
        writer.WriteEndObject()
