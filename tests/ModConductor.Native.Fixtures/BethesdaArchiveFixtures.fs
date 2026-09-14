namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Numerics
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.Platform

module BethesdaArchiveFixtures =
    let private token = CancellationToken.None
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private bytes (value: string) = Encoding.UTF8.GetBytes(value)

    let private hash path =
        File.ReadAllBytes path |> SHA256.HashData |> Convert.ToHexString

    let private check value =
        if not value then
            failwith "Bethesda archive observation failed."

    let private reference (artifact: Artifact) : ArtifactRef =
        { WorkspaceId = artifact.WorkspaceId
          Id = artifact.Id
          Revision = artifact.Revision }

    let private writeU16 (writer: BinaryWriter) (value: int) = writer.Write(uint16 value)
    let private writeU32 (writer: BinaryWriter) (value: int64) = writer.Write(uint32 value)

    module private Xx =
        [<Literal>]
        let P1 = 2654435761u

        [<Literal>]
        let P2 = 2246822519u

        [<Literal>]
        let P3 = 3266489917u

        [<Literal>]
        let P4 = 668265263u

        [<Literal>]
        let P5 = 374761393u

        let u32 (value: byte[]) offset =
            uint32 value[offset]
            ||| (uint32 value[offset + 1] <<< 8)
            ||| (uint32 value[offset + 2] <<< 16)
            ||| (uint32 value[offset + 3] <<< 24)

        let round value input =
            BitOperations.RotateLeft(value + input * P2, 13) * P1

        let hash (value: byte[]) =
            let mutable offset = 0
            let mutable output = P5

            if value.Length >= 16 then
                let mutable v1, v2, v3, v4 = P1 + P2, P2, 0u, 0u - P1

                while offset <= value.Length - 16 do
                    v1 <- round v1 (u32 value offset)
                    v2 <- round v2 (u32 value (offset + 4))
                    v3 <- round v3 (u32 value (offset + 8))
                    v4 <- round v4 (u32 value (offset + 12))
                    offset <- offset + 16

                output <-
                    BitOperations.RotateLeft(v1, 1)
                    + BitOperations.RotateLeft(v2, 7)
                    + BitOperations.RotateLeft(v3, 12)
                    + BitOperations.RotateLeft(v4, 18)

            output <- output + uint32 value.Length

            while offset <= value.Length - 4 do
                output <- BitOperations.RotateLeft(output + u32 value offset * P3, 17) * P4
                offset <- offset + 4

            while offset < value.Length do
                output <- BitOperations.RotateLeft(output + uint32 value[offset] * P5, 11) * P1
                offset <- offset + 1

            output <- output ^^^ (output >>> 15)
            output <- output * P2
            output <- output ^^^ (output >>> 13)
            output <- output * P3
            output ^^^ (output >>> 16)

    let private literalBlock (value: byte[]) =
        use output = new MemoryStream()
        let length = value.Length
        output.WriteByte(byte (min 15 length <<< 4))

        if length >= 15 then
            let mutable extra = length - 15

            while extra >= 255 do
                output.WriteByte 255uy
                extra <- extra - 255

            output.WriteByte(byte extra)

        output.Write value
        output.ToArray()

    let private lz4Frame independent invalidDistance badHeader checksums =
        let first = bytes "ABCDEFGH"

        let second, expanded =
            if independent then
                literalBlock (bytes "independent frame payload"), bytes "independent frame payload"
            else
                let block =
                    if invalidDistance then
                        [| 0x04uy; 0uy; 0uy |]
                    else
                        [| 0x04uy; 8uy; 0uy |]

                block, Array.append first first

        let blocks =
            if independent then
                [ expanded, true ]
            else
                [ literalBlock first, false; second, false ]

        use output = new MemoryStream()
        use writer = new BinaryWriter(output, Encoding.UTF8, true)
        writer.Write 0x184D2204u

        let flags =
            (if independent then 0x68uy else 0x48uy) ||| if checksums then 0x14uy else 0uy

        let descriptor =
            Array.append [| flags; 0x40uy |] (BitConverter.GetBytes(uint64 expanded.Length))

        writer.Write descriptor
        let checksum = byte ((Xx.hash descriptor >>> 8) &&& 0xFFu)
        writer.Write(if badHeader then checksum ^^^ 1uy else checksum)

        for block, uncompressed in blocks do
            writer.Write(uint32 block.Length ||| if uncompressed then 0x80000000u else 0u)
            writer.Write block

            if checksums then
                writer.Write(Xx.hash block)

        writer.Write 0u

        if checksums then
            writer.Write(Xx.hash expanded)

        output.ToArray(), expanded

    let private bsa path invalidDistance badHeader =
        let raw = bytes "uncompressed BSA entry\n"
        let independent, independentBytes = lz4Frame true false badHeader false
        let linked, linkedBytes = lz4Frame false invalidDistance false true
        let folder = "textures"
        let names = [ "raw.txt"; "independent.bin"; "linked.bin" ]
        let payloads = [ raw, false; independent, true; linked, true ]

        let stored =
            List.map2
                (fun name ((payload: byte[]), compressed) ->
                    let embedded = bytes (folder + "\\" + name)
                    use value = new MemoryStream()
                    use writer = new BinaryWriter(value, Encoding.UTF8, true)
                    writer.Write(byte embedded.Length)
                    writer.Write embedded

                    if compressed then
                        writer.Write(
                            uint32 (
                                if name = "independent.bin" then
                                    independentBytes.Length
                                else
                                    linkedBytes.Length
                            )
                        )

                    writer.Write payload
                    value.ToArray(), compressed)
                names
                payloads

        let folderBytes = Array.append (bytes folder) [| 0uy |]

        let fileNameBytes =
            names
            |> List.collect (fun n -> Array.toList (Array.append (bytes n) [| 0uy |]))
            |> List.toArray

        let metadata =
            36 + 24 + 1 + folderBytes.Length + 16 * names.Length + fileNameBytes.Length

        use output = File.Create path
        use writer = new BinaryWriter(output)
        writer.Write(bytes "BSA\000")
        writer.Write 105u
        writer.Write 36u
        writer.Write 0x103u
        writer.Write 1u
        writer.Write(uint32 names.Length)
        writer.Write(uint32 folderBytes.Length)
        writer.Write(uint32 fileNameBytes.Length)
        writer.Write 0u
        writer.Write 0UL
        writer.Write(uint32 names.Length)
        writer.Write 0u
        writer.Write(uint64 (36 + 24 + fileNameBytes.Length))
        writer.Write(byte folderBytes.Length)
        writer.Write folderBytes
        let mutable offset = metadata

        for data, compressed in stored do
            writer.Write 0UL
            writer.Write(uint32 data.Length ||| if compressed then 0x40000000u else 0u)
            writer.Write(uint32 offset)
            offset <- offset + data.Length

        writer.Write fileNameBytes

        for data, _ in stored do
            writer.Write data

        [ raw; independentBytes; linkedBytes ]

    let private zlib (value: byte[]) =
        use output = new MemoryStream()

        do
            use compressed = new ZLibStream(output, CompressionLevel.SmallestSize, true)
            compressed.Write value

        output.ToArray()

    let private ba2General path =
        let values = [ bytes "plain general data"; bytes "compressed general data" ]
        let encoded = [ values[0]; zlib values[1] ]
        let names = [ "meshes/plain.nif"; "scripts/compressed.pex" ]
        let recordsEnd = 24 + 36 * names.Length
        let mutable offset = recordsEnd

        let offsets =
            encoded
            |> List.map (fun value ->
                let current = offset in
                offset <- offset + value.Length
                current)

        let namesOffset = offset
        use output = File.Create path
        use writer = new BinaryWriter(output)
        writer.Write(bytes "BTDX")
        writer.Write 1u
        writer.Write(bytes "GNRL")
        writer.Write(uint32 names.Length)
        writer.Write(uint64 namesOffset)

        for index in 0 .. names.Length - 1 do
            writer.Write(Array.zeroCreate<byte> 16)
            writer.Write(uint64 offsets[index])
            writer.Write(if index = 0 then 0u else uint32 encoded[index].Length)
            writer.Write(uint32 values[index].Length)
            writer.Write 0xBAADF00Du

        for value in encoded do
            writer.Write value

        for name in names do
            let value = bytes name
            writeU16 writer value.Length
            writer.Write value

        values

    type private Texture =
        { Name: string
          Width: int
          Height: int
          Mips: int
          Format: int
          Cube: bool
          Values: byte[] list
          Encoded: byte[] list }

    let private ba2Textures path =
        let first =
            { Name = "textures/blocks_bc1.dds"
              Width = 8
              Height = 8
              Mips = 2
              Format = 71
              Cube = false
              Values = [ Array.init 32 byte; Array.init 8 (fun i -> byte (100 + i)) ]
              Encoded = [] }

        let second =
            { Name = "textures/cube_bc7.dds"
              Width = 4
              Height = 4
              Mips = 1
              Format = 98
              Cube = true
              Values = [ Array.init 96 (fun i -> byte (200 + i)) ]
              Encoded = [] }

        let textures =
            [ { first with
                  Encoded = [ zlib first.Values[0]; first.Values[1] ] }
              { second with Encoded = second.Values } ]

        let recordsEnd =
            24 + (textures |> List.sumBy (fun value -> 24 + 24 * value.Values.Length))

        let mutable dataOffset = recordsEnd

        let offsets =
            textures
            |> List.map (fun texture ->
                texture.Encoded
                |> List.map (fun value ->
                    let current = dataOffset in
                    dataOffset <- dataOffset + value.Length
                    current))

        let namesOffset = dataOffset
        use output = File.Create path
        use writer = new BinaryWriter(output)
        writer.Write(bytes "BTDX")
        writer.Write 1u
        writer.Write(bytes "DX10")
        writer.Write(uint32 textures.Length)
        writer.Write(uint64 namesOffset)

        for index in 0 .. textures.Length - 1 do
            let texture = textures[index]
            writer.Write(Array.zeroCreate<byte> 13)
            writer.Write(byte texture.Values.Length)
            writeU16 writer 24
            writeU16 writer texture.Height
            writeU16 writer texture.Width
            writer.Write(byte texture.Mips)
            writer.Write(byte texture.Format)
            writeU16 writer (if texture.Cube then 2049 else 2048)

            for chunk in 0 .. texture.Values.Length - 1 do
                writer.Write(uint64 offsets[index].[chunk])

                writer.Write(
                    if texture.Encoded[chunk].Length = texture.Values[chunk].Length then
                        0u
                    else
                        uint32 texture.Encoded[chunk].Length
                )

                writer.Write(uint32 texture.Values[chunk].Length)
                writeU16 writer chunk
                writeU16 writer chunk
                writer.Write 0xBAADF00Du

        for texture in textures do
            for value in texture.Encoded do
                writer.Write value

        for texture in textures do
            let value = bytes texture.Name
            writeU16 writer value.Length
            writer.Write value

        textures

    let observe
        (writer: Utf8JsonWriter)
        (area: string)
        (inspection: Inspection)
        (adopt: string -> Artifact)
        =
        writer.WriteStartObject("bethesdaArchives")
        check (Xx.hash Array.empty = 0x02CC5D05u)
        check (Xx.hash (bytes "abc") = 0x32D153FFu)
        let bsaPath = Path.Combine(area, "selected-v105.bsa")
        let expectedBsa = bsa bsaPath false false
        let generalPath = Path.Combine(area, "selected-gnrl.ba2")
        let expectedGeneral = ba2General generalPath
        let texturesPath = Path.Combine(area, "selected-dx10.ba2")
        let expectedTextures = ba2Textures texturesPath

        let inspect artifact =
            inspection.Inspect(reference artifact, token) |> wait |> result

        let extract artifact index =
            inspection.WithContents(
                reference artifact,
                token,
                fun contents ->
                    use output = new MemoryStream()
                    contents.ReadEntry(index, fun input -> input.CopyTo output)
                    output.ToArray()
            )
            |> wait
            |> result

        let safe action =
            try
                action ()
                None
            with error ->
                ArchiveFailure.message error

        let bsaBefore = hash bsaPath
        let bsaArtifact = adopt bsaPath
        let bsaManifest = inspect bsaArtifact
        check (bsaManifest.Format = "BSA v105" && bsaManifest.Entries.Length = 3)
        check (String.Equals(bsaManifest.Sha256, bsaBefore, StringComparison.OrdinalIgnoreCase))

        for index in 0..2 do
            check (extract bsaArtifact index = expectedBsa[index])

        check (hash bsaPath = bsaBefore)
        writer.WriteBoolean("Bsa105UncompressedAndLz4FramesExact", true)
        writer.WriteBoolean("BsaManifestCarriesVerifiedSha256", true)

        let generalBefore = hash generalPath
        let generalArtifact = adopt generalPath
        let generalManifest = inspect generalArtifact
        check (generalManifest.Format = "BA2 v1 GNRL")

        for index in 0..1 do
            check (extract generalArtifact index = expectedGeneral[index])

        check (hash generalPath = generalBefore)
        writer.WriteBoolean("Ba2V1GeneralRawAndZlibExact", true)

        let texturesBefore = hash texturesPath
        let texturesArtifact = adopt texturesPath
        let textureManifest = inspect texturesArtifact
        check (textureManifest.Format = "BA2 v1 DX10" && textureManifest.Entries.Length = 2)
        let bc1 = extract texturesArtifact 0
        let bc7 = extract texturesArtifact 1

        check (
            Encoding.ASCII.GetString(bc1, 0, 4) = "DDS "
            && BitConverter.ToUInt32(bc1, 84) = 0x31545844u
        )

        check (Array.sub bc1 128 (bc1.Length - 128) = Array.concat expectedTextures[0].Values)

        check (
            Encoding.ASCII.GetString(bc7, 84, 4) = "DX10"
            && BitConverter.ToUInt32(bc7, 128) = 98u
        )

        check (
            BitConverter.ToUInt32(bc7, 136) = 4u
            && Array.sub bc7 148 (bc7.Length - 148) = expectedTextures[1].Values[0]
        )

        check (hash texturesPath = texturesBefore)
        writer.WriteBoolean("Ba2V1Dx10Bc1Bc7AndCubemapExact", true)

        let badFrame = Path.Combine(area, "bad-frame.bsa")
        bsa badFrame false true |> ignore
        let badFrameArtifact = adopt badFrame
        check (safe (fun () -> extract badFrameArtifact 1 |> ignore) |> Option.isSome)
        let badOffset = Path.Combine(area, "bad-offset.bsa")
        bsa badOffset true false |> ignore
        let badOffsetArtifact = adopt badOffset
        check (safe (fun () -> extract badOffsetArtifact 2 |> ignore) |> Option.isSome)
        writer.WriteBoolean("Lz4ChecksumsAndOffsetsRefused", true)

        let mutate offset (value: byte[]) sourcePath name =
            let path = Path.Combine(area, name)
            File.Copy(sourcePath, path)
            use stream = File.Open(path, FileMode.Open, FileAccess.Write, FileShare.None)
            stream.Position <- offset
            stream.Write(value, 0, value.Length)
            path

        let unsupportedVersion =
            mutate 4L (BitConverter.GetBytes 2u) generalPath "unsupported-version.ba2"
            |> adopt

        let unsupportedBsaVersion =
            mutate 4L (BitConverter.GetBytes 104u) bsaPath "unsupported-version.bsa"
            |> adopt

        let unsupportedType =
            mutate 8L (bytes "GNMF") generalPath "unsupported-type.ba2" |> adopt

        let unsupportedDxgi =
            mutate 45L [| 1uy |] texturesPath "unsupported-dxgi.ba2" |> adopt

        let badSentinel =
            mutate 56L (BitConverter.GetBytes 0u) generalPath "bad-sentinel.ba2" |> adopt

        for artifact in
            [ unsupportedVersion
              unsupportedBsaVersion
              unsupportedType
              unsupportedDxgi
              badSentinel ] do
            check (safe (fun () -> inspect artifact |> ignore) |> Option.isSome)

        writer.WriteBoolean("UnsupportedAndMalformedBa2VariantsRefused", true)

        use limitedFile = File.OpenRead bsaPath

        let limited =
            Inspection(
                Unchecked.defaultof<IArtifactSource>,
                { ArchiveLimits.Default with
                    FileBytes = 8L }
            )

        check (
            safe (fun () ->
                limited.WithOwnedStream(bsaBefore, limitedFile, token, fun c -> c.Manifest)
                |> ignore)
            |> Option.isSome
        )

        writer.WriteBoolean("BethesdaEntryLimitRefused", true)

        let changed = Path.Combine(area, "changed-v105.bsa")
        File.Copy(bsaPath, changed)
        let changedArtifact = adopt changed
        File.WriteAllText(changed, "changed after adoption")
        check (inspection.Inspect(reference changedArtifact, token) |> wait |> Result.isError)
        writer.WriteBoolean("ChangedBethesdaSourceRefusedBeforeReader", true)

        let samples = Environment.GetEnvironmentVariable "MC_BETHESDA_SAMPLE_ROOT"

        if not (String.IsNullOrWhiteSpace samples) then
            let sampleBsa = Path.Combine(samples, "test_read.bsa")
            let sampleBa2 = Path.Combine(samples, "test_read.ba2")

            check (
                hash sampleBsa = "2E713318A8F647862FAF2A8C52C3C8F28F65387FC6A8E6DD94124E885B769D96"
            )

            check (
                hash sampleBa2 = "04EBDE8B69D28808093C86930E115C23CC2FF05909A73B86CCB411E9577CBF67"
            )

            let source = extract (adopt sampleBsa) 0
            let rebuilt = extract (adopt sampleBa2) 0
            check (source = rebuilt)

            check (
                Convert.ToHexString(SHA256.HashData source) =
                    "FE7296C4FE274E403922FA1B967C4A953926819BCC96822421C76016B72EC8B1"
            )

            writer.WriteBoolean("PinnedLibbsarchSamplesByteEquivalent", true)
        else
            writer.WriteBoolean("PinnedLibbsarchSamplesByteEquivalent", false)

        writer.WriteEndObject()
