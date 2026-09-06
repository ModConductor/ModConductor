namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type LibraryTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("library")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``changed versions should share unchanged files and retain exact earlier contents``() =
        flag "unchangedShared" |> should equal true
        flag "changedDistinct" |> should equal true
        flag "oldBytes" |> should equal true
        flag "oldManifestUnchanged" |> should equal true

    [<Test>]
    member _.``metadata rename should preserve shared profile inventory and survive restart``() =
        flag "sharedProfileRename" |> should equal true
        flag "staleRefused" |> should equal true
        flag "restartMetadata" |> should equal true

    [<Test>]
    member _.``published payloads should refuse ordinary writes without changing source or foreign files``
        ()
        =
        flag "ordinaryWriteRefused" |> should equal true
        flag "sourceStillWritable" |> should equal true
        flag "foreignPreserved" |> should equal true

    [<Test>]
    member _.``restart should complete only durably observed files and preserve unproved effects``
        ()
        =
        let windows =
            NativeObservations.report.RootElement.GetProperty("libraryWindows").EnumerateArray()
            |> Seq.toList

        let window name =
            windows |> List.find (fun item -> item.GetProperty("window").GetString() = name)

        let effect, observed = window "effect", window "observed"

        effect.GetProperty("unpublishedBeforeRecovery").GetBoolean()
        |> should equal true

        effect.GetProperty("phaseBefore").GetString() |> should equal "interrupted"
        effect.GetProperty("resumed").GetBoolean() |> should equal false
        effect.GetProperty("payloadsPreserved").GetInt32() |> should equal 1

        observed.GetProperty("unpublishedBeforeRecovery").GetBoolean()
        |> should equal true

        observed.GetProperty("phaseBefore").GetString() |> should equal "observed"
        observed.GetProperty("resumed").GetBoolean() |> should equal true

    [<Test>]
    member _.``another owner and cancellation should respect the active file worker and commit boundary``
        ()
        =
        let windows =
            NativeObservations.report.RootElement.GetProperty("libraryWindows").EnumerateArray()
            |> Seq.toList

        let window name =
            windows |> List.find (fun item -> item.GetProperty("window").GetString() = name)

        let live, cancel = window "live", window "cancel"
        live.GetProperty("liveRefused").GetBoolean() |> should equal true
        live.GetProperty("unpublishedWhileLive").GetBoolean() |> should equal true
        live.GetProperty("committed").GetBoolean() |> should equal true

        live.GetProperty("cancelAfterCommitKeepsResult").GetBoolean()
        |> should equal true

        cancel.GetProperty("cancelDurable").GetBoolean() |> should equal true
        cancel.GetProperty("retryWhileClosingRefused").GetBoolean() |> should equal true
        cancel.GetProperty("committed").GetBoolean() |> should equal false
        cancel.GetProperty("workerResult").GetString() |> should equal "cancelled"

    [<Test>]
    member _.``concurrent source edits and changed observed payloads should refuse publication without removing data``
        ()
        =
        let windows =
            NativeObservations.report.RootElement.GetProperty("libraryWindows").EnumerateArray()
            |> Seq.toList

        let window name =
            windows |> List.find (fun item -> item.GetProperty("window").GetString() = name)

        let source, payload = window "source-change", window "payload-change"
        source.GetProperty("committed").GetBoolean() |> should equal false
        source.GetProperty("workerResult").GetString() |> should equal "refused"
        payload.GetProperty("committed").GetBoolean() |> should equal false
        payload.GetProperty("changedPayloadPreserved").GetBoolean() |> should equal true

    [<Test>]
    member _.``termination around rename should keep both profile views on the complete old or new metadata``
        ()
        =
        let data = NativeObservations.report.RootElement.GetProperty("libraryIdentity")

        let before, after =
            data.GetProperty("rename-before"), data.GetProperty("rename-after")

        before.GetProperty("profilesAgree").GetBoolean() |> should equal true
        after.GetProperty("profilesAgree").GetBoolean() |> should equal true
        before.GetProperty("revision").GetInt64() |> should equal 0L
        before.GetProperty("name").GetString() |> should equal "Original"
        before.GetProperty("notes").GetString() |> should equal "Before"
        after.GetProperty("revision").GetInt64() |> should equal 1L
        after.GetProperty("name").GetString() |> should equal "Renamed"
        after.GetProperty("notes").GetString() |> should equal "After"

    [<Test>]
    member _.``replacements and library overlap should refuse without adopting or deleting data``
        ()
        =
        let data = NativeObservations.report.RootElement.GetProperty("libraryIdentity")
        data.GetProperty("storeOverlapRefused").GetBoolean() |> should equal true
        data.GetProperty("replacementUnproved").GetBoolean() |> should equal true
        data.GetProperty("replacementPublishRefused").GetBoolean() |> should equal true
        data.GetProperty("replacementPreserved").GetBoolean() |> should equal true
        data.GetProperty("oldVersionRetained").GetBoolean() |> should equal true
        data.GetProperty("changedPayloadRefused").GetBoolean() |> should equal true
        data.GetProperty("changedPayloadNotDeleted").GetBoolean() |> should equal true
        data.GetProperty("tinyScanIsLimited").GetBoolean() |> should equal true
