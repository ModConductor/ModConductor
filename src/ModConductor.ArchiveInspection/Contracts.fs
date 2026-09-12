namespace ModConductor.ArchiveInspection

open ModConductor.Platform

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

type ArchiveLimits =
    { Entries: int
      Depth: int
      PathCharacters: int
      NameCharacters: int
      FileBytes: int64
      TotalBytes: int64
      Ratio: int64 }

    static member Default =
        { Entries = 20000
          Depth = 32
          PathCharacters = 1024
          NameCharacters = 2 * 1024 * 1024
          FileBytes = 16L * 1024L * 1024L * 1024L
          TotalBytes = 64L * 1024L * 1024L * 1024L
          Ratio = 1000L }

type ArchiveInspectionException(message: string) =
    inherit System.Exception(message)
