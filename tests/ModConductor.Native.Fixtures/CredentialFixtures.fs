namespace ModConductor.Native.Fixtures

open System
open System.Security.Cryptography
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.Credentials

module CredentialFixtures =
    let private token = CancellationToken.None
    let private wait (task: Task<'a>) = task.GetAwaiter().GetResult()

    let private check condition message =
        if not condition then
            failwith message

    let private synthetic () = [| 0uy; 1uy; 2uy; 255uy; 0uy; 91uy |]

    let private value =
        function
        | Ok value -> value
        | Error _ -> failwith "Synthetic credential operation failed."

    let private compare (expected: byte[]) (result: Result<byte[] option, StorageProblem>) =
        match value result with
        | None -> failwith "Synthetic credential was absent."
        | Some actual ->
            try
                check (actual = expected) "Synthetic binary credential differed."
            finally
                CryptographicOperations.ZeroMemory actual

    let worker operation =
        use session = new CredentialSession(CredentialStore.create ())

        match operation with
        | "seed" -> session.Save(synthetic (), token) |> wait |> value
        | "read" -> session.Read token |> wait |> compare (synthetic ())
        | "absent" ->
            check
                ((session.Status token |> wait).Saved = SavedPresence.Absent)
                "Deleted credential still exists."
        | "locked" ->
            let status = session.Status token |> wait

            check
                (status.Saved = SavedPresence.Present
                 && status.Problem = Some StorageProblem.Locked)
                "Locked metadata was not reported."

            let removal = session.Remove token |> wait

            check
                (removal.Saved = SavedPresence.Present
                 && removal.RemovalProblem = Some StorageProblem.Locked)
                "Locked removal claimed success."
        | "unavailable" ->
            let status = session.Status token |> wait

            check
                (status.Saved = SavedPresence.Unknown
                 && status.Problem = Some StorageProblem.Unavailable)
                "Absent private store was reported available."
        | _ -> invalidArg "operation" "Select a credential fixture operation."

        Console.WriteLine("{\"passed\":true}")

    let observe (writer: Utf8JsonWriter) =
        let mutable checks = 0

        let observed (name: string) =
            writer.WriteBoolean(name, true)
            checks <- checks + 1

        let store = CredentialStore.create ()
        use session = new CredentialSession(store)
        session.Remove token |> wait |> ignore
        let original = synthetic ()
        session.Save(original, token) |> wait |> value
        original[0] <- 80uy
        session.Read token |> wait |> compare (synthetic ())
        observed "secureBinaryValueIsOwnedByStore"

        session.SetMode(StorageMode.SessionOnly, token) |> wait |> ignore
        let transient = [| 19uy; 0uy; 91uy |]
        session.Save(transient, token) |> wait |> value
        transient[0] <- 42uy
        session.Read token |> wait |> compare [| 19uy; 0uy; 91uy |]
        use other = new CredentialSession(store)
        other.Read token |> wait |> compare (synthetic ())

        check
            ((other.Status token |> wait).Mode = StorageMode.Secure)
            "New owner inherited session-only mode."

        observed "explicitMemoryDoesNotReplaceSavedValueOrSurviveNewOwner"

        session.SetMode(StorageMode.Secure, token) |> wait |> ignore
        session.Read token |> wait |> compare [| 19uy; 0uy; 91uy |]
        other.Read token |> wait |> compare (synthetic ())
        observed "changingModeDoesNotMigrateExistingMemory"

        let removal = session.Remove token |> wait

        check
            (not removal.HasSession
             && removal.Saved = SavedPresence.Absent
             && removal.RemovalProblem.IsNone)
            "Removal left owned credentials."

        observed "removalClearsMemoryAndSavedValue"

        let contaminated =
            "synthetic-token-MC038 https://invalid.local/file?token=synthetic-signed-value"

        let failureStore =
            { new ICredentialStore with
                member _.Kind = StorageKind.SecretService
                member _.Inspect t = store.Inspect t

                member _.Save(_, _) =
                    raise (InvalidOperationException contaminated)

                member _.Read t = store.Read t

                member _.Delete _ =
                    raise (InvalidOperationException contaminated) }

        use failed = new CredentialSession(failureStore)

        check
            (failed.Save(synthetic (), token) |> wait = Error StorageProblem.Failed)
            "Failed secure save was not reported."

        let status = failed.Status token |> wait

        check
            (not status.HasSession && status.Saved = SavedPresence.Absent)
            "Failed secure save silently retained candidate."

        observed "secureFailureDoesNotFallBackToMemory"
        session.Save(synthetic (), token) |> wait |> value
        failed.SetMode(StorageMode.SessionOnly, token) |> wait |> ignore
        failed.Save([| 72uy |], token) |> wait |> value
        let status = failed.Remove token |> wait

        check
            (status.Saved = SavedPresence.Present
             && not status.HasSession
             && status.RemovalProblem = Some StorageProblem.Failed)
            "Failed deletion lost truthful saved presence."

        let report = CredentialDiagnostics.report status

        check
            (not (report.Contains "synthetic")
             && not (report.Contains "https:")
             && not (report.Contains "token="))
            "Credential diagnostic leaked dependency detail."

        observed "failedRemovalClearsMemoryButRetainsTruthfulSavedStateAndSafeReport"
        session.Remove token |> wait |> ignore

        let allFailures =
            { new ICredentialStore with
                member _.Kind = StorageKind.SecretService

                member _.Inspect _ =
                    raise (InvalidOperationException contaminated)

                member _.Save(_, _) =
                    raise (InvalidOperationException contaminated)

                member _.Read _ =
                    raise (InvalidOperationException contaminated)

                member _.Delete _ =
                    raise (InvalidOperationException contaminated) }

        use unavailable = new CredentialSession(allFailures)
        let status = unavailable.Status token |> wait

        check
            (status.Saved = SavedPresence.Unknown
             && status.Problem = Some StorageProblem.Failed)
            "Failed status implied saved absence."

        check
            (not ((CredentialDiagnostics.report status).Contains "synthetic"))
            "Status report leaked raw failure."

        observed "statusFailureUsesUnknownPresenceAndSafeCategory"
        unavailable.SetMode(StorageMode.SessionOnly, token) |> wait |> ignore
        unavailable.Save(synthetic (), token) |> wait |> value
        unavailable.Read token |> wait |> compare (synthetic ())
        (unavailable :> IDisposable).Dispose()
        let mutable closed = false

        try
            unavailable.Read token |> wait |> ignore
        with :? ObjectDisposedException ->
            closed <- true

        check closed "Disposed owner remained usable."
        observed "explicitSessionWorksWithoutStoreAndClosesWithOwner"
        writer.WriteNumber("passed", checks)
