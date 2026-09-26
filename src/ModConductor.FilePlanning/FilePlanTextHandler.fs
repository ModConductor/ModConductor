namespace ModConductor.FilePlanning

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

type internal FilePlanTextHandler(state: FilePlanSessionState) =
    let repository = state.Repository
    let cache = state.Cache
    let checkedSnapshot id = state.CheckedSnapshot id
    let describe stale snapshot = state.Describe stale snapshot

    let editBytes (source: ManagedPreviewSource) original content =
        TextDocuments.encode original content
        |> Result.mapError FilePlanError.InvalidEdit
        |> Result.bind (fun bytes ->
            let digest = Convert.ToHexStringLower(SHA256.HashData bytes)

            if int64 bytes.Length = source.Length && digest = source.Sha256 then
                Error(FilePlanError.InvalidEdit "The draft has no changes to save.")
            else
                Ok bytes)

    let openManagedText (snapshot: PlanSnapshot) (managed: ManagedPreviewSource) token =
        task {
            if managed.Length < 0L || managed.Length > int64 TextDocuments.bytesLimit then
                return Error(FilePlanError.LimitExceeded "This text file is too large to edit.")
            else
                let target = managed.Target

                match InspectionProjection.inspect target None snapshot with
                | Error error -> return Error error
                | Ok(copies, _) ->
                    match
                        copies
                        |> List.tryFind (fun row ->
                            row.Source = FilePreviewSource.ManagedCopy managed)
                    with
                    | None -> return Error FilePlanError.Stale
                    | Some _ ->
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
                                let bytes = Array.zeroCreate<byte> (int managed.Length)
                                stream.ReadExactly bytes
                                token.ThrowIfCancellationRequested()

                                if stream.Length <> managed.Length then
                                    return Error FilePlanError.Stale
                                else
                                    return
                                        TextDocuments.editable bytes
                                        |> Result.mapError FilePlanError.Unsupported
        }

    member _.OpenManagedText(id, source, token) =
        task {
            let! found = checkedSnapshot id

            match found with
            | Error error -> return Error error
            | Ok(_, true) -> return Error FilePlanError.Stale
            | Ok(snapshot, false) ->
                let! document = openManagedText snapshot source token

                return document |> Result.map (fun value -> { Source = source; Document = value })
        }

    member _.SaveManagedText(id, action, source, content, token) =
        task {
            if action = Guid.Empty then
                return Error FilePlanError.InvalidCopy
            else
                let! found = checkedSnapshot id

                match found with
                | Error error -> return Error error
                | Ok(_, true) -> return Error FilePlanError.Stale
                | Ok(snapshot, false) ->
                    let! original = openManagedText snapshot source token

                    match original with
                    | Error error -> return Error error
                    | Ok original ->
                        match editBytes source original content with
                        | Error error -> return Error error
                        | Ok bytes ->
                            let! published =
                                repository.PublishText(
                                    snapshot.Sources.Stamp,
                                    action,
                                    source,
                                    bytes,
                                    token
                                )

                            return
                                published
                                |> Result.map (fun version ->
                                    cache.MarkStale snapshot

                                    { Id = action
                                      VersionId = version
                                      Source = source })
        }

    member _.AbandonManagedText(action) =
        if action = Guid.Empty then
            Task.FromResult(Error FilePlanError.InvalidCopy)
        else
            repository.AbandonText action
