namespace ModConductor.Engine

open System
open System.Threading.Channels

module internal ProfileActionStream =
    let send
        (context: Grpc.Core.ServerCallContext)
        (output: Grpc.Core.IServerStreamWriter<'Event>)
        progress
        finished
        execute
        =
        task {
            let events =
                Channel.CreateBounded<'Event>(
                    BoundedChannelOptions(
                        1,
                        FullMode = BoundedChannelFullMode.DropOldest,
                        SingleReader = true,
                        SingleWriter = true
                    )
                )

            let mutable last = DateTime.MinValue

            let notify value =
                if (DateTime.UtcNow - last).TotalMilliseconds >= 100. then
                    last <- DateTime.UtcNow
                    events.Writer.TryWrite(progress value) |> ignore

            let producer =
                task {
                    try
                        let! result = execute notify
                        events.Writer.TryWrite(finished result) |> ignore
                        events.Writer.TryComplete() |> ignore
                    with error ->
                        events.Writer.TryComplete error |> ignore
                }

            let mutable failure = None

            try
                let mutable reading = true

                while reading do
                    let! more = events.Reader.WaitToReadAsync(context.CancellationToken)
                    reading <- more

                    if more then
                        let mutable item = Unchecked.defaultof<'Event>

                        while events.Reader.TryRead(&item) do
                            do! output.WriteAsync(item, context.CancellationToken)
            with error ->
                failure <- Some error

            do! producer
            failure |> Option.iter raise
        }
