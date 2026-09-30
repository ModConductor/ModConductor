namespace ModConductor.Native.Tests

open System
open FsUnit
open NUnit.Framework

[<TestFixture>]
type NonSteamContextTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("nonSteam")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``direct launches should use profile roots without Steam provenance and constrain SKSE to the matching edition``
        ()
        =
        flag "windowsDirectAndToolsUseProfileRootWithoutSteam" |> should equal true
        flag "gogSkseCannotSelectSameVersionSteamBuild" |> should equal true
        flag "unknownManualEditionLimitsSkseNotBaseLaunch" |> should equal true

    [<Test>]
    member _.``Wine selection should round trip and reject stale or cross runtime changes without dropping profile state``
        ()
        =
        if OperatingSystem.IsLinux() then
            flag "incompleteRuntimeRetainsInstallation" |> should equal true
            flag "incompleteRuntimeCannotPlay" |> should equal true
            flag "wineGogPathsAndSelectionRoundTrip" |> should equal true
            flag "wineToolKeepsSelectedPrefixAndProfileRoot" |> should equal true
            flag "nonSteamLaunchAppliesManagedFilesSettingsAndSaves" |> should equal true
            flag "staleContextSwitchPreservesWine" |> should equal true
            flag "steamCannotAcquireStandaloneWine" |> should equal true
            flag "wineUsesExplicitExistingDocumentsRedirect" |> should equal true
            flag "manualGogRuntimeUsesGogPathsWithoutSteamProvenance" |> should equal true
            flag "partialRuntimeRetainedWithoutOldCheckedRuntime" |> should equal true
        else
            Assert.Ignore "Wine runtime selection requires Linux."

    [<Test>]
    member _.``released database upgrade should preserve Steam bindings and profiles and roll back an interrupted context column update``
        ()
        =
        flag "clonePreservesWineWithoutSharingBinding" |> should equal true
        flag "releasedUpgradeRollsBackBeforeCommit" |> should equal true
        flag "releasedSteamStateAndProfileSelectionSurviveUpgrade" |> should equal true
