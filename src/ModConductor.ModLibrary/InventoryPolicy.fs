namespace ModConductor.ModLibrary

open System
open ModConductor.Platform

module InventoryPolicy =
    let metadata value =
        let valid limit (text: string) =
            not (isNull text) && text.Length <= limit && not (text.Contains '\000')

        if
            not (valid 256 value.Name)
            || String.IsNullOrWhiteSpace value.Name
            || not (valid 4096 value.Notes)
            || not (valid 1024 value.Comment)
            || not (valid 256 value.Version)
            || not (valid 1024 value.Source)
            || not (valid 256 value.Category)
        then
            Error LibraryError.InvalidMetadata
        else
            Ok { value with Name = value.Name.Trim() }

    let actions kind status version =
        let reads =
            if Option.isSome version then
                [ ModAction.ReadVersion ]
            else
                []

        match kind with
        | ModKind.Regular ->
            ModAction.EditMetadata
            :: (if status = InventoryStatus.Ready || status = InventoryStatus.Changed then
                    ModAction.Publish :: reads
                else
                    reads)
        | ModKind.Separator -> [ ModAction.EditMetadata ]
        | ModKind.Backup -> reads
        | ModKind.Unmanaged
        | ModKind.GeneratedOutput -> []

    let entry id workspace kind metadata revision source version status =
        { Id = id
          WorkspaceId = workspace
          Kind = kind
          Metadata = metadata
          Revision = revision
          SourcePath = source
          CurrentVersion = version
          Status = status
          Actions = actions kind status version }

    // Conservative wire-size bounds in addition to row bounds. Paths retain original components.
    let private textSize (text: string) =
        System.Text.Encoding.UTF8.GetByteCount text + 8

    let private pathSize path =
        LogicalPath.components path |> List.sumBy textSize

    let inventoryWindow (entries: ModEntry list) =
        let mutable remaining = 512 * 1024

        entries
        |> List.truncate 32
        |> List.takeWhile (fun entry ->
            let metadata = entry.Metadata

            let size =
                512
                + List.sumBy
                    textSize
                    [ metadata.Name
                      metadata.Notes
                      metadata.Comment
                      metadata.Version
                      metadata.Source
                      metadata.Category ]
                + (entry.SourcePath |> Option.map pathSize |> Option.defaultValue 0)

            remaining <- remaining - size
            remaining >= 0)

    let manifestWindow (entries: ManifestEntry list) =
        let mutable remaining = 512 * 1024

        entries
        |> List.truncate 64
        |> List.takeWhile (fun entry ->
            remaining <- remaining - 256 - pathSize entry.Path
            remaining >= 0)
