module ModConductor.Native.Fixtures.Program

open System
open System.IO
open System.Runtime.CompilerServices
open System.Text.Json
open ModConductor.Native.Fixtures

[<EntryPoint>]
let main args =
    try
        if
            args.Length = 2
            && args[0] = "--inspection-files"
            && Path.IsPathFullyQualified args[1]
        then
            ArchiveInspectionFixtures.create args[1]
            0
        elif
            args.Length = 2
            && args[0] = "--archive-inspection"
            && Path.IsPathFullyQualified args[1]
        then
            use writer =
                new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            ArchiveInspectionFixtures.observe writer args[1]
            writer.WriteEndObject()
            writer.Flush()
            0
        elif args.Length = 8 && args[0] = "--maintenance-worker" then
            MaintenanceRecoveryFixtures.worker
                args[1]
                args[2]
                args[3]
                args[4]
                args[5]
                args[6]
                args[7]

            0
        elif args.Length = 2 && args[0] = "--mod-maintenance" then
            use output = Console.OpenStandardOutput()
            use writer = new Utf8JsonWriter(output, JsonWriterOptions(Indented = true))
            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            MaintenanceFixtures.observe writer (Path.Combine(args[1], "effects"))
            MaintenanceRecoveryFixtures.observe writer (Path.Combine(args[1], "restart"))
            writer.WriteEndObject()
            writer.Flush()
            0
        elif args.Length = 6 && args[0] = "--installation-worker" then
            InstallationFixtures.worker args[1] args[2] args[3] args[4] args[5]
            0
        elif
            args.Length = 2
            && args[0] = "--installation-files"
            && Path.IsPathFullyQualified args[1]
        then
            InstallationFixtures.create args[1]
            0
        elif
            args.Length = 2
            && args[0] = "--archive-installation"
            && Path.IsPathFullyQualified args[1]
        then
            use writer =
                new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            InstallationFixtures.observe writer args[1]
            writer.WriteEndObject()
            writer.Flush()
            0
        elif args.Length = 6 && args[0] = "--download-worker" then
            DownloadFixtures.worker args[1] args[2] args[3] args[4] args[5]
            0
        elif args.Length = 1 && args[0] = "--download-server" then
            use server = new DownloadServer()

            Console.WriteLine(
                server.Url + " " + server.Checksum + " " + server.Payload.Length.ToString()
            )

            Console.Out.Flush()
            Console.ReadLine() |> ignore
            0
        elif args.Length = 2 && args[0] = "--downloads" && Path.IsPathFullyQualified args[1] then
            use writer =
                new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            DownloadFixtures.observe writer args[1]
            writer.WriteEndObject()
            writer.Flush()
            0
        elif args.Length = 6 && args[0] = "--artifact-worker" then
            ArtifactFixtures.worker args[1] args[2] args[3] args[4] args[5]
            0
        elif args.Length = 2 && args[0] = "--artifacts" && Path.IsPathFullyQualified args[1] then
            use writer =
                new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            ArtifactFixtures.observe writer args[1]
            writer.WriteEndObject()
            writer.Flush()
            0
        elif
            args.Length = 2
            && args[0] = "--profile-data"
            && Path.IsPathFullyQualified args[1]
        then
            use writer =
                new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            ProfileDataFixtures.observe writer args[1]
            writer.WriteEndObject()
            writer.Flush()
            0
        elif args.Length = 3 && args[0] = "--wine-check" then
            GameLaunchChild.wine args[1]
        elif args.Length >= 3 && args[0] = "--game-load" then
            GameLaunchChild.run args[1..]
        elif
            args.Length = 2
            && args[0] = "--game-launch"
            && Path.IsPathFullyQualified args[1]
        then
            use writer =
                new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            GameLaunchFixtures.observe writer args[1]
            writer.WriteEndObject()
            writer.Flush()
            0
        elif args.Length >= 3 && args[0] = "--executable-child" then
            ExecutableChild.run args[1..]
        elif
            args.Length = 2
            && args[0] = "--executables"
            && Path.IsPathFullyQualified args[1]
        then
            use writer =
                new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            ExecutableFixtures.observe writer args[1]
            writer.WriteEndObject()
            writer.Flush()
            0
        elif args.Length = 1 && args[0] = "--generation-game" then
            Console.WriteLine "ready"
            Console.ReadLine() |> ignore
            0
        elif
            args.Length = 2
            && args[0] = "--normalize-owned-fixture"
            && Path.IsPathFullyQualified args[1]
        then
            GenerationCleanup.normalize args[1]
            0
        elif
            args.Length = 2
            && args[0] = "--generated-outputs"
            && Path.IsPathFullyQualified args[1]
        then
            use writer =
                new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            GeneratedOutputFixtures.observe writer args[1]
            writer.WriteEndObject()
            writer.Flush()
            0
        elif
            args.Length = 6
            && args[0] = "--deployment-live"
            && Path.IsPathFullyQualified args[1]
            && Path.IsPathFullyQualified args[2]
        then
            DeploymentLiveFixture.run args[1] args[2] args[3] args[4] args[5]
            0
        elif
            args.Length = 2
            && args[0] = "--deployment-backend"
            && Path.IsPathFullyQualified args[1]
        then
            use writer =
                new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            DeploymentBackendFixtures.observe writer args[1]
            DeploymentProcessFixtures.observe writer args[1]
            writer.WriteEndObject()
            writer.Flush()
            0
        elif
            args.Length = 3
            && args[0] = "--generation-legacy"
            && Path.IsPathFullyQualified args[1]
        then
            GenerationFixtures.legacy args[1] args[2]
            0
        elif
            args.Length = 2
            && args[0] = "--generations"
            && Path.IsPathFullyQualified args[1]
        then
            use writer =
                new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

            writer.WriteStartObject()
            writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)
            GenerationFixtures.observe writer args[1]
            GenerationCorrectionFixtures.observe writer args[1]
            writer.WriteEndObject()
            writer.Flush()
            0
        elif
            args.Length = 2
            && args[0] = "--deployment-recovery"
            && Path.IsPathFullyQualified args[1]
        then
            DeploymentFixtures.run args[1]
            0
        elif args.Length = 2 && args[0] = "--storage" && Path.IsPathFullyQualified args[1] then
            StorageFixtures.run args[1]
            0
        elif
            args.Length = 2
            && args[0] = "--migrate-state"
            && Path.IsPathFullyQualified args[1]
        then
            DeploymentFixtures.migrate args[1]
            0
        elif args.Length = 5 && args[0] = "--deployment-worker" then
            DeploymentFixtures.worker args[1] args[2] args[3] args[4]
            0
        elif
            args.Length = 2
            && args[0] = "--proton-files"
            && Path.IsPathFullyQualified args[1]
        then
            ProtonFixtures.create args[1] |> ignore
            0
        elif
            args.Length = 2
            && args[0] = "--steam-files"
            && Path.IsPathFullyQualified args[1]
        then
            SteamDiscoveryFixtures.create args[1] |> ignore
            0
        elif args.Length = 2 && args[0] = "--game-files" && Path.IsPathFullyQualified args[1] then
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
            let filePlansOnly = args.Length = 2 && args[0] = "--file-plans"
            let protonOnly = args.Length = 2 && args[0] = "--proton-contexts"
            let steamOnly = args.Length = 2 && args[0] = "--steam-discovery"
            let contextsOnly = args.Length = 2 && args[0] = "--game-contexts"
            let plannerOnly = args.Length = 2 && args[0] = "--planner"
            let organizationOnly = args.Length = 2 && args[0] = "--organization"
            let selectionOnly = args.Length = 2 && args[0] = "--selection"

            let primary, secondary =
                match args with
                | [| "--file-plans"; primary |]
                | [| "--proton-contexts"; primary |]
                | [| "--steam-discovery"; primary |]
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

            if
                not filePlansOnly
                && not selectionOnly
                && not organizationOnly
                && not plannerOnly
                && not contextsOnly
                && not steamOnly
                && not protonOnly
            then
                Fixtures.observe writer primary secondary
                StorageFixtures.observe writer primary
                WorkspaceFixtures.observe writer primary
                LibraryFixtures.observe writer primary
                LibraryRecoveryFixtures.observe writer primary
                LibraryIdentityFixtures.observe writer primary

            if
                not filePlansOnly
                && not organizationOnly
                && not plannerOnly
                && not contextsOnly
                && not steamOnly
                && not protonOnly
            then
                SelectionFixtures.observe writer primary

            if
                not filePlansOnly
                && not selectionOnly
                && not plannerOnly
                && not contextsOnly
                && not steamOnly
                && not protonOnly
            then
                OrganizationFixtures.observe writer primary
                OrganizationMigration.observe writer primary

            if
                not filePlansOnly
                && not selectionOnly
                && not organizationOnly
                && not contextsOnly
                && not steamOnly
                && not protonOnly
            then
                PlanningFixtures.observe writer

            if filePlansOnly then
                FileVisibilityFixtures.observe writer
                ConcurrentRootFixtures.observe writer primary
                FilePlanningFixtures.observe writer primary

            if protonOnly then
                ProtonFixtures.observe writer primary

            if steamOnly then
                SteamDiscoveryFixtures.observe writer primary

            if contextsOnly then
                GameContextFixtures.observe writer primary

            writer.WriteEndObject()
            writer.Flush()
            0
    with error ->
        Console.Error.WriteLine(error.Message)
        1
