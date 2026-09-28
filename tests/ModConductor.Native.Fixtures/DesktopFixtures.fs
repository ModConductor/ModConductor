namespace ModConductor.Native.Fixtures

open System
open System.Diagnostics
open System.IO
open System.Text.Json
open ModConductor.Desktop
open ModConductor.Engine
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Protocol.V1
open ModConductor.Workspaces

module DesktopFixtures =
    let tryLease path =
        try
            use lease = StateLease.acquire path
            0
        with :? IOException ->
            17

    let observe (writer: Utf8JsonWriter) directory =
        Directory.CreateDirectory directory |> ignore

        let verify (name: string) value =
            writer.WriteBoolean(name, value)

            if not value then
                failwith name

        let child path =
            let info = ProcessStartInfo(Environment.ProcessPath, UseShellExecute = false)
            info.ArgumentList.Add "--desktop-lease"
            info.ArgumentList.Add path
            use worker = Process.Start info

            if not (worker.WaitForExit 10000) then
                failwith "Desktop lease fixture timed out."

            worker.ExitCode

        let statePath = Path.Combine(directory, "state")

        do
            use lease = StateLease.acquire statePath
            verify "secondOwnerRefused" (child statePath = 17)

        verify "releasedOwnerAdmitted" (child statePath = 0)

        let root =
            Directory.CreateDirectory(Path.Combine(directory, "Weekend rivière")).FullName

        let archive = Path.Combine(directory, "Northern lights — rivière.7z")
        File.WriteAllText(archive, "synthetic archive input")
        use store = new OperationStore(statePath)

        let selected =
            HostPath.create root
            |> Result.bind (fun path ->
                RootSelection.select path |> Result.mapError (fun _ -> "root"))
            |> Result.defaultWith failwith

        let id = Guid.NewGuid()

        let workspace =
            (store.Workspaces :> IWorkspaceState)
                .Create(id, "Weekend", selected)
                .GetAwaiter()
                .GetResult()
            |> Result.defaultWith (fun _ -> failwith "create")

        let service = DesktopService(store.Workspaces)

        let resolve args =
            let request = ResolveDesktopRequestMessage()
            request.Arguments.AddRange args
            service.ResolveDesktopRequest(request, Unchecked.defaultof<_>).GetAwaiter().GetResult()

        let route = resolve [ "--uri"; "modconductor://archives/" + id.ToString("N") ]

        verify
            "registeredWorkspaceRoute"
            (route.Intent.Kind = DesktopIntentKind.Archives
             && route.Intent.Path = HostPath.value workspace.Workspace.Path
             && route.Intent.WorkspaceId = id.ToString("N"))

        let missing =
            resolve [ "--uri"; "modconductor://workspace/" + Guid.NewGuid().ToString("N") ]

        verify
            "unregisteredWorkspaceRefused"
            (missing.OutcomeCase = DesktopRequestReply.OutcomeOneofCase.Problem)

        let file = resolve [ "--archive"; archive ]

        verify
            "archiveMetadataWithoutAdoption"
            (file.Intent.Kind = DesktopIntentKind.Archive
             && file.Intent.Length = uint64 (FileInfo(archive).Length)
             && File.ReadAllText(archive) = "synthetic archive input")

        let profile = Path.Combine(directory, "Weekend rivière.mcprof")
        File.WriteAllText(profile, "synthetic profile input")
        let opened = resolve [ "--profile"; profile ]
        let openedUri = resolve [ Uri(profile).AbsoluteUri ]

        verify
            "profileFileActivationWithoutImport"
            (opened.Intent.Kind = DesktopIntentKind.Profile
             && opened.Intent.Path = profile
             && opened.Intent.Length = uint64 (FileInfo(profile).Length)
             && openedUri.Intent.Kind = DesktopIntentKind.Profile
             && openedUri.Intent.Path = profile
             && File.ReadAllText(profile) = "synthetic profile input")
