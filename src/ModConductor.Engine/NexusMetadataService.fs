namespace ModConductor.Engine

open System
open ModConductor.Nexus
open ModConductor.HttpDownloads
open ModConductor.GameContexts
open ModConductor.ArtifactLibrary
open ModConductor.Protocol.V1

type NexusMetadataService
    (
        session: NexusSession,
        details: NexusModDetails,
        downloads: DownloadSession,
        games: IGameContexts
    ) =
    inherit NexusMetadata.NexusMetadataBase()

    override _.ReadModNexus(request, _) =
        task {
            let! result =
                details.Read(ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.ModId)

            return NexusMetadataWire.reply result
        }

    override _.RefreshModNexus(request, _) =
        task {
            let! expected = NexusMetadataWire.expected details request

            match expected with
            | Error error -> return NexusMetadataWire.reply (Error error)
            | Ok value ->
                let! result = details.Refresh value
                return NexusMetadataWire.reply result
        }

    override _.LinkModNexus(request, _) =
        task {
            let! expected = NexusMetadataWire.expected details request.Reference

            match expected with
            | Error error -> return NexusMetadataWire.reply (Error error)
            | Ok value when not request.HasProviderMod ->
                let! result = details.Link(value, None, None)
                return NexusMetadataWire.reply result
            | Ok value ->
                let! context = games.Read value.Workspace

                match context with
                | Ok context when
                    context.Binding
                    |> Option.exists (fun binding ->
                        binding.Evidence.DefinitionId = "skyrim-se-steam")
                    ->
                    let! metadata =
                        session.ReadMetadata
                            { Game = "skyrimspecialedition"
                              Mod = request.ProviderMod }

                    match metadata with
                    | Error error -> return NexusMetadataWire.reply (Error error)
                    | Ok metadata ->
                        let file =
                            if request.HasFileId then
                                metadata.Files
                                |> List.tryFind (fun file -> file.File.Id = request.FileId)
                                |> Option.map _.File
                            else
                                None

                        if request.HasFileId && file.IsNone then
                            return NexusMetadataWire.reply (Error NexusProblem.NotFound)
                        else
                            let! result = details.Link(value, Some metadata, file)
                            return NexusMetadataWire.reply result
                | _ -> return NexusMetadataWire.reply (Error NexusProblem.NotFound)
        }

    override _.MapModNexusCategory(request, _) =
        task {
            let! expected = NexusMetadataWire.expected details request.Reference

            match expected with
            | Error error -> return NexusMetadataWire.reply (Error error)
            | Ok value when
                (value.Snapshot |> Option.bind _.Category |> Option.map fst)
                <> Some request.ProviderCategoryId
                ->
                return NexusMetadataWire.reply (Error NexusProblem.CategoryUnavailable)
            | Ok value ->
                let! result = details.MapCategory(value, ModLibraryWire.id request.CategoryId)
                return NexusMetadataWire.reply result
        }

    override _.DownloadModNexusFile(request, _) =
        task {
            let! expected = NexusMetadataWire.expected details request.Reference

            match expected, session.Status.Account with
            | Error error, _ -> return NexusDownloadReply(Failure = NexusWire.failure error)
            | _, None ->
                return NexusDownloadReply(Failure = NexusWire.failure NexusProblem.SignInRequired)
            | Ok value, Some account ->
                let! selected = details.File(value, request.FileId, request.UpdateOnly)

                match selected with
                | Error error -> return NexusDownloadReply(Failure = NexusWire.failure error)
                | Ok(value, file) ->
                    let identity = value.Identity.Value

                    let source =
                        { Account = account.Subject
                          Game = identity.Game
                          ModId = identity.Mod
                          FileId = file.Id
                          Keyed = false
                          Version = Some file.Version }

                    let! existing = downloads.FindNexus(value.Workspace, source)

                    match existing with
                    | Some artifact ->
                        return NexusDownloadReply(Artifact = ArtifactWire.artifact artifact)
                    | None ->
                        let! lease =
                            session.Resolve(identity.Game, identity.Mod, file.Id, account.Subject)

                        match lease with
                        | Error error ->
                            return NexusDownloadReply(Failure = NexusWire.failure error)
                        | Ok _ ->
                            let! result =
                                downloads.Start
                                    { Id = ModLibraryWire.id request.ArtifactId
                                      WorkspaceId = value.Workspace
                                      Name = file.Name
                                      Sources = [ DownloadSource.Nexus source ]
                                      ExpectedLength = file.Bytes
                                      ExpectedSha256 = None }

                            return
                                NexusDownloadReply(
                                    Artifact = ArtifactWire.artifact (ArtifactWire.result result)
                                )
        }
