namespace ModConductor.Engine

open System
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Protocol.V1
open ModConductor.Skse

type SkseView =
    { Phase: SksePhase
      GameVersion: string
      ComponentVersion: string
      Status: string
      Detail: string
      FileId: int64 option }

module internal SkseStatus =
    let phaseName (value: SksePhase) =
        match value with
        | SksePhase.Available -> "available"
        | SksePhase.WaitingForNexus -> "waiting"
        | SksePhase.Downloading -> "downloading"
        | SksePhase.Installing -> "installing"
        | SksePhase.Ready -> "current"
        | SksePhase.Failed -> "failed"
        | SksePhase.UpdateAvailable -> "update"
        | SksePhase.Incompatible -> "incompatible"
        | SksePhase.SourceUnavailable -> "source-unavailable"
        | _ -> "unavailable"

    let phase (value: string) =
        match value with
        | "available" -> SksePhase.Available
        | "waiting" -> SksePhase.WaitingForNexus
        | "downloading" -> SksePhase.Downloading
        | "installing" -> SksePhase.Installing
        | "current" -> SksePhase.Ready
        | "failed" -> SksePhase.Failed
        | "update" -> SksePhase.UpdateAvailable
        | "incompatible" -> SksePhase.Incompatible
        | "source-unavailable" -> SksePhase.SourceUnavailable
        | _ -> SksePhase.Unavailable

    let fromStored (value: StoredSkseStatus) : SkseView =
        { Phase = phase value.Phase
          GameVersion = value.GameVersion
          ComponentVersion = value.ComponentVersion
          Status = value.Status
          Detail = value.Detail
          FileId = value.NexusFileId }

    let storedStatus (workspace, profile) (value: SkseView) =
        { WorkspaceId = workspace
          ProfileId = profile
          Phase = phaseName value.Phase
          GameVersion = value.GameVersion
          ComponentVersion = value.ComponentVersion
          Status = value.Status
          Detail = value.Detail
          NexusFileId = value.FileId
          CheckedAt = DateTimeOffset.UtcNow }

    let facts (context: ModConductor.GameContexts.GameContextState) =
        let executable = context.Binding.Value.Evidence.Executable.Value
        executable.FileVersion, executable.Sha256

    let newerVersion (offered: string) (installed: string) =
        match Version.TryParse offered, Version.TryParse installed with
        | (true, latest), (true, current) -> latest > current
        | _ -> false

    let installedState
        (context: ModConductor.GameContexts.GameContextState)
        (loader: StoredSkseLoader)
        (saved: StoredSkseStatus option)
        =
        let gameVersion, gameSha256 = facts context

        if loader.Loader.GameSha256 <> gameSha256 then
            { Phase = SksePhase.Incompatible
              GameVersion = gameVersion
              ComponentVersion = loader.Loader.ComponentVersion
              Status = "Skyrim changed"
              Detail = "The installed SKSE loader is for a different Skyrim build."
              FileId = Some loader.NexusFileId }
        else
            match saved with
            | Some status when
                status.Phase = "update"
                && status.GameVersion = gameVersion
                && newerVersion status.ComponentVersion loader.Loader.ComponentVersion
                ->
                fromStored status
            | _ ->
                { Phase = SksePhase.Ready
                  GameVersion = gameVersion
                  ComponentVersion = loader.Loader.ComponentVersion
                  Status = "SKSE is installed"
                  Detail = ""
                  FileId = Some loader.NexusFileId }

type internal SkseStatusStore(store: OperationStore) =
    let changed = Event<Guid * Guid>()

    member _.Changed = changed.Publish
    member _.Signal key = changed.Trigger key

    member _.Persist key (value: SkseView) =
        task {
            do! store.SkseLoaders.SaveStatus(SkseStatus.storedStatus key value)
            changed.Trigger key
            return value
        }

    member this.Unavailable key problem =
        this.Persist
            key
            { Phase = SksePhase.Unavailable
              GameVersion = ""
              ComponentVersion = ""
              Status = SkseProblem.message problem
              Detail = ""
              FileId = None }

    member this.Failed key game componentVersion file status detail =
        this.Persist
            key
            { Phase = SksePhase.Failed
              GameVersion = game
              ComponentVersion = componentVersion
              Status = status
              Detail = detail
              FileId = file }
