namespace ModConductor.Engine

open System
open Grpc.Core
open ModConductor.Migration
open ModConductor.Protocol.V1

module private MigrationWire =
    let private error value =
        let code, detail =
            match value with
            | Error.InvalidSource detail -> MigrateErrorCode.InvalidSource, detail
            | Error.TargetNotEmpty ->
                MigrateErrorCode.TargetNotEmpty,
                "The current workspace must have no profiles, mods, or downloads."
            | Error.UnsafeSource detail -> MigrateErrorCode.UnsafeSource, detail
            | Error.CaseCollision path ->
                MigrateErrorCode.CaseCollision,
                "Two source entries use the same name with different letter case: " + path
            | Error.UnsupportedData detail -> MigrateErrorCode.UnsupportedData, detail
            | Error.SourceChanged ->
                MigrateErrorCode.SourceChanged,
                "The Mod Organizer files changed during migration. No data was migrated."
            | Error.Cancelled -> MigrateErrorCode.Cancelled, "Migration was cancelled."
            | Error.Busy -> MigrateErrorCode.Busy, "Another workspace change is in progress."
            | Error.Unavailable detail -> MigrateErrorCode.Unavailable, detail

        MigrateEvent(Error = MigrateError(Code = code, Detail = detail))

    let progress (value: Progress) =
        MigrateEvent(
            Progress =
                MigrateProgress(
                    Completed = uint32 value.Completed,
                    Total = uint32 value.Total,
                    Message = value.Message
                )
        )

    let result =
        function
        | Ok(value: ModConductor.Migration.Result) ->
            MigrateEvent(
                Result =
                    MigrateResult(
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
            if request.Manager <> Manager.ModOrganizer then
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
