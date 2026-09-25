namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.Protocol.V1

type internal EnbService(coordinator: EnbCoordinator) =
    inherit EnbOperations.EnbOperationsBase()

    let ids (request: EnbRequest) =
        ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.ProfileId

    let wire value =
        EnbState(
            Phase = value.Phase,
            Status = value.Status,
            Detail = value.Detail,
            RuntimeVersion = value.RuntimeVersion,
            PresetVersion = value.PresetVersion,
            CanOpenAuthorPage =
                (value.Phase = EnbPhase.Available
                 || value.Phase = EnbPhase.WaitingForArchive
                 || value.Phase = EnbPhase.Failed),
            CanSelectArchive =
                (value.Phase = EnbPhase.WaitingForArchive || value.Phase = EnbPhase.Failed),
            CanCancel = (value.Phase = EnbPhase.WaitingForArchive),
            CanUpdate = (value.Phase = EnbPhase.Ready),
            CanRemove = (value.Phase = EnbPhase.Ready),
            CanRecover = (value.Phase = EnbPhase.Failed || value.Phase = EnbPhase.Conflict)
        )

    override _.ReadEnb(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Read(workspace, profile)
            return wire value
        }

    override _.OpenEnbAuthorPage(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.OpenAuthorPage(workspace, profile)
            return wire value
        }

    override _.CancelEnbWait(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Cancel(workspace, profile)
            return wire value
        }

    override _.SelectEnbArchive(request, context) =
        task {
            let workspace = ModLibraryWire.id request.WorkspaceId
            let profile = ModLibraryWire.id request.ProfileId
            let operation = ModLibraryWire.id request.OperationId

            let! value =
                coordinator.SelectArchive(
                    workspace,
                    profile,
                    operation,
                    request.Path,
                    context.CancellationToken
                )

            return wire value
        }

    override _.UpdateEnb(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Update(workspace, profile)
            return wire value
        }

    override _.RemoveEnb(request, context) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Remove(workspace, profile, context.CancellationToken)
            return wire value
        }

    override _.RecoverEnb(request, context) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Recover(workspace, profile, context.CancellationToken)
            return wire value
        }
