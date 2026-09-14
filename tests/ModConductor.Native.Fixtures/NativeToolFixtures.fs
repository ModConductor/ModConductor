namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.Loot
open ModConductor.Platform

module NativeToolFixtures =
    let child mode =
        match mode with
        | "echo" ->
            use input = Console.OpenStandardInput()
            use output = Console.OpenStandardOutput()
            input.CopyTo output
            0
        | "oversize" ->
            Console.OpenStandardOutput().Write(Array.zeroCreate<byte> (5 * 1024 * 1024))
            0
        | "malformed" ->
            Console.Write "{"
            0
        | "crash" ->
            Console.Error.Write "fixture helper failed"
            23
        | "wait" ->
            let start =
                Diagnostics.ProcessStartInfo(Environment.ProcessPath, "--native-tool-grandchild")

            start.UseShellExecute <- false
            use _grandchild = Diagnostics.Process.Start start
            Thread.Sleep Timeout.Infinite
            0
        | _ -> 2

    let grandchild () =
        Thread.Sleep Timeout.Infinite
        0

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject "nativeTool"
        let area = Directory.CreateDirectory(Path.Combine(primary, "native-tool")).FullName

        let check (name: string) (value: bool) =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                invalidOp ("Native tool fixture failed: " + name)

        let limits =
            { InputBytes = 1024
              OutputBytes = 1024
              ErrorBytes = 1024
              Timeout = TimeSpan.FromSeconds 5.0 }

        let run mode input token =
            let command = Environment.GetCommandLineArgs()[0]

            let arguments =
                if command.EndsWith(".dll", StringComparison.OrdinalIgnoreCase) then
                    [ command; "--native-tool-child"; mode ]
                else
                    [ "--native-tool-child"; mode ]

            NativeToolLaunch.run
                { Executable = Environment.ProcessPath
                  Arguments = arguments
                  WorkingDirectory = area
                  Environment = [] }
                input
                limits
                token
            |> StorageWorker.wait

        let echoed =
            run "echo" (Encoding.UTF8.GetBytes "bounded standard streams") CancellationToken.None

        check
            "standardStreamsRoundTrip"
            (match echoed with
             | Ok result -> Encoding.UTF8.GetString result.Output = "bounded standard streams"
             | Error _ -> false)

        check
            "oversizedOutputTerminatesScope"
            (run "oversize" Array.empty CancellationToken.None = Error NativeToolError.OutputLimit)

        let crashed = run "crash" Array.empty CancellationToken.None

        check
            "helperCrashIsContained"
            (match crashed with
             | Ok result ->
                 result.ExitCode = 23
                 && Encoding.UTF8.GetString result.Error = "fixture helper failed"
                 && (Directory.EnumerateFiles(area, ".mc-tool-*") |> Seq.isEmpty)
             | Error _ -> false)

        let malformed = run "malformed" Array.empty CancellationToken.None

        check
            "malformedResponseIsRefused"
            (match malformed with
             | Error _ -> false
             | Ok result ->
                 try
                     LootJson.response result.Output |> ignore
                     false
                 with _ ->
                     Directory.EnumerateFiles(area, ".mc-tool-*") |> Seq.isEmpty)

        use cancelled = new CancellationTokenSource()
        cancelled.CancelAfter 100
        let stopped = run "wait" Array.empty cancelled.Token

        check
            "cancellationTerminatesDescendants"
            (stopped = Error NativeToolError.Cancelled
             && (Directory.EnumerateFiles(area, ".mc-tool-*") |> Seq.isEmpty))

        writer.WriteEndObject()
        writer.Flush()
