namespace ModConductor.ProfileGameData

open System
open System.Threading.Tasks

[<Sealed>]
type internal ProfilePluginOrderOperations
    (context: ProfileDataSessionContext, runtime: ProfileDataSessionRuntime) =
    let repository = context.Repository
    let plugins = context.Plugins
    let protect action = runtime.Protect action
    let run workspace action = runtime.Run(workspace, action)
    let resultTask = ProfileDataResultTask.resultTask
    let requireIds = ProfileDataSessionContext.requireIds

    interface IProfilePluginOrders with
        member _.PreflightForLaunch(workspace, profile, token) =
            protect (fun () ->
                resultTask {
                    do! requireIds [ workspace; profile ]
                    let! scopeResult = repository.Read(workspace, profile)
                    let! scope = scopeResult
                    let! preflight = PluginOrders.forLaunch plugins scope token
                    let! _ = preflight
                    return ()
                })

        member _.Read(workspace, profile, headers) =
            protect (fun () -> PluginOrders.read repository plugins workspace profile headers)

        member _.Change(expected, headers, change) =
            run expected.WorkspaceId (fun () ->
                PluginOrders.save repository plugins expected headers (Some change))

        member _.UseGameOrder(expected, headers) =
            run expected.WorkspaceId (fun () ->
                PluginOrders.save repository plugins expected headers None)

        member _.ApplyExactOrder(expected, headers, names) =
            run expected.WorkspaceId (fun () ->
                PluginOrders.save
                    repository
                    plugins
                    expected
                    headers
                    (Some(ModConductor.Bethesda.PluginOrderChange.Replace names)))
