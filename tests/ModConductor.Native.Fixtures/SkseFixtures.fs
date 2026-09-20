namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open ModConductor.ArchiveInspection
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Skse
open ModConductor.Workspaces

module SkseFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private archiveEntry index (value: string) =
        { Index = index
          Path =
            LogicalPath.create (value.Split('/') |> Array.toList)
            |> Result.defaultWith (fun _ -> invalidOp "Invalid fixture path.")
          Directory = false
          Size = 10L
          CompressedSize = Some 5L }

    let private nexusFile id name version description =
        { Id = id
          Name = name
          Version = version
          Category = "MAIN"
          Description = description
          Bytes = Some 100L }

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "skse")).FullName
        let workspacePath = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "installation"))

        if OperatingSystem.IsLinux() then
            let launcher = Path.Combine(proton.RuntimeDirectory, "proton")
            File.WriteAllText(launcher, "#!/bin/sh\nexit 0\n")
            File.SetUnixFileMode(
                launcher,
                UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
            )
            File.WriteAllText(
                Path.Combine(proton.RuntimeDirectory, "toolmanifest.vdf"),
                "manifest { version 2 commandline \"/proton %verb%\" }"
            )

        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()

        use store = new OperationStore(Path.Combine(area, "state"))
        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "SKSE", StorageWorker.select workspacePath)
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "SKSE" }
        )
        |> wait
        |> result
        |> ignore

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                0L,
                { Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
        |> wait
        |> result
        |> ignore

        let state = (store.GameContexts :> IGameContexts).Read workspace |> wait |> result
        let evidence = state.Binding.Value.Evidence
        let runtime = evidence.Executable.Value.FileVersion

        let modInfo =
            { Game = "skyrimspecialedition"
              Id = SkseResolver.NexusModId
              Name = "SKSE"
              Summary = "Fixture"
              Files =
                [ nexusFile 10L "older" "2.0.0" ("For game version " + runtime)
                  nexusFile 11L "matching" "2.2.0" ("Current game version " + runtime)
                  nexusFile 12L "newer incompatible" "3.0.0" "Current game version 9.9.9.9"
                  nexusFile 13L "label only" "4.0.0" "Anniversary Edition" ] }

        let releases = SkseResolver.releases modInfo

        let premium =
            SkseResolver.select
                state
                releases
                (Some
                    { Subject = "42"
                      Name = "Premium"
                      Premium = Some true })
            |> Result.defaultWith (fun _ -> invalidOp "Premium SKSE resolution failed.")

        let regular =
            SkseResolver.select
                state
                releases
                (Some
                    { Subject = "43"
                      Name = "Regular"
                      Premium = Some false })
            |> Result.defaultWith (fun _ -> invalidOp "Regular SKSE resolution failed.")

        let manifest =
            { Sha256 = String.replicate 64 "a"
              Format = "7z"
              Entries =
                [ archiveEntry 0 "skse64_2_02_00/skse64_loader.exe"
                  archiveEntry 1 "skse64_2_02_00/skse64_1_7_104.dll"
                  archiveEntry 2 "skse64_2_02_00/skse64_steam_loader.dll"
                  archiveEntry 3 "skse64_2_02_00/Data/Scripts/skse.pex"
                  archiveEntry 4 "skse64_2_02_00/readme.txt" ]
              TotalSize = 50L }

        let plan =
            SkseArchiveLayout.review premium.Release manifest
            |> Result.defaultWith (fun _ -> invalidOp "SKSE archive review failed.")

        let invalidLayout =
            SkseArchiveLayout.review
                premium.Release
                { manifest with
                    Entries = manifest.Entries |> List.filter (fun entry -> entry.Index <> 3) }
            |> Result.isError

        let loaderPath = Path.Combine(game, "skse64_loader.exe")
        File.WriteAllText(loaderPath, "fixture loader")
        let generation = Guid.NewGuid()

        store.SkseLoaders.Save(
            workspace,
            profile,
            Guid.NewGuid(),
            Guid.NewGuid(),
            generation,
            loaderPath,
            string premium.Release.ComponentVersion,
            string premium.Release.RuntimeVersion,
            evidence.Executable.Value.Sha256,
            manifest.Sha256,
            premium.Release.ModId,
            premium.Release.File.Id
        )
        |> wait

        let selection =
            (store.SkseLoaders :> IComponentLoaderSelection)
                .Read(workspace, profile, Some generation)
            |> wait

        let wrongGeneration =
            (store.SkseLoaders :> IComponentLoaderSelection)
                .Read(workspace, profile, Some(Guid.NewGuid()))
            |> wait

        let launch =
            ModConductor.GameLaunching.Descriptor.create state selection
            |> Result.defaultWith invalidOp

        let stale =
            ModConductor.GameLaunching.Descriptor.create
                state
                (selection
                 |> Option.map (fun value ->
                     { value with
                         GameSha256 = String.replicate 64 "0" }))
            |> Result.isError

        let _, runtimeName, descriptor = launch
        writer.WriteStartObject("skse")
        writer.WriteBoolean("exactRuntimeWins", premium.Release.File.Id = 11L)
        writer.WriteBoolean("newerIncompatibleRejected", premium.Release.File.Id <> 12L)
        writer.WriteBoolean("labelWithoutRuntimeRejected", releases.Length = 3)

        writer.WriteBoolean(
            "ordinaryNexusRoutes",
            premium.Acquisition = SkseAcquisition.Direct
            && regular.Acquisition = SkseAcquisition.NexusPage
        )

        writer.WriteBoolean(
            "reviewedArchiveLayout",
            plan.Files.Length = 4
            && plan.ComponentFiles.Length = 4
            && invalidLayout
        )

        writer.WriteBoolean(
            "generationBoundLoader",
            selection.IsSome && wrongGeneration.IsNone && stale
        )

        writer.WriteBoolean(
            "protonUsesLoader",
            if OperatingSystem.IsLinux() then
                descriptor.Arguments |> List.tryLast = Some loaderPath
                && descriptor.WorkingDirectory = game
                && runtimeName = evidence.Proton.Value.RuntimeName
            else
                descriptor.Executable = loaderPath && descriptor.WorkingDirectory = game
        )

        writer.WriteEndObject()
