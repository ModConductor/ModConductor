namespace ModConductor.Nexus

open System
open System.Collections.Generic
open System.Threading.Tasks

[<Struct>]
type NexusIdentity = { Game: string; Mod: int64 }

type NexusMetadataFile =
    { File: NexusFile
      CategoryId: int
      Uploaded: DateTimeOffset option }

type NexusFileUpdate = { Previous: int64; Next: int64 }

type NexusMetadata =
    { Identity: NexusIdentity
      Name: string
      Summary: string
      Version: string
      Author: string
      Uploader: string
      Category: (int64 * string) option
      Modified: DateTimeOffset option
      Available: bool
      AllowsRating: bool
      Files: NexusMetadataFile list
      Updates: NexusFileUpdate list }

[<RequireQualifiedAccess>]
type NexusEndorsement =
    | Undecided
    | Abstained
    | Endorsed

[<RequireQualifiedAccess>]
type NexusInteraction =
    | Track
    | Untrack
    | Endorse
    | Abstain

type NexusInteractions =
    { Revision: int64
      Subject: string option
      AccountName: string option
      Tracking: bool option
      Endorsement: NexusEndorsement option
      Busy: bool
      Problem: NexusProblem option }

[<RequireQualifiedAccess>]
type NexusFreshness =
    | Unavailable
    | Stale
    | Current

type InstalledNexusFile =
    { Id: int64
      Version: string
      Manual: bool }

type NexusCategoryMapping =
    { ProviderId: int64
      CategoryId: Guid
      Label: string }

type ModNexusDetails =
    { Workspace: Guid
      Mod: Guid
      Name: string
      ModRevision: int64
      Version: Guid option
      LinkRevision: int64
      Identity: NexusIdentity option
      Installed: InstalledNexusFile option
      Snapshot: NexusMetadata option
      Freshness: NexusFreshness
      Checked: DateTimeOffset option
      Problem: string option
      CategoryMapping: NexusCategoryMapping option }

type INexusMetadataStore =
    abstract Read: Guid * Guid -> Task<Result<ModNexusDetails, NexusProblem>>

    abstract Link:
        ModNexusDetails * NexusMetadata option * NexusFile option ->
            Task<Result<ModNexusDetails, NexusProblem>>

    abstract Save:
        ModNexusDetails * Result<NexusMetadata, NexusProblem> ->
            Task<Result<ModNexusDetails, NexusProblem>>

    abstract MapCategory: ModNexusDetails * Guid -> Task<Result<ModNexusDetails, NexusProblem>>

module NexusUpdates =
    let candidates (installed: InstalledNexusFile option) (metadata: NexusMetadata) =
        match installed with
        | None -> []
        | Some file ->
            let next = Dictionary<int64, ResizeArray<int64>>()

            for edge in metadata.Updates do
                if not (next.ContainsKey edge.Previous) then
                    next[edge.Previous] <- ResizeArray()

                next[edge.Previous].Add edge.Next

            let visited, active, leaves = HashSet<int64>(), HashSet<int64>(), HashSet<int64>()
            let mutable invalid = false
            let pending = Stack<int64 * bool>()
            pending.Push(file.Id, false)

            while pending.Count > 0 do
                let id, leaving = pending.Pop()

                if leaving then
                    active.Remove id |> ignore
                elif active.Contains id then
                    invalid <- true
                elif visited.Add id then
                    active.Add id |> ignore
                    pending.Push(id, true)

                    match next.TryGetValue id with
                    | true, children ->
                        for child in children do
                            pending.Push(child, false)
                    | _ ->
                        if id <> file.Id then
                            leaves.Add id |> ignore

            if invalid then
                []
            else
                metadata.Files
                |> List.filter (fun entry ->
                    leaves.Contains entry.File.Id && entry.CategoryId >= 1 && entry.CategoryId <= 3)
                |> List.sortByDescending (fun entry -> entry.Uploaded, entry.File.Id)
