namespace ModConductor.Engine

open System
open ModConductor
open ModConductor.Executables

module internal ExecutableWire =
    let preset (value: ExecutablePreset) =
        let wire =
            Protocol.V1.ExecutablePreset(
                Id = value.Id.ToString("N"),
                WorkspaceId = value.WorkspaceId.ToString("N"),
                Revision = uint64 value.Revision,
                Name = value.Name,
                Executable = value.Launch.Executable,
                WorkingDirectory = value.Launch.WorkingDirectory
            )

        wire.Arguments.AddRange value.Launch.Arguments

        for name, value in value.Launch.Environment do
            let setting = Protocol.V1.ExecutableEnvironmentSetting(Name = name)
            value |> Option.iter (fun text -> setting.Value <- text)
            wire.Environment.Add setting

        wire

    let parsePreset (value: Protocol.V1.ExecutablePreset) : ExecutablePreset =
        { Id = ModLibraryWire.id value.Id
          WorkspaceId = ModLibraryWire.id value.WorkspaceId
          Revision = ModLibraryWire.number value.Revision
          Name = value.Name
          Launch =
            { Executable = value.Executable
              WorkingDirectory = value.WorkingDirectory
              Arguments = List.ofSeq value.Arguments
              Environment =
                value.Environment
                |> Seq.map (fun setting ->
                    setting.Name, (if setting.HasValue then Some setting.Value else None))
                |> List.ofSeq } }

    let request (value: RunRequest) =
        Protocol.V1.ExecutableRunRequest(
            Id = value.Id.ToString("N"),
            WorkspaceId = value.WorkspaceId.ToString("N"),
            WorkspaceRevision = uint64 value.WorkspaceRevision,
            PresetId = value.PresetId.ToString("N"),
            PresetRevision = uint64 value.PresetRevision
        )

    let parseRequest (value: Protocol.V1.ExecutableRunRequest) : RunRequest =
        { Id = ModLibraryWire.id value.Id
          WorkspaceId = ModLibraryWire.id value.WorkspaceId
          WorkspaceRevision = ModLibraryWire.number value.WorkspaceRevision
          PresetId = ModLibraryWire.id value.PresetId
          PresetRevision = ModLibraryWire.number value.PresetRevision }

    let private phase =
        function
        | RunPhase.Starting -> Protocol.V1.ExecutableRunPhase.Starting
        | RunPhase.Running -> Protocol.V1.ExecutableRunPhase.Running
        | RunPhase.WaitingForChildren -> Protocol.V1.ExecutableRunPhase.WaitingForChildren
        | RunPhase.Finished -> Protocol.V1.ExecutableRunPhase.Finished
        | RunPhase.Failed -> Protocol.V1.ExecutableRunPhase.Failed
        | RunPhase.Detached -> Protocol.V1.ExecutableRunPhase.Detached
        | RunPhase.TrackingUnavailable -> Protocol.V1.ExecutableRunPhase.TrackingUnavailable

    let run (value: ExecutableRun) =
        let wire =
            Protocol.V1.ExecutableRun(
                Request = request value.Request,
                Revision = uint64 value.Revision,
                Preset = preset value.Preset,
                RequestedAt = value.RequestedAt.ToString("O"),
                Phase = phase value.Phase
            )

        value.ProfileId |> Option.iter (fun id -> wire.ProfileId <- id.ToString("N"))
        value.ProfileName |> Option.iter (fun name -> wire.ProfileName <- name)
        value.ProcessId |> Option.iter (fun pid -> wire.ProcessId <- uint32 pid)
        value.Scope |> Option.iter (fun scope -> wire.Scope <- scope)
        value.RootExitCode |> Option.iter (fun code -> wire.RootExitCode <- code)

        value.ActiveProcesses
        |> Option.iter (fun count -> wire.ObservedProcessCount <- uint32 count)

        value.Problem |> Option.iter (fun problem -> wire.Problem <- problem)
        wire

    let problem value =
        let code, detail =
            match value with
            | ExecutableError.NotFound ->
                Protocol.V1.ExecutableProblemCode.NotFound, "The executable or run was not found."
            | ExecutableError.StaleRevision ->
                Protocol.V1.ExecutableProblemCode.StaleRevision,
                "The saved configuration changed. Read it again before continuing."
            | ExecutableError.IdentityConflict ->
                Protocol.V1.ExecutableProblemCode.IdentityConflict,
                "This request identity belongs to a different executable action."
            | ExecutableError.Capacity ->
                Protocol.V1.ExecutableProblemCode.Capacity,
                "The engine cannot observe another executable now."
            | ExecutableError.Invalid detail -> Protocol.V1.ExecutableProblemCode.Invalid, detail
            | ExecutableError.Unavailable detail ->
                Protocol.V1.ExecutableProblemCode.Unavailable, detail

        Protocol.V1.ExecutableProblem(Code = code, Detail = detail)

    let presetReply =
        function
        | Ok value -> Protocol.V1.ExecutablePresetReply(Preset = preset value)
        | Error error -> Protocol.V1.ExecutablePresetReply(Problem = problem error)

    let runReply =
        function
        | Ok value -> Protocol.V1.ExecutableRunReply(Run = run value)
        | Error error -> Protocol.V1.ExecutableRunReply(Problem = problem error)
