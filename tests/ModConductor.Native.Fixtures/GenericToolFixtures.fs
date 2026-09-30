namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.Persistence
open ModConductor.Executables
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.Deployment
open ModConductor.ModSelection
open ModConductor.ModLibrary
open ModConductor.Workspaces

module GenericToolFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private finished (store: OperationStore) workspace (run: ExecutableRun) =
        let deadline = DateTime.UtcNow.AddSeconds 30.
        let mutable current = run

        while not (ExecutablePolicy.terminal current.Phase) && DateTime.UtcNow < deadline do
            Thread.Sleep 20
            current <- store.Executables.Read(workspace, run.Id) |> wait |> result

        if not (ExecutablePolicy.terminal current.Phase) then
            invalidOp "The owned generic fixture did not close."

        current

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject "genericTools"

        let check (name: string) (condition: bool) =
            writer.WriteBoolean(name, condition)

            if not condition then
                invalidOp ("Generic tool fixture failed: " + name)

        let area =
            Directory.CreateDirectory(Path.Combine(primary, "generic-tools")).FullName

        let statePath = Path.Combine(area, "state")
        use store = new OperationStore(statePath)

        let workspace, profile, game, proton, savedContext =
            SkyrimFixtureWorkspace.create
                store
                statePath
                area
                "Tool fixture"
                "workspace"
                "installation"
                true

        let context = savedContext |> result
        let ws = store.Workspaces :> IWorkspaceState

        let select profile =
            let current = ws.Read(workspace, None) |> wait |> result

            ws.Edit(workspace, current.Workspace.Revision, ProfileEdit.Select profile)
            |> wait
            |> result
            |> ignore

        select profile

        let controls =
            Directory.CreateDirectory(Path.Combine(area, "external Ω tool")).FullName

        let executable, prefix = ExecutableChild.invocation ()

        let mutable tool =
            store.Executables.Save
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  Revision = 0L
                  Name = "Arbitrary native generator"
                  Runtime = ExecutableRuntime.Native
                  OutputName = Some "Shared label output"
                  Launch =
                    { Executable = executable
                      WorkingDirectory = controls
                      Arguments =
                        prefix
                        @ [ "--executable-child"; controls; "generator"; "{output}"; "first"; "0" ]
                      Environment = [] } }
            |> wait
            |> result

        check
            "missingOutputPlaceholderRefused"
            (store.Executables.Save { tool with OutputName = None } |> wait |> Result.isError)

        let launch () =
            let current = ws.Read(workspace, None) |> wait |> result

            store.Executables.Begin
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  WorkspaceRevision = current.Workspace.Revision
                  PresetId = tool.Id
                  PresetRevision = tool.Revision }
            |> wait
            |> result
            |> finished store workspace

        let update content exit =
            tool <-
                store.Executables.Save
                    { tool with
                        Launch =
                            { tool.Launch with
                                Arguments =
                                    prefix
                                    @ [ "--executable-child"
                                        controls
                                        "generator"
                                        "{output}"
                                        content
                                        string exit ] } }
                |> wait
                |> result

        let initial = launch ()
        let output = initial.OutputDirectory.Value

        let entry () =
            (InventoryObservations.read store profile).Entries
            |> List.find (fun v -> v.Entry.Mod.Kind = ModKind.GeneratedOutput)

        let firstEntry = entry ()
        let retained = Path.Combine(output, "untouched.txt")
        File.WriteAllText(retained, "tool owns cleanup")
        update "second" 0
        let repeated = launch ()

        check
            "sameFolderStateSurvivesRerunWithoutSnapshot"
            (initial.RootExitCode = Some 0
             && repeated.OutputDirectory = Some output
             && File.ReadAllText(Path.Combine(output, "generated.txt")) = "second"
             && File.ReadAllText(Path.Combine(output, "tool-state.txt")) = "11"
             && File.ReadAllText retained = "tool owns cleanup"
             && (entry ()).Entry.Mod.CurrentVersion.IsNone)

        let literalPath = Path.Combine(area, "literal {output} folder")

        let literalArguments =
            ToolArguments.substitute
                ExecutableRuntime.Native
                context.Binding.Value.Evidence
                (Some literalPath)
                (Some output)
                [ "{game}"; "{output}" ]
            |> result

        check "replacementPathsRemainLiteral" (literalArguments = [ literalPath; output ])
        let original = File.ReadAllBytes(Path.Combine(game, "SkyrimSE.exe"))
        let backend = store.Deployments

        let snapshot () =
            let status = backend.Read profile |> wait |> result

            backend.Prepare(Guid.NewGuid(), status.Sources, ignore, CancellationToken.None)
            |> wait
            |> result

        let prepared = snapshot ()
        let captured = (entry ()).Entry.Mod.CurrentVersion

        check
            "deploymentPrepareAloneCapturesOutput"
            (captured.IsSome
             && (prepared.Sources.Versions
                 |> List.exists (fun (id, version) ->
                     id = firstEntry.Entry.Mod.Id && version = captured)))

        backend.Activate(prepared.Id, prepared.Sources, ignore, CancellationToken.None)
        |> wait
        |> result
        |> ignore

        let view = (backend.Read profile |> wait |> result).RunnableRoot
        update "partial" 13
        let failed = launch ()

        check
            "nonzeroExitRetainsPartialOutputAndPriorDeployment"
            (failed.Phase = RunPhase.Finished
             && failed.RootExitCode = Some 13
             && File.ReadAllText(Path.Combine(output, "generated.txt")) = "partial"
             && File.ReadAllText(Path.Combine(view, "Data", "generated.txt")) = "second"
             && (entry ()).Entry.Mod.CurrentVersion = captured
             && File.ReadAllBytes(Path.Combine(game, "SkyrimSE.exe")) = original)

        let selection = InventoryObservations.read store profile
        let selections = store.ModSelection :> IModSelection

        selections.Change(
            profile,
            selection.SelectionRevision,
            [ firstEntry.Entry.Mod.Id ],
            SelectionEdit.Enable false
        )
        |> wait
        |> result
        |> ignore

        let disabled = entry ()
        update "disabled" 0
        launch () |> ignore
        let disabledAgain = entry ()
        let _disabledSnapshot = snapshot ()

        check
            "rerunPreservesDisabledOutputAndDeploymentSkipsIt"
            (disabled.Entry.Selection = disabledAgain.Entry.Selection
             && (entry ()).Entry.Mod.CurrentVersion = captured)

        let secondProfile = Guid.NewGuid()
        let current = ws.Read(workspace, None) |> wait |> result

        ws.Edit(
            workspace,
            current.Workspace.Revision,
            ProfileEdit.Create { Id = secondProfile; Name = "Second" }
        )
        |> wait
        |> result
        |> ignore

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                secondProfile,
                0L,
                { GameId = GameId.SkyrimSpecialEditionSteam
                  Path = game
                  Wine = None
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
        |> wait
        |> result
        |> ignore

        select secondProfile
        update "other profile" 0
        let other = launch ()

        let entries =
            (InventoryObservations.read store secondProfile).Entries
            |> List.filter (fun v -> v.Entry.Mod.Kind = ModKind.GeneratedOutput)

        check
            "sameRegistrationResolvesPrivateOutputInEveryProfile"
            (other.OutputDirectory.IsSome
             && other.OutputDirectory <> Some output
             && entries.Length = 1
             && entries.Head.Entry.Mod.Id <> firstEntry.Entry.Mod.Id
             && File.ReadAllText(Path.Combine(output, "generated.txt")) = "disabled")

        if OperatingSystem.IsLinux() then
            let evidence = context.Binding.Value.Evidence

            let converted =
                ToolArguments.substitute
                    ExecutableRuntime.Proton
                    evidence
                    (Some view)
                    (Some output)
                    [ "--game={game}"; "{output}"; "two words"; "$(literal)"; "" ]
                |> result

            check
                "runtimePlaceholderPathsPreserveArgumentBoundaries"
                (converted[0].StartsWith("--game=Z:\\")
                 && converted[1].StartsWith("Z:\\")
                 && converted[2..] = [ "two words"; "$(literal)"; "" ])

            let external = Path.Combine(controls, "Custom Ω.exe")

            let launch =
                { tool.Launch with
                    Executable = external
                    Arguments = [ "two words"; ""; "literal; &" ] }

            let projected =
                RegisteredTool.projectWithHost
                    false
                    true
                    ExecutableRuntime.Proton
                    context
                    view
                    launch
                |> result

            check
                "externalProtonProjectionUsesSelectedContext"
                (projected.Executable = (evidence.Proton.Value.Launch
                                         |> Result.map _.Executable
                                         |> result)
                 && (List.rev projected.Arguments |> List.take 4 |> List.rev) = external
                                                                                :: launch.Arguments
                 && projected.WorkingDirectory = controls)

            check
                "unavailableWineRouteRefusedBeforeProcess"
                (RegisteredTool.projectWithHost
                    false
                    true
                    ExecutableRuntime.Wine
                    context
                    view
                    launch
                 |> Result.isError)

        select profile
        let heldOutput = output + "-held"
        Directory.Move(output, heldOutput)
        Directory.CreateDirectory output |> ignore
        let foreignFile = Path.Combine(output, "generated.txt")
        File.WriteAllText(foreignFile, "not the registered output")
        let refused = launch ()

        check
            "replacedOwnedOutputDirectoryRefusedWithoutWriting"
            (refused.Phase = RunPhase.Failed
             && refused.ProcessId.IsNone
             && File.ReadAllText(foreignFile) = "not the registered output")

        Directory.Delete(output, true)
        Directory.Move(heldOutput, output)
        writer.WriteEndObject()
        GenerationCleanup.normalize area
