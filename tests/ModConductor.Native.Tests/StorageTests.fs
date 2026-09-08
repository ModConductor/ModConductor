namespace ModConductor.Native.Tests

open System.Text.Json
open FsUnit
open NUnit.Framework

[<TestFixture>]
type StorageTests() =
    let field (name: string) =
        NativeObservations.report.RootElement.GetProperty("storage").GetProperty name

    let text (value: JsonElement) (name: string) = value.GetProperty(name).GetString()
    let number (value: JsonElement) (name: string) = value.GetProperty(name).GetInt64()
    let flag (value: JsonElement) (name: string) = value.GetProperty(name).GetBoolean()

    [<Test>]
    member _.``interrupted schema migration should preserve the old committed state and upgrade on restart``
        ()
        =
        let migration = field "migration"
        number migration "before" |> should equal 1L
        number migration "afterInterruption" |> should equal 1L
        number migration "partialTables" |> should equal 0L
        number migration "committedRows" |> should equal 1L

        number migration "afterUpgrade"
        |> should be (greaterThan (number migration "before"))

        number migration "replayRevision" |> should equal 1L

    [<Test>]
    member _.``stale root revisions should fail while completed creation replays unchanged across restart``
        ()
        =
        let state = field "lifecycle"
        flag state "stalePrepare" |> should equal true
        flag state "staleApply" |> should equal true
        flag state "staleComplete" |> should equal true
        flag state "replayUnchanged" |> should equal true
        flag state "restartUnchanged" |> should equal true
        text state "phase" |> should equal "complete"
        number state "workspaceRevision" |> should equal 1L

    [<Test>]
    member _.``interrupted intent without durable file identity should remain unresolved rather than adopt a name``
        ()
        =
        let intent = field "intent"
        text intent "phase" |> should equal "unresolved"
        number intent "workspaceRevision" |> should equal 0L
        flag intent "fileExists" |> should equal false
        flag intent "listedForRecovery" |> should equal true
        let effect = field "effect"
        text effect "phase" |> should equal "unresolved"
        number effect "workspaceRevision" |> should equal 0L
        flag effect "fileExists" |> should equal true

        effect.GetProperty("markerIdentity").ValueKind
        |> should equal JsonValueKind.Null

    [<Test>]
    member _.``recorded native file identity should allow observed creation to complete after owner termination``
        ()
        =
        let observed = field "observed"
        flag observed "listedForRecovery" |> should equal true
        text observed "phase" |> should equal "complete"
        number observed "workspaceRevision" |> should equal 1L
        flag observed "fileExists" |> should equal true

        observed.GetProperty("markerIdentity").ValueKind
        |> should equal JsonValueKind.Object

    [<Test>]
    member _.``recovery should preserve changed content and replacement files even when replacement bytes match``
        ()
        =
        let changed = field "changed"
        text changed "phase" |> should equal "unresolved"
        number changed "workspaceRevision" |> should equal 0L
        flag changed "foreignPreserved" |> should equal true
        let replaced = field "replaced"
        text replaced "phase" |> should equal "unresolved"
        number replaced "workspaceRevision" |> should equal 0L
        flag replaced "foreignPreserved" |> should equal true

    [<Test>]
    member _.``another live owner should retain its receipt and finish without recovery interference``
        ()
        =
        let live = field "live"
        flag live "recoveryRefused" |> should equal true
        flag live "notAbandoned" |> should equal true
        text live "phase" |> should equal "complete"
        number live "workspaceRevision" |> should equal 1L

    [<Test>]
    member _.``blocked file work should not stop runtime commits or release its live owner during close``
        ()
        =
        let slow = field "slow"
        number slow "progressWhileFileBlocked" |> should equal 1L
        flag slow "closeRefused" |> should equal true
        flag slow "featureAvailableAfterRefusedClose" |> should equal true
        flag slow "sameOwnerListed" |> should equal false
        number slow "otherOwnerRuntimeRevision" |> should equal 2L
        flag slow "recoveryRefused" |> should equal true
        flag slow "notAbandoned" |> should equal true
        text slow "phase" |> should equal "complete"

    [<Test>]
    member _.``a preexisting identity file should remain foreign after a failed create``() =
        let foreign = field "foreign"
        text foreign "phase" |> should equal "unresolved"
        number foreign "workspaceRevision" |> should equal 0L
        text foreign "contents" |> should equal "foreign"

    [<Test>]
    member _.``replacement of a selected root should refuse the write and preserve both directories``
        ()
        =
        let moved = field "movedRoot"
        text moved "phase" |> should equal "unresolved"
        number moved "workspaceRevision" |> should equal 0L
        flag moved "replacementUntouched" |> should equal true
        flag moved "originalUntouched" |> should equal true
