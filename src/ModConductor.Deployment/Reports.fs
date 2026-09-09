namespace ModConductor.Deployment

open ModConductor.DeploymentRecovery

module internal DeploymentReports =
    let phase =
        function
        | ReceiptPhase.Applying -> DeploymentPhase.Applying
        | ReceiptPhase.Restoring -> DeploymentPhase.Restoring
        | ReceiptPhase.Complete -> DeploymentPhase.Complete
        | ReceiptPhase.Restored -> DeploymentPhase.Restored
        | ReceiptPhase.Blocked -> DeploymentPhase.Blocked

    let receipt (value: Receipt) =
        { Id = value.Id
          WorkspaceId = value.Context.Roots.Head.Root.Id
          Revision = value.Revision
          Phase = phase value.Phase
          Previous = value.Previous
          Proposed = value.Proposed
          Completed =
            value.Changes
            |> List.filter (fun change ->
                change.Phase = EntryPhase.Installed || change.Phase = EntryPhase.Restored)
            |> List.length
          Total = value.Changes.Length
          Detail = value.Detail }

    let error =
        function
        | RecoveryError.NotFound -> DeploymentError.NotFound
        | RecoveryError.Busy -> DeploymentError.Busy
        | RecoveryError.Stale -> DeploymentError.Stale
        | RecoveryError.InvalidPlan -> DeploymentError.Blocked "The file plan is not valid."
        | RecoveryError.Limit ->
            DeploymentError.Unavailable "The deployment exceeds its supported bounds."
        | RecoveryError.Mismatch text
        | RecoveryError.Corrupt text -> DeploymentError.Blocked text
        | RecoveryError.Unavailable text -> DeploymentError.Unavailable text
