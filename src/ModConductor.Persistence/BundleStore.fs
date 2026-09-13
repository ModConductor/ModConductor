namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.ArtifactLibrary
open ModConductor.BundleInstallation
open ModConductor.ModLibrary
open ModConductor.Platform

type BundleDiscovery =
    { Draft: InstallationDraft
      Archives: Candidate list }

type BundleStore
    internal
    (
        database: StateDatabase,
        installations: InstallationStore,
        sources: BundleSources,
        inspection: Inspection
    ) =
    let connection = database.Connection
    let wait (task: Task<'a>) = task.GetAwaiter().GetResult()
    let db action = database.EnqueueInternal action |> wait
    let refuse = BundleRows.refuse

    let name value =
        InventoryPolicy.metadata
            { Name = value
              Version = ""
              Notes = ""
              Comment = ""
              Source = ""
              Categories = [] }
        |> Result.map _.Name
        |> Result.defaultWith (fun _ -> refuse "Enter a mod name of at most 256 characters.")

    let snapshot workspace id =
        BundleRows.snapshot connection null workspace id

    let add
        connection
        transaction
        bundle
        parent
        position
        (existing: string list)
        (candidates: Candidate list)
        =
        let names =
            System.Collections.Generic.HashSet<string>(existing, StringComparer.OrdinalIgnoreCase)

        for offset, candidate in List.indexed candidates do
            let sourceId, itemId, modId = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

            let proposed =
                name (Path.GetFileNameWithoutExtension(LogicalPath.display candidate.Path))

            let mutable destination = proposed
            let mutable suffix = 2

            while not (names.Add destination) do
                destination <- proposed + " (" + string suffix + ")"
                suffix <- suffix + 1

            Sqlite.execute
                connection
                transaction
                "INSERT INTO bundle_sources(id,bundle_id,parent_id,entry_index,path,expected_length) VALUES($source,$bundle,$parent,$index,$path,$length); INSERT INTO bundle_mods(id,bundle_id,source_id,mod_id,name,position) VALUES($item,$bundle,$source,$mod,$name,$position)"
                [ "$source", box (string sourceId)
                  "$bundle", box (string bundle)
                  "$parent",
                  parent |> Option.map (string >> box) |> Option.defaultValue (box DBNull.Value)
                  "$index", box candidate.Index
                  "$path", box (LibraryEncoding.path candidate.Path)
                  "$length", box candidate.Length
                  "$item", box (string itemId)
                  "$mod", box (string modId)
                  "$name", box destination
                  "$position", box (position + offset) ]

    let selected (draft: InstallationDraft) indices =
        let candidates =
            Discovery.candidates draft.Manifest
            |> List.map (fun c -> c.Index, c)
            |> Map.ofList

        if List.isEmpty indices then
            refuse "Select at least one archive."

        indices
        |> List.distinct
        |> List.map (fun i ->
            candidates
            |> Map.tryFind i
            |> Option.defaultWith (fun () -> refuse "Select an archive from this bundle."))

    let checkedDraft (reference: BundleRef) itemId draftId revision =
        let draft = installations.Draft(reference.WorkspaceId, draftId, revision)

        match draft.Bundle with
        | Some destination when destination.BundleId = reference.Id && destination.ItemId = itemId ->
            draft
        | _ -> refuse "Open this mod's current archive review."

    member _.Status(workspace, bundle, itemId) =
        task {
            let item = db (fun () -> BundleRows.item connection null workspace bundle itemId)

            let id =
                item.Attempt
                |> Option.defaultWith (fun () -> refuse "This mod has not started installation.")

            return! installations.Read(workspace, id)
        }

    member _.Find(workspace, artifact) =
        database.Enqueue(fun () ->
            use q =
                Sqlite.command
                    connection
                    null
                    "SELECT id FROM bundle_work WHERE workspace_id=$workspace AND artifact_id=$artifact"
                    [ "$workspace", box (string workspace); "$artifact", box (string artifact) ]

            match q.ExecuteScalar() with
            | :? string as id -> Some(snapshot workspace (Guid.Parse id))
            | _ -> None)

    member _.Read(workspace, id) =
        database.Enqueue(fun () -> snapshot workspace id)

    member _.Discover(reference, token) =
        task {
            let! draft = installations.Prepare(reference, token)

            return
                { Draft = draft
                  Archives = Discovery.candidates draft.Manifest }
        }

    member _.Create(workspace, draftId, revision, indices) =
        let draft = installations.Draft(workspace, draftId, revision)

        if draft.Nested.IsSome then
            refuse "Choose nested archives from their current bundle."

        let chosen = selected draft indices

        let result =
            db (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                if
                    Sqlite.number
                        connection
                        transaction
                        "SELECT count(*) FROM bundle_work WHERE workspace_id=$workspace"
                        [ "$workspace", box (string workspace) ]
                    <> 0L
                then
                    refuse "Finish the open bundle or delete its temporary files first."

                let id = Guid.NewGuid()

                Sqlite.execute
                    connection
                    transaction
                    "INSERT INTO bundle_work(id,workspace_id,artifact_id,archive_name,parent_digest,owner) VALUES($id,$workspace,$artifact,$name,$digest,$owner)"
                    [ "$id", box (string id)
                      "$workspace", box (string workspace)
                      "$artifact", box (string draft.Artifact.Id)
                      "$name", box draft.ArchiveName
                      "$digest", box draft.Manifest.Sha256
                      "$owner", box database.OwnerId ]

                add connection transaction id None 0 [] chosen
                BundleRows.sources connection transaction id |> BundleRows.budget
                transaction.Commit()
                snapshot workspace id)

        installations.CloseDraft(workspace, draftId)
        result

    member _.Prepare(reference: BundleRef, itemId, token: CancellationToken) =
        task {
            let item =
                db (fun () ->
                    BundleRows.check connection null reference |> ignore

                    let item =
                        BundleRows.item connection null reference.WorkspaceId reference.Id itemId

                    if item.State = ModState.Installed || item.State = ModState.Installing then
                        refuse
                            "This mod has already started installation. Open its current status."

                    if item.State = ModState.Failed && item.Attempt.IsSome then
                        refuse "Delete the incomplete mod files before reviewing again."

                    item)

            let mutable opened = None

            try
                let! input =
                    sources.Materialize(
                        reference.WorkspaceId,
                        reference.Id,
                        item.SourceId,
                        inspection,
                        token
                    )

                let bundle = db (fun () -> snapshot reference.WorkspaceId reference.Id)
                let archiveName = LogicalPath.components (List.last item.Path) |> List.last

                let destination =
                    { BundleId = reference.Id
                      ItemId = item.Id
                      ModId = item.ModId }

                let! draft =
                    installations.PrepareNested(
                        bundle.Artifact,
                        input,
                        destination,
                        archiveName,
                        item.Name,
                        token
                    )

                opened <- Some draft.Id

                db (fun () ->
                    use transaction = connection.BeginTransaction(deferred = false)

                    BundleRows.item
                        connection
                        transaction
                        reference.WorkspaceId
                        reference.Id
                        itemId
                    |> ignore

                    Sqlite.execute
                        connection
                        transaction
                        "UPDATE bundle_sources SET leaf_entries=$entries,leaf_bytes=$bytes,problem=NULL WHERE id=$id"
                        [ "$id", box (string item.SourceId)
                          "$entries", box draft.Manifest.Entries.Length
                          "$bytes", box draft.Manifest.TotalSize ]

                    BundleRows.sources connection transaction reference.Id |> BundleRows.budget
                    BundleRows.touch connection transaction reference.Id
                    transaction.Commit())

                return
                    { Draft = draft
                      Archives = Discovery.candidates draft.Manifest }
            with error ->
                opened
                |> Option.iter (fun id -> installations.CloseDraft(reference.WorkspaceId, id))

                let message =
                    match error with
                    | :? OperationCanceledException ->
                        "Archive preparation cancelled. Review this mod to continue."
                    | _ -> ArchiveFailure.message error |> Option.defaultValue error.Message

                db (fun () ->
                    Sqlite.execute
                        connection
                        null
                        "UPDATE bundle_sources SET problem=$problem WHERE id=$id"
                        [ "$id", box (string item.SourceId); "$problem", box message ]

                    BundleRows.touch connection null reference.Id)

                return raise error
        }

    member _.ChooseNested(reference: BundleRef, itemId, draftId, revision, indices) =
        let draft = checkedDraft reference itemId draftId revision
        let chosen = selected draft indices

        let result =
            db (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                BundleRows.check connection transaction reference |> ignore

                let item =
                    BundleRows.item
                        connection
                        transaction
                        reference.WorkspaceId
                        reference.Id
                        itemId

                if item.Attempt.IsSome then
                    refuse "Nested archive selection cannot replace a started installation."

                let all =
                    BundleRows.snapshot connection transaction reference.WorkspaceId reference.Id

                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM bundle_mods WHERE id=$id; UPDATE bundle_sources SET leaf_entries=0,leaf_bytes=0 WHERE id=$source; UPDATE bundle_mods SET position=position+$shift WHERE bundle_id=$bundle AND position>$position"
                    [ "$id", box (string itemId)
                      "$source", box (string item.SourceId)
                      "$bundle", box (string reference.Id)
                      "$position", box item.Order
                      "$shift", box (chosen.Length - 1) ]

                add
                    connection
                    transaction
                    reference.Id
                    (Some item.SourceId)
                    item.Order
                    (all.Mods |> List.filter (fun m -> m.Id <> itemId) |> List.map _.Name)
                    chosen

                BundleRows.sources connection transaction reference.Id |> BundleRows.budget
                BundleRows.touch connection transaction reference.Id
                transaction.Commit()
                snapshot reference.WorkspaceId reference.Id)

        installations.CloseDraft(reference.WorkspaceId, draftId)
        result

    member _.Rename(reference: BundleRef, itemId, newName) =
        let newName = name newName

        db (fun () ->
            use transaction = connection.BeginTransaction(deferred = false)
            BundleRows.check connection transaction reference |> ignore

            let bundle =
                BundleRows.snapshot connection transaction reference.WorkspaceId reference.Id

            let item = bundle.Mods |> List.find (fun m -> m.Id = itemId)

            if item.State = ModState.Installed || item.Attempt.IsSome then
                refuse "Change the name before starting this mod."

            if
                bundle.Mods
                |> List.exists (fun m ->
                    m.Id <> itemId
                    && String.Equals(m.Name, newName, StringComparison.OrdinalIgnoreCase))
            then
                refuse "Use different mod names within this bundle."

            Sqlite.execute
                connection
                transaction
                "UPDATE bundle_mods SET name=$name WHERE id=$id"
                [ "$id", box (string itemId); "$name", box newName ]

            BundleRows.touch connection transaction reference.Id
            transaction.Commit()
            snapshot reference.WorkspaceId reference.Id)

    member _.Move(reference: BundleRef, itemId, earlier) =
        db (fun () ->
            use transaction = connection.BeginTransaction(deferred = false)
            BundleRows.check connection transaction reference |> ignore

            let bundle =
                BundleRows.snapshot connection transaction reference.WorkspaceId reference.Id

            let index = bundle.Mods |> List.findIndex (fun m -> m.Id = itemId)
            let other = index + (if earlier then -1 else 1)

            if other < 0 || other >= bundle.Mods.Length then
                refuse "This mod is already at the end of the list."

            let item, neighbor = bundle.Mods[index], bundle.Mods[other]

            if
                item.State = ModState.Installed
                || neighbor.State = ModState.Installed
                || item.State = ModState.Installing
                || neighbor.State = ModState.Installing
            then
                refuse "Only unfinished mods can change installation order."

            Sqlite.execute
                connection
                transaction
                "UPDATE bundle_mods SET position=$other WHERE id=$id; UPDATE bundle_mods SET position=$position WHERE id=$neighbor"
                [ "$id", box (string itemId)
                  "$other", box neighbor.Order
                  "$position", box item.Order
                  "$neighbor", box (string neighbor.Id) ]

            BundleRows.touch connection transaction reference.Id
            transaction.Commit()
            snapshot reference.WorkspaceId reference.Id)

    member _.Retry(reference: BundleRef, itemId) =
        task {
            let item =
                db (fun () ->
                    BundleRows.check connection null reference |> ignore
                    BundleRows.item connection null reference.WorkspaceId reference.Id itemId)

            match item.State, item.Attempt with
            | ModState.Installed, _ ->
                return db (fun () -> snapshot reference.WorkspaceId reference.Id)
            | ModState.Installing, _ -> return refuse "Wait for this installation to stop."
            | ModState.Failed, Some id ->
                let! _ = installations.Discard(reference.WorkspaceId, id)

                return
                    db (fun () ->
                        BundleRows.touch connection null reference.Id
                        snapshot reference.WorkspaceId reference.Id)
            | _ ->
                let! result =
                    sources.ClearIncomplete(reference.WorkspaceId, reference.Id, item.SourceId)

                result
                |> Result.defaultWith (fun _ ->
                    refuse "The incomplete archive copy could not be deleted.")

                return db (fun () -> snapshot reference.WorkspaceId reference.Id)
        }

    member _.Delete(reference: BundleRef) =
        task {
            let! result =
                sources.Exclusive(
                    reference.WorkspaceId,
                    reference.Id,
                    fun directory ->
                        let bundle =
                            db (fun () ->
                                let work =
                                    BundleRows.work
                                        connection
                                        null
                                        reference.WorkspaceId
                                        reference.Id

                                if work.Revision <> reference.Revision then
                                    refuse "The bundle changed. Review its current checklist."

                                snapshot reference.WorkspaceId reference.Id)

                        if bundle.Mods |> List.exists (fun m -> m.State = ModState.Installing) then
                            refuse "Cancel the current installation and wait for it to stop first."

                        for item in bundle.Mods do
                            match item.State, item.Attempt with
                            | ModState.Failed, Some id ->
                                installations.Discard(reference.WorkspaceId, id) |> wait |> ignore
                            | _ -> ()

                        let nodes = db (fun () -> BundleRows.sources connection null reference.Id)

                        for node in nodes do
                            ArtifactFiles.remove directory (BundleFiles.name node.Id) node.Identity

                            db (fun () ->
                                Sqlite.execute
                                    connection
                                    null
                                    "UPDATE bundle_sources SET identity=NULL,length=NULL,digest=NULL WHERE id=$id"
                                    [ "$id", box (string node.Id) ])

                        db (fun () ->
                            use transaction = connection.BeginTransaction(deferred = false)

                            Sqlite.execute
                                connection
                                transaction
                                "DELETE FROM bundle_mods WHERE bundle_id=$id"
                                [ "$id", box (string reference.Id) ]

                            for node in
                                nodes
                                |> List.sortByDescending (fun n ->
                                    (BundleRows.chain nodes n).Length) do
                                Sqlite.execute
                                    connection
                                    transaction
                                    "DELETE FROM bundle_sources WHERE id=$id"
                                    [ "$id", box (string node.Id) ]

                            Sqlite.execute
                                connection
                                transaction
                                "DELETE FROM bundle_work WHERE id=$id"
                                [ "$id", box (string reference.Id) ]

                            transaction.Commit())
                )

            result
            |> Result.defaultWith (fun _ ->
                refuse
                    "The temporary files could not be deleted. Try again from the bundle checklist.")

            installations.CloseBundleDraft(reference.WorkspaceId, reference.Id)
        }
