namespace ModConductor.GameContexts

open System
open System.Buffers.Binary
open System.IO
open System.Reflection.PortableExecutable
open System.Text

/// The selected pack targets the x64 Unity Mono client, not the dedicated server or IL2CPP.
module internal UnityMonoValidation =
    let private elf (stream: FileStream) =
        let bytes = Array.zeroCreate<byte> 20
        stream.Position <- 0L

        stream.Read(bytes, 0, bytes.Length) = bytes.Length
        && bytes[0..5] = [| 0x7fuy; 0x45uy; 0x4cuy; 0x46uy; 2uy; 1uy |]
        && BinaryPrimitives.ReadUInt16LittleEndian(bytes.AsSpan(18, 2)) = 62us

    let private windows (stream: FileStream) =
        use pe = new PEReader(stream, PEStreamOptions.LeaveOpen)
        pe.PEHeaders.CoffHeader.Machine = Machine.Amd64

    let private mono (definition: GameDefinition) (client: UnityMonoClient) root linux =
        let data = Path.Combine(root, definition.Data)
        let library = if linux then client.LinuxRuntime else client.WindowsRuntime
        use runtime = File.OpenRead(Path.Combine(data, library))
        use assembly = File.OpenRead(Path.Combine(data, client.ManagedAssembly))
        use managed = new PEReader(assembly)
        managed.HasMetadata && (if linux then elf runtime else windows runtime)

    let private unity (definition: GameDefinition) (client: UnityMonoClient) root =
        use stream =
            File.OpenRead(Path.Combine(root, definition.Data, client.UnityMetadata))

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

    let inspect definition client root executable linux =
        try
            if not (if linux then elf executable else windows executable) then
                Error "Select the native x64 Unity Mono client for this operating system."
            elif not (mono definition client root linux) then
                Error
                    "The selected Unity Mono client does not contain the supported Unity Mono runtime."
            else
                unity definition client root
                |> Option.map Ok
                |> Option.defaultValue (Error "The Unity version is unavailable.")
        with
        | :? BadImageFormatException ->
            Error "The Unity Mono client or Mono runtime has an unsupported executable format."
        | :? IOException ->
            Error "The Unity Mono client runtime is unavailable or changed during the check."
        | :? UnauthorizedAccessException -> Error "The Unity Mono client runtime cannot be read."
