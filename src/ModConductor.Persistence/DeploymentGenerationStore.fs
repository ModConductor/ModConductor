namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.Platform
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations

type internal DeploymentGenerationStore
    (database: StateDatabase, access: LibraryAccess, recovery: Recovery) =
    let gate = obj ()
    let mutable active = 0
    let mutable closed = false

    let prepare action =
        task {
            let accepted =
                lock gate (fun () ->
                    if closed || active >= 2 then
                        false
                    else
                        active <- active + 1
                        true)

            if not accepted then
                return Error RecoveryError.Busy
            else
                try
                    return! action ()
                finally
                    lock gate (fun () -> active <- active - 1)
        }

    let protect action =
        task {
            try
                return! action ()
            with
            | RecoveryException error -> return Error error
            | :? IOException as error -> return Error(RecoveryError.Unavailable error.Message)
            | :? UnauthorizedAccessException as error ->
                return Error(RecoveryError.Unavailable error.Message)
            | :? OperationCanceledException ->
                return Error(RecoveryError.Unavailable "Generation preparation was cancelled.")
            | :? PlatformNotSupportedException ->
                return
                    Error(
                        RecoveryError.Unavailable "Required symbolic-link storage is unavailable."
                    )
        }

    member _.Build
        (
            request,
            profile,
            snapshots,
            writable,
            cancellation: CancellationToken,
            available,
            ?gameFolderOnly: bool
        ) =
        prepare (fun () ->
            protect (fun () ->
                task {
                    let! admitted =
                        access.Run(fun () ->
                            task {
                                let! sources =
                                    GenerationSources.read
                                        database
                                        access
                                        profile
                                        (request.Roots |> List.map _.Root)
                                        snapshots
                                        writable

                                let sources =
                                    if defaultArg gameFolderOnly false then
                                        { sources with
                                            Input =
                                                { sources.Input with
                                                    Planning =
                                                        { sources.Input.Planning with
                                                            Profile =
                                                                { sources.Input.Planning.Profile with
                                                                    Mods = [] } } } }
                                    else
                                        sources

                                let! built =
                                    Task.Run(fun () ->
                                        GenerationBuilder.build
                                            available
                                            request
                                            sources
                                            cancellation)

                                return Ok built
                            })

                    return
                        admitted
                        |> Result.mapError (function
                            | LibraryError.Busy -> RecoveryError.Busy
                            | _ ->
                                RecoveryError.Unavailable
                                    "Generation source storage is unavailable.")
                }))

    member this.Build(request, profile, snapshots, writable, cancellation: CancellationToken) =
        this.Build(
            request,
            profile,
            snapshots,
            writable,
            cancellation,
            fun location -> GenerationStorage.available location.Path location.Identity
        )

    member _.Start(request: SwitchRequest, processes, ?cancellation: CancellationToken) =
        protect (fun () ->
            task {
                GenerationFiles.checkProcesses processes

                match request.ExpectedSources with
                | Some _ -> return! recovery.Start(request, ?cancellation = cancellation)
                | None ->
                    let! retained = recovery.Generation(request.ContextId, request.Generation.Id)

                    if retained = Some request.Generation then
                        return! recovery.Start(request, ?cancellation = cancellation)
                    else
                        return Error RecoveryError.Stale
            })

    member _.Run(id, revision, restore, cancellation, afterEffect, processes) =
        protect (fun () ->
            task {
                GenerationFiles.checkProcesses processes
                return! recovery.Run(id, revision, restore, cancellation, afterEffect)
            })

    member _.TryClose(next: unit -> bool) =
        lock gate (fun () ->
            if active <> 0 || not (next ()) then
                false
            else
                closed <- true
                true)
