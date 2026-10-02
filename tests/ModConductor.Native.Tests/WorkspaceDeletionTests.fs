namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type WorkspaceDeletionTests() =
    let report =
        lazy (NativeObservations.report.RootElement.GetProperty "workspaceDeletion")

    let flag scenario name =
        report.Value.GetProperty(scenario: string).GetProperty(name: string).GetBoolean()

    [<Test>]
    member _.``deleting an active workspace should restore game routing and remove owned data without removing foreign files``
        ()
        =
        flag "discardActive" "routingRestored" |> should equal true
        flag "discardActive" "ownedRemoved" |> should equal true
        flag "discardActive" "registrationRemoved" |> should equal true
        flag "discardActive" "foreignPreserved" |> should equal true
        flag "discardActive" "saveDisposition" |> should equal true
        flag "discardActive" "globalPreserved" |> should equal true
        flag "discardActive" "busyRefusesWithoutDeletion" |> should equal true
        flag "discardActive" "newRoutingRefusesCleanup" |> should equal true

    [<Test>]
    member _.``deleting after restart should remove recorded deployment links and restore profile data without deploying again``
        ()
        =
        flag "activeAfterRestart" "contextNeedsRefresh" |> should equal true
        flag "activeAfterRestart" "noNewDeployment" |> should equal true
        flag "activeAfterRestart" "displacedOriginalRestored" |> should equal true
        flag "activeAfterRestart" "routingRestored" |> should equal true
        flag "activeAfterRestart" "ownedRemoved" |> should equal true
        flag "activeAfterRestart" "registrationRemoved" |> should equal true
        flag "activeAfterRestart" "foreignPreserved" |> should equal true
        flag "activeAfterRestart" "globalPreserved" |> should equal true
        flag "activeAfterRestart" "busyRefusesWithoutDeletion" |> should equal true

    [<Test>]
    member _.``moving private saves should keep existing saves and rename matching pairs across profiles``
        ()
        =
        flag "moveKeepBoth" "failedDeletionRetainsRegistration" |> should equal true
        flag "moveKeepBoth" "saveDisposition" |> should equal true
        flag "moveKeepBoth" "globalPreserved" |> should equal true
        flag "moveKeepBoth" "ownedRemoved" |> should equal true
        flag "moveKeepBoth" "registrationRemoved" |> should equal true
        flag "moveKeepBoth" "privateSaveDestination" |> should equal true

    [<Test>]
    member _.``deleting a workspace should create a known absent save folder when moving and remove only empty owned roots``
        ()
        =
        flag "createSaveFolder" "saveDisposition" |> should equal true
        flag "createSaveFolder" "ownedRemoved" |> should equal true
        flag "createSaveFolder" "registrationRemoved" |> should equal true
        report.Value.GetProperty("emptyRootRemoved").GetBoolean() |> should equal true

    [<Test>]
    member _.``cancelling setup should preserve the workspace until cancellation completes then allow deletion``
        ()
        =
        report.Value.GetProperty("unfinishedCancellationPreservesWorkspace").GetBoolean()
        |> should equal true

        report.Value.GetProperty("cancelledSetupAllowsDeletion").GetBoolean()
        |> should equal true
