namespace ModConductor.Native.Tests

open System
open System.Diagnostics
open System.IO
open System.Text.Json
open FsUnit
open NUnit.Framework

module NativeObservations =
    let mutable report: JsonDocument = null

[<SetUpFixture>]
type NativeObservationSetup() =
    let mutable primary = ""
    let mutable secondary = ""

    [<OneTimeSetUp>]
    member _.LoadNativeObservations() =
        let executable = Environment.GetEnvironmentVariable "MC_NATIVE_FIXTURE"

        if
            String.IsNullOrWhiteSpace executable
            || not (Path.IsPathFullyQualified executable)
        then
            invalidOp "Set MC_NATIVE_FIXTURE to the published native fixture executable."

        primary <-
            Path.Combine(
                Environment.CurrentDirectory,
                ".agent-workspace",
                "platform-fixtures-" + Guid.NewGuid().ToString("N")
            )

        Directory.CreateDirectory primary |> ignore

        let info =
            ProcessStartInfo(
                executable,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            )

        match Environment.GetEnvironmentVariable "MC_NATIVE_SCOPE" with
        | "executables" -> info.ArgumentList.Add "--executables"
        | "generated-outputs" -> info.ArgumentList.Add "--generated-outputs"
        | "deployment-backend" -> info.ArgumentList.Add "--deployment-backend"
        | "components" -> info.ArgumentList.Add "--components"
        | "skse" -> info.ArgumentList.Add "--skse"
        | "enb" -> info.ArgumentList.Add "--enb"
        | "fnis" -> info.ArgumentList.Add "--fnis"
        | "skyrim-setup" -> info.ArgumentList.Add "--skyrim-setup"
        | "generations" -> info.ArgumentList.Add "--generations"
        | "storage" -> info.ArgumentList.Add "--storage"
        | "deployment-recovery" -> info.ArgumentList.Add "--deployment-recovery"
        | "file-plans" -> info.ArgumentList.Add "--file-plans"
        | "proton-contexts" -> info.ArgumentList.Add "--proton-contexts"
        | "steam-discovery" -> info.ArgumentList.Add "--steam-discovery"
        | "game-contexts" -> info.ArgumentList.Add "--game-contexts"
        | "planner" -> info.ArgumentList.Add "--planner"
        | "organization" -> info.ArgumentList.Add "--organization"
        | "selection" -> info.ArgumentList.Add "--selection"
        | "migration" -> info.ArgumentList.Add "--migration"
        | null
        | "" -> ()
        | _ -> invalidOp "Unknown native fixture scope."

        info.ArgumentList.Add primary
        let secondParent = Environment.GetEnvironmentVariable "MC_SECOND_FIXTURE_ROOT"

        if not (String.IsNullOrWhiteSpace secondParent) then
            if not (Path.IsPathFullyQualified secondParent) then
                invalidOp "The second fixture root must be absolute."

            secondary <- Path.Combine(secondParent, "mc-platform-" + Guid.NewGuid().ToString("N"))
            Directory.CreateDirectory secondary |> ignore
            info.ArgumentList.Add secondary

        use child = Process.Start info

        let output, errors =
            child.StandardOutput.ReadToEndAsync(), child.StandardError.ReadToEndAsync()

        if not (child.WaitForExit 120000) then
            child.Kill(true)
            invalidOp "The native fixture timed out."

        let text = output.GetAwaiter().GetResult()

        if child.ExitCode <> 0 then
            invalidOp (errors.GetAwaiter().GetResult() + Environment.NewLine + text)

        let evidence = Environment.GetEnvironmentVariable "MC_NATIVE_REPORT"

        if not (String.IsNullOrWhiteSpace evidence) then
            File.WriteAllText(evidence, text)

        NativeObservations.report <- JsonDocument.Parse text

    [<OneTimeTearDown>]
    member _.RemoveOwnedFixtures() =
        if not (isNull NativeObservations.report) then
            NativeObservations.report.Dispose()

        for path in [ primary; secondary ] do
            if path <> "" && Directory.Exists path then
                let info =
                    ProcessStartInfo(
                        Environment.GetEnvironmentVariable "MC_NATIVE_FIXTURE",
                        UseShellExecute = false
                    )

                info.ArgumentList.Add "--normalize-owned-fixture"
                info.ArgumentList.Add path
                use child = Process.Start info
                child.WaitForExit()

                if child.ExitCode <> 0 then
                    invalidOp "The native fixture could not restore its test directory permissions."

                Directory.Delete(path, true)
