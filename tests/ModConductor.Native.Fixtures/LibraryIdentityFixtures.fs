namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open ModConductor.Persistence
open ModConductor.ModLibrary
open ModConductor.Platform
open ModConductor.Workspaces

module LibraryIdentityFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private metadata =
        { Name = "Original"
          Notes = "Before"
          Comment = ""
          Version = ""
          Source = ""
          Categories = [] }

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject("libraryIdentity")

        for mode in [ "rename-before"; "rename-after" ] do
            let area = Directory.CreateDirectory(Path.Combine(primary, mode)).FullName
            let state = Path.Combine(area, "state")
            let root = Directory.CreateDirectory(Path.Combine(area, "root")).FullName

            let workspace, first, second, modId =
                Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

            do
                use store = new OperationStore(state)
                let workspaces = store.Workspaces :> IWorkspaceState

                workspaces.Create(workspace, "Rename", StorageWorker.select root)
                |> wait
                |> result
                |> ignore

                workspaces.Edit(workspace, 0L, ProfileEdit.Create { Id = first; Name = "Daily" })
                |> wait
                |> result
                |> ignore

                workspaces.Edit(workspace, 1L, ProfileEdit.Create { Id = second; Name = "Weekend" })
                |> wait
                |> result
                |> ignore

                (store.ModLibrary :> IModLibrary)
                    .Register(workspace, modId, metadata, Registration.Separator)
                |> wait
                |> result
                |> ignore

            use child =
                new NativeChild(
                    Environment.ProcessPath,
                    [ "--library-worker"; mode; state; string modId; string (Guid.NewGuid()) ]
                )

            child.Line() |> ignore
            child.Terminate()
            use reopened = new OperationStore(state)
            let library = reopened.ModLibrary :> IModLibrary

            let read profile =
                (InventoryObservations.read reopened profile).Entries
                |> List.map (fun row -> row.Entry.Mod)
                |> List.exactlyOne

            let actual = read first
            writer.WriteStartObject(mode)
            writer.WriteBoolean("profilesAgree", actual = read second && actual.Id = modId)
            writer.WriteNumber("revision", actual.Revision)
            writer.WriteString("name", actual.Metadata.Name)
            writer.WriteString("notes", actual.Metadata.Notes)
            writer.WriteEndObject()

        let area =
            Directory.CreateDirectory(Path.Combine(primary, "library-replacement")).FullName

        let root = Directory.CreateDirectory(Path.Combine(area, "root")).FullName
        let source = Directory.CreateDirectory(Path.Combine(root, "source")).FullName
        File.WriteAllText(Path.Combine(source, "file"), "original")
        let workspace, modId, version = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        use store = new OperationStore(Path.Combine(area, "state"))

        (store.Workspaces :> IWorkspaceState)
            .Create(workspace, "Replacement", StorageWorker.select root)
        |> wait
        |> result
        |> ignore

        let library = store.ModLibrary :> IModLibrary

        library.Register(
            workspace,
            modId,
            metadata,
            Registration.Directory(ModKind.Regular, LogicalPath.create [ "source" ] |> result)
        )
        |> wait
        |> result
        |> ignore

        library.Publish(modId, 0L, version) |> wait |> result |> ignore
        let manifest = library.Version(version, 0) |> wait |> result

        let libraryPath =
            Directory.GetDirectories(root, ".mod-conductor-library-*") |> Array.exactlyOne

        let overlap =
            library.Register(
                workspace,
                Guid.NewGuid(),
                metadata,
                Registration.Directory(
                    ModKind.Regular,
                    LogicalPath.create [ Path.GetFileName libraryPath ] |> result
                )
            )
            |> wait

        writer.WriteBoolean("storeOverlapRefused", (overlap = Error LibraryError.InvalidSource))
        Directory.Move(source, source + "-detached")
        Directory.CreateDirectory(source) |> ignore
        File.WriteAllText(Path.Combine(source, "foreign"), "not adopted")
        let scan = library.Scan(workspace, 1000) |> wait |> result

        writer.WriteBoolean(
            "replacementUnproved",
            scan.Entries.Head.Status = InventoryStatus.Unproved
        )

        writer.WriteBoolean(
            "replacementPublishRefused",
            library.Publish(modId, 1L, Guid.NewGuid()) |> wait |> Result.isError
        )

        writer.WriteBoolean(
            "replacementPreserved",
            File.ReadAllText(Path.Combine(source, "foreign")) = "not adopted"
        )

        writer.WriteBoolean(
            "oldVersionRetained",
            library.ReadPayload(version, manifest.Entries.Head.Payload.Id, 0L, 65536)
            |> wait
            |> Result.isOk
        )

        let payload =
            Path.Combine(libraryPath, manifest.Entries.Head.Payload.Id.ToString("N") + ".payload")

        if OperatingSystem.IsWindows() then
            File.SetAttributes(payload, FileAttributes.Normal)
        else
            File.SetUnixFileMode(payload, UnixFileMode.UserRead ||| UnixFileMode.UserWrite)

        File.WriteAllText(payload, "changed published file")

        writer.WriteBoolean(
            "changedPayloadRefused",
            library.ReadPayload(version, manifest.Entries.Head.Payload.Id, 0L, 65536)
            |> wait
            |> Result.isError
        )

        writer.WriteBoolean(
            "changedPayloadNotDeleted",
            File.ReadAllText payload = "changed published file"
        )

        writer.WriteBoolean(
            "tinyScanIsLimited",
            (library.Scan(workspace, 1) |> wait |> result).Limited
        )

        writer.WriteEndObject()
