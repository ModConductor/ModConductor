namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open ModConductor.Persistence
open ModConductor.ModLibrary
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
                          Category = "" },
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
