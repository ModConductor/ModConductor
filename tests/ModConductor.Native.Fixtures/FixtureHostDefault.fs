module ModConductor.Native.Fixtures.FixtureHostDefault

open System
open System.IO
open System.Runtime.CompilerServices
open System.Text.Json
open ModConductor.Native.Fixtures

type private FixtureSet =
    | Full
    | Platform
    | Workspaces
    | Library
    | FilePlans
    | ProtonContexts
    | SteamDiscovery
    | GameContexts
    | Planner
    | Organization
    | Selection
    | Migration

let private select (args: string array) =
    match args with
    | [| "--platform"; primary |] when Path.IsPathFullyQualified primary -> Platform, primary, None
    | [| "--platform"; primary; secondary |] when
        Path.IsPathFullyQualified primary && Path.IsPathFullyQualified secondary
        ->
        Platform, primary, Some secondary
    | [| "--workspaces"; primary |] when Path.IsPathFullyQualified primary ->
        Workspaces, primary, None
    | [| "--library"; primary |] when Path.IsPathFullyQualified primary -> Library, primary, None
    | [| "--file-plans"; primary |] when Path.IsPathFullyQualified primary ->
        FilePlans, primary, None
    | [| "--proton-contexts"; primary |] when Path.IsPathFullyQualified primary ->
        ProtonContexts, primary, None
    | [| "--steam-discovery"; primary |] when Path.IsPathFullyQualified primary ->
        SteamDiscovery, primary, None
    | [| "--game-contexts"; primary |] when Path.IsPathFullyQualified primary ->
        GameContexts, primary, None
    | [| "--planner"; primary |] when Path.IsPathFullyQualified primary -> Planner, primary, None
    | [| "--organization"; primary |] when Path.IsPathFullyQualified primary ->
        Organization, primary, None
    | [| "--selection"; primary |] when Path.IsPathFullyQualified primary ->
        Selection, primary, None
    | [| "--migration"; primary |] when Path.IsPathFullyQualified primary ->
        Migration, primary, None
    | [| primary |] when Path.IsPathFullyQualified primary -> Full, primary, None
    | [| primary; secondary |] when
        Path.IsPathFullyQualified primary && Path.IsPathFullyQualified secondary
        ->
        Full, primary, Some secondary
    | _ -> invalidArg "args" "Supply owned absolute fixture directories."

let private observeFull writer primary secondary =
    Fixtures.observe writer primary secondary
    StorageFixtures.observe writer primary
    WorkspaceFixtures.observe writer primary
    LibraryFixtures.observe writer primary
    LibraryRecoveryFixtures.observe writer primary
    LibraryIdentityFixtures.observe writer primary
    MigrationFixtures.observe writer primary
    VortexMigrationFixtures.observe writer primary
    SelectionFixtures.observe writer primary
    OrganizationFixtures.observe writer primary
    PlanningFixtures.observe writer

let run args =
    let fixtureSet, primary, secondary = select args
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

    match fixtureSet with
    | Full -> observeFull writer primary secondary
    | Platform -> Fixtures.observe writer primary secondary
    | Workspaces -> WorkspaceFixtures.observe writer primary
    | Library ->
        LibraryFixtures.observe writer primary
        LibraryRecoveryFixtures.observe writer primary
        LibraryIdentityFixtures.observe writer primary
    | FilePlans ->
        FileVisibilityFixtures.observe writer
        ConcurrentRootFixtures.observe writer primary
        FilePlanningFixtures.observe writer primary
    | ProtonContexts -> ProtonFixtures.observe writer primary
    | SteamDiscovery -> SteamDiscoveryFixtures.observe writer primary
    | GameContexts -> GameContextFixtures.observe writer primary
    | Planner -> PlanningFixtures.observe writer
    | Organization -> OrganizationFixtures.observe writer primary
    | Selection -> SelectionFixtures.observe writer primary
    | Migration ->
        MigrationFixtures.observe writer primary
        VortexMigrationFixtures.observe writer primary

    writer.WriteEndObject()
    writer.Flush()
    0
