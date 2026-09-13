namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads
open ModConductor.Persistence
open ModConductor.Workspaces

module DownloadFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private policy =
        { DownloadPolicy.Default with
            HeaderTimeout = TimeSpan.FromMilliseconds 400.
            ReadTimeout = TimeSpan.FromMilliseconds 400.
            RetryDelay = TimeSpan.FromMilliseconds 30.
            CheckpointBytes = 16384L }

    let private read (store: OperationStore) workspace id =
        store.Artifacts.Read(workspace, id) |> wait |> result

    let private until (store: OperationStore) workspace id condition =
        let limit = DateTime.UtcNow.AddSeconds 12.
        let mutable value = read store workspace id

        while not (condition value) && DateTime.UtcNow < limit do
            Thread.Sleep 10
            value <- read store workspace id

        if not (condition value) then
            failwith (
                "Download did not reach the expected state: "
                + (value.Problem |> Option.defaultValue "No error")
                + "; bytes="
                + value.Download.Value.Bytes.ToString()
            )

        value

    let private terminal (a: Artifact) =
        a.Download.Value.State = DownloadState.Complete
        || a.Download.Value.State = DownloadState.Failed

    let private request workspace id url hash =
        { Id = id
          WorkspaceId = workspace
          Name = "Textures — rivière.zip"
          Sources = [ DownloadSource.Url url ]
          ExpectedLength = Some(4L * 1024L * 1024L)
          ExpectedSha256 = hash }

    let worker state (workspace: string) (id: string) url hash =
        use store =
            new OperationStore(
                state,
                downloadPolicy =
                    { policy with
                        ReadTimeout = TimeSpan.FromSeconds 30. }
            )

        let workspace, id = Guid.Parse workspace, Guid.Parse id

        store.Downloads.Start(request workspace id url (Some hash))
        |> wait
        |> result
        |> ignore

        until store workspace id (fun a -> a.Download.Value.Bytes >= 32768L) |> ignore
        StorageWorker.pause ()
        store.Downloads.Stop().GetAwaiter().GetResult()

    let observe (writer: Utf8JsonWriter) primary =
        let check (name: string) condition =
            writer.WriteBoolean(name, condition)

            if not condition then
                failwith ("Download fixture failed: " + name)

        writer.WriteStartObject("downloads")
        let area = Directory.CreateDirectory(Path.Combine(primary, "downloads")).FullName
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspace = Guid.NewGuid()
        use server = new DownloadServer()

        do
            use setup = new OperationStore(state)

            (setup.Workspaces :> IWorkspaceState)
                .Create(workspace, "Download fixture", StorageWorker.select root)
            |> wait
            |> result
            |> ignore

        let crashed = Guid.NewGuid()

        do
            use child =
                new NativeChild(
                    Environment.ProcessPath,
                    [ "--download-worker"
                      state
                      string workspace
                      string crashed
                      server.Url + "/slow"
                      server.Checksum ]
                )

            if child.Line() <> "ready" then
                failwith "The download child did not save a prefix."

            child.Terminate()

        use store = new OperationStore(state, downloadPolicy = policy)

        try
            let restored = read store workspace crashed
            let requests = server.Count "/slow"
            Thread.Sleep 100

            check
                "restartRetainsPausedPrefixWithoutNetwork"
                (restored.Download.Value.State = DownloadState.Paused
                 && restored.Download.Value.Bytes >= 32768L
                 && restored.OriginalName = "Textures — rivière.zip"
                 && restored.Download.Value.Source = server.Url + "/slow"
                 && restored.Download.Value.ExpectedSha256 = Some server.Checksum
                 && server.Count "/slow" = requests)

            store.Downloads.Control(workspace, crashed, DownloadAction.Resume)
            |> wait
            |> result
            |> ignore

            let completed = until store workspace crashed terminal

            check
                "strongRangeResumePublishesExactBytes"
                (completed.State = ArtifactState.Ready
                 && completed.Download.Value.ChecksumMatched
                 && File.ReadAllBytes completed.Path = server.Payload)

            check
                "resumeUsesSavedValidatorAndOffset"
                (server.Seen
                 |> Array.exists (fun r ->
                     r.Path = "/slow" && not (isNull r.Range) && r.Validator = "\"fixture-1\""))

            let replay =
                store.Downloads.Start(
                    request workspace crashed (server.Url + "/slow") (Some server.Checksum)
                )
                |> wait
                |> result

            check
                "replayedStartDoesNotDownloadAgain"
                (replay.Id = crashed && server.Count "/slow" = requests + 1)

            for endpoint in
                [ "ignore-range"
                  "changed-etag"
                  "wrong-range"
                  "changed-total"
                  "no-etag-slow" ] do
                let id = Guid.NewGuid()

                store.Downloads.Start(
                    request workspace id (server.Url + "/" + endpoint) (Some server.Checksum)
                )
                |> wait
                |> result
                |> ignore

                let partial = until store workspace id (fun a -> a.Download.Value.Bytes >= 32768L)

                store.Downloads.Control(workspace, id, DownloadAction.Pause)
                |> wait
                |> result
                |> ignore

                let paused =
                    until store workspace id (fun a ->
                        a.Download.Value.State = DownloadState.Paused && a.CanDeleteCopy)

                let length = paused.Download.Value.Bytes

                let resumed = store.Downloads.Control(workspace, id, DownloadAction.Resume) |> wait

                let failed =
                    if paused.Download.Value.RestartRequired then
                        if resumed <> Error ArtifactError.Conflict then
                            failwith "A missing validator allowed resume."

                        read store workspace id
                    else
                        resumed |> result |> ignore
                        until store workspace id terminal

                check
                    (endpoint + "PreservesPrefixWithoutPublication")
                    (failed.State = ArtifactState.Incomplete
                     && failed.Download.Value.RestartRequired
                     && failed.Download.Value.Bytes = length
                     && not (File.Exists failed.Path)
                     && partial.Id = failed.Id)

            for endpoint in [ "corrupt"; "encoding"; "truncate"; "timeout"; "headers-timeout" ] do
                let id = Guid.NewGuid()

                store.Downloads.Start(
                    request workspace id (server.Url + "/" + endpoint) (Some server.Checksum)
                )
                |> wait
                |> result
                |> ignore

                let failed = until store workspace id terminal

                check
                    (endpoint + "NeverBecomesReady")
                    (failed.Download.Value.State = DownloadState.Failed
                     && failed.State = ArtifactState.Incomplete
                     && not (File.Exists failed.Path))

            for endpoint in [ "truncate-once"; "retry429"; "no-etag" ] do
                let id = Guid.NewGuid()
                let hash = if endpoint = "no-etag" then None else Some server.Checksum

                store.Downloads.Start(request workspace id (server.Url + "/" + endpoint) hash)
                |> wait
                |> result
                |> ignore

                let complete = until store workspace id terminal

                check
                    (endpoint + "CompletesWithTruthfulIntegrity")
                    (complete.State = ArtifactState.Ready
                     && complete.Download.Value.ChecksumMatched = hash.IsSome
                     && File.ReadAllBytes complete.Path = server.Payload)

            let retries = server.Seen |> Array.filter (fun r -> r.Path = "/retry429")

            check
                "retryAfterIsNotIgnored"
                (retries.Length = 2 && (retries[1].At - retries[0].At).TotalMilliseconds >= 950.)

            let mirror = Guid.NewGuid()

            let mirrorRequest =
                { request workspace mirror (server.Url + "/mirror-fail") (Some server.Checksum) with
                    Sources =
                        [ DownloadSource.Url(server.Url + "/mirror-fail")
                          DownloadSource.Url(server.Url + "/good") ] }

            store.Downloads.Start mirrorRequest |> wait |> result |> ignore
            let mirrorResult = until store workspace mirror terminal

            check
                "emptyMirrorFailureRotatesWithoutNewArtifact"
                (mirrorResult.Id = mirror
                 && mirrorResult.State = ArtifactState.Ready
                 && File.ReadAllBytes mirrorResult.Path = server.Payload)

            let partialMirror = Guid.NewGuid()

            store.Downloads.Start
                { mirrorRequest with
                    Id = partialMirror
                    Sources =
                        [ DownloadSource.Url(server.Url + "/partial-fail")
                          DownloadSource.Url(server.Url + "/good") ] }
            |> wait
            |> result
            |> ignore

            let retained = until store workspace partialMirror terminal

            check
                "partialMirrorFailureKeepsSourceAndBytes"
                (retained.State = ArtifactState.Incomplete
                 && retained.Download.Value.Bytes > 0L
                 && retained.Download.Value.Source.EndsWith("/partial-fail"))

            store.Downloads.Control(workspace, partialMirror, DownloadAction.Restart)
            |> wait
            |> result
            |> ignore

            let restarted = until store workspace partialMirror terminal

            check
                "explicitRestartReusesIdentityAndReplacesOnlyPartial"
                (restarted.Id = partialMirror
                 && restarted.State = ArtifactState.Ready
                 && File.ReadAllBytes restarted.Path = server.Payload)

            check
                "failedAttemptsStayBounded"
                (server.Count "/truncate" = policy.Attempts
                 && server.Count "/timeout" = policy.Attempts
                 && server.Count "/headers-timeout" = policy.Attempts)

            store.Downloads.Stop().GetAwaiter().GetResult()

            let queueState =
                Directory.CreateDirectory(Path.Combine(area, "queue-state")).FullName

            let queueRoot =
                Directory.CreateDirectory(Path.Combine(area, "queue-workspace")).FullName

            let queueWorkspace = Guid.NewGuid()
            let beforeQueue = server.Count "/slow"

            do
                use queue =
                    new OperationStore(
                        queueState,
                        downloadPolicy =
                            { policy with
                                ReadTimeout = TimeSpan.FromSeconds 30. }
                    )

                (queue.Workspaces :> IWorkspaceState)
                    .Create(queueWorkspace, "Queued downloads", StorageWorker.select queueRoot)
                |> wait
                |> result
                |> ignore

                let beginDownload id =
                    queue.Downloads.Start(
                        request queueWorkspace id (server.Url + "/slow") (Some server.Checksum)
                    )
                    |> wait

                let first, second = Guid.NewGuid(), Guid.NewGuid()
                beginDownload first |> result |> ignore
                beginDownload second |> result |> ignore

                until queue queueWorkspace first (fun a -> a.Download.Value.Bytes >= 32768L)
                |> ignore

                until queue queueWorkspace second (fun a -> a.Download.Value.Bytes >= 32768L)
                |> ignore

                let queued = List.init 32 (fun _ -> Guid.NewGuid())

                for id in queued do
                    beginDownload id |> result |> ignore

                let refused = Guid.NewGuid()

                check
                    "workerAndQueueCapacityAreBounded"
                    (beginDownload refused = Error ArtifactError.Busy
                     && server.Count "/slow" = beforeQueue + 2)

                check
                    "capacityRefusalLeavesNoArtifact"
                    (queue.Artifacts.Read(queueWorkspace, refused) |> wait = Error
                        ArtifactError.NotFound)

                queue.Downloads.Control(queueWorkspace, queued.Head, DownloadAction.Pause)
                |> wait
                |> result
                |> ignore

                let paused = read queue queueWorkspace queued.Head

                check
                    "pauseBeforeTransferKeepsQueuedIdentityWithoutBytes"
                    (paused.Id = queued.Head
                     && paused.Download.Value.State = DownloadState.Paused
                     && paused.Download.Value.Bytes = 0L)

                queue.Downloads.Stop().GetAwaiter().GetResult()

            do
                use reopened = new OperationStore(queueState, downloadPolicy = policy)

                let saved =
                    reopened.Artifacts.List(queueWorkspace, None, false, CancellationToken.None)
                    |> wait
                    |> result

                Thread.Sleep 100

                check
                    "shutdownPausesRunningAndQueuedWorkWithoutRestartNetwork"
                    (saved.Entries.Length = 34
                     && saved.Entries
                        |> List.forall (fun a -> a.Download.Value.State = DownloadState.Paused)
                     && server.Count "/slow" = beforeQueue + 2)

        finally
            store.Downloads.Stop().GetAwaiter().GetResult()

        writer.WriteEndObject()
