namespace ModConductor.Engine

open System
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

type SkseCoordinator
    (
        nexus: NexusSession,
        downloads: DownloadSession,
        games: IGameContexts,
        store: OperationStore,
        handoff: IOAuthHandoff
    ) =
    let status = SkseStatusStore(store)
    let sources = SkseSources(nexus, downloads, games, store)
    let monitor = new SkseSetupMonitor(downloads, store, sources, status)
    let reader = SkseSetupReader(games, store, sources, monitor, status)

    let start =
        SkseStart(nexus, downloads, games, store, handoff, sources, monitor, status)

    let nxm = SkseNxmIngress(nexus, downloads, games, store, sources, monitor, status)

    member _.Read(workspace, profile) = reader.Read(workspace, profile)
    member _.CheckUpdate(workspace, profile) = reader.CheckUpdate(workspace, profile)
    member _.Start(workspace, profile) = start.Start(workspace, profile)
    member _.AcceptNxm(id: Guid) = nxm.Accept(id)

    member _.CheckBeforePlay(workspace, profile) =
        reader.CheckBeforePlay(workspace, profile)

    member _.Changed = status.Changed

    member _.Cancel(workspace, profile) =
        task {
            let key = workspace, profile
            do! monitor.Cancel key
            do! store.SkseLoaders.RemovePending profile
            let! deployed = store.Deployments.Read profile

            match deployed with
            | Ok deployed ->
                let! installed =
                    store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match installed with
                | Some loader ->
                    let! context = games.Read(workspace, profile)

                    match context with
                    | Ok context when context.Binding.IsSome ->
                        return SkseStatus.installedState context loader None
                    | Ok _
                    | Error _ -> return! reader.Read(workspace, profile)
                | None ->
                    return!
                        status.Persist
                            key
                            { Phase = SksePhase.Available
                              GameVersion = ""
                              ComponentVersion = ""
                              Status = "SKSE setup was cancelled"
                              Detail = "No active profile generation was changed."
                              FileId = None }
            | Error _ -> return! reader.Read(workspace, profile)
        }

    member _.Remove(workspace, profile, token) =
        task {
            let! removed = store.RemoveSkse(workspace, profile, token)

            match removed with
            | Error detail -> return Error detail
            | Ok _ ->
                let! current = reader.Read(workspace, profile)
                return Ok current
        }

    member internal _.Stop() = monitor.Stop()

    interface IDisposable with
        member _.Dispose() = (monitor :> IDisposable).Dispose()
