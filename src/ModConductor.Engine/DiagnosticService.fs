namespace ModConductor.Engine

open ModConductor.Diagnostics
open ModConductor.Protocol.V1

module private DiagnosticRequest =
    let read (value: ModConductor.Protocol.V1.DiagnosticRequest) =
        if value.HasDeploymentId <> value.HasDeploymentRevision then
            ModLibraryWire.reject "The deployment reference is incomplete."

        { WorkspaceId = ModLibraryWire.id value.WorkspaceId
          ProfileId = ModLibraryWire.id value.ProfileId
          FileSnapshotId =
            if value.HasFileSnapshotId then
                Some(ModLibraryWire.id value.FileSnapshotId)
            else
                None
          PluginSnapshotId =
            if value.HasPluginSnapshotId then
                Some(ModLibraryWire.id value.PluginSnapshotId)
            else
                None
          DeploymentReceipt =
            if value.HasDeploymentId then
                Some(
                    ModLibraryWire.id value.DeploymentId,
                    ModLibraryWire.number value.DeploymentRevision
                )
            else
                None }

type DiagnosticService(diagnostics: IDiagnostics) =
    inherit DiagnosticOperations.DiagnosticOperationsBase()

    override _.CheckDiagnostics(request, context) =
        task {
            let! result =
                diagnostics.Check(DiagnosticRequest.read request, context.CancellationToken)

            return DiagnosticWire.snapshotReply result
        }

    override _.PreviewDiagnosticChange(request, context) =
        task {
            let! result =
                diagnostics.Preview(
                    ModLibraryWire.id request.SnapshotId,
                    request.ProblemId,
                    context.CancellationToken
                )

            return DiagnosticWire.previewReply result
        }

    override _.ApplyDiagnosticChange(request, context) =
        task {
            let! result =
                diagnostics.Apply(ModLibraryWire.id request.PreviewId, context.CancellationToken)

            return DiagnosticWire.applyReply result
        }

    override _.ExportDiagnosticSupport(request, context) =
        task {
            let! result =
                diagnostics.Export(ModLibraryWire.id request.SnapshotId, context.CancellationToken)

            return DiagnosticWire.supportReply result
        }
