namespace ModConductor.GameLaunching

open System
open System.IO
open System.Threading
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.FilePlanning
open ModConductor.ProfileGameData

module internal Preparation =
    let error =
        function
        | DeploymentError.NotFound -> "The deployment context is unavailable."
        | DeploymentError.Busy -> "Wait for the current deployment operation."
        | DeploymentError.Stale ->
            "The selected profile or installation changed. Read the launch state again."
        | DeploymentError.Cancelled -> "Launch cancelled before the game started."
        | DeploymentError.Blocked detail
        | DeploymentError.Unavailable detail -> detail

    let private applyProfile
        (profiles: ProfileGameDataSession)
        (game: GameRun)
        (lease: IDisposable)
        (token: CancellationToken)
        (progress: GameRun -> System.Threading.Tasks.Task<unit>)
        =
        task {
            let mutable current = game

            try
                do! progress current

                let report (value: ProfileDataApplication) =
                    task {
                        current <-
                            { current with
                                ProfileData =
                                    Some
                                        { ReceiptId = value.ReceiptId
                                          Revision = value.Revision
                                          CompletedFiles = value.CompletedFiles
                                          Complete = value.Complete }
                                Preparation =
                                    { current.Preparation with
                                        Completed = value.CompletedFiles } }

                        do! progress current
                    }

                let! result =
                    profiles.ApplyForLaunch(
                        game.Request.Id,
                        game.Request.WorkspaceId,
                        game.Request.ProfileId,
                        game.ProfileDataRevision,
                        token,
                        report
                    )

                match result with
                | Error problem ->
                    let detail =
                        match problem with
                        | ProfileDataError.Busy -> "Wait for the current settings operation."
                        | ProfileDataError.Stale ->
                            "The profile settings changed. Read the launch state again."
                        | ProfileDataError.Cancelled -> "Launch cancelled before the game started."
                        | ProfileDataError.NotFound -> "The profile settings are unavailable."
                        | ProfileDataError.Invalid detail
                        | ProfileDataError.Unavailable detail
                        | ProfileDataError.Conflict detail -> detail

                    raise (IOException detail)
                | Ok(Some result) when not result.Complete ->
                    raise (
                        IOException(
                            result.Problem
                            |> Option.defaultValue "Profile settings were not fully applied."
                        )
                    )
                | Ok _ -> ()

                return
                    { current with
                        Preparation =
                            { current.Preparation with
                                Phase = GamePreparationPhase.Ready } },
                    lease
            with error ->
                lease.Dispose()
                return raise error
        }

    let run
        (deployment: DeploymentBackend)
        (profiles: ProfileGameDataSession)
        (sources: SourceStamp)
        : PrepareGameRun =
        fun game token progress ->
            task {
                let mutable last = game.Preparation
                let mutable pending = System.Threading.Tasks.Task.CompletedTask

                let notify (value: DeploymentProgress) =
                    let current =
                        { Phase =
                            match value.Phase with
                            | DeploymentPhase.Preparing -> GamePreparationPhase.Preparing
                            | DeploymentPhase.Applying
                            | DeploymentPhase.Restoring
                            | DeploymentPhase.Complete
                            | DeploymentPhase.Restored
                            | DeploymentPhase.Blocked -> GamePreparationPhase.Applying
                          Completed = value.Completed
                          Total = value.Total }

                    if current <> last && pending.IsCompletedSuccessfully then
                        last <- current
                        pending <- progress { game with Preparation = current }

                let! result = deployment.PrepareForLaunch(game.Request.Id, sources, notify, token)

                try
                    do! pending
                with error ->
                    match result with
                    | Ok(_, _, lease) -> lease.Dispose()
                    | Error _ -> ()

                    raise error

                match result with
                | Error problem -> return raise (IOException(error problem))
                | Ok(prepared, receipt, lease) ->
                    let current =
                        { game with
                            Preparation =
                                { Phase = GamePreparationPhase.ProfileData
                                  Completed = 0
                                  Total = 0 }
                            Files =
                                Some
                                    { ReceiptId = receipt.Id
                                      GenerationId = receipt.Proposed
                                      Fingerprint = prepared.Fingerprint } }

                    return! applyProfile profiles current lease token progress
            }
