namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type FnisTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("fnis")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``reviewed FNIS file should require the exact immutable Skyrim SE layout``() =
        flag "reviewedLayoutRegistersExactGenerator" |> should equal true
        flag "incompleteArchiveIsRefused" |> should equal true
        flag "catalogueSelectsReviewedSkyrimSeMainFile" |> should equal true

    [<Test>]
    member _.``effective FNIS inputs should be stable by path and content``() =
        flag "effectiveInputFingerprintIgnoresEnumerationOrder" |> should equal true
        flag "effectiveInputFingerprintChangesWithAnimationContent" |> should equal true
        flag "effectiveInputFilterRejectsUnrelatedFiles" |> should equal true
        flag "effectiveInputFilterIncludesSkeletons" |> should equal true
        flag "windowsToolProjectionUsesExactDescriptorAndTypedArguments"
        |> should equal true
        flag "selectedWindowsContextProjectsRegisteredGenerator" |> should equal true

    [<Test>]
    member _.``direct acquisition should retain complete generator provenance``() =
        flag "directAcquisitionPublishesImmutableGenerationAndProvenance"
        |> should equal true

    [<Test>]
    member _.``cancel retry failure and recovery should preserve the active setup``() =
        flag "cancelledUpdatePreservesPriorGeneration" |> should equal true
        flag "retryResumesAndPublishesSelectedUpdate" |> should equal true
        flag "failedReplacementInterruptionReachedPublication" |> should equal true
        flag "failedReplacementRecoveryPreservesActiveSetup" |> should equal true

    [<Test>]
    member _.``FNIS execution should publish only successful output``() =
        flag "successfulRunPublishesAndSelectsOneCurrentOutput" |> should equal true
        flag "failedRunPreservesPriorOutputAndBoundedExitEvidence" |> should equal true
        flag "cancelledRunTerminatesAndPreservesPriorOutput" |> should equal true
        flag "runReturnsWhileCancellationIsReachable" |> should equal true
        flag "activeGeneratedOutputIsExcludedFromEffectiveInputs" |> should equal true
        flag "addedEffectiveInputMakesFnisStale" |> should equal true
        flag "removedEffectiveInputRestoresFingerprint" |> should equal true
        flag "distinctRunIdsCreateVersionsOfOneStableOutput" |> should equal true
        flag "timedOutRunRetainsDetailAndRemovesStage" |> should equal true
        flag "outputLimitFailureRetainsDetailAndRemovesStage" |> should equal true
        flag "launchFailureRetainsDetailAndRemovesStage" |> should equal true
        flag "malformedTemporaryLogIsCapturedBoundedInOwnedState" |> should equal true
        flag "temporaryLogCleanupPreservesImmutableGenerator" |> should equal true
        flag "missingTemporaryLogIsAnEmptyOwnedRecord" |> should equal true
        flag "stalePublicationRollsBackVersionAndSelectionAtomically" |> should equal true
        flag "firstStalePublicationRemovesOutputAndProfileShells" |> should equal true
        flag "restartMarksRunAbandonedRemovesStageAndPreservesOutput" |> should equal true
        flag "engineShutdownCancelsAndDrainsSleepingFnisProcessGroup" |> should equal true

    [<Test>]
    member _.``removal and restart should preserve foreign files and retained provenance``() =
        flag "removalPublishesOwnedGenerationAndPreservesForeignFiles"
        |> should equal true

        flag "restartKeepsRemovalAndRetainedProvenanceDurable" |> should equal true
        flag "interruptedDownloadResumesAfterColdRestart" |> should equal true

    [<Test>]
    member _.``NXM handoff should be account bound and automatic after admission``() =
        flag "accountBoundNxmCompletesWithoutManualArchiveSelection"
        |> should equal true

        flag "wrongAccountHandoffFailsDurablyWithoutChangingInstalledSetup"
        |> should equal true
