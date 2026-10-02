namespace ModConductor.Native.Fixtures

open System
open Google.Protobuf
open ModConductor.Engine
open ModConductor.Persistence
open ModConductor.Protocol.V1

module UnityMonoWireFixtures =
    let observe check (store: OperationStore) (workspace: Guid) (profile: Guid) =
        let wait = StorageWorker.wait
        let service = BepInExService store.BepInEx

        let request =
            LoaderRequest(WorkspaceId = workspace.ToString("N"), ProfileId = profile.ToString("N"))

        let state = service.ReadLoader(request, Unchecked.defaultof<_>) |> wait
        let transmitted = LoaderReply.Parser.ParseFrom(state.ToByteArray())

        let stale =
            ChangeLoaderRequest(
                WorkspaceId = transmitted.Loader.WorkspaceId,
                ProfileId = transmitted.Loader.ProfileId,
                ContextRevision = transmitted.Loader.ContextRevision,
                SelectionRevision = transmitted.Loader.SelectionRevision + 1UL,
                Enabled = false
            )

        let changed = service.ChangeLoader(stale, Unchecked.defaultof<_>) |> wait
        let current = service.ReadLoader(request, Unchecked.defaultof<_>) |> wait

        check
            "v1 stale selection refuses without disabling the loader"
            (changed.HasProblem && current.Loader.Enabled)

        let text = service.ReadLoaderSettings(request, Unchecked.defaultof<_>) |> wait
        let transmitted = LoaderTextReply.Parser.ParseFrom(text.ToByteArray())

        let save =
            SaveLoaderSettingsRequest(
                WorkspaceId = request.WorkspaceId,
                ProfileId = request.ProfileId,
                Original = transmitted.Text.Original,
                Content = transmitted.Text.Document.Content
            )

        let saved = service.SaveLoaderSettings(save, Unchecked.defaultof<_>) |> wait

        check
            "v1 settings preserve original bytes and text document through save"
            (saved.ResultCase = LoaderTextReply.ResultOneofCase.Text
             && saved.Text = transmitted.Text)
