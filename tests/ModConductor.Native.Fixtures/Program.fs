module ModConductor.Native.Fixtures.Program

open System
open System.IO
open System.Runtime.CompilerServices
open System.Text.Json
open ModConductor.Native.Fixtures

[<EntryPoint>]
let main args =
    try
        if args.Length = 2 && args[0] = "--game-files" && Path.IsPathFullyQualified args[1] then
            GameContextFixtures.create args[1] 104
            0
        elif args.Length = 5 && args[0] = "--storage-worker" then
            StorageWorker.run args[1] args[2] args[3] args[4]
            0
        elif args.Length = 5 && args[0] = "--workspace-worker" then
            WorkspaceWorker.run args[1] args[2] args[3] args[4]
            0
        elif args.Length = 5 && args[0] = "--library-worker" then
            LibraryWorker.run args[1] args[2] args[3] args[4]
            0
        elif args.Length = 5 && args[0] = "--selection-worker" then
            SelectionFixtures.worker args[1] args[2] args[3] args[4]
            0
        else
            let contextsOnly = args.Length = 2 && args[0] = "--game-contexts"
            let plannerOnly = args.Length = 2 && args[0] = "--planner"
            let organizationOnly = args.Length = 2 && args[0] = "--organization"
            let selectionOnly = args.Length = 2 && args[0] = "--selection"

            let primary, secondary =
                match args with
                | [| "--game-contexts"; primary |]
                | [| "--planner"; primary |]
                | [| "--organization"; primary |]
                | [| "--selection"; primary |] when Path.IsPathFullyQualified primary ->
                    primary, None
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

            if not selectionOnly && not organizationOnly && not plannerOnly && not contextsOnly then
                Fixtures.observe writer primary secondary
                StorageFixtures.observe writer primary
                WorkspaceFixtures.observe writer primary
                LibraryFixtures.observe writer primary
                LibraryRecoveryFixtures.observe writer primary
                LibraryIdentityFixtures.observe writer primary

            if not organizationOnly && not plannerOnly && not contextsOnly then
                SelectionFixtures.observe writer primary

            if not selectionOnly && not plannerOnly && not contextsOnly then
                OrganizationFixtures.observe writer primary
                OrganizationMigration.observe writer primary

            if not selectionOnly && not organizationOnly && not contextsOnly then
                PlanningFixtures.observe writer

            if contextsOnly then
                GameContextFixtures.observe writer primary

            writer.WriteEndObject()
            writer.Flush()
            0
    with error ->
        Console.Error.WriteLine(error.Message)
        1
