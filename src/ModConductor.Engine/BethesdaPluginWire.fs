namespace ModConductor.Engine

open System
open ModConductor.Platform
open ModConductor.Bethesda
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning
open ModConductor.Protocol.V1

module internal BethesdaPluginWire =
    let private kind =
        function
        | PluginKind.Plugin -> "Plugin"
        | PluginKind.Master -> "Master"
        | PluginKind.LightPlugin -> "Light plugin"
        | PluginKind.LightMaster -> "Light master"

    let source target (value: PluginSource) =
        let output = BethesdaPluginSource(Name = value.Name, Version = value.Version)

        match value.Source with
        | CandidateSource.Pinned(SourcePin.Mod(modId, version, entry)) ->
            output.ModId <- modId.ToString "N"
            output.VersionId <- version.ToString "N"
            output.Path <- LogicalPath.display entry.Path
        | CandidateSource.Pinned(SourcePin.Snapshot(_, _, file)) ->
            output.GameFile <- true
            output.Path <- LogicalPath.display file.Path
        | CandidateSource.Observed _ ->
            output.GameFile <- true
            output.Path <- LogicalPath.display target

        output

    let private masterStatus =
        function
        | MasterState.Found -> "Found"
        | MasterState.Missing -> "Missing"
        | MasterState.Ambiguous -> "Ambiguous"
        | MasterState.Unavailable -> "Cannot read header"
        | MasterState.Cyclic -> "Cyclic dependency"

    let private plugin (value: PluginEntry) =
        let output =
            BethesdaPlugin(Name = value.Name, Kind = "Unknown", Status = "No issues found")

        value.Winner
        |> Option.iter (fun winner -> output.Winner <- source value.Path winner)

        output.Alternatives.AddRange(value.Alternatives |> Seq.map (source value.Path))
        let problems = ResizeArray<string>()

        match value.Ambiguity, value.Header with
        | Some detail, _ ->
            output.Status <- "Ambiguous source"
            problems.Add detail
        | None, Error error ->
            let status, detail =
                match error with
                | HeaderError.Unsupported detail -> "Unsupported header", detail
                | HeaderError.Limit detail -> "Read limit reached", detail
                | HeaderError.Malformed detail ->
                    "Cannot read header", detail + " Obtain a complete copy of this plugin."
                | HeaderError.Unavailable detail -> "Cannot read header", detail

            output.Status <- status
            problems.Add detail
        | None, Ok header ->
            output.Kind <- kind header.Kind

            output.Header <-
                BethesdaPluginHeader(
                    Extension = header.Extension,
                    Flags = header.Flags,
                    FormVersion = uint32 header.FormVersion,
                    HeaderVersion = header.HeaderVersion,
                    DeclaredRecords = header.DeclaredRecords,
                    Localized = header.Localized,
                    Author = Option.defaultValue "" header.Author,
                    Description = Option.defaultValue "" header.Description,
                    FlagLabels =
                        ([ if header.Flags &&& 1u <> 0u then
                               "Master"
                           if header.Flags &&& 0x200u <> 0u then
                               "Light"
                           if header.Localized then
                               "Localized" ]
                         |> function
                             | [] -> "None"
                             | values -> String.concat ", " values)
                )

        for master in value.Masters do
            let row = BethesdaMaster(Name = master.Name, Status = masterStatus master.State)
            // Master source paths are recorded in their own plugin entries. This label is a reference, not an open request.
            match master.Source with
            | Some origin ->
                row.Source <-
                    source
                        (LogicalPath.create [ master.Name ] |> Result.defaultValue value.Path)
                        origin
            | None -> ()

            output.Masters.Add row

            match master.State with
            | MasterState.Found -> ()
            | MasterState.Missing -> problems.Add(master.Name + " is missing.")
            | MasterState.Ambiguous -> problems.Add(master.Name + " has ambiguous sources.")
            | MasterState.Unavailable -> problems.Add(master.Name + " has an unavailable header.")
            | MasterState.Cyclic ->
                problems.Add(value.Name + " and " + master.Name + " have a cyclic dependency.")

        if output.Status = "No issues found" && problems.Count > 0 then
            output.Status <-
                if
                    value.Masters |> List.exists (fun master -> master.State = MasterState.Missing)
                then
                    "Missing master"
                elif
                    value.Masters
                    |> List.exists (fun master -> master.State = MasterState.Ambiguous)
                then
                    "Ambiguous master"
                elif
                    value.Masters |> List.exists (fun master -> master.State = MasterState.Cyclic)
                then
                    "Cyclic masters"
                else
                    "Master unavailable"

        output.HasIssues <- problems.Count > 0
        output.Problem <- String.concat "\n" problems
        output

    let reply result =
        match result with
        | Error error ->
            let fault = FilePlanWire.fault error

            match error with
            | FilePlanError.Expired ->
                fault.Detail <- "The plugin scan expired. Scan plugins again."
            | FilePlanError.Cancelled -> fault.Detail <- "The plugin scan was cancelled."
            | _ -> ()

            BethesdaPluginsReply(Fault = fault)
        | Ok(value: PluginSnapshot) ->
            let snapshot =
                BethesdaPluginSnapshot(
                    SnapshotId = value.Id.ToString "N",
                    WorkspaceId = value.Stamp.WorkspaceId.ToString "N",
                    ProfileId = value.Stamp.ProfileId.ToString "N",
                    ObservedAtUnixMs = value.ObservedAt.ToUnixTimeMilliseconds(),
                    Stale = value.Stale
                )

            snapshot.Plugins.AddRange(value.Entries |> Seq.map plugin)
            snapshot.Problems.AddRange value.Problems

            if snapshot.CalculateSize() > 16 * 1024 * 1024 - 1024 then
                BethesdaPluginsReply(
                    Fault =
                        FilePlanWire.fault (
                            FilePlanError.LimitExceeded
                                "The plugin scan exceeds the 16 MiB reply limit."
                        )
                )
            else
                BethesdaPluginsReply(Snapshot = snapshot)
