namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.Bethesda
open ModConductor.Diagnostics
open ModConductor.GameContexts
open ModConductor.Loot
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module LootFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let validateMoves (writer: Utf8JsonWriter) =
        writer.WriteStartObject "lootResponseValidation"

        let check (name: string) (value: bool) =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                invalidOp ("LOOT response fixture failed: " + name)

        let metadata =
            { Revision = "metadata-fixture"
              MasterlistCommit = "masterlist"
              PreludeCommit = "prelude"
              MasterlistSha256 = String.replicate 64 "1"
              PreludeSha256 = String.replicate 64 "2"
              MasterlistPath = "unused"
              PreludePath = "unused"
              FetchedAt = DateTimeOffset.UnixEpoch }

        let first = "First.esp"
        let second = "Second.esp"
        let unchanged = "Unchanged.esp"
        let current = [ first; second; unchanged ]
        let sorted = [ second; first; unchanged ]

        let move plugin before after =
            { Plugin = plugin
              Current = before
              Proposed = after
              Reason = "fixture" }

        let response moves : LootJson.Response =
            { Correlation = "move-validation"
              Capability = "skyrim-se-steam"
              Fingerprint = "move-fixture"
              MetadataRevision = metadata.Revision
              HelperRevision = "0.1.0"
              LiblootVersion = "0.29.6"
              LiblootRevision = "136f3983"
              Current = current
              Sorted = sorted
              Moves = moves
              Messages = [] }

        let validate moves =
            ResponseValidation.validate
                "move-validation"
                "move-fixture"
                metadata
                current
                (response moves)

        let refused moves =
            match validate moves with
            | Error(LootError.InvalidResponse _) -> true
            | _ -> false

        let correct = [ move first 1 2; move second 2 1 ]
        check "exactMoveSetAccepted" (validate correct |> Result.isOk)
        check "omittedMoveRefused" (refused [ move first 1 2 ])
        check "duplicateMoveRefused" (refused [ move first 1 2; move first 1 2 ])

        check "unchangedMoveRefused" (refused [ move first 1 2; move unchanged 3 3 ])

        check "mismatchedMovePositionRefused" (refused [ move first 2 1; move second 2 1 ])

        check "extraMoveRefused" (refused (correct @ [ move unchanged 3 3 ]))

        writer.WriteEndObject()
        writer.Flush()

    let observe (writer: Utf8JsonWriter) primary (helper: string) masterlist prelude =
        writer.WriteStartObject "loot"

        let check (name: string) (value: bool) =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                invalidOp ("LOOT fixture failed: " + name)

        let area = Directory.CreateDirectory(Path.Combine(primary, "loot")).FullName
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
        let data = Path.Combine(game, "Data")

        for name in OrderRules.baseFiles do
            File.WriteAllBytes(Path.Combine(data, name), BethesdaSamples.header 1u 1.7f [] false)

        let patch = "Unofficial Skyrim Special Edition Patch.esp"

        File.WriteAllBytes(
            Path.Combine(data, patch),
            BethesdaSamples.header 0u 1.7f [ "Skyrim.esm" ] false
        )

        File.WriteAllBytes(
            Path.Combine(data, "NeedsPatch.esp"),
            BethesdaSamples.header 0u 1.7f [ patch ] false
        )

        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let state = Path.Combine(area, "state")
        use store = new OperationStore(state)

        let created =
            (store.Workspaces :> IWorkspaceState)
                .Create(workspace, "LOOT", StorageWorker.select root)
            |> wait
            |> result

        (store.Workspaces :> IWorkspaceState)
            .Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "Sorted" }
            )
        |> wait
        |> result
        |> ignore

        let context =
            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    profile,
                    0L,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Proton = Some proton }
                )
            |> wait
            |> result

        let local =
            match context.Binding.Value.Evidence.Locations.LocalAppData with
            | Location.Located(path, _) -> path
            | Location.Unavailable detail -> invalidOp detail

        Directory.CreateDirectory local |> ignore
        let pluginFile = Path.Combine(local, "Plugins.txt")
        let original = Encoding.Latin1.GetBytes("*NeedsPatch.esp\n*" + patch + "\n")
        File.WriteAllBytes(pluginFile, original)

        let metadataCache = MetadataCache(state)

        let metadata =
            metadataCache.Install(
                "e3c591ba9c041f23f407a0a0f87f72cc6325aa43",
                "3ae09f060500468d937f38bf23ffc40b2c950d13",
                File.ReadAllBytes masterlist,
                File.ReadAllBytes prelude
            )

        check
            "pinnedMetadataBytes"
            (metadata.MasterlistSha256 = "95caf8492923b77386fc725150d38c635a581a16bf0e546c3a44eec85afbe484"
             && metadata.PreludeSha256 = "d766b2d98565c2147bfeedf8df8385aae1c32731fc0b14b1bdb1ee54d1729711")

        let rejectedMetadata =
            metadataCache.ValidateAndInstall(
                "rejected-masterlist",
                "rejected-prelude",
                Encoding.UTF8.GetBytes "not valid LOOT metadata",
                Encoding.UTF8.GetBytes "not valid LOOT prelude",
                fun _ -> async { return Error(LootError.InvalidResponse "rejected fixture") }
            )
            |> Async.StartAsTask
            |> wait

        let retained =
            metadataCache.Current()
            |> Option.defaultWith (fun () -> invalidOp "metadata missing")

        check
            "rejectedRefreshRetainsLastKnownGood"
            (rejectedMetadata = Error(LootError.InvalidResponse "rejected fixture")
             && retained.Revision = metadata.Revision
             && retained.MasterlistSha256 = metadata.MasterlistSha256
             && retained.PreludeSha256 = metadata.PreludeSha256)

        let validator (state: GameContextState) = Ok state.Binding.Value.Evidence
        let bundle = Directory.CreateDirectory(Path.Combine(area, "bundle")).FullName
        let bundledHelper = Path.Combine(bundle, Path.GetFileName helper)
        let installed = store.LootForFixture(bundledHelper, validator)

        let diagnostics =
            DiagnosticSession(
                store.Workspaces,
                store.FilePlans,
                store.Deployments,
                store.GameLaunching,
                store.ProfileGameData,
                store.GameContexts,
                store.PluginOrders,
                helperDiagnostic = installed.HelperDiagnostic
            )
            :> IDiagnostics

        let helperFindings () =
            diagnostics.Check(
                { WorkspaceId = workspace
                  ProfileId = profile
                  FileSnapshotId = None
                  PluginSnapshotId = None
                  DeploymentReceipt = None },
                CancellationToken.None
            )
            |> wait
            |> result
            |> _.Findings
            |> List.filter (fun finding -> finding.Code = "loot-helper-unavailable")

        check
            "missingHelperIsUnavailable"
            (not (installed.Read().Available) && installed.HelperDiagnostic().IsSome)

        check
            "missingHelperHasOneHelpFindingWithPackageDetails"
            (match helperFindings () with
             | [ finding ] ->
                 finding.Evidence
                 |> List.exists (fun evidence ->
                     evidence.Label = "Package details" && evidence.Value.Contains bundledHelper)
             | _ -> false)

        File.Copy(helper, bundledHelper)

        check
            "helperRepairRestoresAvailability"
            (installed.Read().Available
             && installed.HelperDiagnostic().IsNone
             && (helperFindings () |> List.isEmpty))

        File.Delete bundledHelper
        File.Copy(Environment.ProcessPath, bundledHelper)

        check
            "incompatibleHelperIsUnavailable"
            (not (installed.Read().Available)
             && installed.HelperDiagnostic().IsSome
             && (helperFindings () |> List.length) = 1)

        let loot = store.LootForFixture(helper, validator)
        let headers = store.Plugins.Scan(profile, CancellationToken.None) |> wait |> result

        let initial =
            store.PluginOrders.Read(workspace, profile, headers.Id) |> wait |> result

        let order =
            store.PluginOrders.Change(
                initial.Reference,
                headers.Id,
                PluginOrderChange.Enable([ "Dawnguard.esm" ], false)
            )
            |> wait
            |> result

        let withEnabledName name =
            { order with
                View =
                    { order.View with
                        Order =
                            { order.View.Order with
                                Entries =
                                    { Name = name
                                      Enabled = Some true
                                      LockedIndex = None }
                                    :: order.View.Order.Entries } } }

        let projected value =
            store.LootProjectionForFixture(value, CancellationToken.None)
            |> Async.StartAsTask
            |> wait

        let stagingEmpty () =
            let staging = Path.Combine(state, "loot-staging")

            not (Directory.Exists staging)
            || (Directory.EnumerateFileSystemEntries(staging) |> Seq.isEmpty)

        let invalidProjection = projected (withEnabledName "../escape.esp")

        check
            "invalidProjectionNameIsRejectedWithoutStaging"
            (invalidProjection = Error(
                LootError.Unsupported "A plugin name is not a single file name."
             )
             && stagingEmpty ())

        let missingSource = projected (withEnabledName "Absent.esp")

        check
            "missingCheckedProjectionSourceIsRejected"
            (missingSource = Error(
                LootError.Unsupported "Absent.esp does not have a checked projected source."
             )
             && stagingEmpty ())

        let source = Path.Combine(data, "NeedsPatch.esp")
        let held = Path.Combine(area, "held-plugin.esp")
        File.Move(source, held)

        let missingFile =
            try
                projected order
            finally
                File.Move(held, source)

        let missingFileRejected =
            missingFile = Error(
                LootError.Unsupported "NeedsPatch.esp could not be copied into the LOOT projection."
            )

        check
            "missingProjectionFileIsRejectedAndStagingCleaned"
            (missingFileRejected && stagingEmpty ())

        let proposal =
            loot.Preview(order, CancellationToken.None)
            |> Async.StartAsTask
            |> wait
            |> result

        let position (name: string) (rows: string list) =
            rows
            |> List.findIndex (fun value -> value.Equals(name, StringComparison.OrdinalIgnoreCase))

        check
            "realLiblootSortsMasterDependency"
            (position patch proposal.Sorted < position "NeedsPatch.esp" proposal.Sorted
             && proposal.LiblootVersion = "0.29.6"
             && proposal.LiblootRevision = "136f3983")

        check "previewDoesNotWriteGameList" (File.ReadAllBytes(pluginFile) = original)

        check
            "proposalSetIsExact"
            (Set.ofList (proposal.Current |> List.map _.ToUpperInvariant()) = Set.ofList (
                proposal.Sorted |> List.map _.ToUpperInvariant()
            ))

        check
            "disabledOfficialRemainsOutsideLootMoves"
            (proposal.Current |> List.contains "Dawnguard.esm"
             && proposal.Moves
                |> List.exists (fun move ->
                    move.Plugin.Equals("Dawnguard.esm", StringComparison.OrdinalIgnoreCase))
                |> not
             && position "Dawnguard.esm" proposal.Current = position "Dawnguard.esm" proposal.Sorted)

        let sorted =
            loot.ValidateApply(proposal.Id, proposal.Expected, proposal.HeadersId) |> result

        let saved =
            store.PluginOrders.ApplyExactOrder(proposal.Expected, proposal.HeadersId, sorted)
            |> wait
            |> result

        loot.Applied proposal.Id

        check
            "explicitApplyChangesOnlySavedOrder"
            (saved.Saved
             && (saved.View.Order.Entries
                 |> List.find (fun row -> row.Name = "Dawnguard.esm")
                 |> _.Enabled) = Some false
             && position patch (saved.View.Order.Entries |> List.map _.Name) < position
                 "NeedsPatch.esp"
                 (saved.View.Order.Entries |> List.map _.Name)
             && File.ReadAllBytes(pluginFile) = original)

        check
            "appliedProposalExpires"
            (loot.ValidateApply(proposal.Id, saved.Reference, saved.Headers.Id) = Error
                LootError.Stale)

        check "privateProjectionWasCleaned" (stagingEmpty ())

        writer.WriteEndObject()
        writer.Flush()
