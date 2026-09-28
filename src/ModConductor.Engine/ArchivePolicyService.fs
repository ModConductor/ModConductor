namespace ModConductor.Engine

open ModConductor.Bethesda
open ModConductor.ProfileGameData
open ModConductor.Protocol.V1

module internal ArchivePolicyWire =
    let private state =
        function
        | ModConductor.Bethesda.ArchivePolicyState.Active ->
            ModConductor.Protocol.V1.ArchivePolicyState.Active
        | ModConductor.Bethesda.ArchivePolicyState.Inactive ->
            ModConductor.Protocol.V1.ArchivePolicyState.Inactive
        | ModConductor.Bethesda.ArchivePolicyState.Unavailable ->
            ModConductor.Protocol.V1.ArchivePolicyState.Unavailable
        | ModConductor.Bethesda.ArchivePolicyState.Unsupported ->
            ModConductor.Protocol.V1.ArchivePolicyState.Unsupported

    let private entry (value: ModConductor.Bethesda.ArchivePolicyEntry) =
        let result =
            ModConductor.Protocol.V1.ArchivePolicyEntry(
                Name = value.Name,
                State = state value.State,
                Required = value.Required,
                Explicit = value.Explicit.IsSome,
                AssociatedPlugin = Option.defaultValue "" value.AssociatedPlugin,
                Format = Option.defaultValue "" value.Format,
                Problem = Option.defaultValue "" value.Problem
            )

        value.Position
        |> Option.iter (uint32 >> fun position -> result.Position <- position)

        value.Explicit
        |> Option.iter (fun explicit ->
            result.IniKey <- explicit.Key
            result.IniPosition <- uint32 explicit.Position)

        value.Source
        |> Option.iter (fun source ->
            result.Source <-
                BethesdaPluginWire.source
                    (ModConductor.Platform.LogicalPath.create [ value.Name ]
                     |> Result.defaultWith (fun _ ->
                         invalidOp "The archive source name is invalid."))
                    source)

        result.Reasons.AddRange value.Reasons
        result

    let reply =
        function
        | Error error -> ArchivePolicyReply(Problem = ProfileDataWire.problem error)
        | Ok(value: ProfileArchivePolicy) ->
            let result =
                ArchivePolicyView(
                    Reference = ProfileDataWire.reference value.Reference,
                    SnapshotId = value.Snapshot.Id.ToString("N"),
                    ObservedAtUnixMs = value.Snapshot.ObservedAt.ToUnixTimeMilliseconds(),
                    Stale = value.Snapshot.Stale,
                    Saved = value.Saved,
                    Applied = value.Applied,
                    Pending = value.Pending,
                    PendingProblem = Option.defaultValue "" value.Problem,
                    Invalidation = "Not available for this game"
                )

            result.Entries.AddRange(value.Snapshot.Entries |> Seq.map entry)
            result.Changes.AddRange value.Changes
            result.Problems.AddRange value.Snapshot.Problems
            result.BlockingProblems.AddRange value.Snapshot.BlockingProblems

            if result.CalculateSize() > 16 * 1024 * 1024 - 1024 then
                ArchivePolicyReply(
                    Problem =
                        ProfileDataWire.problem (
                            ProfileDataError.Unavailable
                                "The archive view exceeds the 16 MiB reply limit."
                        )
                )
            else
                ArchivePolicyReply(Policy = result)

type ArchivePolicyService(policies: IProfileArchivePolicies) =
    inherit ArchivePolicies.ArchivePoliciesBase()

    override _.ScanArchivePolicy(request, context) =
        task {
            let! result =
                policies.Scan(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId,
                    ModLibraryWire.id request.HeadersId,
                    context.CancellationToken
                )

            return ArchivePolicyWire.reply result
        }

    override _.ReadArchivePolicy(request, context) =
        task {
            let! result =
                policies.Read(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId,
                    ModLibraryWire.id request.SnapshotId,
                    context.CancellationToken
                )

            return ArchivePolicyWire.reply result
        }

    override _.ApplyArchivePolicy(request, output, context) =
        ProfileActionStream.send
            context
            output
            (fun (value: ModConductor.ProfileGameData.ProfileDataProgress) ->
                ProfileDataEvent(
                    Progress =
                        ModConductor.Protocol.V1.ProfileDataProgress(
                            Files = uint32 value.Files,
                            Bytes = uint64 value.Bytes
                        )
                ))
            ProfileDataWire.finished
            (fun progress ->
                policies.Apply(
                    ModLibraryWire.id request.Id,
                    ProfileDataWire.readReference request.Expected,
                    ModLibraryWire.id request.SnapshotId,
                    progress,
                    context.CancellationToken
                ))

    override _.RestoreArchivePolicy(request, output, context) =
        ProfileActionStream.send
            context
            output
            (fun (value: ModConductor.ProfileGameData.ProfileDataProgress) ->
                ProfileDataEvent(
                    Progress =
                        ModConductor.Protocol.V1.ProfileDataProgress(
                            Files = uint32 value.Files,
                            Bytes = uint64 value.Bytes
                        )
                ))
            ProfileDataWire.finished
            (fun progress ->
                policies.Restore(
                    ModLibraryWire.id request.Id,
                    ProfileDataWire.readReference request.Expected,
                    progress,
                    context.CancellationToken
                ))
