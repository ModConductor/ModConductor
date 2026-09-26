namespace ModConductor.FilePlanning

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

type internal FilePlanQueryHandler(state: FilePlanSessionState) =
    let repository = state.Repository
    let cache = state.Cache
    let checkedSnapshot id = state.CheckedSnapshot id
    let describe stale snapshot = state.Describe stale snapshot

    member _.Read id =
        task {
            let! found = checkedSnapshot id
            return found |> Result.map (fun (snapshot, stale) -> describe stale snapshot)
        }

    member _.Children(id, parent, query, cursor) =
        task {
            let! found = checkedSnapshot id

            return
                found
                |> Result.bind (fun (snapshot, stale) ->
                    if stale then
                        Error FilePlanError.Stale
                    else
                        PlanSnapshotPaging.children parent query cursor snapshot
                        |> Result.map (fun (nodes, next) ->
                            { Snapshot = describe false snapshot
                              Nodes = nodes
                              Next = next }))
        }

    member _.Problems(id, cursor) =
        task {
            match cache.Find id with
            | None -> return Error FilePlanError.Expired
            | Some snapshot -> return PlanSnapshotPaging.problems cursor snapshot
        }

    member _.DiagnosticProblems id =
        task {
            let! found = checkedSnapshot id

            return
                found
                |> Result.bind (fun (snapshot, stale) ->
                    if stale then
                        Error FilePlanError.Stale
                    else
                        Ok(PlanSnapshotPaging.diagnosticProblems snapshot))
        }

    member _.Inspect(id, target, cursor) =
        task {
            let! found = checkedSnapshot id

            return
                found
                |> Result.bind (fun (snapshot, stale) ->
                    InspectionProjection.inspect target cursor snapshot
                    |> Result.map (fun (copies, next) ->
                        { Snapshot = describe stale snapshot
                          Writable = snapshot.Index.Writable.Contains target
                          Target = target
                          Next = next
                          FocusedCopy = None
                          Copies =
                            copies
                            |> List.map (fun copy ->
                                { copy with
                                    CanHide =
                                        copy.CanHide && not stale && not (cache.Stale snapshot)
                                    CanUnhide = copy.CanUnhide && not stale }) }))
        }

    member _.InspectCopy(id, copy) =
        task {
            let! found = checkedSnapshot id

            match found with
            | Error error -> return Error error
            | Ok(snapshot, stale) ->
                let! saved = repository.Copy(snapshot.Sources.Stamp.WorkspaceId, copy)

                return
                    saved
                    |> Result.bind (fun saved ->
                        match saved.Current, snapshot.Index.CopyTargets.TryFind copy with
                        | true, Some target ->
                            InspectionProjection.inspect target None snapshot
                            |> Result.map (fun (copies, next) ->
                                { Snapshot = describe stale snapshot
                                  Writable = snapshot.Index.Writable.Contains target
                                  Target = target
                                  Next = next
                                  FocusedCopy =
                                    let row =
                                        InspectionProjection.inspectCopy target copy snapshot

                                    Some
                                        { row with
                                            CanHide =
                                                row.CanHide
                                                && not stale
                                                && not (cache.Stale snapshot)
                                            CanUnhide = row.CanUnhide && not stale }
                                  Copies =
                                    copies
                                    |> List.map (fun row ->
                                        { row with
                                            CanHide =
                                                row.CanHide
                                                && not stale
                                                && not (cache.Stale snapshot)
                                            CanUnhide = row.CanUnhide && not stale }) })
                        | _ ->
                            Ok
                                { Snapshot = describe stale snapshot
                                  Writable = false
                                  Target = copy.Path
                                  Next = None
                                  FocusedCopy = None
                                  Copies =
                                    [ { Source =
                                          FilePreviewSource.ManagedCopy
                                              { Copy = copy
                                                SourcePath = copy.Path
                                                Target = copy.Path
                                                PayloadId = saved.Entry.Payload.Id
                                                Length = saved.Entry.Payload.Length
                                                Sha256 = saved.Entry.Payload.Sha256
                                                ModRevision =
                                                  snapshot.Index.Labels
                                                  |> Map.tryFind copy.ModId
                                                  |> Option.map _.Revision
                                                  |> Option.defaultValue 0L }
                                        Standing =
                                          if saved.Current then
                                              FileSourceStanding.Unavailable
                                          else
                                              FileSourceStanding.Previous
                                        Copy = Some copy
                                        SourcePath = copy.Path
                                        Name = saved.Name
                                        VersionLabel = saved.VersionLabel
                                        Priority = None
                                        Enabled = false
                                        Hidden = saved.Hidden
                                        Winner = false
                                        Historical = not saved.Current
                                        Length = saved.Entry.Payload.Length
                                        Sha256 = Some saved.Entry.Payload.Sha256
                                        CanHide = false
                                        CanUnhide = false } ] })
                    |> Result.bind InspectionProjection.bounded
        }

    member _.History(id, copy, after) =
        task {
            match cache.Find id with
            | None -> return Error FilePlanError.Expired
            | Some snapshot ->
                let! changes = repository.History(snapshot.Sources.Stamp.WorkspaceId, copy, after)

                return changes |> Result.bind PlanSnapshotPaging.historyPage
        }
