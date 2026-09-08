namespace ModConductor.Persistence

open System
open ModConductor.Platform
open ModConductor.FilePlanning
open ModConductor.DeploymentRecovery

[<AutoOpen>]
module private DeploymentProjectionHelpers =
    let contains parent child =
        let a, b = LogicalPath.components parent, LogicalPath.components child
        List.truncate a.Length b = a

module internal DeploymentProjection =
    let read connection transaction owner (expected: SourceStamp) token =
        if FilePlanRows.stamp connection transaction expected.ProfileId <> Some expected then
            Error FilePlanError.Stale
        else
            let selected =
                GameContextRows.read connection transaction owner expected.WorkspaceId

            let id =
                selected
                |> Result.toOption
                |> Option.bind _.Binding
                |> Option.map (fun binding ->
                    ModConductor.Deployment.DeploymentContextId.create
                        expected.WorkspaceId
                        (ModConductor.Deployment.DeploymentContextId.fingerprint binding.Evidence))

            match id |> Option.bind (DeploymentRows.context connection transaction) with
            | None -> Ok GameProjection.empty
            | Some context when context.Pending.IsSome -> Error FilePlanError.Blocked
            | Some context ->
                match GameContextRows.read connection transaction owner expected.WorkspaceId with
                | Error _ -> Error FilePlanError.NotFound
                | Ok state ->
                    let evidence = state.Binding |> Option.map _.Evidence

                    let root =
                        context.Roots
                        |> List.tryFind (fun root -> root.Root.Id = expected.WorkspaceId)

                    match evidence, root with
                    | Some evidence, Some root when
                        evidence.DataIdentity = Some root.Directory.Identity
                        && evidence.DataPath = Some(HostPath.value root.Directory.Path)
                        ->
                        match context.Active with
                        | Some id ->
                            DeploymentRows.generation connection transaction context.Id id
                            |> Option.defaultWith (fun () ->
                                RecoveryFiles.fail "The active generation is unavailable.")
                            |> RecoveryFiles.verifyGenerationWith token
                        | None -> ()

                        for link in context.Links do
                            if RecoveryFiles.observe context link.Target <> Some link.Entry then
                                RecoveryFiles.fail "An active deployment link changed."

                        let originals =
                            context.Originals
                            |> List.choose (fun original ->
                                if
                                    context.Links
                                    |> List.exists (fun link ->
                                        contains link.Target.Path original.Target.Path)
                                then
                                    if
                                        not (
                                            RecoveryFiles.originalMatches
                                                token
                                                context
                                                original
                                                true
                                        )
                                    then
                                        RecoveryFiles.fail "A preserved game file changed."

                                    if original.Entry.Kind <> EntryKind.RegularFile then
                                        RecoveryFiles.fail
                                            "A preserved directory cannot be read as a game file."

                                    Some(
                                        original.Target.Path,
                                        { Root = root.Originals.Path
                                          RootIdentity = root.Originals.Identity
                                          Path =
                                            LogicalPath.create [ original.Backup ]
                                            |> Result.defaultWith (fun _ ->
                                                invalidOp "Invalid original name.")
                                          Identity = original.Entry.Identity }
                                    )
                                else
                                    None)
                            |> Map.ofList

                        Ok
                            { Directories =
                                context.Directories
                                |> List.map (fun row -> row.Target.Path, row.Identity)
                                |> Map.ofList
                              Stamp = expected.Deployment
                              Links =
                                context.Links
                                |> List.map (fun link ->
                                    { Path = link.Target.Path
                                      Entry = link.Entry })
                              Originals = originals }
                    | _ ->
                        Error(
                            FilePlanError.ContextUnavailable
                                "The deployment belongs to a different game installation."
                        )
