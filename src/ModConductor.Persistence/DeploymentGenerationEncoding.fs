namespace ModConductor.Persistence

open System
open System.IO
open System.Text
open System.Security.Cryptography
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

module internal DeploymentGenerationEncoding =
    open DeploymentValueEncoding

    let private source (w: BinaryWriter) =
        function
        | SourcePin.Mod(modId, versionId, file) ->
            w.Write 0
            guid w modId
            guid w versionId
            path w file.Path
            guid w file.Payload.Id
            w.Write file.Payload.Length
            w.Write file.Payload.Sha256
        | SourcePin.Snapshot(snapshot, version, file) ->
            w.Write(
                match file.Identity with
                | SnapshotFileIdentity.Content _ -> 1
                | SnapshotFileIdentity.Metadata _ -> 2
            )

            guid w snapshot
            w.Write version
            path w file.Path

            match file.Identity with
            | SnapshotFileIdentity.Content(length, sha256) ->
                w.Write length
                w.Write sha256
            | SnapshotFileIdentity.Metadata metadata ->
                identity w metadata.Identity
                w.Write metadata.Length
                w.Write(metadata.Modified.ToUniversalTime().Ticks)

    let private readSource (r: BinaryReader) =
        match r.ReadInt32() with
        | 0 ->
            let m = readGuid r in
            let v = readGuid r in

            SourcePin.Mod(
                m,
                v,
                { Path = readPath r
                  Payload =
                    { Id = readGuid r
                      Length = r.ReadInt64()
                      Sha256 = r.ReadString() } }
            )
        | 1 ->
            let id = readGuid r in
            let v = r.ReadString() in

            SourcePin.Snapshot(
                id,
                v,
                { Path = readPath r
                  Identity = SnapshotFileIdentity.Content(r.ReadInt64(), r.ReadString()) }
            )
        | 2 ->
            let id = readGuid r in
            let v = r.ReadString() in

            SourcePin.Snapshot(
                id,
                v,
                { Path = readPath r
                  Identity =
                    SnapshotFileIdentity.Metadata
                        { Identity = readIdentity r
                          Length = r.ReadInt64()
                          Modified = DateTime(r.ReadInt64(), DateTimeKind.Utc) } }
            )
        | _ -> corrupt ()

    let private writable (w: BinaryWriter) =
        function
        | WritableTarget.File(id, p) ->
            w.Write 0
            guid w id
            path w p
        | WritableTarget.Subtree(id, PlanPath.Root) ->
            w.Write 1
            guid w id
        | WritableTarget.Subtree(id, PlanPath.At p) ->
            w.Write 2
            guid w id
            path w p

    let private readWritable (r: BinaryReader) =
        match r.ReadInt32() with
        | 0 -> let id = readGuid r in WritableTarget.File(id, readPath r)
        | 1 -> WritableTarget.Subtree(readGuid r, PlanPath.Root)
        | 2 -> let id = readGuid r in WritableTarget.Subtree(id, PlanPath.At(readPath r))
        | _ -> corrupt ()

    let private backing (w: BinaryWriter) (v: FileBacking) =
        location w v.Directory
        path w v.Path
        identity w v.Identity
        option guid w v.OwnerGeneration

    let private readBacking (r: BinaryReader) : FileBacking =
        { Directory = readLocation r
          Path = readPath r
          Identity = readIdentity r
          OwnerGeneration = readOption readGuid r }

    let private observed (w: BinaryWriter) (v: ObservedFile) =
        target w v.Target
        identity w v.Identity
        w.Write v.Length
        option (fun w (value: DateTime) -> w.Write(value.ToUniversalTime().Ticks)) w v.Modified

    let private readObserved version (r: BinaryReader) : ObservedFile =
        let target = readTarget r
        let identity = readIdentity r
        let length = r.ReadInt64()

        let modified =
            if version >= 5 then
                readOption (fun r -> DateTime(r.ReadInt64(), DateTimeKind.Utc)) r
            else
                r.ReadString() |> ignore
                None

        { Target = target
          Identity = identity
          Length = length
          Modified = modified }

    let private working (w: BinaryWriter) (v: WorkingBinding) =
        target w v.Target
        w.Write v.Directory
        location w v.Root
        path w v.Path
        option identity w v.Identity

    let private readWorking version (r: BinaryReader) : WorkingBinding =
        { Target = readTarget r
          Directory = r.ReadBoolean()
          Root = readLocation r
          Path = readPath r
          Identity =
            if version >= 4 then
                readOption readIdentity r
            else
                Some(readIdentity r) }

    let private file (w: BinaryWriter) (v: GenerationFile) =
        target w v.Target
        path w v.Path
        identity w v.Identity
        w.Write v.Length
        option text w v.Sha256
        option backing w v.Backing

    let private readFile version (r: BinaryReader) : GenerationFile =
        { Target = readTarget r
          Path = readPath r
          Identity = readIdentity r
          Length = r.ReadInt64()
          Sha256 =
            if version >= 5 then
                readOption readText r
            else
                Some(r.ReadString())
          Backing = if version >= 2 then readOption readBacking r else None }

    let private savedMod (w: BinaryWriter) (value: SavedMod) =
        guid w value.ModId
        option guid w value.VersionId
        w.Write value.Priority
        boolean w value.Enabled

    let private readSavedMod (r: BinaryReader) : SavedMod =
        { ModId = readGuid r
          VersionId = readOption readGuid r
          Priority = r.ReadInt32()
          Enabled = readBoolean r }

    let private savedProfile (w: BinaryWriter) (value: SavedProfile) =
        guid w value.Id
        w.Write value.Name
        w.Write value.Revision
        list savedMod w value.Mods

        list
            (fun w (file: ModFile) ->
                guid w file.ModId
                guid w file.VersionId
                path w file.Path)
            w
            (Set.toList value.Hidden)

    let private readSavedProfile (r: BinaryReader) : SavedProfile =
        { Id = readGuid r
          Name = r.ReadString()
          Revision = r.ReadInt64()
          Mods = readList readSavedMod r
          Hidden =
            readList
                (fun r ->
                    { ModId = readGuid r
                      VersionId = readGuid r
                      Path = readPath r })
                r
            |> Set.ofList }

    let private provenance (w: BinaryWriter) (value: GenerationProvenance) =
        w.Write(value.PreparedAt.ToUnixTimeMilliseconds())
        option savedProfile w value.Profile

    let private readProvenance (r: BinaryReader) : GenerationProvenance =
        { PreparedAt = DateTimeOffset.FromUnixTimeMilliseconds(r.ReadInt64())
          Profile = readOption readSavedProfile r }

    let generation (w: BinaryWriter) (v: Generation) =
        guid w v.Id
        w.Write v.PlanFingerprint
        location w v.Directory
        list file w v.Files
        list source w v.References
        list writable w v.Writable
        list root w v.Roots
        list observed w v.Observed
        list working w v.Working

        list
            (fun w (key, value) ->
                target w key
                path w value)
            w
            (Map.toList v.NativeTargets)

        option provenance w v.Provenance

    let readGeneration version (r: BinaryReader) : Generation =
        { Id = readGuid r
          PlanFingerprint = r.ReadString()
          Directory = readLocation r
          Files = readList (readFile version) r
          References = readList readSource r
          Writable = readList readWritable r
          Roots = readList readRoot r
          Observed =
            if version >= 2 then
                readList (readObserved version) r
            else
                []
          Working =
            if version >= 2 then
                readList (readWorking version) r
            else
                []
          NativeTargets =
            if version >= 3 then
                readList (fun r -> let key = readTarget r in key, readPath r) r |> Map.ofList
            else
                Map.empty
          Provenance = if version >= 4 then readOption readProvenance r else None }
