namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type WorkspaceTests() =
    let data () =
        NativeObservations.report.RootElement.GetProperty "workspaces"

    let flag (name: string) =
        (data ()).GetProperty(name).GetBoolean()

    let window (name: string) (mode: string) =
        (data ()).GetProperty(name).EnumerateArray()
        |> Seq.find (fun value -> value.GetProperty("window").GetString() = mode)

    [<Test>]
    member _.``profile clone rename selection and delete should persist exactly across explicit folder reopen``
        ()
        =
        flag "emptyAtCreation" |> should equal true
        flag "cloneKeepsSelection" |> should equal true
        flag "selectedRename" |> should equal true
        flag "staleRefused" |> should equal true
        flag "selectedDeleteRefused" |> should equal true
        (data ()).GetProperty("finalRevision").GetInt64() |> should equal 5L
        flag "selectedCopy" |> should equal true
        flag "restartSelection" |> should equal true
        flag "restartContents" |> should equal true

    [<Test>]
    member _.``profile changes should stay within the owning workspace and leave unrelated files unchanged``
        ()
        =
        flag "crossWorkspaceDeleteRefused" |> should equal true
        flag "crossWorkspaceCloneRefused" |> should equal true
        flag "profileFilesAbsent" |> should equal true
        flag "foreignPreserved" |> should equal true

    [<Test>]
    member _.``changed roots replaced markers and unregistered folders should refuse without adoption``
        ()
        =
        flag "changedRootRefused" |> should equal true
        flag "replacementPreserved" |> should equal true
        flag "changedMarkerRefused" |> should equal true
        flag "markerReplacementPreserved" |> should equal true
        flag "unregisteredRefused" |> should equal true

    [<Test>]
    member _.``workspace creation should retain its name and recover only an observed owned effect``
        ()
        =
        let intent = window "creationWindows" "intent"
        intent.GetProperty("nameRetained").GetBoolean() |> should equal true
        intent.GetProperty("ready").GetBoolean() |> should equal false
        intent.GetProperty("files").GetInt32() |> should equal 0
        let effect = window "creationWindows" "effect"
        effect.GetProperty("nameRetained").GetBoolean() |> should equal true
        effect.GetProperty("ready").GetBoolean() |> should equal false
        effect.GetProperty("files").GetInt32() |> should equal 1
        let observed = window "creationWindows" "observed"
        observed.GetProperty("nameRetained").GetBoolean() |> should equal true
        observed.GetProperty("ready").GetBoolean() |> should equal true
        observed.GetProperty("files").GetInt32() |> should equal 1

    [<Test>]
    member _.``opening the same state should not recover or interrupt another live workspace creator``
        ()
        =
        let live = window "creationWindows" "live"
        live.GetProperty("liveRecoveryRefused").GetBoolean() |> should equal true
        live.GetProperty("ready").GetBoolean() |> should equal true

    [<Test>]
    member _.``termination around a profile commit should expose the whole old or new metadata state``
        ()
        =
        let before = window "metadataWindows" "before-commit"
        before.GetProperty("revision").GetInt64() |> should equal 0L
        before.GetProperty("profiles").GetInt32() |> should equal 0
        before.GetProperty("selectionMatches").GetBoolean() |> should equal true
        before.GetProperty("files").GetInt32() |> should equal 1
        let after = window "metadataWindows" "after-commit"
        after.GetProperty("revision").GetInt64() |> should equal 1L
        after.GetProperty("profiles").GetInt32() |> should equal 1
        after.GetProperty("selectionMatches").GetBoolean() |> should equal true
        after.GetProperty("files").GetInt32() |> should equal 1
