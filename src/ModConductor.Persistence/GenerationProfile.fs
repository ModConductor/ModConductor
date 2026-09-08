namespace ModConductor.Persistence

open System
open System.Text
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.FilePlanning

module internal GenerationProfile =
    let capture connection transaction (sources: PlanSources) : SavedProfile =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT name FROM profiles WHERE id=$id"
                [ "$id", box (string sources.Profile.ProfileId) ]

        { Id = sources.Profile.ProfileId
          Name = query.ExecuteScalar() :?> string
          Revision = sources.Profile.Revision
          Mods =
            sources.Profile.Mods
            |> List.map (fun value ->
                { ModId = value.ModId
                  VersionId = value.Version |> Option.map _.Id
                  Priority = value.Priority
                  Enabled = value.Enabled })
          Hidden = sources.Hidden }

    let restore connection transaction workspace (saved: SavedProfile) =
        let mutable remaining = Limits.entries
        let mutable bytes = 0L

        let mods =
            saved.Mods
            |> List.map (fun pin ->
                match LibraryRows.find connection transaction pin.ModId with
                | Some row when row.Entry.WorkspaceId = workspace -> ()
                | _ -> RecoveryFiles.fail "A mod required by the saved deployment is unavailable."

                let version =
                    pin.VersionId
                    |> Option.map (fun id ->
                        let value =
                            LibraryRows.version connection transaction id 0 (remaining + 1)
                            |> Option.defaultWith (fun () ->
                                RecoveryFiles.fail
                                    "An exact mod version required by the saved deployment is unavailable.")

                        if value.ModId <> pin.ModId then
                            RecoveryFiles.fail
                                "The saved deployment version does not belong to its mod."

                        remaining <- remaining - value.Entries.Length

                        for entry in value.Entries do
                            bytes <-
                                bytes
                                + int64 (
                                    Encoding.UTF8.GetByteCount(LibraryEncoding.path entry.Path)
                                    + 256
                                )

                        if remaining < 0 || bytes > Limits.snapshotBytes then
                            raise (RecoveryException RecoveryError.Limit)

                        value)

                { ModId = pin.ModId
                  Priority = pin.Priority
                  Enabled = pin.Enabled
                  Version = version
                  Mappings =
                    [ { SourcePrefix = PlanPath.Root
                        TargetRoot = workspace
                        TargetPrefix = PlanPath.Root } ]
                  Archives = [] })

        { ProfileId = saved.Id
          Revision = saved.Revision
          Complete = true
          Mods = mods }
