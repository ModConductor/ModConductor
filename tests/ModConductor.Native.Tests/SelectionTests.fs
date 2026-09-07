namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type SelectionTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("selection")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``stable multi selection moves should preserve runs and contiguous saved precedence``
        ()
        =
        flag "disabledAndContiguous" |> should equal true
        flag "stableRuns" |> should equal true
        flag "downRestoresOrder" |> should equal true
        flag "separatorMoves" |> should equal true
        flag "coherentRevision" |> should equal true

    [<Test>]
    member _.``stale and unsupported batches should leave every profile row unchanged``() =
        flag "staleAtomic" |> should equal true
        flag "constraintsAtomic" |> should equal true
        flag "membershipInvalidates" |> should equal true
        flag "profileIsolation" |> should equal true

    [<Test>]
    member _.``profile clone and deletion should preserve selection ownership``() =
        flag "cloneCopies" |> should equal true
        flag "deleteCleans" |> should equal true
        flag "currentDeleteRefused" |> should equal true

    [<Test>]
    member _.``interrupted selection commits should recover either the complete old or new state``
        ()
        =
        flag "restartPreserves" |> should equal true
        flag "beforeCommit" |> should equal true
        flag "afterCommit" |> should equal true

    [<Test>]
    member _.``v4 migration should initialize profiles without losing metadata across interruption``
        ()
        =
        flag "migrationRollback" |> should equal true
        flag "migrationPreserves" |> should equal true
