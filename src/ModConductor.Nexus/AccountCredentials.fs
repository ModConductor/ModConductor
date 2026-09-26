namespace ModConductor.Nexus

open System
open System.Security.Cryptography
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.Credentials

type internal AccountCredentials
    (
        credentials: CredentialSession,
        transport: NexusTransport,
        commit: SemaphoreSlim,
        requireCurrent: int64 -> CancellationToken -> unit,
        boundSubject: unit -> string option,
        unavailable: unit -> bool,
        acceptKey: int64 -> Account -> string -> CancellationToken -> unit
    ) =
    member _.ReadSaved(token: CancellationToken) =
        task {
            let! read = credentials.Read token

            match read with
            | Ok None -> return Error NexusProblem.SignInRequired
            | Error error -> return Error(NexusProblem.Storage error)
            | Ok(Some bytes) ->
                try
                    use document = JsonDocument.Parse(ReadOnlyMemory bytes)
                    return Ok(NexusJson.saved document.RootElement)
                finally
                    CryptographicOperations.ZeroMemory bytes
        }

    member _.RestoreKey(savedSubject: string, key: string, epoch, token) =
        task {
            let! response = transport.ValidatePersonalApiKey(key, token)

            match response with
            | Error error -> return Error error
            | Ok response ->
                use response = response
                let identity = NexusJson.apiKeyAccount response.RootElement

                if identity.Subject <> savedSubject then
                    return Error NexusProblem.AccountChanged
                else
                    acceptKey epoch identity key token
                    return Ok(NexusAuthorization.PersonalApiKey key)
        }

    member _.Submit(key: string, epoch, token: CancellationToken) =
        task {
            if String.IsNullOrWhiteSpace key then
                return Error NexusProblem.InvalidApiKey
            elif unavailable () then
                return Error NexusProblem.SignInRequired
            else
                let! response = transport.ValidatePersonalApiKey(key, token)

                match response with
                | Error error -> return Error error
                | Ok response ->
                    use response = response
                    let identity = NexusJson.apiKeyAccount response.RootElement

                    if boundSubject () |> Option.exists ((<>) identity.Subject) then
                        return Error NexusProblem.AccountChanged
                    else
                        let packet = NexusJson.writeSavedApiKey identity.Subject key

                        try
                            do! commit.WaitAsync token

                            try
                                requireCurrent epoch token

                                if boundSubject () |> Option.exists ((<>) identity.Subject) then
                                    return Error NexusProblem.AccountChanged
                                else
                                    let! saved = credentials.Save(packet, token)

                                    match saved with
                                    | Error error -> return Error(NexusProblem.Storage error)
                                    | Ok() ->
                                        acceptKey epoch identity key token
                                        return Ok()
                            finally
                                commit.Release() |> ignore
                        finally
                            CryptographicOperations.ZeroMemory packet
        }
