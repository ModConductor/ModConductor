namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type EnbTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("enb")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``runtime and preset archives should require pinned safe complete layouts``() =
        flag "exactRuntimeLayout" |> should equal true
        flag "wrongRuntimeHashRejected" |> should equal true
        flag "incompleteRuntimeRejected" |> should equal true
        flag "presetKeepsConfigurationWritable" |> should equal true
        flag "companionMapsOnlyData" |> should equal true
        flag "traversalArchiveRejected" |> should equal true
        flag "corruptArchiveRejected" |> should equal true

    [<Test>]
    member _.``author acquisition should remain explicit durable and cancellable``() =
        flag "authorPageWaitCancelRestart" |> should equal true

    [<Test>]
    member _.``Lean ENB should retain exact component provenance and prior values``() =
        flag "pinnedPresetProvenance" |> should equal true
        flag "runtimePlanPreservesPriorValues" |> should equal true

    [<Test>]
    member _.``profile ownership and generation launch plans should not overwrite foreign setup``
        ()
        =
        flag "profileAndForeignConflictsRefused" |> should equal true
        flag "generationScopedUpdateRemovalRecovery" |> should equal true
