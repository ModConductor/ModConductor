namespace ModConductor.Nexus

open System.Collections.Generic

type internal InteractionMemory() =
    let entries = Dictionary<string * NexusIdentity, NexusInteractions>()
    let mutable revision = 0L

    let next () =
        revision <- revision + 1L
        revision

    let unknown subject =
        { Revision = next ()
          Subject = subject
          AccountName = None
          Tracking = None
          Endorsement = None
          Busy = false
          Problem = None }

    member _.Get(subject, identity) =
        match subject with
        | None ->
            { Revision = 0L
              Subject = None
              AccountName = None
              Tracking = None
              Endorsement = None
              Busy = false
              Problem = None }
        | Some account ->
            let key = account, identity

            match entries.TryGetValue key with
            | true, value -> value
            | _ ->
                if entries.Count >= 128 then
                    entries
                    |> Seq.tryFind (fun entry -> not entry.Value.Busy)
                    |> Option.iter (fun entry -> entries.Remove entry.Key |> ignore)

                if entries.Count >= 128 then
                    raise (NexusException NexusProblem.InteractionBusy)

                let value = unknown subject
                entries[key] <- value
                value

    member this.Begin(subject, identity, expected) =
        let current = this.Get(Some subject, identity)

        if current.Busy then
            Error NexusProblem.InteractionBusy
        elif expected |> Option.exists ((<>) current.Revision) then
            Error NexusProblem.InteractionUnknown
        else
            let value =
                { current with
                    Revision = next ()
                    Busy = true
                    Problem = None }

            entries[(subject, identity)] <- value
            Ok value

    member _.Finish(identity, started: NexusInteractions, tracking, endorsement, problem) =
        match started.Subject with
        | None -> ()
        | Some subject ->
            match entries.TryGetValue((subject, identity)) with
            | true, current when current.Revision = started.Revision ->
                entries[(subject, identity)] <-
                    { current with
                        Revision = next ()
                        Busy = false
                        Tracking = tracking
                        Endorsement = endorsement
                        Problem = problem }
            | _ -> ()

    member _.Forget(identity) =
        for key in entries.Keys |> Seq.filter (fun (_, value) -> value = identity) |> Seq.toArray do
            entries.Remove key |> ignore

    member _.Clear() = entries.Clear()
