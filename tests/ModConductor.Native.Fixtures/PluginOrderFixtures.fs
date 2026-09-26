namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.Bethesda
open ModConductor.Workspaces
open ModConductor.GameContexts
open ModConductor.ProfileGameData
open ModConductor.Persistence

module PluginOrderFixtures =
    let private wait = StorageWorker.wait
    let private result value =
        value
        |> Result.defaultWith (fun error ->
            let detail =
                match box error with
                | :? ModConductor.FilePlanning.FilePlanError as value ->
                    match value with
                    | ModConductor.FilePlanning.FilePlanError.ContextUnavailable text -> text
                    | _ -> string value
                | _ -> string error

            invalidOp ("Plugin order fixture request: " + detail))
    let private token = CancellationToken.None

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject "pluginOrder"

        let check (name: string) value =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                invalidOp ("Plugin order fixture failed: " + name)

        let area = Directory.CreateDirectory(Path.Combine(primary, "plugin-order")).FullName
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
        let data = Path.Combine(game, "Data")

        for name in OrderRules.baseFiles do
            File.WriteAllBytes(Path.Combine(data, name), BethesdaSamples.header 1u 1.7f [] false)

        for name, flags, masters in
            [ "A.esp", 0u, [ "Skyrim.esm" ]
              "B.esp", 0u, [ "A.esp" ]
              "Off.esp", 0u, []
              "Light.esp", 0x200u, []
              "Bad.esp", 0u, [ "Absent.esm" ] ] do
            File.WriteAllBytes(
                Path.Combine(data, name),
                BethesdaSamples.header flags 1.7f masters false
            )

        let workspace, first, second = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        let mutable store = new OperationStore(Path.Combine(area, "state"))

        use lifetime =
            { new IDisposable with
                member _.Dispose() = (store :> IDisposable).Dispose() }

        let created =
            (store.Workspaces :> IWorkspaceState)
                .Create(workspace, "Plugin order", StorageWorker.select root)
            |> wait
            |> result

        let created =
            (store.Workspaces :> IWorkspaceState)
                .Edit(
                    workspace,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = first; Name = "First" }
                )
            |> wait
            |> result

        (store.Workspaces :> IWorkspaceState)
            .Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = second; Name = "Second" }
            )
        |> wait
        |> result
        |> ignore

        let context =
            [ first; second ]
            |> List.map (fun profile ->
                (store.GameContexts :> IGameContexts)
                    .Save(workspace, profile, 0L, { GameId = GameId.SkyrimSpecialEditionSteam
                                                    Path = game; Proton = Some proton })
                |> wait
                |> result)
            |> List.head

        let uncheckedScope =
            { WorkspaceId = workspace
              ProfileId = first
              Workspace = DataLocations.root root
              Game = { context with Binding = None }
              Availability = None
              Context = None
              Profile = None }
            : ProfileDataScope

        check
            "uncheckedGameRefusesPluginInputs"
            (match PluginInputs.read uncheckedScope [] token with
             | Error(ProfileDataError.Unavailable detail) ->
                 detail = "Select and refresh the game installation first."
             | _ -> false)

        let local =
            match context.Binding.Value.Evidence.Locations.LocalAppData with
            | Location.Located(path, _) -> path
            | Location.Unavailable error -> invalidOp error

        Directory.CreateDirectory local |> ignore
        let file = Path.Combine(local, "plugins.txt")

        let original =
            Encoding.Latin1.GetBytes("# external caf\u00e9\n*B.esp\r\nA.esp\n*Old.esp\nOff.esp\n")

        File.WriteAllBytes(file, original)

        let scan profile =
            store.Plugins.Scan(profile, token) |> wait |> result

        let read profile (headers: PluginSnapshot) =
            store.PluginOrders.Read(workspace, profile, headers.Id) |> wait |> result

        let change (value: ProfilePluginOrder) edit =
            store.PluginOrders.Change(value.Reference, value.Headers.Id, edit)
            |> wait
            |> result

        let mutable headers = scan first
        let mutable view = read first headers

        check
            "initialInvalidGameOrderReadableWithoutWrites"
            (not view.View.Issues.IsEmpty
             && not view.Saved
             && File.ReadAllBytes(file) = original)

        let rejected =
            store.ApplyProfileDataAtCheckpoint(
                Guid.NewGuid(),
                workspace,
                first,
                view.Reference.Revision,
                token,
                ignore
            )
            |> wait

        check
            "invalidActiveSetRefusedBeforeReceipt"
            (Result.isError rejected
             && (store.ProfileGameData.Read(workspace, first) |> wait |> result).Pending.IsNone
             && File.ReadAllBytes(file) = original)

        headers <- scan first
        view <- read first headers
        let previous = view.Reference
        view <- change view (PluginOrderChange.Enable([ "A.esp" ], true))

        check
            "dependencyIsExplicitAndSavedDraftRemainsCorrectable"
            (not view.View.Issues.IsEmpty && view.Saved && File.ReadAllBytes(file) = original)

        let stale =
            store.PluginOrders.Change(
                previous,
                headers.Id,
                PluginOrderChange.Enable([ "Off.esp" ], true)
            )
            |> wait

        check "staleEditDoesNotOverwriteNewOrder" (stale = Error ProfileDataError.Stale)
        view <- change view (PluginOrderChange.Move([ "A.esp" ], true))
        check "correctedActiveDependencyOrder" view.View.Issues.IsEmpty
        view <- change view (PluginOrderChange.Lock([ "B.esp" ], true))

        let locked =
            view.View.Order.Entries
            |> List.find (fun r -> r.Name = "B.esp")
            |> _.LockedIndex

        view <- change view (PluginOrderChange.Enable([ "Off.esp" ], true))
        view <- change view (PluginOrderChange.Move([ "Off.esp" ], true))
        let active = view.View.Order.Entries |> List.filter (fun r -> r.Enabled = Some true)
        check "locksReapplyActiveIndexNotDisabledPosition" (active[locked.Value].Name = "B.esp")
        view <- change view (PluginOrderChange.Enable([ "Light.esp" ], true))

        check
            "lightSlotsReserveFeAndCountForcedBase"
            (view.View.FullLimit = 254 && view.View.Light = 1 && view.View.Full = 8)

        let apply (view: ProfilePluginOrder) checkpoint =
            match
                store.ApplyProfileDataAtCheckpoint(
                    Guid.NewGuid(),
                    workspace,
                    view.Reference.ProfileId,
                    view.Reference.Revision,
                    token,
                    checkpoint
                )
                |> wait
            with
            | Ok(Some value) -> value
            | Ok None -> invalidOp "No plugin application was needed."
            | Error error -> raise (IOException(DataErrors.message (ProfileDataException error)))

        File.AppendAllText(file, "# changed before first application\n")
        let retainedOriginal = File.ReadAllBytes file
        view <- read first view.Headers

        let appliedFirst =
            store.ApplyProfileDataAtCheckpoint(
                Guid.NewGuid(),
                workspace,
                first,
                view.Reference.Revision,
                token,
                ignore
            )
            |> wait

        check
            "gameListRewriteDoesNotDiscardSavedSelection"
            (view.ExternalChanged
             && Result.isOk appliedFirst
             && (store.ProfileGameData.Read(workspace, first) |> wait |> result).Pending.IsNone
             && File.ReadAllBytes(file) <> retainedOriginal)

        view <- read first view.Headers
        view <-
            store.PluginOrders.UseGameOrder(view.Reference, view.Headers.Id)
            |> wait
            |> result

        view <- change view (PluginOrderChange.Enable([ "A.esp"; "Off.esp"; "Light.esp" ], true))
        let applied = apply view ignore
        let savedBytes = File.ReadAllBytes file

        check
            "applicationUsesSelectedLocalListAndPreservesOpaqueLines"
            (applied.Complete
             && Encoding.Latin1.GetString(savedBytes).Contains("# external caf\u00e9\n")
             && Encoding.Latin1.GetString(savedBytes).Contains("*Old.esp\n")
             && not (File.Exists(Path.Combine(local, "loadorder.txt"))))

        headers <- scan first
        view <- read first headers
        let repeated = apply view ignore

        check
            "unchangedApplyHasNoFileEffects"
            (repeated.Complete
             && repeated.CompletedFiles = 0
             && File.ReadAllBytes(file) = savedBytes)

        File.AppendAllText(file, "# external addition\n")
        headers <- scan first
        view <- read first headers
        check "externalChangeIsVisible" view.ExternalChanged

        let adopted =
            store.PluginOrders.UseGameOrder(view.Reference, headers.Id) |> wait |> result

        check
            "explicitAdoptionSavesWithoutWritingGameFile"
            (not adopted.ExternalChanged
             && Encoding.Latin1.GetString(File.ReadAllBytes file).EndsWith("# external addition\n"))

        view <- change adopted (PluginOrderChange.Enable([ "Off.esp" ], false))

        let interrupted =
            apply view (fun phase ->
                if phase = "preserved" then
                    raise (IOException "Fixture stopped after preserving plugins.txt."))

        check
            "interruptionRetainsReceiptAndOriginal"
            (not interrupted.Complete && not (File.Exists file))

        (store :> IDisposable).Dispose()
        store <- new OperationStore(Path.Combine(area, "state"))
        let contexts = store.GameContexts :> IGameContexts
        let reloaded = contexts.Read(workspace, first) |> wait |> result

        contexts.Refresh(workspace, first, reloaded.Revision) |> wait |> result |> ignore
        let reloadedOther = contexts.Read(workspace, second) |> wait |> result
        contexts.Refresh(workspace, second, reloadedOther.Revision) |> wait |> result |> ignore
        let pending = store.ProfileGameData.Read(workspace, first) |> wait |> result

        let resumed =
            store.ProfileGameData.Resume(workspace, pending.Pending.Value, token)
            |> wait
            |> result

        resumed.Problem
        |> Option.iter (fun detail -> writer.WriteString("resumeProblem", detail))

        check "restartResumeCompletesRecordedEffect" (resumed.Complete && File.Exists file)
        headers <- scan second
        let other = read second headers
        let other = change other (PluginOrderChange.Enable([ "Off.esp" ], true))
        let switched = apply other ignore

        check
            "profileSwitchAppliesIndependentOrder"
            (switched.Complete
             && Encoding.Latin1.GetString(File.ReadAllBytes file).Contains("*Off.esp"))

        let state = store.ProfileGameData.Read(workspace, second) |> wait |> result

        let restored =
            store.ProfileGameData.Restore(Guid.NewGuid(), state.Reference, token)
            |> wait
            |> result

        check
            "completedRestoreReturnsExactOriginal"
            (restored.Complete && File.ReadAllBytes(file) = retainedOriginal)

        headers <- scan first
        view <- read first headers
        check "ownRestoreIsNotAnExternalEdit" (not view.ExternalChanged)
        let archive = Path.Combine(area, "plugin-facts.zip")

        FomodSamples.create
            archive
            """<config><moduleName>Plugin facts</moduleName><moduleDependencies><fileDependency file="B.esp" state="Active"/></moduleDependencies><installSteps><installStep name="Choice"><optionalFileGroups><group name="Files" type="SelectAny"><plugins><plugin name="Water"><description>Fixture</description><files><file source="Core/textures/water.dds" destination="textures/water.dds"/></files><typeDescriptor><type name="Optional"/></typeDescriptor></plugin></plugins></group></optionalFileGroups></installStep></installSteps></config>"""

        let artifact =
            store.Artifacts.Add(
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  Path = archive
                  Storage = ModConductor.ArtifactLibrary.ArtifactStorage.Copy },
                token
            )
            |> wait
            |> result

        let draft =
            store.Installations.Prepare(
                { WorkspaceId = workspace
                  Id = artifact.Id
                  Revision = artifact.Revision },
                token
            )
            |> wait

        let installer =
            store.Installations.Fomod.Open(workspace, draft.Id, draft.Revision, first)
            |> wait

        check "fomodUsesSavedPluginActivation" (installer.Problem.IsNone && installer.Wizard.IsSome)
        headers <- scan first
        view <- read first headers
        change view (PluginOrderChange.Enable([ "B.esp" ], false)) |> ignore
        let mutable staleFacts = false

        try
            store.Installations.Fomod.Next(workspace, installer.Draft.Id, installer.Draft.Revision)
            |> ignore
        with :? ModConductor.Fomod.FomodException ->
            staleFacts <- true

        check "fomodChoicesRefuseChangedPluginRevision" staleFacts

        File.Delete file
        headers <- scan first
        view <- read first headers
        view <- store.PluginOrders.UseGameOrder(view.Reference, headers.Id) |> wait |> result
        view <- change view (PluginOrderChange.Enable([ "A.esp" ], true))
        let createdList = apply view ignore
        let gameList = Path.Combine(local, "Plugins.txt")
        let beforeGame = File.ReadAllBytes gameList
        let gameText = Encoding.Latin1.GetString(beforeGame).Replace("\r\n", "\n")
        File.WriteAllText(gameList, gameText, Encoding.Latin1)
        headers <- scan first
        view <- read first headers
        let afterGame = apply view ignore

        check
            "gameLineEndingsDoNotRequireAdoptionBeforeNextApplication"
            (createdList.Complete
             && not view.ExternalChanged
             && afterGame.Complete
             && afterGame.CompletedFiles = 0
             && File.ReadAllBytes(gameList) = beforeGame)

        writer.WriteEndObject()
