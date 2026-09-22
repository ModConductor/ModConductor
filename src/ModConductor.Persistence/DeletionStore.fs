namespace ModConductor.Persistence

open System.Threading.Tasks
open ModConductor.ModMaintenance
open ModConductor.ArchiveInstallation

type DeletionStore internal (database: StateDatabase, access: LibraryAccess) =
    let refuse message = raise (InstallationException message)

    let run action =
        task {
            let! result = access.Run action
            return result |> Result.defaultWith (fun _ -> refuse "The mod library is unavailable.")
        }

    member _.Prepare(workspace, modId, revision) =
        run (fun () ->
            task {
                let! state = DeletionInspection.read database access workspace modId revision
                return Ok state.View
            })

    member internal _.DeleteAtCheckpoint(workspace, modId, revision, checkpoint) =
        run (fun () ->
            task {
                let! state = DeletionInspection.read database access workspace modId revision
                state.View.Blocked |> Option.iter refuse

                do!
                    Task.Run(fun () ->
                        state.Effects
                        |> List.sortBy (fun effect ->
                            if effect.Kind = DeletionFileKind.GenerationLink then
                                0
                            else
                                1)
                        |> List.iter (fun effect ->
                            checkpoint "before-deletion-effect"
                            DeletionFiles.remove effect
                            checkpoint "after-deletion-effect"))

                checkpoint "before-deletion-completion"

                do!
                    database.EnqueueInternal(fun () ->
                        DeletionCompletion.finish database.Connection state)

                checkpoint "after-deletion-completion"
                return Ok()
            })

    member this.Delete(workspace, modId, revision) =
        this.DeleteAtCheckpoint(workspace, modId, revision, ignore)
