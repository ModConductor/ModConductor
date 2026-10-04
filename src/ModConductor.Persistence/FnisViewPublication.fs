namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.FilePlanning
open ModConductor.Fnis
open ModConductor.Platform

type internal FnisViewPublication(database: StateDatabase, access: LibraryAccess) =
    let desiredFiles (generation: Generation) (sources: PlanSources) output =
        let policy = generation.Roots |> List.find (fun root -> root.Id = sources.Stamp.WorkspaceId) |> _.Policy
        let key (target: TargetFile) = target.Root, TargetPolicy.key policy target.Path
        let previous = generation.References |> List.choose (function
            | SourcePin.Mod(id, _, entry) when id = output -> Some { Root = sources.Stamp.WorkspaceId; Path = entry.Path }
            | _ -> None)
        let candidate = sources.Profile.Mods |> List.find (fun row -> row.ModId = output)
        let proposed = candidate.Version.Value.Entries |> List.map (fun entry -> { Root = sources.Stamp.WorkspaceId; Path = entry.Path })
        let targets = previous @ proposed |> List.distinctBy key
        let visibility = Visibility.prepare { Planning = { Profile = sources.Profile; Roots = generation.Roots; ReadOnly = []; Writable = [] }; Hidden = sources.Hidden }
        let effective = Visibility.files visibility |> Map.toList |> List.map (fun (target, file) -> key target, file) |> Map.ofList
        targets |> List.map (fun target -> target, effective.TryFind(key target) |> Option.flatten |> Option.map _.Winner.Source)

    let read (stage: FnisRunStage) =
        let connection = database.Connection
        let workspace, profile = stage.Request.WorkspaceId, stage.Request.ProfileId
        let inputs = FnisInputInspection.read database connection null workspace profile
        match FilePlanRows.readFnisCandidate connection null database.OwnerId profile stage.Request.Id with
        | _ when (inputs |> Result.toOption |> Option.map (fun (fingerprint, _, _) -> fingerprint)) <> Some stage.Fingerprint -> Error FnisExecutionError.Stale
        | Error _ -> Error FnisExecutionError.Stale
        | Ok sources ->
            let context = sources.Context.Binding |> Option.bind (fun binding ->
                DeploymentRows.context connection null
                    (ModConductor.Deployment.DeploymentContextId.create workspace profile
                        (ModConductor.Deployment.DeploymentContextId.fingerprint binding.Evidence)))
            match context with
            | None -> Error FnisExecutionError.Stale
            | Some context when context.Pending.IsSome || context.Active <> Some stage.GenerationId -> Error FnisExecutionError.Stale
            | Some context ->
                let generation = DeploymentRows.generation connection null context.Id stage.GenerationId |> Option.get
                let output = FnisRunRows.outputId profile
                let desired = desiredFiles generation sources output
                let transient =
                    Sqlite.number connection null
                        "SELECT saved FROM deployment_generations WHERE context_id=$context AND id=$id"
                        [ "$context", box (string context.Id); "$id", box (string generation.Id) ] = 0L
                let current = FilePlanRows.stamp connection null profile |> Option.get
                let library = LibraryRows.library connection null workspace |> Option.get
                let payloads = desired |> List.map (fun (target, pin) ->
                    let payload = pin |> Option.bind (function
                        | SourcePin.Mod(_, _, entry) -> LibraryRows.payload connection null entry.Payload.Id
                        | _ -> None)
                    target, pin, payload)
                Ok((context, generation, current, library, payloads, transient), sources.Context)

    let write (context: Context) (generation: Generation) transient files links (stamp: SourceStamp) =
        let connection = database.Connection
        use transaction = connection.BeginTransaction(deferred = false)
        if DeploymentRows.context connection transaction context.Id <> Some context
           || FilePlanRows.stamp connection transaction stamp.ProfileId <> Some stamp then
            Error FnisExecutionError.Stale
        else
            let changed = { generation with Files = files }
            if transient then
                let body = DeploymentEncoding.generationBytes changed
                Sqlite.execute connection transaction
                    "UPDATE deployment_generations SET body=$body,digest=$digest WHERE context_id=$context AND id=$id"
                    [ "$body", box body; "$digest", box (DeploymentEncoding.hash body)
                      "$context", box (string context.Id); "$id", box (string generation.Id) ]
            else
                DeploymentRows.writeGeneration connection transaction context.Id changed
                Sqlite.execute connection transaction
                    "UPDATE deployment_generations SET saved=0,unavailable=(SELECT unavailable FROM deployment_generations WHERE context_id=$context AND id=$previous) WHERE context_id=$context AND id=$id"
                    [ "$context", box (string context.Id); "$previous", box (string context.Active.Value); "$id", box (string generation.Id) ]
            DeploymentRows.writeContext connection transaction
                { context with Revision = context.Revision + 1L; Active = Some generation.Id
                               Links = links |> List.map (fun link -> { link with Spec = { link.Spec with Generation = generation.Id } }) }
            transaction.Commit()
            Ok()

    let publish (stage: FnisRunStage) (token: CancellationToken) (context, previous, stamp, library, desired, transient) root =
        task {
            use held = LibraryFiles.openLibrary root library
            let location = { Path = HostPath.create (Path.Combine(HostPath.value root.Path, library.Name)) |> Result.defaultWith invalidOp; Identity = held.Identity }
            let changes = desired |> List.map (fun (target, pin, payload: StoredPayload option) ->
                target, pin, payload |> Option.map (fun payload ->
                    { Directory = location; Path = LogicalPath.create [ LibraryFiles.payloadName payload.Payload.Id ] |> Result.defaultWith (fun _ -> invalidOp "Invalid FNIS payload path.")
                      Identity = payload.Identity; OwnerGeneration = None }))
            token.ThrowIfCancellationRequested()
            let! files, links, rollback, complete = System.Threading.Tasks.Task.Run(fun () -> FnisViewFiles.apply context previous changes)
            let output = FnisRunRows.outputId stage.Request.ProfileId
            let references = previous.References |> List.filter (function SourcePin.Mod(id, _, _) -> id <> output | _ -> true)
            let outputPins = desired |> List.choose (fun (_, pin, _) -> pin) |> List.filter (function SourcePin.Mod(id, _, _) -> id = output | _ -> false)
            let generation = { previous with Id = (if transient then previous.Id else stage.Request.Id); References = references @ outputPins; Provenance = None }
            let! written =
                task {
                    try return! database.EnqueueInternal(fun () -> write context generation transient files links stamp)
                    with error ->
                        rollback ()
                        return raise error
                }
            match written with
            | Error error ->
                rollback ()
                return Error error
            | Ok() ->
                complete ()
                return Ok()
        }

    member _.Refresh(stage: FnisRunStage, token: CancellationToken) =
        task {
            let! snapshot = database.Enqueue(fun () -> read stage)
            match snapshot with
            | Error error -> return Error error
            | Ok(snapshot, game) ->
                match ModConductor.Deployment.GameProcesses.validate game with
                | Error detail -> return Error(FnisExecutionError.Unavailable detail)
                | Ok _ ->
                    let! root = access.Root stage.Request.WorkspaceId
                    match root with
                    | Error _ -> return Error(FnisExecutionError.Unavailable "The FNIS output library is unavailable.")
                    | Ok root -> return! publish stage token snapshot root
        }
