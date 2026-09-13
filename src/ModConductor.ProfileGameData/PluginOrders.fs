namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Bethesda
open ModConductor.FilePlanning

module internal PluginOrders =
    let headers (plugins: PluginSession) workspace profile id =
        task {
            let! result = plugins.Read id

            match result with
            | Ok value when
                value.Stamp.WorkspaceId = workspace
                && value.Stamp.ProfileId = profile
                && not value.Stale
                ->
                return value
            | _ -> return raise (ProfileDataException ProfileDataError.Stale)
        }

    let view (scope: ProfileDataScope) (headers: PluginSnapshot) (input: PluginInputs) =
        let saved = scope.Profile |> Option.bind _.PluginOrder
        let order = OrderRules.reconcile input.Facts headers.Entries input.Bytes saved

        let changed =
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

        { Reference =
            { WorkspaceId = scope.WorkspaceId
              ProfileId = scope.ProfileId
              ContextId =
                scope.Context
                |> Option.map _.Id
                |> Option.defaultWith (fun () ->
                    DataLocations.id scope.WorkspaceId (DataLocations.documents scope.Game))
              Revision = scope.Context |> Option.map _.Revision |> Option.defaultValue 0L }
          Headers = headers
          Facts = input.Facts
          View = OrderRules.inspect input.Facts headers.Entries order
          Saved = saved.IsSome
          Applied = applied
          ExternalChanged = changed
          Pending = scope.Context |> Option.bind _.Pending |> Option.isSome
          Problem = None }

    let read (repository: IProfileDataRepository) plugins workspace profile id =
        task {
            let! header = headers plugins workspace profile id
            let! scope = repository.Read(workspace, profile)
            let input = PluginInputs.read scope header.Entries CancellationToken.None
            let value = view scope header input

            match scope.Context |> Option.bind _.Pending with
            | None -> return value
            | Some id ->
                let! action = repository.Action(workspace, id)

                return
                    { value with
                        Problem = action |> Option.bind _.Problem }
        }

    let save (repository: IProfileDataRepository) plugins (expected: ProfileDataRef) id change =
        task {
            let! header = headers plugins expected.WorkspaceId expected.ProfileId id
            let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
            let input = PluginInputs.read scope header.Entries CancellationToken.None
            let current = view scope header input

            if current.Reference <> expected then
                raise (ProfileDataException ProfileDataError.Stale)

            if current.Pending then
                raise (ProfileDataException ProfileDataError.Busy)

            let order =
                match change with
                | Some change ->
                    OrderRules.change input.Facts current.View.Order change
                    |> Result.defaultWith (fun detail ->
                        raise (ProfileDataException(ProfileDataError.Invalid detail)))
                | None ->
                    let imported = OrderRules.reconcile input.Facts header.Entries input.Bytes None

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

                    { imported with
                        Entries = imported.Entries |> List.map keepLock }

            match change with
            | Some(PluginOrderChange.Move _) ->
                let next = OrderRules.inspect input.Facts header.Entries order

                next.Issues
                |> List.tryFind (fun issue -> not (List.contains issue current.View.Issues))
                |> Option.iter (fun issue ->
                    raise (ProfileDataException(ProfileDataError.Invalid issue.Detail)))
            | _ -> ()

            let! context = DataInitialization.context repository scope
            let root = PluginInputs.ensureRoot input

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
                      PluginOrder = None }

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
                        if change.IsNone || context.PluginObserved.IsNone then
                            Some input.File
                        else
                            context.PluginObserved
                    Applied = context.Applied |> Option.map adopt }

            do!
                repository.SaveOrder(
                    context,
                    { profile with
                        Revision = profile.Revision + 1L
                        PluginOrder = Some order },
                    header.Stamp
                )

            return! read repository plugins expected.WorkspaceId expected.ProfileId id
        }

    let forLaunch (plugins: PluginSession) (scope: ProfileDataScope) token =
        task {
            let saved = scope.Profile |> Option.bind _.PluginOrder
            let! result = plugins.Observe(scope.ProfileId, token)

            let header =
                match result with
                | Ok value when not value.Stale -> value
                | Error FilePlanError.Busy -> raise (ProfileDataException ProfileDataError.Busy)
                | _ ->
                    raise (
                        ProfileDataException(
                            ProfileDataError.Unavailable "Refresh the plugins before playing."
                        )
                    )

            let input = PluginInputs.read scope header.Entries token

            if
                scope.Context
                |> Option.bind _.PluginObserved
                |> Option.exists (fun observed -> observed <> input.File)
            then
                raise (
                    ProfileDataException(
                        ProfileDataError.Conflict
                            "The game plugin list changed. Use game order before playing."
                    )
                )

            let order = OrderRules.reconcile input.Facts header.Entries input.Bytes saved
            let view = OrderRules.inspect input.Facts header.Entries order

            match view.Issues with
            | issue :: _ -> raise (ProfileDataException(ProfileDataError.Invalid issue.Detail))
            | [] -> ()

            if not header.Problems.IsEmpty then
                raise (ProfileDataException(ProfileDataError.Invalid header.Problems.Head))

            return saved |> Option.map (fun _ -> OrderDocument.write input.Facts.Early order)
        }
