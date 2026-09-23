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
    member _.``only selected components enter a reviewable plan``() =
        flag "enbNeedsArchiveBeforeApply" |> should equal true
        flag "enbOnlyPlan" |> should equal true
        flag "enbDoesNotSelectSkseOrFnis" |> should equal true
        flag "enbArchiveEnablesReview" |> should equal true
        flag "fnisOnlyPlan" |> should equal true
        flag "skseOnlyPlan" |> should equal true
        flag "combinedPlanNamesOnlySelectedComponents" |> should equal true

    [<Test>]
    member _.``start requires the reviewed selection and explicit confirmation``() =
        flag "selectionBoundToPlan" |> should equal true
        flag "staleSelectionDoesNotWrite" |> should equal true
        flag "unconfirmedPlanDoesNotWrite" |> should equal true
        flag "confirmedChoiceRetained" |> should equal true
        flag "confirmedChoiceSurvivesCoordinatorRestart" |> should equal true
        flag "confirmedChoiceSurvivesStoreRestart" |> should equal true
        flag "unselectedComponentsNotStarted" |> should equal true
        flag "selectedSkseOnlyExecutes" |> should equal true
        flag "selectedEnbOnlyExecutes" |> should equal true
        flag "selectedFnisOnlyExecutes" |> should equal true
        flag "combinedChoicesExecuteOnceEach" |> should equal true

    [<Test>]
    member _.``child changes allow only expected plan rollover``() =
        flag "expectedChildOnlyDeltasAdvanceEveryRollover" |> should equal true
        flag "combinedChildAndUnrelatedDeltasInvalidateEveryRollover" |> should equal true

    [<Test>]
    member _.``cancelling an active setup should allow a fresh explicit attempt from installed state``() =
        flag "activeCancellationShowsInstalledComponentsWithoutRetry" |> should equal true
        flag "cancelledSetupAcceptsNewSelection" |> should equal true
        flag "explicitNewAttemptRunsOnlyChosenComponent" |> should equal true
