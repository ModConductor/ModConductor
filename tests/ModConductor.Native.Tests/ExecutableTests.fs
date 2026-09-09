namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type ExecutableTests() =
    let flag name =
        NativeObservations.report.RootElement.GetProperty(name: string).GetBoolean()

    [<Test>]
    member _.``native launch should preserve argument boundaries and isolate environment working directory and streams``
        ()
        =
        flag "argumentVectorPreserved" |> should equal true
        flag "workingDirectoryPreserved" |> should equal true
        flag "environmentIsolated" |> should equal true
        flag "independentNullStreams" |> should equal true

    [<Test>]
    member _.``root exit should retain observation of a later grandchild without removing deployment``
        ()
        =
        flag "rootExitRecorded" |> should equal true
        flag "earlyRootExitKeepsChildObservation" |> should equal true
        flag "grandchildAfterRootExitObserved" |> should equal true
        flag "observedScopeCompletion" |> should equal true
        flag "rootExitDoesNotUndeploy" |> should equal true

    [<Test>]
    member _.``stop waiting and owner closure should leave tools streams and deployed files intact``
        ()
        =
        flag "stopWaitingDoesNotKill" |> should equal true
        flag "detachedStreamsRemainIndependent" |> should equal true
        flag "detachDoesNotUndeploy" |> should equal true
        flag "ownerCloseDoesNotKillOrBreakStreams" |> should equal true
        flag "ownerCloseDoesNotUndeploy" |> should equal true
        flag "restartReportsUnknownTracking" |> should equal true

    [<Test>]
    member _.``replay and preset editing should retain the original run while current and historical reads stay distinct``
        ()
        =
        flag "launchReplayDoesNotSpawn" |> should equal true
        flag "restartReplayKeepsHistoricalResult" |> should equal true
        flag "stalePresetSaveRefused" |> should equal true
        flag "presetEditKeepsCapturedRun" |> should equal true
        flag "presetPageReportsLatestRun" |> should equal true
        flag "presetSurvivesRestart" |> should equal true
        flag "runHistorySurvivesRestart" |> should equal true
        flag "launchFailureVisible" |> should equal true
