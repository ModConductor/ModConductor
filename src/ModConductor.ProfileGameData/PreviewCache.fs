namespace ModConductor.ProfileGameData

open System

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
