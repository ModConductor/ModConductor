namespace ModConductor.Engine

open ModConductor.Enb
open ModConductor.Persistence
open ModConductor.Protocol.V1

type EnbView =
    { Phase: EnbPhase
      Status: string
      Detail: string
      RuntimeVersion: string
      PresetVersion: string }

module internal EnbPresentation =
    let phaseName =
        function
        | EnbPhase.Blocked -> "blocked"
        | EnbPhase.Available -> "available"
        | EnbPhase.WaitingForArchive -> "waiting"
        | EnbPhase.Validating -> "validating"
        | EnbPhase.Acquiring -> "acquiring"
        | EnbPhase.Installing -> "installing"
        | EnbPhase.Ready -> "ready"
        | EnbPhase.Failed -> "failed"
        | EnbPhase.Conflict -> "conflict"
        | _ -> "unavailable"

    let phase =
        function
        | "blocked" -> EnbPhase.Blocked
        | "available" -> EnbPhase.Available
        | "waiting" -> EnbPhase.WaitingForArchive
        | "validating" -> EnbPhase.Validating
        | "acquiring" -> EnbPhase.Acquiring
        | "installing" -> EnbPhase.Installing
        | "ready" -> EnbPhase.Ready
        | "failed" -> EnbPhase.Failed
        | "conflict" -> EnbPhase.Conflict
        | _ -> EnbPhase.Unavailable

    let view (row: EnbCompatibilityRow) state status detail =
        { Phase = state
          Status = status
          Detail = detail
          RuntimeVersion = row.Runtime.Version
          PresetVersion = row.Preset.Version }

    let defaultView row =
        view
            row
            EnbPhase.Available
            "Lean ENB is available"
            "Open the ENBSeries author page, download version 0.505, then choose the archive."

    let adoptionView row =
        view
            row
            EnbPhase.Blocked
            "Lean ENB setup is not approved"
            (EnbProblem.message EnbProblem.AdoptionBlocked)

    let fromStored (stored: StoredEnbStatus) =
        { Phase = phase stored.Phase
          Status = stored.Status
          Detail = stored.Detail
          RuntimeVersion = stored.RuntimeVersion
          PresetVersion = stored.PresetVersion }
