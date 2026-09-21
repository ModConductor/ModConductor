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
    abstract Read: workspace: Guid * profile: Guid * context: Guid option ->
        Task<OutputScope * OutputBacking list>
    abstract Add: Guid * OutputScope * string * OutputPurpose -> Task<OutputLocation>
    abstract Workspace: Guid -> Task<Guid>
    abstract StopUsing: Guid * int64 -> Task<OutputLocation>
    abstract Current: OutputScope -> Task<bool>

    abstract Previous:
        OutputScope -> Task<Map<Guid * ModConductor.Platform.LogicalPath, string * bool>>

    abstract Observed: OutputScope * OutputObservation list -> Task<bool>
    abstract ActiveDeployment: OutputScope -> Task<Guid option>
    abstract CheckAction: OutputActionRecord -> Task<unit>
    abstract Preview: OutputActionRecord -> Task<OutputPromotionPreview>
    abstract Claim: OutputActionRecord -> Task<OutputActionRecord>
    abstract FindAction: Guid -> Task<OutputActionRecord option>
    abstract Resume: Guid -> Task<OutputActionRecord>
    abstract Publish: OutputActionRecord * CancellationToken -> Task<Guid>
    abstract SaveEntry: Guid * OutputSelection * OutputDisposition -> Task<OutputActionResult>
    abstract Release: Guid -> Task<unit>
