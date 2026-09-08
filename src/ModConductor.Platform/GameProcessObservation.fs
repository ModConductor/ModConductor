namespace ModConductor.Platform

open System
open System.IO
open System.Diagnostics
open System.ComponentModel
open System.Text

/// Only candidate executable arguments and the prefix locator are returned; other environment values are discarded.
type GameProcessObservation =
    { ProcessId: int
      ProcessName: string
      Executable: string option
      Arguments: string list
      Prefix: string option
      Incomplete: bool }

module GameProcessObservation =
    let private fields path =
        use stream = File.OpenRead path
        let buffer = Array.zeroCreate<byte> (128 * 1024)
        let count = stream.ReadAtLeast(buffer, buffer.Length, false)

        if count = buffer.Length && stream.ReadByte() <> -1 then
            raise (IOException "The candidate process metadata exceeds the read limit.")

        Encoding.UTF8
            .GetString(buffer, 0, count)
            .Split('\000', StringSplitOptions.RemoveEmptyEntries)

    let read (names: string list) =
        let candidate (name: string) =
            names
            |> List.exists (fun expected ->
                name.Equals(expected, StringComparison.OrdinalIgnoreCase)
                || name.Equals(
                    Path.GetFileNameWithoutExtension expected,
                    StringComparison.OrdinalIgnoreCase
                )
                || name.Equals(
                    expected.Substring(0, min 15 expected.Length),
                    StringComparison.OrdinalIgnoreCase
                ))
            || (OperatingSystem.IsLinux()
                && name.StartsWith("wine", StringComparison.OrdinalIgnoreCase))

        Process.GetProcesses()
        |> Array.choose (fun running ->
            use running = running

            try
                let name = running.ProcessName

                if not (candidate name) then
                    None
                else
                    let mutable record =
                        { ProcessId = running.Id
                          ProcessName = name
                          Executable = None
                          Arguments = []
                          Prefix = None
                          Incomplete = false }

                    try
                        record <-
                            { record with
                                Executable =
                                    running.MainModule |> Option.ofObj |> Option.map _.FileName }

                        if OperatingSystem.IsLinux() then
                            let root = "/proc/" + string running.Id

                            record <-
                                { record with
                                    Arguments = fields (root + "/cmdline") |> Array.toList }

                            let prefix =
                                fields (root + "/environ")
                                |> Array.tryPick (fun field ->
                                    if
                                        field.StartsWith("WINEPREFIX=", StringComparison.Ordinal)
                                    then
                                        Some(field.Substring 11)
                                    else
                                        None)

                            record <- { record with Prefix = prefix }

                        if running.HasExited then None else Some record
                    with
                    | :? IOException
                    | :? UnauthorizedAccessException
                    | :? Win32Exception ->
                        let exited =
                            try
                                running.HasExited
                            with
                            | :? InvalidOperationException -> true
                            | :? Win32Exception -> false

                        if exited then
                            None
                        else
                            Some { record with Incomplete = true }
            with
            | :? InvalidOperationException
            | :? Win32Exception -> None)
        |> Array.toList
