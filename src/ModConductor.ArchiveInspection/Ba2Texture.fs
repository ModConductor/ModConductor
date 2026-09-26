namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.Threading
open ModConductor.Platform
open BethesdaArchiveCommon

module internal Ba2Texture =
    let private writeU32 (bytes: byte[]) offset (value: uint32) =
        bytes[offset] <- byte value
        bytes[offset + 1] <- byte (value >>> 8)
        bytes[offset + 2] <- byte (value >>> 16)
        bytes[offset + 3] <- byte (value >>> 24)

    let ddsHeader width height mips format cube =
        let mutable dimension = max width height
        let mutable maximumMips = 1

        while dimension > 1 do
            dimension <- dimension / 2
            maximumMips <- maximumMips + 1

        if mips > maximumMips then
            unsupported ()

        let legacy =
            if cube then
                None
            else
                match format with
                | 71 -> Some(0x31545844u, true)
                | 74 -> Some(0x33545844u, false)
                | 77 -> Some(0x35545844u, false)
                | 80 -> Some(0x55344342u, true)
                | 81 -> Some(0x53344342u, true)
                | 83 -> Some(0x55354342u, false)
                | 84 -> Some(0x53354342u, false)
                | _ -> None

        let qualified = (format >= 70 && format <= 84) || (format >= 94 && format <= 99)

        if not qualified then
            unsupported ()

        let hasDx10 = legacy.IsNone
        let bytes = Array.zeroCreate<byte> (if hasDx10 then 148 else 128)
        writeU32 bytes 0 0x20534444u
        writeU32 bytes 4 124u
        writeU32 bytes 8 0xA1007u
        writeU32 bytes 12 (uint32 height)
        writeU32 bytes 16 (uint32 width)
        let halfBlock = (format >= 70 && format <= 72) || (format >= 79 && format <= 81)
        let blocksWide = int64 (max 1 ((width + 3) / 4))
        let blocksHigh = int64 (max 1 ((height + 3) / 4))
        let linearSize = blocksWide * blocksHigh * (if halfBlock then 8L else 16L)

        if linearSize > int64 UInt32.MaxValue then
            unsupported ()

        writeU32 bytes 20 (uint32 linearSize)
        writeU32 bytes 24 1u
        writeU32 bytes 28 (uint32 mips)
        writeU32 bytes 76 32u
        writeU32 bytes 80 4u
        writeU32 bytes 84 (legacy |> Option.map fst |> Option.defaultValue 0x30315844u)
        let mutable caps = 0x1000u

        if mips > 1 then
            caps <- caps ||| 0x400008u

        if cube then
            caps <- caps ||| 0x08u

        writeU32 bytes 108 caps

        if cube then
            writeU32 bytes 112 0xFE00u

        if hasDx10 then
            writeU32 bytes 128 (uint32 format)
            writeU32 bytes 132 3u
            writeU32 bytes 136 (if cube then 4u else 0u)
            writeU32 bytes 140 1u

        bytes
