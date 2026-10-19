namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type ArtifactTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("artifacts")
            .GetProperty("ordering")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``archive pages should retain arrival chronology through deletion and new arrivals``
        ()
        =
        flag "newestFirstAcrossPages" |> should equal true
        flag "deletedCursorRetainsContinuation" |> should equal true
        flag "lateAdditionPrecedesOlderPages" |> should equal true

    [<Test>]
    member _.``archive arrival chronology should survive replay refresh and restart``() =
        flag "replayPreservesArrivalOrder" |> should equal true
        flag "restartRetainsArrivalOrder" |> should equal true
