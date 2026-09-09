namespace ModConductor.Engine

open System.Threading.Tasks
open ModConductor
open ModConductor.Executables

type ExecutableService(executables: IExecutables) =
    inherit Protocol.V1.ExecutableOperations.ExecutableOperationsBase()

    let page (request: Protocol.V1.ExecutablePageRequest) =
        ModLibraryWire.id request.WorkspaceId,
        (if request.HasAfterId then
             Some(ModLibraryWire.id request.AfterId)
         else
             None)

    let reference (request: Protocol.V1.ExecutableRunRef) =
        ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.Id

    override _.ListExecutablePresets(request, _) =
        task {
            let! result = executables.List(page request)
            let reply = Protocol.V1.ExecutablePresetPageReply()

            match result with
            | Error error -> reply.Problem <- ExecutableWire.problem error
            | Ok value ->
                reply.Presets.AddRange(value.Presets |> Seq.map ExecutableWire.preset)
                reply.LatestRuns.AddRange(value.LatestRuns |> Seq.map ExecutableWire.run)
                value.Next |> Option.iter (fun id -> reply.NextId <- id.ToString("N"))

            return reply
        }

    override _.ReadExecutablePreset(request, _) =
        task {
            let! result =
                executables.ReadPreset(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.Id
                )

            return ExecutableWire.presetReply result
        }

    override _.SaveExecutablePreset(request, _) =
        task {
            let! result = executables.Save(ExecutableWire.parsePreset request)
            return ExecutableWire.presetReply result
        }

    override _.DeleteExecutablePreset(request, _) =
        task {
            let! result =
                executables.Delete(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.Id,
                    ModLibraryWire.number request.ExpectedRevision
                )

            let reply = Protocol.V1.ExecutableMutationReply()

            match result with
            | Ok() -> ()
            | Error error -> reply.Problem <- ExecutableWire.problem error

            return reply
        }

    override _.BeginExecutableRun(request, _) =
        task {
            let! result = executables.Begin(ExecutableWire.parseRequest request)
            return ExecutableWire.runReply result
        }

    override _.ReadExecutableRun(request, _) =
        task {
            let! result = executables.Read(reference request)
            return ExecutableWire.runReply result
        }

    override _.ReadExecutableRuns(request, _) =
        task {
            let! result = executables.Recent(page request)
            let reply = Protocol.V1.ExecutableRunPageReply()

            match result with
            | Error error -> reply.Problem <- ExecutableWire.problem error
            | Ok(rows, next) ->
                reply.Runs.AddRange(rows |> Seq.map ExecutableWire.run)
                next |> Option.iter (fun id -> reply.NextId <- id.ToString("N"))

            return reply
        }

    override _.StopWaitingForExecutable(request, _) =
        task {
            let! result = executables.StopWaiting(reference request)
            return ExecutableWire.runReply result
        }

    override _.ObserveExecutableRun(request, stream, context) =
        task {
            let key = reference request
            let mutable watching = true
            let mutable revision = -1L

            while watching && not context.CancellationToken.IsCancellationRequested do
                let! result = executables.Read key

                match result with
                | Error _ ->
                    do! stream.WriteAsync(ExecutableWire.runReply result, context.CancellationToken)
                    watching <- false
                | Ok value ->
                    if value.Revision <> revision then
                        do!
                            stream.WriteAsync(
                                ExecutableWire.runReply result,
                                context.CancellationToken
                            )

                        revision <- value.Revision

                    watching <- not (ExecutablePolicy.terminal value.Phase)

                if watching then
                    do! Task.Delay(200, context.CancellationToken)
        }
