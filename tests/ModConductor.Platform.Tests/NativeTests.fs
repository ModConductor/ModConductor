namespace ModConductor.Platform.Tests

open System
open System.Diagnostics
open System.IO
open System.Text.Json
open FsUnit
open NUnit.Framework

[<TestFixture>]
type NativeTests() =
    let mutable report: JsonDocument = null
    let mutable primary = ""
    let mutable secondary = ""

    let field name =
        report.RootElement.GetProperty(name: string)

    let entries name =
        (field name).GetProperty("entries").EnumerateArray() |> Seq.toList

    let names name =
        entries name |> List.map (fun item -> item.GetProperty("name").GetString())

    let problems name =
        (field name).GetProperty("diagnostics").EnumerateArray()
        |> Seq.map (fun item -> item.GetProperty("problem").GetString())
        |> Seq.toList

    let linux () = (field "os").GetString() = "linux"

    let identity (item: JsonElement) =
        item.GetProperty("identity").GetProperty("device").GetString(),
        item.GetProperty("identity").GetProperty("low").GetUInt64(),
        item.GetProperty("identity").GetProperty("high").GetUInt64()

    [<OneTimeSetUp>]
    member _.LoadNativeObservations() =
        let executable = Environment.GetEnvironmentVariable "MC_PLATFORM_FIXTURE"

        if
            String.IsNullOrWhiteSpace executable
            || not (Path.IsPathFullyQualified executable)
        then
            invalidOp "Set MC_PLATFORM_FIXTURE to the published native fixture executable."

        primary <-
            Path.Combine(
                Environment.CurrentDirectory,
                ".agent-workspace",
                "platform-fixtures-" + Guid.NewGuid().ToString("N")
            )

        Directory.CreateDirectory primary |> ignore

        let info =
            ProcessStartInfo(
                executable,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            )

        info.ArgumentList.Add primary
        let secondParent = Environment.GetEnvironmentVariable "MC_SECOND_FIXTURE_ROOT"

        if not (String.IsNullOrWhiteSpace secondParent) then
            if not (Path.IsPathFullyQualified secondParent) then
                invalidOp "The second fixture root must be absolute."

            secondary <- Path.Combine(secondParent, "mc-platform-" + Guid.NewGuid().ToString("N"))
            Directory.CreateDirectory secondary |> ignore
            info.ArgumentList.Add secondary

        use child = Process.Start info

        let output, errors =
            child.StandardOutput.ReadToEndAsync(), child.StandardError.ReadToEndAsync()

        if not (child.WaitForExit 60000) then
            child.Kill(true)
            invalidOp "The native fixture timed out."

        let text = output.GetAwaiter().GetResult()

        if child.ExitCode <> 0 then
            invalidOp (errors.GetAwaiter().GetResult() + Environment.NewLine + text)

        let evidence = Environment.GetEnvironmentVariable "MC_PLATFORM_REPORT"

        if not (String.IsNullOrWhiteSpace evidence) then
            File.WriteAllText(evidence, text)

        report <- JsonDocument.Parse text

    [<OneTimeTearDown>]
    member _.RemoveOwnedFixtures() =
        if not (isNull report) then
            report.Dispose()

        for path in [ primary; secondary ] do
            if path <> "" && Directory.Exists path then
                Directory.Delete(path, true)

    [<Test>]
    member _.``the fixture should execute native code rather than a managed substitute``() =
        (field "nativeAot").GetBoolean() |> should equal true

    [<Test>]
    member _.``selected target rules should diagnose collisions without changing source names``() =
        names "sourceNames" |> should contain "MixedCase.txt"

        names "windowsNames"
        |> List.sort
        |> should equal (names "sourceNames" |> List.sort)

        if linux () then
            names "sourceNames" |> should contain "mixedcase.txt"
            problems "sourceNames" |> should be Empty
            problems "windowsNames" |> should contain "target-collision"
            problems "windowsNames" |> should contain "file-directory-conflict"
        else
            problems "sourceNames" |> should be Empty
            problems "windowsNames" |> should be Empty

    [<Test>]
    member _.``unicode normalization should remain a selected policy rather than rename source entries``
        ()
        =
        names "sourceNames" |> should contain "Caf\u00e9.txt"
        names "sourceNames" |> should contain "Cafe\u0301.txt"
        names "sourceNames" |> should contain "日本語.txt"

        names "normalizedNames"
        |> List.sort
        |> should equal (names "sourceNames" |> List.sort)

        problems "normalizedNames" |> should contain "target-collision"

    [<Test>]
    member _.``linux backslashes and windows reserved source names should survive with target diagnostics``
        ()
        =
        if not (linux ()) then
            Assert.Ignore "These source names require the Linux fixture."

        names "sourceNames" |> should contain "native\\backslash"
        names "sourceNames" |> should contain "NUL.txt"
        names "sourceNames" |> should contain "trailing."
        problems "windowsNames" |> should contain "invalid-target-name"

    [<Test>]
    member _.``a selected linked root and contained aliases should return the actual target and file identity``
        ()
        =
        (field "inside").GetProperty("root").GetString()
        |> should equal ((field "actualSelectedTarget").GetString())

        problems "inside" |> should be Empty

        let original =
            entries "inside"
            |> List.find (fun entry -> entry.GetProperty("name").GetString() = "content/file")

        let hard =
            entries "inside"
            |> List.find (fun entry -> entry.GetProperty("name").GetString() = "content/hard")

        let alias =
            entries "inside"
            |> List.find (fun entry -> entry.GetProperty("name").GetString() = "alias/file")

        identity hard |> should equal (identity original)
        identity alias |> should equal (identity original)

        let selectedAlias =
            entries "inside"
            |> List.find (fun entry ->
                entry.GetProperty("name").GetString() = "selected-alias/file")

        identity selectedAlias |> should equal (identity original)

        alias.GetProperty("resolved").GetString()
        |> should equal (original.GetProperty("resolved").GetString())

    [<Test>]
    member _.``escaping links and cycles should be refused before outside entries are returned``() =
        problems "blockedLinks" |> should contain "outside-root"

        let chain =
            (field "blockedLinks").GetProperty("diagnostics").EnumerateArray()
            |> Seq.find (fun item -> item.GetProperty("path").GetString() = "chain-escape")

        chain.GetProperty("problem").GetString() |> should equal "outside-root"
        problems "blockedLinks" |> should contain "link-cycle"

        let selfCycle =
            (field "blockedLinks").GetProperty("diagnostics").EnumerateArray()
            |> Seq.find (fun item -> item.GetProperty("path").GetString() = "self-cycle")

        selfCycle.GetProperty("problem").GetString() |> should equal "link-cycle"

        names "blockedLinks"
        |> List.exists (fun name -> name.Contains "must-not-enumerate")
        |> should equal false

    [<Test>]
    member _.``caller inspection budgets should report incomplete traversal including failed candidates``
        ()
        =
        problems "bounded" |> should contain "limit-exceeded"
        (entries "bounded").Length <= 2 |> should equal true

        if linux () then
            problems "failedBudget" |> should contain "limit-exceeded"
            (problems "failedBudget").Length <= 3 |> should equal true
            entries "failedBudget" |> should be Empty

    [<Test>]
    member _.``passive facts should not invent write or link capabilities or change a directory``
        ()
        =
        (field "entriesAfterPassive").GetInt32() |> should equal 0
        let passive = field "passive"
        passive.GetProperty("write").GetString() |> should equal "unknown"
        passive.GetProperty("hardLink").GetString() |> should equal "unknown"

        passive.GetProperty("distinctCaseNames").ValueKind
        |> should equal JsonValueKind.Null

    [<Test>]
    member _.``owned active probes should exercise rename and links and remove their files``() =
        let active = field "active"
        active.GetProperty("write").GetString() |> should equal "observed"
        active.GetProperty("rename").GetString() |> should equal "observed"
        active.GetProperty("hardLink").GetString() |> should equal "observed"
        active.GetProperty("longPath").GetString() |> should equal "observed"
        active.GetProperty("testedPathLength").GetInt32() > 260 |> should equal true
        active.GetProperty("metadataPreservation").GetString() |> should equal "unknown"
        active.GetProperty("reflink").GetString() |> should equal "unknown"
        (field "entriesAfterActive").GetInt32() |> should equal 0

        if linux () then
            (field "readOnly").GetProperty("write").GetString() |> should equal "refused"

    [<Test>]
    member _.``actual devices should distinguish successful same volume links from cross volume refusal``
        ()
        =
        let same = field "samePair"
        same.GetProperty("devices").GetString() |> should equal "same"
        same.GetProperty("hardLink").GetString() |> should equal "observed"
        let cross = field "crossPair"

        if cross.ValueKind = JsonValueKind.Null then
            Assert.Ignore
                "Set MC_SECOND_FIXTURE_ROOT to a separate owned filesystem for cross-device qualification."

        cross.GetProperty("devices").GetString() |> should equal "different"
        cross.GetProperty("hardLink").GetString() |> should equal "refused"

        (field "active").GetProperty("identity").GetProperty("device").GetString()
        |> should
            not'
            (equal ((field "secondRoot").GetProperty("identity").GetProperty("device").GetString()))

    [<Test>]
    member _.``special entries should be refused instead of opened as regular files``() =
        if not (linux ()) then
            Assert.Ignore "This fixture exercises a Linux FIFO."

        problems "special" |> should contain "unsupported-entry"
        entries "special" |> should be Empty
