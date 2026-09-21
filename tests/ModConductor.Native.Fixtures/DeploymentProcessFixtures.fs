namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Diagnostics
open System.Runtime.CompilerServices
open System.Text.Json
open ModConductor.GameContexts
open ModConductor.Platform
open System.Security.Cryptography
open ModConductor.Deployment

module DeploymentProcessFixtures =
    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject("deploymentProcesses")

        if RuntimeFeature.IsDynamicCodeSupported then
            writer.WriteString(
                "status",
                "Managed diagnostic: native executable process check not run"
            )
        else
            let area =
                Directory.CreateDirectory(Path.Combine(primary, "process-observation")).FullName

            let game = Path.Combine(area, "SkyrimSE.exe")
            File.Copy(Environment.ProcessPath, game, false)
            let other = Directory.CreateDirectory(Path.Combine(area, "other")).FullName
            let otherGame = Path.Combine(other, "SkyrimSE.exe")
            File.Copy(Environment.ProcessPath, otherGame, false)
            let context = InstallationValidation.inspect Skyrim.definition area

            let executable (path: string) =
                let location = DeploymentFixtureData.location (Path.GetDirectoryName path)
                use parent = HeldDirectory.Open(location.Path, location.Identity)
                let stream, identity = parent.Read(Path.GetFileName path, None)
                use stream = stream

                { Path = path
                  Identity = identity
                  Length = stream.Length
                  Sha256 = Convert.ToHexStringLower(SHA256.HashData stream)
                  FileVersion = "process matcher fixture"
                  ProductVersion = "process matcher fixture" }

            let evidence =
                { context with
                    Executable = Some(executable game)
                    LauncherPath = None }

            let info =
                ProcessStartInfo(
                    game,
                    UseShellExecute = false,
                    RedirectStandardInput = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                )

            info.ArgumentList.Add "--generation-game"
            use child = Process.Start info

            try
                let ready = child.StandardOutput.ReadLineAsync()

                if not (ready.Wait(TimeSpan.FromSeconds 10.)) || ready.Result <> "ready" then
                    invalidOp "The owned executable did not reach its readiness boundary."

                let refused =
                    try
                        GameProcesses.check evidence
                        false
                    with :? IOException ->
                        true

                writer.WriteBoolean("matchingNativeProcessRefused", refused)

                GameProcesses.check
                    { evidence with
                        Executable = Some(executable otherGame) }

                writer.WriteBoolean("unrelatedSameNameAllowed", true)
                child.StandardInput.WriteLine()

                if not (child.WaitForExit 10000) then
                    invalidOp "The owned executable did not stop."

                GameProcesses.check evidence
                writer.WriteBoolean("stoppedNativeProcessAllowed", child.ExitCode = 0)
            finally
                if not child.HasExited then
                    child.Kill()
                    child.WaitForExit()

        writer.WriteEndObject()
