namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.ArchiveInstallation
open ModConductor.ArtifactLibrary
open ModConductor.Bethesda
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module ProfileTransportFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None
    let private path parts = LogicalPath.create parts |> result

    let private check name passed =
        if not passed then invalidOp ("Profile transport fixture failed: " + name)
        passed

    let private archive destination =
        use stream = File.Create destination
        use zip = new ZipArchive(stream, ZipArchiveMode.Create)

        for name, content in
            [ "Variant A/edited.ini", "first=one\nsecond=two\n"
              "Variant A/removed.txt", "remove me"
              "Variant A/retained.txt", "keep me"
              "Variant B/edited.ini", "wrong variant" ] do
            use memberFile = zip.CreateEntry(name).Open()
            let bytes = Encoding.UTF8.GetBytes content
            memberFile.Write bytes

    let private gameProfile (store: OperationStore) workspace game proton =
        let workspaces = store.Workspaces :> IWorkspaceState
        let opened = workspaces.Read(workspace, None) |> wait |> result
        let profile = Guid.NewGuid()

        workspaces.Edit(
            workspace,
            opened.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Original" }
        )
        |> wait |> result |> ignore

        (store.GameContexts :> IGameContexts).Save(
            workspace, profile, 0L,
            { GameId = GameId.SkyrimSpecialEditionSteam
              Path = game
              Proton = if OperatingSystem.IsLinux() then Some proton else None }
        )
        |> wait |> result |> ignore
        profile

    let private install (store: OperationStore) workspace source =
        let artifact =
            store.Artifacts.Add(
                { Id = Guid.NewGuid(); WorkspaceId = workspace; Path = source; Storage = ArtifactStorage.Copy },
                token
            ) |> wait |> result
        let reference =
            { ArtifactRef.WorkspaceId = workspace; Id = artifact.Id; Revision = artifact.Revision }
        let prepared = store.Installations.Prepare(reference, token) |> wait |> result
        let rooted =
            store.Installations.Change(
                workspace, prepared.Id, prepared.Revision, LayoutChange.Root [ "Variant A" ]
            ) |> result
        let selected =
            rooted.Manifest.Entries
            |> List.filter (fun entry ->
                not entry.Directory
                && (LogicalPath.components entry.Path |> List.tryHead) = Some "Variant A")
            |> List.map (fun entry ->
                { SelectedFile.Index = entry.Index
                  Destination = path (LogicalPath.components entry.Path |> List.tail) })
        let reviewed =
            store.Installations.SelectReviewed(
                workspace, rooted.Id, rooted.Revision, "Variant mod", "1", selected
            ) |> result
        let started =
            store.Installations.Start(workspace, reviewed.Id, reviewed.Revision, Guid.NewGuid()) |> result
        let completed =
            store.Installations.UntilStopped(workspace, started.Id, started, token) |> wait |> result
        if completed.State <> InstallationState.Complete then
            invalidOp (defaultArg completed.Problem "The selected source did not install.")
        artifact, completed.ModId.Value, completed.VersionId.Value

    let private edit (store: OperationStore) profile modId version area =
        let stage = Directory.CreateDirectory(Path.Combine(area, "changed")).FullName
        File.WriteAllText(Path.Combine(stage, "edited.ini"), "first=one\nsecond=changed\n")
        File.WriteAllText(Path.Combine(stage, "added.ini"), "new=yes\n")
        let selected = StorageWorker.select stage
        let identity =
            match (RootSelection.facts selected).File with
            | Known value -> value
            | Unknown _ -> invalidOp "The changed files are unavailable."
        use held = HeldDirectory.Open(RootSelection.path selected, identity)
        let files = SourceFiles.scan held Set.empty 100000 ignore |> result |> fst
        let row =
            (InventoryObservations.read store profile).Entries
            |> List.find (fun row -> row.Entry.Mod.Id = modId)
        let input =
            { ActionId = Guid.NewGuid()
              SourceVersion = Some version
              VersionLabel = "1"
              Policy = Skyrim.definition.TargetPolicy
              Files =
                files |> List.map (fun file ->
                    { Target = file.Path
                      Root = RootSelection.path selected
                      RootIdentity = identity
                      File = file })
              Bytes = []
              Deleted = [ path [ "removed.txt" ] ] }
        store.ModLibrary.Access.Run(fun () ->
            store.ModLibrary.PublicationOwner.Compose(
                modId, row.Entry.Mod.Revision, Guid.NewGuid(), input, token, ignore, ignore, ignore
            )) |> wait |> result |> ignore

    let private portable file =
        use bundle = new ProfileTransportZip.Bundle(file)
        bundle.Profile

    let private files (store: OperationStore) profile =
        let row =
            (InventoryObservations.read store profile).Entries
            |> List.find (fun row -> row.Entry.Mod.Metadata.Name = "Variant mod")
        (store.ModLibrary :> IModLibrary).Version(row.Entry.Mod.CurrentVersion.Value, 0)
        |> wait |> result
        |> _.Entries
        |> List.map (fun file -> LogicalPath.display file.Path, file.Payload.Sha256)
        |> Map.ofList

    let observe (writer: Utf8JsonWriter) area =
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
        let source = Path.Combine(area, "Variant source.zip")
        archive source
        let workspace = Guid.NewGuid()
        use store = new OperationStore(state)
        let workspaces = store.Workspaces :> IWorkspaceState
        workspaces.Create(workspace, "Transport", StorageWorker.select root)
        |> wait |> result |> ignore
        let original = gameProfile store workspace game proton
        let artifact, modId, version = install store workspace source
        let inventory = InventoryObservations.read store original
        (store.ModSelection :> IModSelection).Change(
            original, inventory.SelectionRevision, [ modId ], SelectionEdit.Enable true
        ) |> wait |> result |> ignore
        edit store original modId version area

        let editedVersion =
            (InventoryObservations.read store original).Entries
            |> List.find (fun row -> row.Entry.Mod.Id = modId)
            |> _.Entry.Mod.CurrentVersion.Value

        do
            use connection =
                new Microsoft.Data.Sqlite.SqliteConnection(
                    "Data Source=" + Path.Combine(state, "state.db") + ";Pooling=False"
                )

            connection.Open()
            Sqlite.execute
                connection
                null
                "INSERT INTO hidden_mod_files(workspace_id,mod_id,version_id,path,hidden) VALUES($workspace,$mod,$version,$path,1)"
                [ "$workspace", box (string workspace)
                  "$mod", box (string modId)
                  "$version", box (string editedVersion)
                  "$path", box (LibraryEncoding.path (path [ "edited.ini" ])) ]

        let local = Directory.CreateDirectory(Path.Combine(root, "local files")).FullName
        File.WriteAllText(Path.Combine(local, "owned.txt"), "portable local content")
        let localId = Guid.NewGuid()
        let library = store.ModLibrary :> IModLibrary
        let registered =
            library.Register(
                workspace,
                localId,
                { Name = "Local owned mod"
                  Notes = ""
                  Comment = ""
                  Version = "1"
                  Source = ""
                  Categories = [] },
                Registration.Directory(ModKind.Regular, path [ "local files" ])
            ) |> wait |> result
        library.Publish(localId, registered.Revision, Guid.NewGuid()) |> wait |> result |> ignore
        let inventory = InventoryObservations.read store original
        (store.ModSelection :> IModSelection).Change(
            original, inventory.SelectionRevision, [ localId ], SelectionEdit.Enable true
        ) |> wait |> result |> ignore

        let privateData = store.ProfileGameData
        let beforePrivate = privateData.Read(workspace, original) |> wait |> result
        let enabledPrivate =
            privateData.Edit(
                { Id = Guid.NewGuid()
                  Expected = beforePrivate.Reference
                  Options = { Settings = true; Saves = true }
                  InitialSaves = InitialSaves.Empty
                  DisabledFiles = DisabledFiles.Keep },
                ignore,
                token
            ) |> wait |> result

        if not enabledPrivate.Complete then invalidOp "The fixture private folders were not created."
        File.WriteAllText(Path.Combine(enabledPrivate.State.SettingsPath, "SkyrimCustom.ini"), "portable setting")
        File.WriteAllText(Path.Combine(enabledPrivate.State.SavesPath, "personal.ess"), "private save")

        do
            use connection =
                new Microsoft.Data.Sqlite.SqliteConnection(
                    "Data Source=" + Path.Combine(state, "state.db") + ";Pooling=False"
                )

            connection.Open()
            use transaction = connection.BeginTransaction(deferred = false)
            use query =
                Sqlite.command
                    connection
                    transaction
                    "SELECT context_id FROM profile_data_profiles WHERE profile_id=$profile"
                    [ "$profile", box (string original) ]

            let contextId = Guid.Parse(query.ExecuteScalar() :?> string)
            let row = ProfileDataRows.profile connection transaction contextId original |> Option.get
            let order: PluginOrder =
                { Document = Array.empty
                  Entries =
                    [ { Name = "Disabled.esp"
                        Enabled = Some false
                        LockedIndex = None } ] }

            ProfileDataRows.saveProfile
                connection
                transaction
                contextId
                { row with Revision = row.Revision + 1L; PluginOrder = Some order }
            transaction.Commit()

        let image = Path.Combine(area, "chosen-image.png")
        let imageBytes = [| 1uy; 2uy; 3uy; 4uy |]
        File.WriteAllBytes(image, imageBytes)
        store.ProfileImages.Set(workspace, original, Some image) |> wait |> result |> ignore

        let first, second, third, withSaves =
            Path.Combine(area, "first.mcprof"),
            Path.Combine(area, "second.mcprof"),
            Path.Combine(area, "third.mcprof"),
            Path.Combine(area, "with-saves.mcprof")
        store.ProfileTransport.Export(workspace, original, first, false, token) |> wait |> result
        store.ProfileTransport.Export(workspace, original, withSaves, true, token) |> wait |> result
        let initial = portable first
        let includedSaves = portable withSaves
        let import file name =
            store.ProfileTransport.Import(
                file, workspace, Some original, name, Map.ofList [ 0, artifact.Id ], token
            ) |> wait |> result
        let imported = import first "Imported"
        store.ProfileTransport.Export(workspace, imported, second, false, token) |> wait |> result
        let next = portable second
        let importedAgain = import second "Imported again"
        store.ProfileTransport.Export(workspace, importedAgain, third, false, token) |> wait |> result
        let final = portable third
        let canonicalContent file =
            use zip = ZipFile.OpenRead file

            zip.Entries
            |> Seq.filter (fun entry -> entry.FullName <> "profile.json")
            |> Seq.map (fun entry ->
                use source = entry.Open()
                use bytes = new MemoryStream()
                source.CopyTo bytes
                entry.FullName, entry.LastWriteTime, bytes.ToArray())
            |> Seq.toList

        let unsafeProfile = Path.Combine(area, "unsafe.mcprof")

        do
            use source = ZipFile.OpenRead first
            use target = ZipFile.Open(unsafeProfile, ZipArchiveMode.Create)

            for entry in source.Entries do
                use input = entry.Open()
                use bytes = new MemoryStream()
                input.CopyTo bytes
                let content =
                    if entry.FullName = "profile.json" then
                        Encoding.UTF8.GetString(bytes.ToArray()).Replace("\"added.ini\"", "\"..\"")
                        |> Encoding.UTF8.GetBytes
                    else
                        bytes.ToArray()

                use output = target.CreateEntry(entry.FullName).Open()
                output.Write content

        let unsafeRejected =
            try
                store.ProfileTransport.Inspect unsafeProfile |> ignore
                false
            with :? InvalidDataException -> true

        let before = workspaces.Read(workspace, None) |> wait |> result
        let missing =
            store.ProfileTransport.Import(first, workspace, Some original, "Missing source", Map.empty, token)
            |> wait
        let after = workspaces.Read(workspace, None) |> wait |> result

        writer.WriteStartObject("profileTransport")
        writer.WriteBoolean(
            "patchAndDeletion",
            check "patch and deletion"
                (initial.Mods.Head.Base.IsSome
                 && initial.Mods.Head.Deleted = [ [ "removed.txt" ] ]
                 && initial.Mods.Head.Hidden = [ [ "edited.ini" ] ]
                 && (initial.Mods.Head.Files |> List.exists (fun file ->
                    match file.Content with
                    | PortableContent.Patch _ -> true
                    | _ -> false)))
        )
        writer.WriteBoolean("effectiveFiles", check "effective files" (files store original = files store imported && (files store imported).Count = 3))
        writer.WriteBoolean(
            "localPayload",
            check "local payload"
                (initial.Mods.Length = 2
                 && initial.Mods[1].Base.IsNone
                 && (initial.Mods[1].Files |> List.exists (fun file ->
                     match file.Content with
                     | PortableContent.Payload _ -> true
                     | _ -> false)))
        )
        writer.WriteBoolean(
            "savesOptIn",
            check "saves opt-in"
                (initial.Settings.Length = 1
                 && initial.Saves.IsEmpty
                 && initial.SavesEnabled
                 && includedSaves.Saves.Length = 1
                 && includedSaves.Saves.Head.Path = [ "personal.ess" ]
                 && initial.PluginOrder =
                    [ { Name = "Disabled.esp"
                        Enabled = Some false
                        LockedIndex = None } ])
        )
        writer.WriteBoolean(
            "artworkRestored",
            check "artwork restored"
                (initial.Artwork.IsSome
                 && (store.ProfileImages.Read(workspace, imported) |> wait |> result |> Option.map File.ReadAllBytes)
                    = Some imageBytes)
        )
        writer.WriteBoolean(
            "stableRepresentation",
            check "stable representation"
                ({ initial with Name = "" } = { next with Name = "" }
                 && { next with Name = "" } = { final with Name = "" })
        )
        writer.WriteBoolean(
            "canonicalZipContent",
            check "canonical ZIP content"
                (canonicalContent first = canonicalContent second
                 && canonicalContent second = canonicalContent third
                 && canonicalContent first
                    |> List.forall (fun (_, timestamp, _) ->
                        timestamp = DateTimeOffset(1980, 1, 1, 0, 0, 0, TimeSpan.Zero)))
        )
        writer.WriteBoolean(
            "missingExactSourceDoesNotCreateProfile",
            check "missing exact source" (Result.isError missing && before.Profiles = after.Profiles)
        )
        writer.WriteBoolean("unsafePathRejected", check "unsafe path" unsafeRejected)
        writer.WriteEndObject()
