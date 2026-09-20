namespace ModConductor.Engine

open ModConductor
open ModConductor.GameLaunching
open ModConductor.Executables

type GameLaunchService(launches: IGameLaunching, skse: SkseCoordinator) =
    inherit Protocol.V1.GameLaunchOperations.GameLaunchOperationsBase()

    override _.ReadGameLaunch(request, _) =
        task {
            let workspace = ModLibraryWire.id request.WorkspaceId
            let profile = ModLibraryWire.id request.ProfileId
            let! skseCheck = skse.CheckBeforePlay(workspace, profile)
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
                return Protocol.V1.GameLaunchStateReply(State = wire)
        }

    override _.PlayGame(request, _) =
        task {
            let parsed = ExecutableWire.parseGameRequest request
            let! allowed = skse.CheckBeforePlay(parsed.WorkspaceId, parsed.ProfileId)

            match allowed with
            | Error detail ->
                return ExecutableWire.runReply (Error(ExecutableError.Unavailable detail))
            | Ok() ->
                let! result = launches.Begin parsed
                return ExecutableWire.runReply result
        }

    override _.CancelGameLaunch(request, _) =
        task {
            let! result =
                launches.Cancel(ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.Id)

            return ExecutableWire.runReply result
        }
