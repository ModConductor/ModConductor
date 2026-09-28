namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type EnbTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("enb")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``runtime and preset archives should require pinned safe complete layouts``() =
        flag "exactRuntimeLayout" |> should equal true
        flag "wrongRuntimeHashRejected" |> should equal true
        flag "incompleteRuntimeRejected" |> should equal true
        flag "presetKeepsConfigurationWritable" |> should equal true
        flag "companionMapsOnlyData" |> should equal true
        flag "traversalArchiveRejected" |> should equal true
        flag "corruptArchiveRejected" |> should equal true

    [<Test>]
    member _.``author acquisition should remain explicit durable and cancellable``() =
        flag "authorPageWaitCancelRestart" |> should equal true
        flag "combinedCancelUsesProductionEnbOwner" |> should equal true
        flag "combinedEnbCancellationSurvivesOwnerRestart" |> should equal true
        flag "unapprovedCatalogueBlocksAcquisition" |> should equal true

    [<Test>]
    member _.``Lean ENB should retain exact component provenance and prior values``() =
        flag "pinnedPresetProvenance" |> should equal true
        flag "approvedCatalogueResolvesHashesAtAcquisition" |> should equal true
        flag "runtimePlanPreservesPriorValues" |> should equal true

    [<Test>]
    member _.``profile ownership and generation launch plans should not overwrite foreign setup``
        ()
        =
        flag "profileAndForeignConflictsRefused" |> should equal true
        flag "generationScopedUpdateRemovalRecovery" |> should equal true

    [<Test>]
    member _.``setup update interruption and removal should use recoverable component generations``
        ()
        =
        flag "setupPublishesReadyGeneration" |> should equal true
        flag "interruptedUpdateRestoresActiveGeneration" |> should equal true
        flag "removalRestoresPriorFilesAndConfiguration" |> should equal true

    [<Test>]
    member _.``authenticated coordinator should complete direct and NXM setup orchestration``() =
        flag "authenticatedGrpcDirectAcquisitionReachesReadyAndUpdates"
        |> should equal true

        flag "nxmAcquisitionReachesReady" |> should equal true

        flag "authenticatedGrpcCombinedCancellationUsesProductionEnbOwner"
        |> should equal true

    [<Test>]
    member _.``configuration removal should remain recoverable and preserve later edits``() =
        flag "configurationFailureRemainsRecoverable" |> should equal true
        flag "compareBeforeRestorePreservesConflictAndRecovers" |> should equal true

    [<Test>]
    member _.``runtime choice does not acquire or remove the preset``() =
        flag "runtimeOnlyRemovalKeepsPresetAndCompanion" |> should equal true
        flag "runtimeOnlySelectionAvoidsPresetAcquisition" |> should equal true

    [<Test>]
    member _.``ENB should initialize fresh local settings without changing saves and retain them on removal``
        ()
        =
        flag "freshProfileSettingsInitializedBeforeEnbInstall" |> should equal true
        flag "enbRemovalRetainsInitializedProfileSettings" |> should equal true
