namespace ModConductor.Native.Fixtures

open System.IO
open System.Text

module BethesdaArchiveSamples =
    let ba2 version =
        let header =
            if version = 2u then 32
            else if version = 3u then 36
            else 24

        let name = Encoding.UTF8.GetBytes "meshes/example.txt"
        let payload = Encoding.UTF8.GetBytes "archive payload"
        let names = header + 36
        let data = names + 2 + name.Length
        use output = new MemoryStream()
        use writer = new BinaryWriter(output)
        writer.Write(Encoding.ASCII.GetBytes "BTDX")
        writer.Write(version: uint32)
        writer.Write(Encoding.ASCII.GetBytes "GNRL")
        writer.Write 1u
        writer.Write(uint64 names)
        writer.Write(Array.zeroCreate<byte> (header - 24))
        writer.Write(Array.zeroCreate<byte> 16)
        writer.Write(uint64 data)
        writer.Write 0u
        writer.Write(uint32 payload.Length)
        writer.Write 0xBAADF00Du
        writer.Write(uint16 name.Length)
        writer.Write name
        writer.Write payload
        output.ToArray()

    let morrowind () =
        let name = Encoding.UTF8.GetBytes "meshes\\example.txt\000"
        let payload = Encoding.UTF8.GetBytes "archive payload"
        use output = new MemoryStream()
        use writer = new BinaryWriter(output)
        writer.Write 0x100u
        writer.Write(uint32 (12 + name.Length))
        writer.Write 1u
        writer.Write(uint32 payload.Length)
        writer.Write 0u
        writer.Write 0u
        writer.Write name
        writer.Write 0UL
        writer.Write payload
        output.ToArray()
