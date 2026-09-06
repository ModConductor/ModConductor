module ModConductor.Native.Fixtures.Program

open System
open System.IO
open System.Runtime.CompilerServices
open System.Text.Json
open ModConductor.Native.Fixtures

[<EntryPoint>]
let main args =
    try
        if args.Length = 5 && args[0] = "--storage-worker" then
            StorageWorker.run args[1] args[2] args[3] args[4]
            0
        elif args.Length = 5 && args[0] = "--workspace-worker" then
            WorkspaceWorker.run args[1] args[2] args[3] args[4]
            0
        elif args.Length = 5 && args[0] = "--library-worker" then
            LibraryWorker.run args[1] args[2] args[3] args[4]
            0
        else
            let primary, secondary =
                match args with
                | [| primary |] when Path.IsPathFullyQualified primary -> primary, None
                | [| primary; secondary |] when
                    Path.IsPathFullyQualified primary && Path.IsPathFullyQualified secondary
                    ->
                    primary, Some secondary
                | _ -> invalidArg "args" "Supply owned absolute fixture directories."

            use output = Console.OpenStandardOutput()
            use writer = new Utf8JsonWriter(output, JsonWriterOptions(Indented = true))
            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)

            writer.WriteString(
                "os",
                if OperatingSystem.IsLinux() then "linux"
                elif OperatingSystem.IsWindows() then "windows"
                else "other"
            )

            Fixtures.observe writer primary secondary
            StorageFixtures.observe writer primary
            WorkspaceFixtures.observe writer primary
            LibraryFixtures.observe writer primary
            LibraryRecoveryFixtures.observe writer primary
            LibraryIdentityFixtures.observe writer primary
            writer.WriteEndObject()
            writer.Flush()
            0
    with error ->
        Console.Error.WriteLine(error.Message)
        1
