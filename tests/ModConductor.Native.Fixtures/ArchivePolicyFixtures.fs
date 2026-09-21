namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.Bethesda
open ModConductor.FilePlanning
open ModConductor.ProfileGameData
open ModConductor.Persistence
open ModConductor.Workspaces
open ModConductor.GameContexts
open System.Threading

module ArchivePolicyFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None
    let private check name value =
        if not value then
            invalidOp ("Archive policy fixture failed: " + name)

        value

    let private stamp =
        { WorkspaceId = Guid.NewGuid()
          ProfileId = Guid.NewGuid()
          SelectionRevision = 1L
          ContextRevision = 2L
          ExclusionRevision = 3L
          OutputRevision = 4L
          Versions = []
          Deployment = None }

    let private input explicit order =
        { Headers =
            { Id = Guid.NewGuid()
              Stamp = stamp
              ObservedAt = DateTimeOffset.UtcNow
              Stale = false
              Entries = []
              Problems = [] }
          Order =
            { Order = { Document = [||]; Entries = order }
              Issues = []
              Full = 0
              Light = 0
              FullLimit = 254 }
          Explicit = explicit
          Ini =
            { Identity = None
              Length = 0L
              Sha256 = "empty" } }

    let private candidate name format =
        { Name = name
          Source = None
          Format = Some format
          Problem = None }

    let observe (writer: Utf8JsonWriter) =
        writer.WriteStartObject "archivePolicy"

        let plain = "# retained\r\n[Archive]\r\nSResourceArchiveList=Old.bsa\r\nSResourceArchiveList2=Old2.bsa\r\n"

        let encoded =
            [ UTF8Encoding(false, true) :> Encoding
              UTF8Encoding(true, true) :> Encoding
              UnicodeEncoding(false, true, true) :> Encoding
              UnicodeEncoding(true, true, true) :> Encoding ]
            |> List.map (fun encoding ->
                Array.append (encoding.GetPreamble()) (encoding.GetBytes plain))

        let codecsRoundTrip =
            encoded
            |> List.forall (fun bytes ->
                let changed, receipt = Ini.applyArchives [ "One.bsa" ] (Some bytes)
                let visible = Ini.archiveEntries changed |> List.map _.Name
                visible = [ "One.bsa" ] && Ini.removeArchives receipt changed = Some bytes)

        writer.WriteBoolean(
            "supportedEncodingsAndStaleList2RoundTrip",
            check "supportedEncodingsAndStaleList2RoundTrip" codecsRoundTrip
        )

        let mutable duplicateRefused = false

        try
            Ini.applyArchives
                [ "One.bsa" ]
                (Some(Encoding.UTF8.GetBytes("[Archive]\nSResourceArchiveList=A.bsa\nSResourceArchiveList=B.bsa\n")))
            |> ignore
        with :? IOException ->
            duplicateRefused <- true

        writer.WriteBoolean(
            "duplicateOwnedKeyRefusesBeforeWrite",
            check "duplicateOwnedKeyRefusesBeforeWrite" duplicateRefused
        )

        let original =
            Array.append
                (Encoding.Unicode.GetPreamble())
                (Encoding.Unicode.GetBytes(
                    "; kept\r\n[Display]\r\nfGamma=1.0\r\n[Archive]\r\nSResourceArchiveList=Old.bsa\r\nOther=kept\r\n"
                ))

        let names =
            SkyrimArchives.required
            @ [ "QuietRivers.bsa" ]

        let applied, receipt = Ini.applyArchives names (Some original)
        let entries = Ini.archiveEntries applied
        let restored = Ini.removeArchives receipt applied

        writer.WriteBoolean(
            "iniEncodingCommentsAndRestoreAreByteExact",
            check
                "iniEncodingCommentsAndRestoreAreByteExact"
                (restored = Some original
                 && applied.AsSpan().StartsWith(Encoding.Unicode.GetPreamble())
                 && Encoding.Unicode.GetString(applied).Contains("Other=kept\r\n"))
        )

        writer.WriteBoolean(
            "longListsSplitInListThenList2Order",
            check
                "longListsSplitInListThenList2Order"
                (entries |> List.map _.Name = names
                 && entries |> List.exists (fun row -> row.Key = "SResourceArchiveList2"))
        )

        let changed =
            Encoding.Unicode.GetString(applied).Replace(
                "SResourceArchiveList=",
                "SResourceArchiveList=External.bsa, "
            )
            |> Encoding.Unicode.GetBytes
            |> fun bytes -> Array.append (Encoding.Unicode.GetPreamble()) bytes

        let mutable refused = false

        try
            Ini.removeArchives receipt changed |> ignore
        with :? IOException ->
            refused <- true

        writer.WriteBoolean(
            "changedIniRefusesRestore",
            check "changedIniRefusesRestore" refused
        )

        let explicit =
            [ { Name = "extra.BSA"
                Key = "SResourceArchiveList"
                Position = 0 }
              { Name = "EXTRA.bsa"
                Key = "SResourceArchiveList2"
                Position = 0 }
              { Name = "Missing.bsa"
                Key = "SResourceArchiveList2"
                Position = 1 } ]

        let order =
            [ { Name = "QuietRivers.esp"
                Enabled = Some true
                LockedIndex = None }
              { Name = "Off.esp"
                Enabled = Some false
                LockedIndex = None } ]

        let candidates =
            [ for name in SkyrimArchives.required -> candidate name "BSA v105"
              yield candidate "Extra.bsa" "BSA v105"
              yield candidate "QuietRivers.BSA" "BSA v105"
              yield candidate "QuietRivers - Textures.bsa" "BSA v105"
              yield candidate "Off.bsa" "BSA v105"
              yield candidate "Foreign.ba2" "BA2 v1 GNRL" ]

        let policy = SkyrimArchivePolicy.resolve (input explicit order) candidates
        let row name =
            policy.Entries
            |> List.find (fun row -> row.Name.Equals(name, StringComparison.OrdinalIgnoreCase))

        writer.WriteBoolean(
            "precedenceDedupAndAssociationsAreCaseInsensitive",
            check
                "precedenceDedupAndAssociationsAreCaseInsensitive"
                (policy.ExplicitNames = SkyrimArchives.required @ [ "extra.BSA"; "Missing.bsa" ]
                 && (row "QuietRivers.bsa").State = ArchivePolicyState.Active
                 && (row "Off.bsa").State = ArchivePolicyState.Inactive
                 && policy.Problems.Length = 2
                 && policy.BlockingProblems.IsEmpty)
        )

        writer.WriteBoolean(
            "effectiveArchivePositionsAreOneBased",
            check
                "effectiveArchivePositionsAreOneBased"
                ((row SkyrimArchives.required.Head).Position = Some 1
                 && (row SkyrimArchives.required[1]).Position = Some 2)
        )

        let missingRequired =
            candidates
            |> List.filter (fun value ->
                not (value.Name.Equals(SkyrimArchives.required.Head, StringComparison.OrdinalIgnoreCase)))
            |> SkyrimArchivePolicy.resolve (input [] order)

        writer.WriteBoolean(
            "missingRequiredArchiveBlocksApplication",
            check
                "missingRequiredArchiveBlocksApplication"
                (missingRequired.BlockingProblems
                 |> List.exists (fun problem -> problem.Contains SkyrimArchives.required.Head))
        )

        let colliding =
            candidate "QuietRivers.bsa" "BSA v105"
            :: candidate "QUIETRIVERS.BSA" "BSA v105"
            :: candidates
            |> SkyrimArchivePolicy.resolve (input [] order)

        writer.WriteBoolean(
            "caseCollidingAssociatedArchiveBlocksApplication",
            check
                "caseCollidingAssociatedArchiveBlocksApplication"
                (colliding.BlockingProblems
                 |> List.exists (fun problem ->
                     problem.Contains("QuietRivers.bsa", StringComparison.OrdinalIgnoreCase)
                     && problem.Contains("ignoring case", StringComparison.OrdinalIgnoreCase)))
        )

        let inspection = Inspection(Unchecked.defaultof<IArtifactSource>)
        let header (magic: string) (version: uint32) =
            use bytes = new MemoryStream()
            use binary = new BinaryWriter(bytes, Encoding.ASCII, true)
            binary.Write(Encoding.ASCII.GetBytes magic)
            binary.Write(version)
            binary.Flush()
            bytes.Position <- 0L
            inspection.IdentifyBethesdaOwnedStream bytes

        writer.WriteBoolean(
            "boundedHeaderIdentificationDoesNotEnumerateEntries",
            check
                "boundedHeaderIdentificationDoesNotEnumerateEntries"
                (header "BSA\000" 105u = "BSA v105")
        )

        let area =
            Directory.CreateDirectory(Path.Combine(Path.GetTempPath(), "mc-archive-policy-" + Guid.NewGuid().ToString("N"))).FullName

        try
            let workspaceRoot = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
            let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
            let data = Path.Combine(game, "Data")

            for name in OrderRules.baseFiles do
                File.WriteAllBytes(
                    Path.Combine(data, name),
                    BethesdaSamples.header 1u 1.7f [] false
                )

            let bsaHeader =
                use bytes = new MemoryStream()
                use binary = new BinaryWriter(bytes, Encoding.ASCII, true)
                binary.Write(Encoding.ASCII.GetBytes "BSA\000")
                binary.Write(105u)
                binary.Flush()
                bytes.ToArray()

            for name in SkyrimArchives.required do
                File.WriteAllBytes(Path.Combine(data, name), bsaHeader)

            File.WriteAllBytes(Path.Combine(data, "QuietRivers.bsa"), bsaHeader)

            let local =
                Path.Combine(
                    proton.CompatData,
                    "pfx",
                    "drive_c",
                    "users",
                    "steamuser",
                    "AppData",
                    "Local",
                    "Skyrim Special Edition"
                )

            Directory.CreateDirectory local |> ignore

            File.WriteAllText(
                Path.Combine(local, "plugins.txt"),
                OrderRules.baseFiles |> List.map ((+) "*") |> String.concat "\r\n"
            )

            let documents =
                Path.Combine(
                    proton.CompatData,
                    "pfx",
                    "drive_c",
                    "users",
                    "steamuser",
                    "Documents",
                    "My Games",
                    "Skyrim Special Edition"
                )

            Directory.CreateDirectory documents |> ignore

            let originalIni =
                Encoding.UTF8.GetBytes(
                    "; original\n[Archive]\nSResourceArchiveList=QuietRivers.bsa\n[Display]\nfGamma=1.0\n"
                )

            let documentsIni = Path.Combine(documents, "Skyrim.ini")
            File.WriteAllBytes(documentsIni, originalIni)
            let archivesTxt = Path.Combine(data, "archives.txt")
            File.WriteAllText(archivesTxt, "Bogus.bsa\n")

            let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
            use store = new OperationStore(Path.Combine(area, "state"))
            let workspaces = store.Workspaces :> IWorkspaceState

            let created =
                workspaces.Create(workspace, "Archive policy", StorageWorker.select workspaceRoot)
                |> wait
                |> result

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "Private" }
            )
            |> wait
            |> result
            |> ignore

            (store.GameContexts :> IGameContexts)
                .Save(workspace, profile, 0L, { GameId = GameId.SkyrimSpecialEditionSteam
                                                Path = game; Proton = Some proton })
            |> wait
            |> result
            |> ignore

            let profileApi = store.ProfileGameData
            let initial = profileApi.Read(workspace, profile) |> wait |> result

            profileApi.Edit(
                { Id = Guid.NewGuid()
                  Expected = initial.Reference
                  Options = { Settings = true; Saves = false }
                  InitialSaves = InitialSaves.Empty
                  DisabledFiles = DisabledFiles.Keep },
                ignore,
                token
            )
            |> wait
            |> result
            |> ignore

            let initialized = profileApi.Read(workspace, profile) |> wait |> result

            store.ApplyProfileDataAtCheckpoint(
                Guid.NewGuid(),
                workspace,
                profile,
                initialized.Reference.Revision,
                token,
                ignore
            )
            |> wait
            |> result
            |> ignore

            let globalOriginal =
                Array.append
                    (Encoding.Unicode.GetPreamble())
                    (Encoding.Unicode.GetBytes(
                        "; distinct global\r\n[Archive]\r\nSResourceArchiveList = GlobalOnly.bsa\r\n[Display]\r\nfGamma=1.25\r\n"
                    ))

            File.WriteAllBytes(documentsIni, globalOriginal)

            let headers = store.Plugins.Scan(profile, token) |> wait |> result
            let archiveApi = store.ArchivePolicies
            let first = archiveApi.Scan(workspace, profile, headers.Id, token) |> wait |> result

            let target = Path.Combine(data, SkyrimArchives.required.Head)
            let replacement = target + ".new"
            File.WriteAllBytes(replacement, bsaHeader)
            File.Move(replacement, target, true)

            let refused =
                archiveApi.Apply(Guid.NewGuid(), first.Reference, first.Snapshot.Id, ignore, token)
                |> wait

            let afterRefusal = profileApi.Read(workspace, profile) |> wait |> result
            writer.WriteBoolean(
                "changedArchiveRefusesBeforeReceipt",
                check
                    "changedArchiveRefusesBeforeReceipt"
                    (refused = Error ProfileDataError.Stale && afterRefusal.Pending.IsNone)
            )

            let headers = store.Plugins.Scan(profile, token) |> wait |> result
            let policy = archiveApi.Scan(workspace, profile, headers.Id, token) |> wait |> result
            let applied =
                archiveApi.Apply(Guid.NewGuid(), policy.Reference, policy.Snapshot.Id, ignore, token)
                |> wait
                |> result

            let privateIni = Path.Combine(applied.State.SettingsPath, "Skyrim.ini")
            let appliedBytes = File.ReadAllBytes privateIni

            writer.WriteBoolean(
                "applyUsesReceiptAndIgnoresArchivesTxt",
                check
                    "applyUsesReceiptAndIgnoresArchivesTxt"
                    (applied.Complete
                     && Ini.archiveEntries appliedBytes |> List.map _.Name = SkyrimArchives.required @ [ "QuietRivers.bsa" ]
                     && not (Encoding.UTF8.GetString(appliedBytes).Contains "Bogus.bsa")
                     && File.ReadAllText archivesTxt = "Bogus.bsa\n")
            )

            let restored =
                archiveApi.Restore(Guid.NewGuid(), applied.State.Reference, ignore, token)
                |> wait
                |> result

            writer.WriteBoolean(
                "divergentActiveDocumentsAndProfileRestoreExactOriginals",
                check
                    "divergentActiveDocumentsAndProfileRestoreExactOriginals"
                    (restored.Complete
                     && File.ReadAllBytes(privateIni) = originalIni
                     && File.ReadAllBytes(documentsIni) = globalOriginal)
            )

            File.Delete documentsIni
            let headers = store.Plugins.Scan(profile, token) |> wait |> result
            let policy = archiveApi.Scan(workspace, profile, headers.Id, token) |> wait |> result

            let createdGlobal =
                archiveApi.Apply(Guid.NewGuid(), policy.Reference, policy.Snapshot.Id, ignore, token)
                |> wait
                |> result

            let removedGlobal =
                archiveApi.Restore(Guid.NewGuid(), createdGlobal.State.Reference, ignore, token)
                |> wait
                |> result

            writer.WriteBoolean(
                "absentActiveDocumentsIniIsRemovedOnRestore",
                check
                    "absentActiveDocumentsIniIsRemovedOnRestore"
                    (createdGlobal.Complete && removedGlobal.Complete && not (File.Exists documentsIni))
            )

            let headers = store.Plugins.Scan(profile, token) |> wait |> result
            let policy = archiveApi.Scan(workspace, profile, headers.Id, token) |> wait |> result

            let changedGlobal =
                archiveApi.Apply(Guid.NewGuid(), policy.Reference, policy.Snapshot.Id, ignore, token)
                |> wait
                |> result

            let changedBytes =
                File.ReadAllText(documentsIni).Replace(
                    "SResourceArchiveList=",
                    "SResourceArchiveList=ExternallyChanged.bsa, "
                )
                |> Encoding.UTF8.GetBytes

            File.WriteAllBytes(documentsIni, changedBytes)

            let refusedGlobalRestore =
                archiveApi.Restore(Guid.NewGuid(), changedGlobal.State.Reference, ignore, token)
                |> wait
                |> result

            writer.WriteBoolean(
                "changedActiveDocumentsArchiveValueRefusesRestore",
                check
                    "changedActiveDocumentsArchiveValueRefusesRestore"
                    (not refusedGlobalRestore.Complete
                     && refusedGlobalRestore.Problem.IsSome
                     && File.ReadAllBytes(documentsIni) = changedBytes)
            )
        finally
            if Directory.Exists area then
                Directory.Delete(area, true)

        writer.WriteEndObject()
