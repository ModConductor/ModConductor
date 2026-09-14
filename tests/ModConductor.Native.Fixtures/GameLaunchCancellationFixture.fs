namespace ModConductor.Native.Fixtures

open System
open System.Collections.Generic
open System.Threading.Tasks
open System.Text.Json
open ModConductor.Executables

module GameLaunchCancellationFixture =
    let sample () =
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()

        let capture =
            { Request =
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  WorkspaceRevision = 1L
                  ProfileId = profile
                  ContextRevision = 1L
                  SourceToken = "fixture" }
              ContextId = Guid.NewGuid()
              Name = "Skyrim Special Edition"
              GameDirectory = "not-used"
              Runtime = "Fixture"
              Launch =
                { Executable = "not-started"
                  WorkingDirectory = "not-used"
                  Arguments = []
                  Environment = [] }
              Preparation =
                { Phase = GamePreparationPhase.Preparing
                  Completed = 0
                  Total = 2 }
              Files = None
              ProfileDataRevision = 0L
              ProfileData = None }

        capture

    let observe (writer: Utf8JsonWriter) (capture: GameRun) =
        let gate = obj ()
        let rows = Dictionary<Guid, ExecutableRun>()

        let repository =
            { new IExecutableRepository with
                member _.List(_, _) = invalidOp "Unused fixture operation"
                member _.ReadPreset(_, _) = invalidOp "Unused fixture operation"
                member _.Save _ = invalidOp "Unused fixture operation"
                member _.Delete(_, _, _) = invalidOp "Unused fixture operation"
                member _.Begin _ = invalidOp "Unused fixture operation"
                member _.Recent(_, _) = invalidOp "Unused fixture operation"
                member _.LatestGame _ = invalidOp "Unused fixture operation"

                member _.BeginGame game =
                    let value =
                        { Source = RunSource.Game game
                          Revision = 1L
                          ProfileId = Some game.Request.ProfileId
                          ProfileName = Some "Selected"
                          RequestedAt = DateTimeOffset.UtcNow
                          Phase = RunPhase.Starting
                          ProcessId = None
                          Scope = None
                          RootExitCode = None
                          ActiveProcesses = None
                          Problem = None }

                    lock gate (fun () -> rows.Add(value.Id, value))
                    Task.FromResult(Ok(value, true))

                member _.Read(_, id) =
                    Task.FromResult(
                        lock gate (fun () ->
                            match rows.TryGetValue id with
                            | true, value -> Ok value
                            | _ -> Error ExecutableError.NotFound)
                    )

                member _.Update value =
                    Task.FromResult(
                        lock gate (fun () ->
                            let previous = rows[value.Id]

                            if previous.Revision <> value.Revision then
                                invalidOp "Stale fixture run write"

                            let next =
                                { value with
                                    Revision = value.Revision + 1L }

                            rows[value.Id] <- next
                            next)
                    ) }

        let owner = ExecutableSession(repository)

        let entered =
            TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

        let prepare: PrepareGameRun =
            fun game token progress ->
                task {
                    do!
                        progress
                            { game with
                                Preparation =
                                    { Phase = GamePreparationPhase.Applying
                                      Completed = 1
                                      Total = 2 } }

                    entered.SetResult()
                    do! Task.Delay(-1, token)
                    return invalidOp "Cancelled preparation continued"
                }

        let request =
            { capture.Request with
                Id = Guid.NewGuid() }

        let pending =
            { capture with
                Request = request
                Files = None }

        let run =
            owner.BeginGame(pending, prepare) |> StorageWorker.wait |> StorageWorker.result

        if not (entered.Task.Wait(TimeSpan.FromSeconds 10.)) then
            invalidOp "Preparation did not enter its controlled checkpoint"

        let cancelled =
            owner.CancelGame(request.WorkspaceId, run.Id)
            |> StorageWorker.wait
            |> StorageWorker.result

        let replay =
            owner.BeginGame(pending, prepare) |> StorageWorker.wait |> StorageWorker.result

        let valid =
            cancelled.Phase = RunPhase.Cancelled
            && cancelled.ProcessId.IsNone
            && replay = cancelled

        writer.WriteBoolean("cancelBeforeSpawnRetainsTerminalRunWithoutReplay", valid)

        if not valid then
            invalidOp "Pre-start cancellation did not preserve its terminal run"

        owner.Close() |> StorageWorker.wait
