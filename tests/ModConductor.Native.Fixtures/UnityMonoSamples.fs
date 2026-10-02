namespace ModConductor.Native.Fixtures

open System
open System.Buffers.Binary
open System.IO
open System.IO.Compression
open System.Reflection
open System.Reflection.Metadata
open System.Reflection.Metadata.Ecma335
open System.Reflection.PortableExecutable
open System.Text
open ModConductor.GameContexts

module UnityMonoSamples =
    let elf () =
        let bytes = Array.zeroCreate<byte> 64
        [| 0x7fuy; 0x45uy; 0x4cuy; 0x46uy; 2uy; 1uy |].CopyTo(bytes, 0)
        BinaryPrimitives.WriteUInt16LittleEndian(bytes.AsSpan(18, 2), 62us)
        bytes

    let managed () =
        let metadata = MetadataBuilder()

        metadata.AddModule(
            0,
            metadata.GetOrAddString "Assembly-CSharp.dll",
            metadata.GetOrAddGuid(Guid.NewGuid()),
            Unchecked.defaultof<GuidHandle>,
            Unchecked.defaultof<GuidHandle>
        )
        |> ignore

        metadata.AddAssembly(
            metadata.GetOrAddString "Assembly-CSharp",
            Version(1, 0, 0, 0),
            Unchecked.defaultof<StringHandle>,
            Unchecked.defaultof<BlobHandle>,
            enum<AssemblyFlags> 0,
            AssemblyHashAlgorithm.None
        )
        |> ignore

        let pe =
            ManagedPEBuilder(
                PEHeaderBuilder.CreateLibraryHeader(),
                MetadataRootBuilder metadata,
                BlobBuilder()
            )

        let bytes = BlobBuilder()
        pe.Serialize bytes |> ignore
        bytes.ToArray()

    let create (definition: GameDefinition) path =
        let client = GameClient.mono definition |> Option.get
        let data = Directory.CreateDirectory(Path.Combine(path, definition.Data)).FullName
        GameContextFixtures.createFor definition false path
        let windows = File.ReadAllBytes(Path.Combine(path, definition.Executable))

        let write relative (bytes: byte array) =
            let target = Path.Combine(data, relative)
            Directory.CreateDirectory(Path.GetDirectoryName target) |> ignore
            File.WriteAllBytes(target, bytes)

        write client.ManagedAssembly (managed ())
        write client.WindowsRuntime windows
        write client.LinuxRuntime (elf ())
        write client.UnityMetadata (Encoding.ASCII.GetBytes("\0006000.0.75f1\000fixture"))
        File.WriteAllBytes(Path.Combine(path, client.LinuxExecutable), elf ())
        File.WriteAllText(Path.Combine(path, "UnityPlayer.so"), "linked game engine")
        File.WriteAllText(Path.Combine(data, "assets.dat"), "linked asset")

        if OperatingSystem.IsLinux() then
            File.SetUnixFileMode(
                Path.Combine(path, client.LinuxExecutable),
                UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
            )

        path

    let package files =
        use bytes = new MemoryStream()

        do
            use zip = new ZipArchive(bytes, ZipArchiveMode.Create, true)

            for name, content in files do
                use entry = zip.CreateEntry(name).Open()
                entry.Write(Encoding.UTF8.GetBytes(content: string))

        bytes.ToArray()

    let loader () =
        package
            [ "BepInExPack_Valheim/start_game_bepinex.sh", "#!/bin/sh\nexec \"$@\"\n"
              "BepInExPack_Valheim/winhttp.dll", "native Windows proxy fixture"
              "BepInExPack_Valheim/doorstop_config.ini", "[General]\nenabled=true\n"
              "BepInExPack_Valheim/BepInEx/core/BepInEx.Preloader.dll", "loader fixture"
              "BepInExPack_Valheim/BepInEx/config/BepInEx.cfg",
              "[Logging.Disk]\r\nEnabled = true\r\n"
              "manifest.json", "{}" ]

    let plugin () =
        package
            [ "plugins\\Jotunn.dll", "plugin fixture"
              "config/Fixture.cfg", "Enabled = true\n"
              "README.md", "fixture metadata" ]
