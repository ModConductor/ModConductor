namespace ModConductor.DeploymentGenerations

open System
open ModConductor.Platform
open ModConductor.FilePlanning
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

type internal SnapshotSource =
    { Snapshot: ReadOnlySnapshot
      Directory: Location
      Files: Map<LogicalPath, FileIdentity> }

type internal GenerationSources =
    { Input: VisibilityInput
      Stamp: SourceStamp
      Files: Map<SourcePin, FileBacking> }

type internal WorkingLocation =
    { Declaration: Guid
      Root: Location
      Path: LogicalPath }

type internal ProcessIdentity =
    { Id: int
      StartedAt: DateTime
      Executable: string }

type internal BuildRequest =
    { Id: Guid
      Storage: Location
      SecondaryStorage: Location
      Roots: RootBinding list
      Working: WorkingLocation list
      Previous: Generation option
      Processes: ProcessIdentity list }

type internal BuildMeasurements =
    { GenerationLinks: int
      CopiedBytes: int64
      WritableSeedBytes: int64
      BaseCopiedBytes: int64
      AvailableBytes: int64
      RequiredBytes: int64 }

type internal PreparedGeneration =
    { Generation: Generation
      Sources: SourceStamp
      Measurements: BuildMeasurements }
