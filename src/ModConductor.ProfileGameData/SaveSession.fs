namespace ModConductor.ProfileGameData

open System
open System.Threading.Tasks

[<Sealed>]
type internal ProfileSaveOperations
    (context: ProfileDataSessionContext, runtime: ProfileDataSessionRuntime) =
    let repository = context.Repository
    let plugins = context.Plugins
    let stopped = context.Stopped
    let previews = context.Previews
    let protect action = runtime.Protect action
    let run workspace action = runtime.Run(workspace, action)
    let resultTask = ProfileDataResultTask.resultTask
    let requireIds = ProfileDataSessionContext.requireIds
    let check = ProfileDataProjection.check
    let initial = ProfileDataActions.initial
    let execute = ProfileDataSessionContext.execute context
    let replay = ProfileDataSessionContext.replay context

    member _.SaveFiles(workspace, profile, path, after) =
        protect (fun () ->
            resultTask {
                do! requireIds [ workspace; profile ]
                let! scope = repository.Read(workspace, profile)
                let root = scope.Profile |> Option.bind _.Saves
                return! SaveBrowsing.page root path after
            })

    member _.SaveGroups(workspace, profile, source, after) =
        protect (fun () ->
            resultTask {
                do! requireIds [ workspace; profile ]
                let! scope = repository.Read(workspace, profile)
                return! SaveGroupPaging.page scope source after
            })

    member _.InspectSave(workspace, profile, source, name, headers, token) =
        protect (fun () ->
            resultTask {
                do! requireIds ([ workspace; profile ] @ (headers |> Option.toList))

                if String.IsNullOrWhiteSpace name then
                    return! Error(ProfileDataError.Invalid "Choose a current save first.")

                let! scope = repository.Read(workspace, profile)

                return!
                    SaveGroupInspection.inspect repository plugins scope source name headers token
            })

    member _.PreviewSaveAction(expected: ProfileDataRef, action: ProfileSaveAction, names, token) =
        protect (fun () ->
            resultTask {
                do! requireIds [ expected.WorkspaceId; expected.ProfileId; expected.ContextId ]

                let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                do! check scope expected
                stopped scope.Game
                let id = Guid.NewGuid()

                let! receipt, source, destination, files =
                    SaveGroups.prepare id scope action names token

                let preview =
                    { Id = id
                      Expected = expected
                      Action = action
                      Source = source
                      Destination = destination
                      Files = files
                      Bytes = files |> List.sumBy _.Bytes }

                previews.RememberSave(preview, receipt)
                return preview
            })

    member _.ApplySaveAction(id, previewId, expected: ProfileDataRef, progress, token) =
        run expected.WorkspaceId (fun () ->
            resultTask {
                do!
                    requireIds
                        [ id
                          previewId
                          expected.WorkspaceId
                          expected.ProfileId
                          expected.ContextId ]

                let! prior = repository.Action(expected.WorkspaceId, id)

                let! receipt =
                    match prior with
                    | Some previous ->
                        match previous.Kind with
                        | ProfileDataActionKind.SaveFiles receipt when
                            previous.ProfileId = expected.ProfileId
                            && previous.ExpectedRevision = expected.Revision
                            && receipt.PreviewId = previewId
                            ->
                            Ok receipt
                        | _ -> Error ProfileDataError.Stale
                    | None ->
                        match previews.ClaimSave(previewId, expected) with
                        | Some(_, receipt) -> Ok receipt
                        | _ -> Error ProfileDataError.Stale

                let kind = ProfileDataActionKind.SaveFiles receipt

                let! replayResult =
                    replay expected.WorkspaceId expected.ProfileId id kind expected.Revision

                let! replayed = replayResult

                match replayed with
                | Some result -> return result
                | None ->
                    let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                    do! check scope expected
                    stopped scope.Game
                    do! SaveGroups.checkReceipt scope receipt token
                    let! context = DataInitialization.context repository scope

                    let! action =
                        repository.Claim(context, initial id context scope.ProfileId kind)

                    let! result =
                        execute (
                            ignore,
                            None,
                            scope,
                            context,
                            action,
                            token,
                            progress,
                            (fun _ -> Task.FromResult())
                        )

                    return result
            })
