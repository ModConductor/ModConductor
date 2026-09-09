namespace ModConductor.GameLaunching

open System
open System.IO
open System.Threading
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.FilePlanning

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

    let run (deployment: DeploymentBackend) (sources: SourceStamp) : PrepareGameRun =
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
                        pending <- progress current

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
                    return
                        { game with
                            Preparation =
                                { Phase = GamePreparationPhase.Ready
                                  Completed = receipt.Completed
                                  Total = receipt.Total }
                            Files =
                                Some
                                    { ReceiptId = receipt.Id
                                      GenerationId = receipt.Proposed
                                      Fingerprint = prepared.Fingerprint } },
                        lease
            }
