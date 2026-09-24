namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open Microsoft.Data.Sqlite
open ModConductor.Credentials
open ModConductor.Nexus
open ModConductor.Engine
open ModConductor.HttpDownloads
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInstallation
open ModConductor.ModLibrary
open ModConductor.ModOrganization
open ModConductor.ModMaintenance
open ModConductor.Persistence
open ModConductor.Workspaces

module NexusMetadataFixtures =
    let private wait = StorageWorker.wait

    let private result value =
        value
        |> Result.defaultWith (fun _ -> failwith "Nexus metadata fixture request failed.")

    let private token = CancellationToken.None

    let private until predicate =
        let deadline = DateTime.UtcNow.AddSeconds 20.

        while not (predicate ()) && DateTime.UtcNow < deadline do
            Thread.Sleep 10

        if not (predicate ()) then
            failwith "The metadata fixture did not reach its completion boundary."

    let payload value =
        use bytes = new MemoryStream()

        do
            use archive = new ZipArchive(bytes, ZipArchiveMode.Create, true)

            for path, text in
                [ "Data/textures/water.dds", value; "Data/textures/unchanged.dds", "same" ] do
                use file = archive.CreateEntry(path).Open()
                file.Write(Encoding.UTF8.GetBytes text)

        bytes.ToArray()

    let private reference (value: Artifact) : ArtifactRef =
        { WorkspaceId = value.WorkspaceId
          Id = value.Id
          Revision = value.Revision }

    let private readMod (store: OperationStore) workspace id =
        ((store.ModLibrary :> IModLibrary).Scan(workspace, 100) |> wait |> result).Entries
        |> List.find (fun entry -> entry.Id = id)

    let private stopped (store: OperationStore) workspace id =
        until (fun () ->
            (store.Installations.Read(workspace, id) |> wait).State
            <> InstallationState.Running)

        store.Installations.Read(workspace, id) |> wait

    let private download (store: OperationStore) workspace file version =
        let source =
            { Account = "42"
              Game = "skyrimspecialedition"
              ModId = 64012L
              FileId = file
              Keyed = false
              Version = Some version }

        let request =
            { Id = Guid.NewGuid()
              WorkspaceId = workspace
              Name = "Quiet rivers.zip"
              Sources = [ DownloadSource.Nexus source ]
              ExpectedLength = None
              ExpectedSha256 = None }

        let started = store.Downloads.Start request |> wait |> result

        until (fun () ->
            let value = store.Artifacts.Read(workspace, started.Id) |> wait |> result

            value.State = ArtifactState.Ready
            || (value.Download |> Option.exists (fun info -> info.State = DownloadState.Failed)))

        let value = store.Artifacts.Read(workspace, started.Id) |> wait |> result

        if value.State <> ArtifactState.Ready then
            failwith ("Fixture download failed: " + defaultArg value.Problem "unknown")

        value, source

    let private install (store: OperationStore) (artifact: Artifact) =
        let draft = store.Installations.Prepare(reference artifact, token) |> wait

        let started =
            store.Installations.Start(
                artifact.WorkspaceId,
                draft.Id,
                draft.Revision,
                Guid.NewGuid()
            )

        let status = stopped store artifact.WorkspaceId started.Id

        if status.State <> InstallationState.Complete then
            failwith ("Fixture installation failed: " + defaultArg status.Problem "unknown")

        status

    let observe (writer: Utf8JsonWriter) area =
        Directory.CreateDirectory area |> ignore

        let check (name: string) value =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                failwith ("Metadata fixture failed: " + name)

        writer.WriteStartObject("nexusMetadata")
        use server = new NexusServer()
        server.Metadata <- true
        server.Payload <- payload "first"
        use credentials = new CredentialSession(NexusMemoryStore())

        use session =
            new NexusSession(
                credentials,
                Some server.Registration,
                server.Handoff,
                (fun _ -> Task.CompletedTask),
                requestInterval = TimeSpan.Zero
            )

        session.SignIn() |> wait |> ignore
        until (fun () -> not session.Status.Waiting)
        check "syntheticAccountConnected" session.Status.Account.IsSome

        server.FnisFiles <-
            [ 7001L, "fnis-archive.zip", "7.6", "FNIS archive"
              7002L, "fnis-guide.txt", "7.6", "FNIS guide" ]

        server.Mode <- "null-size"
        let fnis = session.ReadMod("skyrimspecialedition", 3038L) |> wait

        check
            "nullOptionalFileSizeKeepsFnisMetadataReadable"
            (match fnis with
             | Ok value ->
                 value.Files.Length = 2
                 && (value.Files |> List.find (fun file -> file.Id = 7001L)).Bytes.IsNone
                 && (value.Files |> List.find (fun file -> file.Id = 7002L)).Bytes.IsSome
             | Error _ -> false)

        server.Mode <- "good"
        server.FnisFiles <- []
        let workspace = Guid.NewGuid()
        let state = Path.Combine(area, "state")
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let mutable installedMod = Guid.Empty
        let mutable originalVersion = Guid.Empty
        let mutable retained = Unchecked.defaultof<ModNexusDetails>

        do
            use store = new OperationStore(state, nexusLinks = NexusDownloadLinks(session))
            let workspaces = store.Workspaces :> IWorkspaceState

            let created =
                workspaces.Create(workspace, "Nexus metadata", StorageWorker.select root)
                |> wait
                |> result

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create
                    { Id = Guid.NewGuid()
                      Name = "Default" }
            )
            |> wait
            |> result
            |> ignore

            let artifact, _ = download store workspace 501L "1.4"
            let installed = install store artifact
            installedMod <- installed.ModId.Value
            originalVersion <- installed.VersionId.Value
            let details = NexusModDetails(session, store.NexusMetadata)
            let initial = details.Read(workspace, installedMod) |> wait |> result

            check
                "publicationAnchorsObservedProviderFileVersion"
                (initial.Identity = Some
                    { Game = "skyrimspecialedition"
                      Mod = 64012L }
                 && initial.Installed = Some
                     { Id = 501L
                       Version = "1.4"
                       Manual = false })

            let current = readMod store workspace installedMod

            let edited =
                (store.ModLibrary :> IModLibrary)
                    .Edit(
                        installedMod,
                        current.Revision,
                        { current.Metadata with
                            Name = "My quiet rivers"
                            Notes = "Keep my settings"
                            Version = "local label"
                            Source = "local source" }
                    )
                |> wait
                |> result

            let refreshed = details.Refresh initial |> wait |> result
            let latest = readMod store workspace installedMod

            check
                "refreshPreservesLocalEditsAndUsesExplicitSuccessorLeaves"
                (latest.Metadata = edited.Metadata
                 && refreshed.Freshness = NexusFreshness.Current
                 && (NexusUpdates.candidates refreshed.Installed refreshed.Snapshot.Value
                     |> List.map (fun file -> file.File.Id)
                     |> Set.ofList) = set[502L
                                          504L])

            let org = store.ModOrganization :> IModOrganization
            let cat = Guid.NewGuid()
            let categories = org.Categories(workspace, None, None, None) |> wait |> result

            org.EditCategory(
                workspace,
                categories.Revision,
                CategoryEdit.Create(cat, None, "Environment")
            )
            |> wait
            |> result
            |> ignore

            let mapped = details.MapCategory(refreshed, cat) |> wait |> result
            let afterMap = readMod store workspace installedMod

            check
                "mappingAddsOnlyExplicitCategoryAndKeepsNotes"
                (mapped.CategoryMapping
                 |> Option.exists (fun mapping -> mapping.CategoryId = cat)
                 && afterMap.Metadata.Notes = "Keep my settings"
                 && afterMap.Metadata.Categories |> List.exists (fun category -> category.Id = cat))

            let identity = refreshed.Identity.Value
            server.Mode <- "endorsements-refused"
            let partial = details.Refresh mapped |> wait |> result
            let state = session.InteractionState identity

            check
                "publicAndTrackingRemainKnownWhenEndorsementReadIsRefused"
                (partial.Freshness = NexusFreshness.Current
                 && state.Tracking = Some false
                 && state.Endorsement.IsNone
                 && state.Problem = Some NexusProblem.Forbidden)

            server.Mode <- "good"
            session.RefreshInteractions identity |> wait |> ignore
            let state = session.InteractionState identity

            details.Change(partial, state.Revision, NexusInteraction.Endorse)
            |> wait
            |> result
            |> ignore

            check
                "endorsementUsesObservedFileVersionNotLocalLabel"
                (server.LastVersion = "1.4"
                 && (session.InteractionState identity).Endorsement = Some NexusEndorsement.Endorsed)

            let state = session.InteractionState identity
            let before = server.Writes
            server.Mode <- "write-uncertain"

            details.Change(partial, state.Revision, NexusInteraction.Track)
            |> wait
            |> result
            |> ignore

            let uncertain = session.InteractionState identity

            details.Change(partial, state.Revision, NexusInteraction.Track)
            |> wait
            |> result
            |> ignore

            check
                "uncertainWriteIsNotReplayedAndRequiresExplicitRead"
                (server.Writes = before + 1
                 && uncertain.Tracking.IsNone
                 && uncertain.Problem = Some NexusProblem.InteractionUnknown)

            server.Mode <- "good"
            session.RefreshInteractions identity |> wait |> ignore

            check
                "explicitReadResolvesUncertainServerOutcome"
                ((session.InteractionState identity).Tracking = Some true)

            let count = server.Count "/api/games/skyrimspecialedition/mods/64012.json"
            server.HoldMetadata() |> ignore
            let pending = details.Refresh partial
            until (fun () -> server.Count "/api/games/skyrimspecialedition/mods/64012.json" > count)
            let latest = details.Read(workspace, installedMod) |> wait |> result
            details.Link(latest, None, None) |> wait |> result |> ignore
            server.ReleaseMetadata()

            check
                "lateRefreshCannotRestoreAnExplicitlyRemovedLink"
                (pending |> wait = Error NexusProblem.ModChanged)

            let unlinked = details.Read(workspace, installedMod) |> wait |> result

            check
                "unlinkKeepsArchiveAndSavedVersionWithoutProviderSnapshot"
                (unlinked.Identity.IsNone
                 && unlinked.Snapshot.IsNone
                 && ((store.ModLibrary :> IModLibrary).Version(originalVersion, 0)
                     |> wait
                     |> Result.isOk))

            let metadata = session.ReadMetadata identity |> wait |> result

            let linked =
                details.Link(
                    unlinked,
                    Some metadata,
                    Some((metadata.Files |> List.find (fun file -> file.File.Id = 501L)).File)
                )
                |> wait
                |> result

            check
                "explicitManualFileLinkIsVersionScopedAndTruthful"
                (linked.Installed |> Option.exists _.Manual)

            server.Mode <- "metadata-error"
            let failed = details.Refresh linked |> wait |> result

            check
                "failedRefreshRetainsSavedPublicDetailsButNotCurrentSuggestions"
                (failed.Snapshot = linked.Snapshot
                 && failed.Freshness = NexusFreshness.Stale
                 && failed.Problem.IsSome
                 && (details.File(failed, 502L, true) |> wait |> Result.isError))

            server.Mode <- "unavailable"
            let unavailable = details.Refresh failed |> wait |> result

            check
                "providerUnavailableDisablesAcquisition"
                (unavailable.Freshness = NexusFreshness.Unavailable
                 && (details.File(unavailable, 502L, true) |> wait |> Result.isError))

            server.Mode <- "good"
            let current = details.Refresh unavailable |> wait |> result
            let _, selected = details.File(current, 502L, true) |> wait |> result
            server.Payload <- payload "updated"
            let archive, source = download store workspace selected.Id selected.Version
            let same = store.Downloads.FindNexus(workspace, source) |> wait

            check
                "selectedCandidateUsesExistingArtifactAdmission"
                (same |> Option.exists (fun found -> found.Id = archive.Id))

            let draft = store.Installations.Prepare(reference archive, token) |> wait
            let target = readMod store workspace installedMod

            let preview =
                store.Installations.PrepareUpdate(
                    workspace,
                    draft.Id,
                    draft.Revision,
                    target.Id,
                    target.Revision,
                    UpdateMode.Merge,
                    Set.empty,
                    "local update label"
                )
                |> wait

            let started = store.Installations.StartUpdate(workspace, preview.Id, Guid.NewGuid())
            let updated = stopped store workspace started.Id
            let next = details.Read(workspace, installedMod) |> wait |> result

            check
                "reviewedUpdateKeepsModAndOldVersionWithNewExactOrigin"
                (updated.State = InstallationState.Complete
                 && updated.ModId = Some installedMod
                 && next.Installed = Some
                     { Id = 502L
                       Version = "1.5"
                       Manual = false }
                 && next.Identity = current.Identity
                 && ((store.ModLibrary :> IModLibrary).Version(originalVersion, 0)
                     |> wait
                     |> Result.isOk))

            retained <- details.Refresh next |> wait |> result

        do
            use store = new OperationStore(state, nexusLinks = NexusDownloadLinks(session))
            let details = NexusModDetails(session, store.NexusMetadata)
            let stale = details.Read(workspace, installedMod) |> wait |> result

            check
                "restartRetainsPublicSnapshotAsStaleWithoutNetworkWork"
                (stale.Snapshot = retained.Snapshot && stale.Freshness = NexusFreshness.Stale)

            session.Disconnect token |> wait |> ignore
            let identity = stale.Identity.Value
            let account = session.InteractionState identity

            check
                "disconnectDropsAccountFactsWithoutDeletingPublicDetails"
                (account.Tracking.IsNone
                 && account.Endorsement.IsNone
                 && (details.Read(workspace, installedMod) |> wait |> result).Snapshot = retained.Snapshot)

            session.SignIn() |> wait |> ignore
            until (fun () -> not session.Status.Waiting)
            let count = server.Count "/api/games/skyrimspecialedition/mods/64012.json"
            server.HoldMetadata() |> ignore
            let pending = details.Refresh stale
            until (fun () -> server.Count "/api/games/skyrimspecialedition/mods/64012.json" > count)
            let target = readMod store workspace installedMod

            store.Deletions.Delete(workspace, installedMod, target.Revision) |> wait

            server.ReleaseMetadata()

            check
                "lateRefreshCannotResurrectDeletedMod"
                (pending |> wait = Error NexusProblem.ModChanged)

            use db = new SqliteConnection("Data Source=" + Path.Combine(state, "state.db"))
            db.Open()
            use query = db.CreateCommand()

            query.CommandText <-
                "SELECT (SELECT count(*) FROM mod_nexus_links)+(SELECT count(*) FROM mod_nexus_files)+(SELECT count(*) FROM mod_nexus_updates)+(SELECT count(*) FROM version_nexus_origins)"

            check
                "ownedDeletionRemovesAllProviderRowsAndVersionOrigins"
                (Convert.ToInt64(query.ExecuteScalar()) = 0L)

        writer.WriteEndObject()

    let engine state info =
        use server = new NexusServer()
        server.Metadata <- true
        server.Payload <- payload "synthetic texture bytes"
        File.WriteAllText(info, server.Root)

        ModConductor.Engine.Program.runWithNexus
            (Some server.Registration)
            server.Handoff
            [| "--state-directory"; state |]
