namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.Nexus
open ModConductor.HttpDownloads
open ModConductor.GameContexts
open ModConductor.Protocol.V1

type NexusDownloadLinks(session: NexusSession) =
    interface INexusDownloadLinks with
        member _.Reject(reference, url) =
            session.RejectLease(
                reference.Game,
                reference.ModId,
                reference.FileId,
                reference.Account,
                url
            )

        member _.Resolve(reference, token) =
            task {
                let! result =
                    session
                        .Resolve(
                            reference.Game,
                            reference.ModId,
                            reference.FileId,
                            reference.Account,
                            requiresLink = reference.Keyed
                        )
                        .WaitAsync
                        token

                return
                    result
                    |> Result.map (fun lease ->
                        { Url = lease.Url
                          Expires = lease.Expires })
                    |> Result.mapError NexusProblem.message
            }

type NexusService
    (session: NexusSession, downloads: DownloadSession, games: IGameContexts, handoff: IOAuthHandoff)
    =
    inherit Nexus.NexusBase()

    let game workspace profile =
        task {
            let! result = games.Read(workspace, profile)

            match result with
            | Ok state when
                state.Binding
                |> Option.exists (fun binding ->
                    binding.Evidence.DefinitionId = GameId.SkyrimSpecialEditionSteam)
                ->
                return Ok "skyrimspecialedition"
            | Ok _
            | Error _ -> return Error NexusProblem.NotFound
        }

    override _.ReadNexusStatus(_, _) =
        task {
            do! session.SavedConnection
            return NexusWire.status session.Status
        }

    override _.BeginNexusSignIn(_, _) =
        task {
            let! value = session.SignIn()
            return NexusWire.status value
        }

    override _.CancelNexusSignIn(_, _) =
        task {
            let! value = session.CancelSignIn()
            return NexusWire.status value
        }

    override _.ConnectNexus(_, _) =
        task {
            let! value = session.Connect()
            return NexusWire.status value
        }

    override _.CheckNexusAccount(_, _) =
        task {
            let! value = session.CheckAccount()
            return NexusWire.status value
        }

    override _.SubmitNexusPersonalApiKey(request, _) =
        task {
            let! value = session.SubmitPersonalApiKey(request.ApiKey)
            return NexusWire.status value
        }

    override _.ReadNexusMod(request, _) =
        task {
            let! mapped =
                game
                    (ModLibraryWire.id request.WorkspaceId)
                    (ModLibraryWire.id request.ProfileId)

            let! result =
                match mapped with
                | Ok value -> session.ReadMod(value, request.ModId)
                | Error error -> Task.FromResult(Error error)

            return
                match result with
                | Ok value -> NexusModReply(Mod = NexusWire.modInfo value)
                | Error error -> NexusModReply(Failure = NexusWire.failure error)
        }

    override _.DownloadNexusFile(request, _) =
        task {
            do! session.SavedConnection
            let workspace = ModLibraryWire.id request.WorkspaceId
            let! mapped = game workspace (ModLibraryWire.id request.ProfileId)

            match mapped, session.Status.Account with
            | Error error, _ -> return NexusDownloadReply(Failure = NexusWire.failure error)
            | _, None ->
                return NexusDownloadReply(Failure = NexusWire.failure NexusProblem.SignInRequired)
            | Ok game, Some account ->
                let! file = session.ReadFile(game, request.ModId, request.FileId)

                match file with
                | Error error -> return NexusDownloadReply(Failure = NexusWire.failure error)
                | Ok file ->
                    let! link =
                        session.Resolve(game, request.ModId, request.FileId, account.Subject)

                    match link with
                    | Error error -> return NexusDownloadReply(Failure = NexusWire.failure error)
                    | Ok _ ->
                        let! started =
                            downloads.Start
                                { Id = ModLibraryWire.id request.ArtifactId
                                  WorkspaceId = workspace
                                  Name = file.Name
                                  Sources =
                                    [ DownloadSource.Nexus
                                          { Account = account.Subject
                                            Game = game
                                            ModId = request.ModId
                                            FileId = request.FileId
                                            Keyed = false
                                            Version = Some file.Version } ]
                                  ExpectedLength = file.Bytes
                                  ExpectedSha256 = None }

                        return
                            NexusDownloadReply(
                                Artifact = ArtifactWire.artifact (ArtifactWire.result started)
                            )
        }

    override _.OpenNexusModPage(request, context) =
        task {
            let! mapped =
                game
                    (ModLibraryWire.id request.WorkspaceId)
                    (ModLibraryWire.id request.ProfileId)

            match mapped with
            | Ok value when request.ModId > 0L ->
                do!
                    handoff.Open(
                        Uri(
                            ("https://www.nexusmods.com/"
                             + value
                             + "/mods/"
                             + (request.ModId)
                                 .ToString(System.Globalization.CultureInfo.InvariantCulture))
                        ),
                        context.CancellationToken
                    )
            | _ -> ModLibraryWire.reject "Choose an available Nexus mod."

            return NexusStatusRequest()
        }
