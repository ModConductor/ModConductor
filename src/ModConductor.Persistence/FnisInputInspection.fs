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

    let private snapshotFile
        (target: LogicalPath)
        (file: SnapshotFile)
        : Result<FnisInputFile option, string> =
        let length = SnapshotFile.length file

        match SnapshotFile.sha256 file with
        | None -> Error "FNIS inputs require acquired content."
        | Some digest ->
            Ok(
                Some
                    { Path = target
                      Length = length
                      Sha256 = digest }
            )

    let private relevantFile
        workspace
        (target: TargetFile)
        (resolved: ResolvedFile option)
        : Result<FnisInputFile option, string> =
        match resolved with
        | Some resolved when target.Root = workspace && FnisFreshness.relevant target.Path ->
            match resolved.Winner.Source with
            | SourcePin.Mod(_, _, entry) ->
                Ok(
                    Some
                        { Path = target.Path
                          Length = entry.Payload.Length
                          Sha256 = entry.Payload.Sha256 }
                )
            | SourcePin.Snapshot(_, _, file) -> snapshotFile target.Path file
        | _ -> Ok None

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

        match Visibility.view visibility with
        | Error _ -> Error "The effective FNIS inputs are unresolved."
        | Ok _ ->
            Visibility.files visibility
            |> Map.toList
            |> List.fold
                (fun state (target, resolved) ->
                    state
                    |> Result.bind (fun files ->
                        relevantFile workspace target resolved
                        |> Result.map (fun file ->
                            file |> Option.fold (fun files item -> item :: files) files)))
                (Ok [])
            |> Result.map List.rev

    let read (database: StateDatabase) connection transaction workspace profile =
        match FilePlanRows.read connection transaction database.OwnerId profile with
        | Error _ -> Error "The FNIS inputs are unavailable."
        | Ok sources when sources.Stamp.WorkspaceId <> workspace ->
            Error "The selected profile belongs to another workspace."
        | Ok sources ->
            let activeOutput = selectedOutput connection transaction workspace profile
            let profile = withoutOutput sources activeOutput

            effectiveFiles workspace sources profile
            |> Result.map (fun files ->
                FnisFreshness.compute Skyrim.definition.TargetPolicy files,
                activeOutput |> Option.map snd,
                sources.Stamp.SelectionRevision)

    let input (database: StateDatabase) connection transaction workspace profile =
        read database connection transaction workspace profile
        |> Result.defaultWith (fun detail -> raise (InvalidDataException detail))
