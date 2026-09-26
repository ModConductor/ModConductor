namespace ModConductor.Native.Fixtures

open System
open System.Text.Json
open ModConductor.DeploymentPlanning
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.FilePlanning

module FileVisibilityFixtures =
    let observe (writer: Utf8JsonWriter) =
        let path (text: string) =
            LogicalPath.create (text.Split('/') |> Array.toList) |> StorageWorker.result

        let root, profile, low, high =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let lowVersion, highVersion = Guid.NewGuid(), Guid.NewGuid()

        let mapping =
            { SourcePrefix = PlanPath.Root
              TargetRoot = root
              TargetPrefix = PlanPath.Root }

        let entry name =
            { Path = path name
              Payload =
                { Id = Guid.NewGuid()
                  Length = 3L
                  Sha256 = String('a', 64) } }

        let layer id version priority entries =
            { ModId = id
              Priority = priority
              Enabled = true
              Version =
                Some
                    { Id = version
                      ModId = id
                      Entries = entries
                      Origin = ModConductor.ModLibrary.VersionOrigin.RegisteredSource
                      NextOffset = None }
              Mappings = [ mapping ]
              Archives = [] }

        let input layers =
            { Profile =
                { ProfileId = profile
                  Revision = 1L
                  Complete = true
                  Mods = layers }
              Roots =
                [ { Id = root
                    Policy = TargetPolicy.windows } ]
              ReadOnly = []
              Writable = [] }

        let lower = entry "textures/stone.txt"
        let upper = entry "Textures/Stone.txt"

        let source =
            input [ layer low lowVersion 0 [ lower ]; layer high highVersion 1 [ upper ] ]

        let original =
            Visibility.prepare
                { Planning = source
                  Hidden = Set.empty }

        let copy =
            { ModId = high
              VersionId = highVersion
              Path = upper.Path }

        let hidden = Visibility.setHidden copy true original |> StorageWorker.result

        let fresh =
            Visibility.prepare
                { Planning = source
                  Hidden = Set.singleton copy }

        let winner state =
            Visibility.files state |> Map.toList |> List.exactlyOne

        writer.WriteStartObject("fileVisibility")

        writer.WriteBoolean(
            "incrementalPreservesCanonicalTargets",
            fst (winner original) = fst (winner hidden)
            && snd (winner hidden) = snd (winner fresh)
            && Visibility.fingerprint hidden = Visibility.fingerprint fresh
        )

        writer.WriteBoolean(
            "retainedOriginalIsUnchanged",
            match (snd (winner original)).Value.Winner.Source with
            | SourcePin.Mod(id, _, _) -> id = high
            | SourcePin.Snapshot _ -> false
        )

        let aliasInput = input [ layer high highVersion 1 [ upper; lower ] ]

        let blocked =
            Visibility.prepare
                { Planning = aliasInput
                  Hidden = Set.empty }

        let stillBlocked = Visibility.setHidden copy true blocked |> StorageWorker.result

        writer.WriteBoolean(
            "hideCannotResolveInputAliases",
            match Visibility.original blocked, Visibility.original stillBlocked with
            | PlanningResult.Blocked before, PlanningResult.Blocked after ->
                before.Issues = after.Issues && not before.Issues.IsEmpty
            | _ -> false
        )

        writer.WriteBoolean(
            "unknownCopyCannotCreateRule",
            Visibility.setHidden { copy with VersionId = Guid.NewGuid() } true original
            |> Result.isError
        )

        let longPath =
            LogicalPath.create ((List.replicate 60 (String('界', 50))) @ [ "copy.txt" ])
            |> StorageWorker.result

        let changes =
            [ for id in List.rev [ 1L .. 64L ] ->
                  { Id = id
                    Copy =
                      { ModId = high
                        VersionId = highVersion
                        Path = longPath }
                    Hidden = id % 2L = 0L
                    BeforeHidden = id % 2L <> 0L
                    ProfileId = profile
                    BeforeFingerprint = String('a', 64)
                    AfterFingerprint = String('b', 64)
                    RecordedAt = DateTimeOffset.UnixEpoch.AddSeconds(float id) } ]

        let first =
            changes
            |> List.truncate 32
            |> PlanSnapshotPaging.historyPage
            |> StorageWorker.result

        let collected = ResizeArray<FileChange>(first.Changes)
        let mutable next = first.NextBeforeId

        while next.IsSome do
            let before = next.Value

            let page =
                changes
                |> List.filter (fun change -> change.Id < before)
                |> List.truncate 32
                |> PlanSnapshotPaging.historyPage
                |> StorageWorker.result

            collected.AddRange page.Changes
            next <- page.NextBeforeId

        writer.WriteBoolean(
            "historyBytePagesContinueWithoutLoss",
            first.Changes.Length < 32
            && first.NextBeforeId.IsSome
            && List.ofSeq collected = changes
        )

        writer.WriteEndObject()
