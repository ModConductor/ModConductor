namespace ModConductor.Bethesda

[<RequireQualifiedAccess>]
type SkyrimSaveCompression =
    | Uncompressed
    | Zlib
    | Lz4

type SkyrimSaveMetadata =
    { HeaderVersion: uint32
      FormVersion: byte
      Compression: SkyrimSaveCompression
      SaveNumber: uint32
      Character: string
      Level: uint32
      Location: string
      GameTime: string
      FullPlugins: string list
      LightPlugins: string list }

[<RequireQualifiedAccess>]
type SkyrimSaveError =
    | Malformed of string
    | Unsupported of string
    | Limit of string
