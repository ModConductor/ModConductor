namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open Google.Protobuf
open ModConductor.Bethesda
open ModConductor.Engine
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.ModOrganization
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Protocol.V1

module LootFreshProfileFixtures =
    let observe (writer: Utf8JsonWriter) primary helper =
        let wait = StorageWorker.wait
        let value = StorageWorker.result
        let token = CancellationToken.None

        let query =
            { Text = ""
              Mode = FilterMode.All
              Filters = []
              View = OrganizationView.Groups
              Sort = OrganizationSort.Priority }

        writer.WriteStartArray "freshLoot"

        for withBase in [ true; false ] do
            let area =
                Directory.CreateDirectory(Path.Combine(primary, string withBase)).FullName

            let state = Path.Combine(area, "state")
            use store = new OperationStore(state)

            let workspace, profile, game, _, context =
                SkyrimFixtureWorkspace.create store state area "fresh" "workspace" "game" true

            let context = value context

            if withBase then
                for name in OrderRules.baseFiles do
                    File.WriteAllBytes(
                        Path.Combine(game, "Data", name),
                        BethesdaSamples.header 1u 1.7f [] false
                    )

            let root = Path.Combine(area, "workspace")
            let library = store.ModLibrary :> IModLibrary
            let selection = store.ModSelection :> IModSelection

            for name in [ "SKSE"; "Textures" ] do
                let id = Guid.NewGuid()
                let folder = Directory.CreateDirectory(Path.Combine(root, name)).FullName
                File.WriteAllText(Path.Combine(folder, "loose.txt"), name)

                let metadata =
                    { Name = name
                      Version = ""
                      Notes = ""
                      Comment = ""
                      Source = ""
                      Categories = [] }

                let entry =
                    library.Register(
                        workspace,
                        id,
                        metadata,
                        Registration.Directory(
                            ModKind.Regular,
                            ModConductor.Platform.LogicalPath.create [ name ] |> value
                        )
                    )
                    |> wait
                    |> value

                library.Publish(id, entry.Revision, Guid.NewGuid()) |> wait |> value |> ignore

                let current =
                    (store.ModOrganization :> IModOrganization).Query(profile, query, None, None)
                    |> wait
                    |> value

                selection.Change(
                    profile,
                    current.SelectionRevision,
                    [ id ],
                    SelectionEdit.Enable true
                )
                |> wait
                |> value
                |> ignore

            let local =
                match context.Binding.Value.Evidence.Locations.LocalAppData with
                | Location.Located(path, _) -> path
                | Location.Unavailable detail -> invalidOp detail

            Directory.CreateDirectory local |> ignore

            if withBase then
                let deployment = store.Deployments.Read profile |> wait |> value

                let prepared =
                    store.Deployments.Prepare(Guid.NewGuid(), deployment.Sources, ignore, token)
                    |> wait
                    |> value

                store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, token)
                |> wait
                |> value
                |> ignore

            let headers = store.Plugins.Scan(profile, token) |> wait |> value
            let order = store.PluginOrders.Read(workspace, profile, headers.Id) |> wait |> value

            let loot =
                store.LootForFixture(helper, fun state -> Ok state.Binding.Value.Evidence)

            if loot.Read().Metadata.IsSome then
                invalidOp "The fixture metadata must start absent."

            let before =
                (store.ModOrganization :> IModOrganization).Query(profile, query, None, None)
                |> wait
                |> value

            let layout = [ "files:fixture"; "plugin:skyrim.esm"; "files:other" ]

            (store.ModOrganization :> IModOrganization).SaveLoadOrderLayout(profile, layout)
            |> wait
            |> value

            loot.RefreshMetadata token |> Async.StartAsTask |> wait |> value |> ignore
            let proposal = loot.Preview(order, token) |> Async.StartAsTask |> wait |> value
            let replacement = store.Plugins.Scan(profile, token) |> wait |> value
            let service = LootService(loot, store.PluginOrders)

            let reply =
                service.ApplyLootSort(
                    ApplyLootSortRequest(
                        ProposalId = proposal.Id.ToString("N"),
                        HeadersId = proposal.HeadersId.ToString("N"),
                        Expected =
                            ModConductor.Protocol.V1.ProfileDataRef(
                                WorkspaceId = workspace.ToString("N"),
                                ProfileId = profile.ToString("N"),
                                ContextId = proposal.Expected.ContextId.ToString("N"),
                                Revision = uint64 proposal.Expected.Revision
                            )
                    ),
                    Unchecked.defaultof<_>
                )
                |> wait

            let transmitted = PluginOrderReply.Parser.ParseFrom(reply.ToByteArray())
            writer.WriteStartObject()

            let check (name: string) (passed: bool) =
                writer.WriteBoolean(name, passed)
                writer.Flush()

                if not passed then
                    invalidOp ("Fresh LOOT fixture failed: " + name)

            check
                "oneActionSaved"
                (transmitted.OutcomeCase = PluginOrderReply.OutcomeOneofCase.Order
                 && transmitted.Order.Saved)

            check "unchangedScanRetainsId" (replacement.Id = headers.Id)

            let after =
                (store.ModOrganization :> IModOrganization).Query(profile, query, None, None)
                |> wait
                |> value

            check "filePrecedenceEnablementAndOrganizationUnchanged" (before = after)

            check
                "mixedPositionsUnchanged"
                ((store.ModOrganization :> IModOrganization).LoadOrderLayout profile
                 |> wait
                 |> value = layout)

            let current =
                store.PluginOrders.Read(workspace, profile, replacement.Id) |> wait |> value

            let proposed = loot.Preview(current, token) |> Async.StartAsTask |> wait |> value

            let selected =
                after.Entries |> List.find (fun row -> row.Entry.Mod.Metadata.Name = "Textures")

            selection.Change(
                profile,
                after.SelectionRevision,
                [ selected.Entry.Mod.Id ],
                SelectionEdit.Enable false
            )
            |> wait
            |> value
            |> ignore

            let changed = store.Plugins.Scan(profile, token) |> wait |> value
            check "changedInputsReplaceSnapshot" (changed.Id <> replacement.Id)

            let refused =
                service.ApplyLootSort(
                    ApplyLootSortRequest(
                        ProposalId = proposed.Id.ToString("N"),
                        HeadersId = proposed.HeadersId.ToString("N"),
                        Expected =
                            ModConductor.Protocol.V1.ProfileDataRef(
                                WorkspaceId = workspace.ToString("N"),
                                ProfileId = profile.ToString("N"),
                                ContextId = proposed.Expected.ContextId.ToString("N"),
                                Revision = uint64 proposed.Expected.Revision
                            )
                    ),
                    Unchecked.defaultof<_>
                )
                |> wait

            check
                "changedInputsStillRefused"
                (refused.OutcomeCase = PluginOrderReply.OutcomeOneofCase.Problem
                 && refused.Problem.Kind = ProfileDataProblemKind.ProfileDataProblemStale)

            let remaining =
                store.PluginOrders.Read(workspace, profile, changed.Id) |> wait |> value

            check
                "staleApplyDoesNotChangeSavedOrder"
                (remaining.Reference = current.Reference
                 && remaining.View.Order = current.View.Order)

            writer.WriteBoolean("withBase", withBase)
            writer.WriteNumber("plugins", order.View.Order.Entries.Length)
            writer.WriteBoolean("replacementSameId", replacement.Id = headers.Id)

            writer.WriteBoolean(
                "replacementSameEvidence",
                replacement.Stamp = headers.Stamp
                && replacement.Entries = headers.Entries
                && replacement.Problems = headers.Problems
            )

            writer.WriteString("outcome", string transmitted.OutcomeCase)

            if transmitted.OutcomeCase = PluginOrderReply.OutcomeOneofCase.Problem then
                writer.WriteString("kind", string transmitted.Problem.Kind)
                writer.WriteString("detail", transmitted.Problem.Detail)

            writer.WriteEndObject()
            writer.Flush()

        writer.WriteEndArray()
