namespace ModConductor.Operations

open System
open System.Threading
open System.Threading.Tasks

type RuntimeResult =
    { Architecture: string
      NativeAot: bool
      SqliteVersion: string }

type Phase =
    | Running
    | Completed
    | Cancelled
    | Interrupted
    | Stale

type Request =
    { Id: string
      ExpectedRevision: int64
      Count: int }

type Snapshot =
    { Request: Request
      Phase: Phase
      Progress: int
      Result: RuntimeResult option
      ResultRevision: int64 }

type Change = { Cursor: int64; Operation: Snapshot }

type Feed =
    { Cursor: int64
      Revision: int64
      ResyncRequired: bool
      Snapshot: Snapshot list option
      Changes: Change list }

type Rejection =
    | StaleRevision
    | IdentityConflict
    | Capacity
    | NotFound

type IOperationStore =
    abstract Begin: Request -> Task<Result<Snapshot * bool, Rejection>>
    abstract Advance: string * int * RuntimeResult -> Task<Snapshot>
    abstract Cancel: string -> Task<Result<Snapshot, Rejection>>
    abstract Get: string -> Task<Result<Snapshot, Rejection>>
    abstract InitialFeed: int64 option -> Task<Feed>
    abstract Changes: int64 -> Task<Feed>
    abstract WaitForChanges: int64 * CancellationToken -> Task
    abstract Interrupt: string -> Task<unit>

type CapacityException() =
    inherit Exception("The operation queue is full.")
