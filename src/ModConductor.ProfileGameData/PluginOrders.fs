namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Bethesda
open ModConductor.FilePlanning

module internal PluginOrders =
    let private titleOrder (scope: ProfileDataScope) order =
        if
            (ModConductor.GameContexts.GameCatalog.rules scope.Game.Binding.Value.GameId)
                .SupportsBlueprint
        then
            BlueprintPlugins.synchronize order
        else
            order

    let private resultTask = ProfileDataResultTask.resultTask

    let headers (plugins: PluginSession) workspace profile id =
        task {
            let! result = plugins.Read id

            match result with
            | Ok value when
                value.Stamp.WorkspaceId = workspace
                && value.Stamp.ProfileId = profile
                && not value.Stale
                ->
                return Ok value
            | _ -> return Error ProfileDataError.Stale
        }

    let view (scope: ProfileDataScope) (headers: PluginSnapshot) (input: PluginInputs) =
        let saved =
            if input.TestOverride then
                None
            else
                scope.Profile |> Option.bind _.PluginOrder

        let order =
            PluginLists.reconcile
                input.Ordering
                input.Activation
                input.Facts
                headers.Entries
                input.Bytes
                input.LoadOrder
                saved
            |> titleOrder scope

        let changed =
            if input.Activation = ModConductor.GameContexts.PluginActivation.MorrowindIni then
                let expected =
                    match scope.Profile |> Option.bind _.PluginOrder with
                    | Some order when
                        scope.Context
                        |> Option.bind _.Applied
                        |> Option.exists (fun active -> active.Plugins.IsSome)
                        ->
                        order.Entries
                        |> List.filter (fun row -> row.Enabled = Some true)
                        |> List.map _.Name
                    | Some order -> MorrowindActivation.names order.Document
                    | None -> MorrowindActivation.names input.Bytes

                expected <> MorrowindActivation.names input.Bytes
            else
                scope.Context
                |> Option.bind _.PluginObserved
                |> Option.exists (fun observed -> observed <> input.File)

        let applied =
            scope.Context
            |> Option.bind _.Applied
            |> Option.exists (fun active ->
                active.ProfileId = scope.ProfileId
                && not changed
                && (active.Plugins
                    |> Option.exists (fun value ->
                        scope.Profile
                        |> Option.exists (fun profile -> profile.Revision = value.ProfileRevision))))

        let contextId =
            match scope.Context with
            | Some context -> Ok context.Id
            | None ->
                DataLocations.documents scope.Game
                |> Result.map (DataLocations.id scope.WorkspaceId)

        contextId
        |> Result.map (fun selected ->
            { Reference =
                { WorkspaceId = scope.WorkspaceId
                  ProfileId = scope.ProfileId
                  ContextId = selected
                  Revision = scope.Context |> Option.map _.Revision |> Option.defaultValue 0L }
              Headers = headers
              Facts = input.Facts
              View =
                OrderRules.inspectFor
                    (ModConductor.GameContexts.GameCatalog.rules scope.Game.Binding.Value.GameId)
                    input.Facts
                    headers.Entries
                    order
              Saved = saved.IsSome
              Applied = applied
              ExternalChanged = changed
              Pending = scope.Context |> Option.bind _.Pending |> Option.isSome
              Problem =
                if input.TestOverride then
                    Some
                        "The game uses sTestFile settings instead of plugins.txt. Remove those settings to use plugin order."
                else
                    None })

    let read (repository: IProfileDataRepository) plugins workspace profile id =
        resultTask {
            let! headerResult = headers plugins workspace profile id
            let! header = headerResult
            let! scopeResult = repository.Read(workspace, profile)
            let! scope = scopeResult
            let! input = PluginInputs.read scope header.Entries CancellationToken.None
            let! value = view scope header input

            match scope.Context |> Option.bind _.Pending with
            | None -> return value
            | Some id ->
                let! actionResult = repository.Action(workspace, id)
                let! action = actionResult

                return
                    { value with
                        Problem = action |> Option.bind _.Problem }
        }

    let save (repository: IProfileDataRepository) plugins (expected: ProfileDataRef) id change =
        resultTask {
            let! headerResult = headers plugins expected.WorkspaceId expected.ProfileId id
            let! header = headerResult
            let! scopeResult = repository.Read(expected.WorkspaceId, expected.ProfileId)
            let! scope = scopeResult
            let! input = PluginInputs.read scope header.Entries CancellationToken.None
            let! current = view scope header input

            if current.Reference <> expected then
                return! Error ProfileDataError.Stale

            if current.Pending then
                return! Error ProfileDataError.Busy

            if input.TestOverride then
                return!
                    Error(
                        ProfileDataError.Unavailable
                            "Remove sTestFile entries from the game's Custom.ini before changing plugin order."
                    )

            let rules =
                ModConductor.GameContexts.GameCatalog.rules scope.Game.Binding.Value.GameId

            match change with
            | Some(PluginOrderChange.Enable(names, _)) when
                rules.SupportsBlueprint && names |> List.exists BlueprintPlugins.isNamed
                ->
                return!
                    Error(
                        ProfileDataError.Invalid
                            "Change the matching main plugin to enable or disable its blueprint plugin."
                    )
            | _ -> ()

            let! changedOrder =
                match change with
                | Some change ->
                    OrderRules.change input.Facts header.Entries current.View.Order change
                    |> Result.mapError ProfileDataError.Invalid
                | None ->
                    let imported =
                        PluginLists.reconcile
                            input.Ordering
                            input.Activation
                            input.Facts
                            header.Entries
                            input.Bytes
                            input.LoadOrder
                            None

                    let keepLock (entry: PluginSetting) =
                        let locked =
                            current.View.Order.Entries
                            |> List.tryFind (fun previous ->
                                previous.Name.Equals(
                                    entry.Name,
                                    StringComparison.OrdinalIgnoreCase
                                ))
                            |> Option.bind _.LockedIndex

                        { entry with LockedIndex = locked }

                    Ok
                        { imported with
                            Entries = imported.Entries |> List.map keepLock }

            let order = titleOrder scope changedOrder

            match change with
            | Some(PluginOrderChange.Move _)
            | Some(PluginOrderChange.Replace _) ->
                let next =
                    OrderRules.inspectFor
                        (ModConductor.GameContexts.GameCatalog.rules scope.Game.Binding.Value.GameId)
                        input.Facts
                        header.Entries
                        order

                match
                    next.Issues
                    |> List.tryFind (fun issue -> not (List.contains issue current.View.Issues))
                with
                | Some issue -> return! Error(ProfileDataError.Invalid issue.Detail)
                | None -> ()
            | _ -> ()

            let! contextResult = DataInitialization.context repository scope
            let! context = contextResult
            let! root = PluginInputs.ensureRoot input

            let profile =
                scope.Profile
                |> Option.defaultValue
                    { ProfileId = scope.ProfileId
                      Revision = 0L
                      Options = { Settings = false; Saves = false }
                      Root = None
                      Settings = None
                      Saves = None
                      SettingsInitialized = false
                      SavesInitialized = false
                      PluginOrder = None
                      ArchiveList = None }

            let adopt (active: AppliedProfileData) =
                if change.IsSome then
                    active
                else
                    let update (previous: AppliedPluginOrder) =
                        { previous with ProfileRevision = -1L }

                    { active with
                        Plugins = active.Plugins |> Option.map update }

            let context =
                { context with
                    PluginRoot = Some root
                    PluginObserved =
                        if
                            input.Activation = ModConductor.GameContexts.PluginActivation.MorrowindIni
                        then
                            None
                        elif change.IsNone || context.PluginObserved.IsNone then
                            Some input.File
                        else
                            context.PluginObserved
                    Applied = context.Applied |> Option.map adopt }

            let! saved =
                repository.SaveOrder(
                    context,
                    { profile with
                        Revision = profile.Revision + 1L
                        PluginOrder = Some order },
                    header.Stamp
                )

            do! saved

            return! read repository plugins expected.WorkspaceId expected.ProfileId id
        }

    let forLaunch (plugins: PluginSession) (scope: ProfileDataScope) token =
        resultTask {
            let saved = scope.Profile |> Option.bind _.PluginOrder
            let! result = plugins.Observe(scope.ProfileId, token)

            let! header =
                match result with
                | Ok value when not value.Stale -> Ok value
                | Error FilePlanError.Busy -> Error ProfileDataError.Busy
                | _ -> Error(ProfileDataError.Unavailable "Refresh the plugins before playing.")

            let! input = PluginInputs.read scope header.Entries token

            if
                saved.IsNone
                && (scope.Context
                    |> Option.bind _.PluginObserved
                    |> Option.exists (fun observed -> observed <> input.File))
            then
                return!
                    Error(
                        ProfileDataError.Conflict
                            "The game plugin list changed. Use game order before playing."
                    )

            let order =
                PluginLists.reconcile
                    input.Ordering
                    input.Activation
                    input.Facts
                    header.Entries
                    input.Bytes
                    input.LoadOrder
                    (if input.TestOverride then None else saved)
                |> titleOrder scope

            let view =
                OrderRules.inspectFor
                    (ModConductor.GameContexts.GameCatalog.rules scope.Game.Binding.Value.GameId)
                    input.Facts
                    header.Entries
                    order

            match view.Issues with
            | issue :: _ -> return! Error(ProfileDataError.Invalid issue.Detail)
            | [] -> ()

            if not header.Problems.IsEmpty then
                return! Error(ProfileDataError.Invalid header.Problems.Head)

            let implicit =
                input.Facts.Implicit
                @ (if
                       (ModConductor.GameContexts.GameCatalog.rules scope.Game.Binding.Value.GameId)
                           .SupportsBlueprint
                   then
                       header.Entries |> List.filter BlueprintPlugins.isBlueprint |> List.map _.Name
                   else
                       [])

            return
                (if input.TestOverride then None else saved)
                |> Option.map (fun _ -> OrderDocument.writeFor input.Activation implicit order)
        }
