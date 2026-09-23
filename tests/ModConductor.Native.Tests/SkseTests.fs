namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type SkseTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("skse")
            .GetProperty(name: string)
            .GetBoolean()

    let coordinatorFlag name =
        NativeObservations.report.RootElement
            .GetProperty("skseCoordinator")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``compatibility should use the exact game runtime and ordinary Nexus entitlement``() =
        flag "exactRuntimeWins" |> should equal true
        flag "newerIncompatibleRejected" |> should equal true
        flag "labelWithoutRuntimeRejected" |> should equal true
        flag "ordinaryNexusRoutes" |> should equal true

    [<Test>]
    member _.``archive review should map only complete root and Data payloads``() =
        flag "reviewedArchiveLayout" |> should equal true

    [<Test>]
    member _.``launch should select only the active generation loader``() =
        flag "generationBoundLoader" |> should equal true
        flag "protonUsesLoader" |> should equal true

    [<Test>]
    member _.``replacement should publish selection and loader only with its generation``() =
        flag "transferArchiveInstallGeneration" |> should equal true

        flag "failedReplacementPreservesSelectionGenerationAndLoader"
        |> should equal true

        flag "updateRetainsImmutableGenerationLoaders" |> should equal true
        flag "removalRestoresForeignLoaderAndDropsActiveProvenance" |> should equal true

    [<Test>]
    member _.``cold restart should retain compatible cache and every generation loader``() =
        flag "coldRestartRetainsCacheAndLoaderProvenance" |> should equal true
        flag "nxmWaitingAndFailureAreDurable" |> should equal true

    [<Test>]
    member _.``NXM handoff should complete or publish each durable coordinator failure``() =
        coordinatorFlag "acceptNxmCompletesExpectedHandoff" |> should equal true
        coordinatorFlag "acceptNxmWrongAccountIsDurable" |> should equal true
        coordinatorFlag "acceptNxmExpiredIsDurable" |> should equal true
        coordinatorFlag "acceptNxmMetadataFailureIsDurable" |> should equal true
        coordinatorFlag "acceptNxmRateLimitIsDurable" |> should equal true
        coordinatorFlag "acceptNxmOutageIsDurable" |> should equal true
        coordinatorFlag "acceptNxmDownloadStartFailureIsDurable" |> should equal true

    [<Test>]
    member _.``cold coordinator should install validated cache while source is offline``() =
        coordinatorFlag "coldCoordinatorWaitsForChoiceThenUsesCacheOffline"
        |> should equal true

    [<Test>]
    member _.``launch gates should follow real game and source evidence``() =
        coordinatorFlag "coordinatorLaunchGatesCurrentUpdateIncompatibleAndUnavailable"
        |> should equal true

    [<Test>]
    member _.``failed replacements should preserve the installed setup at every boundary``() =
        coordinatorFlag "failedReplacementBoundariesPreserveInstalledSetup"
        |> should equal true

    [<Test>]
    member _.``retained generation rollback should restore its loader after restart``() =
        coordinatorFlag "retainedGenerationRollbackRestoresLoaderAfterRestart"
        |> should equal true
