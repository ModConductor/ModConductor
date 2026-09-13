namespace ModConductor.Native.Fixtures

open System.IO
open ModConductor.Bethesda

module PluginOrderSamples =
    let files directory =
        let game, proton = ProtonFixtures.create directory

        for name in OrderRules.baseFiles do
            File.WriteAllBytes(
                Path.Combine(game, "Data", name),
                BethesdaSamples.header 1u 1.7f [] false
            )

        let source = Directory.CreateDirectory(Path.Combine(directory, "plugins")).FullName

        for name, flags, masters in
            [ "QuietRivers.esp", 0x200u, [ "Skyrim.esm" ]
              "RiverPatch.esp", 0u, [ "NorthernWater.esm" ]
              "RoadSigns.esp", 0u, [ "Skyrim.esm" ]
              "DistantWater.esp", 0u, [ "Skyrim.esm" ] ] do
            File.WriteAllBytes(
                Path.Combine(source, name),
                BethesdaSamples.header flags 1.71f masters false
            )

        Directory.CreateDirectory(
            Path.Combine(
                proton.CompatData,
                "pfx",
                "drive_c",
                "users",
                "steamuser",
                "AppData",
                "Local"
            )
        )
        |> ignore

        let executable = Path.Combine(proton.RuntimeDirectory, "proton")
        File.WriteAllText(executable, "#!/bin/sh\nexit 0\n")

        File.SetUnixFileMode(
            executable,
            UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
        )

        File.WriteAllText(
            Path.Combine(proton.RuntimeDirectory, "toolmanifest.vdf"),
            "manifest { version 2 commandline \"/proton %verb%\" }"
        )

        game
