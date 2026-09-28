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
        (copyName: string)
        (versionLabel: string)
        (remainingName: string)
        (now: DateTimeOffset)
        =
        let items: RemediationItem list =
            [ { Label = "Target file"
                Value = LogicalPath.display target }
              { Label = "Saved copy"
                Value = copyName + " · " + versionLabel }
              { Label = "Profile setting"
                Value = "Hide this copy for " + profileName } ]

        let identifiers: RemediationIdentifier list =
            [ { Label = "Mod ID"; Value = copy.ModId }
              { Label = "Version ID"
                Value = copy.VersionId }
              { Label = "Profile ID"
                Value = profileId } ]

        let view =
            { Id = Guid.NewGuid()
              SnapshotId = snapshotId
              FindingId = findingId
              WorkspaceId = workspace
              ProfileId = profileId
              ExpiresAt = now.AddMinutes Limits.previewMinutes
              Items = items
              Identifiers = identifiers
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
              Items =
                value.Paths
                |> List.map (fun path ->
                    { RemediationItem.Label = "Managed path"
                      Value = path })
              Identifiers =
                [ { RemediationIdentifier.Label = "Deployment restore ID"
                    Value = value.ReceiptId } ]
              Result = "Mod Conductor will continue the deployment restore." }

        { View = view
          Command = RemediationCommand.Recover(value.ReceiptId, value.Revision) }
