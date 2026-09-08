namespace ModConductor.Engine

open System.Threading.Channels
open ModConductor
open ModConductor.GeneratedOutputs

type OutputService(outputs: IGeneratedOutputs) =
    inherit Protocol.V1.GeneratedOutputOperations.GeneratedOutputOperationsBase()

    let expected (value: Protocol.V1.OutputScopeRef) =
        if isNull value then
            ModLibraryWire.reject "Read the output locations first."

        task {
            let! read =
                outputs.Read(
                    ModLibraryWire.id value.WorkspaceId,
                    Some(ModLibraryWire.id value.ContextId)
                )

            return
                read
                |> Result.bind (fun scope ->
                    if
                        scope.Revision <> ModLibraryWire.number value.Revision
                        || scope.ContextRevision <> ModLibraryWire.number value.ContextRevision
                    then
                        Error OutputError.Stale
                    else
                        Ok scope)
        }

    override _.ReadOutputs(request, _) =
        task {
            let! read =
                outputs.Read(
                    ModLibraryWire.id request.WorkspaceId,
                    if request.HasContextId then
                        Some(ModLibraryWire.id request.ContextId)
                    else
                        None
                )

            return OutputWire.scopeReply read
        }

    override _.AddOutputLocation(request, _) =
        task {
            let purpose =
                match request.Kind with
                | Protocol.V1.OutputLocationKind.ToolFolder -> OutputPurpose.ToolFolder
                | Protocol.V1.OutputLocationKind.WritableFile ->
                    OutputPurpose.WritableFile(ModLibraryWire.path request.Target)
                | _ -> ModLibraryWire.reject "Choose a tool folder or writable game file."

            let! scope = expected request.Expected

            match scope with
            | Error error -> return OutputWire.locationReply (Error error)
            | Ok scope ->
                let! result =
                    outputs.Add(ModLibraryWire.id request.Id, scope, request.Name, purpose)

                return OutputWire.locationReply result
        }

    override _.StopUsingOutputLocation(request, _) =
        task {
            let! result =
                outputs.StopUsing(
                    ModLibraryWire.id request.Id,
                    ModLibraryWire.number request.Revision
                )

            return OutputWire.locationReply result
        }

    override _.ReadOutputPage(request, _) =
        task {
            let view =
                match request.Kind with
                | Protocol.V1.OutputLocationKind.ToolFolder -> OutputView.ToolOutputs
                | Protocol.V1.OutputLocationKind.WritableFile -> OutputView.WritableFiles
                | _ -> ModLibraryWire.reject "Choose an output view."

            let! result =
                outputs.Page(
                    ModLibraryWire.id request.SnapshotId,
                    view,
                    (if request.HasCursor then Some request.Cursor else None),
                    request.Filter
                )

            return OutputWire.pageReply result
        }

    override _.PreviewOutputPromotion(request, _) =
        task {
            let! result =
                outputs.Preview(
                    ModLibraryWire.id request.SnapshotId,
                    OutputWire.readSelection request.Files,
                    OutputWire.readAction request.Action
                )

            return OutputWire.previewReply result
        }

    override _.ApplyOutputAction(request, context) =
        task {
            let! result =
                outputs.Apply(
                    ModLibraryWire.id request.Id,
                    ModLibraryWire.id request.SnapshotId,
                    OutputWire.readSelection request.Files,
                    OutputWire.readAction request.Action,
                    context.CancellationToken
                )

            return OutputWire.actionReply result
        }

    override _.ReadOutputAction(request, _) =
        task {
            let! result = outputs.Action(ModLibraryWire.id request.Id)
            return OutputWire.actionReply result
        }

    override _.ResumeOutputAction(request, context) =
        task {
            let! result = outputs.Resume(ModLibraryWire.id request.Id, context.CancellationToken)
            return OutputWire.actionReply result
        }

    override _.ObserveOutputs(request, output, context) =
        task {
            let options =
                BoundedChannelOptions(
                    1,
                    FullMode = BoundedChannelFullMode.DropOldest,
                    SingleReader = true,
                    SingleWriter = true
                )

            let events = Channel.CreateBounded<Protocol.V1.OutputLoadEvent> options

            let producer =
                task {
                    try
                        let! scope = expected request.Expected

                        let! result =
                            match scope with
                            | Error error -> System.Threading.Tasks.Task.FromResult(Error error)
                            | Ok scope ->
                                outputs.Observe(
                                    scope,
                                    (fun value ->
                                        events.Writer.TryWrite(
                                            Protocol.V1.OutputLoadEvent(
                                                Progress =
                                                    Protocol.V1.OutputProgress(
                                                        Files = uint32 value.Files,
                                                        Bytes = uint64 value.Bytes
                                                    )
                                            )
                                        )
                                        |> ignore),
                                    context.CancellationToken
                                )

                        events.Writer.TryWrite(
                            Protocol.V1.OutputLoadEvent(Finished = OutputWire.snapshotReply result)
                        )
                        |> ignore

                        events.Writer.TryComplete() |> ignore
                    with error ->
                        events.Writer.TryComplete error |> ignore
                }

            let mutable reading = true

            while reading do
                let! more = events.Reader.WaitToReadAsync(context.CancellationToken)
                reading <- more

                if more then
                    let mutable item = Unchecked.defaultof<Protocol.V1.OutputLoadEvent>

                    while events.Reader.TryRead(&item) do
                        do! output.WriteAsync(item, context.CancellationToken)

            do! producer
        }
