namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type GameContextTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("gameContexts")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``compiled capability policy should distinguish supported contexts from obsolete extension mechanisms``
        ()
        =
        flag "compiledCapabilitySupportsBothContexts" |> should equal true
        flag "obsoleteExtensionMechanismUnsupported" |> should equal true
        flag "archiveInspectionAvailable" |> should equal true
        flag "policyOnlyCapabilityHiddenFromUsers" |> should equal true

    [<Test>]
    member _.``portable version checks should parse fixed resources without writes or string fallbacks``
        ()
        =
        flag "structuredVersion" |> should equal true
        flag "readOnlyValidation" |> should equal true
        flag "knownFoldersRemainUnchanged" |> should equal true
        flag "malformedVersionsRefused" |> should equal true
        flag "missingDataNotValid" |> should equal true
        flag "protonHasNoHostFolders" |> should equal true

    [<Test>]
    member _.``workspace bindings should survive profile operations and reject stale or invalid replacements``
        ()
        =
        flag "workspacesShareInstallation" |> should equal true
        flag "profilesPreserveBinding" |> should equal true
        flag "staleSavePreservesBinding" |> should equal true
        flag "invalidReplacementPreservesBinding" |> should equal true

    [<Test>]
    member _.``failed checks and restart should retain identity while requiring new evidence``() =
        flag "failedRefreshRetainsEvidence" |> should equal true
        flag "refreshRestoresCurrentEvidence" |> should equal true
        flag "restartRequiresRecheck" |> should equal true
        flag "changedExecutableGetsNewEvidence" |> should equal true
