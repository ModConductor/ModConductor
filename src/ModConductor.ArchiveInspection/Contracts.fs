namespace ModConductor.ArchiveInspection

open ModConductor.Platform

type NestedArchiveRef =
    { BundleId: System.Guid
      SourceId: System.Guid
      Sha256: string }

type INestedArchiveSource =
    abstract ReadVerified<'a> :
        System.Guid *
        NestedArchiveRef *
        System.Threading.CancellationToken *
        (System.IO.Stream -> 'a) ->
            System.Threading.Tasks.Task<Result<'a, ModConductor.ArtifactLibrary.ArtifactError>>

type ArchiveEntry =
    { Index: int
      Path: LogicalPath
      Directory: bool
      Size: int64
      CompressedSize: int64 option }

type ArchiveManifest =
    { Sha256: string
      Format: string
      Entries: ArchiveEntry list
      TotalSize: int64 }

type ArchiveInspectionException(message: string) =
    inherit System.Exception(message)
