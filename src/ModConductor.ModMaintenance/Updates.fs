namespace ModConductor.ModMaintenance

open System
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.ArchiveInstallation

module Updates =
    let private overlapping getPath rows =
        let exact = System.Collections.Generic.Dictionary<string, 'a>()
        let descendants = System.Collections.Generic.Dictionary<string, ResizeArray<'a>>()

        for row in rows do
            let path = getPath row
            exact[Destinations.key path] <- row
            let parts = LogicalPath.components path

            for count in 1 .. parts.Length do
                let prefix =
                    LogicalPath.create (List.take count parts)
                    |> Result.defaultWith (string >> invalidOp)

                let key = Destinations.key prefix

                if not (descendants.ContainsKey key) then
                    descendants[key] <- ResizeArray()

                descendants[key].Add row

        fun path ->
            let parts = LogicalPath.components path

            [ match descendants.TryGetValue(Destinations.key path) with
              | true, values -> yield! values
              | _ -> ()
              for count in 1 .. parts.Length - 1 do
                  let prefix =
                      LogicalPath.create (List.take count parts)
                      |> Result.defaultWith (string >> invalidOp)

                  match exact.TryGetValue(Destinations.key prefix) with
                  | true, value -> yield value
                  | _ -> () ]

    let prepare
        (draft: InstallationDraft)
        (target: ModEntry)
        (version: ModVersion)
        mode
        keep
        label
        notices
        =
        let incoming = draft.Files
        let incomingAt = overlapping (fun (file: SelectedFile) -> file.Destination) incoming

        let inconsistentChoice =
            version.Entries
            |> List.exists (fun old ->
                let matches = incomingAt old.Path

                let kept =
                    matches |> List.filter (fun file -> keep |> Set.contains file.Destination)

                not kept.IsEmpty && kept.Length <> matches.Length)

        if
            target.Kind <> ModKind.Regular
            || target.WorkspaceId <> draft.Artifact.WorkspaceId
            || target.CurrentVersion <> Some version.Id
            || version.ModId <> target.Id
        then
            Error "Choose an installed regular mod in this workspace."
        elif inconsistentChoice then
            Error "Use the same choice for files that replace the same current path."
        else
            let existingAt =
                overlapping (fun (file: ManifestEntry) -> file.Path) version.Entries

            let selected =
                incoming
                |> List.filter (fun file -> not (keep |> Set.contains file.Destination))

            let retained =
                version.Entries
                |> List.filter (fun old ->
                    let matches = incomingAt old.Path

                    if matches.IsEmpty then
                        mode = UpdateMode.Merge
                    else
                        matches |> List.forall (fun file -> keep |> Set.contains file.Destination))

            let sizes =
                draft.Manifest.Entries
                |> List.map (fun entry -> entry.Index, entry.Size)
                |> Map.ofList

            let changes =
                [ for file in incoming do
                      let existing = existingAt file.Destination

                      yield
                          { Path = file.Destination
                            Change =
                              if keep.Contains file.Destination then FileChange.Keep
                              elif existing.IsEmpty then FileChange.Add
                              else FileChange.Replace
                            Existing = existing
                            Incoming = Some file
                            IncomingBytes = Some sizes[file.Index] }
                  for old in version.Entries do
                      if (incomingAt old.Path).IsEmpty then
                          yield
                              { Path = old.Path
                                Change =
                                  (if mode = UpdateMode.Merge then
                                       FileChange.Keep
                                   else
                                       FileChange.Remove)
                                Existing = [ old ]
                                Incoming = None
                                IncomingBytes = None } ]

            let plan =
                Layout.forUpdate
                    draft
                    target.Metadata.Name
                    label
                    { ModId = target.Id
                      Revision = target.Revision
                      PreviousVersion = version.Id
                      Existing = retained }
                    selected

            let preview =
                { Id = Guid.NewGuid()
                  DraftId = draft.Id
                  DraftRevision = draft.Revision
                  Target = target
                  Previous = version
                  Mode = mode
                  Keep = keep
                  Files = changes
                  Plan = plan
                  SourceNotices = notices }


            Ok preview
