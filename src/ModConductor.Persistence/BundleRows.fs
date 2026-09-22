namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.Platform
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.BundleInstallation

type internal BundleSource =
    { Id: Guid
      BundleId: Guid
      Parent: Guid option
      Index: int
      Path: LogicalPath
      ExpectedLength: int64
      Identity: FileIdentity option
      Length: int64 option
      Digest: string option
      Entries: int
      Bytes: int64
      Problem: string option }

type internal BundleWork =
    { Id: Guid
      Workspace: Guid
      ArtifactId: Guid
      Name: string
      Digest: string
      Revision: int64
      Busy: int
      Problem: string option }

module internal BundleRows =
    let refuse message = raise (BundleException message)

    let optional (r: SqliteDataReader) column read =
        if r.IsDBNull column then None else Some(read column)

    let work connection transaction workspace id =
        use q =
            Sqlite.command
                connection
                transaction
                "SELECT artifact_id,archive_name,parent_digest,revision,busy,problem FROM bundle_work WHERE workspace_id=$workspace AND id=$id"
                [ "$workspace", box (string workspace); "$id", box (string id) ]

        use r = q.ExecuteReader()

        if not (r.Read()) then
            refuse "This bundle is no longer open."

        { Id = id
          Workspace = workspace
          ArtifactId = Guid.Parse(r.GetString 0)
          Name = r.GetString 1
          Digest = r.GetString 2
          Revision = r.GetInt64 3
          Busy = r.GetInt32 4
          Problem = optional r 5 r.GetString }

    let check connection transaction (reference: BundleRef) =
        let value = work connection transaction reference.WorkspaceId reference.Id

        if value.Revision <> reference.Revision then
            refuse "The bundle changed. Open its current checklist."

        if value.Busy <> 0 then
            refuse "The bundle has an operation in progress."

        value

    let touch connection transaction id =
        Sqlite.execute
            connection
            transaction
            "UPDATE bundle_work SET revision=revision+1,problem=NULL WHERE id=$id"
            [ "$id", box (string id) ]

    let sources connection transaction id =
        use q =
            Sqlite.command
                connection
                transaction
                "SELECT id,parent_id,entry_index,path,expected_length,identity,length,digest,leaf_entries,leaf_bytes,problem FROM bundle_sources WHERE bundle_id=$id"
                [ "$id", box (string id) ]

        use r = q.ExecuteReader()

        [ while r.Read() do
              yield
                  { Id = Guid.Parse(r.GetString 0)
                    BundleId = id
                    Parent = optional r 1 (r.GetString >> Guid.Parse)
                    Index = r.GetInt32 2
                    Path = LibraryEncoding.readPath (r.GetString 3)
                    ExpectedLength = r.GetInt64 4
                    Identity = optional r 5 (r.GetString >> LibraryEncoding.readIdentity)
                    Length = optional r 6 r.GetInt64
                    Digest = optional r 7 r.GetString
                    Entries = r.GetInt32 8
                    Bytes = r.GetInt64 9
                    Problem = optional r 10 r.GetString } ]

    let source connection transaction bundle id =
        sources connection transaction bundle
        |> List.tryFind (fun s -> s.Id = id)
        |> Option.defaultWith (fun () -> refuse "This archive is no longer in the bundle.")

    let chain (sources: BundleSource list) (source: BundleSource) =
        let rec walk (s: BundleSource) =
            let previous =
                s.Parent
                |> Option.map (fun id -> walk (sources |> List.find (fun n -> n.Id = id)))
                |> Option.defaultValue []

            previous @ [ s ]

        walk source

    let budget values =
        for source in values do
            Budgets.check
                (chain values source |> List.length)
                values.Length
                (values |> List.sumBy _.Entries)
                (values |> List.sumBy (fun s -> s.ExpectedLength + s.Bytes))

    let snapshot connection transaction workspace id =
        let work = work connection transaction workspace id
        let sources = sources connection transaction id

        use q =
            Sqlite.command
                connection
                transaction
                "SELECT m.id,m.source_id,m.mod_id,m.name,m.position,m.attempt,i.state,i.problem FROM bundle_mods m LEFT JOIN archive_installations i ON i.id=m.attempt WHERE m.bundle_id=$id ORDER BY m.position,m.id"
                [ "$id", box (string id) ]

        use r = q.ExecuteReader()

        let mods =
            [ while r.Read() do
                  let source = sources |> List.find (fun s -> s.Id = Guid.Parse(r.GetString 1))

                  let state =
                      if r.IsDBNull 6 then
                          (if source.Problem.IsSome then
                               ModState.Failed
                           else
                               ModState.NeedsReview)
                      else
                          match r.GetInt32 6 with
                          | 0 -> ModState.Installing
                          | 1 -> ModState.Failed
                          | 2 -> ModState.Installed
                          | 3 -> ModState.NeedsReview
                          | _ -> invalidOp "Unknown installation state."

                  yield
                      { Id = Guid.Parse(r.GetString 0)
                        SourceId = source.Id
                        ModId = Guid.Parse(r.GetString 2)
                        Name = r.GetString 3
                        Order = r.GetInt32 4
                        Path = chain sources source |> List.map _.Path
                        Length = source.ExpectedLength
                        State = state
                        IncompleteArchive = source.Identity.IsSome && source.Digest.IsNone
                        Attempt = optional r 5 (r.GetString >> Guid.Parse)
                        Problem = (optional r 7 r.GetString |> Option.orElse source.Problem) } ]

        r.Close()

        let revision =
            Sqlite.number
                connection
                transaction
                "SELECT revision FROM artifacts WHERE id=$id"
                [ "$id", box (string work.ArtifactId) ]

        { Reference =
            { WorkspaceId = workspace
              Id = id
              Revision = work.Revision }
          Artifact =
            { WorkspaceId = workspace
              Id = work.ArtifactId
              Revision = revision }
          ArchiveName = work.Name
          Mods = mods
          TemporaryBytes = sources |> List.sumBy (fun s -> defaultArg s.Length 0L)
          Problem = work.Problem }

    let item connection transaction workspace bundle id =
        (snapshot connection transaction workspace bundle).Mods
        |> List.tryFind (fun m -> m.Id = id)
        |> Option.defaultWith (fun () -> refuse "This mod is no longer in the bundle.")

    let target connection transaction workspace (destination: BundleDestination option) incoming =
        match destination with
        | None -> incoming
        | Some destination ->
            let owner = work connection transaction workspace destination.BundleId

            if owner.Busy <> 0 then
                refuse "The bundle is busy. Wait for its current operation."

            let item =
                item connection transaction workspace destination.BundleId destination.ItemId

            if item.ModId <> destination.ModId then
                refuse "The mod destination changed. Review it again."

            match item.Attempt, item.State with
            | Some id, (ModState.Installed | ModState.Installing | ModState.Failed) -> id
            | _ ->
                let first =
                    (snapshot connection transaction workspace destination.BundleId).Mods
                    |> List.tryFind (fun m -> m.State <> ModState.Installed)

                if first |> Option.exists (fun m -> m.Id <> item.Id) then
                    refuse "Finish the earlier mod first."

                incoming

    let reserved connection transaction id (plan: InstallationPlan) =
        match plan.Bundle with
        | None -> ()
        | Some destination ->
            let bundle =
                snapshot connection transaction plan.Artifact.WorkspaceId destination.BundleId

            if
                bundle.Mods
                |> List.exists (fun item ->
                    item.Id <> destination.ItemId
                    && String.Equals(item.Name, plan.Name, StringComparison.OrdinalIgnoreCase))
            then
                refuse "Use different mod names within this bundle."

            Sqlite.execute
                connection
                transaction
                "UPDATE bundle_mods SET attempt=$attempt,name=$name WHERE id=$id AND mod_id=$mod"
                [ "$name", box plan.Name
                  "$attempt", box (string id)
                  "$id", box (string destination.ItemId)
                  "$mod", box (string destination.ModId) ]

            touch connection transaction destination.BundleId

    let published connection transaction version (plan: InstallationPlan) =
        match plan.Bundle, plan.Nested with
        | Some destination, Some nested ->
            let work =
                work connection transaction plan.Artifact.WorkspaceId destination.BundleId

            let values = sources connection transaction destination.BundleId
            let path = chain values (values |> List.find (fun s -> s.Id = nested.SourceId))

            let paths =
                String.Join('\001', path |> List.map (fun s -> LibraryEncoding.path s.Path))

            let digests = String.Join('\001', path |> List.map (fun s -> s.Digest.Value))

            Sqlite.execute
                connection
                transaction
                "INSERT INTO bundle_version_origins VALUES($version,$parent,$paths,$digests); UPDATE bundle_mods SET name=$name WHERE id=$item"
                [ "$version", box (string version)
                  "$parent", box work.Digest
                  "$paths", box paths
                  "$digests", box digests
                  "$name", box plan.Name
                  "$item", box (string destination.ItemId) ]

            touch connection transaction destination.BundleId
        | None, None -> ()
        | _ -> invalidOp "Bundle installation source is incomplete."
