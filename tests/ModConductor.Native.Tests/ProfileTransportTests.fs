namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type ProfileTransportTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("profileTransport")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``import should restore modified selected files and explicit deletion``() =
        flag "patchAndDeletion" |> should equal true
        flag "effectiveFiles" |> should equal true
        flag "localPayload" |> should equal true
        flag "savesOptIn" |> should equal true
        flag "artworkRestored" |> should equal true

    [<Test>]
    member _.``repeated transport should preserve patch representation``() =
        flag "stableRepresentation" |> should equal true
        flag "canonicalZipContent" |> should equal true

    [<Test>]
    member _.``missing exact archive should not create a profile``() =
        flag "missingExactSourceDoesNotCreateProfile" |> should equal true
        flag "unsafePathRejected" |> should equal true
