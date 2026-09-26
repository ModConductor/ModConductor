namespace ModConductor.Loot

open System
open System.Text
open System.Threading
open ModConductor.Platform

module internal HelperInvocation =
    let run
        (helperPath: string)
        (operation: string)
        (root: string)
        (game: string)
        (local: string)
        (metadata: LootMetadata)
        (plugins: string list)
        (fingerprint: string)
        (correlation: string)
        (token: CancellationToken)
        =
        async {
            let request =
                LootJson.request operation correlation root game local metadata plugins fingerprint

            let limits =
                { InputBytes = 4 * 1024 * 1024
                  OutputBytes = 4 * 1024 * 1024
                  ErrorBytes = 256 * 1024
                  Timeout = TimeSpan.FromSeconds 120.0 }

            let! result =
                NativeToolLaunch.run
                    { Executable = helperPath
                      Arguments = []
                      WorkingDirectory = root
                      Environment = [ "http_proxy", None; "https_proxy", None; "all_proxy", None ] }
                    request
                    limits
                    token
                |> Async.AwaitTask

            match result with
            | Error NativeToolError.Cancelled -> return Error LootError.Cancelled
            | Error NativeToolError.TimedOut ->
                return Error(LootError.HelperUnavailable "The LOOT helper timed out.")
            | Error NativeToolError.OutputLimit ->
                return Error(LootError.InvalidResponse "The LOOT helper output exceeded 4 MiB.")
            | Error NativeToolError.ErrorLimit ->
                return
                    Error(
                        LootError.HelperUnavailable "The LOOT helper diagnostic exceeded 256 KiB."
                    )
            | Error(NativeToolError.LaunchFailed detail) ->
                return Error(LootError.HelperUnavailable detail)
            | Ok result when result.ExitCode <> 0 ->
                let detail = Encoding.UTF8.GetString result.Error

                return
                    Error(
                        LootError.HelperUnavailable(
                            if String.IsNullOrWhiteSpace detail then
                                "The LOOT helper exited with code " + string result.ExitCode + "."
                            else
                                detail.Trim()
                        )
                    )
            | Ok result ->
                try
                    return Ok(LootJson.response result.Output)
                with error ->
                    return Error(LootError.InvalidResponse error.Message)
        }
