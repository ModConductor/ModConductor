namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.Persistence
open ModConductor.ModLibrary
open ModConductor.ModOrganization
open ModConductor.Platform
open ModConductor.Workspaces

module LibraryRecoveryFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartArray("libraryWindows")

        for mode in [ "effect"; "observed"; "live"; "cancel"; "source-change"; "payload-change" ] do
            let area =
                Directory.CreateDirectory(Path.Combine(primary, "library-" + mode)).FullName

            let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
            let root = Directory.CreateDirectory(Path.Combine(area, "root")).FullName
            let source = Directory.CreateDirectory(Path.Combine(root, "source")).FullName
            File.WriteAllText(Path.Combine(source, "file.txt"), "original")
            let workspace, modId, version = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

            do
                use store = new OperationStore(state)

                (store.Workspaces :> IWorkspaceState)
                    .Create(workspace, "Interruption", StorageWorker.select root)
                |> wait
                |> result
                |> ignore

                (store.ModLibrary :> IModLibrary)
                    .Register(
                        workspace,
                        modId,
                        { Name = "Fixture"
                          Notes = ""
                          Comment = ""
                          Version = ""
                          Source = ""
                          Categories = [] },
                        Registration.Directory(
                            ModKind.Regular,
                            LogicalPath.create [ "source" ] |> result
                        )
                    )
                |> wait
                |> result
                |> ignore

            let checkpoint =
                if mode = "effect" || mode = "cancel" || mode = "source-change" then
                    "effect"
                else
                    "observed"

            use child =
                new NativeChild(
                    Environment.ProcessPath,
                    [ "--library-worker"; checkpoint; state; string modId; string version ]
                )

            child.Line() |> ignore
            writer.WriteStartObject()
            writer.WriteString("window", mode)

            if mode = "effect" || mode = "observed" then
                child.Terminate()
                use restarted = new OperationStore(state)
                let library = restarted.ModLibrary :> IModLibrary
                let before = library.Publication version |> wait |> result

                writer.WriteBoolean(
                    "unpublishedBeforeRecovery",
                    library.Version(version, 0) |> wait = Error LibraryError.NotFound
                )

                writer.WriteString(
                    "phaseBefore",
                    if before.Phase = PublicationPhase.Observed then
                        "observed"
                    elif before.Phase = PublicationPhase.Interrupted then
                        "interrupted"
                    else
                        "unexpected"
                )

                let resumed = library.Publish(modId, 0L, version) |> wait
                writer.WriteBoolean("resumed", Result.isOk resumed)

                writer.WriteNumber(
                    "payloadsPreserved",
                    Directory.GetFiles(root, "*.payload", SearchOption.AllDirectories).Length
                )
            else
                use observer = new OperationStore(state)
                let library = observer.ModLibrary :> IModLibrary

                writer.WriteBoolean(
                    "liveRefused",
                    library.Publish(modId, 0L, version) |> wait = Error LibraryError.Busy
                )

                writer.WriteBoolean(
                    "unpublishedWhileLive",
                    library.Version(version, 0) |> wait = Error LibraryError.NotFound
                )

                if mode = "cancel" then
                    let cancelled = library.CancelPublication version |> wait |> result

                    writer.WriteBoolean(
                        "cancelDurable",
                        cancelled.Phase = PublicationPhase.Cancelled
                    )

                    writer.WriteBoolean(
                        "retryWhileClosingRefused",
                        library.Publish(modId, 0L, Guid.NewGuid()) |> wait = Error LibraryError.Busy
                    )
                elif mode = "source-change" then
                    File.WriteAllText(Path.Combine(source, "file.txt"), "external edit")
                elif mode = "payload-change" then
                    let payload =
                        Directory.GetFiles(root, "*.payload", SearchOption.AllDirectories)
                        |> Array.exactlyOne

                    if OperatingSystem.IsWindows() then
                        File.SetAttributes(payload, FileAttributes.Normal)
                    else
                        File.SetUnixFileMode(
                            payload,
                            UnixFileMode.UserRead ||| UnixFileMode.UserWrite
                        )

                    File.WriteAllText(payload, "external payload")

                child.Send "continue"
                writer.WriteString("workerResult", child.Line())
                child.Finish()

                if mode = "cancel" then
                    writer.WriteBoolean(
                        "cancelledPublicationRemoved",
                        library.Publication version |> wait = Error LibraryError.NotFound
                    )

                    writer.WriteBoolean(
                        "cancelledPayloadsRemoved",
                        Directory.GetFiles(root, "*.payload", SearchOption.AllDirectories).Length =
                            0
                    )

                    writer.WriteBoolean("committed", false)
                else
                    let receipt = library.Publication version |> wait |> result
                    writer.WriteBoolean("committed", receipt.Phase = PublicationPhase.Complete)

                if mode = "live" then
                    writer.WriteBoolean(
                        "cancelAfterCommitKeepsResult",
                        (library.CancelPublication version |> wait |> result).Phase =
                            PublicationPhase.Complete
                    )

                if mode = "payload-change" then
                    writer.WriteBoolean(
                        "changedPayloadPreserved",
                        Directory.GetFiles(root, "*.payload", SearchOption.AllDirectories)
                        |> Array.exists (fun file -> File.ReadAllText file = "external payload")
                    )

            for file in Directory.GetFiles(root, "*.payload", SearchOption.AllDirectories) do
                if OperatingSystem.IsWindows() then
                    File.SetAttributes(file, FileAttributes.Normal)

            writer.WriteEndObject()

        writer.WriteEndArray()

        let admissionArea =
            Directory.CreateDirectory(Path.Combine(primary, "library-admission")).FullName

        let state = Directory.CreateDirectory(Path.Combine(admissionArea, "state")).FullName
        use store = new OperationStore(state)
        let workspaces = store.Workspaces :> IWorkspaceState
        let library = store.ModLibrary :> IModLibrary
        let organization = store.ModOrganization :> IModOrganization

        let createWorkspace name =
            let workspace, profile, modId = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
            let root = Directory.CreateDirectory(Path.Combine(admissionArea, name)).FullName
            let source = Directory.CreateDirectory(Path.Combine(root, "source")).FullName
            File.WriteAllText(Path.Combine(source, "file.txt"), name)

            let created =
                workspaces.Create(workspace, name, StorageWorker.select root) |> wait |> result

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = name }
            )
            |> wait
            |> result
            |> ignore

            let entry =
                library.Register(
                    workspace,
                    modId,
                    { Name = name
                      Notes = ""
                      Comment = ""
                      Version = ""
                      Source = ""
                      Categories = [] },
                    Registration.Directory(
                        ModKind.Regular,
                        LogicalPath.create [ "source" ] |> result
                    )
                )
                |> wait
                |> result

            workspace, profile, entry

        let workspace, profile, entry = createWorkspace "active"
        let _, otherProfile, otherEntry = createWorkspace "other"
        let version = Guid.NewGuid()
        use entered = new ManualResetEventSlim()
        use release = new ManualResetEventSlim()

        let publishing =
            store.ModLibrary.PublishAtCheckpoint(
                entry.Id,
                entry.Revision,
                version,
                (fun () ->
                    entered.Set()
                    release.Wait()),
                ignore
            )

        if not (entered.Wait(TimeSpan.FromSeconds 5.)) then
            invalidOp "The publication did not reach the admission boundary."

        let sameRead =
            organization.Query(profile, InventoryObservations.query, None, None) |> wait

        let otherRead =
            organization.Query(otherProfile, InventoryObservations.query, None, None)
            |> wait

        let otherEdit =
            library.Edit(
                otherEntry.Id,
                otherEntry.Revision,
                { otherEntry.Metadata with
                    Notes = "Unrelated" }
            )
            |> wait

        let blocked =
            library.Edit(
                entry.Id,
                entry.Revision,
                { entry.Metadata with
                    Notes = "Blocked" }
            )
            |> wait

        let locallyBusy = blocked = Error LibraryError.Busy
        let cancelled = library.CancelPublication version |> wait |> result
        release.Set()
        let stopped = publishing |> wait

        let afterCancellation =
            library.Edit(
                entry.Id,
                entry.Revision,
                { entry.Metadata with
                    Notes = "Available" }
            )
            |> wait

        writer.WriteStartObject("libraryAdmission")
        writer.WriteBoolean("readsContinueDuringMutation", Result.isOk sameRead)

        writer.WriteBoolean(
            "otherWorkspaceContinues",
            Result.isOk otherRead && Result.isOk otherEdit
        )

        writer.WriteBoolean("conflictingMutationIsBusy", locallyBusy)

        writer.WriteBoolean(
            "cancelReleasesMutation",
            cancelled.Phase = PublicationPhase.Cancelled
            && stopped = Error LibraryError.Cancelled
            && Result.isOk afterCancellation
        )

        writer.WriteString("workspace", workspace)
        writer.WriteEndObject()

        let initializationArea =
            Directory.CreateDirectory(Path.Combine(primary, "library-initialization")).FullName

        let initializationState =
            Directory.CreateDirectory(Path.Combine(initializationArea, "state")).FullName

        let initializationRoot =
            Directory.CreateDirectory(Path.Combine(initializationArea, "root")).FullName

        let initializationSource =
            Directory.CreateDirectory(Path.Combine(initializationRoot, "source")).FullName

        File.WriteAllText(Path.Combine(initializationSource, "file.txt"), "source")
        let initializationWorkspace = Guid.NewGuid()

        do
            use initializing = new OperationStore(initializationState)

            (initializing.Workspaces :> IWorkspaceState)
                .Create(
                    initializationWorkspace,
                    "Initialization",
                    StorageWorker.select initializationRoot
                )
            |> wait
            |> result
            |> ignore

        use initializationChild =
            new NativeChild(
                Environment.ProcessPath,
                [ "--library-worker"
                  "initialize"
                  initializationState
                  string initializationWorkspace
                  string Guid.Empty ]
            )

        initializationChild.Line() |> ignore
        initializationChild.Terminate()

        use recovered = new OperationStore(initializationState)
        let recoveredMod = Guid.NewGuid()

        let recoveredEntry =
            (recovered.ModLibrary :> IModLibrary)
                .Register(
                    initializationWorkspace,
                    recoveredMod,
                    { Name = "Recovered"
                      Notes = ""
                      Comment = ""
                      Version = ""
                      Source = ""
                      Categories = [] },
                    Registration.Directory(
                        ModKind.Regular,
                        LogicalPath.create [ "source" ] |> result
                    )
                )
            |> wait

        writer.WriteStartObject("libraryInitialization")
        writer.WriteBoolean("staleOwnerCanRetry", Result.isOk recoveredEntry)
        writer.WriteEndObject()
