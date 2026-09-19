namespace ModConductor.Engine

open System
open Grpc.Core
open ModConductor.Migration
open ModConductor.Protocol.V1

module private MigrationWire =
    let error value =
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
                "The source files changed during migration. No data was migrated."
            | Error.Cancelled -> MigrationErrorCode.Cancelled, "Migration was cancelled."
            | Error.Busy -> MigrationErrorCode.Busy, "Another workspace change is in progress."
            | Error.Unavailable detail -> MigrationErrorCode.Unavailable, detail

        MigrationError(Code = code, Detail = detail)

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
        | Error value -> MigrationEvent(Error = error value)

type MigrationService(store: IStore) =
    inherit MigrationOperations.MigrationOperationsBase()

    override _.Profiles(request, _) =
        task {
            let response = ProfileList()

            if request.Manager <> MigrationManager.Vortex then
                response.Error <-
                    MigrationWire.error (
                        Error.InvalidSource "Choose Vortex before selecting a profile."
                    )
            else
                match Vortex.profiles request.SourceFile with
                | Error error -> response.Error <- MigrationWire.error error
                | Ok profiles ->
                    for profile in profiles do
                        response.Profiles.Add(
                            BackupProfile(
                                Id = profile.Id,
                                Name = profile.Name,
                                GameId = profile.GameId
                            )
                        )

            return response
        }

    override _.Migrate(request, response, context) =
        task {
            let mutable writes = System.Threading.Tasks.Task.CompletedTask

            let progress value =
                writes <-
                    task {
                        do! writes
                        do! response.WriteAsync(MigrationWire.progress value)
                    }

            let workspace =
                match Guid.TryParse request.WorkspaceId with
                | true, value when value <> Guid.Empty -> Ok value
                | _ -> Error(Error.InvalidSource "The workspace ID is invalid.")

            let! result =
                match workspace, request.Manager with
                | Error error, _ -> task { return Error error }
                | Ok value, MigrationManager.ModOrganizer ->
                    ModOrganizer.migrate
                        store
                        { Request.WorkspaceId = value
                          SourceFolder = request.SourceFolder }
                        progress
                        context.CancellationToken
                | Ok value, MigrationManager.Vortex ->
                    Vortex.migrate
                        store
                        { Vortex.Request.WorkspaceId = value
                          BackupFile = request.SourceFolder
                          ProfileId = request.ProfileId
                          StagingRoot = request.StagingRoot
                          DownloadRoot = request.DownloadRoot }
                        progress
                        context.CancellationToken
                | Ok _, _ ->
                    task {
                        return
                            Error(
                                Error.InvalidSource
                                    "Choose Mod Organizer or Vortex as the source manager."
                            )
                    }

            do! writes
            do! response.WriteAsync(MigrationWire.result result)
        }
