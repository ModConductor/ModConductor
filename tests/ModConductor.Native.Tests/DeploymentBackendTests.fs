namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type DeploymentBackendTests() =
    let flag group name =
        NativeObservations.report.RootElement
            .GetProperty(group: string)
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``cancelled or stale preparation should leave original game files unchanged``
        ()
        =
        for name in
            [ "cancelledPreparationNoReceipt"
              "stalePreparationNoEffects" ] do
            flag "deploymentBackend" name |> should equal true

    [<Test>]
    member _.``profile view should switch between managed files and original game files``
        ()
        =
        for name in
            [ "profileViewContainsManagedWinner"
              "sourceInventoryUnaffected"
              "retainedBaselineUsesOriginalSource"
              "retainedGenerationReactivated" ] do
            flag "deploymentBackend" name |> should equal true

    [<Test>]
    member _.``changing an installation should leave both game directories unchanged``
        ()
        =
        flag "deploymentBackend" "sourceChangeRetiresPriorView" |> should equal true

    [<Test>]
    member _.``process observation should refuse the selected executable without blocking an unrelated same name``
        ()
        =
        for name in
            [ "matchingNativeProcessRefused"
              "unrelatedSameNameAllowed"
              "stoppedNativeProcessAllowed" ] do
            flag "deploymentProcesses" name |> should equal true
