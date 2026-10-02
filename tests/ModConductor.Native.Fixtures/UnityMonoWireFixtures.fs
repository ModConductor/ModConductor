namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
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

        let declared = store.BepInEx.Read(workspace, profile) |> UnityMonoEnvironment.get

        check
            "v1 preserves optional loader package provenance"
            ((not (isNull transmitted.Loader.Package)) = declared.Package.IsSome)

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

    let observeLog check (store: OperationStore) (workspace: Guid) (profile: Guid) root =
        let path = Path.Combine(root, "BepInEx", "LogOutput.log")

        let original =
            Encoding.UTF8.GetBytes "upstream message\r\nembedded callback trace\nnext message\r\n"

        File.WriteAllBytes(path, original)
        let service = BepInExService store.BepInEx

        let request =
            LoaderRequest(WorkspaceId = workspace.ToString("N"), ProfileId = profile.ToString("N"))

        let reply =
            service.ReadLoaderLog(request, Unchecked.defaultof<_>) |> StorageWorker.wait

        let transmitted = LoaderTextReply.Parser.ParseFrom(reply.ToByteArray())

        check
            "v1 read-only log permits upstream mixed newlines without altering file bytes"
            (transmitted.ResultCase = LoaderTextReply.ResultOneofCase.Text
             && transmitted.Text.Original = ByteString.CopyFrom original
             && transmitted.Text.Document.Content = "upstream message\nembedded callback trace\nnext message\n"
             && File.ReadAllBytes(path) = original)
