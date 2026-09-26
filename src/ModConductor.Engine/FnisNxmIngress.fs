namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence

type private NxmRejection =
    { Title: string
      Detail: string
      Selections: StoredFnisSelection list }

module internal FnisNxmIngress =
    let private failPending
        (store: OperationStore)
        (failed:
            Guid * Guid * string * int64 option * Guid option * string * string -> Task<FnisView>)
        (rejection: NxmRejection)
        =
        task {
            for selection in rejection.Selections do
                let! _ =
                    failed (
                        selection.WorkspaceId,
                        selection.ProfileId.Value,
                        string selection.Selection.Release.ComponentVersion,
                        Some selection.Selection.Release.File.Id,
                        None,
                        rejection.Title,
                        rejection.Detail
                    )

                do! store.FnisSetups.RemovePending selection.ProfileId.Value
        }

    let private authorize (file: NxmFile) (pending: StoredFnisSelection list) account =
        let expected =
            pending
            |> List.filter (fun selection ->
                file.Game = "skyrimspecialedition"
                && file.ModId = selection.Selection.Release.ModId
                && file.FileId = selection.Selection.Release.File.Id)

        match expected, account with
        | [], _ ->
            Error
                { Title = "This Nexus link is not the expected FNIS file"
                  Detail = "Use Mod Manager Download for FNIS Behavior SE 7.6."
                  Selections = pending }
        | _, None ->
            Error
                { Title = "Sign in to Nexus Mods"
                  Detail = "Use the Nexus account that started this FNIS setup."
                  Selections = expected }
        | _, Some account ->
            let matches =
                expected |> List.filter (fun value -> value.AccountId = account.Subject)

            match matches with
            | [] ->
                Error
                    { Title = "Nexus account changed"
                      Detail = "Use the Nexus account that started this FNIS setup."
                      Selections = expected }
            | selection :: _ -> Ok(account, selection, matches)

    let private acquire
        (nexus: NexusSession)
        (downloads: DownloadSession)
        (sources: FnisSources)
        (file: NxmFile)
        (selection: StoredFnisSelection)
        =
        task {
            let! metadata = nexus.ReadFile(file.Game, file.ModId, file.FileId)

            match metadata with
            | Error problem ->
                return Error("FNIS file details are unavailable", NexusProblem.message problem)
            | Ok metadata ->
                let selection =
                    { selection with
                        Selection =
                            { selection.Selection with
                                Release =
                                    { selection.Selection.Release with
                                        File = metadata } }
                        CheckedAt = DateTimeOffset.UtcNow }

                let! started =
                    downloads.Start
                        { Id = Guid.NewGuid()
                          WorkspaceId = selection.WorkspaceId
                          Name = metadata.Name
                          Sources =
                            [ DownloadSource.Nexus(sources.Reference(selection, file.Keyed)) ]
                          ExpectedLength = metadata.Bytes
                          ExpectedSha256 = None }

                return
                    match started with
                    | Error problem -> Error("FNIS download could not start", string problem)
                    | Ok artifact -> Ok(selection, artifact)
        }

    let private acceptFile
        (nexus: NexusSession)
        (downloads: DownloadSession)
        (store: OperationStore)
        (sources: FnisSources)
        failed
        prepareArtifact
        pending
        (id: Guid)
        (file: NxmFile)
        =
        task {
            match authorize file pending nexus.Status.Account with
            | Error rejection -> do! failPending store failed rejection
            | Ok(account, selection, matches) ->
                match nexus.AdmitNxm(id, account.Subject) with
                | Error problem ->
                    do!
                        failPending
                            store
                            failed
                            { Title = problem.Title
                              Detail = problem.Detail
                              Selections = matches }
                | Ok admitted ->
                    use admitted = admitted
                    let! acquired = acquire nexus downloads sources file selection

                    match acquired with
                    | Error(title, detail) ->
                        do!
                            failPending
                                store
                                failed
                                { Title = title
                                  Detail = detail
                                  Selections = matches }
                    | Ok(selection, artifact) ->
                        admitted.Complete()
                        do! store.FnisSetups.RemovePending selection.ProfileId.Value

                        let! _ =
                            prepareArtifact
                                (selection.WorkspaceId, selection.ProfileId.Value)
                                selection
                                artifact
                                "Downloading FNIS"

                        ()
        }

    let accept
        (nexus: NexusSession)
        (downloads: DownloadSession)
        (store: OperationStore)
        (sources: FnisSources)
        (failed:
            Guid * Guid * string * int64 option * Guid option * string * string -> Task<FnisView>)
        (prepareArtifact:
            (Guid * Guid) -> StoredFnisSelection -> Artifact -> string -> Task<FnisView>)
        (id: Guid)
        =
        Task.Run(fun () ->
            task {
                let! pending = store.FnisSetups.Pending()

                match nexus.ReadNxm id with
                | Error problem ->
                    do!
                        failPending
                            store
                            failed
                            { Title = problem.Title
                              Detail = problem.Detail
                              Selections = pending }
                | Ok file ->
                    do!
                        acceptFile
                            nexus
                            downloads
                            store
                            sources
                            failed
                            prepareArtifact
                            pending
                            id
                            file
            }
            :> Task)
        |> ignore
