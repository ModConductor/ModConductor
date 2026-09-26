namespace ModConductor.Engine

open System
open ModConductor.ArtifactLibrary
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Skse

type internal SkseSources
    (nexus: NexusSession, downloads: DownloadSession, games: IGameContexts, store: OperationStore) =

    member _.Reference(selection: StoredSkseSelection, keyed) =
        let release = selection.Selection.Release

        { Account = selection.AccountId
          Game = "skyrimspecialedition"
          ModId = release.ModId
          FileId = release.File.Id
          Keyed = keyed
          Version = Some release.File.Version }

    member _.ResolveContext(workspace, profile, context: GameContextState) =
        task {
            let! source = nexus.ReadMod("skyrimspecialedition", SkseResolver.NexusModId)

            return
                source
                |> Result.mapError (NexusProblem.message >> SkseProblem.SourceUnavailable)
                |> Result.bind (fun source ->
                    SkseResolver.select context (SkseResolver.releases source) nexus.Status.Account)
                |> Result.map (fun selection ->
                    let gameVersion, gameSha256 = SkseStatus.facts context

                    context,
                    { ArtifactId = None
                      WorkspaceId = workspace
                      ProfileId = Some profile
                      AccountId = nexus.Status.Account.Value.Subject
                      GameVersion = gameVersion
                      GameSha256 = gameSha256
                      Selection = selection
                      CheckedAt = DateTimeOffset.UtcNow })
        }

    member this.Resolve(workspace, profile) =
        task {
            let! context = games.Read(workspace, profile)

            match context with
            | Error _ -> return Error SkseProblem.GameUnavailable
            | Ok context -> return! this.ResolveContext(workspace, profile, context)
        }

    member _.Cached(context: GameContextState, workspace) =
        task {
            match nexus.Status.Account with
            | None -> return None
            | Some account ->
                let _, gameSha256 = SkseStatus.facts context
                return! store.SkseLoaders.Cached(workspace, account.Subject, gameSha256)
        }

    member this.RetainedArchive(workspace, profile) =
        task {
            let! context = games.Read(workspace, profile)
            let! deployed = store.Deployments.Read profile

            match context, deployed with
            | Ok context, Ok deployed when
                context.Binding.IsSome && deployed.WorkspaceId = workspace
                ->
                let! installed =
                    store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match installed with
                | Some _ -> return None
                | None ->
                    let! cached = this.Cached(context, workspace)

                    match cached with
                    | None -> return None
                    | Some selection ->
                        let! artifact = store.Artifacts.Read(workspace, selection.ArtifactId.Value)

                        return
                            artifact
                            |> Result.toOption
                            |> Option.map (fun value -> context, selection, value)
            | _ -> return None
        }

    member _.SaveArtifact(artifact: Artifact, selection: StoredSkseSelection) =
        store.SkseLoaders.SaveArtifactSelection(
            artifact,
            { selection with
                ArtifactId = Some artifact.Id }
        )
