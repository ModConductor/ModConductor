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

    let required message =
        function
        | Some value -> Ok value
        | None -> Error message


    let transact action =
        db (fun () ->
            use transaction = connection.BeginTransaction(deferred = false)
            let outcome = action transaction

            if Result.isOk outcome then
                transaction.Commit()

            outcome)

    let name value =
        InventoryPolicy.metadata
            { Name = value
              Version = ""
              Notes = ""
              Comment = ""
              Source = ""
              Categories = [] }
        |> Result.map _.Name
        |> Result.mapError (fun _ -> "Enter a mod name of at most 256 characters.")

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

        let insert (offset, candidate: Candidate) =
            let sourceId, itemId, modId = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

            name (Path.GetFileNameWithoutExtension(LogicalPath.display candidate.Path))
            |> Result.map (fun proposed ->
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
                      parent
                      |> Option.map (string >> box)
                      |> Option.defaultValue (box DBNull.Value)
                      "$index", box candidate.Index
                      "$path", box (LibraryEncoding.path candidate.Path)
                      "$length", box candidate.Length
                      "$item", box (string itemId)
                      "$mod", box (string modId)
                      "$name", box destination
                      "$position", box (position + offset) ])

        candidates
        |> List.indexed
        |> List.fold
            (fun outcome candidate -> outcome |> Result.bind (fun () -> insert candidate))
            (Ok())

    let selected (draft: InstallationDraft) indices =
        let candidates =
            Discovery.candidates draft.Manifest
            |> List.map (fun c -> c.Index, c)
            |> Map.ofList

        if List.isEmpty indices then
            Error "Select at least one archive."
        else
            indices
            |> List.distinct
            |> List.fold
                (fun outcome index ->
                    outcome
                    |> Result.bind (fun chosen ->
                        candidates
                        |> Map.tryFind index
                        |> required "Select an archive from this bundle."
                        |> Result.map (fun candidate -> candidate :: chosen)))
                (Ok [])
            |> Result.map List.rev

    let checkedDraft (reference: BundleRef) itemId draftId revision =
        installations.Draft(reference.WorkspaceId, draftId, revision)
        |> Result.bind (fun draft ->
            match draft.Bundle with
            | Some destination when
                destination.BundleId = reference.Id && destination.ItemId = itemId
                ->
                Ok draft
            | _ -> Error "Open this mod's current archive review.")

    member _.Status(workspace, bundle, itemId) =
        task {
            match db (fun () -> BundleRows.item connection null workspace bundle itemId) with
            | Error error -> return Error error
            | Ok item ->
                match item.Attempt with
                | None -> return Error "This mod has not started installation."
                | Some id ->
                    let! status = installations.Read(workspace, id)
                    return Ok status
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
            | :? string as id -> snapshot workspace (Guid.Parse id) |> Result.map Some
            | _ -> Ok None)

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
        installations.Draft(workspace, draftId, revision)
        |> Result.bind (fun draft ->
            if draft.Nested.IsSome then
                Error "Choose nested archives from their current bundle."
            else
                selected draft indices
                |> Result.bind (fun chosen ->
                    transact (fun transaction ->
                        if
                            Sqlite.number
                                connection
                                transaction
                                "SELECT count(*) FROM bundle_work WHERE workspace_id=$workspace"
                                [ "$workspace", box (string workspace) ]
                            <> 0L
                        then
                            Error "Finish the open bundle or delete its temporary files first."
                        else
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
                            |> Result.bind (fun () ->
                                BundleRows.sources connection transaction id
                                |> BundleRows.budget

                                BundleRows.snapshot connection transaction workspace id)))
                |> fun outcome ->
                    if Result.isOk outcome then
                        installations.CloseDraft(workspace, draftId)

                    outcome)

    member _.Prepare(reference: BundleRef, itemId, token: CancellationToken) =
        task {
            let checkedItem =
                db (fun () ->
                    BundleRows.check connection null reference
                    |> Result.bind (fun _ ->
                        BundleRows.item connection null reference.WorkspaceId reference.Id itemId)
                    |> Result.bind (fun item ->
                        if
                            item.State = ModState.Installed || item.State = ModState.Installing
                        then
                            Error
                                "This mod has already started installation. Open its current status."
                        elif item.State = ModState.Failed && item.Attempt.IsSome then
                            Error "Delete the incomplete mod files before reviewing again."
                        else
                            Ok item))

            match checkedItem with
            | Error error -> return Error error
            | Ok item ->
                let mutable opened = None

                let recordProblem message =
                    db (fun () ->
                        Sqlite.execute
                            connection
                            null
                            "UPDATE bundle_sources SET problem=$problem WHERE id=$id"
                            [ "$id", box (string item.SourceId); "$problem", box message ]

                        BundleRows.touch connection null reference.Id)

                let rejectExpected message =
                    opened
                    |> Option.iter (fun id -> installations.CloseDraft(reference.WorkspaceId, id))

                    recordProblem message
                    Error message

                try
                    let! input =
                        sources.Materialize(
                            reference.WorkspaceId,
                            reference.Id,
                            item.SourceId,
                            inspection,
                            token
                        )

                    match input with
                    | Error error -> return rejectExpected error
                    | Ok input ->
                        let bundle = db (fun () -> snapshot reference.WorkspaceId reference.Id)

                        match bundle with
                        | Error error -> return rejectExpected error
                        | Ok bundle ->
                            let archiveName =
                                LogicalPath.components (List.last item.Path) |> List.last

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

                            let recorded =
                                transact (fun transaction ->
                                    BundleRows.item
                                        connection
                                        transaction
                                        reference.WorkspaceId
                                        reference.Id
                                        itemId
                                    |> Result.map (fun _ ->
                                        Sqlite.execute
                                            connection
                                            transaction
                                            "UPDATE bundle_sources SET leaf_entries=$entries,leaf_bytes=$bytes,problem=NULL WHERE id=$id"
                                            [ "$id", box (string item.SourceId)
                                              "$entries", box draft.Manifest.Entries.Length
                                              "$bytes", box draft.Manifest.TotalSize ]

                                        BundleRows.sources connection transaction reference.Id
                                        |> BundleRows.budget

                                        BundleRows.touch connection transaction reference.Id))

                            match recorded with
                            | Error error -> return rejectExpected error
                            | Ok() ->
                                return
                                    Ok
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

                    recordProblem message
                    return raise error
        }

    member _.ChooseNested(reference: BundleRef, itemId, draftId, revision, indices) =
        checkedDraft reference itemId draftId revision
        |> Result.bind (fun draft -> selected draft indices)
        |> Result.bind (fun chosen ->
            transact (fun transaction ->
                BundleRows.check connection transaction reference
                |> Result.bind (fun _ ->
                    BundleRows.item
                        connection
                        transaction
                        reference.WorkspaceId
                        reference.Id
                        itemId)
                |> Result.bind (fun item ->
                    if item.Attempt.IsSome then
                        Error "Nested archive selection cannot replace a started installation."
                    else
                        BundleRows.snapshot
                            connection
                            transaction
                            reference.WorkspaceId
                            reference.Id
                        |> Result.bind (fun all ->
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
                                (all.Mods
                                 |> List.filter (fun m -> m.Id <> itemId)
                                 |> List.map _.Name)
                                chosen
                            |> Result.bind (fun () ->
                                BundleRows.sources connection transaction reference.Id
                                |> BundleRows.budget

                                BundleRows.touch connection transaction reference.Id

                                BundleRows.snapshot
                                    connection
                                    transaction
                                    reference.WorkspaceId
                                    reference.Id)))))
        |> fun outcome ->
            if Result.isOk outcome then
                installations.CloseDraft(reference.WorkspaceId, draftId)

            outcome

    member _.Rename(reference: BundleRef, itemId, newName) =
        name newName
        |> Result.bind (fun newName ->
            transact (fun transaction ->
                BundleRows.check connection transaction reference
                |> Result.bind (fun _ ->
                    BundleRows.snapshot connection transaction reference.WorkspaceId reference.Id)
                |> Result.bind (fun bundle ->
                    bundle.Mods
                    |> List.tryFind (fun item -> item.Id = itemId)
                    |> required "This mod is no longer in the bundle."
                    |> Result.bind (fun item ->
                        if item.State = ModState.Installed || item.Attempt.IsSome then
                            Error "Change the name before starting this mod."
                        elif
                            bundle.Mods
                            |> List.exists (fun modItem ->
                                modItem.Id <> itemId
                                && String.Equals(
                                    modItem.Name,
                                    newName,
                                    StringComparison.OrdinalIgnoreCase
                                ))
                        then
                            Error "Use different mod names within this bundle."
                        else
                            Sqlite.execute
                                connection
                                transaction
                                "UPDATE bundle_mods SET name=$name WHERE id=$id"
                                [ "$id", box (string itemId); "$name", box newName ]

                            BundleRows.touch connection transaction reference.Id

                            BundleRows.snapshot
                                connection
                                transaction
                                reference.WorkspaceId
                                reference.Id))))

    member _.Move(reference: BundleRef, itemId, earlier) =
        transact (fun transaction ->
            BundleRows.check connection transaction reference
            |> Result.bind (fun _ ->
                BundleRows.snapshot connection transaction reference.WorkspaceId reference.Id)
            |> Result.bind (fun bundle ->
                bundle.Mods
                |> List.tryFindIndex (fun item -> item.Id = itemId)
                |> required "This mod is no longer in the bundle."
                |> Result.bind (fun index ->
                    let other = index + (if earlier then -1 else 1)

                    if other < 0 || other >= bundle.Mods.Length then
                        Error "This mod is already at the end of the list."
                    else
                        let item, neighbor = bundle.Mods[index], bundle.Mods[other]

                        if
                            item.State = ModState.Installed
                            || neighbor.State = ModState.Installed
                            || item.State = ModState.Installing
                            || neighbor.State = ModState.Installing
                        then
                            Error "Only unfinished mods can change installation order."
                        else
                            Sqlite.execute
                                connection
                                transaction
                                "UPDATE bundle_mods SET position=$other WHERE id=$id; UPDATE bundle_mods SET position=$position WHERE id=$neighbor"
                                [ "$id", box (string itemId)
                                  "$other", box neighbor.Order
                                  "$position", box item.Order
                                  "$neighbor", box (string neighbor.Id) ]

                            BundleRows.touch connection transaction reference.Id

                            BundleRows.snapshot
                                connection
                                transaction
                                reference.WorkspaceId
                                reference.Id)))

    member _.Retry(reference: BundleRef, itemId) =
        task {
            let item =
                db (fun () ->
                    BundleRows.check connection null reference
                    |> Result.bind (fun _ ->
                        BundleRows.item connection null reference.WorkspaceId reference.Id itemId))

            match item with
            | Error error -> return Error error
            | Ok item ->
                match item.State, item.Attempt with
                | ModState.Installed, _ ->
                    return db (fun () -> snapshot reference.WorkspaceId reference.Id)
                | ModState.Installing, _ -> return Error "Wait for this installation to stop."
                | ModState.Failed, Some id ->
                    let! _ = installations.Discard(reference.WorkspaceId, id)

                    return
                        db (fun () ->
                            BundleRows.touch connection null reference.Id
                            snapshot reference.WorkspaceId reference.Id)
                | _ ->
                    let! result =
                        sources.ClearIncomplete(reference.WorkspaceId, reference.Id, item.SourceId)

                    match result with
                    | Error(BundleSourceFailure.Refused error) -> return Error error
                    | Error(BundleSourceFailure.AccessFailed _) ->
                        return Error "The incomplete archive copy could not be deleted."
                    | Ok() -> return db (fun () -> snapshot reference.WorkspaceId reference.Id)
        }

    member _.Delete(reference: BundleRef) =
        task {
            let! result =
                sources.Exclusive(
                    reference.WorkspaceId,
                    reference.Id,
                    fun directory ->
                        let currentBundle =
                            db (fun () ->
                                BundleRows.work connection null reference.WorkspaceId reference.Id
                                |> Result.bind (fun work ->
                                    if work.Revision <> reference.Revision then
                                        Error "The bundle changed. Review its current checklist."
                                    else
                                        snapshot reference.WorkspaceId reference.Id))

                        currentBundle
                        |> Result.bind (fun bundle ->
                            if
                                bundle.Mods
                                |> List.exists (fun item -> item.State = ModState.Installing)
                            then
                                Error
                                    "Cancel the current installation and wait for it to stop first."
                            else
                                for item in bundle.Mods do
                                    match item.State, item.Attempt with
                                    | ModState.Failed, Some id ->
                                        installations.Discard(reference.WorkspaceId, id)
                                        |> wait
                                        |> ignore
                                    | _ -> ()

                                let nodes =
                                    db (fun () -> BundleRows.sources connection null reference.Id)

                                for node in nodes do
                                    ArtifactFiles.remove
                                        directory
                                        (BundleFiles.name node.Id)
                                        node.Identity

                                    db (fun () ->
                                        Sqlite.execute
                                            connection
                                            null
                                            "UPDATE bundle_sources SET identity=NULL,length=NULL,digest=NULL WHERE id=$id"
                                            [ "$id", box (string node.Id) ])

                                db (fun () ->
                                    use transaction =
                                        connection.BeginTransaction(deferred = false)

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

                                Ok())
                )

            match result with
            | Error(BundleSourceFailure.Refused error) -> return Error error
            | Error(BundleSourceFailure.AccessFailed _) ->
                return
                    Error
                        "The temporary files could not be deleted. Try again from the bundle checklist."
            | Ok() ->
                installations.CloseBundleDraft(reference.WorkspaceId, reference.Id)
                return Ok()
        }
