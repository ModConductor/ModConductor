namespace ModConductor.ProfileGameData

open System
open System.Threading.Tasks
open ModConductor.GameContexts

[<Sealed>]
type ProfileGameDataSession
    internal
    (
        repository: IProfileDataRepository,
        enter: Guid -> IDisposable option,
        stopped: GameContextState -> unit,
        plugins: ModConductor.Bethesda.PluginSession,
        archives: ModConductor.Bethesda.ArchivePolicySession,
        ?configurationCheckpoint: string -> unit
    ) =

    let configurationCheckpoint = defaultArg configurationCheckpoint ignore

    let previews = ProfileDataPreviewCache()
    let runtime = ProfileDataSessionRuntime(enter)

    let context =
        { Repository = repository
          Plugins = plugins
          Archives = archives
          Stopped = stopped
          ConfigurationCheckpoint = configurationCheckpoint
          Previews = previews }
        : ProfileDataSessionContext

    let protect action = runtime.Protect action
    let resultTask = ProfileDataResultTask.resultTask
    let read = ProfileDataSessionContext.read context

    let pluginOrders =
        ProfilePluginOrderOperations(context, runtime) :> IProfilePluginOrders

    let archivePolicies =
        ProfileArchivePolicyOperations(context, runtime) :> IProfileArchivePolicies

    let configurationOperations = ProfileConfigurationOperations(context, runtime)
    let saveOperations = ProfileSaveOperations(context, runtime)
    let lifecycle = ProfileDataLifecycleOperations(context, runtime)

    member internal _.RestoreAtCheckpoint(id, expected, token, checkpoint) =
        lifecycle.RestoreAtCheckpoint(id, expected, token, checkpoint)

    member internal _.RetainedSavePreviewCount = previews.RetainedSaveCount

    member _.Drain() = runtime.Drain()

    member _.TryClose(next: unit -> bool) = runtime.TryClose next

    member _.Revision(workspace, profile) = lifecycle.Revision(workspace, profile)

    member internal _.ApplyForLaunchAtCheckpoint
        (id, workspace, profile, expected, token, report, checkpoint)
        =
        lifecycle.ApplyForLaunchAtCheckpoint(
            id,
            workspace,
            profile,
            expected,
            token,
            report,
            checkpoint
        )

    member this.ApplyForLaunch(id, workspace, profile, expected, token, report) =
        this.ApplyForLaunchAtCheckpoint(id, workspace, profile, expected, token, report, ignore)

    interface IProfilePluginOrders with
        member _.PreflightForLaunch(workspace, profile, token) =
            pluginOrders.PreflightForLaunch(workspace, profile, token)

        member _.Read(workspace, profile, headers) =
            pluginOrders.Read(workspace, profile, headers)

        member _.Change(expected, headers, change) =
            pluginOrders.Change(expected, headers, change)

        member _.UseGameOrder(expected, headers) =
            pluginOrders.UseGameOrder(expected, headers)

        member _.ApplyExactOrder(expected, headers, names) =
            pluginOrders.ApplyExactOrder(expected, headers, names)

    interface IProfileArchivePolicies with
        member _.Scan(workspace, profile, headers, token) =
            archivePolicies.Scan(workspace, profile, headers, token)

        member _.Read(workspace, profile, snapshot, token) =
            archivePolicies.Read(workspace, profile, snapshot, token)

        member _.Apply(id, expected, snapshot, progress, token) =
            archivePolicies.Apply(id, expected, snapshot, progress, token)

        member _.Restore(id, expected, progress, token) =
            archivePolicies.Restore(id, expected, progress, token)

    interface IProfileGameData with
        member _.ConfigurationFiles(expected, token) =
            configurationOperations.ConfigurationFiles(expected, token)

        member _.ReadConfiguration(expected, name, token) =
            configurationOperations.ReadConfiguration(expected, name, token)

        member _.SaveConfiguration(request, progress, token) =
            configurationOperations.SaveConfiguration(request, progress, token)

        member _.RestoreConfiguration(workspace, id, token) =
            configurationOperations.RestoreConfiguration(workspace, id, token)

        member _.SaveFiles(workspace, profile, path, after) =
            saveOperations.SaveFiles(workspace, profile, path, after)

        member _.Read(workspace, profile) =
            protect (fun () ->
                resultTask {
                    do! ProfileDataSessionContext.requireIds [ workspace; profile ]
                    let! state = read workspace profile
                    return state
                })

        member _.SaveGroups(workspace, profile, source, after) =
            saveOperations.SaveGroups(workspace, profile, source, after)

        member _.InspectSave(workspace, profile, source, name, headers, token) =
            saveOperations.InspectSave(workspace, profile, source, name, headers, token)

        member _.PreviewSaveAction(expected, action, names, token) =
            saveOperations.PreviewSaveAction(expected, action, names, token)

        member _.ApplySaveAction(id, previewId, expected, progress, token) =
            saveOperations.ApplySaveAction(id, previewId, expected, progress, token)

        member _.Edit(request, progress, token) =
            lifecycle.Edit(request, progress, token)

        member _.Restore(id, expected, token) = lifecycle.Restore(id, expected, token)

        member _.Resume(workspace, id, token) = lifecycle.Resume(workspace, id, token)
