namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type GeneratedOutputTests() =
    let flag name =
        NativeObservations.report.RootElement.GetProperty(name: string).GetBoolean()

    [<Test>]
    member _.``review should preserve changed outputs and continue complete pages without losing review state``
        ()
        =
        flag "nonRegularWritableFileReturnsErrorAndReleasesObservation" |> should equal true
        flag "toolFolderStartsEmptyOutsideGame" |> should equal true
        flag "changedReviewedFileRemainsUntouched" |> should equal true
        flag "invalidOutputRequestsReturnErrorsWithoutChangingFiles" |> should equal true
        flag "keepAcknowledgesCurrentBytes" |> should equal true
        flag "laterOutputChangeNeedsReview" |> should equal true
        flag "outputPagingKeepsCompleteRowsAndViewIdentity" |> should equal true

    [<Test>]
    member _.``promotion should survive cancellation and restart without duplicating publication or losing source provenance``
        ()
        =
        flag "cancelAfterPublicationKeepsDurableVersionAndOutput" |> should equal true
        flag "movePublishesOneImmutableVersionBeforeRemoval" |> should equal true
        flag "publicationResultSurvivesRestart" |> should equal true
        flag "createdOutputModIsDisabledAcrossProfiles" |> should equal true
        flag "sourceLessModIsReadyWithoutPublish" |> should equal true
        flag "ownedOutputFolderIsNotAnUnmanagedMod" |> should equal true
        flag "promotionPreviewReportsActualSavedReplacement" |> should equal true
        flag "promotionPreservesSourceAndSharesUnchangedPayload" |> should equal true
        flag "explicitSourcePublishRetainsPriorOutputVersion" |> should equal true

    [<Test>]
    member _.``writable review should keep saved copies and never reseed an intentionally discarded slot``
        ()
        =
        flag "exactWritableSlotIsInitialized" |> should equal true
        flag "saveCopyKeepsWorkingFile" |> should equal true
        flag "discardedSlotIsNotReseeded" |> should equal true
        flag "deactivationPreservesReviewStorage" |> should equal true

    [<Test>]
    member _.``saved deployment restore should retain immutable pins and current writable choices without changing the configured profile``
        ()
        =
        flag "savedRestoreKeepsExactVersionAndCurrentStoppedDeclarations"
        |> should equal true

        flag "savedRecipeSurvivesRestart" |> should equal true
        flag "restartRestoreKeepsPinsAndAbsentStoppedSlot" |> should equal true
        flag "restoreDoesNotChangeConfiguredProfileSelection" |> should equal true

    [<Test>]
    member _.``resuming an unfinished review should respect later output configuration while completed replay stays historical``
        ()
        =
        flag "stoppedOutputRefusesOldDiscardAfterRestart" |> should equal true

        flag "completedOutputReplayRemainsHistoricalAfterConfigurationChange"
        |> should equal true

    [<Test>]
    member _.``resuming after removal should complete the absent intent without republishing or removing replacement bytes``
        ()
        =
        flag "removedOutputRetainsPendingPublicationBeforeResultSave"
        |> should equal true

        flag "restartCompletesAbsentMoveWithoutAnotherPublication" |> should equal true
        flag "restartCompletesAbsentDiscardTruthfully" |> should equal true
        flag "restartLeavesPresentReplacementUntouched" |> should equal true
