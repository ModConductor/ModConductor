namespace ModConductor.GameContexts

open System
open System.Buffers.Binary
open System.IO

module internal UnityIl2CppValidation =
    let inspect (definition: GameDefinition) (client: UnityIl2CppClient) root executable linux =
        try
            let format =
                if linux then
                    UnityValidation.elf
                else
                    UnityValidation.windows

            use runtime =
                File.OpenRead(
                    Path.Combine(root, if linux then client.LinuxRuntime else client.WindowsRuntime)
                )

            use metadata = File.OpenRead(Path.Combine(root, definition.Data, client.Metadata))
            let signature = Array.zeroCreate<byte> 4

            if not (format executable && format runtime) then
                Error "Select the declared x64 Unity IL2CPP client and runtime."
            elif
                metadata.Read(signature, 0, signature.Length) <> signature.Length
                || BinaryPrimitives.ReadUInt32LittleEndian(signature) <> 0xFAB11BAFu
            then
                Error "The declared IL2CPP metadata is unavailable or has an unsupported format."
            else
                UnityValidation.version definition client.UnityMetadata root
                |> Option.map Ok
                |> Option.defaultValue (Error "The Unity version is unavailable.")
        with
        | :? BadImageFormatException ->
            Error "The Unity IL2CPP client or runtime has an unsupported executable format."
        | :? IOException ->
            Error "The declared Unity IL2CPP runtime is unavailable or changed during the check."
        | :? UnauthorizedAccessException ->
            Error "The declared Unity IL2CPP runtime cannot be read."
