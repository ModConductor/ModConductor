namespace ModConductor.Engine

open ModConductor.Protocol.V1

type internal SkseService(coordinator: SkseCoordinator) =
    inherit SkseOperations.SkseOperationsBase()

    let ids (request: SkseRequest) =
        ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.ProfileId

    let wire (value: SkseView) =
        let reply =
            SkseState(
                Phase = value.Phase,
                GameVersion = value.GameVersion,
                ComponentVersion = value.ComponentVersion,
                Status = value.Status,
                Detail = value.Detail
            )

        value.FileId |> Option.iter (fun id -> reply.NexusFileId <- id)
        reply

    override _.ReadSkse(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Read(workspace, profile)
            return wire value
        }

    override _.StartSkse(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Start(workspace, profile)
            return wire value
        }

    override _.CheckSkseUpdate(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.CheckUpdate(workspace, profile)
            return wire value
        }
