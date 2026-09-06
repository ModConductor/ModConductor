namespace ModConductor.Native.Fixtures

open System
open System.Diagnostics
open System.Threading.Tasks

type NativeChild(executable, arguments: string list) =
    let info =
        ProcessStartInfo(
            executable,
            UseShellExecute = false,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        )

    do
        for value in arguments do
            info.ArgumentList.Add value

    let child = Process.Start info
    let errors = child.StandardError.ReadToEndAsync()

    member _.Line() =
        let line =
            child.StandardOutput
                .ReadLineAsync()
                .WaitAsync(TimeSpan.FromSeconds 15.0)
                .GetAwaiter()
                .GetResult()

        if isNull line then
            invalidOp (errors.GetAwaiter().GetResult())

        line

    member _.Send(value: string) =
        child.StandardInput.WriteLine value
        child.StandardInput.Flush()

    member _.Finish() =
        if not (child.WaitForExit 15000) then
            invalidOp "The native child did not stop."

        if child.ExitCode <> 0 then
            invalidOp (errors.GetAwaiter().GetResult())

    member _.Terminate() =
        child.Kill(true)

        if not (child.WaitForExit 15000) then
            invalidOp "The owned native child did not stop."

    interface IDisposable with
        member _.Dispose() =
            if not child.HasExited then
                child.Kill(true)

                if not (child.WaitForExit 15000) then
                    invalidOp "The owned native child did not stop."

            child.Dispose()
