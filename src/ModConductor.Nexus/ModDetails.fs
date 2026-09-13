namespace ModConductor.Nexus

open System

// Provider work and brief mod-owned commits share the same identity and revision checks.
type NexusModDetails(session: NexusSession, store: INexusMetadataStore) =
    let current (expected: ModNexusDetails) =
        task {
            let! result = store.Read(expected.Workspace, expected.Mod)

            return
                result
                |> Result.bind (fun value ->
                    if
                        value.Identity <> expected.Identity
                        || value.LinkRevision <> expected.LinkRevision
                        || value.Version <> expected.Version
                    then
                        Error NexusProblem.ModChanged
                    else
                        Ok value)
        }

    member _.Read(workspace, modId) = store.Read(workspace, modId)

    member _.Refresh(expected: ModNexusDetails) =
        task {
            let! latest = current expected

            match latest with
            | Error error -> return Error error
            | Ok value when value.Identity.IsNone -> return Ok value
            | Ok value ->
                let! metadata = session.ReadMetadata value.Identity.Value
                let! saved = store.Save(value, metadata)

                match saved with
                | Error error -> return Error error
                | Ok value ->
                    let! _ = session.RefreshInteractions value.Identity.Value
                    return! current value
        }

    member _.Link(expected, metadata, file) =
        task {
            let! result = store.Link(expected, metadata, file)

            match result with
            | Ok value ->
                expected.Identity |> Option.iter session.ForgetInteractions
                value.Identity |> Option.iter session.ForgetInteractions
            | Error _ -> ()

            return result
        }

    member _.MapCategory(expected, category) = store.MapCategory(expected, category)

    member _.Change(expected: ModNexusDetails, revision, action) =
        task {
            let! result = current expected

            match result with
            | Error error -> return Error error
            | Ok value when value.Identity.IsNone -> return Error NexusProblem.ModChanged
            | Ok value ->
                let endorsement =
                    action = NexusInteraction.Endorse || action = NexusInteraction.Abstain

                if
                    endorsement
                    && (value.Freshness <> NexusFreshness.Current
                        || value.Snapshot
                           |> Option.forall (fun metadata -> not metadata.AllowsRating)
                        || value.Installed
                           |> Option.forall (fun file -> String.IsNullOrWhiteSpace file.Version))
                then
                    return Error NexusProblem.InteractionUnavailable
                else
                    let version = value.Installed |> Option.map _.Version |> Option.defaultValue ""

                    let! state =
                        session.ChangeInteraction(value.Identity.Value, revision, action, version)

                    let! latest = current value
                    return latest |> Result.map (fun _ -> state)
        }

    member _.File(expected: ModNexusDetails, fileId, updateOnly) =
        task {
            let! result = current expected

            return
                result
                |> Result.bind (fun value ->
                    match value.Snapshot with
                    | Some metadata when
                        value.Freshness = NexusFreshness.Current && metadata.Available
                        ->
                        let files =
                            if updateOnly then
                                NexusUpdates.candidates value.Installed metadata
                            else
                                metadata.Files
                                |> List.filter (fun file ->
                                    file.CategoryId >= 1 && file.CategoryId <= 3)

                        files
                        |> List.tryFind (fun file -> file.File.Id = fileId)
                        |> Option.map (fun file -> value, file.File)
                        |> function
                            | Some value -> Ok value
                            | None -> Error NexusProblem.ModChanged
                    | _ -> Error NexusProblem.ModChanged)
        }
