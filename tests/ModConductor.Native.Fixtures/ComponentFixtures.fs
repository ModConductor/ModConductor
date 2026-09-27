namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.Cryptography
open System.Text.Json
open System.Threading
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Workspaces
open ModConductor.GameContexts
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.Deployment
open ModConductor.Persistence

module internal ComponentFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private path = DeploymentFixtureData.path

    let private recovery =
        function
        | Ok value -> value
        | Error RecoveryError.NotFound -> invalidOp "Component recovery: not found."
        | Error RecoveryError.Busy -> invalidOp "Component recovery: busy."
        | Error RecoveryError.Stale -> invalidOp "Component recovery: stale."
        | Error RecoveryError.Cancelled -> invalidOp "Component recovery: cancelled."
        | Error RecoveryError.InvalidPlan -> invalidOp "Component recovery: invalid plan."
        | Error RecoveryError.Limit -> invalidOp "Component recovery: limit."
        | Error(RecoveryError.Mismatch text) -> invalidOp ("Component recovery: " + text)
        | Error(RecoveryError.Unavailable text) -> invalidOp ("Component recovery: " + text)
        | Error(RecoveryError.Corrupt text) -> invalidOp ("Component recovery: " + text)

    let private digest file =
        use stream = File.OpenRead file
        SHA256.HashData stream |> Convert.ToHexStringLower

    let private destination source root target useAs =
        { Source = path source
          Root = root
          Destination = path target
          Use = useAs }

    let private review workspace gameRoot (version: ModVersion) =
        ComponentManifests.review
            workspace
            gameRoot
            Skyrim.definition.TargetPolicy
            { ModId = version.ModId
              Version = version
              Priority = 0
              Files =
                [ destination
                      "Root/loader.dll"
                      ComponentRoot.GameRoot
                      "skse_loader.dll"
                      ComponentFileUse.Immutable
                  destination
                      "Root/blocked.dll"
                      ComponentRoot.GameRoot
                      "blocked.dll"
                      ComponentFileUse.Immutable
                  destination
                      "Data/Scripts/component.pex"
                      ComponentRoot.Data
                      "Scripts/component.pex"
                      ComponentFileUse.Immutable
                  destination
                      "Config/enblocal.ini"
                      ComponentRoot.GameRoot
                      "enblocal.ini"
                      ComponentFileUse.WritableConfiguration ] }
        |> Result.defaultWith (fun _ -> invalidOp "The component manifest was not accepted.")

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "components")).FullName

        let workspacePath =
            Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))

        let originalStore (profile: Guid) =
            Path.Combine(workspacePath, ".mc-game-views", profile.ToString("N"), "originals")

        let originalsClean profile =
            let path = originalStore profile

            not (Directory.Exists path)
            || (Directory.EnumerateFileSystemEntries path |> Seq.isEmpty)

        let source =
            Directory.CreateDirectory(Path.Combine(workspacePath, "Component")).FullName

        let write (relative: string) (contents: string) =
            let file = Path.Combine(source, relative)
            Directory.CreateDirectory(Path.GetDirectoryName file) |> ignore
            File.WriteAllText(file, contents)

        write "Root/loader.dll" "loader-v1"
        write "Root/blocked.dll" "blocked"
        write "Data/Scripts/component.pex" "script"
        write "Config/enblocal.ini" "config-v1"

        let foreignLoader = Path.Combine(game, "skse_loader.dll")
        File.WriteAllText(foreignLoader, "foreign-loader")
        let executable = Path.Combine(game, "SkyrimSE.exe")
        let executableHash = digest executable

        let workspace, profileOne, profileTwo, modId, versionOne, versionTwo =
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid()

        use store = new OperationStore(Path.Combine(area, "state"))
        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "Components", StorageWorker.select workspacePath)
            |> wait
            |> result

        let withOne =
            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profileOne; Name = "One" }
            )
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            withOne.Workspace.Revision,
            ProfileEdit.Create { Id = profileTwo; Name = "Two" }
        )
        |> wait
        |> result
        |> ignore

        let library = store.ModLibrary :> IModLibrary

        let registered =
            library.Register(
                workspace,
                modId,
                { Name = "Component"
                  Version = "1"
                  Notes = ""
                  Comment = ""
                  Source = "fixture"
                  Categories = [] },
                Registration.Directory(ModKind.Regular, path "Component")
            )
            |> wait
            |> result

        library.Publish(modId, registered.Revision, versionOne)
        |> wait
        |> result
        |> ignore

        let firstVersion = library.Version(versionOne, 0) |> wait |> result

        let firstPayload =
            library.ReadPayload(versionOne, firstVersion.Entries.Head.Payload.Id, 0L, 64)
            |> wait
            |> result

        write "Root/loader.dll" "loader-v2"

        let revision =
            InventoryObservations.read store profileOne
            |> _.Entries
            |> List.find (fun row -> row.Entry.Mod.Id = modId)
            |> _.Entry.Mod.Revision

        library.Publish(modId, revision, versionTwo) |> wait |> result |> ignore
        let secondVersion = library.Version(versionTwo, 0) |> wait |> result

        let sharedPayloads =
            firstVersion.Entries
            |> List.filter (fun first ->
                secondVersion.Entries
                |> List.exists (fun second ->
                    second.Path = first.Path && second.Payload.Id = first.Payload.Id))

        let selection = store.ModSelection :> IModSelection

        let enable profile =
            let current = InventoryObservations.read store profile

            selection.Change(
                profile,
                current.SelectionRevision,
                [ modId ],
                SelectionEdit.Enable true
            )
            |> wait
            |> result
            |> ignore

        enable profileOne
        enable profileTwo

        for profile in [ profileOne; profileTwo ] do
            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    profile,
                    0L,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Proton = if OperatingSystem.IsLinux() then Some proton else None }
                )
            |> wait
            |> result
            |> ignore

        let context =
            (store.GameContexts :> IGameContexts).Read(workspace, profileOne)
            |> wait
            |> result

        let gameRoot =
            ComponentRoots.gameRootId workspace context.Binding.Value.Evidence
            |> Result.defaultWith invalidOp

        let targetGame (prepared: PreparedState) =
            prepared.Switch.Roots
            |> List.find (fun root -> root.Root.Id = gameRoot)
            |> fun root -> HostPath.value root.Directory.Path

        let first = review workspace gameRoot firstVersion
        let second = review workspace gameRoot secondVersion

        let prepare profile reviewed =
            let state = store.Deployments.Read profile |> wait |> result

            store.PrepareComponents(
                Guid.NewGuid(),
                state.Sources,
                [ reviewed ],
                ignore,
                CancellationToken.None
            )
            |> wait
            |> recovery

        let abandonedPreparation = prepare profileOne first
        PreparedState.abandon abandonedPreparation
        let abandonedPreparationClean = originalsClean profileOne

        let cancelledPreparation = prepare profileOne first
        use cancelled = new CancellationTokenSource()
        cancelled.Cancel()

        let cancelledStart =
            store.Generations.Start(cancelledPreparation, [], cancellation = cancelled.Token)
            |> wait

        let cancelledStartClean = Result.isError cancelledStart && originalsClean profileOne

        let blockedPreparation = prepare profileOne first

        let blocked = Path.Combine(targetGame blockedPreparation, "blocked.dll")

        File.CreateSymbolicLink(blocked, executable) |> ignore
        let blockedStart = store.Generations.Start(blockedPreparation, []) |> wait

        let foreignLinkRefused =
            Result.isError blockedStart && File.Exists blocked && originalsClean profileOne

        File.Delete blocked

        let preparedOne = prepare profileOne first
        let receiptOne = store.Generations.Start(preparedOne, []) |> wait |> result

        let interrupted =
            store.Generations.Run(
                receiptOne.Id,
                receiptOne.Revision,
                false,
                CancellationToken.None,
                (fun name index ->
                    if name = "install-intent" && index = 1 then
                        raise (OperationCanceledException())),
                []
            )
            |> wait

        let pending = store.Deployment.Read receiptOne.Id |> wait |> Option.get

        store.Generations.Run(
            pending.Id,
            pending.Revision,
            false,
            CancellationToken.None,
            (fun _ _ -> ()),
            []
        )
        |> wait
        |> recovery
        |> ignore

        File.WriteAllText(Path.Combine(targetGame preparedOne, "enblocal.ini"), "profile-one")
        let firstGeneration = preparedOne.Switch.Generation
        let preparedTwo = prepare profileTwo second
        let receiptTwo = store.Generations.Start(preparedTwo, []) |> wait |> result

        store.Generations.Run(
            receiptTwo.Id,
            receiptTwo.Revision,
            false,
            CancellationToken.None,
            (fun _ _ -> ()),
            []
        )
        |> wait
        |> result
        |> ignore

        let secondSelected =
            File.ReadAllText(Path.Combine(targetGame preparedTwo, "skse_loader.dll")) = "loader-v2"
            && File.ReadAllText(Path.Combine(targetGame preparedTwo, "enblocal.ini")) = "config-v1"

        let preparedBack = prepare profileOne first
        let back = store.Generations.Start(preparedBack, []) |> wait |> result

        store.Generations.Run(
            back.Id,
            back.Revision,
            false,
            CancellationToken.None,
            (fun _ _ -> ()),
            []
        )
        |> wait
        |> result
        |> ignore

        let firstRestored =
            File.ReadAllText(Path.Combine(targetGame preparedBack, "skse_loader.dll")) = "loader-v1"
            && File.ReadAllText(Path.Combine(targetGame preparedBack, "enblocal.ini")) = "profile-one"

        let current = InventoryObservations.read store profileOne

        selection.Change(
            profileOne,
            current.SelectionRevision,
            [ modId ],
            SelectionEdit.Enable false
        )
        |> wait
        |> result
        |> ignore

        let removal = prepare profileOne first
        let removalReceipt = store.Generations.Start(removal, []) |> wait |> result

        store.Generations.Run(
            removalReceipt.Id,
            removalReceipt.Revision,
            false,
            CancellationToken.None,
            (fun _ _ -> ()),
            []
        )
        |> wait
        |> result
        |> ignore

        let immutableAfter =
            library.ReadPayload(versionOne, firstVersion.Entries.Head.Payload.Id, 0L, 64)
            |> wait
            |> result

        let persistedContext =
            store.Deployment.Context(preparedOne.Switch.ContextId) |> wait |> Option.get

        let persistedOriginalStores =
            persistedContext.Roots
            |> List.map (fun root -> HostPath.value root.Originals.Path |> Path.GetFullPath)
            |> Set.ofList

        let finalOriginalStoresOwned =
            persistedOriginalStores = Set.singleton (Path.GetFullPath(originalStore profileOne))
            && originalsClean profileOne

        let invalidRoot =
            let version =
                { firstVersion with
                    Entries = [ firstVersion.Entries.Head ] }

            ComponentManifests.review
                workspace
                gameRoot
                Skyrim.definition.TargetPolicy
                { ModId = modId
                  Version = version
                  Priority = 0
                  Files =
                    [ destination
                          (LogicalPath.display version.Entries.Head.Path)
                          ComponentRoot.GameRoot
                          "Data/escape.dll"
                          ComponentFileUse.Immutable ] }
            |> Result.isError

        let caseCollision =
            ComponentManifests.review
                workspace
                gameRoot
                Skyrim.definition.TargetPolicy
                { ModId = modId
                  Version = firstVersion
                  Priority = 0
                  Files =
                    firstVersion.Entries
                    |> List.mapi (fun index entry ->
                        { Source = entry.Path
                          Root = ComponentRoot.GameRoot
                          Destination =
                            path (
                                if index = 0 then "Same.dll"
                                elif index = 1 then "same.DLL"
                                else "x" + string index
                            )
                          Use = ComponentFileUse.Immutable }) }
            |> Result.isError

        writer.WriteStartObject("components")
        writer.WriteBoolean("stableDistinctRoots", gameRoot <> workspace)
        writer.WriteBoolean("foreignLinkRefused", foreignLinkRefused)
        writer.WriteBoolean("abandonedPreparationClean", abandonedPreparationClean)
        writer.WriteBoolean("cancelledStartClean", cancelledStartClean)
        writer.WriteBoolean("finalOriginalStoresOwned", finalOriginalStoresOwned)
        writer.WriteBoolean("interruptedActivationRecovered", Result.isError interrupted)
        writer.WriteBoolean("profileVersionsIndependent", secondSelected && firstRestored)
        writer.WriteBoolean("sharedPayloadRetained", sharedPayloads.Length = 3)
        writer.WriteBoolean("immutablePayloadUnchanged", (immutableAfter = firstPayload))

        writer.WriteBoolean(
            "rootOriginalRestored",
            (File.ReadAllText(foreignLoader) = "foreign-loader"
             && File.ReadAllText(Path.Combine(targetGame removal, "skse_loader.dll")) = "foreign-loader")
        )

        writer.WriteBoolean(
            "dataLinkRemoved",
            not (File.Exists(Path.Combine(targetGame removal, "Data", "Scripts", "component.pex")))
        )

        writer.WriteBoolean(
            "configurationLinkRemoved",
            not (File.Exists(Path.Combine(targetGame removal, "enblocal.ini")))
        )

        writer.WriteBoolean("gameUpdatePreserved", digest executable = executableHash)

        writer.WriteBoolean(
            "earlierGenerationRetained",
            (store.Deployment.Generation(preparedOne.Switch.ContextId, firstGeneration.Id)
             |> wait)
                .IsSome
        )

        writer.WriteBoolean("wrongRootRefused", invalidRoot)
        writer.WriteBoolean("caseCollisionRefused", caseCollision)

        writer.WriteBoolean(
            "traversalRefused",
            LogicalPath.create [ ".."; "escape.dll" ] |> Result.isError
        )

        writer.WriteEndObject()
        GenerationCleanup.normalize area
