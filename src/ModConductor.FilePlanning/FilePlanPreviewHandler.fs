namespace ModConductor.FilePlanning

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

type internal FilePlanPreviewHandler(state: FilePlanSessionState) =
    let repository = state.Repository
    let cache = state.Cache
    let checkedSnapshot id = state.CheckedSnapshot id
    let describe stale snapshot = state.Describe stale snapshot

    let previewRow (snapshot: PlanSnapshot) source =
        let target = FilePreviewRendering.target source

        InspectionProjection.inspect target None snapshot
        |> Result.bind (fun (copies, _) ->
            match copies |> List.tryFind (fun row -> row.Source = source) with
            | Some row -> Ok row
            | None -> Error FilePlanError.Stale)

    member _.Preview(id, source, representation, token) =
        task {
            let! found = checkedSnapshot id

            match found with
            | Error error -> return Error error
            | Ok(_, true) -> return Error FilePlanError.Stale
            | Ok(snapshot, false) ->
                match previewRow snapshot source with
                | Error error -> return Error error
                | Ok row ->
                    match source with
                    | FilePreviewSource.ManagedCopy managed ->
                        let! saved =
                            repository.Copy(snapshot.Sources.Stamp.WorkspaceId, managed.Copy)

                        match saved with
                        | Error error -> return Error error
                        | Ok saved when
                            not saved.Current
                            || saved.Entry.Path <> managed.SourcePath
                            || saved.Entry.Payload.Id <> managed.PayloadId
                            || saved.Entry.Payload.Length <> managed.Length
                            || saved.Entry.Payload.Sha256 <> managed.Sha256
                            ->
                            return Error FilePlanError.Stale
                        | Ok saved ->
                            let pin =
                                SourcePin.Mod(
                                    managed.Copy.ModId,
                                    managed.Copy.VersionId,
                                    saved.Entry
                                )

                            let! opened =
                                repository.OpenManaged(
                                    snapshot.Sources.Stamp.WorkspaceId,
                                    pin,
                                    token
                                )

                            match opened with
                            | Error error -> return Error error
                            | Ok stream ->
                                use stream = stream

                                return
                                    Ok(
                                        FilePreviewRendering.render
                                            source
                                            row.Standing
                                            representation
                                            stream
                                            token
                                    )
                    | FilePreviewSource.CheckedGameFile game ->
                        match snapshot.Game with
                        | None -> return Error FilePlanError.Stale
                        | Some observation ->
                            return
                                GameFiles.readChecked observation game token (fun stream ->
                                    FilePreviewRendering.render
                                        source
                                        row.Standing
                                        representation
                                        stream
                                        token)
                    | FilePreviewSource.QualifiedArchiveEntry _ ->
                        return Error FilePlanError.InvalidCopy
        }
