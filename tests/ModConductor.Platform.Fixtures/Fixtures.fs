namespace ModConductor.Platform.Fixtures

open System
open System.Diagnostics
open System.IO
open System.Text.Json
open ModConductor.Platform

module Fixtures =
    let private limits =
        { Candidates = 1000
          Depth = 32
          Diagnostics = 1000 }

    let private host path =
        HostPath.create path |> Result.defaultWith invalidOp

    let private select path =
        RootSelection.select (host path)
        |> Result.defaultWith (Report.problem >> invalidOp)

    let private scan policy path =
        PathPreflight.inspect limits policy (select path)

    let private runTool executable arguments =
        let info =
            ProcessStartInfo(
                executable,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            )

        for argument in arguments do
            info.ArgumentList.Add argument

        use child = Process.Start info

        let output, errors =
            child.StandardOutput.ReadToEndAsync(), child.StandardError.ReadToEndAsync()

        if not (child.WaitForExit 10000) then
            child.Kill(true)
            invalidOp "Fixture creation timed out."

        if child.ExitCode <> 0 then
            invalidOp (errors.GetAwaiter().GetResult() + output.GetAwaiter().GetResult())

    let private createDirectoryLink path target =
        if OperatingSystem.IsWindows() then
            runTool "cmd.exe" [ "/d"; "/c"; "mklink"; "/J"; path; target ]
        else
            Directory.CreateSymbolicLink(path, target) |> ignore

    let private hardLink source target =
        if OperatingSystem.IsWindows() then
            runTool "cmd.exe" [ "/d"; "/c"; "mklink"; "/H"; target; source ]
        else
            runTool "ln" [ source; target ]

    let observe (writer: Utf8JsonWriter) primary secondary =
        let links = ResizeArray<string>()

        let directoryLink path target =
            createDirectoryLink path target
            links.Add path

        try
            let root = Path.Combine(primary, "fixture")
            Directory.CreateDirectory root |> ignore

            let folder name =
                let path = Path.Combine(root, name) in
                Directory.CreateDirectory path |> ignore
                path

            let file directory name =
                let path = Path.Combine(directory, name) in
                File.WriteAllText(path, "owned fixture")
                path

            let names = folder "names"
            file names "Caf\u00e9.txt" |> ignore
            file names "Cafe\u0301.txt" |> ignore
            file names "MixedCase.txt" |> ignore
            file names "日本語.txt" |> ignore

            if OperatingSystem.IsLinux() then
                file names "mixedcase.txt" |> ignore
                file names "native\\backslash" |> ignore
                file names "NUL.txt" |> ignore
                file names "trailing." |> ignore
                file names "colon:name" |> ignore
                file names "Conflict" |> ignore

                file
                    (Path.Combine(names, "conflict")
                     |> Directory.CreateDirectory
                     |> fun d -> d.FullName)
                    "child"
                |> ignore

            Report.preflight writer "sourceNames" (scan TargetPolicy.linux names)
            Report.preflight writer "windowsNames" (scan TargetPolicy.windows names)

            Report.preflight
                writer
                "normalizedNames"
                (scan
                    { TargetPolicy.linux with
                        Unicode = CanonicalComposition }
                    names)

            let inside = folder "inside"
            let content = Directory.CreateDirectory(Path.Combine(inside, "content")).FullName
            let original = file content "file"
            hardLink original (Path.Combine(content, "hard"))
            directoryLink (Path.Combine(inside, "alias")) content
            let selectedLink = Path.Combine(root, "selected-link")
            directoryLink selectedLink inside

            directoryLink
                (Path.Combine(inside, "selected-alias"))
                (Path.Combine(selectedLink, "content"))

            Report.preflight writer "inside" (scan TargetPolicy.linux selectedLink)
            writer.WriteString("actualSelectedTarget", inside)

            let outside = folder "outside"
            file outside "must-not-enumerate" |> ignore
            let escape = Path.Combine(inside, "escape")
            directoryLink escape outside
            directoryLink (Path.Combine(inside, "chain-escape")) escape
            directoryLink (Path.Combine(inside, "cycle")) inside
            let selfCycle = Path.Combine(inside, "self-cycle")
            directoryLink selfCycle selfCycle
            Report.preflight writer "blockedLinks" (scan TargetPolicy.linux inside)

            let bounded =
                PathPreflight.inspect
                    { Candidates = 2
                      Depth = 8
                      Diagnostics = 2 }
                    TargetPolicy.linux
                    (select inside)

            Report.preflight writer "bounded" bounded

            if OperatingSystem.IsLinux() then
                let failed = folder "failed-candidates"

                for i in 1..8 do
                    Directory.CreateSymbolicLink(Path.Combine(failed, i.ToString()), outside)
                    |> ignore

                Report.preflight
                    writer
                    "failedBudget"
                    (PathPreflight.inspect
                        { Candidates = 3
                          Depth = 8
                          Diagnostics = 3 }
                        TargetPolicy.linux
                        (select failed))

                let special = folder "special"
                runTool "mkfifo" [ Path.Combine(special, "pipe") ]
                Report.preflight writer "special" (scan TargetPolicy.linux special)

            let active = folder "active"
            let selectedActive = select active
            Report.capabilities writer "passive" (CapabilityProbe.passive selectedActive)
            writer.WriteNumber("entriesAfterPassive", Directory.GetFileSystemEntries(active).Length)
            Report.capabilities writer "active" (CapabilityProbe.probeOwnedFixture selectedActive)
            writer.WriteNumber("entriesAfterActive", Directory.GetFileSystemEntries(active).Length)

            if OperatingSystem.IsLinux() then
                File.SetUnixFileMode(active, UnixFileMode.UserRead ||| UnixFileMode.UserExecute)

                try
                    Report.capabilities
                        writer
                        "readOnly"
                        (CapabilityProbe.probeOwnedFixture selectedActive)
                finally
                    File.SetUnixFileMode(
                        active,
                        UnixFileMode.UserRead
                        ||| UnixFileMode.UserWrite
                        ||| UnixFileMode.UserExecute
                    )

            let source, same = select (folder "pair-source"), select (folder "pair-same")

            let writePair name (result: PairCapabilities) =
                writer.WriteStartObject(name: string)

                writer.WriteString(
                    "devices",
                    match result.Devices with
                    | SameDevice -> "same"
                    | DifferentDevices -> "different"
                    | UnknownDevices -> "unknown"
                )

                Report.outcome writer "hardLink" result.HardLink
                writer.WriteEndObject()

            writePair "samePair" (CapabilityProbe.probeOwnedPair source same)

            match secondary with
            | Some parent ->
                let target =
                    Directory.CreateDirectory(Path.Combine(parent, "fixture")).FullName |> select

                writePair "crossPair" (CapabilityProbe.probeOwnedPair source target)
                writer.WriteStartObject("secondRoot")
                writer.WriteString("path", RootSelection.path target |> HostPath.value)
                Report.identity writer (RootSelection.facts target)
                writer.WriteEndObject()
            | None -> writer.WriteNull("crossPair")
        finally
            for link in Seq.rev links do
                if OperatingSystem.IsWindows() then
                    runTool "cmd.exe" [ "/d"; "/c"; "rmdir"; link ]
                else
                    File.Delete link
