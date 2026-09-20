namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type DeploymentBackendTests() =
    let flag group name =
        NativeObservations.report.RootElement
            .GetProperty(group: string)
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``checked deployment should preserve originals and expose the same logical file view across switches``
        ()
        =
        for name in
            [ "contextDerivedTarget"
              "caseVariantSingleEntry"
              "missingParentCreated"
              "activeReaderReconstructsBase"
              "originalRestored"
              "ownedParentRemoved"
              "unrelatedBasePreserved"
              "retainedGenerationReactivated"
              "sourceBytesPreserved" ] do
            flag "deploymentBackend" name |> should equal true

    [<Test>]
    member _.``interrupted parent changes should restore known identities and refuse unrecorded creations``
        ()
        =
        for name in
            [ "removedParentInterruptionRecorded"
              "pendingReaderUnavailable"
              "removedParentRestored"
              "unknownCreatedParentRefused"
              "cancelledPreparationNoReceipt"
              "stalePreparationNoEffects"
              "cacheEvictionRemovedOriginalStore" ] do
            flag "deploymentBackend" name |> should equal true

    [<Test>]
    member _.``changing an installation should preserve historical targets and exclude outstanding effects``
        ()
        =
        for name in
            [ "refreshedEvidenceKeepsTargetOwnership"
              "newInstallationAfterDeactivation"
              "oldReceiptCannotRetarget"
              "otherActiveContextRefused"
              "otherPendingContextRefused" ] do
            flag "deploymentBackend" name |> should equal true

    [<Test>]
    member _.``process observation should refuse the selected executable without blocking an unrelated same name``
        ()
        =
        for name in
            [ "matchingNativeProcessRefused"
              "unrelatedSameNameAllowed"
              "stoppedNativeProcessAllowed" ] do
            flag "deploymentProcesses" name |> should equal true
