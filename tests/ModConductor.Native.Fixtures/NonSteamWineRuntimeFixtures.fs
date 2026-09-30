namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.Platform

module NonSteamWineRuntimeFixtures =
    let observe (writer: Utf8JsonWriter) area executable prefix tool =
        Directory.CreateDirectory area |> ignore
        let game = Path.Combine(area, "source")
        let runnable = Path.Combine(area, "profile", "game")
        GameContextFixtures.create game 104
        Directory.CreateDirectory(Path.Combine(game, "Data")) |> ignore
        Directory.CreateDirectory(Path.Combine(runnable, "Data")) |> ignore
        File.Copy(tool, Path.Combine(game, "Data", "tool.exe"))
        File.Copy(tool, Path.Combine(runnable, "Data", "tool.exe"))
        File.WriteAllText(Path.Combine(game, "Data", "Marker.TXT"), "base")
        File.WriteAllText(Path.Combine(runnable, "Data", "Marker.TXT"), "profile")

        let evidence =
            InstallationValidation.inspect Skyrim.direct game
            |> fun game ->
                ModConductor.WineContexts.WineValidation.inspect
                    game
                    { Executable = executable
                      Prefix = prefix }

        let state =
            { WorkspaceId = Guid.NewGuid()
              ProfileId = Guid.NewGuid()
              Revision = 1L
              Binding =
                Some
                    { Id = Guid.NewGuid()
                      GameId = GameId.SkyrimSpecialEditionDirect
                      Path = game
                      Proton = None
                      Wine =
                        Some
                            { Executable = executable
                              Prefix = prefix }
                      Evidence = evidence
                      NeedsCheck = false
                      Failure = None } }

        let command =
            Descriptor.createToolWithHost
                false
                true
                state
                runnable
                None
                None
                (Guid.NewGuid())
                "Data/tool.exe"
                [ "/c"
                  "type Data\\Marker.TXT & echo %SteamAppId% & echo %STEAM_COMPAT_DATA_PATH%" ]
            |> StorageWorker.result

        let environment =
            command.Launch.Environment
            @ [ "WINEDEBUG", Some "-all"; "WINEDLLOVERRIDES", Some "mscoree,mshtml=" ]

        let run =
            NativeToolLaunch.runIn
                area
                { command.Launch with
                    Environment = environment }
                [||]
                { InputBytes = 1024
                  OutputBytes = 16384
                  ErrorBytes = 16384
                  Timeout = TimeSpan.FromSeconds 30. }
                CancellationToken.None
            |> StorageWorker.wait
            |> StorageWorker.result

        writer.WriteStartObject("wineRuntime")
        writer.WriteNumber("exitCode", run.ExitCode)
        let output = Encoding.UTF8.GetString run.Output
        writer.WriteString("output", output)

        writer.WriteBoolean(
            "actualWineReadsProjectedProfileRoot",
            run.ExitCode = 0 && output.Contains("profile") && not (output.Contains("base"))
        )

        writer.WriteBoolean("nativeScopeRecorded", run.Scope <> "")

        writer.WriteBoolean(
            "steamVariablesNotInherited",
            not (output.Contains("mc066-steam-sentinel"))
        )

        writer.WriteBoolean(
            "existingPrefixCheckedWithoutProton",
            evidence.Valid && evidence.Wine.IsSome && evidence.Proton.IsNone
        )


        use cancellation = new CancellationTokenSource()

        let waiting =
            { command.Launch with
                Arguments =
                    [ Path.Combine(runnable, "Data", "tool.exe")
                      "/c"
                      "ping -n 30 127.0.0.1 > nul" ]
                Environment = environment }

        let task =
            NativeToolLaunch.runIn
                area
                waiting
                [||]
                { InputBytes = 1024
                  OutputBytes = 16384
                  ErrorBytes = 16384
                  Timeout = TimeSpan.FromSeconds 30. }
                cancellation.Token

        let deadline = DateTime.UtcNow.AddSeconds 5.

        let active () =
            GameProcessObservation.read [ "tool.exe"; "ping.exe" ]
            |> List.exists (fun running ->
                running.Prefix = Some prefix
                && (running.ProcessName.Equals("tool.exe", StringComparison.OrdinalIgnoreCase)
                    || running.ProcessName.Equals("ping.exe", StringComparison.OrdinalIgnoreCase)))

        let mutable observed = active ()

        while not observed && DateTime.UtcNow < deadline do
            Thread.Sleep 20
            observed <- active ()

        cancellation.Cancel()
        let cancelled = task |> StorageWorker.wait

        writer.WriteBoolean(
            "cancelEndsOwnedWineCommand",
            observed && cancelled = Error NativeToolError.Cancelled && not (active ())
        )

        writer.WriteEndObject()
