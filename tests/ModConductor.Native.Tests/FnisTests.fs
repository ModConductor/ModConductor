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
