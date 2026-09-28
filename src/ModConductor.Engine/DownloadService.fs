namespace ModConductor.Engine

open System
open System.Collections.Generic
open System.Threading.Tasks
open Grpc.Core
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads
open ModConductor.Protocol.V1

type DownloadService(downloads: DownloadSession, artifacts: IArtifactLibrary) =
    inherit ArtifactDownloads.ArtifactDownloadsBase()

    override _.StartDownload(request, context) =
        ArtifactWire.reply (
            downloads.Start
                { Id = ModLibraryWire.id request.Id
                  WorkspaceId = ModLibraryWire.id request.WorkspaceId
                  Name = request.Name
                  Sources = request.Sources |> Seq.map DownloadSource.Url |> Seq.toList
                  ExpectedLength =
                    if request.HasExpectedLength then
                        Some(ModLibraryWire.number request.ExpectedLength)
                    else
                        None
                  ExpectedSha256 =
                    if request.HasExpectedSha256 then
                        Some request.ExpectedSha256
                    else
                        None }
        )

    override _.ControlDownload(request, context) =
        let action =
            match request.Command with
            | DownloadCommand.Pause -> DownloadAction.Pause
            | DownloadCommand.Resume -> DownloadAction.Resume
            | DownloadCommand.Restart -> DownloadAction.Restart
            | _ -> ModLibraryWire.reject "Choose a download action."

        ArtifactWire.reply (
            downloads.Control(
                ModLibraryWire.id request.WorkspaceId,
                ModLibraryWire.id request.Id,
                action
            )
        )

    override _.WatchDownloads(request, stream, context) =
        task {
            if request.Ids.Count = 0 || request.Ids.Count > 64 then
                ModLibraryWire.reject "Observe up to 64 archives at once."

            let workspace = ModLibraryWire.id request.WorkspaceId
            let ids = request.Ids |> Seq.map ModLibraryWire.id |> Seq.distinct |> Seq.toArray
            let revisions = Dictionary<Guid, int64>()

            for id in ids do
                revisions[id] <- -1L

            while not context.CancellationToken.IsCancellationRequested do
                for id in ids do
                    let! found = artifacts.Read(workspace, id)

                    match found with
                    | Ok artifact when
                        not (revisions.ContainsKey id) || revisions[id] <> artifact.Revision
                        ->
                        do!
                            stream.WriteAsync(
                                ArtifactWire.artifact artifact,
                                context.CancellationToken
                            )

                        revisions[id] <- artifact.Revision
                    | Ok _
                    | Error ArtifactError.Busy
                    | Error ArtifactError.NotFound -> ()
                    | Error error -> ArtifactWire.result (Error error) |> ignore

                do!
                    downloads.WaitForChange(
                        workspace,
                        [ for item in revisions -> item.Key, item.Value ],
                        context.CancellationToken
                    )
        }
