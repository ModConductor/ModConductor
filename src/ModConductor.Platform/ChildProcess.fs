namespace ModConductor.Platform

open System
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks

type NativeLaunch =
    { Executable: string
      Arguments: string list
      WorkingDirectory: string
      Environment: (string * string option) list }

type NativeRunObservation =
    { RootExitCode: int option
      ActiveProcesses: int option
      ScopeEnded: bool }

type INativeRun =
    inherit IDisposable
    abstract ProcessId: int
    abstract Scope: string
    abstract RootExit: Task<int>
    abstract Observe: unit -> NativeRunObservation
    abstract TerminateScope: unit -> unit

type NativeToolLimits =
    { InputBytes: int
      OutputBytes: int
      ErrorBytes: int
      Timeout: TimeSpan }

[<RequireQualifiedAccess>]
type NativeToolError =
    | Cancelled
    | TimedOut
    | OutputLimit
    | ErrorLimit
    | LaunchFailed of string

type NativeToolResult =
    { ExitCode: int
      Output: byte array
      Error: byte array
      Scope: string }

type internal NativeStreamFiles =
    { Input: string
      Output: string
      Error: string }

module internal ChildEnvironment =
    let build edits =
        let comparer =
            if OperatingSystem.IsWindows() then
                StringComparer.OrdinalIgnoreCase
            else
                StringComparer.Ordinal

        let values = Dictionary<string, string>(comparer)

        for entry in
            Environment.GetEnvironmentVariables()
            |> Seq.cast<System.Collections.DictionaryEntry> do
            values[string entry.Key] <- string entry.Value

        for name, value in edits do
            match value with
            | Some text -> values[name] <- text
            | None -> values.Remove name |> ignore

        values
        |> Seq.map (fun pair -> pair.Key + "=" + pair.Value)
        |> Seq.sortWith (fun left right -> comparer.Compare(left, right))
        |> Seq.toArray
