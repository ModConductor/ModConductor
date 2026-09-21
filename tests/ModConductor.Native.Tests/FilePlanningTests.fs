namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type FilePlanningTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("filePlanning")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``acquisition should index metadata without reading content and keep bounded page identities separate``
        ()
        =
        flag "coldViewNotComplete" |> should equal true
        flag "initialViewDoesNotReadGameContent" |> should equal true
        flag "initialViewDoesNotRehashManagedPayloads" |> should equal true
        flag "initialUsefulPageWithinOneSecond" |> should equal true
        flag "priorityWinnerAndBasePins" |> should equal true
        flag "opaqueArchiveIsAFile" |> should equal true
        flag "boundedCursorKeepsIdentity" |> should equal true
        flag "visibilityKeepsPagingLineage" |> should equal true
        flag "cancelPreservesPrevious" |> should equal true

    [<Test>]
    member _.``shared exact copy changes should promote fallback without changing source files or profile selection``
        ()
        =
        flag "hidePromotesNext" |> should equal true
        flag "incrementalMatchesFresh" |> should equal true
        flag "labelsDoNotChangePlanPins" |> should equal true
        flag "gameFolderFallback" |> should equal true
        flag "allHiddenRemainsInspectable" |> should equal true
        flag "sharedAcrossProfiles" |> should equal true
        flag "unhideRestoresEligibility" |> should equal true
        flag "rulesDoNotChangeProfileOrSource" |> should equal true

    [<Test>]
    member _.``stale observations should refuse hiding while allowing removal of an existing exclusion``
        ()
        =
        flag "staleWriteHasNoAudit" |> should equal true
        flag "changedGameRejectsHide" |> should equal true
        flag "staleGameAllowsUnhideOnly" |> should equal true
        flag "refreshPinsChangedContent" |> should equal true
        flag "disabledCopyCanUnhideWithoutEnabling" |> should equal true
        flag "disabledCopyDoesNotEnterPlan" |> should equal true

    [<Test>]
    member _.``publication and restart should preserve historical rules without applying them to new versions``
        ()
        =
        flag "newVersionDoesNotInherit" |> should equal true
        flag "historicalCopyIsReadOnly" |> should equal true
        flag "auditRetainsExactCopyTransitions" |> should equal true
        flag "restartRequiresObservation" |> should equal true

    [<Test>]
    member _.``visibility changes should preserve original collision guards and canonical target identities``
        ()
        =
        let flag name =
            NativeObservations.report.RootElement
                .GetProperty("fileVisibility")
                .GetProperty(name: string)
                .GetBoolean()

        flag "incrementalPreservesCanonicalTargets" |> should equal true
        flag "retainedOriginalIsUnchanged" |> should equal true
        flag "hideCannotResolveInputAliases" |> should equal true
        flag "unknownCopyCannotCreateRule" |> should equal true
        flag "historyBytePagesContinueWithoutLoss" |> should equal true

    [<Test>]
    member _.``concurrent inventory and file reads should share root checks without admitting writes or caching completed checks``
        ()
        =
        flag "concurrentInventoryAndFileReads" |> should equal true

        let rootFlag name =
            NativeObservations.report.RootElement
                .GetProperty("concurrentRoots")
                .GetProperty(name: string)
                .GetBoolean()

        rootFlag "sharedReadsKeepWriteAndCloseExclusion" |> should equal true
        rootFlag "completedAndFailedReadsAreNotCached" |> should equal true
        rootFlag "writesRemainExclusiveAndClosedRootsRefuseReads" |> should equal true
