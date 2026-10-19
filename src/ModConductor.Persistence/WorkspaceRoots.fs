namespace ModConductor.Persistence

open System
open ModConductor.Platform

[<RequireQualifiedAccess>]
type RootCreationPhase =
    | Intent
    | Observed
    | Complete
    | Unresolved

[<RequireQualifiedAccess>]
type WorkspaceFailure =
    | NotFound
    | StaleRevision
    | IdentityConflict
    | Busy
    | InvalidRoot

type WorkspaceRoot =
    { Id: Guid
      Path: HostPath
      Identity: FileIdentity
      Revision: int64 }

type RootCreationReceipt =
    { Workspace: WorkspaceRoot
      Revision: int64
      Phase: RootCreationPhase
      MarkerIdentity: FileIdentity option
      Detail: string }

type internal RootCreationRow =
    { Receipt: RootCreationReceipt
      Owner: string
      Busy: bool
      Abandoned: bool
      Marker: Guid }

module internal WorkspaceRootFiles =
    let contents row =
        System.Text.Encoding.UTF8.GetBytes(
            "ModConductor root 1\n"
            + row.Receipt.Workspace.Id.ToString("N")
            + "\n"
            + row.Marker.ToString("N")
            + "\n"
        )

    let current row =
        if row.Receipt.Phase <> RootCreationPhase.Complete then
            row
        else
            match RootIdentityFile.observe row.Receipt.Workspace.Path (contents row) with
            | Some(rootIdentity, markerIdentity) ->
                { row with
                    Receipt =
                        { row.Receipt with
                            Workspace =
                                { row.Receipt.Workspace with
                                    Identity = rootIdentity }
                            MarkerIdentity = Some markerIdentity } }
            | None -> raise (System.IO.IOException "The workspace ownership marker changed.")
