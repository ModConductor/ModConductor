namespace ModConductor.Engine

open ModConductor.Persistence
open ModConductor.Protocol.V1
open ModConductor.Unreal
open System.Threading.Tasks

module internal UnrealWire =
    let state (store: UnrealStore) (state: LoaderState) =
        task {
            let! files = store.SettingsFiles(state.Workspace, state.Profile)

            let result =
                UnrealLoaderInfo(
                    WorkspaceId = state.Workspace.ToString("N"),
                    ProfileId = state.Profile.ToString("N"),
                    ContextRevision = uint64 state.ContextRevision,
                    SelectionRevision = uint64 state.SelectionRevision,
                    LoaderId = state.Declaration.Id,
                    Name = state.Declaration.Name,
                    Version = state.Version,
                    IconUrl = state.Declaration.Icon,
                    Enabled = state.Enabled,
                    ArchiveRequired = state.Declaration.Download.IsNone,
                    LogAvailable = state.LogAvailable,
                    DeclaredVersion = state.Declaration.Version,
                    DeclaredVersionLabel = state.Declaration.VersionLabel,
                    DeclaredSource = state.Declaration.Source,
                    UpstreamLicense = state.Declaration.License
                )

            state.Declaration.Subtitle
            |> Option.iter (fun value -> result.Subtitle <- value)

            state.Declaration.UpstreamCommit
            |> Option.iter (fun value -> result.UpstreamCommit <- value)

            state.Mod |> Option.iter (fun value -> result.ModId <- value.ToString("N"))
            result.SettingsFiles.AddRange(files |> Result.defaultValue [])

            state.Declaration.IconHeaders
            |> List.iter (fun (key, value) -> result.IconHeaders.Add(key, value))

            return result
        }

    let reply store result =
        task {
            match result with
            | Error detail -> return UnrealLoaderReply(Problem = detail)
            | Ok value ->
                let! value = state store value
                return UnrealLoaderReply(Loader = value)
        }

type UnrealService(store: UnrealStore, acquisition: UnrealAcquisition) =
    inherit Unreal.UnrealBase()

    let ids workspace profile =
        ModLibraryWire.id workspace, ModLibraryWire.id profile

    override _.ReadUnrealLoader(request, _) =
        task {
            let workspace, profile = ids request.WorkspaceId request.ProfileId
            let! result = store.Read(workspace, profile)
            return! UnrealWire.reply store result
        }

    override _.ChangeUnrealLoader(request, _) =
        task {
            let workspace, profile = ids request.WorkspaceId request.ProfileId

            let! result =
                store.Change(
                    workspace,
                    profile,
                    ModLibraryWire.number request.ContextRevision,
                    ModLibraryWire.number request.SelectionRevision,
                    request.Enabled
                )

            return! UnrealWire.reply store result
        }

    override _.AcquireUnrealLoader(request, stream, context) : Task =
        task {
            let workspace, profile = ids request.WorkspaceId request.ProfileId

            use cancellation =
                System.Threading.CancellationTokenSource.CreateLinkedTokenSource(
                    context.CancellationToken
                )

            let observe (value: UnrealProgress) : Task =
                task {
                    let result =
                        UnrealAcquisitionProgress(Stage = value.Stage, Bytes = uint64 value.Bytes)

                    value.Total |> Option.iter (fun total -> result.Total <- uint64 total)
                    value.Mod |> Option.iter (fun id -> result.ModId <- id.ToString("N"))

                    try
                        do! stream.WriteAsync(result, cancellation.Token)
                    with
                    | :? Grpc.Core.RpcException
                    | :? System.IO.IOException ->
                        cancellation.Cancel()
                        cancellation.Token.ThrowIfCancellationRequested()
                }

            let! result =
                acquisition.Acquire(
                    workspace,
                    profile,
                    ModLibraryWire.number request.ContextRevision,
                    request.ArchivePath,
                    observe,
                    cancellation.Token
                )

            let reply = UnrealAcquisitionProgress(Stage = "complete")

            match result with
            | Error detail ->
                reply.Stage <- "stopped"
                reply.Problem <- detail
            | Ok state ->
                let! state = UnrealWire.state store state
                reply.Loader <- state

            if not cancellation.IsCancellationRequested then
                do! stream.WriteAsync(reply, cancellation.Token)
        }

    override _.ReadUnrealText(request, _) =
        task {
            let workspace, profile = ids request.WorkspaceId request.ProfileId
            let! result = store.Text(workspace, profile, request.Name, None, request.Log)
            return BepInExWire.text result
        }

    override _.SaveUnrealText(request, _) =
        task {
            let workspace, profile = ids request.WorkspaceId request.ProfileId

            let! result =
                store.Text(
                    workspace,
                    profile,
                    request.Name,
                    Some(request.Original.ToByteArray(), request.Content),
                    false
                )

            return BepInExWire.text result
        }

    override _.OpenUnrealLoaderPage(request, context) =
        task {
            let workspace, profile = ids request.WorkspaceId request.ProfileId
            let! result = store.Read(workspace, profile)

            match result with
            | Error detail -> return UnrealPageReply(Problem = detail)
            | Ok selected ->
                try
                    do!
                        ModConductor.Desktop.WebLink.openBrowser (
                            System.Uri selected.Declaration.Page,
                            context.CancellationToken
                        )

                    return UnrealPageReply()
                with :? System.ComponentModel.Win32Exception ->
                    return UnrealPageReply(Problem = "The web browser could not open.")
        }
