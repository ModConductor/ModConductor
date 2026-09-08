namespace ModConductor.GeneratedOutputs

open System
open System.Text
open ModConductor.Platform

module internal OutputLimits =
    let locations = 64
    let entries = 1000000
    let depth = 128
    let content = 64L * 1024L * 1024L * 1024L
    let snapshot = 128L * 1024L * 1024L
    let cache = 256L * 1024L * 1024L
    let selected = 512
    let pageRows = 32
    let pageBytes = 240 * 1024

module internal OutputPolicy =
    let text limit (value: string) =
        not (isNull value) && value.Length <= limit && not (value.Contains '\000')

    let name value =
        if text 256 value && not (String.IsNullOrWhiteSpace value) then
            Ok(value.Trim())
        else
            Error(OutputError.Invalid "Enter a name of at most 256 characters.")

    let path policy value =
        if (LogicalPath.components value).Length > OutputLimits.depth then
            Error OutputError.LimitExceeded
        elif TargetPolicy.problems policy value |> List.isEmpty then
            Ok value
        else
            Error(OutputError.Invalid "The path is not valid for this game.")

    let fileSize (file: OutputFile) =
        256
        + (LogicalPath.components file.Path
           |> List.sumBy (fun value -> Encoding.UTF8.GetByteCount value + 8))

    let selection (files: OutputSelection list) =
        if
            files.IsEmpty
            || files.Length > OutputLimits.selected
            || (files
                |> List.sumBy (fun value ->
                    64
                    + (LogicalPath.components value.Path
                       |> List.sumBy (fun part -> Encoding.UTF8.GetByteCount part + 8)))) > OutputLimits.pageBytes
        then
            Error OutputError.LimitExceeded
        elif files |> List.distinct |> List.length <> files.Length then
            Error(OutputError.Invalid "Select each file once.")
        else
            Ok files

    let action (locations: OutputLocation list) selected action =
        let purposes =
            selected
            |> List.choose (fun (file: OutputSelection) ->
                locations |> List.tryFind (fun location -> location.Id = file.LocationId))
            |> List.map _.Purpose

        if purposes.Length <> selected.Length then
            Error OutputError.NotFound
        else
            match action with
            | OutputAction.MoveToMod _ when purposes |> List.exists ((<>) OutputPurpose.ToolFolder) ->
                Error(OutputError.Invalid "Use Save copy for writable game files.")
            | OutputAction.SaveCopyToMod _ when purposes |> List.contains OutputPurpose.ToolFolder ->
                Error(OutputError.Invalid "Use Move to mod for tool outputs.")
            | OutputAction.Keep
            | OutputAction.Discard
            | OutputAction.MoveToMod _
            | OutputAction.SaveCopyToMod _ -> Ok()

    let scopeBytes (scope: OutputScope) =
        512
        + Encoding.UTF8.GetByteCount scope.Installation
        + (scope.Contexts
           |> List.sumBy (fun value -> 96 + Encoding.UTF8.GetByteCount value.Installation))
        + (scope.Locations
           |> List.sumBy (fun value ->
               160
               + Encoding.UTF8.GetByteCount value.Name
               + Encoding.UTF8.GetByteCount value.PhysicalPath
               + (match value.Purpose with
                  | OutputPurpose.ToolFolder -> 0
                  | OutputPurpose.WritableFile path ->
                      LogicalPath.components path
                      |> List.sumBy (fun value -> Encoding.UTF8.GetByteCount value + 8))))
