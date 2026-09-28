namespace ModConductor.Engine

open System.Threading.Tasks
open ModConductor.Desktop
open ModConductor.Platform
open ModConductor.Workspaces
open ModConductor.Protocol.V1

type DesktopService(state: IWorkspaceState) =
    inherit DesktopOperations.DesktopOperationsBase()

    override _.ResolveDesktopRequest(request, _) =
        task {
            let problem detail = DesktopRequestReply(Problem = detail)

            let intent kind path id length =
                DesktopRequestReply(
                    Intent =
                        DesktopIntent(
                            Kind = kind,
                            Path = path,
                            WorkspaceId = id,
                            Length = uint64 length
                        )
                )

            match Activation.parse (request.Arguments |> Seq.toArray) with
            | Error detail -> return problem detail
            | Ok Show -> return intent DesktopIntentKind.Show "" "" 0L
            | Ok(WorkspacePath path) ->
                return
                    match Activation.directory path with
                    | Ok value -> intent DesktopIntentKind.Workspace value "" 0L
                    | Error detail -> problem detail
            | Ok(ArchivePath path) ->
                return
                    match Activation.archive path with
                    | Ok(value, length) -> intent DesktopIntentKind.Archive value "" length
                    | Error detail -> problem detail
            | Ok(ProfilePath path) ->
                return
                    match Activation.profile path with
                    | Ok(value, length) -> intent DesktopIntentKind.Profile value "" length
                    | Error detail -> problem detail
            | Ok(Workspace id as activation)
            | Ok(Archives id as activation) ->
                let! result = state.Read(id, None)

                return
                    match result with
                    | Ok page ->
                        let kind =
                            match activation with
                            | Archives _ -> DesktopIntentKind.Archives
                            | _ -> DesktopIntentKind.Workspace

                        intent kind (HostPath.value page.Workspace.Path) (id.ToString("N")) 0L
                    | Error _ -> problem "This workspace is unavailable. Open it from Workspaces."
        }
