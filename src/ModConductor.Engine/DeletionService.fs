namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.Persistence
open ModConductor.Protocol.V1

type DeletionService(store: DeletionStore, deployments: IDeploymentBackend) =
    inherit ModDeletion.ModDeletionBase()

    let failure error = (DeploymentWire.fault error).Detail

    let deactivate profile generation (token: CancellationToken) =
        task {
            let! current = deployments.Read profile

            match current with
            | Error error -> return Error(failure error)
            | Ok state when state.ActiveGeneration <> Some generation ->
                return Error "The active game files changed. Try again."
            | Ok state ->
                let! prepared =
                    deployments.PrepareRetained(Guid.NewGuid(), state.Sources, None, ignore, token)

                match prepared with
                | Error error -> return Error(failure error)
                | Ok value when value.Profile.IsSome ->
                    return Error "The game files could not be deactivated."
                | Ok value ->
                    let! finished = deployments.Activate(value.Id, value.Sources, ignore, token)
                    return finished |> Result.map ignore |> Result.mapError failure
        }

    let rec deactivateAffected profiles token =
        task {
            match profiles with
            | [] -> return Ok()
            | (profile, generation) :: remaining ->
                let! result = deactivate profile generation token

                match result with
                | Error error -> return Error error
                | Ok() -> return! deactivateAffected remaining token
        }

    override _.DeleteMod(request, context) =
        InstallationWire.guard (fun () ->
            task {
                let workspace = ModLibraryWire.id request.WorkspaceId
                let modId = ModLibraryWire.id request.ModId
                let revision = ModLibraryWire.number request.Revision
                let! affected = store.ActiveProfiles(workspace, modId, revision)
                let profiles = affected |> InstallationWire.outcome
                let! deactivated = deactivateAffected profiles context.CancellationToken
                deactivated |> InstallationWire.outcome |> ignore

                let! deleted = store.Delete(workspace, modId, revision)

                deleted |> InstallationWire.outcome |> ignore

                return ModDeleted()
            })
