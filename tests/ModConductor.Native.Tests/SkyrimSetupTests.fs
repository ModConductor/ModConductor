namespace ModConductor.Native.Tests

open FsUnit
open NUnit.Framework

[<TestFixture>]
type SkyrimSetupTests() =
    let flag name =
        NativeObservations.report.RootElement
            .GetProperty("skyrimSetup")
            .GetProperty(name: string)
            .GetBoolean()

    [<Test>]
    member _.``confirmed setup intent should survive restart without crossing workspaces``() =
        flag "intentSurvivesRestart" |> should equal true
        flag "fnisChoiceSurvivesRestart" |> should equal true
        flag "planConsentSurvivesRestart" |> should equal true
        flag "profileIntentIsWorkspaceScoped" |> should equal true
