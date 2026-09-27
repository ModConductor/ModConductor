module ModConductor.Native.Fixtures.Program

open System
open System.IO
open System.Runtime.CompilerServices
open System.Text.Json
open ModConductor.Native.Fixtures

let private writeJson includeNativeAot observe =
    use writer =
        new Utf8JsonWriter(Console.OpenStandardOutput(), JsonWriterOptions(Indented = true))

    writer.WriteStartObject()

    if includeNativeAot then
        writer.WriteBoolean("nativeAot", not RuntimeFeature.IsDynamicCodeSupported)

    observe writer
    writer.WriteEndObject()
    writer.Flush()
    0

let private run (args: string array) =
    match args with
    | [| "--native-tool-grandchild" |] -> NativeToolFixtures.grandchild ()
    | [| "--native-tool-child"; path |] -> NativeToolFixtures.child path
    | [| "--native-tool"; path |] ->
        writeJson true (fun writer -> NativeToolFixtures.observe writer path)
    | [| "--loot-response-validation" |] -> writeJson true LootFixtures.validateMoves
    | [| "--loot"; game; folder; plugin; output |] ->
        writeJson true (fun writer -> LootFixtures.observe writer game folder plugin output)
    | [| "--game-launch-cancellation" |] ->
        writeJson true (fun writer ->
            GameLaunchCancellationFixture.sample ()
            |> GameLaunchCancellationFixture.observe writer)
    | [| "--archive-preview-race" |] -> writeJson true ArchivePreviewRaceFixtures.observe
    | [| "--file-preview" |] -> writeJson true FilePreviewFixtures.observe
    | [| "--text-edits"; path |] ->
        writeJson true (fun writer -> TextEditFixtures.observe writer path)
    | [| "--archive-policy" |] -> writeJson true ArchivePolicyFixtures.observe
    | [| "--plugin-order-files"; path |] ->
        PluginOrderSamples.files path |> Console.WriteLine
        0
    | [| "--plugin-order"; path |] ->
        writeJson true (fun writer -> PluginOrderFixtures.observe writer path)
    | [| "--game-view"; path |] ->
        writeJson true (fun writer -> GameViewFixtures.observe writer path)
    | [| "--bethesda-files"; path |] ->
        BethesdaSamples.files path |> Console.WriteLine
        0
    | [| "--bethesda"; path |] ->
        writeJson true (fun writer -> BethesdaFixtures.observe writer path)
    | [| "--nxm-delivery"; first; second |] ->
        writeJson true (fun writer -> NxmDeliveryFixtures.observe writer first second)
    | [| "--nxm"; path |] ->
        writeJson true (fun writer ->
            NxmFixtures.ingress writer
            NxmFixtures.observe writer path
            NxmFixtures.setup writer (Path.Combine(path, "link-setup")))
    | [| "--desktop-engine"; path |] ->
        ModConductor.Engine.Program.run [| "--state-directory"; path |]
    | [| "--skyrim-setup"; path |] ->
        writeJson true (fun writer -> SkyrimSetupFixtures.observe writer path)
    | [| "--desktop-lease"; path |] -> DesktopFixtures.tryLease path
    | [| "--desktop"; path |] -> writeJson false (fun writer -> DesktopFixtures.observe writer path)
    | [| "--nexus-engine"; first; second |] -> NexusFixtures.engine first second
    | [| "--nexus-metadata-engine"; first; second |] -> NexusMetadataFixtures.engine first second
    | [| "--nexus-metadata"; path |] ->
        writeJson true (fun writer -> NexusMetadataFixtures.observe writer path)
    | [| "--nexus"; path |] -> writeJson true (fun writer -> NexusFixtures.observe writer path)
    | [| "--nexus-discovery" |] -> writeJson true NexusFixtures.discovery
    | [| "--credential-worker"; path |] ->
        CredentialFixtures.worker path
        0
    | [| "--credentials"; _ |] -> writeJson true CredentialFixtures.observe
    | [| "--inspection-files"; path |] when Path.IsPathFullyQualified path ->
        ArchiveInspectionFixtures.create path
        0
    | [| "--archive-inspection"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> ArchiveInspectionFixtures.observe writer path)
    | [| "--maintenance-worker"; a; b; c; d; e; f; g |] ->
        MaintenanceRecoveryFixtures.worker a b c d e f g
        0
    | [| "--bundle-worker"; a; b; c |] ->
        BundleFixtures.worker a b c
        0
    | [| "--bundle-files"; path |] ->
        BundleFixtures.create path
        0
    | [| "--bundles"; path |] -> writeJson true (fun writer -> BundleFixtures.observe writer path)
    | [| "--bain"; path |] -> writeJson true (fun writer -> BainFixtures.observe writer path)
    | [| "--fomod"; path |] -> writeJson true (fun writer -> FomodFixtures.observe writer path)
    | [| "--mod-maintenance"; path |] ->
        writeJson true (fun writer ->
            MaintenanceFixtures.observe writer (Path.Combine(path, "effects"))
            MaintenanceRecoveryFixtures.observe writer (Path.Combine(path, "restart")))
    | [| "--installation-worker"; a; b; c; d; e |] ->
        InstallationFixtures.worker a b c d e
        0
    | [| "--installation-files"; path |] when Path.IsPathFullyQualified path ->
        InstallationFixtures.create path
        0
    | [| "--archive-installation"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> InstallationFixtures.observe writer path)
    | [| "--download-worker"; a; b; c; d; e |] ->
        DownloadFixtures.worker a b c d e
        0
    | [| "--download-server" |] ->
        use server = new DownloadServer()

        Console.WriteLine(
            server.Url + " " + server.Checksum + " " + server.Payload.Length.ToString()
        )

        Console.Out.Flush()
        Console.ReadLine() |> ignore
        0
    | [| "--downloads"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> DownloadFixtures.observe writer path)
    | [| "--artifact-worker"; a; b; c; d; e |] ->
        ArtifactFixtures.worker a b c d e
        0
    | [| "--artifacts"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> ArtifactFixtures.observe writer path)
    | [| "--profile-data"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> ProfileDataFixtures.observe writer path)
    | [| "--save-management"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> SaveFixtures.observe writer path)
    | [| "--save-samples"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> SaveFixtures.samples writer path)
    | [| "--wine-check"; path; _ |] -> GameLaunchChild.wine path
    | args when args.Length >= 3 && args[0] = "--game-load" -> GameLaunchChild.run args[1..]
    | [| "--game-launch"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> GameLaunchFixtures.observe writer path)
    | args when args.Length >= 3 && args[0] = "--executable-child" -> ExecutableChild.run args[1..]
    | [| "--executables"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> ExecutableFixtures.observe writer path)
    | [| "--generation-game" |] ->
        Console.WriteLine "ready"
        Console.ReadLine() |> ignore
        0
    | [| "--components"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> ComponentFixtures.observe writer path)
    | [| "--skse"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer ->
            SkseFixtures.observe writer path
            SkseCoordinatorFixtures.observe writer path)
    | [| "--enb"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> EnbFixtures.observe writer path)
    | [| "--fnis"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> FnisFixtures.observe writer path)
    | [| "--normalize-owned-fixture"; path |] when Path.IsPathFullyQualified path ->
        GenerationCleanup.normalize path
        0
    | [| "--generated-outputs"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer -> GeneratedOutputFixtures.observe writer path)
    | [| "--deployment-live"; a; b; c; d; e |] when
        Path.IsPathFullyQualified a && Path.IsPathFullyQualified b
        ->
        DeploymentLiveFixture.run a b c d e
        0
    | [| "--deployment-backend"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer ->
            DeploymentBackendFixtures.observe writer path
            DeploymentProcessFixtures.observe writer path)
    | [| "--generations"; path |] when Path.IsPathFullyQualified path ->
        writeJson true (fun writer ->
            GenerationFixtures.observe writer path
            GenerationCorrectionFixtures.observe writer path)
    | [| "--deployment-recovery"; path |] when Path.IsPathFullyQualified path ->
        DeploymentFixtures.run path
        0
    | [| "--storage"; path |] when Path.IsPathFullyQualified path ->
        StorageFixtures.run path
        0
    | [| "--deployment-worker"; a; b; c; d |] ->
        DeploymentFixtures.worker a b c d
        0
    | [| "--proton-files"; path |] when Path.IsPathFullyQualified path ->
        ProtonFixtures.create path |> ignore
        0
    | [| "--steam-files"; path |] when Path.IsPathFullyQualified path ->
        SteamDiscoveryFixtures.create path |> ignore
        0
    | [| "--game-files"; path |] when Path.IsPathFullyQualified path ->
        GameContextFixtures.create path 104
        0
    | [| "--storage-worker"; a; b; c; d |] ->
        StorageWorker.run a b c d
        0
    | [| "--workspace-worker"; a; b; c; d |] ->
        WorkspaceWorker.run a b c d
        0
    | [| "--library-worker"; a; b; c; d |] ->
        LibraryWorker.run a b c d
        0
    | [| "--selection-worker"; a; b; c; d |] ->
        SelectionFixtures.worker a b c d
        0
    | [| "--migration-worker"; a; b; c; d |] ->
        MigrationFixtures.worker a b c d
        0
    | [| "--vortex-migration-worker"; a; b; c; d; e; f; g |] ->
        VortexMigrationFixtures.worker a b c d e f g
        0
    | _ -> FixtureHostDefault.run args

[<EntryPoint>]
let main args =
    try
        run args
    with error ->
        Console.Error.WriteLine(error.Message)
        1
