namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Buffers.Binary
open System.Text
open System.Text.Json
open System.Threading
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

        let inspected = InstallationValidation.inspect Skyrim.definition game
        writer.WriteStartObject("gameContexts")

        let installationCapability =
            CapabilityPolicy.tryFind Skyrim.definition.Id CapabilityId.GameInstallationValidation

        let legacyCapability =
            CapabilityPolicy.tryFind Skyrim.definition.Id CapabilityId.LegacyExtensionAbi

        let archiveCapability =
            CapabilityPolicy.tryFind Skyrim.definition.Id CapabilityId.ArchiveInspection

        let userCapabilities = CapabilityPolicy.forUsers Skyrim.definition.Id

        writer.WriteBoolean(
            "compiledCapabilitySupportsBothContexts",
            installationCapability
            |> Option.exists (fun capability ->
                capability.Disposition = CapabilityDisposition.Available
                && CapabilityPolicy.supports
                    Skyrim.definition.Id
                    ContextPlatform.Windows
                    capability
                && CapabilityPolicy.supports Skyrim.definition.Id ContextPlatform.Proton capability)
        )

        writer.WriteBoolean(
            "obsoleteExtensionMechanismUnsupported",
            legacyCapability
            |> Option.exists (fun capability ->
                match capability.Kind, capability.Audience, capability.Disposition with
                | CapabilityKind.ObsoleteMechanism,
                  CapabilityAudience.PolicyOnly,
                  CapabilityDisposition.Unsupported _ -> true
                | _ -> false)
        )

        writer.WriteBoolean(
            "archiveInspectionAvailable",
            archiveCapability
            |> Option.exists (fun capability ->
                capability.Kind = CapabilityKind.GameAdapter
                && capability.Audience = CapabilityAudience.User
                && capability.Disposition = CapabilityDisposition.Available)
        )

        writer.WriteBoolean(
            "policyOnlyCapabilityHiddenFromUsers",
            userCapabilities
            |> List.exists (fun capability -> capability.Id = CapabilityId.LegacyExtensionAbi)
            |> not
        )

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
        let cyclic = InstallationValidation.inspect Skyrim.definition game
        File.WriteAllBytes(exe, initialBytes[..779])
        let truncated = InstallationValidation.inspect Skyrim.definition game
        let noVersion = image 104
        BinaryPrimitives.WriteUInt32LittleEndian(noVersion.AsSpan(528, 4), 10u)
        Encoding.Unicode.GetBytes("FileVersion\0001.7.104.0").CopyTo(noVersion, 1200)
        File.WriteAllBytes(exe, noVersion)
        let stringsOnly = InstallationValidation.inspect Skyrim.definition game

        writer.WriteBoolean(
            "malformedVersionsRefused",
            not cyclic.Valid && not truncated.Valid && not stringsOnly.Valid
        )

        create game 104

        let statePath =
            Directory.CreateDirectory(Path.Combine(primary, "game-contexts", "state")).FullName

        let first, second = Guid.NewGuid(), Guid.NewGuid()

        let firstProfile, secondProfile, cloneProfile, unboundProfile =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let mutable prior = Unchecked.defaultof<GameContextState>

        do
            use store = new OperationStore(statePath)
            let workspaces = store.Workspaces :> IWorkspaceState
            let contexts = store.GameContexts :> IGameContexts

            for id, profile in [ first, firstProfile; second, secondProfile ] do
                let root =
                    Directory
                        .CreateDirectory(Path.Combine(primary, "game-contexts", id.ToString("N")))
                        .FullName

                let created =
                    workspaces.Create(id, "Context", StorageWorker.select root) |> wait |> result

                workspaces.Edit(
                    id,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = profile; Name = "Everyday" }
                )
                |> wait
                |> result
                |> ignore

            let empty = contexts.Read(first, firstProfile) |> wait |> result

            let saved =
                contexts.Save(
                    first,
                    firstProfile,
                    empty.Revision,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Proton = None }
                )
                |> wait
                |> result

            let other =
                contexts.Save(
                    second,
                    secondProfile,
                    0L,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Proton = None }
                )
                |> wait
                |> result

            writer.WriteBoolean(
                "workspacesShareInstallation",
                saved.Binding.Value.Path = other.Binding.Value.Path
                && saved.Binding.Value.Id <> other.Binding.Value.Id
            )

            let workspace = workspaces.Read(first, None) |> wait |> result

            let clonedWorkspace =
                workspaces.Edit(
                    first,
                    workspace.Workspace.Revision,
                    ProfileEdit.Clone(firstProfile, { Id = cloneProfile; Name = "Copy" })
                )
                |> wait
                |> result

            writer.WriteBoolean(
                "profilesPreserveBinding",
                let cloned = contexts.Read(first, cloneProfile) |> wait |> result

                cloned.Binding.Value.Path = saved.Binding.Value.Path
                && cloned.Binding.Value.GameId = saved.Binding.Value.GameId
                && cloned.Binding.Value.Id <> saved.Binding.Value.Id
            )

            let deploymentFingerprint =
                ModConductor.Deployment.DeploymentContextId.fingerprint saved.Binding.Value.Evidence

            writer.WriteBoolean(
                "profileDeploymentContextsAreDistinct",
                ModConductor.Deployment.DeploymentContextId.create
                    first
                    firstProfile
                    deploymentFingerprint
                <> ModConductor.Deployment.DeploymentContextId.create
                    first
                    cloneProfile
                    deploymentFingerprint
            )

            let withUnbound =
                workspaces.Edit(
                    first,
                    clonedWorkspace.Workspace.Revision,
                    ProfileEdit.Create
                        { Id = unboundProfile
                          Name = "Unbound" }
                )
                |> wait
                |> result

            let unbound = contexts.Read(first, unboundProfile) |> wait |> result

            writer.WriteBoolean(
                "unboundProfileSafe",
                unbound.Revision = 0L && unbound.Binding.IsNone
            )

            let alternate = Path.Combine(primary, "game-contexts", "alternate-game")
            create alternate 106
            let cloneBefore = contexts.Read(first, cloneProfile) |> wait |> result

            let changedClone =
                contexts.Save(
                    first,
                    cloneProfile,
                    cloneBefore.Revision,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = alternate
                      Proton = None }
                )
                |> wait
                |> result

            writer.WriteBoolean(
                "profilesIsolateBindings",
                changedClone.Binding.Value.Path = alternate
                && (contexts.Read(first, firstProfile) |> wait |> result) = saved
            )

            workspaces.Edit(first, withUnbound.Workspace.Revision, ProfileEdit.Delete cloneProfile)
            |> wait
            |> result
            |> ignore

            writer.WriteBoolean(
                "profileDeleteRemovesOnlyOwnedBinding",
                contexts.Read(first, cloneProfile) |> wait = Error ContextError.NotFound
                && (contexts.Read(first, firstProfile) |> wait |> result) = saved
            )

            let stale =
                contexts.Save(
                    first,
                    firstProfile,
                    0L,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Proton = None }
                )
                |> wait

            writer.WriteBoolean(
                "staleSavePreservesBinding",
                stale = Error ContextError.StaleRevision
                && (contexts.Read(first, firstProfile) |> wait |> result) = saved
            )

            let missing =
                contexts.Save(
                    first,
                    firstProfile,
                    saved.Revision,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = Path.Combine(game, "absent")
                      Proton = None }
                )
                |> wait

            writer.WriteBoolean(
                "invalidReplacementPreservesBinding",
                (match missing with
                 | Error(ContextError.Invalid e) -> not e.Valid
                 | _ -> false)
                && (contexts.Read(first, firstProfile) |> wait |> result) = saved
            )

            File.Move(exe, exe + ".moved")
            let failed = contexts.Refresh(first, firstProfile, saved.Revision) |> wait |> result

            writer.WriteBoolean(
                "failedRefreshRetainsEvidence",
                failed.Binding.Value.NeedsCheck
                && failed.Binding.Value.Failure.IsSome
                && failed.Binding.Value.Evidence = saved.Binding.Value.Evidence
                && failed.Binding.Value.Path = game
            )

            File.Move(exe + ".moved", exe)

            let refreshed =
                contexts.Refresh(first, firstProfile, failed.Revision) |> wait |> result

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
            let reopened = contexts.Read(first, firstProfile) |> wait |> result

            writer.WriteBoolean(
                "restartRequiresRecheck",
                reopened.Binding.Value.NeedsCheck
                && reopened.Binding.Value.Evidence = prior.Binding.Value.Evidence
                && reopened.Binding.Value.Id = prior.Binding.Value.Id
            )

            create game 105

            let refreshed =
                contexts.Refresh(first, firstProfile, reopened.Revision) |> wait |> result

            writer.WriteBoolean(
                "changedExecutableGetsNewEvidence",
                refreshed.Binding.Value.Evidence.Executable.Value.FileVersion = "1.7.105.0"
                && refreshed.Binding.Value.Evidence.Fingerprint
                   <> prior.Binding.Value.Evidence.Fingerprint
            )

            let missingData = Path.Combine(game, "Data-away")
            Directory.Move(Path.Combine(game, "Data"), missingData)
            let invalid = InstallationValidation.inspect Skyrim.definition game

            writer.WriteBoolean(
                "missingDataNotValid",
                not invalid.Valid && invalid.Executable.IsSome
            )

            Directory.Move(missingData, Path.Combine(game, "Data"))

        do
            use database = new StateDatabase(statePath)
            let roots = OwnedWorkspaceRootStore(database)
            let contextStore = GameContextStore(database, roots)
            let contexts = contextStore :> IGameContexts
            use queued = new ManualResetEventSlim(false)
            use release = new ManualResetEventSlim(false)

            let blocker =
                database.Enqueue(fun () ->
                    queued.Set()
                    release.Wait())

            try
                if not (queued.Wait 5000) then
                    failwith "The context read fixture did not block the database queue."

                let reads = Array.init 3 (fun _ -> contexts.Read(first, firstProfile))
                let pending = reads |> Array.forall (fun read -> not read.IsCompleted)
                release.Set()
                blocker |> wait
                let results = reads |> Array.map wait

                writer.WriteBoolean(
                    "concurrentSnapshotsWaitForAdmission",
                    pending
                    && (results
                        |> Array.forall (function
                            | Ok context -> context.Binding.IsSome
                            | Error _ -> false))
                )
            finally
                release.Set()

            if not (contextStore.TryClose() && roots.TryClose()) then
                failwith "The context read fixture still owns an operation."

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
