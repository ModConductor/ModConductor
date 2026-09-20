namespace ModConductor.Engine

open ModConductor
open ModConductor.GameLaunching
open ModConductor.Executables
open ModConductor.Fnis

type GameLaunchService(launches: IGameLaunching, skse: SkseCoordinator, fnis: IFnisInspection) =
    inherit Protocol.V1.GameLaunchOperations.GameLaunchOperationsBase()

    let stale =
        function
        | FnisOutputPhase.Missing
        | FnisOutputPhase.Stale
        | FnisOutputPhase.Failed
        | FnisOutputPhase.Cancelled
        | FnisOutputPhase.Abandoned -> true
        | _ -> false

    let inspect workspace profile token =
        task {
            let! result = fnis.Inspect(workspace, profile, token)
            return Result.toOption result
        }

    let play request (context: Grpc.Core.ServerCallContext) continueStale =
        task {
            let parsed = ExecutableWire.parseGameRequest request
            let! allowed = skse.CheckBeforePlay(parsed.WorkspaceId, parsed.ProfileId)
            let! fnisCheck = inspect parsed.WorkspaceId parsed.ProfileId context.CancellationToken

            match allowed, fnisCheck with
            | Error detail, _ ->
                return ExecutableWire.runReply (Error(ExecutableError.Unavailable detail))
            | Ok(), Some value when stale value.Phase && not continueStale ->
                return
                    ExecutableWire.runReply (
                        Error(
                            ExecutableError.Unavailable(
                                value.Status + ". Run FNIS or explicitly continue without it."
                            )
                        )
                    )
            | Ok(), _ ->
                let! result = launches.Begin parsed
                return ExecutableWire.runReply result
        }

    override _.ReadGameLaunch(request, context) =
        task {
            let workspace = ModLibraryWire.id request.WorkspaceId
            let profile = ModLibraryWire.id request.ProfileId
            let! skseCheck = skse.CheckBeforePlay(workspace, profile)
            let! fnisCheck = inspect workspace profile context.CancellationToken
            let! result = launches.Read(workspace, profile)

            match result with
            | Error error ->
                return Protocol.V1.GameLaunchStateReply(Problem = ExecutableWire.problem error)
            | Ok value ->
                let wire =
                    Protocol.V1.GameLaunchState(
                        WorkspaceId = value.WorkspaceId.ToString("N"),
                        ProfileId = value.ProfileId.ToString("N"),
                        ContextRevision = uint64 value.ContextRevision,
                        SourceToken = value.SourceToken,
                        Name = value.Name,
                        Runtime = value.Runtime
                    )

                (match skseCheck with
                 | Error detail -> Some detail
                 | Ok() -> value.Problem)
                |> Option.iter (fun detail -> wire.Problem <- detail)

                value.Latest |> Option.iter (fun run -> wire.Latest <- ExecutableWire.run run)
                fnisCheck
                |> Option.iter (fun value ->
                    wire.FnisStale <- stale value.Phase
                    wire.FnisStatus <- value.Status
                    wire.CanRunFnis <- value.Phase <> FnisOutputPhase.Running)
                return Protocol.V1.GameLaunchStateReply(State = wire)
        }

    override _.PlayGame(request, context) = play request context false

    override _.PlayGameContinuingFnis(request, context) = play request context true

    override _.CancelGameLaunch(request, _) =
        task {
            let! result =
                launches.Cancel(ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.Id)

            return ExecutableWire.runReply result
        }
