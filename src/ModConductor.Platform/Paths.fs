namespace ModConductor.Platform

open System
open System.IO
open System.Text

type LogicalPath = private LogicalPath of string list

type HostPath = private HostPath of string

type CaseRule =
    | Sensitive
    | Insensitive

type UnicodeRule =
    | Preserve
    | CanonicalComposition

type NameRule =
    | Posix
    | Windows

type TargetPolicy =
    { Case: CaseRule
      Unicode: UnicodeRule
      Names: NameRule }

type NameProblem =
    | InvalidComponent
    | InvalidUnicode
    | ReservedWindowsName
    | WindowsCharacter
    | TrailingDotOrSpace

module LogicalPath =
    let create components =
        if
            List.isEmpty components
            || components
               |> List.exists (fun (name: string) ->
                   String.IsNullOrEmpty name
                   || name = "."
                   || name = ".."
                   || name.Contains('/')
                   || name.Contains('\000'))
        then
            Error InvalidComponent
        else
            Ok(LogicalPath components)

    let components (LogicalPath components) = components
    let display (LogicalPath components) = String.Join("/", components)

module HostPath =
    let create path =
        if
            String.IsNullOrWhiteSpace path
            || path.Contains('\000')
            || not (Path.IsPathFullyQualified path)
        then
            Error "Select an absolute path."
        else
            Ok(HostPath path)

    let value (HostPath path) = path

module TargetPolicy =
    let linux =
        { Case = Sensitive
          Unicode = Preserve
          Names = Posix }

    let windows =
        { Case = Insensitive
          Unicode = Preserve
          Names = Windows }

    let private reserved (name: string) =
        let stem = name.Split('.')[0]

        [ "CON"; "PRN"; "AUX"; "NUL" ]
        |> List.exists (fun value -> String.Equals(stem, value, StringComparison.OrdinalIgnoreCase))
        || ((stem.Length = 4
             && (stem.StartsWith("COM", StringComparison.OrdinalIgnoreCase)
                 || stem.StartsWith("LPT", StringComparison.OrdinalIgnoreCase)))
            && "123456789¹²³".Contains(stem[3]))

    let problems policy path =
        LogicalPath.components path
        |> List.collect (fun name ->
            [ try
                  name.Normalize() |> ignore
              with :? ArgumentException ->
                  yield InvalidUnicode
              if policy.Names = Windows then
                  if reserved name then
                      yield ReservedWindowsName

                  if name |> Seq.exists (fun c -> c < ' ' || "<>:\"/\\|?*".Contains c) then
                      yield WindowsCharacter

                  if name.EndsWith('.') || name.EndsWith(' ') then
                      yield TrailingDotOrSpace ])
        |> List.distinct

    let internal key policy path =
        LogicalPath.components path
        |> List.map (fun name ->
            match policy.Unicode with
            | Preserve -> name
            | CanonicalComposition -> name.Normalize(NormalizationForm.FormC))
        |> fun components -> String.Join("/", components)

    let internal comparer policy =
        match policy.Case with
        | Sensitive -> StringComparer.Ordinal
        | Insensitive -> StringComparer.OrdinalIgnoreCase
