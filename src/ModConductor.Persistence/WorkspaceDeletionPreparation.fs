namespace ModConductor.Persistence

open System
open System.Threading
open ModConductor.Deployment
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module internal WorkspaceDeletionPreparation =
    let private deploymentError =
        function
        | DeploymentError.Busy -> WorkspaceError.Busy
        | DeploymentError.Stale -> WorkspaceError.StaleRevision
        | DeploymentError.NotFound ->
            WorkspaceError.ProfileData
                "The active deployment is unavailable. Refresh its game context before deletion."
        | DeploymentError.Cancelled ->
            WorkspaceError.ProfileData "Workspace deletion was cancelled."
        | DeploymentError.Blocked detail
        | DeploymentError.Unavailable detail -> WorkspaceError.ProfileData detail

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

    let private deactivate (backend: IDeploymentBackend) profile generation token =
        task {
            let! read = backend.Read profile

            match read with
            | Error error -> return Error(deploymentError error)
            | Ok state when state.ActiveGeneration <> Some generation ->
                return Error WorkspaceError.StaleRevision
            | Ok state ->
                let! prepared =
                    backend.PrepareRetained(Guid.NewGuid(), state.Sources, None, ignore, token)

                match prepared with
                | Error error -> return Error(deploymentError error)
                | Ok value when value.Profile.IsSome ->
                    return
                        Error(WorkspaceError.ProfileData "The game files could not be deactivated.")
                | Ok value ->
                    let! finished = backend.Activate(value.Id, value.Sources, ignore, token)
                    return finished |> Result.map ignore |> Result.mapError deploymentError
        }

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

    let deactivateAffected backend (state: WorkspaceDeletionState) token =
        state.Deployments
        |> List.choose (fun (context, generation) ->
            if context.Active <> Some generation.Id then
                None
            else
                generation.Provenance
                |> Option.bind _.Profile
                |> Option.map (fun profile -> profile.Id, generation.Id))
        |> List.distinct
        |> each (fun (profile, generation) -> deactivate backend profile generation token)

    let unapply (data: IProfileGameData) (state: WorkspaceDeletionState) token =
        let restore (context: ProfileDataContext) =
            task {
                let profile = context.Applied.Value.ProfileId
                let! current = data.Read(state.Workspace.Id, profile)

                match current with
                | Error error -> return Error(dataError error)
                | Ok current when current.ContextId <> context.Id ->
                    return
                        Error(
                            WorkspaceError.ProfileData
                                "Select and refresh the applied profile's original game context before deleting this workspace."
                        )
                | Ok current ->
                    let! restored = data.Restore(Guid.NewGuid(), current.Reference, token)

                    return
                        restored
                        |> Result.bind (fun result ->
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
