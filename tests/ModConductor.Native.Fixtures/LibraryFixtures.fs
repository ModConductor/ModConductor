namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open ModConductor.ModLibrary
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces

module LibraryFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private path names = LogicalPath.create names |> result

    let private metadata name =
        { Name = name
          Notes = "Keep this note"
          Comment = "Local fixture"
          Version = "1.0"
          Source = "Manual directory"
          Category = "Visual" }

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "library")).FullName
        let root = Directory.CreateDirectory(Path.Combine(area, "root")).FullName
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let source = Directory.CreateDirectory(Path.Combine(root, "source")).FullName
        File.WriteAllText(Path.Combine(source, "first.txt"), "first version")
        File.WriteAllText(Path.Combine(source, "same.txt"), "same bytes")
        File.WriteAllText(Path.Combine(root, "foreign.txt"), "keep this")

        let workspace, profile, profile2, modId =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let version1, version2 = Guid.NewGuid(), Guid.NewGuid()
        writer.WriteStartObject("library")

        do
            use store = new OperationStore(state)
            let workspaces = store.Workspaces :> IWorkspaceState

            workspaces.Create(workspace, "Library fixture", StorageWorker.select root)
            |> wait
            |> result
            |> ignore

            workspaces.Edit(workspace, 0L, ProfileEdit.Create { Id = profile; Name = "Daily" })
            |> wait
            |> result
            |> ignore

            workspaces.Edit(workspace, 1L, ProfileEdit.Create { Id = profile2; Name = "Weekend" })
            |> wait
            |> result
            |> ignore

            let library = store.ModLibrary :> IModLibrary

            let registered =
                library.Register(
                    workspace,
                    modId,
                    metadata "Trees",
                    Registration.Directory(ModKind.Regular, path [ "source" ])
                )
                |> wait
                |> result

            let first = library.Publish(modId, registered.Revision, version1) |> wait |> result
            let old = library.Version(version1, 0) |> wait |> result
            File.WriteAllText(Path.Combine(source, "first.txt"), "second version")
            let second = library.Publish(modId, first.Revision, version2) |> wait |> result
            let current = library.Version(version2, 0) |> wait |> result

            let entry name (entries: ManifestEntry list) =
                entries |> List.find (fun value -> value.Path = path [ name ])

            writer.WriteBoolean(
                "unchangedShared",
                (entry "same.txt" old.Entries).Payload.Id =
                    (entry "same.txt" current.Entries).Payload.Id
            )

            writer.WriteBoolean(
                "changedDistinct",
                (entry "first.txt" old.Entries).Payload.Id
                <> (entry "first.txt" current.Entries).Payload.Id
            )

            let bytes =
                library.ReadPayload(version1, (entry "first.txt" old.Entries).Payload.Id, 0L, 65536)
                |> wait
                |> result

            writer.WriteBoolean("oldBytes", Encoding.UTF8.GetString bytes = "first version")

            let renamed =
                library.Edit(modId, second.Revision, metadata "Trees renamed") |> wait |> result

            let view id =
                (library.Inventory(id, None) |> wait |> result).Entries
                |> List.find (fun value -> value.Id = modId)

            writer.WriteBoolean(
                "sharedProfileRename",
                view profile = renamed && view profile2 = renamed
            )

            writer.WriteBoolean(
                "staleRefused",
                library.Edit(modId, second.Revision, metadata "Stale") |> wait =
                    Error LibraryError.StaleRevision
            )

            writer.WriteBoolean(
                "oldManifestUnchanged",
                library.Version(version1, 0) |> wait |> result = old
            )

            let payloadFolder =
                Directory.GetDirectories(root, ".mod-conductor-library-*") |> Array.exactlyOne

            let payload =
                Path.Combine(
                    payloadFolder,
                    (entry "first.txt" old.Entries).Payload.Id.ToString("N") + ".payload"
                )

            let refused =
                try
                    File.WriteAllText(payload, "ordinary write")
                    false
                with :? UnauthorizedAccessException ->
                    true

            writer.WriteBoolean("ordinaryWriteRefused", refused)

            writer.WriteBoolean(
                "sourceStillWritable",
                (File.GetAttributes(Path.Combine(source, "first.txt"))
                 &&& FileAttributes.ReadOnly) =
                    enum<FileAttributes> 0
            )

        do
            use store = new OperationStore(state)
            let library = store.ModLibrary :> IModLibrary

            let entry =
                (library.Inventory(profile, None) |> wait |> result).Entries
                |> List.find (fun value -> value.Id = modId)

            writer.WriteBoolean(
                "restartMetadata",
                entry.Metadata = metadata "Trees renamed"
                && entry.CurrentVersion = Some version2
            )

            writer.WriteBoolean(
                "foreignPreserved",
                File.ReadAllText(Path.Combine(root, "foreign.txt")) = "keep this"
            )
        // Restore only permissions on exact fixture-owned payloads so normal harness cleanup can remove them.
        for file in Directory.EnumerateFiles(root, "*.payload", SearchOption.AllDirectories) do
            if OperatingSystem.IsWindows() then
                File.SetAttributes(file, FileAttributes.Normal)

        writer.WriteEndObject()
