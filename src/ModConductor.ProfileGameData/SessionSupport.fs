namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Threading.Tasks
open ModConductor.Bethesda
open ModConductor.GameContexts

[<Sealed>]
type internal ProfileDataPreviewCache() =
    let gate = obj ()
    let mutable save: (ProfileSaveActionPreview * SaveActionReceipt) option = None
    let mutable configuration: ConfigurationPreview option = None

    member _.RememberSave(preview: ProfileSaveActionPreview, receipt: SaveActionReceipt) =
        lock gate (fun () -> save <- Some(preview, receipt))

    member _.ClaimSave(id, expected) =
        lock gate (fun () ->
            match save with
            | Some(preview, receipt) when
                preview.Id = id
                && preview.Expected = expected
                && preview.Action = receipt.Action
                ->
                save <- None
                Some(preview, receipt)
            | _ -> None)

    member _.RememberConfiguration(preview) =
        lock gate (fun () -> configuration <- Some preview)

    member _.ClaimConfiguration(id, expected, name: string) =
        lock gate (fun () ->
            match configuration with
            | Some preview when
                preview.Public.PreviewId = id
                && preview.Public.Expected = expected
                && preview.Public.Name.Equals(name, StringComparison.OrdinalIgnoreCase)
                ->
                configuration <- None
                Some preview
            | _ -> None)

    member _.RetainedSaveCount = lock gate (fun () -> if save.IsSome then 1 else 0)

type internal ProfileDataSessionContext =
    { Repository: IProfileDataRepository
      Plugins: PluginSession
      Archives: ArchivePolicySession
      Stopped: GameContextState -> unit
      ConfigurationCheckpoint: string -> unit
      Previews: ProfileDataPreviewCache }

module internal ProfileDataSessionContext =
    let requireIds ids =
        if ids |> List.contains Guid.Empty then
            raise (
                ProfileDataException(
                    ProfileDataError.Invalid "The request contains an empty identifier."
                )
            )

    let read context =
        ProfileDataProjection.read context.Repository

    let execute context arguments =
        ProfileDataActions.execute
            { Repository = context.Repository
              Archives = context.Archives
              Stopped = context.Stopped
              Read = read context }
            arguments

    let replay context =
        ProfileDataActions.replay context.Repository (read context)

[<Sealed>]
type internal ProfileDataSessionRuntime(enter: Guid -> IDisposable option) =
    let gate = obj ()
    let mutable active = 0
    let mutable closed = false

    let mutable drained =
        TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously)

    do drained.SetResult()

    member _.Protect(action: unit -> Task<Result<'a, ProfileDataError>>) =
        task {
            let admitted =
                lock gate (fun () ->
                    if closed || active >= 2 then
                        false
                    else
                        if active = 0 then
                            drained <-
                                TaskCompletionSource<unit>(
                                    TaskCreationOptions.RunContinuationsAsynchronously
                                )

                        active <- active + 1
                        true)

            if not admitted then
                return Error ProfileDataError.Busy
            else
                try
                    try
                        return! action ()
                    with
                    | ProfileDataException error -> return Error error
                    | :? OperationCanceledException -> return Error ProfileDataError.Cancelled
                    | :? IOException as error ->
                        return Error(ProfileDataError.Unavailable error.Message)
                    | :? UnauthorizedAccessException ->
                        return
                            Error(
                                ProfileDataError.Unavailable
                                    "The settings or saves cannot be accessed."
                            )
                finally
                    lock gate (fun () ->
                        active <- active - 1

                        if active = 0 then
                            drained.TrySetResult() |> ignore)
        }

    member this.Run(workspace, action: unit -> Task<Result<'a, ProfileDataError>>) =
        this.Protect(fun () ->
            task {
                match enter workspace with
                | None -> return Error ProfileDataError.Busy
                | Some lease ->
                    use lease = lease
                    return! action ()
            })

    member _.Drain() = lock gate (fun () -> drained.Task)

    member _.TryClose(next: unit -> bool) =
        lock gate (fun () ->
            if active <> 0 || not (next ()) then
                false
            else
                closed <- true
                true)
