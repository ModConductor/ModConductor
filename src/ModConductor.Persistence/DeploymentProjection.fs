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
    let private readWith candidate connection transaction owner (expected: SourceStamp) token =
        let included path =
            candidate |> Option.forall (fun predicate -> predicate path)

        if FilePlanRows.stamp connection transaction expected.ProfileId <> Some expected then
            Error FilePlanError.Stale
        else
            let selected =
                GameContextRows.read
                    connection
                    transaction
                    owner
                    expected.WorkspaceId
                    expected.ProfileId

            let context =
                selected
                |> Result.toOption
                |> Option.bind _.Binding
                |> Option.bind (fun binding ->
                    let id fingerprint =
                        ModConductor.Deployment.DeploymentContextId.create
                            expected.WorkspaceId
                            expected.ProfileId
                            fingerprint

                    let current =
                        ModConductor.Deployment.DeploymentContextId.fingerprint binding.Evidence
                        |> id

                    DeploymentRows.context connection transaction current
                    |> Option.orElseWith (fun () ->
                        ModConductor.Deployment.DeploymentContextId.legacyFingerprint binding.Evidence
                        |> id
                        |> DeploymentRows.context connection transaction))

            match context with
            | None -> Ok GameProjection.empty
            | Some context when context.Pending.IsSome -> Error FilePlanError.Blocked
            | Some context ->
                match
                    GameContextRows.read
                        connection
                        transaction
                        owner
                        expected.WorkspaceId
                        expected.ProfileId
                with
                | Error _ -> Error FilePlanError.NotFound
                | Ok state ->
                    let evidence = state.Binding |> Option.map _.Evidence

                    let root =
                        context.Roots
                        |> List.tryFind (fun root -> root.Root.Id = expected.WorkspaceId)

                    match evidence, root with
                    | Some _, Some root when
                        (HostPath.value root.Directory.Path).Contains(
                            ".mc-game-views",
                            StringComparison.Ordinal
                        ) ->
                        // The selected installation is a source. Managed links live in the
                        // separate profile root and must not enter its source inventory.
                        Ok GameProjection.empty
                    | Some evidence, Some root when
                        evidence.DataIdentity = Some root.Directory.Identity
                        && evidence.DataPath = Some(HostPath.value root.Directory.Path)
                        ->
                        match context.Active, candidate with
                        | Some id, None ->
                            DeploymentRows.generation connection transaction context.Id id
                            |> Option.defaultWith (fun () ->
                                RecoveryFiles.fail "The active generation is unavailable.")
                            |> RecoveryFiles.verifyGenerationWith token
                        | _ -> ()

                        for link in
                            context.Links
                            |> List.filter (fun link ->
                                link.Target.Root = expected.WorkspaceId
                                && included link.Target.Path) do
                            if RecoveryFiles.observe context link.Target <> Some link.Entry then
                                RecoveryFiles.fail "An active deployment link changed."

                        let originals =
                            context.Originals
                            |> List.choose (fun original ->
                                if
                                    original.Target.Root = expected.WorkspaceId
                                    && included original.Target.Path
                                    && context.Links
                                       |> List.exists (fun link ->
                                           contains link.Target.Path original.Target.Path)
                                then
                                    if
                                        candidate.IsNone
                                        && not (
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

                                    let source: GameFileSource =
                                        { Root = root.Originals.Path
                                          RootIdentity = root.Originals.Identity
                                          Path =
                                            LogicalPath.create [ original.Backup ]
                                            |> Result.defaultWith (fun _ ->
                                                invalidOp "Invalid original name.")
                                          Identity = original.Entry.Identity }

                                    Some(original.Target.Path, source)
                                else
                                    None)
                            |> Map.ofList

                        Ok
                            { Directories =
                                context.Directories
                                |> List.filter (fun row ->
                                    row.Target.Root = expected.WorkspaceId
                                    && included row.Target.Path)
                                |> List.map (fun row -> row.Target.Path, row.Identity)
                                |> Map.ofList
                              Stamp = expected.Deployment
                              Links =
                                context.Links
                                |> List.filter (fun link ->
                                    link.Target.Root = expected.WorkspaceId
                                    && included link.Target.Path)
                                |> List.map (fun link ->
                                    { Path = link.Target.Path
                                      Entry = link.Entry })
                              Originals = originals }
                    | _ ->
                        Error(
                            FilePlanError.ContextUnavailable
                                "The deployment belongs to a different game installation."
                        )

    let read connection transaction owner expected token =
        readWith None connection transaction owner expected token

    let candidates predicate connection transaction owner expected token =
        readWith (Some predicate) connection transaction owner expected token
