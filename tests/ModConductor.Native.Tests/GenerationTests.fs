namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type GenerationTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("generations")
            .GetProperty(name: string)
            .GetBoolean()

    let correction name =
        NativeObservations.report.RootElement
            .GetProperty("generationCorrections")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``generation switching should share exact managed payloads and leave base files in place``
        ()
        =
        flag "baseUntouched" |> should equal true
        flag "deploymentDoesNotRehashManagedPayloads" |> should equal true
        flag "deploymentChecksBaseMetadataWithoutReadingContent" |> should equal true
        flag "mixedBranchUsesLeaf" |> should equal true
        flag "managedDirectoryLink" |> should equal true
        flag "individualCollisionLink" |> should equal true
        flag "exactVisibilityPin" |> should equal true
        flag "unchangedPayloadShared" |> should equal true
        flag "onlyChangedPublicationBytes" |> should equal true
        flag "newVersionDoesNotInheritHide" |> should equal true
        flag "secondaryCopiedOnce" |> should equal true
        flag "addedAndRemoved" |> should equal true
        flag "baseOnlyRestored" |> should equal true

    [<Test>]
    member _.``retained generations should recover without rolling back mutable copies or altering immutable sources``
        ()
        =
        correction "partialSeedNotPublished" |> should equal true
        correction "seedRetryPublishesComplete" |> should equal true
        correction "seedPublicationNeverOverwrites" |> should equal true
        flag "interruptedSwitchRecorded" |> should equal true
        flag "sourceBytesAndPermissionsUnchanged" |> should equal true
        flag "ordinaryWritesRefused" |> should equal true
        flag "writableIsolated" |> should equal true
        flag "mutableNotRolledBack" |> should equal true
        flag "retainedRollback" |> should equal true
        flag "originalRetained" |> should equal true
        flag "oldGenerationRetained" |> should equal true

    [<Test>]
    member _.``deployment should refuse live processes stale inputs changed base and foreign targets without effects``
        ()
        =
        correction "reusedSecondaryNeedsNoCopyCapacity" |> should equal true
        correction "secondaryEntriesCharged" |> should equal true
        correction "targetCostsRemainOnTheirDevice" |> should equal true
        correction "workingActivationCharged" |> should equal true
        correction "capacityOverflowRefused" |> should equal true
        flag "newGenerationRequiresStamp" |> should equal true
        flag "staleNewGenerationWithoutStampRefused" |> should equal true
        flag "closePreservesActivePreparation" |> should equal true
        flag "runningGameRefused" |> should equal true
        flag "wholeRootRefusedWithoutEffects" |> should equal true
        flag "controlledLowSpaceRefused" |> should equal true
        flag "staleSelectionRefused" |> should equal true
        flag "changedBaseRefused" |> should equal true
        flag "foreignTargetRefused" |> should equal true
