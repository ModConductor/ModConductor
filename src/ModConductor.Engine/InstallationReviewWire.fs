namespace ModConductor.Engine

open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.Platform
open ModConductor.Protocol.V1

module internal InstallationReviewWire =
    let file (entries: Map<int, ArchiveEntry>) (planned: ReviewedFile) =
        let file =
            InstallationReviewedFile(
                Index = uint32 planned.File.Index,
                Choice = planned.Choice,
                Bytes = uint64 entries[planned.File.Index].Size
            )

        file.Destination.AddRange(LogicalPath.components planned.File.Destination)
        file.Source.AddRange(LogicalPath.components planned.Source)

        for path in planned.Replaces do
            let source = InstallationSourcePath()
            source.Path.AddRange(LogicalPath.components path)
            file.Replaces.Add source

        file
