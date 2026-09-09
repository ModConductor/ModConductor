namespace ModConductor.Engine

open ModConductor
open ModConductor.GameLaunching

type GameLaunchService(launches: IGameLaunching) =
    inherit Protocol.V1.GameLaunchOperations.GameLaunchOperationsBase()

    override _.ReadGameLaunch(request, _) =
        task {
            let! result =
                launches.Read(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId
                )

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

                value.Problem |> Option.iter (fun detail -> wire.Problem <- detail)
                value.Latest |> Option.iter (fun run -> wire.Latest <- ExecutableWire.run run)
                return Protocol.V1.GameLaunchStateReply(State = wire)
        }

    override _.PlayGame(request, _) =
        task {
            let! result = launches.Begin(ExecutableWire.parseGameRequest request)
            return ExecutableWire.runReply result
        }

    override _.CancelGameLaunch(request, _) =
        task {
            let! result =
                launches.Cancel(ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.Id)

            return ExecutableWire.runReply result
        }
