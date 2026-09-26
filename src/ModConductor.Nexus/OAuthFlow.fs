namespace ModConductor.Nexus

open System
open System.Security.Cryptography
open System.Text
open System.Threading
open System.Threading.Tasks

type internal OAuthFlow
    (
        handoff: IOAuthHandoff,
        transport: NexusTransport,
        publish:
            int64
                -> NexusJson.Tokens
                -> string option
                -> CancellationToken
                -> Task<Result<unit, NexusProblem>>,
        boundSubject: unit -> string option
    ) =
    let random () =
        Convert
            .ToBase64String(RandomNumberGenerator.GetBytes 32)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_')

    member _.Execute(config: NexusRegistration, epoch: int64, token: CancellationToken) =
        task {
            let verifier = random ()
            let state = random ()

            let challenge =
                Convert
                    .ToBase64String(SHA256.HashData(Encoding.ASCII.GetBytes verifier))
                    .TrimEnd('=')
                    .Replace('+', '-')
                    .Replace('/', '_')

            let! listener = handoff.Listen(config, token)

            try
                let redirect = listener.Redirect

                if
                    redirect.Scheme <> "http"
                    || redirect.Host <> "127.0.0.1"
                    || redirect.AbsolutePath <> config.RedirectPath
                    || (config.RedirectPort <> 0 && redirect.Port <> config.RedirectPort)
                then
                    return Error NexusProblem.InvalidCallback
                else
                    let query =
                        [ "response_type", "code"
                          "client_id", config.ClientId
                          "redirect_uri", redirect.AbsoluteUri
                          "scope", String.concat " " config.Scopes
                          "state", state
                          "code_challenge", challenge
                          "code_challenge_method", "S256" ]
                        |> List.map (fun (key, value) ->
                            Uri.EscapeDataString key + "=" + Uri.EscapeDataString value)
                        |> String.concat "&"

                    let uri = UriBuilder config.Authorize
                    uri.Query <- query
                    do! handoff.Open(uri.Uri, token)
                    let! callback = listener.Wait token

                    match callback with
                    | Error error -> return Error error
                    | Ok callback when
                        callback.State <> state
                        || String.IsNullOrWhiteSpace callback.Code
                        || (callback.Issuer |> Option.exists ((<>) config.Issuer.AbsoluteUri))
                        ->
                        return Error NexusProblem.InvalidCallback
                    | Ok callback ->
                        let! reply =
                            transport.Token(
                                config.Token,
                                [ "grant_type", "authorization_code"
                                  "code", callback.Code
                                  "client_id", config.ClientId
                                  "redirect_uri", redirect.AbsoluteUri
                                  "code_verifier", verifier ],
                                token
                            )

                        match reply with
                        | Error error -> return Error error
                        | Ok reply ->
                            use reply = reply
                            let value = NexusJson.tokens None reply.RootElement
                            return! publish epoch value (boundSubject ()) token
            finally
                listener.DisposeAsync().AsTask().GetAwaiter().GetResult()
        }
