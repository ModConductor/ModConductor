namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Buffers.Binary
open System.Text
open System.Text.Json
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Workspaces

module GameContextFixtures =
    let private image patch =
        let bytes = Array.zeroCreate<byte> 1536

        let word offset value =
            BinaryPrimitives.WriteUInt16LittleEndian(bytes.AsSpan(offset, 2), value)

        let number offset value =
            BinaryPrimitives.WriteUInt32LittleEndian(bytes.AsSpan(offset, 4), value)

        word 0 0x5A4Dus
        number 60 128u
        number 128 0x4550u
        word 132 0x8664us
        word 134 1us
        word 148 240us
        word 152 0x20Bus
        number 260 16u
        number 280 0x1000u
        number 284 1024u
        number 404 0x1000u
        number 408 1024u
        number 412 512u
        word 526 1us
        number 528 16u
        number 532 0x80000020u
        word 558 1us
        number 560 1u
        number 564 0x80000040u
        word 590 1us
        number 592 1033u
        number 596 96u
        number 608 0x1100u
        number 612 92u
        word 768 92us
        word 770 52us
        Encoding.Unicode.GetBytes("VS_VERSION_INFO\000").CopyTo(bytes, 774)
        number 808 0xFEEF04BDu
        number 812 0x10000u
        number 816 0x10007u
        number 820 (uint32 patch <<< 16)
        number 824 0x10007u
        number 828 (uint32 patch <<< 16)
        bytes

    let create path patch =
        Directory.CreateDirectory(Path.Combine(path, "Data")) |> ignore
        let bytes = image patch
        File.WriteAllBytes(Path.Combine(path, "SkyrimSE.exe"), bytes)
        File.WriteAllBytes(Path.Combine(path, "SkyrimSELauncher.exe"), bytes)

    let observe (writer: Utf8JsonWriter) primary =
        let wait = StorageWorker.wait
        let result = StorageWorker.result
        let game = Path.Combine(primary, "game-contexts", "game")
        create game 104
        let exe = Path.Combine(game, "SkyrimSE.exe")
        let initialBytes = File.ReadAllBytes exe
        let initialNames = Directory.GetFileSystemEntries(game) |> Array.sort

        let knownFolderPaths =
            if OperatingSystem.IsWindows() then
                [ Environment.SpecialFolder.MyDocuments, Skyrim.definition.Documents
                  Environment.SpecialFolder.MyDocuments, Skyrim.definition.Saves
                  Environment.SpecialFolder.LocalApplicationData, Skyrim.definition.LocalAppData ]
                |> List.map (fun (folder, components) ->
                    let root =
                        Environment.GetFolderPath(
                            folder,
                            Environment.SpecialFolderOption.DoNotVerify
                        )

                    if String.IsNullOrEmpty root then
                        None
                    else
                        let path = Path.Combine(Array.ofList (root :: components))
                        Some(path, Directory.Exists path))
            else
                []

        let inspected = InstallationValidation.inspect game
        writer.WriteStartObject("gameContexts")

        writer.WriteBoolean(
            "structuredVersion",
            inspected.Valid && inspected.Executable.Value.FileVersion = "1.7.104.0"
        )

        writer.WriteString(
            "fileVersion",
            inspected.Executable |> Option.map _.FileVersion |> Option.defaultValue ""
        )

        writer.WriteString(
            "exeHash",
            inspected.Executable |> Option.map _.Sha256 |> Option.defaultValue ""
        )

        writer.WriteBoolean(
            "readOnlyValidation",
            initialBytes = File.ReadAllBytes exe
            && initialNames = (Directory.GetFileSystemEntries(game) |> Array.sort)
        )

        let userFoldersUnchanged =
            if OperatingSystem.IsWindows() then
                List.zip
                    knownFolderPaths
                    [ inspected.Locations.Documents
                      inspected.Locations.Saves
                      inspected.Locations.LocalAppData ]
                |> List.forall (fun (before, observed) ->
                    match before, observed with
                    | Some(path, existed), Location.Located(actual, exists) ->
                        actual = path && exists = existed && Directory.Exists path = existed
                    | None, Location.Unavailable _ -> true
                    | _ -> false)
            else
                true

        writer.WriteBoolean("knownFoldersRemainUnchanged", userFoldersUnchanged)

        let malformed = image 104
        BinaryPrimitives.WriteUInt32LittleEndian(malformed.AsSpan(564, 4), 0x80000020u)
        File.WriteAllBytes(exe, malformed)
        let cyclic = InstallationValidation.inspect game
        File.WriteAllBytes(exe, initialBytes[..779])
        let truncated = InstallationValidation.inspect game
        let noVersion = image 104
        BinaryPrimitives.WriteUInt32LittleEndian(noVersion.AsSpan(528, 4), 10u)
        Encoding.Unicode.GetBytes("FileVersion\0001.7.104.0").CopyTo(noVersion, 1200)
        File.WriteAllBytes(exe, noVersion)
        let stringsOnly = InstallationValidation.inspect game

        writer.WriteBoolean(
            "malformedVersionsRefused",
            not cyclic.Valid && not truncated.Valid && not stringsOnly.Valid
        )

        create game 104

        let statePath =
            Directory.CreateDirectory(Path.Combine(primary, "game-contexts", "state")).FullName

        let first, second = Guid.NewGuid(), Guid.NewGuid()
        let mutable prior = Unchecked.defaultof<GameContextState>

        do
            use store = new OperationStore(statePath)
            let workspaces = store.Workspaces :> IWorkspaceState
            let contexts = store.GameContexts :> IGameContexts

            for id in [ first; second ] do
                let root =
                    Directory
                        .CreateDirectory(Path.Combine(primary, "game-contexts", id.ToString("N")))
                        .FullName

                workspaces.Create(id, "Context", StorageWorker.select root)
                |> wait
                |> result
                |> ignore

            let empty = contexts.Read first |> wait |> result
            let saved = contexts.Save(first, empty.Revision, game) |> wait |> result
            let other = contexts.Save(second, 0L, game) |> wait |> result

            writer.WriteBoolean(
                "workspacesShareInstallation",
                saved.Binding.Value.Path = other.Binding.Value.Path
                && saved.Binding.Value.Id <> other.Binding.Value.Id
            )

            let workspace = workspaces.Read(first, None) |> wait |> result
            let profileId = Guid.NewGuid()

            let created =
                workspaces.Edit(
                    first,
                    workspace.Workspace.Revision,
                    ProfileEdit.Create { Id = profileId; Name = "Everyday" }
                )
                |> wait
                |> result

            workspaces.Edit(
                first,
                created.Workspace.Revision,
                ProfileEdit.Clone(profileId, { Id = Guid.NewGuid(); Name = "Copy" })
            )
            |> wait
            |> result
            |> ignore

            writer.WriteBoolean(
                "profilesPreserveBinding",
                contexts.Read first |> wait |> result = saved
            )

            let stale = contexts.Save(first, 0L, game) |> wait

            writer.WriteBoolean(
                "staleSavePreservesBinding",
                stale = Error ContextError.StaleRevision
                && (contexts.Read first |> wait |> result) = saved
            )

            let missing =
                contexts.Save(first, saved.Revision, Path.Combine(game, "absent")) |> wait

            writer.WriteBoolean(
                "invalidReplacementPreservesBinding",
                (match missing with
                 | Error(ContextError.Invalid e) -> not e.Valid
                 | _ -> false)
                && (contexts.Read first |> wait |> result) = saved
            )

            File.Move(exe, exe + ".moved")
            let failed = contexts.Refresh(first, saved.Revision) |> wait |> result

            writer.WriteBoolean(
                "failedRefreshRetainsEvidence",
                failed.Binding.Value.NeedsCheck
                && failed.Binding.Value.Failure.IsSome
                && failed.Binding.Value.Evidence = saved.Binding.Value.Evidence
                && failed.Binding.Value.Path = game
            )

            File.Move(exe + ".moved", exe)
            let refreshed = contexts.Refresh(first, failed.Revision) |> wait |> result

            writer.WriteBoolean(
                "refreshRestoresCurrentEvidence",
                not refreshed.Binding.Value.NeedsCheck
                && refreshed.Binding.Value.Failure.IsNone
                && refreshed.Binding.Value.Evidence.Fingerprint = saved.Binding.Value.Evidence.Fingerprint
            )

            prior <- refreshed

        do
            use store = new OperationStore(statePath)
            let contexts = store.GameContexts :> IGameContexts
            let reopened = contexts.Read first |> wait |> result

            writer.WriteBoolean(
                "restartRequiresRecheck",
                reopened.Binding.Value.NeedsCheck
                && reopened.Binding.Value.Evidence = prior.Binding.Value.Evidence
                && reopened.Binding.Value.Id = prior.Binding.Value.Id
            )

            create game 105
            let refreshed = contexts.Refresh(first, reopened.Revision) |> wait |> result

            writer.WriteBoolean(
                "changedExecutableGetsNewEvidence",
                refreshed.Binding.Value.Evidence.Executable.Value.FileVersion = "1.7.105.0"
                && refreshed.Binding.Value.Evidence.Fingerprint
                   <> prior.Binding.Value.Evidence.Fingerprint
            )

            let missingData = Path.Combine(game, "Data-away")
            Directory.Move(Path.Combine(game, "Data"), missingData)
            let invalid = InstallationValidation.inspect game

            writer.WriteBoolean(
                "missingDataNotValid",
                not invalid.Valid && invalid.Executable.IsSome
            )

        let noHostFolders =
            if OperatingSystem.IsLinux() then
                match
                    inspected.Locations.Documents,
                    inspected.Locations.Saves,
                    inspected.Locations.LocalAppData
                with
                | Location.Unavailable _, Location.Unavailable _, Location.Unavailable _ -> true
                | _ -> false
            else
                true

        writer.WriteBoolean("protonHasNoHostFolders", noHostFolders)
        writer.WriteEndObject()
