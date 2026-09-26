namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.Platform

module internal FnisInputInspection =
    let private latest = FnisRunRows.latest
    let private outputId = FnisRunRows.outputId

    let private selectedOutput connection transaction workspace profile =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT mod_id,input_fingerprint FROM fnis_outputs WHERE profile_id=$profile AND workspace_id=$workspace"
                [ "$profile", box (string profile); "$workspace", box (string workspace) ]

        use reader = command.ExecuteReader()

        if reader.Read() then
            Some(Guid.Parse(reader.GetString 0), reader.GetString 1)
        else
            None

    let private withoutOutput (sources: PlanSources) activeOutput =
        let excluded = activeOutput |> Option.map fst

        { sources.Profile with
            Mods =
                sources.Profile.Mods
                |> List.map (fun value ->
                    if excluded = Some value.ModId then
                        { value with Enabled = false }
                    else
                        value) }

    let private effectiveFiles workspace (sources: PlanSources) (profile: ProfileSnapshot) =
        let visibility =
            Visibility.prepare
                { Planning =
                    { Profile = profile
                      Roots =
                        [ { Id = workspace
                            Policy = Skyrim.definition.TargetPolicy } ]
                      ReadOnly = []
                      Writable = [] }
                  Hidden = sources.Hidden }

        Visibility.view visibility
        |> Result.defaultWith (fun _ ->
            raise (InvalidDataException "The effective FNIS inputs are unresolved."))
        |> ignore

        Visibility.files visibility
        |> Map.toList
        |> List.choose (fun (target, resolved) ->
            match resolved with
            | Some resolved when target.Root = workspace && FnisFreshness.relevant target.Path ->
                let length, digest =
                    match resolved.Winner.Source with
                    | SourcePin.Mod(_, _, entry) -> entry.Payload.Length, entry.Payload.Sha256
                    | SourcePin.Snapshot(_, _, file) ->
                        SnapshotFile.length file,
                        SnapshotFile.sha256 file
                        |> Option.defaultWith (fun () ->
                            raise (InvalidDataException "FNIS inputs require acquired content."))

                Some
                    { Path = target.Path
                      Length = length
                      Sha256 = digest }
            | _ -> None)

    let input (database: StateDatabase) connection transaction workspace profile =
        let sources =
            FilePlanRows.read connection transaction database.OwnerId profile
            |> Result.defaultWith (fun _ ->
                raise (InvalidDataException "The FNIS inputs are unavailable."))

        if sources.Stamp.WorkspaceId <> workspace then
            raise (InvalidDataException "The selected profile belongs to another workspace.")

        let activeOutput = selectedOutput connection transaction workspace profile
        let profile = withoutOutput sources activeOutput
        let files = effectiveFiles workspace sources profile

        FnisFreshness.compute Skyrim.definition.TargetPolicy files,
        activeOutput |> Option.map snd,
        sources.Stamp.SelectionRevision

    let viewMatchesOutput connection profile generation =
        let output = outputId profile

        use query =
            Sqlite.command
                connection
                null
                "SELECT context_id FROM deployment_generations WHERE id=$id"
                [ "$id", box (string generation) ]

        let context =
            match query.ExecuteScalar() with
            | :? string as id -> Some(Guid.Parse id)
            | _ -> None

        let activeVersion =
            context
            |> Option.bind (fun context ->
                DeploymentRows.generation connection null context generation)
            |> Option.bind (fun value ->
                value.References
                |> List.tryPick (function
                    | SourcePin.Mod(modId, version, _) when modId = output -> Some version
                    | _ -> None))

        use selected =
            Sqlite.command
                connection
                null
                "SELECT version_id FROM fnis_outputs WHERE profile_id=$profile"
                [ "$profile", box (string profile) ]

        let selectedVersion =
            match selected.ExecuteScalar() with
            | :? string as id -> Some(Guid.Parse id)
            | _ -> None

        activeVersion = selectedVersion

    let inspection (database: StateDatabase) workspace profile (generator: StoredFnisGenerator) =
        database.Enqueue(fun () ->
            let fingerprint, activeFingerprint, _ =
                input database database.Connection null workspace profile

            let latest = latest database.Connection null profile

            let matchingView =
                viewMatchesOutput database.Connection profile generator.GenerationId

            let phase, status, detail =
                match latest, activeFingerprint with
                | Some run, _ when run.Busy ->
                    FnisOutputPhase.Running,
                    "FNIS is running",
                    "The previous generated output stays active until this run succeeds."
                | Some run, _ when
                    (run.Phase = FnisOutputPhase.Failed
                     || run.Phase = FnisOutputPhase.Cancelled
                     || run.Phase = FnisOutputPhase.Abandoned)
                    ->
                    run.Phase,
                    (match run.Phase with
                     | FnisOutputPhase.Cancelled -> "FNIS run was cancelled"
                     | FnisOutputPhase.Abandoned -> "FNIS run was interrupted"
                     | _ -> "FNIS run failed"),
                    (run.Problem
                     |> Option.defaultValue "The previous generated output remains active.")
                | _, None ->
                    FnisOutputPhase.Missing,
                    "FNIS output is missing",
                    "Run FNIS to create the generated behavior files for this profile."
                | _, Some previous when previous <> fingerprint ->
                    FnisOutputPhase.Stale,
                    "FNIS output is stale",
                    "Animation inputs changed. Run FNIS before playing."
                | _, Some _ when not matchingView ->
                    FnisOutputPhase.Stale,
                    "FNIS output differs from the restored deployment",
                    "Run FNIS to update the active game view."
                | Some { Phase = FnisOutputPhase.Current
                         ExitCode = Some code },
                  _ when code <> 0 ->
                    FnisOutputPhase.Current,
                    "FNIS output is available, but FNIS exited with code " + string code,
                    "Check the FNIS messages before you use these files."
                | _ ->
                    FnisOutputPhase.Current,
                    "FNIS output is current",
                    "The active generated output matches the effective animation inputs."

            { WorkspaceId = workspace
              ProfileId = profile
              GenerationId = generator.GenerationId
              Generator = generator.Executable
              Fingerprint = fingerprint
              Phase = phase
              Status = status
              Detail = detail
              LatestRunId = latest |> Option.map _.Id
              ExitCode = latest |> Option.bind _.ExitCode
              StandardOutput = latest |> Option.map _.StandardOutput |> Option.defaultValue ""
              StandardError = latest |> Option.map _.StandardError |> Option.defaultValue ""
              RunLog = latest |> Option.map _.RunLog |> Option.defaultValue "" })
