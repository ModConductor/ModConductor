namespace ModConductor.Engine

open ModConductor.Platform
open ModConductor.BundleInstallation
open ModConductor.Protocol.V1

module internal BundleWire =
    let reference (value: BundleReference) : BundleRef =
        if isNull value then
            ModLibraryWire.reject "Open a bundle checklist."

        { WorkspaceId = ModLibraryWire.id value.WorkspaceId
          Id = ModLibraryWire.id value.Id
          Revision = ModLibraryWire.number value.Revision }

    let artifact (value: ArtifactReference) : ModConductor.ArtifactLibrary.ArtifactRef =
        if isNull value then
            ModLibraryWire.reject "Choose an archive."

        { WorkspaceId = ModLibraryWire.id value.WorkspaceId
          Id = ModLibraryWire.id value.Id
          Revision = ModLibraryWire.number value.Revision }

    let bundle (value: Bundle) =
        let r = value.Reference
        let a = value.Artifact

        let output =
            ModBundle(
                Reference =
                    BundleReference(
                        WorkspaceId = r.WorkspaceId.ToString("N"),
                        Id = r.Id.ToString("N"),
                        Revision = uint64 r.Revision
                    ),
                Artifact =
                    ArtifactReference(
                        WorkspaceId = a.WorkspaceId.ToString("N"),
                        Id = a.Id.ToString("N"),
                        Revision = uint64 a.Revision
                    ),
                ArchiveName = value.ArchiveName,
                TemporaryBytes = uint64 value.TemporaryBytes
            )

        value.Problem |> Option.iter (fun p -> output.Problem <- p)

        for item in value.Mods do
            let state =
                match item.State with
                | ModState.NeedsReview -> BundleModState.NeedsReview
                | ModState.Installed -> BundleModState.Installed
                | ModState.Failed -> BundleModState.Failed
                | ModState.Installing -> BundleModState.Installing

            let result =
                BundleMod(
                    Id = item.Id.ToString("N"),
                    SourceId = item.SourceId.ToString("N"),
                    ModId = item.ModId.ToString("N"),
                    Name = item.Name,
                    Order = uint32 item.Order,
                    Bytes = uint64 item.Length,
                    IncompleteArchive = item.IncompleteArchive,
                    State = state
                )

            for path in item.Path do
                let source = BundleArchivePath()
                source.Components.AddRange(LogicalPath.components path)
                result.Archives.Add source

            item.Attempt |> Option.iter (fun id -> result.AttemptId <- id.ToString("N"))
            item.Problem |> Option.iter (fun p -> result.Problem <- p)
            output.Mods.Add result

        output

    let discovery (value: ModConductor.Persistence.BundleDiscovery) =
        let result = BundleDiscovery(Draft = InstallationWire.draft value.Draft)

        for candidate in value.Archives do
            let entry =
                BundleArchive(Index = uint32 candidate.Index, Bytes = uint64 candidate.Length)

            entry.Path.AddRange(LogicalPath.components candidate.Path)
            result.Archives.Add entry

        result
