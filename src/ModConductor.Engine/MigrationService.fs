namespace ModConductor.Engine

open System
open Grpc.Core
open ModConductor.Migration
open ModConductor.Protocol.V1

module private MigrationWire =
    let private error value =
        let code, detail =
            match value with
            | Error.InvalidSource detail -> MigrationErrorCode.InvalidSource, detail
            | Error.TargetNotEmpty ->
                MigrationErrorCode.TargetNotEmpty, "The current workspace must be empty."
            | Error.UnsafeSource detail -> MigrationErrorCode.UnsafeSource, detail
            | Error.CaseCollision path ->
                MigrationErrorCode.CaseCollision,
                "Two source entries use the same name with different letter case: " + path
            | Error.UnsupportedData detail -> MigrationErrorCode.UnsupportedData, detail
            | Error.SourceChanged ->
                MigrationErrorCode.SourceChanged,
                "The Mod Organizer files changed during migration. No data was migrated."
            | Error.Cancelled -> MigrationErrorCode.Cancelled, "Migration was cancelled."
            | Error.Busy -> MigrationErrorCode.Busy, "Another workspace change is in progress."
            | Error.Unavailable detail -> MigrationErrorCode.Unavailable, detail

        MigrationEvent(Error = MigrationError(Code = code, Detail = detail))

    let progress (value: Progress) =
        MigrationEvent(
            Progress =
                MigrationProgress(
                    Completed = uint32 value.Completed,
                    Total = uint32 value.Total,
                    Message = value.Message
                )
        )

    let result =
        function
        | Ok(value: ModConductor.Migration.Result) ->
            MigrationEvent(
                Result =
                    MigrationResult(
                        WorkspaceId = value.WorkspaceId.ToString("N"),
                        Profiles = uint32 value.Profiles,
                        Mods = uint32 value.Mods,
                        Artifacts = uint32 value.Artifacts
                    )
            )
        | Error value -> error value

type MigrationService(store: IStore) =
    inherit MigrationOperations.MigrationOperationsBase()

    override _.Migrate(request, response, context) =
        task {
            if request.Manager <> MigrationManager.ModOrganizer then
                do!
                    response.WriteAsync(
                        MigrationWire.result (
                            Error(Error.InvalidSource "Choose Mod Organizer as the source manager.")
                        )
                    )
            else
                let mutable writes = System.Threading.Tasks.Task.CompletedTask

                let progress value =
                    writes <-
                        task {
                            do! writes
                            do! response.WriteAsync(MigrationWire.progress value)
                        }

                let parsed =
                    match Guid.TryParse request.WorkspaceId with
                    | true, value when value <> Guid.Empty ->
                        Ok
                            { Request.WorkspaceId = value
                              SourceFolder = request.SourceFolder }
                    | _ -> Error(Error.InvalidSource "The workspace ID is invalid.")

                match parsed with
                | Error error -> do! response.WriteAsync(MigrationWire.result (Error error))
                | Ok value ->
                    let! result =
                        ModOrganizer.migrate store value progress context.CancellationToken

                    do! writes
                    do! response.WriteAsync(MigrationWire.result result)
        }
