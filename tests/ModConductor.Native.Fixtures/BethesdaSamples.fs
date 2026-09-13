namespace ModConductor.Native.Fixtures

open System.IO
open System.Text

module BethesdaSamples =
    let header flags version masters extended =
        use body = new MemoryStream()
        use fields = new BinaryWriter(body, Encoding.UTF8, true)

        let tag (text: string) =
            fields.Write(Encoding.ASCII.GetBytes text)

        tag "HEDR"
        fields.Write 12us
        fields.Write(version: single)
        fields.Write 48u
        fields.Write 0x800u

        for master: string in masters do
            let bytes = Encoding.Latin1.GetBytes(master + "\000")
            tag "MAST"
            fields.Write(uint16 bytes.Length)
            fields.Write bytes
            tag "DATA"
            fields.Write 8us
            fields.Write 0L

        if extended then
            tag "XXXX"
            fields.Write 4us
            fields.Write 70000u
            tag "ONAM"
            fields.Write 0us
            fields.Write(Array.zeroCreate<byte> 70000)

        fields.Flush()
        use output = new MemoryStream()
        use writer = new BinaryWriter(output, Encoding.UTF8, true)
        writer.Write(Encoding.ASCII.GetBytes "TES4")
        writer.Write(uint32 body.Length)
        writer.Write(flags: uint32)
        writer.Write 0u
        writer.Write 0u
        writer.Write 44us
        writer.Write 0us
        writer.Write(body.ToArray())
        writer.Flush()
        output.ToArray()

    let files directory =
        let game, _ = ProtonFixtures.create directory
        File.WriteAllBytes(Path.Combine(game, "Data", "Skyrim.esm"), header 1u 1.7f [] false)
        let source = Directory.CreateDirectory(Path.Combine(directory, "plugins")).FullName

        for name, bytes in
            [ "QuietRivers.esp", header 0x200u 1.71f [ "Skyrim.esm" ] false
              "RiverPatch.esp", header 0u 1.71f [ "NorthernWater.esm" ] false
              "RoadA.esp", header 0u 1.71f [ "RoadB.esp" ] false
              "RoadB.esp", header 0u 1.71f [ "RoadA.esp" ] false
              "Other.esp", header 0u 1.0f [] false ] do
            File.WriteAllBytes(Path.Combine(source, name), bytes)

        game
