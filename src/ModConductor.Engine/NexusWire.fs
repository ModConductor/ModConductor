namespace ModConductor.Engine

open ModConductor.Nexus
open ModConductor.Protocol.V1

module internal NexusWire =
    let failure problem =
        let code =
            match problem with
            | NexusProblem.NotConfigured -> "not_configured"
            | NexusProblem.SignInRequired -> "sign_in_required"
            | NexusProblem.Cancelled -> "cancelled"
            | NexusProblem.InvalidCallback -> "invalid_callback"
            | NexusProblem.AccountChanged -> "account_changed"
            | NexusProblem.DownloadLinkNeeded -> "download_link_needed"
            | NexusProblem.DownloadAccount -> "download_account"
            | NexusProblem.Storage _ -> "storage"
            | NexusProblem.Entitlement -> "entitlement"
            | NexusProblem.Forbidden -> "forbidden"
            | NexusProblem.NotFound -> "not_found"
            | NexusProblem.RateLimited _ -> "rate_limited"
            | NexusProblem.TimedOut -> "timed_out"
            | NexusProblem.Offline -> "offline"
            | NexusProblem.InvalidResponse -> "invalid_response"
            | NexusProblem.Failed -> "failed"

        let value = NexusFailure(Code = code, Message = NexusProblem.message problem)

        match problem with
        | NexusProblem.RateLimited at -> value.RetryAtUnixMs <- at.ToUnixTimeMilliseconds()
        | _ -> ()

        value

    let status (source: NexusStatus) =
        let value =
            NexusAccountStatus(Configured = source.Configured, Waiting = source.Waiting)

        source.Account
        |> Option.iter (fun account ->
            value.AccountName <- account.Name
            account.Premium |> Option.iter (fun premium -> value.Premium <- premium))

        source.Problem |> Option.iter (fun problem -> value.Failure <- failure problem)
        value

    let file (source: NexusFile) =
        let value =
            NexusFileInfo(
                Id = source.Id,
                Name = source.Name,
                Version = source.Version,
                Category = source.Category,
                Description = source.Description
            )

        source.Bytes |> Option.iter (fun bytes -> value.Bytes <- bytes)
        value

    let modInfo (source: NexusMod) =
        let value =
            NexusModInfo(Id = source.Id, Name = source.Name, Summary = source.Summary)

        value.Files.AddRange(source.Files |> Seq.map file)
        value
