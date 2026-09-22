namespace ModConductor.Engine

open ModConductor.Persistence
open ModConductor.Protocol.V1

type DeletionService(store: DeletionStore) =
    inherit ModDeletion.ModDeletionBase()

    override _.DeleteMod(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace = ModLibraryWire.id request.WorkspaceId
                let modId = ModLibraryWire.id request.ModId

                do! store.Delete(workspace, modId, ModLibraryWire.number request.Revision)

                return ModDeleted()
            })
