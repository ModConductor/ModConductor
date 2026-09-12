namespace ModConductor.Native.Fixtures

open System.IO
open System.IO.Compression
open System.Text

module BainSamples =
    let entries =
        [ "Package/00 Core/textures/water.dds", "core"
          "Package/00 Core/meshes/bank.nif", "banks"
          "Package/00 Core/Riviere/settings.ini", "settings"
          "Package/02 Banks/meshes/bank.nif", "new-banks"
          "Package/10 Textures/textures/water.dds", "textures"
          "Package/2 Alternatives/Data/textures/water.dds", "alternative"
          "Package/2 Alternatives/Data/wizard.txt", "SelectSubPackage \"not-selected\""
          "Package/30 Foam/textures/foam.dds", "foam"
          "Package/package.txt",
          "Rivière textures\n00 Core contains the main files. Optional folders replace files in name order."
          "Package/wizard.txt",
          "SelectSubPackage \"30 Foam\"\nEditINI(\"not-run.ini\",\"Settings\",\"enabled\",\"true\")"
          "Package/Docs/notes.txt", "Not a package folder"
          "Package/-- ignored/textures/unused.dds", "Not installed" ]

    let write path entries =
        use stream = File.Create path
        use archive = new ZipArchive(stream, ZipArchiveMode.Create)

        for name, text in entries do
            use output = archive.CreateEntry(name).Open()
            output.Write(Encoding.UTF8.GetBytes(text: string))

    let create area =
        Directory.CreateDirectory area |> ignore
        write (Path.Combine(area, "Rivière textures.zip")) entries
        write (Path.Combine(area, "reversed.zip")) (List.rev entries)

        write
            (Path.Combine(area, "ambiguous.zip"))
            (entries @ [ "Package/Tools/tool.exe", "not executed" ])

        write (Path.Combine(area, "single.zip")) [ "Package/00 Core/textures/water.dds", "single" ]

        write
            (Path.Combine(area, "combined.zip"))
            (entries
             @ [ "Package/fomod/ModuleConfig.xml",
                 "<config><moduleName>XML choice</moduleName><requiredInstallFiles><file source='00 Core/textures/water.dds' destination='textures/from-xml.dds'/></requiredInstallFiles></config>" ])
