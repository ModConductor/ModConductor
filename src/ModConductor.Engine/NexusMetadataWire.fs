namespace ModConductor.Engine

open System
open ModConductor.Nexus
open ModConductor.Protocol.V1

module internal NexusMetadataWire =
    let reference (value: ModConductor.Nexus.ModNexusDetails) =
        let wire =
            ModNexusReference(
                WorkspaceId = value.Workspace.ToString("N"),
                ModId = value.Mod.ToString("N"),
                LinkRevision = value.LinkRevision,
                ModRevision = value.ModRevision,
                VersionId =
                    (value.Version
                     |> Option.map (fun id -> id.ToString("N"))
                     |> Option.defaultValue "")
            )

        value.Identity |> Option.iter (fun identity -> wire.ProviderMod <- identity.Mod)
        wire

    let details (value: ModConductor.Nexus.ModNexusDetails) =
        let wire =
            ModConductor.Protocol.V1.ModNexusDetails(
                Reference = reference value,
                LocalName = value.Name,
                Freshness =
                    (match value.Freshness with
                     | NexusFreshness.Current -> "current"
                     | NexusFreshness.Stale -> "stale"
                     | NexusFreshness.Unavailable -> "unavailable"),
                Problem = defaultArg value.Problem ""
            )

        value.Installed
        |> Option.iter (fun file ->
            wire.InstalledFile <- file.Id
            wire.InstalledVersion <- file.Version
            wire.LinkedManually <- file.Manual)

        value.Checked
        |> Option.iter (fun date -> wire.CheckedUnixMs <- date.ToUnixTimeMilliseconds())

        value.CategoryMapping
        |> Option.iter (fun category ->
            wire.CategoryId <- category.CategoryId.ToString("N")
            wire.Category <- category.Label)

        value.Snapshot
        |> Option.iter (fun metadata ->
            let info =
                NexusPublicMetadata(
                    Name = metadata.Name,
                    Summary = metadata.Summary,
                    Version = metadata.Version,
                    Author = metadata.Author,
                    Uploader = metadata.Uploader,
                    Available = metadata.Available,
                    AllowsRating = metadata.AllowsRating
                )

            metadata.Category
            |> Option.iter (fun (id, label) ->
                info.CategoryId <- id
                info.Category <- label)

            metadata.Modified
            |> Option.iter (fun date -> info.ModifiedUnixMs <- date.ToUnixTimeMilliseconds())

            let candidates =
                NexusUpdates.candidates value.Installed metadata
                |> List.map (fun file -> file.File.Id)
                |> Set.ofList

            for file in metadata.Files do
                let item =
                    ModConductor.Protocol.V1.NexusMetadataFile(
                        File = NexusWire.file file.File,
                        CategoryId = file.CategoryId,
                        UpdateCandidate = candidates.Contains file.File.Id
                    )

                file.Uploaded
                |> Option.iter (fun date -> item.UploadedUnixMs <- date.ToUnixTimeMilliseconds())

                info.Files.Add item

            wire.Metadata <- info)

        wire

    let reply =
        function
        | Ok value -> ModNexusReply(Details = details value)
        | Error error -> ModNexusReply(Failure = NexusWire.failure error)

    let expected (store: NexusModDetails) (request: ModNexusReference) =
        task {
            if isNull request then
                ModLibraryWire.reject "Reopen mod details."

            let! result =
                store.Read(ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.ModId)

            return
                result
                |> Result.bind (fun value ->
                    let actual = reference value

                    if
                        actual.LinkRevision <> request.LinkRevision
                        || actual.VersionId <> request.VersionId
                        || actual.HasProviderMod <> request.HasProviderMod
                        || actual.ProviderMod <> request.ProviderMod
                    then
                        Error NexusProblem.ModChanged
                    else
                        Ok
                            { value with
                                ModRevision = request.ModRevision })
        }

    let interaction (value: ModConductor.Nexus.NexusInteractions) =
        let wire = ModNexusInteractionState(Revision = value.Revision, Busy = value.Busy)
        value.AccountName |> Option.iter (fun name -> wire.AccountName <- name)
        value.Tracking |> Option.iter (fun tracked -> wire.Tracking <- tracked)

        value.Endorsement
        |> Option.iter (fun state ->
            wire.Endorsement <-
                (match state with
                 | NexusEndorsement.Endorsed -> "endorsed"
                 | NexusEndorsement.Abstained -> "abstained"
                 | NexusEndorsement.Undecided -> "undecided"))

        value.Problem
        |> Option.iter (fun error -> wire.Failure <- NexusWire.failure error)

        wire
