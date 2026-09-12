namespace ModConductor.Engine

open ModConductor.ArchiveInstallation
open ModConductor.Bain
open ModConductor.Protocol.V1

module internal BainWire =
    let choices (value: PackageChoices) =
        let draft = value.Draft

        let result =
            BainChoices(
                Reference =
                    InstallationDraftReference(
                        WorkspaceId = draft.Artifact.WorkspaceId.ToString("N"),
                        Id = draft.Id.ToString("N"),
                        Revision = uint64 draft.Revision
                    )
            )

        value.Problem |> Option.iter (fun p -> result.Problem <- p)

        match value.Selection with
        | None -> ()
        | Some state ->
            result.HasNotes <- state.Definition.Notes.IsSome
            result.Reviewing <- state.Reviewing

            for package in state.Definition.Packages do
                result.Packages.Add(
                    BainPackage(
                        Index = uint32 package.Index,
                        Name = package.Name,
                        Files = uint32 package.Files.Length,
                        Bytes = uint64 package.Bytes,
                        Selected = state.Selected.Contains package.Index
                    )
                )

            if state.Reviewing then
                result.ReviewedDraft <- InstallationWire.draft draft
                let entries = draft.Manifest.Entries |> List.map (fun e -> e.Index, e) |> Map.ofList

                for key, file in Map.toList state.Files do
                    result.Files.Add(
                        BainReviewedFile(
                            File = InstallationReviewWire.file entries file,
                            Included = not (state.Excluded.Contains key)
                        )
                    )

        result

    let folder ((draft: InstallationDraft), files) =
        let entries = draft.Manifest.Entries |> List.map (fun e -> e.Index, e) |> Map.ofList
        let result = BainFolderFiles()
        result.Files.AddRange(files |> List.map (InstallationReviewWire.file entries))
        result
