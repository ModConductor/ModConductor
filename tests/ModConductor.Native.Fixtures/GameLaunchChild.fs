namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Runtime.InteropServices
open System.Security.Cryptography
open System.Text.Json

module GameLaunchChild =
    [<DllImport("libc", EntryPoint = "prctl", SetLastError = true)>]
    extern int private name(int option, string value, nativeint a, nativeint b, nativeint c)

    let run (args: string array) =
        let directory = args[0]
        let target = Path.Combine(Path.GetDirectoryName args[1], "Data", "Marker.TXT")

        if args.Length > 2 && OperatingSystem.IsLinux() then
            name (15, "Main", 0n, 0n, 0n) |> ignore

        use input = File.OpenRead target
        let hash = SHA256.HashData input |> Convert.ToHexStringLower
        input.Position <- 0L
        use text = new StreamReader(input)
        let content = text.ReadToEnd()

        do
            use output = File.Create(Path.Combine(directory, "read.json"))
            use writer = new Utf8JsonWriter(output)
            writer.WriteStartObject()
            writer.WriteString("sha256", hash)
            writer.WriteString("content", content)
            writer.WriteString("cwd", Environment.CurrentDirectory)
            writer.WriteString("appId", Environment.GetEnvironmentVariable "SteamAppId")
            writer.WriteNumber("pid", Environment.ProcessId)
            writer.WriteEndObject()
            writer.Flush()

        File.AppendAllText(Path.Combine(directory, "count"), "1")
        ExecutableChild.waitFile (Path.Combine(directory, "finish"))
        0

    let wine directory =
        if name (15, "Main", 0n, 0n, 0n) <> 0 then
            invalidOp "The owned thread name could not be set."

        File.WriteAllText(Path.Combine(directory, "ready"), "ready")
        ExecutableChild.waitFile (Path.Combine(directory, "finish"))
        0
