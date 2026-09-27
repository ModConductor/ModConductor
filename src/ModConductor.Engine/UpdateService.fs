namespace ModConductor.Engine

open ModConductor.ModMaintenance
open ModConductor.Persistence
open ModConductor.Protocol.V1
open ModConductor.Platform

module internal UpdateWire =
    let path value =
        let result = ModLogicalPath()
        result.Components.AddRange(LogicalPath.components value)
        result

    let preview (value: UpdatePreview) =
        let result =
            ModUpdatePreview(
                Id = value.Id.ToString("N"),
                WorkspaceId = value.Target.WorkspaceId.ToString("N"),
                ModId = value.Target.Id.ToString("N"),
                Name = value.Target.Metadata.Name,
                CurrentVersion = value.Target.Metadata.Version,
                NextVersion = value.Plan.Version,
                Mode =
                    (match value.Mode with
                     | UpdateMode.Merge -> ModUpdateMode.Merge
                     | UpdateMode.Replace -> ModUpdateMode.Replace),
                RequiredBytes = uint64 value.Plan.Bytes
            )

        result.Keep.AddRange(value.Keep |> Seq.map path)
        result.SourceNotices.AddRange value.SourceNotices

        for file in value.Files do
            let row =
                ModUpdateFile(
                    Path = path file.Path,
                    HasIncoming = file.Incoming.IsSome,
                    Change =
                        (match file.Change with
                         | FileChange.Add -> ModUpdateChange.Add
                         | FileChange.Replace -> ModUpdateChange.Replace
                         | FileChange.Remove -> ModUpdateChange.Remove
                         | FileChange.Keep -> ModUpdateChange.Keep)
                )

            if not file.Existing.IsEmpty then
                row.ExistingBytes <- file.Existing |> List.sumBy _.Payload.Length |> uint64

            file.IncomingBytes
            |> Option.iter (fun bytes -> row.IncomingBytes <- uint64 bytes)

            row.ExistingPaths.AddRange(file.Existing |> List.map (fun entry -> path entry.Path))
            result.Files.Add row

        result

type UpdateService(store: InstallationStore) =
    inherit ModUpdates.ModUpdatesBase()

    override _.PrepareModUpdate(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, draft, revision = InstallationWire.reference request.Draft

                let mode =
                    match request.Mode with
                    | ModUpdateMode.Merge -> UpdateMode.Merge
                    | ModUpdateMode.Replace -> UpdateMode.Replace
                    | _ -> ModLibraryWire.reject "Choose Merge or Replace."

                let keep =
                    request.Keep
                    |> Seq.map (fun value ->
                        LogicalPath.create (Seq.toList value.Components)
                        |> Result.defaultWith (fun error -> ModLibraryWire.reject (string error)))
                    |> Set.ofSeq

                let! value =
                    store.PrepareUpdate(
                        workspace,
                        draft,
                        revision,
                        ModLibraryWire.id request.ModId,
                        ModLibraryWire.number request.Revision,
                        mode,
                        keep,
                        request.Version
                    )

                return value |> InstallationWire.outcome |> UpdateWire.preview
            })

    override _.StartModUpdate(request, _) =
        InstallationWire.guard (fun () ->
            task {
                return
                    store.StartUpdate(
                        ModLibraryWire.id request.WorkspaceId,
                        ModLibraryWire.id request.PreviewId,
                        ModLibraryWire.id request.Id
                    )
                    |> InstallationWire.outcome
                    |> InstallationWire.status
            })
