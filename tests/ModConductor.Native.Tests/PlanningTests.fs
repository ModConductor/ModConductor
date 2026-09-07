namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type PlanningTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("planning")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``ordered layers should retain alternatives and promote the next pinned winner``() =
        flag "layeredOverride" |> should equal true
        flag "consistentDirectorySpelling" |> should equal true
        flag "disabledPromotes" |> should equal true
        flag "versionPinsRetained" |> should equal true
        flag "unchangedPayloadShared" |> should equal true
        flag "canonicalEnumeration" |> should equal true
        flag "changedInputsRefused" |> should equal true

    [<Test>]
    member _.``exact source mappings should retain roots and archive container annotations``() =
        flag "longestMappingAcrossRoots" |> should equal true
        flag "archiveRemainsContainer" |> should equal true
        flag "archiveGenerationChangesInput" |> should equal true
        flag "sourceMappingIsOrdinal" |> should equal true
        flag "ambiguousMappingBlocked" |> should equal true
        flag "missingRootBlocked" |> should equal true
        flag "baseGenerationChangesInput" |> should equal true

    [<Test>]
    member _.``target policies should distinguish normal overrides from unresolved aliases and structural conflicts``
        ()
        =
        flag "sameLayerAliasBlocked" |> should equal true
        flag "sensitiveNamesRemainDistinct" |> should equal true
        flag "directoryAliasBlocked" |> should equal true
        flag "competingTieBlocked" |> should equal true
        flag "directorySpellingTieBlocked" |> should equal true
        flag "fileDirectoryBlocked" |> should equal true
        flag "unicodePolicyControlsOverrides" |> should equal true
        flag "targetNamesValidated" |> should equal true
        flag "nativeBackslashPreserved" |> should equal true

    [<Test>]
    member _.``explicit writable targets should consume immutable initial seeds without changing retained plans``
        ()
        =
        flag "writableFileConsumesWinner" |> should equal true
        flag "writableSubtreeKeepsSiblings" |> should equal true
        flag "wholeRootWritableProjection" |> should equal true
        flag "emptySinkHasNoSeed" |> should equal true
        flag "overlappingSinksBlocked" |> should equal true
        flag "sinkStructureBlocked" |> should equal true
        flag "sinkCannotHideCollision" |> should equal true
        flag "newSeedDoesNotAlterOldPlan" |> should equal true
        flag "writableDeclarationChangesInput" |> should equal true
        flag "emptySiblingSpellingBlocked" |> should equal true
        flag "sensitiveWritableDirectoriesRemainDistinct" |> should equal true
        flag "subtreeSpellingParticipates" |> should equal true
        flag "ordinaryDirectorySpellingRemainsAuthoritative" |> should equal true
        flag "consistentEmptyDirectoryStructure" |> should equal true
        flag "nestedWritableSpellingUsesCanonicalParents" |> should equal true

    [<Test>]
    member _.``incomplete or inconsistent pins should block retained plan validation``() =
        flag "incompleteSelectionRefused" |> should equal true
        flag "partialManifestBlocked" |> should equal true
        flag "missingVersionBlocked" |> should equal true
        flag "wrongModPinBlocked" |> should equal true
        flag "payloadIdentityConflictBlocked" |> should equal true
        flag "invalidContentBlocked" |> should equal true
