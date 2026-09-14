namespace ModConductor.Engine

open Google.Protobuf
open ModConductor.Diagnostics

module DiagnosticWire =
    let fault =
        function
        | DiagnosticError.NotFound -> ModConductor.Protocol.V1.DiagnosticFault.NotFound
        | DiagnosticError.Expired -> ModConductor.Protocol.V1.DiagnosticFault.Expired
        | DiagnosticError.Stale -> ModConductor.Protocol.V1.DiagnosticFault.Stale
        | DiagnosticError.Foreign -> ModConductor.Protocol.V1.DiagnosticFault.Foreign
        | DiagnosticError.NotOwned -> ModConductor.Protocol.V1.DiagnosticFault.NotOwned
        | DiagnosticError.Busy -> ModConductor.Protocol.V1.DiagnosticFault.Busy
        | DiagnosticError.Oversized -> ModConductor.Protocol.V1.DiagnosticFault.Oversized
        | DiagnosticError.Unsupported -> ModConductor.Protocol.V1.DiagnosticFault.Unsupported
        | DiagnosticError.Cancelled -> ModConductor.Protocol.V1.DiagnosticFault.Cancelled

    let severity (value: ModConductor.Diagnostics.DiagnosticSeverity) =
        match value with
        | ModConductor.Diagnostics.DiagnosticSeverity.Information -> ModConductor.Protocol.V1.DiagnosticSeverity.Information
        | ModConductor.Diagnostics.DiagnosticSeverity.Warning -> ModConductor.Protocol.V1.DiagnosticSeverity.Warning
        | ModConductor.Diagnostics.DiagnosticSeverity.Error -> ModConductor.Protocol.V1.DiagnosticSeverity.Error

    let fixability (value: ModConductor.Diagnostics.Fixability) =
        match value with
        | ModConductor.Diagnostics.Fixability.NotFixable -> ModConductor.Protocol.V1.DiagnosticFixability.NotFixable
        | ModConductor.Diagnostics.Fixability.PreviewAvailable -> ModConductor.Protocol.V1.DiagnosticFixability.PreviewAvailable
        | ModConductor.Diagnostics.Fixability.Ready -> ModConductor.Protocol.V1.DiagnosticFixability.Ready
        | ModConductor.Diagnostics.Fixability.Refused -> ModConductor.Protocol.V1.DiagnosticFixability.Refused

    let correlationKind (value: ModConductor.Diagnostics.CorrelationKind) =
        match value with
        | ModConductor.Diagnostics.CorrelationKind.Launch -> "launch"
        | ModConductor.Diagnostics.CorrelationKind.ModFiles -> "mod-files"
        | ModConductor.Diagnostics.CorrelationKind.GameSetup -> "game-setup"
        | ModConductor.Diagnostics.CorrelationKind.Deployment -> "deployment"
        | ModConductor.Diagnostics.CorrelationKind.Profile -> "profile"
        | ModConductor.Diagnostics.CorrelationKind.Action -> "action"

    let finding (value: ModConductor.Diagnostics.DiagnosticFinding) =
        let result =
            ModConductor.Protocol.V1.DiagnosticFinding(
                Id = value.Id,
                Code = value.Code,
                Severity = severity value.Severity,
                WorkspaceName = value.WorkspaceName,
                ProfileName = value.ProfileName,
                GameName = value.GameName,
                Title = value.Title,
                Summary = value.Summary,
                Area = value.Area,
                NextAction = value.NextAction,
                Fixability = fixability value.Fixability,
                FixDetail = value.FixDetail
            )

        value.Detail |> Option.iter (fun detail -> result.Detail <- detail)

        result.Evidence.AddRange(
            value.Evidence
            |> Seq.map (fun item -> ModConductor.Protocol.V1.DiagnosticEvidence(Label = item.Label, Value = item.Value))
        )

        result.Correlations.AddRange(
            value.Correlations
            |> Seq.map (fun item ->
                let result =
                    ModConductor.Protocol.V1.DiagnosticCorrelation(
                        Kind = correlationKind item.Kind,
                        Id = item.Id.ToString "N"
                    )

                item.Revision |> Option.iter (fun revision -> result.Revision <- uint64 revision)
                result)
        )

        result

    let snapshotReply (result: Result<ModConductor.Diagnostics.DiagnosticSnapshot, DiagnosticError>) =
        match result with
        | Error error -> ModConductor.Protocol.V1.DiagnosticSnapshotReply(Fault = fault error)
        | Ok value ->
            let snapshot =
                ModConductor.Protocol.V1.DiagnosticSnapshot(
                    Id = value.Id.ToString "N",
                    WorkspaceId = value.WorkspaceId.ToString "N",
                    ProfileId = value.ProfileId.ToString "N",
                    CapturedAt = value.CapturedAt.ToString "O"
                )

            snapshot.Findings.AddRange(value.Findings |> Seq.map finding)
            ModConductor.Protocol.V1.DiagnosticSnapshotReply(Snapshot = snapshot)

    let previewReply (result: Result<ModConductor.Diagnostics.RemediationPreview, DiagnosticError>) =
        match result with
        | Error error -> ModConductor.Protocol.V1.DiagnosticPreviewReply(Fault = fault error)
        | Ok value ->
            let preview =
                ModConductor.Protocol.V1.DiagnosticPreview(
                    Id = value.Id.ToString "N",
                    SnapshotId = value.SnapshotId.ToString "N",
                    ProblemId = value.FindingId,
                    ExpiresAt = value.ExpiresAt.ToString "O",
                    Result = value.Result
                )

            preview.Items.AddRange(
                value.Items
                |> Seq.map (fun item ->
                    ModConductor.Protocol.V1.DiagnosticRemediationItem(
                        Label = item.Label,
                        Value = item.Value
                    ))
            )

            preview.Identifiers.AddRange(
                value.Identifiers
                |> Seq.map (fun item ->
                    ModConductor.Protocol.V1.DiagnosticRemediationIdentifier(
                        Label = item.Label,
                        Value = item.Value.ToString "N"
                    ))
            )
            ModConductor.Protocol.V1.DiagnosticPreviewReply(Preview = preview)

    let applyReply (result: Result<ModConductor.Diagnostics.RemediationResult, DiagnosticError>) =
        match result with
        | Error error -> ModConductor.Protocol.V1.DiagnosticApplyReply(Fault = fault error)
        | Ok value ->
            let result =
                ModConductor.Protocol.V1.DiagnosticApplyResult(
                    PreviewId = value.PreviewId.ToString "N",
                    Complete = value.Complete,
                    Result = value.Result
                )

            value.Detail |> Option.iter (fun detail -> result.Detail <- detail)
            ModConductor.Protocol.V1.DiagnosticApplyReply(Result = result)

    let supportReply (result: Result<ModConductor.Diagnostics.SupportReport, DiagnosticError>) =
        match result with
        | Error error -> ModConductor.Protocol.V1.DiagnosticSupportReply(Fault = fault error)
        | Ok value ->
            ModConductor.Protocol.V1.DiagnosticSupportReply(
                Report =
                    ModConductor.Protocol.V1.DiagnosticSupportReport(
                        FileName = value.FileName,
                        Content = ByteString.CopyFrom value.Content
                    )
            )
