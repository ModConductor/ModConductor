namespace ModConductor.GameContexts

open System
open System.Buffers.Binary
open System.IO
open System.Reflection.PortableExecutable
open System.Text

module internal UnityValidation =
    let elf (stream: FileStream) =
        let bytes = Array.zeroCreate<byte> 20
        stream.Position <- 0L

        stream.Read(bytes, 0, bytes.Length) = bytes.Length
        && bytes[0..5] = [| 0x7fuy; 0x45uy; 0x4cuy; 0x46uy; 2uy; 1uy |]
        && BinaryPrimitives.ReadUInt16LittleEndian(bytes.AsSpan(18, 2)) = 62us

    let windows (stream: FileStream) =
        use pe = new PEReader(stream, PEStreamOptions.LeaveOpen)
        pe.PEHeaders.CoffHeader.Machine = Machine.Amd64

    let version (definition: GameDefinition) metadata root =
        use stream = File.OpenRead(Path.Combine(root, definition.Data, metadata))

        let bytes = Array.zeroCreate<byte> 128
        let count = stream.Read(bytes, 0, bytes.Length)

        Encoding.ASCII.GetString(bytes, 0, count).Split('\000')
        |> Array.tryFind (fun value ->
            value.Length > 3
            && Char.IsAsciiDigit value[0]
            && value.Contains '.'
            && (value
                |> Seq.forall (fun character ->
                    Char.IsAsciiLetterOrDigit character || character = '.')))
