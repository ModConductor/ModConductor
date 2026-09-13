namespace ModConductor.Engine

open Grpc.Core
open ModConductor.Credentials
open ModConductor.Protocol.V1

module private CredentialWire =
    let problem =
        function
        | None -> CredentialStorageProblem.None
        | Some StorageProblem.Unavailable -> CredentialStorageProblem.Unavailable
        | Some StorageProblem.Locked -> CredentialStorageProblem.Locked
        | Some StorageProblem.Denied -> CredentialStorageProblem.Denied
        | Some StorageProblem.TimedOut -> CredentialStorageProblem.TimedOut
        | Some StorageProblem.Cancelled -> CredentialStorageProblem.Cancelled
        | Some StorageProblem.TooLarge -> CredentialStorageProblem.TooLarge
        | Some StorageProblem.Failed -> CredentialStorageProblem.Failed

    let status (value: CredentialStatus) =
        CredentialStorageStatus(
            Storage =
                (match value.Storage with
                 | StorageKind.SecretService -> CredentialStorageKind.SecretService
                 | StorageKind.CredentialManager -> CredentialStorageKind.Windows
                 | StorageKind.Unavailable -> CredentialStorageKind.Unavailable),
            Mode =
                (match value.Mode with
                 | StorageMode.Secure -> CredentialStorageMode.Secure
                 | StorageMode.SessionOnly -> CredentialStorageMode.SessionOnly),
            Saved =
                (match value.Saved with
                 | SavedPresence.Present -> CredentialPresence.Present
                 | SavedPresence.Absent -> CredentialPresence.Absent
                 | SavedPresence.Unknown -> CredentialPresence.Unknown),
            HasSession = value.HasSession,
            Problem = problem value.Problem,
            RemovalProblem = problem value.RemovalProblem,
            DiagnosticReport = CredentialDiagnostics.report value
        )

type CredentialService(session: CredentialSession) =
    inherit CredentialStorage.CredentialStorageBase()

    override _.ReadCredentialStatus(_, context) =
        task {
            let! result = session.Status context.CancellationToken
            return CredentialWire.status result
        }

    override _.SetCredentialStorageMode(request, context) =
        task {
            let mode =
                match request.Mode with
                | CredentialStorageMode.Secure -> StorageMode.Secure
                | CredentialStorageMode.SessionOnly -> StorageMode.SessionOnly
                | _ ->
                    raise (
                        RpcException(
                            Status(
                                StatusCode.InvalidArgument,
                                "Choose where to keep new sign-in details."
                            )
                        )
                    )

            let! result = session.SetMode(mode, context.CancellationToken)
            return CredentialWire.status result
        }

    override _.RemoveSavedCredentials(_, context) =
        task {
            let! result = session.Remove context.CancellationToken
            return CredentialWire.status result
        }
