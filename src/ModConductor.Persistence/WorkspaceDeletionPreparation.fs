namespace ModConductor.Persistence

open ModConductor.ProfileGameData
open ModConductor.Workspaces

module internal WorkspaceDeletionPreparation =
    let private dataError =
        function
        | ProfileDataError.Busy -> WorkspaceError.Busy
        | ProfileDataError.Stale -> WorkspaceError.StaleRevision
        | ProfileDataError.NotFound ->
            WorkspaceError.ProfileData "The applied profile data is unavailable."
        | ProfileDataError.Cancelled ->
            WorkspaceError.ProfileData "Workspace deletion was cancelled."
        | ProfileDataError.Invalid detail
        | ProfileDataError.Unavailable detail
        | ProfileDataError.Conflict detail -> WorkspaceError.ProfileData detail

    let rec private each action items =
        task {
            match items with
            | [] -> return Ok()
            | item :: rest ->
                let! result = action item

                match result with
                | Error error -> return Error error
                | Ok() -> return! each action rest
        }

    let unapply restoreContext (state: WorkspaceDeletionState) token =
        let restore (context: ProfileDataContext) =
            task {
                let! restored = restoreContext context token

                return
                    restored
                    |> Result.bind (fun (result: ProfileDataResult) ->
                        if result.Complete then
                            Ok()
                        else
                            Error(
                                ProfileDataError.Unavailable(
                                    result.Problem
                                    |> Option.defaultValue
                                        "Restore the applied profile data before deletion."
                                )
                            ))
                    |> Result.mapError dataError
            }

        state.Data
        |> List.map fst
        |> List.filter (fun context -> context.Applied.IsSome)
        |> each restore
