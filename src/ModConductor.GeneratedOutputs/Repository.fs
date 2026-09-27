namespace ModConductor.GeneratedOutputs

open System
open System.Threading
open System.Threading.Tasks

type internal OutputActionRecord =
    { Id: Guid
      SnapshotId: Guid
      Scope: OutputScope
      Action: OutputAction
      Files: OutputObservation list
      Result: OutputActionResult }

type internal IOutputRepository =
    abstract Read:
        workspace: Guid * profile: Guid * context: Guid option ->
            Task<Result<OutputScope * OutputBacking list, OutputError>>

    abstract Add:
        Guid * OutputScope * string * OutputPurpose -> Task<Result<OutputLocation, OutputError>>

    abstract Workspace: Guid -> Task<Result<Guid, OutputError>>
    abstract StopUsing: Guid * int64 -> Task<Result<OutputLocation, OutputError>>
    abstract Current: OutputScope -> Task<Result<bool, OutputError>>

    abstract Previous:
        OutputScope ->
            Task<Result<Map<Guid * ModConductor.Platform.LogicalPath, string * bool>, OutputError>>

    abstract Observed: OutputScope * OutputObservation list -> Task<bool>
    abstract ActiveDeployment: OutputScope -> Task<Result<Guid option, OutputError>>
    abstract CheckAction: OutputActionRecord -> Task<Result<unit, OutputError>>
    abstract Preview: OutputActionRecord -> Task<Result<OutputPromotionPreview, OutputError>>
    abstract Claim: OutputActionRecord -> Task<Result<OutputActionRecord, OutputError>>
    abstract FindAction: Guid -> Task<Result<OutputActionRecord option, OutputError>>
    abstract Resume: Guid -> Task<Result<OutputActionRecord, OutputError>>
    abstract Publish: OutputActionRecord * CancellationToken -> Task<Result<Guid, OutputError>>

    abstract SaveEntry:
        Guid * OutputSelection * OutputDisposition -> Task<Result<OutputActionResult, OutputError>>

    abstract Release: Guid -> Task<unit>
