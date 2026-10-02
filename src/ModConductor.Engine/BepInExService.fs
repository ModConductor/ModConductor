namespace ModConductor.Engine

open Google.Protobuf
open ModConductor.Persistence
open ModConductor.BepInEx
open ModConductor.FilePlanning
open ModConductor.Protocol.V1

module internal BepInExWire =
    let state (value: LoaderState) =
        let reply =
            LoaderInfo(
                WorkspaceId = value.Workspace.ToString("N"),
                ProfileId = value.Profile.ToString("N"),
                ContextRevision = uint64 value.ContextRevision,
                SelectionRevision = uint64 value.SelectionRevision,
                Enabled = value.Enabled,
                SettingsAvailable = value.SettingsAvailable,
                LogAvailable = value.LogAvailable
            )

        value.Package
        |> Option.iter (fun package -> reply.Package <- ThunderstoreWire.reference package)

        value.Mod |> Option.iter (fun id -> reply.ModId <- id.ToString("N"))
        reply

    let loader =
        function
        | Ok value -> LoaderReply(Loader = state value)
        | Error detail -> LoaderReply(Problem = detail)

    let private textReply =
        function
        | Ok((bytes: byte array), document) ->
            LoaderTextReply(
                Text =
                    LoaderText(
                        Document = FilePlanWire.textDocument document,
                        Original = ByteString.CopyFrom bytes
                    )
            )
        | Error detail -> LoaderTextReply(Problem = detail)

    let text result =
        result
        |> Result.bind (fun bytes ->
            TextDocuments.editable bytes |> Result.map (fun document -> bytes, document))
        |> textReply

    let log result =
        result
        |> Result.bind (fun bytes ->
            TextDocuments.decode bytes
            |> Result.map (fun decoded ->
                let document: ModConductor.FilePlanning.TextDocument =
                    { Content = decoded.Content.Replace("\r\n", "\n")
                      Encoding = decoded.Encoding
                      Newline =
                        match decoded.Newline with
                        | Some ModConductor.FilePlanning.TextDocumentNewline.NoLineBreaks ->
                            ModConductor.FilePlanning.TextDocumentNewline.NoLineBreaks
                        | _ -> ModConductor.FilePlanning.TextDocumentNewline.Lf
                      FinalTerminator = decoded.FinalTerminator
                      Lines = decoded.Lines }

                bytes, document))
        |> textReply

/// The profile and existing working files remain the authority, not a second loader receipt store.
type BepInExService(store: BepInExStore) =
    inherit ModConductor.Protocol.V1.BepInEx.BepInExBase()

    let ids workspace profile =
        ModLibraryWire.id workspace, ModLibraryWire.id profile

    override _.ReadLoader(request, _) =
        task {
            let workspace, profile = ids request.WorkspaceId request.ProfileId
            let! result = store.Read(workspace, profile)
            return BepInExWire.loader result
        }

    override _.ChangeLoader(request, _) =
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

            return BepInExWire.loader result
        }

    override _.ReadLoaderSettings(request, _) =
        task {
            let workspace, profile = ids request.WorkspaceId request.ProfileId
            let! result = store.ReadSettings(workspace, profile)
            return BepInExWire.text result
        }

    override _.SaveLoaderSettings(request, _) =
        task {
            let workspace, profile = ids request.WorkspaceId request.ProfileId

            let! saved =
                store.SaveSettings(
                    workspace,
                    profile,
                    request.Original.ToByteArray(),
                    request.Content
                )

            match saved with
            | Error detail -> return LoaderTextReply(Problem = detail)
            | Ok _ ->
                let! result = store.ReadSettings(workspace, profile)
                return BepInExWire.text result
        }

    override _.ReadLoaderLog(request, _) =
        task {
            let workspace, profile = ids request.WorkspaceId request.ProfileId
            let! result = store.ReadLog(workspace, profile)
            return BepInExWire.log result
        }
