namespace ModConductor.Engine

open System
open ModConductor.ArtifactLibrary
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence

type internal FnisSources(nexus: NexusSession, downloads: DownloadSession, store: OperationStore) =
    member _.Reference(selection: StoredFnisSelection, keyed) =
        let release = selection.Selection.Release

        { Account = selection.AccountId
          Game = "skyrimspecialedition"
          ModId = release.ModId
          FileId = release.File.Id
          Keyed = keyed
          Version = Some release.File.Version }

    member _.Resolve(workspace, profile) =
        task {
            let! game = (store.GameContexts :> IGameContexts).Read(workspace, profile)

            match game with
            | Error _ -> return Error FnisProblem.GameUnavailable
            | Ok game ->
                match FnisCatalogue.eligibility game with
                | Error problem -> return Error problem
                | Ok() ->
                    let! source = nexus.ReadMod("skyrimspecialedition", FnisCatalogue.NexusModId)

                    return
                        source
                        |> Result.mapError (NexusProblem.message >> FnisProblem.SourceUnavailable)
                        |> Result.bind FnisCatalogue.release
                        |> Result.bind (fun release ->
                            FnisCatalogue.acquisition nexus.Status.Account
                            |> Result.map (fun acquisition ->
                                { ArtifactId = None
                                  WorkspaceId = workspace
                                  ProfileId = Some profile
                                  AccountId = nexus.Status.Account.Value.Subject
                                  Selection =
                                    { Release = release
                                      Acquisition = acquisition }
                                  CheckedAt = DateTimeOffset.UtcNow }))
        }

    member _.SaveArtifact(artifact, selection) =
        store.FnisSetups.SaveArtifactSelection(
            artifact,
            { selection with
                ArtifactId = Some artifact.Id }
        )

    member _.Cached(workspace, profile) =
        task {
            match nexus.Status.Account with
            | None -> return None
            | Some account ->
                let! value = store.FnisSetups.Cached(workspace, account.Subject)

                return
                    value
                    |> Option.map (fun selected ->
                        { selected with
                            ProfileId = Some profile })
        }

    member _.Resume(workspace, artifact: Artifact) =
        task {
            match artifact.State, artifact.Download with
            | ArtifactState.Incomplete, Some download when download.State = DownloadState.Paused ->
                let! resumed = downloads.Control(workspace, artifact.Id, DownloadAction.Resume)
                return resumed |> Result.defaultValue artifact
            | ArtifactState.Incomplete, Some download when download.State = DownloadState.Failed ->
                let! restarted = downloads.Control(workspace, artifact.Id, DownloadAction.Restart)
                return restarted |> Result.defaultValue artifact
            | _ -> return artifact
        }
