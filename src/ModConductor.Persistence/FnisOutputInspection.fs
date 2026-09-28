namespace ModConductor.Persistence

open System
open ModConductor.DeploymentPlanning
open ModConductor.Fnis

module internal FnisOutputInspection =
    let private latest = FnisRunRows.latest
    let private outputId = FnisRunRows.outputId

    let private viewMatchesOutput connection profile generation =
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
            | _ ->
                selected.Dispose()

                LibraryRows.find connection null output
                |> Option.filter (fun row ->
                    row.Entry.Kind = ModConductor.ModLibrary.ModKind.GeneratedOutput)
                |> Option.bind _.Entry.CurrentVersion

        activeVersion = selectedVersion

    let private projectInspection
        connection
        workspace
        profile
        (generator: StoredFnisGenerator)
        (fingerprint, activeFingerprint, _)
        =
        let latest = latest connection null profile

        let matchingView = viewMatchesOutput connection profile generator.GenerationId

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
          RunLog = latest |> Option.map _.RunLog |> Option.defaultValue "" }

    let inspection (database: StateDatabase) workspace profile (generator: StoredFnisGenerator) =
        database.Enqueue(fun () ->
            FnisInputInspection.read database database.Connection null workspace profile
            |> Result.mapError FnisExecutionError.Unavailable
            |> Result.map (projectInspection database.Connection workspace profile generator))
