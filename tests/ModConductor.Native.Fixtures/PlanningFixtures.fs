namespace ModConductor.Native.Fixtures

open System
open System.Text.Json
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning

module PlanningFixtures =
    let private id (value: int) =
        Guid.Parse(value.ToString().PadLeft(32, '0'))

    let private path (value: string) =
        match LogicalPath.create (value.Split('/') |> Array.toList) with
        | Ok path -> path
        | Error _ -> invalidOp "Invalid fixture path."

    let private root = id 1
    let private otherRoot = id 2

    let private mapping =
        { SourcePrefix = PlanPath.Root
          TargetRoot = root
          TargetPrefix = PlanPath.Root }

    let private payload value =
        { Id = id value
          Length = int64 value
          Sha256 = String('a', 64) }

    let private entry name content = { Path = path name; Payload = content }

    let private layer identity priority entries =
        { ModId = id identity
          Priority = priority
          Enabled = true
          Version =
            Some
                { Id = id (identity + 100)
                  ModId = id identity
                  Entries = entries
                  Origin = ModConductor.ModLibrary.VersionOrigin.RegisteredSource
                  NextOffset = None }
          Mappings = [ mapping ]
          Archives = [] }

    let private input layers =
        { Profile =
            { ProfileId = id 3
              Revision = 7L
              Complete = true
              Mods = layers }
          Roots =
            [ { Id = root
                Policy = TargetPolicy.windows } ]
          ReadOnly = []
          Writable = [] }

    let private ready value =
        match Planner.compute value with
        | PlanningResult.Ready plan -> plan
        | PlanningResult.Blocked _ -> invalidOp "Expected a resolved fixture plan."

    let private view value = ready value |> Planner.view

    let private hasIssue predicate value =
        match Planner.compute value with
        | PlanningResult.Ready _ -> false
        | PlanningResult.Blocked plan -> List.exists predicate plan.Issues

    let private modId contribution =
        match contribution.Source with
        | SourcePin.Mod(modId, _, _) -> modId
        | SourcePin.Snapshot(snapshot, _, _) -> snapshot

    let private sourcePayload contribution =
        match contribution.Source with
        | SourcePin.Mod(_, _, item) -> Some item.Payload
        | SourcePin.Snapshot _ -> None

    let private reportFiles (writer: Utf8JsonWriter) name (files: ResolvedFile list) =
        let origin (value: Contribution) =
            writer.WriteStartObject()
            writer.WriteString("layerId", value.LayerId)
            writer.WriteNumber("priority", value.Precedence.Priority)
            writer.WriteString("mappedPath", LogicalPath.display value.MappedTarget.Path)

            match value.Source with
            | SourcePin.Mod(modId, versionId, entry) ->
                writer.WriteString("modId", modId)
                writer.WriteString("versionId", versionId)
                writer.WriteString("sourcePath", LogicalPath.display entry.Path)
                writer.WriteString("payloadId", entry.Payload.Id)
                writer.WriteNumber("length", entry.Payload.Length)
                writer.WriteString("sha256", entry.Payload.Sha256)
            | SourcePin.Snapshot(snapshotId, generation, file) ->
                writer.WriteString("snapshotId", snapshotId)
                writer.WriteString("generation", generation)
                writer.WriteString("sourcePath", LogicalPath.display file.Path)
                writer.WriteNumber("length", SnapshotFile.length file)

                SnapshotFile.sha256 file
                |> Option.iter (fun value -> writer.WriteString("sha256", value))

            writer.WriteEndObject()

        writer.WriteStartArray(name: string)

        for file in files do
            writer.WriteStartObject()
            writer.WriteString("targetRoot", file.Target.Root)
            writer.WriteString("targetPath", LogicalPath.display file.Target.Path)

            let reason =
                match file.Reason with
                | WinnerReason.OnlyContribution -> "only contribution"
                | WinnerReason.HigherLayerTier -> "higher layer tier"
                | WinnerReason.HigherPriority -> "higher priority"

            writer.WriteString("reason", reason)
            writer.WritePropertyName("winner")
            origin file.Winner
            writer.WriteStartArray("alternatives")
            List.iter origin file.Alternatives
            writer.WriteEndArray()
            writer.WriteEndObject()

        writer.WriteEndArray()

    let observe (writer: Utf8JsonWriter) =
        writer.WriteStartObject("planning")
        let flag (name: string) value = writer.WriteBoolean(name, value)
        let shared = payload 90

        let low =
            layer 10 1 [ entry "Textures/shared.txt" shared; entry "old.txt" (payload 91) ]

        let high =
            layer 11 2 [ entry "textures/SHARED.txt" (payload 92); entry "textures/new.txt" shared ]

        let baseSnapshot =
            { Id = id 20
              Generation = "base-a"
              Kind = ReadOnlyLayerKind.Base
              Priority = 500
              Complete = true
              Files =
                [ { Path = path "Textures/shared.txt"
                    Identity =
                      SnapshotFileIdentity.Metadata
                          { Identity =
                              { Device = LinuxDevice(1u, 2u)
                                Low = 3UL
                                High = 0UL }
                            Length = 4L
                            Modified = DateTime.UnixEpoch } } ]
              Mappings = [ mapping ]
              Archives = [] }

        let secondary =
            { baseSnapshot with
                Id = id 21
                Kind = ReadOnlyLayerKind.Secondary
                Priority = -10
                Files =
                    baseSnapshot.Files
                    |> List.map (fun file ->
                        { file with
                            Identity = SnapshotFileIdentity.Content(4L, String('b', 64)) }) }

        let initial =
            { input [ low; high ] with
                ReadOnly = [ secondary; baseSnapshot ] }

        let retained = ready initial
        let original = Planner.view retained

        let winner =
            original.ReadOnlyFiles
            |> List.find (fun item -> item.Target.Path = path "textures/SHARED.txt")

        flag
            "layeredOverride"
            (modId winner.Winner = high.ModId
             && winner.Alternatives |> List.map modId = [ low.ModId; secondary.Id; baseSnapshot.Id ]
             && winner.Reason = WinnerReason.HigherPriority)

        flag
            "consistentDirectorySpelling"
            (original.Directories |> List.exists (fun item -> item.Path = path "textures")
             && original.ReadOnlyFiles
                |> List.filter (fun item ->
                    LogicalPath.display item.Target.Path |> fun name -> name.Contains('/'))
                |> List.forall (fun item ->
                    LogicalPath.components item.Target.Path |> List.head = "textures"))

        let disabled =
            { initial with
                Profile =
                    { initial.Profile with
                        Revision = 8L
                        Mods = [ low; { high with Enabled = false } ] } }

        let promoted = view disabled

        flag
            "disabledPromotes"
            (promoted.ReadOnlyFiles
             |> List.exists (fun item ->
                 modId item.Winner = low.ModId && item.Target.Path = path "Textures/shared.txt"))

        let updatedVersion =
            { high.Version.Value with
                Id = id 211
                Entries =
                    [ entry "textures/SHARED.txt" (payload 93); entry "textures/new.txt" shared ] }

        let updated =
            { initial with
                Profile =
                    { initial.Profile with
                        Mods =
                            [ low
                              { high with
                                  Version = Some updatedVersion } ] } }

        let revised = view updated

        flag
            "versionPinsRetained"
            (revised.Fingerprint <> original.Fingerprint
             && Planner.view retained = original
             && sourcePayload winner.Winner = Some(payload 92))

        flag
            "unchangedPayloadShared"
            (revised.ReadOnlyFiles
             |> List.find (fun item -> item.Target.Path = path "textures/new.txt")
             |> fun item -> sourcePayload item.Winner = Some shared)

        let reordered =
            { initial with
                ReadOnly = List.rev initial.ReadOnly
                Profile =
                    { initial.Profile with
                        Mods =
                            initial.Profile.Mods
                            |> List.rev
                            |> List.map (fun item ->
                                { item with
                                    Version =
                                        item.Version
                                        |> Option.map (fun version ->
                                            { version with
                                                Entries = List.rev version.Entries }) }) } }

        flag
            "canonicalEnumeration"
            (view reordered = original && Planner.checkCurrent retained reordered = Ok())

        flag
            "changedInputsRefused"
            (Planner.checkCurrent retained updated = Error CurrentInputProblem.ChangedInputs
             && Planner.checkCurrent retained disabled = Error CurrentInputProblem.ChangedInputs)

        writer.WriteString("retainedFingerprint", original.Fingerprint)
        writer.WriteString("newVersionFingerprint", revised.Fingerprint)

        let archive =
            { Container = path "pack.bsa"
              CapabilityId = "archive-index"
              CapabilityRevision = "declared-1" }

        let mapped =
            { layer
                  30
                  1
                  [ entry "Data/a.txt" shared
                    entry "Data/Special/b.txt" shared
                    entry "pack.bsa" (payload 94) ] with
                Mappings =
                    [ mapping
                      { mapping with
                          SourcePrefix = PlanPath.At(path "Data")
                          TargetPrefix = PlanPath.At(path "assets") }
                      { mapping with
                          SourcePrefix = PlanPath.At(path "Data/Special")
                          TargetRoot = otherRoot
                          TargetPrefix = PlanPath.Root } ]
                Archives = [ archive ] }

        let mappedInput =
            { input [ mapped ] with
                Roots =
                    [ { Id = root
                        Policy = TargetPolicy.linux }
                      { Id = otherRoot
                        Policy = TargetPolicy.windows } ] }

        let mappedPlan = ready mappedInput
        let mappedView = Planner.view mappedPlan

        flag
            "longestMappingAcrossRoots"
            (mappedView.ReadOnlyFiles |> List.map _.Target |> Set.ofList = Set.ofList
                [ { Root = root
                    Path = path "assets/a.txt" }
                  { Root = otherRoot
                    Path = path "b.txt" }
                  { Root = root; Path = path "pack.bsa" } ])

        flag
            "archiveRemainsContainer"
            (mappedView.ReadOnlyFiles
             |> List.find (fun item -> item.Target.Path = path "pack.bsa")
             |> fun item ->
                 item.Winner.Archives = [ archive ]
                 && sourcePayload item.Winner = Some(payload 94))

        let changedArchive =
            { mapped with
                Archives =
                    [ { archive with
                          CapabilityRevision = "declared-2" } ] }

        flag
            "archiveGenerationChangesInput"
            (Planner.checkCurrent
                mappedPlan
                { mappedInput with
                    Profile =
                        { mappedInput.Profile with
                            Mods = [ changedArchive ] } } = Error CurrentInputProblem.ChangedInputs)

        let exactOnly =
            { mapped with
                Mappings =
                    [ { mapping with
                          SourcePrefix = PlanPath.At(path "data") } ] }

        flag
            "sourceMappingIsOrdinal"
            (input [ exactOnly ]
             |> hasIssue (function
                 | PlanningIssue.UnmappedFile _ -> true
                 | _ -> false))

        let ambiguous =
            { mapped with
                Mappings = mapping :: mapped.Mappings }

        flag
            "ambiguousMappingBlocked"
            (input [ ambiguous ]
             |> hasIssue (function
                 | PlanningIssue.AmbiguousMapping _ -> true
                 | _ -> false))

        flag
            "missingRootBlocked"
            (input [ mapped ]
             |> hasIssue (function
                 | PlanningIssue.MissingTargetRoot found -> found = otherRoot
                 | _ -> false))

        let changedBase =
            { initial with
                ReadOnly =
                    [ { baseSnapshot with
                          Generation = "base-b" }
                      secondary ] }

        flag
            "baseGenerationChangesInput"
            (Planner.checkCurrent retained changedBase = Error CurrentInputProblem.ChangedInputs)

        let alias = layer 40 1 [ entry "case.txt" shared; entry "CASE.txt" (payload 95) ]

        flag
            "sameLayerAliasBlocked"
            (input [ alias ]
             |> hasIssue (function
                 | PlanningIssue.TargetAlias _ -> true
                 | _ -> false))

        flag
            "sensitiveNamesRemainDistinct"
            ((view
                { input [ alias ] with
                    Roots =
                        [ { Id = root
                            Policy = TargetPolicy.linux } ] })
                .ReadOnlyFiles.Length = 2)

        let directoryAlias =
            layer 41 1 [ entry "Case/a" shared; entry "case/b" (payload 95) ]

        flag
            "directoryAliasBlocked"
            (input [ directoryAlias ]
             |> hasIssue (function
                 | PlanningIssue.TargetAlias _ -> true
                 | _ -> false))

        let tied = { high with Priority = low.Priority }

        flag
            "competingTieBlocked"
            (input [ low; tied ]
             |> hasIssue (function
                 | PlanningIssue.PrecedenceTie _ -> true
                 | _ -> false))

        let dirTied =
            input [ layer 42 1 [ entry "Case/a" shared ]; layer 43 1 [ entry "case/b" shared ] ]

        flag
            "directorySpellingTieBlocked"
            (dirTied
             |> hasIssue (function
                 | PlanningIssue.DirectorySpellingTie _ -> true
                 | _ -> false))

        let structural =
            input
                [ layer 44 1 [ entry "folder" shared ]
                  layer 45 2 [ entry "folder/child" shared ] ]

        flag
            "fileDirectoryBlocked"
            (structural
             |> hasIssue (function
                 | PlanningIssue.FileDirectoryConflict _ -> true
                 | _ -> false))

        let unicode =
            input
                [ layer 46 1 [ entry "Cafe\u0301.txt" shared ]
                  layer 47 2 [ entry "Café.txt" (payload 96) ] ]

        let composed =
            { unicode with
                Roots =
                    [ { Id = root
                        Policy =
                          { TargetPolicy.linux with
                              Unicode = CanonicalComposition } } ] }

        flag
            "unicodePolicyControlsOverrides"
            ((view unicode).ReadOnlyFiles.Length = 2
             && (view composed).ReadOnlyFiles.Length = 1
             && (view composed).ReadOnlyFiles.Head.Alternatives.Length = 1)

        let invalidName = input [ layer 48 1 [ entry "CON.txt" shared ] ]

        flag
            "targetNamesValidated"
            (invalidName
             |> hasIssue (function
                 | PlanningIssue.InvalidTargetName _ -> true
                 | _ -> false))

        let nativeBackslash = input [ layer 49 1 [ entry "literal\\name" shared ] ]

        flag
            "nativeBackslashPreserved"
            ((view
                { nativeBackslash with
                    Roots =
                        [ { Id = root
                            Policy = TargetPolicy.linux } ] })
                 .ReadOnlyFiles.Head.Target.Path = path "literal\\name"
             && nativeBackslash
                |> hasIssue (function
                    | PlanningIssue.InvalidTargetName _ -> true
                    | _ -> false))

        let fileSink =
            { Id = id 60
              Target = WritableTarget.File(root, path "Textures/shared.txt") }

        let writableInput = { initial with Writable = [ fileSink ] }
        let writable = view writableInput

        let seededFile =
            match writable.Writable with
            | [ WritableProjection.File(_, _, Some seed) ] -> seed = winner
            | _ -> false

        flag
            "writableFileConsumesWinner"
            (seededFile
             && not (
                 writable.ReadOnlyFiles |> List.exists (fun item -> item.Winner = winner.Winner)
             ))

        let subtree =
            { Id = id 61
              Target = WritableTarget.Subtree(root, PlanPath.At(path "Textures")) }

        let treePlan = view { initial with Writable = [ subtree ] }

        flag
            "writableSubtreeKeepsSiblings"
            (treePlan.ReadOnlyFiles
             |> List.map (fun item -> LogicalPath.display item.Target.Path) = [ "old.txt" ]
             && match treePlan.Writable with
                | [ WritableProjection.Subtree(_, _, destination, seeds) ] ->
                    destination = PlanPath.At(path "textures")
                    && seeds.Length = 2
                    && seeds |> List.exists (fun seed -> seed = winner)
                | _ -> false)

        let whole =
            view
                { initial with
                    Writable =
                        [ { subtree with
                              Target = WritableTarget.Subtree(root, PlanPath.Root) } ] }

        flag
            "wholeRootWritableProjection"
            (whole.ReadOnlyFiles.IsEmpty
             && match whole.Writable with
                | [ WritableProjection.Subtree(_, _, PlanPath.Root, seeds) ] ->
                    seeds = original.ReadOnlyFiles
                | _ -> false)

        let empty =
            view
                { initial with
                    Writable =
                        [ { fileSink with
                              Target = WritableTarget.File(root, path "new-output.log") } ] }

        flag
            "emptySinkHasNoSeed"
            (empty.ReadOnlyFiles = original.ReadOnlyFiles
             && match empty.Writable with
                | [ WritableProjection.File(_, _, None) ] -> true
                | _ -> false)

        flag
            "overlappingSinksBlocked"
            ({ initial with
                Writable = [ subtree; fileSink ] }
             |> hasIssue (function
                 | PlanningIssue.OverlappingWritableTargets _ -> true
                 | _ -> false))

        flag
            "sinkStructureBlocked"
            ({ initial with
                Writable =
                    [ { fileSink with
                          Target = WritableTarget.File(root, path "textures") } ] }
             |> hasIssue (function
                 | PlanningIssue.WritableStructureConflict _ -> true
                 | _ -> false))

        flag
            "sinkCannotHideCollision"
            ({ structural with
                Writable =
                    [ { subtree with
                          Target = WritableTarget.Subtree(root, PlanPath.Root) } ] }
             |> hasIssue (function
                 | PlanningIssue.FileDirectoryConflict _ -> true
                 | _ -> false))

        flag
            "newSeedDoesNotAlterOldPlan"
            ((view { updated with Writable = [ fileSink ] }).Fingerprint
             <> writable.Fingerprint
             && view writableInput = writable)

        flag
            "writableDeclarationChangesInput"
            (Planner.checkCurrent retained writableInput = Error CurrentInputProblem.ChangedInputs)

        let emptySiblings =
            { input [] with
                Writable =
                    [ { Id = id 70
                        Target = WritableTarget.File(root, path "A/x") }
                      { Id = id 71
                        Target = WritableTarget.File(root, path "a/y") } ] }

        flag
            "emptySiblingSpellingBlocked"
            (emptySiblings
             |> hasIssue (function
                 | PlanningIssue.WritableDirectorySpellingTie _ -> true
                 | _ -> false))

        let sensitiveSiblings =
            view
                { emptySiblings with
                    Roots =
                        [ { Id = root
                            Policy = TargetPolicy.linux } ] }

        flag
            "sensitiveWritableDirectoriesRemainDistinct"
            (sensitiveSiblings.Directories |> List.map _.Path |> Set.ofList = Set.ofList
                [ path "A"; path "a" ]
             && sensitiveSiblings.Writable
                |> List.forall (function
                    | WritableProjection.File(_, _, None) -> true
                    | _ -> false))

        let subtreeSibling =
            { emptySiblings with
                Writable =
                    [ emptySiblings.Writable.Head
                      { Id = id 71
                        Target = WritableTarget.Subtree(root, PlanPath.At(path "a/y")) } ] }

        flag
            "subtreeSpellingParticipates"
            (subtreeSibling
             |> hasIssue (function
                 | PlanningIssue.WritableDirectorySpellingTie _ -> true
                 | _ -> false))

        let ordinaryAuthority =
            { emptySiblings with
                Profile =
                    { emptySiblings.Profile with
                        Mods = [ layer 72 1 [ entry "a/original" shared ] ] } }

        let authoritative = view ordinaryAuthority

        flag
            "ordinaryDirectorySpellingRemainsAuthoritative"
            (authoritative.Directories |> List.map _.Path = [ path "a" ]
             && authoritative.Writable
                |> List.forall (function
                    | WritableProjection.File(_, target, None) ->
                        LogicalPath.components target.Path |> List.head = "a"
                    | _ -> false)
             && authoritative.ReadOnlyFiles.Head.Target.Path = path "a/original")

        let nestedAuthority =
            view
                { ordinaryAuthority with
                    Writable =
                        [ { Id = id 70
                            Target = WritableTarget.File(root, path "A/B/x") }
                          { Id = id 71
                            Target = WritableTarget.File(root, path "a/B/y") } ] }

        flag
            "nestedWritableSpellingUsesCanonicalParents"
            (nestedAuthority.Directories |> List.map _.Path |> Set.ofList = Set.ofList
                [ path "a"; path "a/B" ]
             && nestedAuthority.Writable
                |> List.forall (function
                    | WritableProjection.File(_, target, None) ->
                        LogicalPath.components target.Path |> List.take 2 = [ "a"; "B" ]
                    | _ -> false))

        let consistentEmpty =
            view
                { subtreeSibling with
                    Writable =
                        [ { Id = id 70
                            Target = WritableTarget.File(root, path "A/x") }
                          { Id = id 71
                            Target = WritableTarget.Subtree(root, PlanPath.At(path "A/y")) } ] }

        flag
            "consistentEmptyDirectoryStructure"
            (consistentEmpty.Directories |> List.map _.Path |> Set.ofList = Set.ofList
                [ path "A"; path "A/y" ]
             && consistentEmpty.ReadOnlyFiles.IsEmpty)

        let emptyFingerprint =
            match Planner.compute emptySiblings with
            | PlanningResult.Blocked result -> result.Draft.Fingerprint
            | PlanningResult.Ready plan -> (Planner.view plan).Fingerprint

        writer.WriteString("emptySiblingFingerprint", emptyFingerprint)
        writer.WriteStartArray("authoritativeWritablePaths")

        for sink in authoritative.Writable do
            match sink with
            | WritableProjection.File(_, target, _) ->
                writer.WriteStringValue(LogicalPath.display target.Path)
            | WritableProjection.Subtree(_, _, _, _) -> invalidOp "Expected writable files."

        writer.WriteEndArray()

        let incomplete =
            { initial with
                Profile =
                    { initial.Profile with
                        Complete = false } }

        flag
            "incompleteSelectionRefused"
            (match Planner.checkCurrent retained incomplete with
             | Error(CurrentInputProblem.UnresolvedInputs issues) ->
                 List.contains PlanningIssue.IncompleteSelection issues
             | _ -> false)

        flag
            "partialManifestBlocked"
            (input
                [ { high with
                      Version =
                          Some
                              { high.Version.Value with
                                  NextOffset = Some 2 } } ]
             |> hasIssue (function
                 | PlanningIssue.IncompleteManifest _ -> true
                 | _ -> false))

        flag
            "missingVersionBlocked"
            (input [ { high with Version = None } ]
             |> hasIssue (function
                 | PlanningIssue.MissingVersion _ -> true
                 | _ -> false))

        flag
            "wrongModPinBlocked"
            (input [ { high with Version = low.Version } ]
             |> hasIssue (function
                 | PlanningIssue.WrongModVersion _ -> true
                 | _ -> false))

        flag
            "payloadIdentityConflictBlocked"
            (input
                [ low
                  layer
                      51
                      3
                      [ entry
                            "different"
                            { shared with
                                Length = shared.Length + 1L } ] ]
             |> hasIssue (function
                 | PlanningIssue.InconsistentPayload found -> found = shared.Id
                 | _ -> false))

        let invalidDigest =
            input [ layer 52 3 [ entry "bad" { shared with Sha256 = "incomplete" } ] ]

        flag
            "invalidContentBlocked"
            (invalidDigest
             |> hasIssue (function
                 | PlanningIssue.InvalidContent _ -> true
                 | _ -> false))

        writer.WriteString("mappedFingerprint", mappedView.Fingerprint)
        writer.WriteString("writableFingerprint", writable.Fingerprint)
        reportFiles writer "retainedFiles" original.ReadOnlyFiles
        reportFiles writer "promotedFiles" promoted.ReadOnlyFiles
        reportFiles writer "newVersionFiles" revised.ReadOnlyFiles

        reportFiles
            writer
            "writableInitialSeeds"
            (writable.Writable
             |> List.collect (function
                 | WritableProjection.File(_, _, Some seed) -> [ seed ]
                 | WritableProjection.File(_, _, None) -> []
                 | WritableProjection.Subtree(_, _, _, seeds) -> seeds))

        writer.WriteEndObject()
