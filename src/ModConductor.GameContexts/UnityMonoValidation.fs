namespace ModConductor.GameContexts

open System
open System.IO
open System.Reflection.PortableExecutable

/// The selected pack targets the x64 Unity Mono client, not the dedicated server or IL2CPP.
module internal UnityMonoValidation =
    let private mono (definition: GameDefinition) (client: UnityMonoClient) root linux =
        let data = Path.Combine(root, definition.Data)
        let library = if linux then client.LinuxRuntime else client.WindowsRuntime
        use runtime = File.OpenRead(Path.Combine(data, library))
        use assembly = File.OpenRead(Path.Combine(data, client.ManagedAssembly))
        use managed = new PEReader(assembly)

        managed.HasMetadata
        && (if linux then
                UnityValidation.elf runtime
            else
                UnityValidation.windows runtime)

    let inspect definition client root executable linux =
        try
            if
                not (
                    if linux then
                        UnityValidation.elf executable
                    else
                        UnityValidation.windows executable
                )
            then
                Error "Select the native x64 Unity Mono client for this operating system."
            elif not (mono definition client root linux) then
                Error
                    "The selected Unity Mono client does not contain the supported Unity Mono runtime."
            else
                UnityValidation.version definition client.UnityMetadata root
                |> Option.map Ok
                |> Option.defaultValue (Error "The Unity version is unavailable.")
        with
        | :? BadImageFormatException ->
            Error "The Unity Mono client or Mono runtime has an unsupported executable format."
        | :? IOException ->
            Error "The Unity Mono client runtime is unavailable or changed during the check."
        | :? UnauthorizedAccessException -> Error "The Unity Mono client runtime cannot be read."
