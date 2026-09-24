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
    member _.``Apply keeps the selected components across restart and starts them``() =
        flag "appliedChoiceRetained" |> should equal true
        flag "appliedChoiceSurvivesCoordinatorRestart" |> should equal true
        flag "appliedChoiceSurvivesStoreRestart" |> should equal true
        flag "completedSetupAcceptsNewChoices" |> should equal true
        flag "unselectedComponentsNotStarted" |> should equal true
        flag "selectedSkseOnlyExecutes" |> should equal true
        flag "selectedEnbOnlyExecutes" |> should equal true
        flag "selectedFnisOnlyExecutes" |> should equal true
        flag "combinedChoicesExecuteOnceEach" |> should equal true

    [<Test>]
    member _.``cancelling an active setup should allow a fresh explicit attempt from installed state``() =
        flag "activeCancellationShowsInstalledComponentsWithoutRetry" |> should equal true
        flag "cancelledSetupAcceptsNewSelection" |> should equal true
        flag "explicitNewAttemptRunsOnlyChosenComponent" |> should equal true
