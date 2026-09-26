namespace ModConductor.Loot

open System
open System.IO
open System.Text
open System.Threading
open ModConductor.Platform

module internal HelperAvailability =
    let check (path: string) (stateDirectory: string) =
        if not (File.Exists path) then
            Error "The helper executable is missing."
        else
            try
                let limits =
                    { InputBytes = 1
                      OutputBytes = 4096
                      ErrorBytes = 4096
                      Timeout = TimeSpan.FromSeconds 5.0 }

                let result =
                    NativeToolLaunch.run
                        { Executable = path
                          Arguments = [ "--identity" ]
                          WorkingDirectory = stateDirectory
                          Environment = [] }
                        Array.empty
                        limits
                        CancellationToken.None
                    |> _.GetAwaiter().GetResult()

                match result with
                | Error error ->
                    let detail =
                        match error with
                        | NativeToolError.Cancelled -> "The check was canceled."
                        | NativeToolError.TimedOut -> "The check timed out."
                        | NativeToolError.OutputLimit -> "The identity output exceeded 4 KiB."
                        | NativeToolError.ErrorLimit -> "The identity diagnostic exceeded 4 KiB."
                        | NativeToolError.LaunchFailed detail -> detail

                    Error("The helper identity check failed: " + detail)
                | Ok output when output.ExitCode <> 0 ->
                    Error(
                        "The helper identity check exited with code "
                        + string output.ExitCode
                        + ": "
                        + Encoding.UTF8.GetString(output.Error).Trim()
                    )
                | Ok output ->
                    let identity = LootJson.response output.Output

                    if
                        identity.Capability = "skyrim-se-steam"
                        && identity.HelperRevision = "0.1.0"
                        && identity.LiblootVersion = "0.29.6"
                        && identity.LiblootRevision = "136f3983"
                    then
                        Ok()
                    else
                        Error(
                            "Expected helper 0.1.0, libloot 0.29.6 at 136f3983 and Skyrim SE protocol 1; found helper "
                            + identity.HelperRevision
                            + ", libloot "
                            + identity.LiblootVersion
                            + " at "
                            + identity.LiblootRevision
                            + ", capability "
                            + identity.Capability
                            + "."
                        )
            with error ->
                Error("The helper identity check failed: " + error.Message)
