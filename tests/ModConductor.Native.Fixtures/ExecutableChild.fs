namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Diagnostics
open System.Threading
open System.Text.Json

module ExecutableChild =
    let invocation () =
        let executable = Environment.ProcessPath

        let prefix =
            if Path.GetFileNameWithoutExtension(executable) = "dotnet" then
                [ Environment.GetCommandLineArgs()[0] ]
            else
                []

        executable, prefix

    let waitFile path =
        let until = DateTime.UtcNow.AddSeconds 30.0

        while not (File.Exists path) && DateTime.UtcNow < until do
            Thread.Sleep 20

        if not (File.Exists path) then
            invalidOp ("The owned executable fixture did not reach " + path)

    let run (args: string array) =
        let area, role = args[0], args[1]
        let mark suffix = Path.Combine(area, role + suffix)

        let spawn role =
            let executable, prefix = invocation ()

            let info =
                ProcessStartInfo(executable, UseShellExecute = false, CreateNoWindow = true)

            for argument in prefix @ [ "--executable-child"; area; role ] do
                info.ArgumentList.Add argument

            Process.Start info

        File.WriteAllText(mark ".started", string Environment.ProcessId)

        match role with
        | "roundtrip" ->
            use stream = File.Create(mark ".json")
            use writer = new Utf8JsonWriter(stream)
            writer.WriteStartObject()
            writer.WriteString("directory", Environment.CurrentDirectory)
            writer.WriteStartArray("arguments")

            for value in args[2..] do
                writer.WriteStringValue value

            writer.WriteEndArray()

            for name in [ "MC024_SET"; "MC024_REMOVE"; "MC024_EMPTY" ] do
                writer.WriteString(name, Environment.GetEnvironmentVariable name)

                writer.WriteBoolean(
                    name + "_present",
                    Environment.GetEnvironmentVariables().Contains name
                )

            writer.WriteNumber("stdin", Console.OpenStandardInput().ReadByte())
            writer.WriteEndObject()
            writer.Flush()
            Console.WriteLine "owned child stdout"
            Console.Error.WriteLine "owned child stderr"
            File.AppendAllText(mark ".count", "1")
            0
        | "parent" ->
            use child = spawn "child"
            waitFile (Path.Combine(area, "child.started"))
            0
        | "child" ->
            waitFile (Path.Combine(area, "grandchild-now"))
            use grandchild = spawn "grandchild"

            if not (grandchild.WaitForExit 30000) then
                invalidOp "The owned grandchild did not finish."

            grandchild.ExitCode
        | "grandchild" ->
            waitFile (Path.Combine(area, "finish"))
            0
        | "waiter" ->
            waitFile (Path.Combine(area, "finish"))
            let input = Console.OpenStandardInput().ReadByte()
            Console.WriteLine "stdout after owner detach"
            Console.Error.WriteLine "stderr after owner detach"
            File.WriteAllText(mark ".finished", string input)
            0
        | _ -> invalidArg "role" "Unknown owned executable fixture role."
