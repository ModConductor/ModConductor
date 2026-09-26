namespace ModConductor.Engine

open System
open System.Threading.Tasks
open Grpc.Core
open ModConductor.Fnis
open ModConductor.Protocol.V1

type internal FnisService(coordinator: FnisCoordinator, execution: IFnisExecution) =
    inherit FnisOperations.FnisOperationsBase()

    let ids (request: FnisRequest) =
        ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.ProfileId

    let outputPhase
        (value: ModConductor.Fnis.FnisOutputPhase)
        : ModConductor.Protocol.V1.FnisOutputPhase =
        match value with
        | ModConductor.Fnis.FnisOutputPhase.Unavailable ->
            ModConductor.Protocol.V1.FnisOutputPhase.Unavailable
        | ModConductor.Fnis.FnisOutputPhase.Missing ->
            ModConductor.Protocol.V1.FnisOutputPhase.Missing
        | ModConductor.Fnis.FnisOutputPhase.Stale -> ModConductor.Protocol.V1.FnisOutputPhase.Stale
        | ModConductor.Fnis.FnisOutputPhase.Current ->
            ModConductor.Protocol.V1.FnisOutputPhase.Current
        | ModConductor.Fnis.FnisOutputPhase.Running ->
            ModConductor.Protocol.V1.FnisOutputPhase.Running
        | ModConductor.Fnis.FnisOutputPhase.Failed ->
            ModConductor.Protocol.V1.FnisOutputPhase.Failed
        | ModConductor.Fnis.FnisOutputPhase.Cancelled ->
            ModConductor.Protocol.V1.FnisOutputPhase.Cancelled
        | ModConductor.Fnis.FnisOutputPhase.Abandoned ->
            ModConductor.Protocol.V1.FnisOutputPhase.Abandoned

    let wire (value: FnisView) output =
        let reply =
            FnisState(
                Phase = value.Phase,
                Version = value.Version,
                Status = value.Status,
                Detail = value.Detail,
                CanInstall = (value.Phase = FnisPhase.Available || value.Phase = FnisPhase.Failed),
                CanCancel =
                    (value.Phase = FnisPhase.WaitingForNexus
                     || value.Phase = FnisPhase.Downloading
                     || value.Phase = FnisPhase.Installing),
                CanUpdate =
                    (value.Phase = FnisPhase.UpdateAvailable || value.Phase = FnisPhase.Ready),
                CanRemove =
                    (value.Phase = FnisPhase.Ready
                     || value.Phase = FnisPhase.UpdateAvailable
                     || value.Phase = FnisPhase.SourceUnavailable),
                CanRecover = (value.Phase = FnisPhase.RecoveryRequired)
            )

        value.FileId |> Option.iter (fun id -> reply.NexusFileId <- id)

        output
        |> Option.iter (fun (value: FnisInspection) ->
            reply.OutputPhase <- outputPhase value.Phase
            reply.OutputStatus <- value.Status
            reply.OutputDetail <- value.Detail
            reply.CanRun <- value.Phase <> ModConductor.Fnis.FnisOutputPhase.Running
            reply.CanCancelRun <- value.Phase = ModConductor.Fnis.FnisOutputPhase.Running
            value.LatestRunId |> Option.iter (fun id -> reply.RunId <- id.ToString("N"))
            value.ExitCode |> Option.iter (fun code -> reply.ExitCode <- code)
            reply.StandardOutput <- value.StandardOutput
            reply.StandardError <- value.StandardError
            reply.RunLog <- value.RunLog)

        reply

    let read workspace profile token =
        task {
            let! value = coordinator.Read(workspace, profile)

            let! output =
                if
                    value.Phase = FnisPhase.Ready
                    || value.Phase = FnisPhase.UpdateAvailable
                    || value.Phase = FnisPhase.SourceUnavailable
                then
                    task {
                        let! result = execution.Inspect(workspace, profile, token)
                        return Result.toOption result
                    }
                else
                    Task.FromResult None

            return wire value output
        }

    override _.ReadFnis(request, context) =
        let workspace, profile = ids request
        read workspace profile context.CancellationToken

    override _.InstallFnis(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Install(workspace, profile)
            return wire value None
        }

    override _.CancelFnis(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Cancel(workspace, profile)
            return wire value None
        }

    override _.UpdateFnis(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Update(workspace, profile)
            return wire value None
        }

    override _.RemoveFnis(request, context) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Remove(workspace, profile, context.CancellationToken)
            return wire value None
        }

    override _.RecoverFnis(request, context) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Recover(workspace, profile, context.CancellationToken)
            return wire value None
        }

    override _.RunFnis(request, context) =
        task {
            let workspace = ModLibraryWire.id request.WorkspaceId
            let profile = ModLibraryWire.id request.ProfileId

            let! output =
                execution.Run(
                    { Id = ModLibraryWire.id request.Id
                      WorkspaceId = workspace
                      ProfileId = profile },
                    context.CancellationToken
                )

            let! setup = coordinator.Read(workspace, profile)
            return wire setup (Result.toOption output)
        }

    override _.ObserveFnisRun(request, stream, context) =
        task {
            let run =
                { Id = ModLibraryWire.id request.Id
                  WorkspaceId = ModLibraryWire.id request.WorkspaceId
                  ProfileId = ModLibraryWire.id request.ProfileId }

            let requireObserved =
                function
                | Ok value when value.LatestRunId = Some run.Id -> value
                | _ ->
                    raise (RpcException(Status(StatusCode.NotFound, "The FNIS run was not found.")))

            let! initial =
                execution.Inspect(run.WorkspaceId, run.ProfileId, context.CancellationToken)

            let initial = requireObserved initial
            let! setup = coordinator.Read(run.WorkspaceId, run.ProfileId)
            do! stream.WriteAsync(wire setup (Some initial), context.CancellationToken)

            if initial.Phase = ModConductor.Fnis.FnisOutputPhase.Running then
                let! completed = execution.WaitForRun(run, context.CancellationToken)
                let completed = requireObserved completed
                let! latestSetup = coordinator.Read(run.WorkspaceId, run.ProfileId)
                do! stream.WriteAsync(wire latestSetup (Some completed), context.CancellationToken)
        }

    override _.CancelFnisRun(request, _) =
        task {
            let workspace, profile = ids request
            let! output = execution.Cancel(workspace, profile)
            let! setup = coordinator.Read(workspace, profile)
            return wire setup (Result.toOption output)
        }
