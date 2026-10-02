namespace ModConductor.Native.Fixtures

open System
open System.IO
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform

module UnrealOrderFixtures =
    let private get = UnityMonoEnvironment.get

    let private controls binary =
        File.ReadAllLines(Path.Combine(binary, "ue4ss", "Mods", "mods.txt"))
        |> Array.filter (String.IsNullOrWhiteSpace >> not)
        |> Array.map (fun line ->
            let fields = line.Split ':'
            fields[0].Trim(), Int32.Parse(fields[1].Trim()) = 1)
        |> Array.toList

    let private regular (store: OperationStore) workspace root name =
        let source = Path.Combine(root, name, name, "scripts")
        Directory.CreateDirectory source |> ignore
        File.WriteAllText(Path.Combine(source, "main.lua"), "fixture script")
        let library = store.ModLibrary :> IModLibrary

        let entry =
            library.Register(
                workspace,
                Guid.NewGuid(),
                { Name = name
                  Version = "1"
                  Notes = ""
                  Comment = ""
                  Source = ""
                  Categories = [] },
                Registration.Directory(
                    ModKind.Regular,
                    LogicalPath.create [ name ] |> StorageWorker.result
                )
            )
            |> get

        library.Publish(entry.Id, entry.Revision, Guid.NewGuid()) |> get |> ignore
        entry.Id

    let observe check (store: OperationStore) workspace first second root binary sibling =
        let bundled = [ "Disabled", false; "Base", true ]
        let trailing = [ "Keybinds", true ]

        check
            "author bundled disabled controls and order survive normal deployment"
            (controls binary = bundled @ trailing)

        let beta = regular store workspace root "RegularBeta"
        let alpha = regular store workspace root "RegularAlpha"
        let selected = store.Unreal.Read(workspace, first) |> get
        let selection = store.ModSelection :> IModSelection

        let enabled =
            selection.Change(
                first,
                selected.SelectionRevision,
                [ beta; alpha ],
                SelectionEdit.Enable true
            )
            |> get

        UnityMonoEnvironment.deploy store first |> ignore

        check
            "enabled regular Lua priority preserves bundled controls and trailing keybinds"
            (controls binary = bundled @ [ "RegularBeta", true; "RegularAlpha", true ] @ trailing)

        let moved =
            selection.Change(first, enabled.Revision, [ alpha ], SelectionEdit.MoveUp)
            |> get

        UnityMonoEnvironment.deploy store first |> ignore

        check
            "moving a regular Lua mod changes its effective order without enabling bundled tools"
            (controls binary = bundled @ [ "RegularAlpha", true; "RegularBeta", true ] @ trailing)

        selection.Change(first, moved.Revision, [ beta ], SelectionEdit.Enable false)
        |> get
        |> ignore

        UnityMonoEnvironment.deploy store first |> ignore
        UnityMonoEnvironment.deploy store second |> ignore

        check
            "regular Lua disablement removes its files without changing sibling defaults or settings"
            (controls binary = bundled @ [ "RegularAlpha", true ] @ trailing
             && controls sibling = bundled @ trailing
             && not (Directory.Exists(Path.Combine(binary, "ue4ss", "Mods", "RegularBeta")))
             && not (Directory.Exists(Path.Combine(sibling, "ue4ss", "Mods", "RegularAlpha")))
             && File.ReadAllText(Path.Combine(binary, "ue4ss", "UE4SS-settings.ini")) = "Enabled = false\r\n"
             && File.ReadAllText(Path.Combine(sibling, "ue4ss", "UE4SS-settings.ini")) = "Enabled = true\r\n")
