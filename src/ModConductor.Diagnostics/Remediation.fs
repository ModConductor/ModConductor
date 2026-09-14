namespace ModConductor.Diagnostics

open System
open System.Text
open ModConductor.Deployment
open ModConductor.FilePlanning
open ModConductor.Platform

[<RequireQualifiedAccess>]
type internal RemediationCommand =
    | Hide of Guid * ModConductor.DeploymentPlanning.ModFile * string
    | Recover of Guid * int64

[<Struct>]
type internal StoredPreview =
    { View: RemediationPreview
      Command: RemediationCommand }

module internal Remediation =
    let pathsBytes (paths: string list) =
        paths |> List.sumBy (fun path -> Encoding.UTF8.GetByteCount path + 8)

    let filePreview
        (snapshotId: Guid)
        (findingId: string)
        (workspace: Guid)
        (profileId: Guid)
        (profileName: string)
        (target: LogicalPath)
        (plan: Guid)
        (copy: ModConductor.DeploymentPlanning.ModFile)
        (remainingName: string)
        (now: DateTimeOffset)
        =
        let paths =
            [ LogicalPath.display target
              LogicalPath.display copy.Path
              profileName + " hidden files" ]

        let view =
            { Id = Guid.NewGuid()
              SnapshotId = snapshotId
              FindingId = findingId
              WorkspaceId = workspace
              ProfileId = profileId
              ExpiresAt = now.AddMinutes Limits.previewMinutes
              Paths = paths
              Result = "Mod Conductor will hide one file copy." }

        { View = view
          Command = RemediationCommand.Hide(plan, copy, remainingName) }

    let deploymentPreview
        (snapshotId: Guid)
        (findingId: string)
        (workspace: Guid)
        (profile: Guid)
        (value: DeploymentRecoveryPreview)
        (now: DateTimeOffset)
        =
        let view =
            { Id = Guid.NewGuid()
              SnapshotId = snapshotId
              FindingId = findingId
              WorkspaceId = workspace
              ProfileId = profile
              ExpiresAt = now.AddMinutes Limits.previewMinutes
              Paths = value.Paths
              Result = "Mod Conductor will continue the deployment restore." }

        { View = view
          Command = RemediationCommand.Recover(value.ReceiptId, value.Revision) }
