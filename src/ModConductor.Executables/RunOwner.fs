namespace ModConductor.Executables

open System
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform

type internal RunOwner(initial: ExecutableRun, prepare: PrepareGameRun option) =
    member _.Prepare = prepare
    member val Cancellation = new CancellationTokenSource()
    member val Gate = new SemaphoreSlim(1, 1)
    member val Snapshot = initial with get, set
    member val Native: INativeRun option = None with get, set
    member val Completion: Task = Task.CompletedTask with get, set

type internal ExecutionState() =
    member val Gate = obj ()
    member val Runs = Dictionary<Guid, RunOwner>()
    member val Roots = HashSet<Task<int>>()
    member val Closing = false with get, set
