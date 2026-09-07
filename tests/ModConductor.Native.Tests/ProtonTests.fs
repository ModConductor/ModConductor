namespace ModConductor.Native.Tests

open System
open FsUnit
open NUnit.Framework

[<TestFixture>]
type ProtonTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("proton")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``prefix lookup should preserve provenance without treating mapping or prefix version as active runtime``
        ()
        =
        if OperatingSystem.IsLinux() then
            flag "defaultPrefixAndToolFound" |> should equal true
            flag "globalOnlyNotActive" |> should equal true
            flag "runtimeAndPrefixVersionsDistinct" |> should equal true
            flag "declaredRuntimeSubdirectory" |> should equal true
            flag "foreignAppRefused" |> should equal true
            flag "manualAssociationExplicit" |> should equal true
            flag "manualAliasCannotHideForeignApp" |> should equal true
        else
            flag "nativeWindowsPreserved" |> should equal true
            flag "protonUnsupported" |> should equal true

    [<Test>]
    member _.``prefix paths should follow internal redirects without host fallback or folder creation``
        ()
        =
        if OperatingSystem.IsLinux() then
            flag "prefixUserPathsLocated" |> should equal true
            flag "absentLeavesNotCreated" |> should equal true
            flag "readOnlyRegistry" |> should equal true
            flag "internalRedirectLocated" |> should equal true
            flag "externalRedirectUnavailable" |> should equal true
            flag "caseAmbiguityUnavailable" |> should equal true
            flag "unknownVariableNoHostFallback" |> should equal true
        else
            Assert.Ignore "Prefix traversal is a Linux capability."

    [<Test>]
    member _.``saved selections should survive stale edits failed refresh and engine restart``() =
        if OperatingSystem.IsLinux() then
            flag "observedToolIdentityPersisted" |> should equal true
            flag "staleDoesNotDropSelection" |> should equal true
            flag "invalidReplacementAtomic" |> should equal true
            flag "failedRefreshRetainsPins" |> should equal true
            flag "restartRetainsSelectionAndRequiresCheck" |> should equal true
        else
            Assert.Ignore "Native Windows bindings are covered by the game-context fixture."
