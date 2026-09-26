namespace ModConductor.Engine

open System
open ModConductor.Fnis
open ModConductor.Persistence
open ModConductor.Protocol.V1

type FnisView =
    { Phase: FnisPhase
      Version: string
      Status: string
      Detail: string
      FileId: int64 option
      ArtifactId: Guid option }

module internal FnisStatus =
    let phaseName =
        function
        | FnisPhase.Available -> "available"
        | FnisPhase.WaitingForNexus -> "waiting"
        | FnisPhase.Downloading -> "downloading"
        | FnisPhase.Installing -> "installing"
        | FnisPhase.Ready -> "ready"
        | FnisPhase.Failed -> "failed"
        | FnisPhase.UpdateAvailable -> "update"
        | FnisPhase.RecoveryRequired -> "recovery"
        | FnisPhase.SourceUnavailable -> "source-unavailable"
        | _ -> "unavailable"

    let phase =
        function
        | "available" -> FnisPhase.Available
        | "waiting" -> FnisPhase.WaitingForNexus
        | "downloading" -> FnisPhase.Downloading
        | "installing" -> FnisPhase.Installing
        | "ready" -> FnisPhase.Ready
        | "failed" -> FnisPhase.Failed
        | "update" -> FnisPhase.UpdateAvailable
        | "recovery" -> FnisPhase.RecoveryRequired
        | "source-unavailable" -> FnisPhase.SourceUnavailable
        | _ -> FnisPhase.Unavailable

    let fromStored (value: StoredFnisStatus) =
        { Phase = phase value.Phase
          Version = value.ComponentVersion
          Status = value.Status
          Detail = value.Detail
          FileId = value.NexusFileId
          ArtifactId = value.ArtifactId }

type internal FnisStatusStore(store: OperationStore) =
    let changed = Event<Guid * Guid>()

    member _.Changed = changed.Publish
    member _.Signal key = changed.Trigger key

    member _.Persist workspace profile (value: FnisView) =
        task {
            do!
                store.FnisSetups.SaveStatus
                    { WorkspaceId = workspace
                      ProfileId = profile
                      Phase = FnisStatus.phaseName value.Phase
                      ComponentVersion = value.Version
                      Status = value.Status
                      Detail = value.Detail
                      NexusFileId = value.FileId
                      ArtifactId = value.ArtifactId
                      CheckedAt = DateTimeOffset.UtcNow }

            changed.Trigger(workspace, profile)
            return value
        }

    member this.Unavailable workspace profile problem =
        this.Persist
            workspace
            profile
            { Phase = FnisPhase.Unavailable
              Version = ""
              Status = "FNIS setup is unavailable"
              Detail = FnisProblem.message problem
              FileId = None
              ArtifactId = None }

    member this.Failed(workspace, profile, version, file, artifact, title, detail) =
        this.Persist
            workspace
            profile
            { Phase = FnisPhase.Failed
              Version = version
              Status = title
              Detail = detail
              FileId = file
              ArtifactId = artifact }
