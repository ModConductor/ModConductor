namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Threading.Tasks
open ModConductor.Platform

module internal ProfileDataProjection =
    let count root =
        match root with
        | None -> Ok 0
        | Some root ->
            let mutable count = 0

            let rec walk (root: DataRoot) depth =
                if depth > 128 || count > 1000000 then
                    Error(
                        ProfileDataError.Unavailable
                            "The private folder exceeds the supported limits."
                    )
                else
                    use held = HeldDirectory.Open(root.Path, root.Identity)
                    use names = held.Names.GetEnumerator()
                    let mutable problem = None

                    while problem.IsNone && names.MoveNext() do
                        let name = names.Current

                        match held.InspectEntry name with
                        | Some entry when entry.Kind = EntryKind.RegularFile ->
                            count <- count + 1

                            if count > 1000000 then
                                problem <-
                                    Some(
                                        ProfileDataError.Unavailable
                                            "The private folder exceeds the supported limits."
                                    )
                        | Some entry when entry.Kind = EntryKind.Directory ->
                            use child = held.Directory(name, Some entry.Identity)

                            let path =
                                HostPath.create (Path.Combine(HostPath.value root.Path, name))
                                |> Result.defaultWith invalidOp

                            match
                                walk
                                    { Path = path
                                      Identity = child.Identity }
                                    (depth + 1)
                            with
                            | Ok() -> ()
                            | Error error -> problem <- Some error
                        | _ ->
                            problem <-
                                Some(
                                    ProfileDataError.Unavailable
                                        "The private folder contains an unsupported entry."
                                )

                    match problem with
                    | Some error -> Error error
                    | None -> Ok()

            walk root 0 |> Result.map (fun () -> count)

    let view (scope: ProfileDataScope) =
        let profile = scope.Profile
        let mutable problem = scope.Availability

        let countKnown root =
            try
                match count root with
                | Ok value -> value
                | Error error ->
                    problem <- Some(DataErrors.problemMessage error)
                    0
            with :? IOException as error ->
                problem <- Some error.Message
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
          PendingConfiguration = None
          Problem = problem }
        : ProfileDataState

    let read (repository: IProfileDataRepository) workspace profile =
        ProfileDataResultTask.resultTask {
            let! scopeResult = repository.Read(workspace, profile)
            let! scope = scopeResult
            let state = view scope

            match state.Pending with
            | None -> return state
            | Some id ->
                let! actionResult = repository.Action(workspace, id)
                let! action = actionResult

                let profileChange =
                    action
                    |> Option.exists (fun value ->
                        match value.Kind with
                        | ProfileDataActionKind.Clone _
                        | ProfileDataActionKind.Delete _ -> true
                        | _ -> false)

                let pendingConfiguration =
                    action
                    |> Option.bind (fun value ->
                        match value.Kind with
                        | ProfileDataActionKind.EditConfiguration receipt -> Some receipt.Name
                        | _ -> None)

                let active =
                    match action with
                    | Some value when value.Deletion.IsSome ->
                        value.Proposed |> Option.map _.ProfileId
                    | _ -> state.InUse

                return
                    { state with
                        Problem = action |> Option.bind _.Problem |> Option.orElse state.Problem
                        PendingProfileChange = profileChange
                        PendingConfiguration = pendingConfiguration
                        InUse = active }
        }

    let check (scope: ProfileDataScope) (expected: ProfileDataRef) =
        match scope.Availability with
        | Some detail -> Error(ProfileDataError.Unavailable detail)
        | None ->
            let id =
                scope.Context
                |> Option.map _.Id
                |> Option.defaultWith (fun () ->
                    DataLocations.id scope.WorkspaceId (DataLocations.documents scope.Game))

            let revision = scope.Context |> Option.map _.Revision |> Option.defaultValue 0L

            if id <> expected.ContextId || revision <> expected.Revision then
                Error ProfileDataError.Stale
            else
                Ok()
