namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open SharpCompress.Common
open SharpCompress.Writers
open SharpCompress.Writers.SevenZip
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces

module ArchiveInspectionFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private reference (a: Artifact) : ArtifactRef =
        { WorkspaceId = a.WorkspaceId
          Id = a.Id
          Revision = a.Revision }

    let private payload = Encoding.UTF8.GetBytes("MC032 synthetic archive contents.\n")

    let private hash path =
        File.ReadAllBytes path |> SHA256.HashData |> Convert.ToHexString

    let private check value =
        if not value then
            failwith "Archive inspection observation failed."

    let private zip path names attr =
        use output = File.Create path
        use archive = new ZipArchive(output, ZipArchiveMode.Create)

        for name in names do
            let entry = archive.CreateEntry(name)
            entry.ExternalAttributes <- attr
            use stream = entry.Open()
            stream.Write payload

    let create area =
        Directory.CreateDirectory area |> ignore

        zip
            (Path.Combine(area, "textures.zip"))
            [ "textures/water.dds"
              "textures/landscape/riverbank.dds"
              "textures/landscape/riverbank_n.dds" ]
            0

        let seven = Path.Combine(area, "textures.7z")

        do
            use output = File.Create seven

            use writer =
                WriterFactory.OpenWriter(
                    output,
                    ArchiveType.SevenZip,
                    SevenZipWriterOptions(CompressionType.LZMA2)
                )

            use source = new MemoryStream(payload)
            writer.Write("textures/water.dds", source, Nullable(DateTime(2026, 9, 12)))

        let bytes = File.ReadAllBytes seven
        File.WriteAllBytes(Path.Combine(area, "corrupt.7z"), bytes[.. bytes.Length - 5])
        File.WriteAllText(Path.Combine(area, "unsupported.bin"), "This is not an archive.")

    let observe (writer: Utf8JsonWriter) area =
        create area
        use store = new OperationStore(Path.Combine(area, "state"))
        let workspace = Guid.NewGuid()
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

        (store.Workspaces :> IWorkspaceState)
            .Create(workspace, "Inspection fixture", StorageWorker.select root)
        |> wait
        |> result
        |> ignore

        let adopt path =
            store.Artifacts.Add(
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  Path = path
                  Storage = ArtifactStorage.Reference },
                token
            )
            |> wait
            |> result

        let inspect artifact =
            store.ArchiveInspection.Inspect(reference artifact, token) |> wait |> result

        let safeError action =
            try
                action ()
                None
            with error ->
                ArchiveFailure.message error

        writer.WriteStartObject("archiveInspection")
        BethesdaArchiveFixtures.observe writer area store.ArchiveInspection adopt

        for name in [ "textures.zip"; "textures.7z" ] do
            let path = Path.Combine(area, name)
            let before = hash path
            let artifact = adopt path
            let manifest = inspect artifact
            check (not manifest.Entries.IsEmpty)

            store.ArchiveInspection.WithContents(
                reference artifact,
                token,
                fun contents ->
                    for entry in contents.Manifest.Entries do
                        contents.ReadEntry(
                            entry.Index,
                            fun stream ->
                                use output = new MemoryStream()
                                stream.CopyTo output
                                check (output.ToArray() = payload)
                        )
            )
            |> wait
            |> result

            check (hash path = before)
            writer.WriteBoolean(name + "MetadataAndLazyBytesUnchanged", true)

        let windowsAttributes =
            adopt (
                Path.Combine(
                    AppContext.BaseDirectory,
                    "fixtures",
                    "archives",
                    "windows-attributes.7z"
                )
            )

        store.ArchiveInspection.WithContents(
            reference windowsAttributes,
            token,
            fun contents ->
                let entry = contents.Manifest.Entries |> List.exactlyOne
                check (LogicalPath.display entry.Path = "file.txt" && not entry.Directory)

                contents.ReadEntry(
                    entry.Index,
                    fun stream ->
                        use output = new MemoryStream()
                        stream.CopyTo output

                        check (
                            output.ToArray() =
                                Encoding.UTF8.GetBytes("synthetic 7z attribute fixture\n")
                        )
                )
        )
        |> wait
        |> result

        writer.WriteBoolean("Windows7zFileAttributesAllowOrdinaryFile", true)

        let unixSymlink =
            adopt (
                Path.Combine(AppContext.BaseDirectory, "fixtures", "archives", "unix-symlink.7z")
            )

        check (safeError (fun () -> inspect unixSymlink |> ignore) |> Option.isSome)
        writer.WriteBoolean("Unix7zSymlinkRefused", true)

        for name in
            [ "rar5-store.rar"
              "test_read_format_rar5_compressed.rar"
              "test_read_format_rar5_multiple_files_solid.rar" ] do
            let path = Path.Combine(AppContext.BaseDirectory, "fixtures", "archives", name)
            let before = hash path
            let artifact = adopt path

            store.ArchiveInspection.WithContents(
                reference artifact,
                token,
                fun contents ->
                    for entry in contents.Manifest.Entries do
                        contents.ReadEntry(
                            entry.Index,
                            fun stream ->
                                use output = new MemoryStream()
                                stream.CopyTo output
                                let bytes = output.ToArray()

                                if name = "rar5-store.rar" then
                                    check (bytes = payload)
                                else
                                    let magic =
                                        if name.Contains("solid") then entry.Index + 1 else 0

                                    check (bytes.Length = if magic = 0 then 1200 else 4096)

                                    for i in 0 .. bytes.Length / 4 - 1 do
                                        let k = i + 1

                                        check (
                                            BitConverter.ToInt32(bytes, i * 4) =
                                                max 0 (k * k - 3 * k + 1 + magic)
                                        )
                        )
            )
            |> wait
            |> result

            check (hash path = before)
            writer.WriteBoolean(name + "LazyBytesUnchanged", true)

        for label, names, attr in
            [ "traversal", [ "../outside.txt" ], 0
              "rooted", [ "/outside.txt" ], 0
              "drive", [ "C:/outside.txt" ], 0
              "unc", [ "\\\\server\\file" ], 0
              "duplicate", [ "a.txt"; "a.txt" ], 0
              "caseCollision", [ "A.txt"; "a.txt" ], 0
              "unicodeCollision", [ "é.txt"; "e\u0301.txt" ], 0
              "fileFolderCollision", [ "a"; "a/b" ], 0
              "parentCollision", [ "A/one"; "a/two" ], 0
              "link", [ "link" ], int (0xA1FFu <<< 16)
              "device", [ "device" ], int (0x21B6u <<< 16) ] do
            let path = Path.Combine(area, label + ".zip")
            zip path names attr
            let artifact = adopt path
            check (safeError (fun () -> inspect artifact |> ignore) |> Option.isSome)
            writer.WriteBoolean(label + "Refused", true)

        let original = adopt (Path.Combine(area, "textures.zip"))

        let limited =
            { ArchiveLimits.Default with
                Entries = 2 }

        let source = store.ArtifactSource

        let checkLimit limits =
            let reader = Inspection(source, limits)

            check (
                safeError (fun () ->
                    reader.Inspect(reference original, token) |> wait |> result |> ignore)
                |> Option.isSome
            )

        checkLimit limited
        checkLimit { ArchiveLimits.Default with Depth = 1 }

        checkLimit
            { ArchiveLimits.Default with
                FileBytes = 10L }

        checkLimit
            { ArchiveLimits.Default with
                TotalBytes = 50L }

        writer.WriteBoolean("MetadataLimitsRefusedWithoutPartialManifest", true)
        let expansion = Path.Combine(area, "expansion.zip")

        do
            use file = File.Create expansion
            use compressed = new ZipArchive(file, ZipArchiveMode.Create)

            use entry =
                compressed.CreateEntry("zeros.bin", CompressionLevel.SmallestSize).Open()

            entry.Write(Array.zeroCreate<byte> 100000)

        let expansive = adopt expansion

        let smallRatio =
            Inspection(
                source,
                { ArchiveLimits.Default with
                    Ratio = 10L }
            )

        check (
            safeError (fun () ->
                smallRatio.Inspect(reference expansive, token) |> wait |> result |> ignore)
            |> Option.isSome
        )

        writer.WriteBoolean("ExpansionRatioRefused", true)
        let corrupt = adopt (Path.Combine(area, "corrupt.7z"))
        let error = safeError (fun () -> inspect corrupt |> ignore)
        check error.IsSome
        writer.WriteString("CorruptError", error.Value)

        let encrypted =
            adopt (
                Path.Combine(AppContext.BaseDirectory, "fixtures", "archives", "rar5-encrypted.rar")
            )

        let passwordError = safeError (fun () -> inspect encrypted |> ignore)
        check passwordError.IsSome
        writer.WriteString("PasswordError", passwordError.Value)
        let unsupported = adopt (Path.Combine(area, "unsupported.bin"))
        check (safeError (fun () -> inspect unsupported |> ignore) |> Option.isSome)
        writer.WriteBoolean("UnsupportedHasNormalError", true)
        let wrongSize = Path.Combine(area, "wrong-size.zip")
        zip wrongSize [ "body.txt" ] 0
        let encoded = File.ReadAllBytes wrongSize

        for offset in 0 .. encoded.Length - 4 do
            let signature = BitConverter.ToUInt32(encoded, offset)

            let sizeOffset =
                if signature = 0x04034B50u then Some(offset + 22)
                elif signature = 0x02014B50u then Some(offset + 24)
                else None

            sizeOffset
            |> Option.iter (fun start -> BitConverter.GetBytes(1u).CopyTo(encoded, start))

        File.WriteAllBytes(wrongSize, encoded)
        let declared = adopt wrongSize
        check ((inspect declared).Entries.Head.Size = 1L)

        check (
            safeError (fun () ->
                store.ArchiveInspection.WithContents(
                    reference declared,
                    token,
                    fun contents -> contents.ReadEntry(0, fun stream -> stream.CopyTo Stream.Null)
                )
                |> wait
                |> result)
            |> Option.isSome
        )

        writer.WriteBoolean("MetadataListingIsLazyAndEntryReadChecksActualSize", true)

        let changed = Path.Combine(area, "changed.zip")
        File.Copy(Path.Combine(area, "textures.zip"), changed)
        let artifact = adopt changed
        File.WriteAllText(changed, "changed after adoption")

        check (
            store.ArchiveInspection.Inspect(reference artifact, token)
            |> wait
            |> Result.isError
        )

        writer.WriteBoolean("ChangedSourceRefusedBeforeReader", true)
        check (inspect original |> fun m -> m.Entries.Length = 3)
        writer.WriteBoolean("NormalReadAfterError", true)
        writer.WriteEndObject()
