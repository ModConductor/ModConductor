namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.Deployment

module GameLaunchProcessFixture =
    let observe (writer: Utf8JsonWriter) primary (evidence: InstallationEvidence) =
        let _, arguments = ExecutableChild.invocation ()

        if not arguments.IsEmpty then
            writer.WriteString("renamedWineCheck", "Not run by managed diagnostic")
        else
            let area = Directory.CreateDirectory(Path.Combine(primary, "renamed-wine")).FullName
            let executable = Path.Combine(area, "wine64-preloader")
            File.Copy(Environment.ProcessPath, executable, false)
            let proton = evidence.Proton.Value

            let library =
                match proton.Selection.Association with
                | ProtonAssociation.Steam(_, path) -> path
                | _ -> invalidOp "No fixture library"

            Directory.CreateSymbolicLink(
                Path.Combine(proton.PrefixPath, "dosdevices", "s:"),
                library
            )
            |> ignore

            let argument =
                "S:\\"
                + Path.GetRelativePath(library, evidence.Executable.Value.Path).Replace('/', '\\')

            use child =
                NativeProcessLaunch.start
                    { Executable = executable
                      Arguments = [ "--wine-check"; area; argument ]
                      WorkingDirectory = area
                      Environment = [ "WINEPREFIX", Some proton.PrefixPath ] }

            try
                ExecutableChild.waitFile (Path.Combine(area, "ready"))
                let observed = GameProcessObservation.read [ "SkyrimSE.exe" ]

                let renamed =
                    observed
                    |> List.exists (fun value ->
                        value.ProcessId = child.ProcessId && value.ProcessName = "Main")

                let refused =
                    try
                        GameProcesses.check evidence
                        false
                    with :? IOException ->
                        true

                writer.WriteBoolean("renamedWineProcessAndSDriveRefused", renamed && refused)

                if not renamed || not refused then
                    invalidOp "The renamed selected Wine child was not refused."

                GameProcesses.check
                    { evidence with
                        Proton =
                            Some
                                { proton with
                                    PrefixPath = Path.Combine(area, "other-prefix") } }

                writer.WriteBoolean("unrelatedWinePrefixAllowed", true)
            finally
                File.WriteAllText(Path.Combine(area, "finish"), "finish")

                if not (child.RootExit.Wait(TimeSpan.FromSeconds 10.)) then
                    invalidOp "The owned Wine matcher did not exit."
