namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open ModConductor.Persistence
open ModConductor.Workspaces

module ProfileImageFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let observe (writer: Utf8JsonWriter) primary =
        let state =
            Directory.CreateDirectory(Path.Combine(primary, "profile-images-state")).FullName

        let root =
            Directory.CreateDirectory(Path.Combine(primary, "profile-images-root")).FullName

        let workspace, first, copy = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        let original = Path.Combine(primary, "chosen-image.png")
        let changed = Path.Combine(primary, "replacement-image.png")
        let initial = [| 1uy; 2uy; 3uy; 4uy |]
        let replacement = [| 5uy; 6uy; 7uy |]
        File.WriteAllBytes(original, initial)
        File.WriteAllBytes(changed, replacement)
        writer.WriteStartObject("profileImages")

        do
            use store = new OperationStore(state)
            let workspaces = store.Workspaces :> IWorkspaceState
            let images = store.ProfileImages

            let opened =
                workspaces.Create(workspace, "Images", StorageWorker.select root)
                |> wait
                |> result

            let created =
                workspaces.Edit(
                    workspace,
                    opened.Workspace.Revision,
                    ProfileEdit.Create { Id = first; Name = "First" }
                )
                |> wait
                |> result

            images.Set(workspace, first, Some original) |> wait |> result |> ignore

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Clone(first, { Id = copy; Name = "Copy" })
            )
            |> wait
            |> result
            |> ignore

            let copyBefore = images.Read(workspace, copy) |> wait |> result

            let failedReplacement =
                images.Set(workspace, first, Some(Path.Combine(primary, "missing.png"))) |> wait

            let firstBefore = images.Read(workspace, first) |> wait |> result

            writer.WriteBoolean(
                "failedReplacementKeepsImage",
                Result.isError failedReplacement
                && (firstBefore |> Option.map File.ReadAllBytes) = Some initial
            )

            images.Set(workspace, first, Some changed) |> wait |> result |> ignore
            let copyAfter = images.Read(workspace, copy) |> wait |> result
            let firstAfter = images.Read(workspace, first) |> wait |> result

            writer.WriteBoolean(
                "cloneIndependent",
                (copyBefore |> Option.map File.ReadAllBytes) = Some initial
                && (copyAfter |> Option.map File.ReadAllBytes) = Some initial
                && (firstAfter |> Option.map File.ReadAllBytes) = Some replacement
                && copyAfter <> firstAfter
            )

            images.Set(workspace, first, None) |> wait |> result |> ignore
            let removed = images.Read(workspace, first) |> wait |> result
            writer.WriteBoolean("removalRestoresDefault", (removed = None))
            writer.WriteBoolean("originalUntouched", (File.ReadAllBytes original = initial))

            let ownedFolder = Path.Combine(state, "profile-images", workspace.ToString("N"))
            let foreign = Path.Combine(ownedFolder, "foreign.txt")
            File.WriteAllText(foreign, "keep")

        do
            use restarted = new OperationStore(state)
            let workspaces = restarted.Workspaces :> IWorkspaceState
            let images = restarted.ProfileImages
            let removed = images.Read(workspace, first) |> wait |> result
            writer.WriteBoolean("restartRemoval", (removed = None))
            let kept = images.Read(workspace, copy) |> wait |> result

            writer.WriteBoolean(
                "restartOverride",
                (kept |> Option.map File.ReadAllBytes) = Some initial
            )

            writer.WriteBoolean("restartOriginal", (File.ReadAllBytes original = initial))

            let current = workspaces.Read(workspace, None) |> wait |> result

            let selected =
                workspaces.Edit(workspace, current.Workspace.Revision, ProfileEdit.Select first)
                |> wait
                |> result

            workspaces.Edit(workspace, selected.Workspace.Revision, ProfileEdit.Delete copy)
            |> wait
            |> result
            |> ignore

            let ownedFolder = Path.Combine(state, "profile-images", workspace.ToString("N"))
            let foreign = Path.Combine(ownedFolder, "foreign.txt")
            let missing = images.Read(workspace, copy) |> wait = Error WorkspaceError.NotFound

            writer.WriteBoolean(
                "deleteOwnedOnly",
                not (File.Exists(Path.Combine(ownedFolder, copy.ToString("N") + ".image")))
                && File.ReadAllText foreign = "keep"
                && missing
            )

        writer.WriteEndObject()
