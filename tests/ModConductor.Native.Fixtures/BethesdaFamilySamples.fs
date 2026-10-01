namespace ModConductor.Native.Fixtures

open System.IO
open ModConductor.GameContexts

module BethesdaFamilySamples =
    let private tes3 master =
        use stream = new MemoryStream()
        use writer = new BinaryWriter(stream)
        writer.Write(System.Text.Encoding.ASCII.GetBytes "TES3")
        writer.Write 308u
        writer.Write 0u
        writer.Write 0u
        writer.Write(System.Text.Encoding.ASCII.GetBytes "HEDR")
        writer.Write 300u
        writer.Write 1.3f
        writer.Write(if master then 1u else 0u)
        writer.Write(Array.zeroCreate<byte> 32)
        writer.Write(Array.zeroCreate<byte> 256)
        writer.Write 1u
        stream.ToArray()

    let header rules master =
        if rules.HeaderBytes = 16 then
            tes3 master
        else
            let bytes = BethesdaSamples.header (if master then 1u else 0u) 1.7f [] false

            if rules.HeaderBytes = 20 then
                Array.append bytes[..19] bytes[24..]
            else
                bytes
