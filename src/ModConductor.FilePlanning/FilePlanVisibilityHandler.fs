namespace ModConductor.FilePlanning

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

type internal FilePlanVisibilityHandler(state: FilePlanSessionState) =
    let repository = state.Repository
    let cache = state.Cache
    let checkedSnapshot id = state.CheckedSnapshot id
    let describe stale snapshot = state.Describe stale snapshot
    let keep fresh snapshot = state.Keep fresh snapshot

    member _.Change(id, copy, hidden, token) =
        task {
            let! found = checkedSnapshot id

            match found with
            | Error error -> return Error error
            | Ok(_, true) -> return Error FilePlanError.Stale
            | Ok(snapshot, false) ->
                match snapshot.Index.CopyTargets.TryFind copy with
                | None -> return Error FilePlanError.InvalidCopy
                | Some target ->
                    let nameProblems =
                        TargetPolicy.problems
                            ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                            copy.Path

                    let denied =
                        hidden
                        && (cache.Stale snapshot
                            || snapshot.Problems.Length <> 0
                            || not nameProblems.IsEmpty)

                    if denied then
                        return Error FilePlanError.Blocked
                    else
                        let! gameCurrent =
                            if not hidden then
                                Task.FromResult(Ok true)
                            else
                                match snapshot.Game with
                                | None -> Task.FromResult(Error FilePlanError.Blocked)
                                | Some game ->
                                    Task.Run((fun () -> GameFiles.current game token), token)

                        match gameCurrent with
                        | Error FilePlanError.Cancelled -> return Error FilePlanError.Cancelled
                        | Error error ->
                            cache.MarkStale snapshot
                            return Error error
                        | Ok false ->
                            cache.MarkStale snapshot
                            return Error FilePlanError.Stale
                        | Ok true ->
                            match Visibility.setHidden copy hidden snapshot.Visibility with
                            | Error _ -> return Error FilePlanError.InvalidCopy
                            | Ok visibility ->
                                token.ThrowIfCancellationRequested()

                                let! changed =
                                    repository.SetHidden(
                                        snapshot.Sources.Stamp,
                                        copy,
                                        hidden,
                                        Visibility.fingerprint snapshot.Visibility,
                                        Visibility.fingerprint visibility
                                    )

                                return
                                    changed
                                    |> Result.map (fun stamp ->
                                        let address =
                                            { Root = stamp.WorkspaceId
                                              Path = target }

                                        let present state =
                                            Visibility.files state
                                            |> Map.tryFind address
                                            |> Option.flatten
                                            |> Option.isSome

                                        let delta =
                                            (if present visibility then 1 else 0)
                                            - (if present snapshot.Visibility then 1 else 0)

                                        let updated =
                                            { snapshot with
                                                Id = Guid.NewGuid()
                                                Sources =
                                                    { snapshot.Sources with
                                                        Stamp = stamp
                                                        Hidden = Visibility.hidden visibility }
                                                Visibility = visibility
                                                Planned = snapshot.Planned + delta }

                                        let summary = keep false updated

                                        { Snapshot = summary
                                          Changed =
                                            if snapshot.Index.Targets.Contains target then
                                                Some(
                                                    FileIndex.node
                                                        updated.Sources
                                                        visibility
                                                        updated.Index
                                                        target
                                                )
                                            else
                                                None })
        }
