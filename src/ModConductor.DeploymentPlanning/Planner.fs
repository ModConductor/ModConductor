namespace ModConductor.DeploymentPlanning

module Planner =
    let compute input =
        let roots, contributions, issues = InputProjection.project input
        let files, directories = TargetResolution.resolve roots contributions issues

        let readOnly, writable =
            WritableResolution.project roots files directories issues input.Writable

        let view =
            { Fingerprint = InputFingerprint.compute input
              ReadOnlyFiles = readOnly
              Directories = directories
              Writable = writable }

        if issues.Count = 0 then
            PlanningResult.Ready(DeploymentPlan view)
        else
            PlanningResult.Blocked
                { Draft = view
                  Issues = issues |> Seq.distinct |> Seq.sort |> Seq.toList }

    let view (DeploymentPlan view) = view

    let checkCurrent (DeploymentPlan retained) input =
        match compute input with
        | PlanningResult.Blocked blocked ->
            Error(CurrentInputProblem.UnresolvedInputs blocked.Issues)
        | PlanningResult.Ready(DeploymentPlan current) ->
            if current.Fingerprint = retained.Fingerprint then
                Ok()
            else
                Error CurrentInputProblem.ChangedInputs
