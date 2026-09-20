namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type ComponentTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("components")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``reviewed components should keep immutable payloads and reject unsafe destinations``
        ()
        =
        flag "stableDistinctRoots" |> should equal true
        flag "immutablePayloadUnchanged" |> should equal true
        flag "wrongRootRefused" |> should equal true
        flag "caseCollisionRefused" |> should equal true
        flag "traversalRefused" |> should equal true

    [<Test>]
    member _.``profiles should switch exact component versions and isolate writable configuration``
        ()
        =
        flag "profileVersionsIndependent" |> should equal true
        flag "sharedPayloadRetained" |> should equal true
        flag "earlierGenerationRetained" |> should equal true

    [<Test>]
    member _.``multi-root recovery should preserve foreign and game files and remove only owned links``
        ()
        =
        flag "foreignLinkRefused" |> should equal true
        flag "interruptedActivationRecovered" |> should equal true
        flag "rootOriginalRestored" |> should equal true
        flag "dataLinkRemoved" |> should equal true
        flag "configurationLinkRemoved" |> should equal true
        flag "gameUpdatePreserved" |> should equal true
