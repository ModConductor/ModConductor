namespace ModConductor.Engine

open System
open Grpc.Core
open ModConductor.Loot
open ModConductor.ProfileGameData
open ModConductor.Protocol.V1

module internal LootWire =
    let metadata (value: LootMetadata) =
        LootMetadataState(
            Revision = value.Revision,
            MasterlistCommit = value.MasterlistCommit,
            PreludeCommit = value.PreludeCommit,
            MasterlistSha256 = value.MasterlistSha256,
            PreludeSha256 = value.PreludeSha256,
            FetchedUnixMs = value.FetchedAt.ToUnixTimeMilliseconds()
        )

    let proposal (value: LootProposal) =
        let result =
            LootSortProposal(
                Id = value.Id.ToString("D"),
                Expected = ProfileDataWire.reference value.Expected,
                HeadersId = value.HeadersId.ToString("D"),
                CreatedUnixMs = value.CreatedAt.ToUnixTimeMilliseconds(),
                Metadata = metadata value.Metadata,
                HelperVersion = value.HelperVersion,
                LiblootVersion = value.LiblootVersion,
                LiblootRevision = value.LiblootRevision
            )

        result.Current.AddRange value.Current
        result.Sorted.AddRange value.Sorted

        for move in value.Moves do
            result.Moves.Add(
                LootSortMove(
                    Plugin = move.Plugin,
                    Current = move.Current,
                    Proposed = move.Proposed,
                    Reason = move.Reason
                )
            )

        for message in value.Messages do
            result.Messages.Add(
                LootSortMessage(
                    Plugin = Option.defaultValue "" message.Plugin,
                    Level = message.Level,
                    Text = message.Text
                )
            )

        result

    let state (value: ModConductor.Loot.LootState) =
        ModConductor.Protocol.V1.LootState(
            CapabilityId = value.CapabilityId,
            Available = value.Available,
            Reason = Option.defaultValue "" value.Reason,
            Metadata = (value.Metadata |> Option.map metadata |> Option.toObj),
            Proposal = (value.Proposal |> Option.map proposal |> Option.toObj)
        )

    let problem =
        function
        | LootError.Busy -> LootProblem(Kind = LootProblemKind.Busy, Detail = "LOOT is busy.")
        | LootError.Stale ->
            LootProblem(
                Kind = LootProblemKind.Stale,
                Detail = "The plugin order changed. Refresh it."
            )
        | LootError.Cancelled ->
            LootProblem(Kind = LootProblemKind.Cancelled, Detail = "The LOOT action was cancelled.")
        | LootError.Unsupported detail ->
            LootProblem(Kind = LootProblemKind.Unsupported, Detail = detail)
        | LootError.MetadataUnavailable detail ->
            LootProblem(Kind = LootProblemKind.Metadata, Detail = detail)
        | LootError.HelperUnavailable detail ->
            LootProblem(Kind = LootProblemKind.Helper, Detail = detail)
        | LootError.InvalidResponse detail ->
            LootProblem(Kind = LootProblemKind.Response, Detail = detail)

    let reply =
        function
        | Ok value -> LootStateReply(State = state value)
        | Error error -> LootStateReply(Problem = problem error)

type LootService(loot: ILootSorting, orders: IProfilePluginOrders) =
    inherit LootSorting.LootSortingBase()

    override _.ReadLootState(_, _) =
        task { return LootWire.reply (Ok(loot.Read())) }

    override _.PreviewLootSort(request, context) =
        task {
            let! current =
                orders.Read(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId,
                    ModLibraryWire.id request.HeadersId
                )

            match current with
            | Error error ->
                return
                    LootWire.reply (
                        Error(
                            match error with
                            | ProfileDataError.Busy -> LootError.Busy
                            | ProfileDataError.Stale -> LootError.Stale
                            | ProfileDataError.Cancelled -> LootError.Cancelled
                            | ProfileDataError.NotFound ->
                                LootError.Unsupported "The selected profile was not found."
                            | ProfileDataError.Invalid detail
                            | ProfileDataError.Unavailable detail
                            | ProfileDataError.Conflict detail -> LootError.Unsupported detail
                        )
                    )
            | Ok current ->
                let! result = loot.Preview(current, context.CancellationToken) |> Async.StartAsTask

                return result |> Result.map (fun _ -> loot.Read()) |> LootWire.reply
        }

    override _.DismissLootSort(request, _) =
        task {
            loot.Dismiss(ModLibraryWire.id request.ProposalId)
            return LootWire.reply (Ok(loot.Read()))
        }

    override _.RefreshLootMetadata(_, context) =
        task {
            let! result = loot.RefreshMetadata context.CancellationToken |> Async.StartAsTask
            return result |> Result.map (fun _ -> loot.Read()) |> LootWire.reply
        }

    override _.ApplyLootSort(request, _) =
        task {
            let id = ModLibraryWire.id request.ProposalId
            let expected = ProfileDataWire.readReference request.Expected
            let headers = ModLibraryWire.id request.HeadersId

            match loot.ValidateApply(id, expected, headers) with
            | Error _ -> return PluginOrderWire.reply (Error ProfileDataError.Stale)
            | Ok names ->
                let! result = orders.ApplyExactOrder(expected, headers, names)

                match result with
                | Ok _ -> loot.Applied id
                | Error _ -> ()

                return PluginOrderWire.reply result
        }
