namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type OrganizationTests() =
    let flag section name =
        NativeObservations.report.RootElement
            .GetProperty(section: string)
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``combined metadata and category filters should retain group context without changing profile state``
        ()
        =
        flag "organization" "combinedAndContext" |> should equal true
        flag "organization" "filterPreservesSelection" |> should equal true
        flag "organization" "anyCategoryMembership" |> should equal true
        flag "organization" "trailingEmptyGroup" |> should equal true

    [<Test>]
    member _.``category changes should reject stale drafts and preserve missing references until explicitly removed``
        ()
        =
        flag "organization" "treeAtomic" |> should equal true
        flag "organization" "canonicalLabel" |> should equal true
        flag "organization" "draftAndMissingPreservation" |> should equal true
        flag "organization" "workspaceSharedProfileIndependent" |> should equal true
        flag "organization" "explicitReferenceRemoval" |> should equal true

    [<Test>]
    member _.``bounded query pages should reject changed query and inventory revisions``() =
        flag "organization" "metadataInvalidatesWithoutSelectionChange"
        |> should equal true

        flag "organization" "profileCursorIsolated" |> should equal true
        flag "organization" "boundedContinuation" |> should equal true
        flag "organization" "queryAndInventoryInvalidate" |> should equal true

    [<Test>]
    member _.``legacy categories should migrate atomically without merging human labels or changing profile state``
        ()
        =
        flag "categoryMigration" "rollback" |> should equal true
        flag "categoryMigration" "exactLabelsAndIsolation" |> should equal true
        flag "categoryMigration" "metadataAndProfiles" |> should equal true
        flag "categoryMigration" "stableAfterRestart" |> should equal true
