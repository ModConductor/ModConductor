namespace ModConductor.Engine

open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Protocol.V1
open ModConductor.Skse

type internal SkseSetupReader
    (
        games: IGameContexts,
        store: OperationStore,
        sources: SkseSources,
        monitor: SkseSetupMonitor,
        statuses: SkseStatusStore
    ) =
    let available gameVersion =
        { Phase = SksePhase.Available
          GameVersion = gameVersion
          ComponentVersion = ""
          Status = "SKSE is not installed"
          Detail = ""
          FileId = None }

    let updateState
        (context: ModConductor.GameContexts.GameContextState)
        (loader: StoredSkseLoader)
        (selection: StoredSkseSelection)
        =
        let latest = selection.Selection.Release.ComponentVersion

        if SkseStatus.newerVersion (string latest) loader.Loader.ComponentVersion then
            { Phase = SksePhase.UpdateAvailable
              GameVersion = fst (SkseStatus.facts context)
              ComponentVersion = string latest
              Status = "SKSE update available"
              Detail = ""
              FileId = Some selection.Selection.Release.File.Id }
        else
            SkseStatus.installedState context loader None

    let mayPublish workspace profile (loader: StoredSkseLoader) =
        task {
            let! current = store.Deployments.Read profile

            let! active =
                store.SkseLoaders.ReadStored(
                    workspace,
                    profile,
                    current |> Result.toOption |> Option.bind _.ActiveGeneration
                )

            let! latestStatus = store.SkseLoaders.ReadStatus(workspace, profile)

            let sameLoader =
                active
                |> Option.exists (fun value ->
                    value.VersionId = loader.VersionId
                    && value.Loader.GenerationId = loader.Loader.GenerationId)

            let busyOrFailed =
                latestStatus
                |> Option.exists (fun state ->
                    state.Phase = "waiting"
                    || state.Phase = "downloading"
                    || state.Phase = "installing"
                    || state.Phase = "failed")

            return not (monitor.IsActive(workspace, profile) || not sameLoader || busyOrFailed)
        }

    member private _.ReadActive
        (
            workspace,
            profile,
            context: ModConductor.GameContexts.GameContextState,
            deployed: ModConductor.Deployment.DeploymentStatus
        ) =
        task {
            let! saved = store.SkseLoaders.ReadStatus(workspace, profile)

            match saved with
            | Some state when state.Phase = "waiting" || state.Phase = "failed" ->
                return SkseStatus.fromStored state
            | Some state when state.Phase = "downloading" || state.Phase = "installing" ->
                if monitor.IsActive(workspace, profile) then
                    return SkseStatus.fromStored state
                else
                    return!
                        statuses.Failed
                            (workspace, profile)
                            state.GameVersion
                            state.ComponentVersion
                            state.NexusFileId
                            "SKSE setup stopped"
                            "Select Try again to install the downloaded archive."
            | _ ->
                let! loader =
                    store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                return
                    loader
                    |> Option.map (fun value -> SkseStatus.installedState context value saved)
                    |> Option.defaultWith (fun () -> available (fst (SkseStatus.facts context)))
        }

    member this.Read(workspace, profile) =
        task {
            let! context = games.Read(workspace, profile)
            let! deployed = store.Deployments.Read profile

            match context, deployed with
            | Ok context, Ok deployed when
                context.Binding.IsSome && deployed.WorkspaceId = workspace
                ->
                return! this.ReadActive(workspace, profile, context, deployed)
            | _ -> return! statuses.Unavailable (workspace, profile) SkseProblem.GameUnavailable
        }

    member private this.PublishUpdate
        (
            workspace,
            profile,
            context: ModConductor.GameContexts.GameContextState,
            loader: StoredSkseLoader,
            saved: StoredSkseStatus option,
            selection: StoredSkseSelection
        ) =
        task {
            let! current = mayPublish workspace profile loader

            if not current then
                return! this.Read(workspace, profile)
            else
                let state = updateState context loader selection

                let! published =
                    store.SkseLoaders.SaveCheckedUpdateStatus(
                        loader.Loader.GenerationId,
                        loader.VersionId,
                        saved,
                        SkseStatus.storedStatus (workspace, profile) state
                    )

                if published then
                    return state
                else
                    return! this.Read(workspace, profile)
        }

    member private this.CheckInstalled
        (
            workspace,
            profile,
            context: ModConductor.GameContexts.GameContextState,
            loader: StoredSkseLoader
        ) =
        task {
            let! saved = store.SkseLoaders.ReadStatus(workspace, profile)

            match saved with
            | Some state when
                state.Phase = "waiting"
                || state.Phase = "downloading"
                || state.Phase = "installing"
                ->
                return SkseStatus.fromStored state
            | _ ->
                let! resolved = sources.ResolveContext(workspace, profile, context)

                match resolved with
                | Error _ -> return! this.Read(workspace, profile)
                | Ok(_, selection) ->
                    return!
                        this.PublishUpdate(workspace, profile, context, loader, saved, selection)
        }

    member this.CheckUpdate(workspace, profile) =
        task {
            let! context = games.Read(workspace, profile)
            let! deployed = store.Deployments.Read profile

            match context, deployed with
            | Ok context, Ok deployed when
                context.Binding.IsSome && deployed.WorkspaceId = workspace
                ->
                let! loader =
                    store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match loader with
                | None -> return available (fst (SkseStatus.facts context))
                | Some loader -> return! this.CheckInstalled(workspace, profile, context, loader)
            | _ ->
                return
                    { Phase = SksePhase.Unavailable
                      GameVersion = ""
                      ComponentVersion = ""
                      Status = "SKSE is unavailable"
                      Detail = ""
                      FileId = None }
        }

    member _.CheckBeforePlay(workspace, profile) =
        task {
            let! deployed = store.Deployments.Read profile

            match deployed with
            | Error _ -> return Ok()
            | Ok deployed ->
                let! loader =
                    store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match loader with
                | None -> return Ok()
                | Some loader ->
                    let! context = games.Read(workspace, profile)

                    match context with
                    | Error _ ->
                        return Error "Refresh the selected Skyrim installation before Play."
                    | Ok context when context.Binding.IsSome ->
                        let _, gameSha256 = SkseStatus.facts context

                        return
                            if loader.Loader.GameSha256 = gameSha256 then
                                Ok()
                            else
                                Error "The installed SKSE loader is for a different Skyrim build."
                    | Ok _ -> return Error "Refresh the selected Skyrim installation before Play."
        }
