namespace ModConductor.Native.Tests

open System
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

        if OperatingSystem.IsLinux() then
            flag "selectedWindowsContextProjectsRegisteredGenerator" |> should equal true

    [<Test>]
    member _.``direct acquisition should retain complete generator provenance``() =
        flag "directAcquisitionPublishesGeneratorAndProvenance" |> should equal true

    [<Test>]
    member _.``cancel retry failure and recovery should preserve the active setup``() =
        flag "cancelledUpdatePreservesPriorGeneration" |> should equal true
        flag "retryResumesAndPublishesSelectedUpdate" |> should equal true
        flag "failedReplacementInterruptionReachedPublication" |> should equal true
        flag "failedReplacementRecoveryPreservesActiveSetup" |> should equal true

    [<Test>]
    member _.``FNIS execution should preserve generated output and report failures``() =
        if not (OperatingSystem.IsLinux()) then
            Assert.Ignore "The FNIS execution fixture uses a Linux Proton launcher."

        flag "successfulRunPublishesAndSelectsOneCurrentOutput" |> should equal true
        flag "generatedFnisOutputIsPrivateToOwningProfile" |> should equal true
        flag "transportKeepsExactFnisProviderAttribution" |> should equal true
        flag "importedFnisOutputIsPrivateBeforeFirstRun" |> should equal true
        flag "importedFnisOutputKeepsTransportRepresentation" |> should equal true

        flag "firstRunReplacesImportedOutputWithoutSecondVisibleMod"
        |> should equal true

        flag "runWithNoOutputPreservesPriorOutputAndExitCode" |> should equal true
        flag "generatedFilesRemainAvailableAfterNonzeroExit" |> should equal true
        flag "cancelledRunTerminatesAndPreservesPriorOutput" |> should equal true
        flag "combinedCancelUsesProductionFnisOwner" |> should equal true

        flag "pendingCombinedFnisCancellationCompletesThroughProductionOwnerAfterRestart"
        |> should equal true

        flag "runReturnsWhileCancellationIsReachable" |> should equal true
        flag "activeGeneratedOutputIsExcludedFromEffectiveInputs" |> should equal true
        flag "addedEffectiveInputMakesFnisStale" |> should equal true
        flag "removedEffectiveInputRestoresFingerprint" |> should equal true
        flag "firstRunUpdatesActiveGameViewWithoutSavingDeployment" |> should equal true
        flag "completedFnisRunStreamsTerminalStateWithoutWaiting" |> should equal true
        flag "unknownFnisRunStreamReturnsNotFound" |> should equal true
        flag "rerunReplacesPriorOutputWithoutSavingDeployment" |> should equal true

        flag "successorReceiptRemainsReadableAfterTransientPredecessorIsPruned"
        |> should equal true

        flag "interruptionBeforeActivationPreservesPriorViewAndWorkingOutput"
        |> should equal true

        flag "interruptionAfterActivationFinalizesWorkingOutput" |> should equal true

        flag "savedDeploymentRestoresExactFnisFilesAndMarksWorkingOutputStale"
        |> should equal true

        flag "deletingOwnerProfileDeletesPrivateFnisOutputAndKeepsOtherProfile"
        |> should equal true

        flag "runningFnisStreamFinishesAfterCancellation" |> should equal true
        flag "engineShutdownCompletesFnisRunStream" |> should equal true
        flag "timedOutRunRetainsDetailAndRemovesStage" |> should equal true
        flag "outputLimitFailureRetainsDetailAndRemovesStage" |> should equal true
        flag "launchFailureRetainsDetailAndRemovesStage" |> should equal true
        flag "malformedTemporaryLogIsCapturedBoundedInOwnedState" |> should equal true
        flag "temporaryLogCleanupPreservesImmutableGenerator" |> should equal true

        flag "restrictiveTemporaryLogTreeRestoresContentMetadataModesAndTimestamps"
        |> should equal true

        flag "newRestrictiveTemporaryLogDirectoryIsCapturedAndRemoved"
        |> should equal true

        flag "missingTemporaryLogIsAnEmptyOwnedRecord" |> should equal true

        flag "stalePublicationRollsBackVersionAndSelectionAtomically"
        |> should equal true

        flag "firstStalePublicationRemovesOutputAndProfileShells" |> should equal true

        flag "restartMarksRunAbandonedRemovesStageAndPreservesOutput"
        |> should equal true

        flag "engineShutdownCancelsAndDrainsSleepingFnisProcessGroup"
        |> should equal true

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
