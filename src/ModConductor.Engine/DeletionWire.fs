namespace ModConductor.Engine

open ModConductor.ModMaintenance
open ModConductor.Protocol.V1

module internal DeletionWire =
    let preview (value: DeletionPreview) =
        let result =
            ModDeletionPreview(
                WorkspaceId = value.WorkspaceId.ToString("N"),
                ModId = value.ModId.ToString("N"),
                Revision = uint64 value.Revision,
                Name = value.Name,
                Versions = uint32 value.Versions
            )

        result.Backups.AddRange value.Backups
        result.External.AddRange value.External
        value.Blocked |> Option.iter (fun text -> result.Blocked <- text)

        result.Profiles.AddRange(
            value.Profiles
            |> List.map (fun profile ->
                ModDeletionProfile(Id = profile.Id.ToString("N"), Name = profile.Name))
        )

        for deployment in value.Deployments do
            let row =
                ModDeletionDeployment(
                    ContextId = deployment.ContextId.ToString("N"),
                    Id = deployment.Id.ToString("N"),
                    Name = deployment.Name,
                    Active = deployment.Active
                )

            deployment.PreparedAt
            |> Option.iter (fun date -> row.PreparedAtUnixMs <- date.ToUnixTimeMilliseconds())

            result.Deployments.Add row

        for file in value.Files do
            let row =
                ModDeletionFile(
                    Label = file.Label,
                    Shared = file.Shared,
                    Kind =
                        (match file.Kind with
                         | DeletionFileKind.Payload -> ModDeletionFileKind.Payload
                         | DeletionFileKind.Archive -> ModDeletionFileKind.Archive
                         | DeletionFileKind.Temporary -> ModDeletionFileKind.Temporary
                         | DeletionFileKind.GenerationLink -> ModDeletionFileKind.GenerationLink)
                )

            file.Bytes |> Option.iter (fun bytes -> row.Bytes <- uint64 bytes)
            result.Files.Add row

        result
