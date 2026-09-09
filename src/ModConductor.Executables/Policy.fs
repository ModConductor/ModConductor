namespace ModConductor.Executables

open System
open System.Text
open ModConductor.Platform

module ExecutablePolicy =
    // Fits the existing 256 KiB feature request envelope, including its field framing.
    let maximumBytes = 240 * 1024

    let validate (preset: ExecutablePreset) =
        let fields =
            preset.Name
            :: preset.Launch.Executable
            :: preset.Launch.WorkingDirectory
            :: preset.Launch.Arguments
            @ (preset.Launch.Environment
               |> List.collect (fun (name, value) -> [ name; Option.defaultValue "" value ]))

        let comparer =
            if OperatingSystem.IsWindows() then
                StringComparer.OrdinalIgnoreCase
            else
                StringComparer.Ordinal

        let names = Collections.Generic.HashSet<string>(comparer)

        if
            preset.Id = Guid.Empty
            || preset.WorkspaceId = Guid.Empty
            || preset.Revision < 0L
        then
            Error(ExecutableError.Invalid "The executable identity is invalid.")
        elif String.IsNullOrWhiteSpace preset.Name || preset.Name.Length > 256 then
            Error(ExecutableError.Invalid "Enter an executable name of at most 256 characters.")
        elif fields |> List.exists (fun value -> isNull value || value.Contains('\000')) then
            Error(ExecutableError.Invalid "Executable settings cannot contain a null character.")
        elif
            (fields
             |> List.sumBy (fun value -> int64 (Encoding.UTF8.GetByteCount value) + 8L))
            + 1024L > int64 maximumBytes
        then
            Error(ExecutableError.Invalid "The executable settings exceed the request size limit.")
        elif
            preset.Launch.Environment
            |> List.exists (fun (name, _) ->
                String.IsNullOrEmpty name || name.Contains('=') || not (names.Add name))
        then
            Error(
                ExecutableError.Invalid
                    "Environment names must be unique, nonempty, and contain no equals sign."
            )
        else
            match
                HostPath.create preset.Launch.Executable,
                HostPath.create preset.Launch.WorkingDirectory
            with
            | Ok _, Ok _ -> Ok()
            | _ ->
                Error(
                    ExecutableError.Invalid "Select an absolute executable and working directory."
                )

    let terminal =
        function
        | RunPhase.Starting
        | RunPhase.Running
        | RunPhase.WaitingForChildren -> false
        | RunPhase.Finished
        | RunPhase.Failed
        | RunPhase.Detached
        | RunPhase.TrackingUnavailable -> true
