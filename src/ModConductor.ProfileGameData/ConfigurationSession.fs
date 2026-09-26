namespace ModConductor.ProfileGameData

open System
open System.Threading.Tasks

[<Sealed>]
type internal ProfileConfigurationOperations
    (context: ProfileDataSessionContext, runtime: ProfileDataSessionRuntime) =
    let repository = context.Repository
    let archives = context.Archives
    let previews = context.Previews
    let configurationCheckpoint = context.ConfigurationCheckpoint
    let protect action = runtime.Protect action
    let run workspace action = runtime.Run(workspace, action)
    let resultTask = ProfileDataResultTask.resultTask
    let requireIds = ProfileDataSessionContext.requireIds
    let read = ProfileDataSessionContext.read context
    let check = ProfileDataProjection.check
    let initial = ProfileDataActions.initial
    let execute = ProfileDataSessionContext.execute context
    let replay = ProfileDataSessionContext.replay context

    let prepareEdit (request: ProfileConfigurationEdit) token prior =
        resultTask {
            let matchingPrior =
                match prior with
                | Some previous ->
                    match previous.Kind with
                    | ProfileDataActionKind.EditConfiguration receipt ->
                        previous.ProfileId = request.Expected.ProfileId
                        && previous.ExpectedRevision = request.Expected.Revision
                        && receipt.PreviewId = request.PreviewId
                        && receipt.Name.Equals(request.Name, StringComparison.OrdinalIgnoreCase)
                    | _ -> false
                | None -> true

            if not matchingPrior then
                return! Error ProfileDataError.Stale

            let! scope = repository.Read(request.Expected.WorkspaceId, request.Expected.ProfileId)

            match prior with
            | Some previous -> return scope, previous.Kind, None
            | None ->
                do! check scope request.Expected

                let! preview =
                    match
                        previews.ClaimConfiguration(
                            request.PreviewId,
                            request.Expected,
                            request.Name
                        )
                    with
                    | Some value -> Ok value
                    | None -> Error ProfileDataError.Stale

                let! bytes =
                    ModConductor.FilePlanning.TextDocuments.encode
                        preview.Public.Document
                        request.Content
                    |> Result.mapError ProfileDataError.Invalid

                ConfigurationFiles.check scope preview token

                if bytes = preview.Bytes then
                    return! Error(ProfileDataError.Invalid "The file has no changes to save.")

                let archiveBefore =
                    if preview.Public.Name = "Skyrim.ini" then
                        Some preview.Bytes
                    else
                        None

                return
                    scope,
                    ProfileDataActionKind.EditConfiguration
                        { PreviewId = preview.Public.PreviewId
                          Name = preview.Public.Name
                          Before = preview.Before
                          Bytes = bytes },
                    archiveBefore
        }

    member _.ConfigurationFiles(expected: ProfileDataRef, token) =
        protect (fun () ->
            resultTask {
                do! requireIds [ expected.WorkspaceId; expected.ProfileId; expected.ContextId ]

                let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                do! check scope expected
                return ConfigurationFiles.list scope token
            })

    member _.ReadConfiguration(expected: ProfileDataRef, name, token) =
        protect (fun () ->
            resultTask {
                do! requireIds [ expected.WorkspaceId; expected.ProfileId; expected.ContextId ]

                if String.IsNullOrWhiteSpace name then
                    return! Error(ProfileDataError.Invalid "Choose a profile settings file first.")

                let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                do! check scope expected
                let preview = ConfigurationFiles.read scope expected name token
                previews.RememberConfiguration preview
                return preview.Public
            })

    member _.SaveConfiguration(request: ProfileConfigurationEdit, progress, token) =
        run request.Expected.WorkspaceId (fun () ->
            resultTask {
                do!
                    requireIds
                        [ request.Id
                          request.PreviewId
                          request.Expected.WorkspaceId
                          request.Expected.ProfileId
                          request.Expected.ContextId ]

                let! prior = repository.Action(request.Expected.WorkspaceId, request.Id)

                let! prepared = prepareEdit request token prior
                let! scope, kind, archiveBefore = prepared

                let! replayResult =
                    replay
                        request.Expected.WorkspaceId
                        request.Expected.ProfileId
                        request.Id
                        kind
                        request.Expected.Revision

                let! replayed = replayResult

                match replayed with
                | Some result -> return result
                | None ->
                    do! check scope request.Expected

                    prior
                    |> Option.iter (fun action -> ConfigurationFiles.checkResume action token)

                    let! context =
                        match scope.Context with
                        | Some value -> Ok value
                        | None -> Error ProfileDataError.NotFound

                    let! action =
                        repository.Claim(context, initial request.Id context scope.ProfileId kind)

                    let! result =
                        execute (
                            configurationCheckpoint,
                            None,
                            scope,
                            context,
                            action,
                            token,
                            progress,
                            (fun _ -> Task.FromResult())
                        )

                    match result.Complete, archiveBefore, kind with
                    | true, Some before, ProfileDataActionKind.EditConfiguration receipt ->
                        let priorNames = ArchivePolicyProjection.explicitNames before

                        if priorNames <> ArchivePolicyProjection.explicitNames receipt.Bytes then
                            archives.NoteSettingsEdit(scope.ProfileId, priorNames)
                    | _ -> ()

                    return result
            })

    member _.RestoreConfiguration(workspace, id, token) =
        run workspace (fun () ->
            resultTask {
                do! requireIds [ workspace; id ]
                let! previous = repository.Action(workspace, id)

                let! action =
                    match previous with
                    | Some value -> Ok value
                    | None -> Error ProfileDataError.NotFound

                if action.Complete then
                    return!
                        Error(
                            ProfileDataError.Invalid
                                "This profile file edit has already completed."
                        )

                match action.Kind with
                | ProfileDataActionKind.EditConfiguration _ -> ()
                | _ ->
                    return!
                        Error(ProfileDataError.Invalid "This action is not a profile file edit.")

                let! scope = repository.Read(workspace, action.ProfileId)

                let! context =
                    match scope.Context with
                    | Some value -> Ok value
                    | None -> Error ProfileDataError.NotFound

                let! claimed = repository.Claim(context, action)

                try
                    ConfigurationFiles.restoreOriginal claimed token
                    do! repository.Complete(context, None, claimed)
                with error ->
                    do! repository.Release claimed.Id
                    raise error

                let! state = read workspace action.ProfileId

                return
                    { Id = id
                      State = state
                      Complete = true
                      NoChange = false
                      CompletedFiles = 0
                      Problem = None }
            })
