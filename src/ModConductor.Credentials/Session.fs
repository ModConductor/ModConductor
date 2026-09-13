namespace ModConductor.Credentials

open System
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks

module CredentialStore =
    let create () : ICredentialStore =
        if OperatingSystem.IsLinux() then
            new SecretServiceStore()
        elif OperatingSystem.IsWindows() then
            new WindowsCredentialStore()
        else
            { new ICredentialStore with
                member _.Kind = StorageKind.Unavailable

                member _.Inspect _ =
                    { Saved = SavedPresence.Unknown
                      Problem = Some StorageProblem.Unavailable }

                member _.Save(_, _) = Error StorageProblem.Unavailable
                member _.Read _ = Error StorageProblem.Unavailable
                member _.Delete _ = Error StorageProblem.Unavailable }

/// Owns only this engine's mode and memory. Saved presence does not establish authentication.
type CredentialSession(store: ICredentialStore) =
    let gate = obj ()
    let mutable disposed = false
    let mutable mode = StorageMode.Secure
    let mutable memory: byte[] option = None
    let mutable removalProblem = None

    let clear () =
        memory |> Option.iter (fun bytes -> CryptographicOperations.ZeroMemory bytes)
        memory <- None

    let safe action =
        try
            action ()
        with
        | :? OperationCanceledException -> Error StorageProblem.Cancelled
        | :? DllNotFoundException
        | :? EntryPointNotFoundException -> Error StorageProblem.Unavailable
        | _ -> Error StorageProblem.Failed

    let inspect token normalize =
        let status =
            match safe (fun () -> Ok(store.Inspect token)) with
            | Ok status -> status
            | Error problem ->
                { Saved = SavedPresence.Unknown
                  Problem = Some problem }

        { Storage = store.Kind
          Mode = mode
          Saved = status.Saved
          HasSession = memory.IsSome
          Problem = Option.map normalize status.Problem
          RemovalProblem = removalProblem }

    let run
        (token: CancellationToken)
        (action: CancellationToken -> (StorageProblem -> StorageProblem) -> 'a)
        : Task<'a> =
        Task.Run<'a>(fun () ->
            lock gate (fun () ->
                ObjectDisposedException.ThrowIf(disposed, typeof<CredentialSession>)
                use timeout = CancellationTokenSource.CreateLinkedTokenSource token
                timeout.CancelAfter(TimeSpan.FromSeconds 15.0)

                let normalize problem =
                    if
                        problem = StorageProblem.Cancelled
                        && timeout.IsCancellationRequested
                        && not token.IsCancellationRequested
                    then
                        StorageProblem.TimedOut
                    else
                        problem

                action timeout.Token normalize))

    member _.Status(token) = run token inspect

    member _.SetMode(value, token) =
        run token (fun token normalize ->
            mode <- value
            inspect token normalize)

    /// Copies the caller's value; the caller must clear its own buffer after completion.
    member _.Save(value: byte[], token) =
        let candidate = Array.copy value

        task {
            try
                return!
                    run token (fun token normalize ->
                        safe (fun () ->
                            token.ThrowIfCancellationRequested()

                            match mode with
                            | StorageMode.SessionOnly ->
                                clear ()
                                memory <- Some(Array.copy candidate)
                                Ok()
                            | StorageMode.Secure ->
                                let result = store.Save(candidate, token)

                                if Result.isOk result then
                                    clear ()

                                result)
                        |> Result.mapError normalize)
            finally
                CryptographicOperations.ZeroMemory candidate
        }

    /// The trusted engine consumer owns and clears the returned buffer; there is no read RPC.
    member _.Read(token) =
        run token (fun token normalize ->
            match memory with
            | Some value -> Ok(Some(Array.copy value))
            | None -> safe (fun () -> store.Read token) |> Result.mapError normalize)

    member _.Remove(token) =
        run token (fun token normalize ->
            clear ()
            let result = safe (fun () -> store.Delete token) |> Result.mapError normalize

            removalProblem <-
                match result with
                | Ok() -> None
                | Error problem -> Some problem

            inspect token normalize)

    interface IDisposable with
        member _.Dispose() =
            lock gate (fun () ->
                disposed <- true
                clear ())
