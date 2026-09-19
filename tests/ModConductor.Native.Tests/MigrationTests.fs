namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type MigrationTests() =
    let data () =
        NativeObservations.report.RootElement.GetProperty "migration"

    let flag (name: string) =
        (data ()).GetProperty(name).GetBoolean()

    [<Test>]
    member _.``direct migration should copy supported data and preserve the source across restart``
        ()
        =
        flag "counts" |> should equal true
        flag "sourceUnchanged" |> should equal true
        flag "selectedProfile" |> should equal true
        flag "modKinds" |> should equal true
        flag "modsReady" |> should equal true
        flag "reversePriority" |> should equal true
        flag "categories" |> should equal true
        flag "artifactOwned" |> should equal true
        flag "credentialsExcluded" |> should equal true
        flag "restartComplete" |> should equal true

    [<Test>]
    member _.``invalid unsafe unsupported and cancelled migration should leave the target empty``
        ()
        =
        flag "emptyTargetGuard" |> should equal true
        flag "cancellation" |> should equal true
        flag "unsupportedBeforeMutation" |> should equal true
        flag "missingFile" |> should equal true
        flag "caseCollision" |> should equal true
        flag "unsafeLink" |> should equal true

    [<Test>]
    member _.``process loss on both sides of file publication should recover an empty target``() =
        flag "crashBeforePublication" |> should equal true
        flag "crashAfterPublication" |> should equal true
