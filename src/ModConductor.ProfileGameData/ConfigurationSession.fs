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
    let requireIds = ProfileDataSessionContext.requireIds
    let read = ProfileDataSessionContext.read context
    let check = ProfileDataProjection.check
    let initial = ProfileDataActions.initial
    let execute = ProfileDataSessionContext.execute context
    let replay = ProfileDataSessionContext.replay context

    let prepareEdit (request: ProfileConfigurationEdit) token prior =
        task {
            let! scope, kind, archiveBefore =
                match prior with
                | Some previous ->
                    match previous.Kind with
                    | ProfileDataActionKind.EditConfiguration receipt when
                        previous.ProfileId = request.Expected.ProfileId
                        && previous.ExpectedRevision = request.Expected.Revision
                        && receipt.PreviewId = request.PreviewId
                        && receipt.Name.Equals(request.Name, StringComparison.OrdinalIgnoreCase)
                        ->
                        task {
                            let! scope =
                                repository.Read(
                                    request.Expected.WorkspaceId,
                                    request.Expected.ProfileId
                                )

                            return scope, previous.Kind, None
                        }
                    | _ -> raise (ProfileDataException ProfileDataError.Stale)
                | None ->
                    task {
                        let! scope =
                            repository.Read(
                                request.Expected.WorkspaceId,
                                request.Expected.ProfileId
                            )

                        check scope request.Expected

                        let preview =
                            previews.ClaimConfiguration(
                                request.PreviewId,
                                request.Expected,
                                request.Name
                            )
                            |> Option.defaultWith (fun () ->
                                raise (ProfileDataException ProfileDataError.Stale))

                        let bytes =
                            ModConductor.FilePlanning.TextDocuments.encode
                                preview.Public.Document
                                request.Content
                            |> Result.defaultWith (fun detail ->
                                raise (ProfileDataException(ProfileDataError.Invalid detail)))

                        ConfigurationFiles.check scope preview token

                        if bytes = preview.Bytes then
                            raise (
                                ProfileDataException(
                                    ProfileDataError.Invalid "The file has no changes to save."
                                )
                            )

                        return
                            scope,
                            ProfileDataActionKind.EditConfiguration
                                { PreviewId = preview.Public.PreviewId
                                  Name = preview.Public.Name
                                  Before = preview.Before
                                  Bytes = bytes },
                            (if preview.Public.Name = "Skyrim.ini" then
                                 Some preview.Bytes
                             else
                                 None)
                    }

            return scope, kind, archiveBefore
        }

    member _.ConfigurationFiles(expected: ProfileDataRef, token) =
        protect (fun () ->
            task {
                requireIds [ expected.WorkspaceId; expected.ProfileId; expected.ContextId ]

                let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                check scope expected
                return Ok(ConfigurationFiles.list scope token)
            })

    member _.ReadConfiguration(expected: ProfileDataRef, name, token) =
        protect (fun () ->
            task {
                requireIds [ expected.WorkspaceId; expected.ProfileId; expected.ContextId ]

                if String.IsNullOrWhiteSpace name then
                    raise (
                        ProfileDataException(
                            ProfileDataError.Invalid "Choose a profile settings file first."
                        )
                    )

                let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                check scope expected
                let preview = ConfigurationFiles.read scope expected name token
                previews.RememberConfiguration preview
                return Ok preview.Public
            })

    member _.SaveConfiguration(request: ProfileConfigurationEdit, progress, token) =
        run request.Expected.WorkspaceId (fun () ->
            task {
                requireIds
                    [ request.Id
                      request.PreviewId
                      request.Expected.WorkspaceId
                      request.Expected.ProfileId
                      request.Expected.ContextId ]

                let! prior = repository.Action(request.Expected.WorkspaceId, request.Id)

                let! scope, kind, archiveBefore = prepareEdit request token prior

                let! replayed =
                    replay
                        request.Expected.WorkspaceId
                        request.Expected.ProfileId
                        request.Id
                        kind
                        request.Expected.Revision

                match replayed with
                | Some result -> return Ok result
                | None ->
                    check scope request.Expected

                    prior
                    |> Option.iter (fun action -> ConfigurationFiles.checkResume action token)

                    let context =
                        scope.Context
                        |> Option.defaultWith (fun () ->
                            raise (ProfileDataException ProfileDataError.NotFound))

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
                        let priorNames = ArchivePolicies.explicitNames before

                        if priorNames <> ArchivePolicies.explicitNames receipt.Bytes then
                            archives.NoteSettingsEdit(scope.ProfileId, priorNames)
                    | _ -> ()

                    return Ok result
            })

    member _.RestoreConfiguration(workspace, id, token) =
        run workspace (fun () ->
            task {
                requireIds [ workspace; id ]
                let! previous = repository.Action(workspace, id)

                let action =
                    previous
                    |> Option.defaultWith (fun () ->
                        raise (ProfileDataException ProfileDataError.NotFound))

                if action.Complete then
                    raise (
                        ProfileDataException(
                            ProfileDataError.Invalid
                                "This profile file edit has already completed."
                        )
                    )

                match action.Kind with
                | ProfileDataActionKind.EditConfiguration _ -> ()
                | _ ->
                    raise (
                        ProfileDataException(
                            ProfileDataError.Invalid "This action is not a profile file edit."
                        )
                    )

                let! scope = repository.Read(workspace, action.ProfileId)

                let context =
                    scope.Context
                    |> Option.defaultWith (fun () ->
                        raise (ProfileDataException ProfileDataError.NotFound))

                let! claimed = repository.Claim(context, action)

                try
                    ConfigurationFiles.restoreOriginal claimed token
                    do! repository.Complete(context, None, claimed)
                with error ->
                    do! repository.Release claimed.Id
                    raise error

                let! state = read workspace action.ProfileId

                return
                    Ok
                        { Id = id
                          State = state
                          Complete = true
                          NoChange = false
                          CompletedFiles = 0
                          Problem = None }
            })
