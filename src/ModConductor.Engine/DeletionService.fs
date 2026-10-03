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

    let rec deactivateAffected profiles token =
        task {
            match profiles with
            | [] -> return Ok()
            | (profile, generation) :: remaining ->
                let! result = deployments.Deactivate(profile, generation, token)

                match result with
                | Error error -> return Error(failure error)
                | Ok() -> return! deactivateAffected remaining token
        }

    override _.DeleteMod(request, context) =
        InstallationWire.guard (fun () ->
            task {
                let workspace = ModLibraryWire.id request.WorkspaceId
                let modId = ModLibraryWire.id request.ModId
                let revision = ModLibraryWire.number request.Revision
                let! affected = store.ActiveProfiles(workspace, modId, revision)
                let profiles = affected |> InstallationWire.outcome |> List.distinctBy fst
                let! deactivated = deactivateAffected profiles context.CancellationToken
                deactivated |> InstallationWire.outcome |> ignore

                let! deleted = store.Delete(workspace, modId, revision)

                deleted |> InstallationWire.outcome |> ignore

                return ModDeleted()
            })
