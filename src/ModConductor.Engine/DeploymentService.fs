namespace ModConductor.Engine

open System.Threading.Channels
open ModConductor
open ModConductor.Deployment

module private DeploymentStream =
    let send
        (context: Grpc.Core.ServerCallContext)
        (output: Grpc.Core.IServerStreamWriter<'Event>)
        progress
        finished
        execute
        =
        task {
            let options =
                BoundedChannelOptions(
                    1,
                    FullMode = BoundedChannelFullMode.DropOldest,
                    SingleReader = true,
                    SingleWriter = true
                )

            let events = Channel.CreateBounded<'Event> options

            let producer =
                task {
                    try
                        let! result =
                            execute (fun value -> events.Writer.TryWrite(progress value) |> ignore)

                        events.Writer.TryWrite(finished result) |> ignore
                        events.Writer.TryComplete() |> ignore
                    with error ->
                        events.Writer.TryComplete error |> ignore
                }

            let mutable reading = true

            while reading do
                let! more = events.Reader.WaitToReadAsync(context.CancellationToken)
                reading <- more

                if more then
                    let mutable item = Unchecked.defaultof<'Event>

                    while events.Reader.TryRead(&item) do
                        do! output.WriteAsync(item, context.CancellationToken)

            do! producer
        }

type DeploymentService(deployments: IDeploymentBackend) =
    inherit Protocol.V1.DeploymentOperations.DeploymentOperationsBase()

    let expected profile token =
        task {
            let! state = deployments.Read(ModLibraryWire.id profile)

            return
                state
                |> Result.bind (fun state ->
                    if DeploymentWire.token state.Sources = token then
                        Ok state.Sources
                    else
                        Error DeploymentError.Stale)
        }

    override _.ReadDeployment(request, _) =
        task {
            let! result = deployments.Read(ModLibraryWire.id request.ProfileId)
            return DeploymentWire.stateReply result
        }

    override _.ReadSavedDeployments(request, _) =
        task {
            let! result =
                deployments.Saved(
                    ModLibraryWire.id request.ProfileId,
                    if request.HasBefore then
                        Some(ModLibraryWire.number request.Before)
                    else
                        None
                )

            return DeploymentWire.savedReply result
        }

    override _.ReadDeploymentReceipt(request, _) =
        task {
            let! result = deployments.Receipt(ModLibraryWire.id request.ReceiptId)
            return DeploymentWire.receiptReply result
        }

    override _.PrepareDeployment(request, output, context) =
        DeploymentStream.send
            context
            output
            (fun value ->
                Protocol.V1.DeploymentPrepareEvent(Progress = DeploymentWire.progress value))
            (fun result ->
                Protocol.V1.DeploymentPrepareEvent(Finished = DeploymentWire.preparedReply result))
            (fun progress ->
                task {
                    let! sources = expected request.ProfileId request.SourceToken

                    match sources with
                    | Error error -> return Error error
                    | Ok sources ->
                        if request.Retained then
                            return!
                                deployments.PrepareRetained(
                                    ModLibraryWire.id request.Id,
                                    sources,
                                    (if request.HasGenerationId then
                                         Some(ModLibraryWire.id request.GenerationId)
                                     else
                                         None),
                                    progress,
                                    context.CancellationToken
                                )
                        elif request.HasGenerationId then
                            return
                                ModLibraryWire.reject
                                    "A saved deployment requires a restore request."
                        else
                            return!
                                deployments.Prepare(
                                    ModLibraryWire.id request.Id,
                                    sources,
                                    progress,
                                    context.CancellationToken
                                )
                })

    override _.ActivateDeployment(request, output, context) =
        DeploymentStream.send
            context
            output
            (fun value -> Protocol.V1.DeploymentRunEvent(Progress = DeploymentWire.progress value))
            (fun result ->
                Protocol.V1.DeploymentRunEvent(Finished = DeploymentWire.receiptReply result))
            (fun progress ->
                task {
                    let! sources = expected request.ProfileId request.SourceToken

                    match sources with
                    | Error error -> return Error error
                    | Ok sources ->
                        return!
                            deployments.Activate(
                                ModLibraryWire.id request.PreparedId,
                                sources,
                                progress,
                                context.CancellationToken
                            )
                })

    override _.RecoverDeployment(request, output, context) =
        DeploymentStream.send
            context
            output
            (fun value -> Protocol.V1.DeploymentRunEvent(Progress = DeploymentWire.progress value))
            (fun result ->
                Protocol.V1.DeploymentRunEvent(Finished = DeploymentWire.receiptReply result))
            (fun progress ->
                deployments.Recover(
                    ModLibraryWire.id request.ReceiptId,
                    ModLibraryWire.number request.Revision,
                    request.Restore,
                    progress,
                    context.CancellationToken
                ))
