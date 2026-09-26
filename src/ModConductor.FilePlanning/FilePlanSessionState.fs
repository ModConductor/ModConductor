namespace ModConductor.FilePlanning

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

type internal FilePlanSessionState(repository: IFileCandidateRepository, cache: SnapshotCache) =
    member _.Repository = repository
    member _.Cache = cache

    member _.CheckedSnapshot id =
        task {
            match cache.Find id with
            | None -> return Error FilePlanError.Expired
            | Some snapshot ->
                let! current = repository.Current snapshot.Sources.Stamp
                return current |> Result.map (fun current -> snapshot, not current)
        }

    member _.Describe stale snapshot =
        PlanSnapshot.summary (stale || cache.Stale snapshot) snapshot

    member this.Keep fresh snapshot =
        cache.Put(snapshot, fresh)
        this.Describe false snapshot
