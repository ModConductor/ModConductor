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
                    let! scope = repository.Read(workspace, profile)
                    let! _ = PluginOrders.forLaunch plugins scope token
                    return ()
                })

        member _.Read(workspace, profile, headers) =
            protect (fun () ->
                task {
                    let! value = PluginOrders.read repository plugins workspace profile headers
                    return Ok value
                })

        member _.Change(expected, headers, change) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! value =
                        PluginOrders.save repository plugins expected headers (Some change)

                    return Ok value
                })

        member _.UseGameOrder(expected, headers) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! value = PluginOrders.save repository plugins expected headers None
                    return Ok value
                })

        member _.ApplyExactOrder(expected, headers, names) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! value =
                        PluginOrders.save
                            repository
                            plugins
                            expected
                            headers
                            (Some(ModConductor.Bethesda.PluginOrderChange.Replace names))

                    return Ok value
                })
