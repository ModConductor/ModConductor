namespace ModConductor.Persistence

open System
open System.IO
open System.Text
open System.Security.Cryptography
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

module internal DeploymentValueEncoding =
    let limit = 16 * 1024 * 1024

    let corrupt () =
        raise (RecoveryException(RecoveryError.Corrupt "The activation record is invalid."))

    let guid (w: BinaryWriter) (v: Guid) = w.Write(v.ToByteArray())

    let readGuid (r: BinaryReader) =
        let bytes = r.ReadBytes 16 in if bytes.Length <> 16 then corrupt () else Guid bytes

    let path (w: BinaryWriter) v = w.Write(LibraryEncoding.path v)

    let readPath (r: BinaryReader) =
        LibraryEncoding.readPath (r.ReadString())

    let identity (w: BinaryWriter) v = w.Write(LibraryEncoding.identity v)

    let readIdentity (r: BinaryReader) =
        LibraryEncoding.readIdentity (r.ReadString())

    let option write (w: BinaryWriter) value =
        w.Write(Option.isSome value)
        value |> Option.iter (write w)

    let readOption read (r: BinaryReader) =
        if r.ReadBoolean() then Some(read r) else None

    let list write (w: BinaryWriter) values =
        w.Write(List.length values)
        values |> List.iter (write w)

    let readList read (r: BinaryReader) =
        let count = r.ReadInt32()

        if count < 0 || count > 1000000 then
            corrupt ()

        [ for _ in 1..count -> read r ]

    let text (w: BinaryWriter) (v: string) = w.Write v
    let readText (r: BinaryReader) = r.ReadString()
    let boolean (w: BinaryWriter) (v: bool) = w.Write v
    let readBoolean (r: BinaryReader) = r.ReadBoolean()

    let target (w: BinaryWriter) (v: TargetFile) =
        guid w v.Root
        path w v.Path

    let readTarget r : TargetFile =
        { Root = readGuid r; Path = readPath r }

    let location (w: BinaryWriter) (v: Location) =
        w.Write(HostPath.value v.Path)
        identity w v.Identity

    let readLocation (r: BinaryReader) : Location =
        { Path = HostPath.create (r.ReadString()) |> Result.defaultWith (fun _ -> corrupt ())
          Identity = readIdentity r }

    let root (w: BinaryWriter) (v: TargetRoot) =
        guid w v.Id

        w.Write(
            match v.Policy.Case with
            | Sensitive -> 0
            | Insensitive -> 1
        )

        w.Write(
            match v.Policy.Unicode with
            | Preserve -> 0
            | CanonicalComposition -> 1
        )

        w.Write(
            match v.Policy.Names with
            | Posix -> 0
            | Windows -> 1
        )

    let readRoot (r: BinaryReader) : TargetRoot =
        { Id = readGuid r
          Policy =
            { Case =
                (match r.ReadInt32() with
                 | 0 -> Sensitive
                 | 1 -> Insensitive
                 | _ -> corrupt ())
              Unicode =
                (match r.ReadInt32() with
                 | 0 -> Preserve
                 | 1 -> CanonicalComposition
                 | _ -> corrupt ())
              Names =
                (match r.ReadInt32() with
                 | 0 -> Posix
                 | 1 -> Windows
                 | _ -> corrupt ()) } }

    let binding w (v: RootBinding) =
        root w v.Root
        location w v.Directory
        location w v.Originals

    let readBinding r : RootBinding =
        { Root = readRoot r
          Directory = readLocation r
          Originals = readLocation r }

    let entry (w: BinaryWriter) (v: HeldEntry) =
        identity w v.Identity

        w.Write(
            match v.Kind with
            | RegularFile -> 0
            | Directory -> 1
            | Link -> 2
            | Other -> 3
        )

        option text w v.LinkTarget
        option boolean w v.DirectoryLink

    let readEntry (r: BinaryReader) : HeldEntry =
        { Identity = readIdentity r
          Kind =
            (match r.ReadInt32() with
             | 0 -> RegularFile
             | 1 -> Directory
             | 2 -> Link
             | 3 -> Other
             | _ -> corrupt ())
          LinkTarget = readOption readText r
          DirectoryLink = readOption readBoolean r }

    let spec (w: BinaryWriter) (v: LinkSpec) =
        guid w v.Generation
        w.Write v.Target
        w.Write v.Directory

    let readSpec (r: BinaryReader) : LinkSpec =
        { Generation = readGuid r
          Target = r.ReadString()
          Directory = r.ReadBoolean() }

    let link w (v: ActiveLink) =
        target w v.Target
        spec w v.Spec
        entry w v.Entry

    let readLink r : ActiveLink =
        { Target = readTarget r
          Spec = readSpec r
          Entry = readEntry r }

    let original (w: BinaryWriter) (v: Original) =
        target w v.Target
        entry w v.Entry
        option text w v.Sha256
        w.Write v.Backup

    let readOriginal (r: BinaryReader) : Original =
        { Target = readTarget r
          Entry = readEntry r
          Sha256 = readOption readText r
          Backup = r.ReadString() }

    let ownedDirectory w (value: OwnedDirectory) =
        target w value.Target
        identity w value.Identity

    let readOwnedDirectory r : OwnedDirectory =
        { Target = readTarget r
          Identity = readIdentity r }

    let context (w: BinaryWriter) (v: Context) =
        guid w v.Id
        w.Write v.Fingerprint
        list binding w v.Roots
        w.Write v.Revision
        option guid w v.Active
        list link w v.Links
        list original w v.Originals
        option guid w v.Pending
        list ownedDirectory w v.Directories

    let readContext (r: BinaryReader) : Context =
        { Id = readGuid r
          Fingerprint = r.ReadString()
          Roots = readList readBinding r
          Revision = r.ReadInt64()
          Active = readOption readGuid r
          Links = readList readLink r
          Originals = readList readOriginal r
          Pending = readOption readGuid r
          Directories = readList readOwnedDirectory r }
