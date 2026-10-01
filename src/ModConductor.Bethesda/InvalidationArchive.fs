namespace ModConductor.Bethesda

open System.IO

module InvalidationArchive =
    let bytes version =
        use output = new MemoryStream()
        use writer = new BinaryWriter(output)
        writer.Write [| 66uy; 83uy; 65uy; 0uy |]
        [ version; 36u; 3u; 1u; 1u; 1u; 10u; 2u ] |> List.iter writer.Write
        writer.Write 0UL
        writer.Write 1u
        writer.Write 62u
        writer.Write 1uy
        writer.Write 0uy
        writer.Write 0x8E50C6FD6405EDF9UL
        writer.Write 0u
        writer.Write 80u
        writer.Write(System.Text.Encoding.ASCII.GetBytes("dummy.dds\000"))
        writer.Write 0u
        writer.Flush()
        output.ToArray()
