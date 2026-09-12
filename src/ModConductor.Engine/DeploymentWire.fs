namespace ModConductor.Engine

open System
open System.Security.Cryptography
open System.Text
open ModConductor
open ModConductor.Deployment

module internal DeploymentWire =
    let token = SourceIdentity.token

    let fault error =
        let code, detail =
            match error with
            | DeploymentError.NotFound ->
                Protocol.V1.DeploymentFaultCode.DeploymentFaultNotFound,
                "The deployment record is unavailable."
            | DeploymentError.Busy ->
                Protocol.V1.DeploymentFaultCode.DeploymentFaultBusy,
                "Wait for the current operation."
            | DeploymentError.Stale ->
                Protocol.V1.DeploymentFaultCode.DeploymentFaultStale,
                "The prepared plan is out of date. Prepare it again."
            | DeploymentError.Cancelled ->
                Protocol.V1.DeploymentFaultCode.DeploymentFaultCancelled,
                "The operation was cancelled. Check the deployment before continuing."
            | DeploymentError.Blocked text ->
                Protocol.V1.DeploymentFaultCode.DeploymentFaultBlocked, text
            | DeploymentError.Unavailable text ->
                Protocol.V1.DeploymentFaultCode.DeploymentFaultUnavailable, text

        Protocol.V1.DeploymentFault(Code = code, Detail = detail)

    let profile (value: DeploymentProfile) =
        Protocol.V1.DeploymentProfile(
            Id = value.Id.ToString("N"),
            Name = value.Name,
            Revision = uint64 value.Revision,
            EnabledMods = uint32 value.EnabledMods
        )

    let saved (value: SavedDeployment) =
        let result =
            Protocol.V1.SavedDeployment(
                Id = value.Id.ToString("N"),
                Known = value.Known,
                Active = value.Active,
                Fingerprint = value.Fingerprint,
                CanRestore = value.CanRestore
            )

        value.Unavailable |> Option.iter (fun reason -> result.Unavailable <- reason)

        value.PreparedAt
        |> Option.iter (fun time -> result.PreparedAtUnixMs <- time.ToUnixTimeMilliseconds())

        value.Profile |> Option.iter (fun value -> result.Profile <- profile value)
        result

    let stateReply =
        function
        | Error error -> Protocol.V1.DeploymentStateReply(Fault = fault error)
        | Ok(value: DeploymentStatus) ->
            let result =
                Protocol.V1.DeploymentState(
                    WorkspaceId = value.WorkspaceId.ToString("N"),
                    Revision = uint64 value.Revision,
                    SourceToken = token value.Sources
                )

            value.Active |> Option.iter (fun value -> result.Active <- saved value)

            value.PendingReceipt
            |> Option.iter (fun id -> result.PendingReceipt <- id.ToString("N"))

            Protocol.V1.DeploymentStateReply(State = result)

    let savedReply =
        function
        | Error error -> Protocol.V1.SavedDeploymentsReply(Fault = fault error)
        | Ok(value: SavedDeploymentPage) ->
            let result = Protocol.V1.SavedDeploymentsPage()
            result.Entries.AddRange(value.Entries |> Seq.map saved)

            value.NextBefore
            |> Option.iter (fun before -> result.NextBefore <- uint64 before)

            Protocol.V1.SavedDeploymentsReply(Page = result)

    let preparedReply =
        function
        | Error error -> Protocol.V1.PreparedDeploymentReply(Fault = fault error)
        | Ok(value: PreparedDeployment) ->
            let result =
                Protocol.V1.PreparedDeployment(
                    Id = value.Id.ToString("N"),
                    WorkspaceId = value.WorkspaceId.ToString("N"),
                    Fingerprint = value.Fingerprint,
                    SourceToken = token value.Sources,
                    WritableFiles = uint32 value.WritableFiles,
                    ChangedPaths = uint32 value.ChangedPaths,
                    PreservedOriginals = uint32 value.PreservedOriginals,
                    ManagedLinks = uint32 value.ManagedLinks,
                    CopiedBytes = uint64 value.CopiedBytes,
                    RequiredBytes = uint64 value.RequiredBytes
                )

            value.Profile |> Option.iter (fun value -> result.Profile <- profile value)
            Protocol.V1.PreparedDeploymentReply(Prepared = result)

    let phase =
        function
        | DeploymentPhase.Preparing -> Protocol.V1.DeploymentPhase.Preparing
        | DeploymentPhase.Applying -> Protocol.V1.DeploymentPhase.Applying
        | DeploymentPhase.Restoring -> Protocol.V1.DeploymentPhase.Restoring
        | DeploymentPhase.Complete -> Protocol.V1.DeploymentPhase.Complete
        | DeploymentPhase.Restored -> Protocol.V1.DeploymentPhase.Restored
        | DeploymentPhase.Blocked -> Protocol.V1.DeploymentPhase.Blocked

    let progress (value: DeploymentProgress) =
        Protocol.V1.DeploymentProgress(
            Phase = phase value.Phase,
            Completed = uint32 value.Completed,
            Total = uint32 value.Total,
            Bytes = uint64 value.Bytes
        )

    let receiptReply =
        function
        | Error error -> Protocol.V1.DeploymentReceiptReply(Fault = fault error)
        | Ok(value: DeploymentReceipt) ->
            let result =
                Protocol.V1.DeploymentReceipt(
                    Id = value.Id.ToString("N"),
                    WorkspaceId = value.WorkspaceId.ToString("N"),
                    Revision = uint64 value.Revision,
                    Phase = phase value.Phase,
                    Proposed = value.Proposed.ToString("N"),
                    Completed = uint32 value.Completed,
                    Total = uint32 value.Total,
                    Detail = value.Detail
                )

            value.Previous |> Option.iter (fun id -> result.Previous <- id.ToString("N"))
            Protocol.V1.DeploymentReceiptReply(Receipt = result)
