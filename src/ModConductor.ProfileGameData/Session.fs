namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.GameContexts

[<Sealed>]
type ProfileGameDataSession
    internal
    (
        repository: IProfileDataRepository,
        enter: Guid -> IDisposable option,
        stopped: GameContextState -> unit,
        plugins: ModConductor.Bethesda.PluginSession,
        archives: ModConductor.Bethesda.ArchivePolicySession
    ) =

    let gate = obj ()
    let previewGate = obj ()
    let mutable active = 0
    let mutable closed = false

    let savePreviews =
        Collections.Generic.Dictionary<Guid, ProfileSaveActionPreview * SaveActionReceipt>()

    let savePreviewOrder = Collections.Generic.Queue<Guid>()

    let rememberSavePreview (preview: ProfileSaveActionPreview) (receipt: SaveActionReceipt) =
        lock previewGate (fun () ->
            while savePreviews.Count >= 64 do
                savePreviews.Remove(savePreviewOrder.Dequeue()) |> ignore

            savePreviews.Add(preview.Id, (preview, receipt))
            savePreviewOrder.Enqueue preview.Id)

    let findSavePreview id =
        lock previewGate (fun () ->
            match savePreviews.TryGetValue id with
            | true, value -> Some value
            | _ -> None)

    let forgetSavePreview id =
        lock previewGate (fun () -> savePreviews.Remove id |> ignore)

    let mutable drained =
        TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously)

    do drained.SetResult()

    let protect action =
        task {
            let admitted =
                lock gate (fun () ->
                    if closed || active >= 2 then
                        false
                    else
                        if active = 0 then
                            drained <-
                                TaskCompletionSource<unit>(
                                    TaskCreationOptions.RunContinuationsAsynchronously
                                )

                        active <- active + 1
                        true)

            if not admitted then
                return Error ProfileDataError.Busy
            else
                try
                    try
                        return! action ()
                    with
                    | ProfileDataException error -> return Error error
                    | :? OperationCanceledException -> return Error ProfileDataError.Cancelled
                    | :? IOException as error ->
                        return Error(ProfileDataError.Unavailable error.Message)
                    | :? UnauthorizedAccessException ->
                        return
                            Error(
                                ProfileDataError.Unavailable
                                    "The settings or saves cannot be accessed."
                            )
                finally
                    lock gate (fun () ->
                        active <- active - 1

                        if active = 0 then
                            drained.TrySetResult() |> ignore)
        }

    let requireIds ids =
        if ids |> List.contains Guid.Empty then
            raise (
                ProfileDataException(
                    ProfileDataError.Invalid "The request contains an empty identifier."
                )
            )

    let run workspace action =
        protect (fun () ->
            task {
                match enter workspace with
                | None -> return Error ProfileDataError.Busy
                | Some lease ->
                    use lease = lease
                    return! action ()
            })

    let count root =
        match root with
        | None -> 0
        | Some root ->
            let mutable count = 0

            let rec walk (root: DataRoot) depth =
                if depth > 128 || count > 1000000 then
                    raise (
                        ProfileDataException(
                            ProfileDataError.Unavailable
                                "The private folder exceeds the supported limits."
                        )
                    )

                use held = HeldDirectory.Open(root.Path, root.Identity)

                for name in held.Names do
                    match held.InspectEntry name with
                    | Some entry when entry.Kind = EntryKind.RegularFile -> count <- count + 1
                    | Some entry when entry.Kind = EntryKind.Directory ->
                        use child = held.Directory(name, Some entry.Identity)

                        let path =
                            HostPath.create (Path.Combine(HostPath.value root.Path, name))
                            |> Result.defaultWith invalidOp

                        walk
                            { Path = path
                              Identity = child.Identity }
                            (depth + 1)
                    | _ ->
                        raise (
                            ProfileDataException(
                                ProfileDataError.Unavailable
                                    "The private folder contains an unsupported entry."
                            )
                        )

            walk root 0
            count

    let view (scope: ProfileDataScope) =
        let profile = scope.Profile
        let mutable problem = scope.Availability

        let countKnown root =
            try
                count root
            with
            | :? IOException as error ->
                problem <- Some error.Message
                0
            | ProfileDataException(ProfileDataError.Unavailable detail) ->
                problem <- Some detail
                0

        let settingsCount = countKnown (profile |> Option.bind _.Settings)
        let saveCount = countKnown (profile |> Option.bind _.Saves)

        { WorkspaceId = scope.WorkspaceId
          ProfileId = scope.ProfileId
          ContextId =
            scope.Context
            |> Option.map _.Id
            |> Option.defaultWith (fun () ->
                if scope.Availability.IsSome then
                    Guid.Empty
                else
                    DataLocations.id scope.WorkspaceId (DataLocations.documents scope.Game))
          Revision = scope.Context |> Option.map _.Revision |> Option.defaultValue 0L
          Options =
            profile
            |> Option.map _.Options
            |> Option.defaultValue { Settings = false; Saves = false }
          InUse = scope.Context |> Option.bind _.Applied |> Option.map _.ProfileId
          SettingsPath =
            profile
            |> Option.bind _.Settings
            |> Option.map (fun root -> HostPath.value root.Path)
            |> Option.defaultValue ""
          SavesPath =
            profile
            |> Option.bind _.Saves
            |> Option.map (fun root -> HostPath.value root.Path)
            |> Option.defaultValue ""
          SettingsFiles = settingsCount
          SaveFiles = saveCount
          SettingsInitialized = profile |> Option.exists _.SettingsInitialized
          SavesInitialized = profile |> Option.exists _.SavesInitialized
          Pending = scope.Context |> Option.bind _.Pending
          PendingProfileChange = false
          Problem = problem }
        : ProfileDataState

    let read workspace profile =
        task {
            let! scope = repository.Read(workspace, profile)
            let state = view scope

            match state.Pending with
            | None -> return state
            | Some id ->
                let! action = repository.Action(workspace, id)

                let profileChange =
                    action
                    |> Option.exists (fun value ->
                        match value.Kind with
                        | ProfileDataActionKind.Clone _
                        | ProfileDataActionKind.Delete _ -> true
                        | _ -> false)

                let active =
                    match action with
                    | Some value when value.Deletion.IsSome ->
                        value.Proposed |> Option.map _.ProfileId
                    | _ -> state.InUse

                return
                    { state with
                        Problem = action |> Option.bind _.Problem |> Option.orElse state.Problem
                        PendingProfileChange = profileChange
                        InUse = active }
        }

    let check (scope: ProfileDataScope) (expected: ProfileDataRef) =
        scope.Availability
        |> Option.iter (fun detail ->
            raise (ProfileDataException(ProfileDataError.Unavailable detail)))

        let id =
            scope.Context
            |> Option.map _.Id
            |> Option.defaultWith (fun () ->
                DataLocations.id scope.WorkspaceId (DataLocations.documents scope.Game))

        let revision = scope.Context |> Option.map _.Revision |> Option.defaultValue 0L

        if id <> expected.ContextId || revision <> expected.Revision then
            raise (ProfileDataException ProfileDataError.Stale)

    let initial id (context: ProfileDataContext) profile kind =
        { Id = id
          ContextId = context.Id
          ProfileId = profile
          ExpectedRevision = context.Revision
          Kind = kind
          Deletion = None
          CloneTarget = None
          Prepared = false
          WorkspaceStage = None
          DocumentsStage = None
          PluginStage = None
          ChangedProfile = None
          Files = []
          CompletedFiles = 0
          Link = SaveLinkEffect.Unchanged
          LinkRemoved = false
          LinkCreated = None
          Proposed = context.Applied
          Complete = false
          Problem = None }
        : ProfileDataActionRecord

    let execute
        checkpoint
        desiredPlugins
        (scope: ProfileDataScope)
        (context: ProfileDataContext)
        (initial: ProfileDataActionRecord)
        (token: CancellationToken)
        progress
        (report: ProfileDataActionRecord -> Task<unit>)
        =
        task {
            let mutable context =
                { context with
                    Pending = Some initial.Id }

            let mutable action = { initial with Problem = None }
            let mutable changed = initial.ChangedProfile

            try
                let! incoming =
                    task {
                        match action.Kind with
                        | ProfileDataActionKind.Edit(options, saves, _) ->
                            let! privateData =
                                DataInitialization.profile repository context action.ProfileId

                            let! initialized =
                                DataInitialization.seed
                                    repository
                                    context
                                    privateData
                                    options
                                    saves
                                    scope.Game
                                    token
                                    progress

                            changed <-
                                Some
                                    { initialized with
                                        Options = options
                                        Revision = initialized.Revision + 1L }

                            match context.Applied with
                            | Some active when active.ProfileId = action.ProfileId ->
                                return
                                    Some
                                        { initialized with
                                            Options =
                                                { Settings =
                                                    active.Options.Settings && options.Settings
                                                  Saves = active.Options.Saves && options.Saves } }
                            | _ -> return None
                        | ProfileDataActionKind.Apply ->
                            let! privateData =
                                DataInitialization.profile repository context action.ProfileId

                            return Some privateData
                        | ProfileDataActionKind.Restore -> return None
                        | ProfileDataActionKind.ApplyArchives _
                        | ProfileDataActionKind.RestoreArchives ->
                            let! privateData =
                                DataInitialization.profile repository context action.ProfileId

                            return Some privateData
                        | ProfileDataActionKind.SaveFiles _ ->
                            let! privateData =
                                DataInitialization.profile repository context action.ProfileId

                            return Some privateData
                        | ProfileDataActionKind.Clone _
                        | ProfileDataActionKind.Delete _ ->
                            return invalidOp "Use the profile mutation owner."
                    }

                let affectsGame =
                    match action.Kind with
                    | ProfileDataActionKind.Edit(options, _, _) ->
                        context.Applied
                        |> Option.exists (fun active ->
                            active.ProfileId = action.ProfileId
                            && ((active.Options.Settings && not options.Settings)
                                || (active.Options.Saves && not options.Saves)))
                    | _ -> true

                if affectsGame && action.Deletion.IsNone then
                    stopped scope.Game

                    let! updatedContext, prepared =
                        match action.Kind with
                        | ProfileDataActionKind.ApplyArchives _
                        | ProfileDataActionKind.RestoreArchives ->
                            ArchivePreparation.prepare
                                repository
                                archives
                                context
                                action
                                incoming.Value
                                token
                        | ProfileDataActionKind.SaveFiles _ ->
                            SavePreparation.prepare
                                repository
                                scope
                                context
                                action
                                incoming.Value
                                token
                                progress
                        | _ ->
                            DataActionPreparation.prepare
                                repository
                                context
                                action
                                incoming
                                desiredPlugins
                                token

                    context <- updatedContext
                    action <- prepared

                    match action.ChangedProfile with
                    | Some profile -> changed <- Some profile
                    | None -> ()

                    do! report action

                    let save current =
                        task {
                            do! repository.SaveAction current
                            action <- current
                            do! report current
                        }

                    let! applied = DataEffects.run context action save token checkpoint

                    action <-
                        { applied with
                            Proposed =
                                applied.Proposed
                                |> Option.map (fun current ->
                                    { current with
                                        SaveLink = applied.LinkCreated }) }
                else
                    action <- { action with Prepared = true }

                match action.Kind, changed with
                | ProfileDataActionKind.Edit(options, _, DisabledFiles.Delete), Some profile ->
                    if action.Deletion.IsNone then
                        let trees =
                            [ if not options.Settings then
                                  yield SaveTrees.observe profile.Settings.Value token progress
                              if not options.Saves then
                                  yield SaveTrees.observe profile.Saves.Value token progress ]

                        action <-
                            { action with
                                Deletion = Some(ProfileDeletion.prepare trees []) }

                        do! repository.SaveAction action

                    let! deleted = ProfileDeletion.run action repository.SaveAction token progress
                    action <- deleted

                    changed <-
                        Some
                            { profile with
                                SettingsInitialized =
                                    options.Settings && profile.SettingsInitialized
                                SavesInitialized = options.Saves && profile.SavesInitialized
                                ArchiveList =
                                    if options.Settings then profile.ArchiveList else None }
                | ProfileDataActionKind.SaveFiles receipt, Some _ when
                    receipt.Action = ProfileSaveAction.DeleteFromProfile
                    ->
                    let! deleted = ProfileDeletion.run action repository.SaveAction token progress
                    action <- deleted
                | _ -> ()

                do! repository.Complete(context, changed, action)
                action <- { action with Complete = true }
                do! report action
                let! state = read scope.WorkspaceId scope.ProfileId

                return
                    { Id = action.Id
                      State = state
                      Complete = true
                      CompletedFiles =
                        action.CompletedFiles
                        + (action.Deletion |> Option.map _.CompletedFiles |> Option.defaultValue 0)
                      Problem = None }
            with error ->
                let! retained = repository.Action(scope.WorkspaceId, action.Id)
                action <- retained |> Option.defaultValue action

                if action.Complete then
                    raise error

                action <-
                    { action with
                        Problem = Some(DataErrors.message error) }

                do! repository.SaveAction action
                do! report action
                do! repository.Release action.Id
                let! state = read scope.WorkspaceId scope.ProfileId

                return
                    { Id = action.Id
                      State = state
                      Complete = false
                      CompletedFiles =
                        action.CompletedFiles
                        + (action.Deletion |> Option.map _.CompletedFiles |> Option.defaultValue 0)
                      Problem = Some(DataErrors.message error) }
        }

    let completedFiles (action: ProfileDataActionRecord) =
        action.CompletedFiles
        + (action.Deletion |> Option.map _.CompletedFiles |> Option.defaultValue 0)

    let replay workspace profile id kind expected =
        task {
            let! prior = repository.Action(workspace, id)

            match prior with
            | Some value when
                value.ProfileId <> profile
                || value.Kind <> kind
                || value.ExpectedRevision <> expected
                ->
                return raise (ProfileDataException ProfileDataError.Stale)
            | Some value when value.Complete ->
                let! state = read workspace profile

                return
                    Some
                        { Id = id
                          State = state
                          Complete = true
                          CompletedFiles = completedFiles value
                          Problem = value.Problem }
            | _ -> return None
        }

    let restore id (expected: ProfileDataRef) token checkpoint =
        run expected.WorkspaceId (fun () ->
            task {
                requireIds [ id; expected.WorkspaceId; expected.ProfileId; expected.ContextId ]

                let! previous =
                    replay
                        expected.WorkspaceId
                        expected.ProfileId
                        id
                        ProfileDataActionKind.Restore
                        expected.Revision

                match previous with
                | Some result -> return Ok result
                | None ->
                    let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                    check scope expected

                    match
                        scope.Context |> Option.bind _.PluginRoot,
                        scope.Context |> Option.bind _.PluginObserved
                    with
                    | Some root, Some expectedFile ->
                        let _, file, _ = PluginInputs.readFile root PluginInputs.fileName token

                        if file <> expectedFile then
                            raise (
                                ProfileDataException(
                                    ProfileDataError.Conflict
                                        "The game plugin list changed. Use game order before restoring it."
                                )
                            )
                    | _ -> ()

                    let! context = DataInitialization.context repository scope

                    let! action =
                        repository.Claim(
                            context,
                            initial id context scope.ProfileId ProfileDataActionKind.Restore
                        )

                    let! result =
                        execute checkpoint None scope context action token ignore (fun _ ->
                            Task.FromResult())

                    return Ok result
            })

    member internal _.RestoreAtCheckpoint(id, expected, token, checkpoint) =
        restore id expected token checkpoint

    member _.Drain() = lock gate (fun () -> drained.Task)

    member _.TryClose(next: unit -> bool) =
        lock gate (fun () ->
            if active <> 0 || not (next ()) then
                false
            else
                closed <- true
                true)

    member _.Revision(workspace, profile) =
        protect (fun () ->
            task {
                requireIds [ workspace; profile ]
                let! exists = repository.HasData workspace

                if not exists then
                    return Ok 0L
                else
                    let! scope = repository.Read(workspace, profile)
                    return Ok(scope.Context |> Option.map _.Revision |> Option.defaultValue 0L)
            })

    member internal _.ApplyForLaunchAtCheckpoint
        (
            id,
            workspace,
            profile,
            expected,
            token,
            report: ProfileDataApplication -> Task<unit>,
            checkpoint
        ) =
        protect (fun () ->
            task {
                requireIds [ id; workspace; profile ]
                let! scope = repository.Read(workspace, profile)
                let revision = scope.Context |> Option.map _.Revision |> Option.defaultValue 0L

                if revision <> expected then
                    return Error ProfileDataError.Stale
                else
                    let! desiredPlugins = PluginOrders.forLaunch plugins scope token

                    let needed =
                        (scope.Context |> Option.bind _.Applied).IsSome
                        || (scope.Profile
                            |> Option.exists (fun value ->
                                value.Options.Settings
                                || value.Options.Saves
                                || value.PluginOrder.IsSome))

                    if not needed then
                        return Ok None
                    else
                        let! context = DataInitialization.context repository scope

                        let! action =
                            repository.Claim(
                                context,
                                initial id context profile ProfileDataActionKind.Apply
                            )

                        let reportAction (value: ProfileDataActionRecord) =
                            report
                                { ReceiptId = value.Id
                                  Revision = expected
                                  CompletedFiles = value.CompletedFiles
                                  Complete = value.Complete
                                  Problem = value.Problem }

                        let! result =
                            execute
                                checkpoint
                                desiredPlugins
                                scope
                                context
                                action
                                token
                                ignore
                                reportAction

                        return
                            Ok(
                                Some
                                    { ReceiptId = result.Id
                                      Revision = expected
                                      CompletedFiles = result.CompletedFiles
                                      Complete = result.Complete
                                      Problem = result.Problem }
                            )
            })

    member this.ApplyForLaunch(id, workspace, profile, expected, token, report) =
        this.ApplyForLaunchAtCheckpoint(id, workspace, profile, expected, token, report, ignore)

    interface IProfilePluginOrders with
        member _.Read(workspace, profile, headers) =
            protect (fun () ->
                task {
                    let! value = PluginOrders.read repository plugins workspace profile headers
                    return Ok value
                })

        member _.Change(expected, headers, change) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! value =
                        PluginOrders.save repository plugins expected headers (Some change)

                    return Ok value
                })

        member _.UseGameOrder(expected, headers) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! value = PluginOrders.save repository plugins expected headers None
                    return Ok value
                })

        member _.ApplyExactOrder(expected, headers, names) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! value =
                        PluginOrders.save
                            repository
                            plugins
                            expected
                            headers
                            (Some(ModConductor.Bethesda.PluginOrderChange.Replace names))

                    return Ok value
                })

    interface IProfileArchivePolicies with
        member _.Scan(workspace, profile, headers, token) =
            protect (fun () ->
                task {
                    requireIds [ workspace; profile; headers ]

                    let! value =
                        ArchivePolicies.scan
                            repository
                            plugins
                            archives
                            workspace
                            profile
                            headers
                            token

                    return Ok value
                })

        member _.Read(workspace, profile, snapshot, token) =
            protect (fun () ->
                task {
                    requireIds [ workspace; profile; snapshot ]

                    let! value =
                        ArchivePolicies.read repository archives workspace profile snapshot token

                    return Ok value
                })

        member _.Apply(id, expected, snapshot, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    requireIds
                        [ id
                          expected.WorkspaceId
                          expected.ProfileId
                          expected.ContextId
                          snapshot ]

                    let! prior = repository.Action(expected.WorkspaceId, id)

                    let! scope, kind =
                        match prior with
                        | Some previous ->
                            match previous.Kind with
                            | ProfileDataActionKind.ApplyArchives request when
                                previous.ProfileId = expected.ProfileId
                                && previous.ExpectedRevision = expected.Revision
                                && request.SnapshotId = snapshot
                                ->
                                task {
                                    let! scope =
                                        repository.Read(expected.WorkspaceId, expected.ProfileId)

                                    return scope, previous.Kind
                                }
                            | _ ->
                                raise (ProfileDataException ProfileDataError.Stale)
                        | None ->
                            task {
                                let! scope, request =
                                    ArchivePolicies.prepareApply
                                        repository
                                        archives
                                        expected
                                        snapshot
                                        token

                                return scope, ProfileDataActionKind.ApplyArchives request
                            }

                    let! replayed =
                        replay
                            expected.WorkspaceId
                            expected.ProfileId
                            id
                            kind
                            expected.Revision

                    match replayed with
                    | Some result -> return Ok result
                    | None ->
                        check scope expected
                        let! context = DataInitialization.context repository scope

                        let! action = repository.Claim(context, initial id context scope.ProfileId kind)

                        let! result =
                            execute ignore None scope context action token progress (fun _ ->
                                Task.FromResult())

                        return Ok result
                })

        member _.Restore(id, expected, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    requireIds [ id; expected.WorkspaceId; expected.ProfileId; expected.ContextId ]
                    let kind = ProfileDataActionKind.RestoreArchives

                    let! replayed =
                        replay
                            expected.WorkspaceId
                            expected.ProfileId
                            id
                            kind
                            expected.Revision

                    match replayed with
                    | Some result -> return Ok result
                    | None ->
                        let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                        check scope expected

                        if scope.Profile |> Option.bind _.ArchiveList |> Option.isNone then
                            raise (
                                ProfileDataException(
                                    ProfileDataError.Invalid
                                        "There are no archive changes to restore."
                                )
                            )

                        let! context = DataInitialization.context repository scope

                        let! action = repository.Claim(context, initial id context scope.ProfileId kind)

                        let! result =
                            execute ignore None scope context action token progress (fun _ ->
                                Task.FromResult())

                        return Ok result
                })

    interface IProfileGameData with
        member _.SaveFiles(workspace, profile, path, after) =
            protect (fun () ->
                task {
                    requireIds [ workspace; profile ]
                    let! scope = repository.Read(workspace, profile)
                    let root = scope.Profile |> Option.bind _.Saves
                    return Ok(SaveBrowsing.page root path after)
                })

        member _.Read(workspace, profile) =
            protect (fun () ->
                task {
                    requireIds [ workspace; profile ]
                    let! state = read workspace profile
                    return Ok state
                })

        member _.SaveGroups(workspace, profile, source, after) =
            protect (fun () ->
                task {
                    requireIds [ workspace; profile ]
                    let! scope = repository.Read(workspace, profile)
                    return Ok(SaveGroups.page scope source after)
                })

        member _.InspectSave(workspace, profile, source, name, headers, token) =
            protect (fun () ->
                task {
                    requireIds ([ workspace; profile ] @ (headers |> Option.toList))

                    if String.IsNullOrWhiteSpace name then
                        raise (
                            ProfileDataException(
                                ProfileDataError.Invalid "Choose a current save first."
                            )
                        )

                    let! scope = repository.Read(workspace, profile)

                    let! value =
                        SaveGroups.inspect repository plugins scope source name headers token

                    return Ok value
                })

        member _.PreviewSaveAction(expected, action, names, token) =
            protect (fun () ->
                task {
                    requireIds [ expected.WorkspaceId; expected.ProfileId; expected.ContextId ]

                    let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                    check scope expected
                    stopped scope.Game
                    let id = Guid.NewGuid()

                    let receipt, source, destination, files =
                        SaveGroups.prepare id scope action names token

                    let preview =
                        { Id = id
                          Expected = expected
                          Action = action
                          Source = source
                          Destination = destination
                          Files = files
                          Bytes = files |> List.sumBy _.Bytes }

                    rememberSavePreview preview receipt
                    return Ok preview
                })

        member _.ApplySaveAction(id, previewId, expected, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    requireIds
                        [ id
                          previewId
                          expected.WorkspaceId
                          expected.ProfileId
                          expected.ContextId ]

                    let! prior = repository.Action(expected.WorkspaceId, id)

                    let receipt =
                        match prior with
                        | Some previous ->
                            match previous.Kind with
                            | ProfileDataActionKind.SaveFiles receipt when
                                previous.ProfileId = expected.ProfileId
                                && previous.ExpectedRevision = expected.Revision
                                && receipt.PreviewId = previewId
                                ->
                                receipt
                            | _ -> raise (ProfileDataException ProfileDataError.Stale)
                        | None ->
                            match findSavePreview previewId with
                            | Some(preview, receipt) when
                                preview.Id = previewId
                                && preview.Expected = expected
                                && preview.Action = receipt.Action
                                ->
                                receipt
                            | _ -> raise (ProfileDataException ProfileDataError.Stale)

                    let kind = ProfileDataActionKind.SaveFiles receipt

                    let! replayed =
                        replay expected.WorkspaceId expected.ProfileId id kind expected.Revision

                    match replayed with
                    | Some result -> return Ok result
                    | None ->
                        let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                        check scope expected
                        stopped scope.Game
                        SaveGroups.checkReceipt scope receipt token
                        let! context = DataInitialization.context repository scope

                        let! action =
                            repository.Claim(context, initial id context scope.ProfileId kind)

                        let! result =
                            execute ignore None scope context action token progress (fun _ ->
                                Task.FromResult())

                        if result.Complete then
                            forgetSavePreview previewId

                        return Ok result
                })

        member _.Edit(request, progress, token) =
            run request.Expected.WorkspaceId (fun () ->
                task {
                    requireIds
                        [ request.Id
                          request.Expected.WorkspaceId
                          request.Expected.ProfileId
                          request.Expected.ContextId ]

                    let kind =
                        ProfileDataActionKind.Edit(
                            request.Options,
                            request.InitialSaves,
                            request.DisabledFiles
                        )

                    let! previous =
                        replay
                            request.Expected.WorkspaceId
                            request.Expected.ProfileId
                            request.Id
                            kind
                            request.Expected.Revision

                    match previous with
                    | Some result -> return Ok result
                    | None ->
                        let! scope =
                            repository.Read(
                                request.Expected.WorkspaceId,
                                request.Expected.ProfileId
                            )

                        check scope request.Expected
                        let! context = DataInitialization.context repository scope

                        let! action =
                            repository.Claim(
                                context,
                                initial request.Id context scope.ProfileId kind
                            )

                        let! result =
                            execute ignore None scope context action token progress (fun _ ->
                                Task.FromResult())

                        return Ok result
                })

        member _.Restore(id, expected, token) = restore id expected token ignore

        member _.Resume(workspace, id, token) =
            run workspace (fun () ->
                task {
                    requireIds [ workspace; id ]
                    let! previous = repository.Action(workspace, id)

                    let previous =
                        previous
                        |> Option.defaultWith (fun () ->
                            raise (ProfileDataException ProfileDataError.NotFound))

                    match previous.Kind with
                    | ProfileDataActionKind.Clone _
                    | ProfileDataActionKind.Delete _ ->
                        raise (
                            ProfileDataException(
                                ProfileDataError.Invalid
                                    "Continue this action from the profile controls."
                            )
                        )
                    | _ -> ()

                    if previous.Complete then
                        let! state = read workspace previous.ProfileId

                        return
                            Ok
                                { Id = id
                                  State = state
                                  Complete = true
                                  CompletedFiles = completedFiles previous
                                  Problem = previous.Problem }
                    else
                        let! scope = repository.Read(workspace, previous.ProfileId)

                        let context =
                            scope.Context
                            |> Option.defaultWith (fun () ->
                                raise (ProfileDataException ProfileDataError.NotFound))

                        let! desiredPlugins =
                            if
                                previous.Kind = ProfileDataActionKind.Apply
                                && not previous.Prepared
                            then
                                PluginOrders.forLaunch plugins scope token
                            else
                                Task.FromResult None

                        let! action = repository.Claim(context, previous)

                        let! result =
                            execute
                                ignore
                                desiredPlugins
                                scope
                                context
                                action
                                token
                                ignore
                                (fun _ -> Task.FromResult())

                        return Ok result
                })
