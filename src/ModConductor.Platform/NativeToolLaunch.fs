namespace ModConductor.Platform

open System
open System.Diagnostics
open System.IO
open System.Threading
open System.Threading.Tasks

module NativeToolLaunch =
    let private length path =
        try
            FileInfo(path).Length
        with :? FileNotFoundException ->
            0L

    let private read path limit =
        let bytes = File.ReadAllBytes path

        if bytes.Length > limit then
            raise (InvalidDataException "The native tool output exceeds its read limit.")

        bytes

    let runIn streamDirectory (request: NativeLaunch) (input: byte array) limits (token: CancellationToken) =
        task {
            if input.Length > limits.InputBytes then
                invalidArg "input" "The native tool input exceeds its write limit."

            if
                limits.InputBytes <= 0
                || limits.OutputBytes <= 0
                || limits.ErrorBytes <= 0
                || limits.Timeout <= TimeSpan.Zero
            then
                invalidArg "limits" "Native tool limits must be positive."

            let id = ".mc-tool-" + Guid.NewGuid().ToString("N")

            let files =
                { Input = Path.Combine(streamDirectory, id + ".in")
                  Output = Path.Combine(streamDirectory, id + ".out")
                  Error = Path.Combine(streamDirectory, id + ".err") }

            let cleanup () =
                for path in [ files.Input; files.Output; files.Error ] do
                    try
                        File.Delete path
                    with
                    | :? IOException
                    | :? UnauthorizedAccessException -> ()

            try
                File.WriteAllBytes(files.Input, input)
                File.WriteAllBytes(files.Output, Array.empty)
                File.WriteAllBytes(files.Error, Array.empty)

                let launched =
                    try
                        if OperatingSystem.IsWindows() then
                            Ok(WindowsChildProcess.startWithStreams (Some files) request)
                        elif OperatingSystem.IsLinux() then
                            Ok(LinuxChildProcess.startWithStreams (Some files) request)
                        else
                            Error(
                                NativeToolError.LaunchFailed
                                    "Native tool launch is unavailable on this platform."
                            )
                    with error ->
                        Error(NativeToolError.LaunchFailed error.Message)

                match launched with
                | Error error -> return Error error
                | Ok run ->
                    use run = run
                    let timer = Stopwatch.StartNew()
                    let mutable failure: NativeToolError option = None
                    let mutable ended = false

                    while not ended && failure.IsNone do
                        if token.IsCancellationRequested then
                            failure <- Some NativeToolError.Cancelled
                        elif timer.Elapsed >= limits.Timeout then
                            failure <- Some NativeToolError.TimedOut
                        elif length files.Output > int64 limits.OutputBytes then
                            failure <- Some NativeToolError.OutputLimit
                        elif length files.Error > int64 limits.ErrorBytes then
                            failure <- Some NativeToolError.ErrorLimit
                        else
                            ended <- run.Observe().ScopeEnded

                        if not ended && failure.IsNone then
                            do! Task.Delay 20

                    if failure.IsSome then
                        run.TerminateScope()

                    let reap = Stopwatch.StartNew()

                    while (not (run.Observe().ScopeEnded)
                           && reap.Elapsed < TimeSpan.FromSeconds 10.0) do
                        do! Task.Delay 20

                    if not (run.Observe().ScopeEnded) then
                        return
                            Error(NativeToolError.LaunchFailed "The native tool scope did not end.")
                    else
                        let! code = run.RootExit

                        match failure with
                        | Some error -> return Error error
                        | None when length files.Output > int64 limits.OutputBytes ->
                            return Error NativeToolError.OutputLimit
                        | None when length files.Error > int64 limits.ErrorBytes ->
                            return Error NativeToolError.ErrorLimit
                        | None ->
                            return
                                Ok
                                    { ExitCode = code
                                      Output = read files.Output limits.OutputBytes
                                      Error = read files.Error limits.ErrorBytes
                                      Scope = run.Scope }
            finally
                cleanup ()
        }

    let run request input limits token =
        runIn request.WorkingDirectory request input limits token
