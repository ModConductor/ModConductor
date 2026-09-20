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
    member _.``combined setup should sequence owned components and readiness``() =
        flag "cleanPlanIncludesInitialDeployment" |> should equal true
        flag "initialDeploymentPrecedesSkse" |> should equal true
        flag "combinedSkseThenEnbPause" |> should equal true
        flag "combinedEnbThenOptionalFnis" |> should equal true
        flag "combinedPluginLaunchReady" |> should equal true

    [<Test>]
    member _.``combined setup should preserve cancellation recovery and existing workspaces``() =
        flag "existingWorkspaceKeepsActiveDeployment" |> should equal true
        flag "combinedCancelOwnsActiveEnb" |> should equal true
        flag "activeCancellationIntentIsDurableBeforeRestart" |> should equal true
        flag "combinedCancellationCompletesAfterRestart" |> should equal true
        flag "pendingDeploymentBlocksChildReads" |> should equal true

    [<Test>]
    member _.``combined setup should retain optional FNIS and reject stale consent``() =
        flag "completedFnisChoiceIsDurable" |> should equal true
        flag "fnisChoiceSurvivesReadyRestart" |> should equal true
        flag "failedFnisOutputRetriesThroughOwner" |> should equal true
        flag "changedGenerationRequiresNewPlan" |> should equal true
        flag "changedContextRequiresNewPlan" |> should equal true
        flag "externalChangesInvalidateEveryRolloverPath" |> should equal true
        flag "externalChangeInvalidatesActiveChildConsent" |> should equal true

        flag "activeChildOutcomeKeepsCancellationDurableUntilTerminal"
        |> should equal true

        flag "missingProtonPausesBeforeDeploymentWrite" |> should equal true
        flag "failedPrefixChoiceSurvivesSteamFirstRunRefresh" |> should equal true
