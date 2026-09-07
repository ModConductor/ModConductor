namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type SteamDiscoveryTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("steamDiscovery")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``linked libraries should deduplicate installations while retaining each observed origin``
        ()
        =
        flag "uncachedAppFound" |> should equal true
        flag "linksDeduplicateWithOrigins" |> should equal true
        flag "originEvidenceRetained" |> should equal true
        flag "deterministicSearch" |> should equal true
        flag "readOnlySearch" |> should equal true
        flag "emptyMetadataAccepted" |> should equal true

    [<Test>]
    member _.``broken library metadata should not hide valid games or escape declared installation roots``
        ()
        =
        flag "unavailableLibraryIsolated" |> should equal true
        flag "badManifestAndStaleCacheIsolated" |> should equal true
        flag "foreignAppRefused" |> should equal true
        flag "unsafeInstallDirectoriesRefused" |> should equal true
        flag "metadataDoesNotLoadIncludes" |> should equal true
        flag "oversizedDefaultIsolated" |> should equal true
        flag "invalidKeysAndMissingValuesRefused" |> should equal true

    [<Test>]
    member _.``bounded and cancelled searches should remain explicit without losing collected candidates``
        ()
        =
        flag "oversizedMetadataIsolated" |> should equal true
        flag "partialSearchDeclared" |> should equal true
        flag "cancelledSearchStops" |> should equal true
