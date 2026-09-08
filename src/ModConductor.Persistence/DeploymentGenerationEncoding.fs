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
            w.Write 1
            guid w snapshot
            w.Write version
            path w file.Path
            w.Write file.Length
            w.Write file.Sha256

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
                  Length = r.ReadInt64()
                  Sha256 = r.ReadString() }
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
        w.Write v.Sha256

    let private readObserved (r: BinaryReader) : ObservedFile =
        { Target = readTarget r
          Identity = readIdentity r
          Length = r.ReadInt64()
          Sha256 = r.ReadString() }

    let private working (w: BinaryWriter) (v: WorkingBinding) =
        target w v.Target
        w.Write v.Directory
        location w v.Root
        path w v.Path
        identity w v.Identity

    let private readWorking (r: BinaryReader) : WorkingBinding =
        { Target = readTarget r
          Directory = r.ReadBoolean()
          Root = readLocation r
          Path = readPath r
          Identity = readIdentity r }

    let private file (w: BinaryWriter) (v: GenerationFile) =
        target w v.Target
        path w v.Path
        identity w v.Identity
        w.Write v.Length
        w.Write v.Sha256
        option backing w v.Backing

    let private readFile version (r: BinaryReader) : GenerationFile =
        { Target = readTarget r
          Path = readPath r
          Identity = readIdentity r
          Length = r.ReadInt64()
          Sha256 = r.ReadString()
          Backing = if version >= 2 then readOption readBacking r else None }

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

    let readGeneration version (r: BinaryReader) : Generation =
        { Id = readGuid r
          PlanFingerprint = r.ReadString()
          Directory = readLocation r
          Files = readList (readFile version) r
          References = readList readSource r
          Writable = readList readWritable r
          Roots = readList readRoot r
          Observed = if version >= 2 then readList readObserved r else []
          Working = if version >= 2 then readList readWorking r else [] }
