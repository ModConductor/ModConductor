namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal EnbNxmIngress
    (
        nexus: NexusSession,
        downloads: DownloadSession,
        store: OperationStore,
        acquisition: EnbAcquisition,
        persist: Guid -> Guid -> Guid option -> string option -> EnbView -> Task<EnbView>,
        view: EnbPhase -> string -> string -> EnbView,
        signal: Guid * Guid -> unit,
        cancelActive: Guid * Guid -> unit
    ) =
    let reference = acquisition.Reference

    member _.Accept(id: Guid) =
        Task.Run(fun () ->
            task {
                let! pending = store.EnbSetups.Pending()

                let failSources title detail (sources: StoredEnbPendingSource list) =
                    task {
                        for source in sources do
                            let! _ =
                                persist
                                    source.WorkspaceId
                                    source.ProfileId
                                    (Some source.RuntimeArtifactId)
                                    (Some source.RuntimeSha256)
                                    (view EnbPhase.Failed title detail)

                            cancelActive (source.WorkspaceId, source.ProfileId)

                            ()
                    }

                match nexus.ReadNxm id, nexus.Status.Account with
                | Ok file, Some account ->
                    let expected =
                        pending
                        |> List.filter (fun value ->
                            value.NexusModId = file.ModId && value.File.Id = file.FileId)

                    let matches =
                        expected |> List.filter (fun value -> value.AccountId = account.Subject)

                    match matches, expected with
                    | source :: _, _ ->
                        match nexus.AdmitNxm(id, account.Subject) with
                        | Ok admitted ->
                            use admitted = admitted
                            let! metadata = nexus.ReadFile(file.Game, file.ModId, file.FileId)

                            match metadata with
                            | Ok metadata ->
                                let! started =
                                    downloads.Start
                                        { Id = Guid.NewGuid()
                                          WorkspaceId = source.WorkspaceId
                                          Name = metadata.Name
                                          Sources =
                                            [ DownloadSource.Nexus(
                                                  reference
                                                      account.Subject
                                                      source.NexusModId
                                                      metadata
                                                      file.Keyed
                                              ) ]
                                          ExpectedLength = metadata.Bytes
                                          ExpectedSha256 = None }

                                if Result.isOk started then
                                    admitted.Complete()
                                    signal (source.WorkspaceId, source.ProfileId)
                                else
                                    do!
                                        failSources
                                            "The Nexus download could not start"
                                            "Retry Mod Manager Download for this Lean ENB component."
                                            [ source ]
                            | Error problem ->
                                do!
                                    failSources
                                        "Nexus file details are unavailable"
                                        (NexusProblem.message problem)
                                        [ source ]
                        | Error problem ->
                            do!
                                failSources
                                    "The Nexus download was refused"
                                    problem.Detail
                                    [ source ]
                    | [], _ :: _ ->
                        do!
                            failSources
                                "Nexus account changed"
                                "Use the Nexus account that started this ENB setup."
                                expected
                    | [], [] -> ()
                | Ok file, None ->
                    let expected =
                        pending
                        |> List.filter (fun value ->
                            value.NexusModId = file.ModId && value.File.Id = file.FileId)

                    do!
                        failSources
                            "Sign in to Nexus Mods"
                            "Use the Nexus account that started this ENB setup."
                            expected
                | Error _, _ -> ()
            }
            :> Task)
        |> ignore
