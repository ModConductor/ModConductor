namespace ModConductor.Settings.Tests

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open FsUnit
open NUnit.Framework
open ModConductor.Settings

[<TestFixture>]
type SettingsTests() =
    let directory () =
        Directory.CreateDirectory(
            Path.Combine(Path.GetTempPath(), "mc-settings-" + Guid.NewGuid().ToString("N"))
        )

    let value =
        function
        | Ok result -> result
        | Error error -> invalidOp (string error)

    let error =
        function
        | Error result -> result
        | Ok result -> invalidOp (string result)

    let presentation appearance scale contrast =
        { Appearance = appearance
          TextScale = scale
          InterfaceScale = 1.0
          Contrast = contrast }

    [<Test>]
    member _.``missing application and workspace files should use their scoped defaults``() =
        let root = directory ()

        try
            let workspace = Directory.CreateDirectory(Path.Combine(root.FullName, "workspace"))
            let owner = SettingsOwner root.FullName
            let application = owner.Read SettingsScope.Application |> value
            let scoped = owner.Read(SettingsScope.Workspace workspace.FullName) |> value
            application.InheritsApplication |> should equal false
            scoped.InheritsApplication |> should equal true
            application.Presentation |> should equal scoped.Presentation
            application.CheckUpdatesOnStartup |> should equal true
        finally
            root.Delete true

    [<Test>]
    member _.``application and workspace settings should round trip without crossing scopes``() =
        task {
            let root = directory ()

            try
                let workspace = Directory.CreateDirectory(Path.Combine(root.FullName, "workspace"))
                let operational = Path.Combine(root.FullName, "state.db")
                File.WriteAllBytes(operational, [| 1uy; 2uy; 3uy |])
                let owner = SettingsOwner root.FullName

                let application =
                    { Presentation = presentation Appearance.Dark 1.25 Contrast.Standard
                      InheritsApplication = false
                      CheckUpdatesOnStartup = false }

                let scoped =
                    { Presentation =
                        { presentation Appearance.Light 1.5 Contrast.High with
                            InterfaceScale = 0.9 }
                      InheritsApplication = false
                      CheckUpdatesOnStartup = false }

                let! _ = owner.Save(SettingsScope.Application, application, CancellationToken.None)

                let! _ =
                    owner.Save(
                        SettingsScope.Workspace workspace.FullName,
                        scoped,
                        CancellationToken.None
                    )

                owner.Read SettingsScope.Application |> value |> should equal application

                owner.Read(SettingsScope.Workspace workspace.FullName)
                |> value
                |> should
                    equal
                    { scoped with
                        CheckUpdatesOnStartup = true }

                let workspaceText =
                    File.ReadAllText(Path.Combine(workspace.FullName, "mod-conductor.toml"))

                workspaceText.Contains("[presentation]", StringComparison.Ordinal)
                |> should equal true

                workspaceText.Contains("check_updates_on_startup", StringComparison.Ordinal)
                |> should equal false

                File.ReadAllBytes operational |> should equal [| 1uy; 2uy; 3uy |]
            finally
                root.Delete true
        }
        :> Task

    [<Test>]
    member _.``workspace inheritance should persist without copying application values``() =
        task {
            let root = directory ()

            try
                let workspace = Directory.CreateDirectory(Path.Combine(root.FullName, "workspace"))
                let owner = SettingsOwner root.FullName

                let inherited =
                    { Presentation = presentation Appearance.Dark 1.5 Contrast.High
                      InheritsApplication = true
                      CheckUpdatesOnStartup = true }

                let! _ =
                    owner.Save(
                        SettingsScope.Workspace workspace.FullName,
                        inherited,
                        CancellationToken.None
                    )

                let loaded = owner.Read(SettingsScope.Workspace workspace.FullName) |> value
                loaded.InheritsApplication |> should equal true

                File.ReadAllText(Path.Combine(workspace.FullName, "mod-conductor.toml"))
                |> should equal "version = 1\n"
            finally
                root.Delete true
        }
        :> Task

    [<TestCase("version = 1\nversion = 1\n[presentation]\nappearance = \"system\"\ntext_scale = 1.0\ncontrast = \"system\"\n")>]
    [<TestCase("version = 1\n[presentation\nappearance = \"system\"\n")>]
    member _.``malformed or duplicate TOML should be rejected``(text: string) =
        let root = directory ()

        try
            File.WriteAllText(Path.Combine(root.FullName, "settings.toml"), text)

            match SettingsOwner(root.FullName).Read SettingsScope.Application |> error with
            | SettingsError.InvalidDocument _ -> ()
            | other -> Assert.Fail($"Unexpected result: {other}")
        finally
            root.Delete true

    [<Test>]
    member _.``unsupported document versions should be rejected``() =
        let root = directory ()

        try
            File.WriteAllText(
                Path.Combine(root.FullName, "settings.toml"),
                "version = 2\n[presentation]\nappearance = \"system\"\ntext_scale = 1.0\ncontrast = \"system\"\n"
            )

            SettingsOwner(root.FullName).Read SettingsScope.Application
            |> error
            |> should equal (SettingsError.UnsupportedVersion 2L)
        finally
            root.Delete true

    [<Test>]
    member _.``unsupported interface size should not replace saved settings``() =
        task {
            let root = directory ()

            try
                let owner = SettingsOwner root.FullName

                let previous =
                    { Presentation = presentation Appearance.Light 1.0 Contrast.System
                      InheritsApplication = false
                      CheckUpdatesOnStartup = true }

                let invalid =
                    { previous with
                        Presentation =
                            { previous.Presentation with
                                InterfaceScale = 0.8 } }

                let! _ = owner.Save(SettingsScope.Application, previous, CancellationToken.None)

                let! rejected =
                    owner.Save(SettingsScope.Application, invalid, CancellationToken.None)

                rejected
                |> error
                |> should
                    equal
                    (SettingsError.InvalidValue "The interface scale value is not supported.")

                owner.Read SettingsScope.Application |> value |> should equal previous
            finally
                root.Delete true
        }
        :> Task

    [<Test>]
    member _.``file size depth and encoding limits should reject bounded input``() =
        let root = directory ()

        try
            let file = Path.Combine(root.FullName, "settings.toml")
            File.WriteAllText(file, "#" + String('x', 32 * 1024))

            match SettingsOwner(root.FullName).Read SettingsScope.Application |> error with
            | SettingsError.InvalidDocument _ -> ()
            | other -> Assert.Fail($"Unexpected size result: {other}")

            File.WriteAllText(file, "version = 1\n[a.b.c.d.e] \nvalue = 1\n")

            match SettingsOwner(root.FullName).Read SettingsScope.Application |> error with
            | SettingsError.InvalidDocument _ -> ()
            | other -> Assert.Fail($"Unexpected depth result: {other}")

            File.WriteAllBytes(file, [| 0xFFuy; 0xFEuy |])

            match SettingsOwner(root.FullName).Read SettingsScope.Application |> error with
            | SettingsError.InvalidDocument _ -> ()
            | other -> Assert.Fail($"Unexpected encoding result: {other}")
        finally
            root.Delete true

    [<Test>]
    member _.``replace failure should preserve the previous settings and remove staging``() =
        task {
            let root = directory ()

            try
                let owner = SettingsOwner root.FullName

                let previous =
                    { Presentation = presentation Appearance.Light 1.0 Contrast.System
                      InheritsApplication = false
                      CheckUpdatesOnStartup = true }

                let next =
                    { Presentation = presentation Appearance.Dark 1.5 Contrast.High
                      InheritsApplication = false
                      CheckUpdatesOnStartup = true }

                let! _ = owner.Save(SettingsScope.Application, previous, CancellationToken.None)

                let! failed =
                    owner.SaveWithBoundary(
                        SettingsScope.Application,
                        next,
                        (fun () -> raise (IOException "injected replace failure")),
                        CancellationToken.None
                    )

                failed |> error |> should equal SettingsError.Unavailable
                owner.Read SettingsScope.Application |> value |> should equal previous
                Directory.GetFiles(root.FullName, ".mc-settings-*.tmp") |> should be Empty
            finally
                root.Delete true
        }
        :> Task
