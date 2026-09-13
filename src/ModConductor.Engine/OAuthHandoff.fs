namespace ModConductor.Engine

open System
open System.Diagnostics
open System.Net
open System.Threading
open System.Threading.Tasks
open Microsoft.AspNetCore.Builder
open Microsoft.AspNetCore.Hosting
open Microsoft.AspNetCore.Hosting.Server
open Microsoft.AspNetCore.Hosting.Server.Features
open Microsoft.AspNetCore.Http
open Microsoft.AspNetCore.Server.Kestrel.Core
open Microsoft.Extensions.DependencyInjection
open Microsoft.Extensions.Logging
open ModConductor.Nexus

type OAuthHandoff(openBrowser: Uri * CancellationToken -> Task) =
    static member SystemBrowser(uri: Uri, token: CancellationToken) : Task =
        task {
            token.ThrowIfCancellationRequested()

            use browser =
                Process.Start(ProcessStartInfo(uri.AbsoluteUri, UseShellExecute = true))

            ()
        }

    interface IOAuthHandoff with
        member _.Open(uri, token) = openBrowser (uri, token)

        member _.Listen(config, token) =
            task {
                let builder =
                    WebApplication.CreateSlimBuilder(
                        WebApplicationOptions(
                            Args = [||],
                            ContentRootPath = AppContext.BaseDirectory
                        )
                    )

                builder.Logging.ClearProviders() |> ignore

                builder.WebHost.ConfigureKestrel(fun options ->
                    options.Listen(
                        IPAddress.Loopback,
                        config.RedirectPort,
                        fun endpoint -> endpoint.Protocols <- HttpProtocols.Http1
                    ))
                |> ignore

                let app = builder.Build()

                let completion =
                    TaskCompletionSource<Result<OAuthCallback, NexusProblem>>(
                        TaskCreationOptions.RunContinuationsAsynchronously
                    )

                let mutable redirect: Uri option = None

                app.Run(
                    RequestDelegate(fun context ->
                        task {
                            let request = context.Request

                            let valid =
                                redirect
                                |> Option.exists (fun uri ->
                                    request.Method = "GET"
                                    && request.Host.Value = uri.Authority
                                    && request.Path.Value = uri.AbsolutePath)

                            let one name =
                                match request.Query.TryGetValue name with
                                | true, value when
                                    value.Count = 1 && not (String.IsNullOrWhiteSpace value[0])
                                    ->
                                    Some value[0]
                                | _ -> None

                            if not valid then
                                context.Response.StatusCode <- 404
                            else
                                let fields =
                                    request.Query.Keys
                                    |> Seq.forall (fun key ->
                                        List.contains
                                            key
                                            [ "code"
                                              "state"
                                              "iss"
                                              "error"
                                              "error_description" ])

                                let result =
                                    match one "code", one "state" with
                                    | Some code, Some state when
                                        fields
                                        && not (request.Query.ContainsKey "error")
                                        && (not (request.Query.ContainsKey "iss")
                                            || (one "iss").IsSome)
                                        ->
                                        Ok
                                            { Code = code
                                              State = state
                                              Issuer = one "iss" }
                                    | _ -> Error NexusProblem.InvalidCallback

                                completion.TrySetResult result |> ignore
                                context.Response.ContentType <- "text/plain; charset=utf-8"
                                context.Response.Headers.CacheControl <- "no-store"

                                do!
                                    context.Response.WriteAsync(
                                        "Return to Mod Conductor to check sign-in."
                                    )
                        })
                )

                try
                    do! app.StartAsync token

                    let addresses =
                        app.Services
                            .GetRequiredService<IServer>()
                            .Features.Get<IServerAddressesFeature>()
                            .Addresses

                    let address = Uri(Seq.exactlyOne addresses)
                    let callback = Uri(address, config.RedirectPath)
                    redirect <- Some callback

                    return
                        { new IOAuthListener with
                            member _.Redirect = callback
                            member _.Wait token = completion.Task.WaitAsync token

                            member _.DisposeAsync() =
                                ValueTask(
                                    task {
                                        do! app.StopAsync()
                                        do! app.DisposeAsync().AsTask()
                                    }
                                ) }
                with error ->
                    do! app.DisposeAsync().AsTask()
                    return raise error
            }
