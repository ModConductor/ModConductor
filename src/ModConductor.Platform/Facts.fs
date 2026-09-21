namespace ModConductor.Platform

open System

type DeviceIdentity =
    | LinuxDevice of major: uint32 * minor: uint32
    | WindowsVolume of serial: uint64

type FileIdentity =
    { Device: DeviceIdentity
      Low: uint64
      High: uint64 }

type HeldFileMetadata =
    { Identity: FileIdentity
      Length: int64
      Modified: DateTime }

type EntryKind =
    | RegularFile
    | Directory
    | Link
    | Other

type Observation<'T> =
    | Known of 'T
    | Unknown of string

type NativeFailure = { Operation: string; Code: int }

type IdentityFacts =
    { File: Observation<FileIdentity>
      Mount: Observation<uint64>
      Kind: EntryKind }

type PathProblem =
    | OutsideRoot
    | LinkCycle
    | MissingEntry
    | UnsupportedEntry
    | FileDirectoryConflict
    | TargetCollision
    | InvalidTargetName of NameProblem list
    | LimitExceeded
    | NativeError of NativeFailure
    | AccessFailure of string

type PathDiagnostic = { Path: string; Problem: PathProblem }

type SelectedRoot =
    internal
        { Selected: HostPath
          Resolved: HostPath
          Facts: IdentityFacts }

type PathEntry =
    { Logical: LogicalPath
      Host: HostPath
      Resolved: HostPath
      Kind: EntryKind
      TargetKind: EntryKind
      Facts: IdentityFacts }

type InspectionLimits =
    { Candidates: int
      Depth: int
      Diagnostics: int }

type Preflight =
    { Root: SelectedRoot
      Entries: PathEntry list
      Diagnostics: PathDiagnostic list }

type ProbeOutcome =
    | Observed
    | Refused of string
    | NotTested of string

type FileSystemCapabilities =
    { Identity: IdentityFacts
      Write: ProbeOutcome
      DistinctCaseNames: Observation<bool>
      CaseOnlyRename: ProbeOutcome
      HardLink: ProbeOutcome
      SymbolicLink: ProbeOutcome
      LongPath: ProbeOutcome
      TestedPathLength: int option
      Reflink: ProbeOutcome
      MetadataPreservation: ProbeOutcome }

type DeviceRelation =
    | SameDevice
    | DifferentDevices
    | UnknownDevices

type PairCapabilities =
    { Devices: DeviceRelation
      HardLink: ProbeOutcome }
