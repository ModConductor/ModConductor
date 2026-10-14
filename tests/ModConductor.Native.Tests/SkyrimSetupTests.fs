namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type SkyrimSetupTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("skyrimSetup")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``new setup does not select or deploy components``() =
        flag "noDefaultComponentChoice" |> should equal true
        flag "noDefaultDeployment" |> should equal true
        flag "noDefaultIntent" |> should equal true
        flag "cancelBeforeApplyDoesNotWrite" |> should equal true

    [<Test>]
    member _.``an ENB archive is required before setup starts``() =
        flag "missingEnbArchiveDoesNotStart" |> should equal true

    [<Test>]
    member _.``failed ENB setup should wait for explicit Apply before retrying``() =
        flag "automaticContinueKeepsEnbFailureWithoutRetry" |> should equal true
        flag "explicitApplyRetriesFailedEnb" |> should equal true

    [<Test>]
    member _.``refused SKSE removal should fail setup without stopping the engine``() =
        flag "skseRemovalRefusalShowsFailedStatusWithoutStoppingEngine"
        |> should equal true

        flag "explicitApplyRetriesRefusedSkseRemovalOnce" |> should equal true

    [<Test>]
    member _.``Apply keeps the selected components across restart and starts them``() =
        flag "appliedChoiceRetained" |> should equal true
        flag "engineCompletesWithoutView" |> should equal true
        flag "activeSetupResumesOnInitialReadAfterRestart" |> should equal true
        flag "completedSetupAcceptsNewChoices" |> should equal true
        flag "unselectedComponentsNotStarted" |> should equal true
        flag "selectedSkseOnlyExecutes" |> should equal true
        flag "selectedEnbOnlyExecutes" |> should equal true
        flag "selectedFnisOnlyExecutes" |> should equal true
        flag "combinedChoicesExecuteOnceEach" |> should equal true

    [<Test>]
    member _.``cancelling an active setup should allow a fresh explicit attempt from installed state``
        ()
        =
        flag "concurrentContinueObservesActorWithoutDuplicateWork" |> should equal true

        flag "activeCancellationShowsInstalledComponentsWithoutRetry"
        |> should equal true

        flag "cancelRecoveryContinuesAfterRestart" |> should equal true
        flag "cancelledSetupAcceptsNewSelection" |> should equal true
        flag "explicitNewAttemptRunsOnlyChosenComponent" |> should equal true

    [<Test>]
    member _.``active component generations should finish before parent setup resumes``() =
        flag "activeSkseGenerationDoesNotTriggerParentRecovery" |> should equal true
        flag "finishedSkseGenerationCompletesParentSetup" |> should equal true
        flag "activeEnbGenerationDoesNotTriggerParentRecovery" |> should equal true
        flag "finishedEnbGenerationCompletesParentSetup" |> should equal true

    [<Test>]
    member _.``admitted FNIS runs should keep setup active until terminal notification without retry``
        ()
        =
        for outcome in [ "success"; "failure"; "cancelled" ] do
            flag ("admittedFnisStaysActive-" + outcome) |> should equal true
            flag ("terminalFnisNotifiesWithoutRetry-" + outcome) |> should equal true

        flag "savedFnisRunResumesObservationWithoutReadmission" |> should equal true

    [<Test>]
    member _.``FNIS admission refusals should remain visible until explicit Apply``() =
        flag "fnisAdmissionRefusalIsVisibleWithoutRetry" |> should equal true
        flag "explicitApplyRetriesFnisWithoutReinstalling" |> should equal true

    [<Test>]
    member _.``installing FNIS after cancellation should retain installed SKSE records and owned bytes``
        ()
        =
        flag "cancelThenFnisRetainsInstalledSkseDuringGeneration" |> should equal true
        flag "cancelThenFnisRetainsOwnedSkseBytesAndRecords" |> should equal true
