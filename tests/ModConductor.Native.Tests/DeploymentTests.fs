namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type DeploymentTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("deployment")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``switching generations should retain exact pins and leave shared payloads and mutable outputs intact``
        ()
        =
        flag "symlinks" |> should equal true
        flag "fileAndDirectoryLinks" |> should equal true
        flag "entriesSeparateFromTargets" |> should equal true
        flag "addedAndRemovedPaths" |> should equal true
        flag "exactGenerationsAndVersions" |> should equal true
        flag "rollbackKeepsMutableOutputs" |> should equal true
        flag "sharedPayloadSurvives" |> should equal true

    [<Test>]
    member _.``interrupted activation and restoration should resume from durable effects after owner loss``
        ()
        =
        flag "recordedActivationPhasesRecover" |> should equal true
        flag "interruptedRestoreRecovers" |> should equal true
        flag "recordedIdentitySurvivesOwnerLoss" |> should equal true
        flag "unrecordedCreateRequiresReviewAfterProcessLoss" |> should equal true
        flag "cancelledEffectRemainsRecoverable" |> should equal true
        flag "originalsRecordedBeforeEffects" |> should equal true
        flag "explicitOriginalsRestored" |> should equal true
        flag "originalPreservationAndRestorationDoNotReadContent" |> should equal true

    [<Test>]
    member _.``changed destinations and pins should block recovery without overwriting foreign entries``
        ()
        =
        flag "foreignFileBeforeResumePreserved" |> should equal true
        flag "foreignLinkBeforeRetryPreserved" |> should equal true
        flag "originalRestoreNeverOverwrites" |> should equal true
        flag "unrecordedActivationLinkPreserved" |> should equal true
        flag "unrecordedRestoreLinkPreserved" |> should equal true
        flag "overlappingStorageRefusedBeforeRows" |> should equal true
        flag "disjointTargetsMayShareOriginals" |> should equal true
        flag "changedGenerationRefusesBeforeEffects" |> should equal true
        flag "corruptReceiptHasNoEffects" |> should equal true
        flag "partialReceiptDiscoverable" |> should equal true

    [<Test>]
    member _.``receipt revisions and live owners should exclude stale or concurrent changes and close``
        ()
        =
        flag "staleActivationRefused" |> should equal true
        flag "liveOwnerExcluded" |> should equal true
        flag "overlappingContextHasNoRowsOrEffects" |> should equal true
        flag "closeExcludedDuringEffects" |> should equal true

    [<Test>]
    member _.``duplicate boundaries should return invalid plan without a receipt``() =
        flag "duplicateBoundaryHasNoReceipt" |> should equal true

    [<Test>]
    member _.``overlapping boundaries should return invalid plan without a receipt``() =
        flag "overlappingBoundaryHasNoReceipt" |> should equal true

    [<Test>]
    member _.``a nested target beneath an active file link should be refused during preparation``
        ()
        =
        flag "oldFileToNestedTargetRefusedDuringPrepare" |> should equal true

    [<Test>]
    member _.``a cancelled profile read should remain a cancelled deployment``() =
        flag "cancelledProfileReadRemainsCancelled" |> should equal true

    [<Test>]
    member _.``missing boundaries should return invalid plan without a receipt``() =
        flag "missingBoundaryHasNoReceipt" |> should equal true

    [<Test>]
    member _.``large target sets should prepare without an arbitrary limit``() =
        flag "largeTargetSetPrepared" |> should equal true

    [<Test>]
    member _.``invalid boundaries in large requests should leave no receipt``() =
        flag "invalidBoundaryInLargeRequestHasNoReceipt" |> should equal true

    [<Test>]
    member _.``large target parent sets should prepare without an arbitrary limit``() =
        flag "largeParentSetPrepared" |> should equal true

    [<Test>]
    member _.``changed generation inputs should return invalid plan before capture``() =
        flag "changedGenerationInputReturnsRefusal" |> should equal true
