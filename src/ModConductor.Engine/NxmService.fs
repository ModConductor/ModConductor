namespace ModConductor.Engine

open System
open System.Threading.Tasks
open Google.Protobuf
open ModConductor.Nexus
open ModConductor.Desktop
open ModConductor.HttpDownloads
open ModConductor.GameContexts
open ModConductor.Protocol.V1

type NxmService
    (
        session: NexusSession,
        ingress: PrivateIngress,
        downloads: DownloadSession,
        games: IGameContexts
    ) =
    inherit NexusLinks.NexusLinksBase()

    let admission = new System.Threading.SemaphoreSlim(1, 1)

    let identity (file: NxmFile) account =
        { Account = account
          Game = file.Game
          ModId = file.ModId
          FileId = file.FileId
          Keyed = file.Keyed
          Version = None }

    let read (request: NexusLinkRequest) =
        task {
            let id = ModLibraryWire.id request.Reference
            let result = NexusLinkReply()

            match session.ReadNxm id with
            | Error detail ->
                result.Problem <- detail.Title
                result.ProblemDetail <- detail.Detail
            | Ok file ->
                result.Game <-
                    (match file.Game with
                     | "skyrimspecialedition" -> "Skyrim Special Edition"
                     | "fallout4" -> "Fallout 4"
                     | _ -> "Another game")

                if file.Game <> "skyrimspecialedition" then
                    result.Problem <- "This download is for a different game"
                    result.ProblemDetail <- "Use a download for this workspace’s game."
                elif not session.Status.Configured then
                    result.Problem <- "Nexus downloads are not available in this build."
                else
                    if request.WorkspaceId <> "" then
                        let! game =
                            games.Read(
                                ModLibraryWire.id request.WorkspaceId,
                                ModLibraryWire.id request.ProfileId
                            )

                        match game with
                        | Ok value when
                            value.Binding
                            |> Option.exists (fun binding ->
                                binding.Evidence.DefinitionId =
                                    GameId.SkyrimSpecialEditionSteam)
                            ->
                            ()
                        | _ ->
                            result.Problem <-
                                "This workspace needs a matching Skyrim Special Edition game context."

                    if result.Problem = "" then
                        match session.Status.Account with
                        | None ->
                            result.Problem <- "Sign in to Nexus Mods."
                            result.SignInRequired <- true
                        | Some account ->
                            match session.ValidateNxm(id, account.Subject) with
                            | Error detail ->
                                result.Problem <- detail.Title
                                result.ProblemDetail <- detail.Detail
                            | Ok _ ->
                                let! metadata = session.ReadFile(file.Game, file.ModId, file.FileId)

                                match metadata with
                                | Error problem -> result.Problem <- NexusProblem.message problem
                                | Ok value ->
                                    result.File <- NexusWire.file value

                                    if request.WorkspaceId <> "" then
                                        let! existing =
                                            downloads.FindNexus(
                                                ModLibraryWire.id request.WorkspaceId,
                                                identity file account.Subject
                                            )

                                        existing
                                        |> Option.iter (fun artifact ->
                                            result.Artifact <- ArtifactWire.artifact artifact)

            return result
        }

    override _.ConfigureNexusIngress(request, _) =
        let descriptor = ingress.Configure request.ProcessId

        Task.FromResult(
            NexusIngressReply(
                Endpoint = descriptor.Endpoint,
                Capability = ByteString.CopyFrom descriptor.Capability,
                ProcessId = descriptor.ProcessId
            )
        )

    override _.ReadNexusLink(request, _) = read request

    override _.DownloadNexusLink(request, _) =
        task {
            do! admission.WaitAsync()

            try
                let! result = read request

                if
                    result.Problem = ""
                    && (isNull result.Artifact
                        || (result.Artifact.State <> ArchiveState.Ready
                            && result.Artifact.State <> ArchiveState.Installed))
                then
                    if request.WorkspaceId = "" then
                        result.Problem <- "Choose a workspace."
                    else
                        match session.Status.Account with
                        | None ->
                            result.Problem <- "Sign in to Nexus Mods."
                            result.SignInRequired <- true
                        | Some account ->
                            match
                                session.AdmitNxm(
                                    ModLibraryWire.id request.Reference,
                                    account.Subject
                                )
                            with
                            | Error detail ->
                                result.Problem <- detail.Title
                                result.ProblemDetail <- detail.Detail
                            | Ok prepared ->
                                use prepared = prepared
                                let file = prepared.File

                                let! started =
                                    downloads.Start
                                        { Id = Guid.NewGuid()
                                          WorkspaceId = ModLibraryWire.id request.WorkspaceId
                                          Name = result.File.Name
                                          Sources =
                                            [ DownloadSource.Nexus
                                                  { identity file account.Subject with
                                                      Version = Some result.File.Version } ]
                                          ExpectedLength =
                                            if result.File.HasBytes then
                                                Some result.File.Bytes
                                            else
                                                None
                                          ExpectedSha256 = None }

                                result.Artifact <-
                                    ArtifactWire.artifact (ArtifactWire.result started)

                                prepared.Complete()

                return result
            finally
                admission.Release() |> ignore
        }

    override _.DismissNexusLink(request, _) =
        session.DismissNxm(ModLibraryWire.id request.Reference)
        Task.FromResult(NexusStatusRequest())

    interface IDisposable with
        member _.Dispose() = admission.Dispose()
