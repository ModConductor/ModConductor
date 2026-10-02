namespace ModConductor.BepInEx

open System
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning

/// These identities name profile working directories. They do not depend on a package version.
module WorkingPaths =
    let config = Guid "e5aa3499-8da0-4d61-a4c7-f4bd8b598012"
    let cache = Guid "4f286d77-b34a-444e-8939-564d18d18cae"
    let assemblies = Guid "343d977d-e643-4862-b0ac-dae8357d6ff7"

    let interop = Guid "382a5899-1491-4420-9c0c-083dcc40bec3"
    let unityLibraries = Guid "4b8a9d04-6c60-4bd0-9f7c-36a4157c9cbd"
    let dummy = Guid "47c33c31-8f86-46f5-a7cc-933716e548b5"

    let log = Guid "18921d2b-c276-41d5-a0bc-38eceecf09d0"
    let errorLog = Guid "489a1e4d-5493-442b-9c67-eae0186c7d8b"

    let logs backend =
        [ log, "LogOutput.log"
          Guid "b382b085-cffe-4615-ab34-b12b21db045f", "LogOutput.log.1"
          Guid "d060cc9e-fda2-4c7d-adb7-399c3362b849", "LogOutput.log.2"
          Guid "b0878edb-8526-40d5-bc9e-4c63b7948697", "LogOutput.log.3"
          Guid "b4e824b3-e988-4bf8-b0d5-3154d323b804", "LogOutput.log.4" ]
        |> List.mapi (fun index (id, name) ->
            id,
            if backend = ModConductor.GameContexts.UnityBackend.Il2Cpp && index > 0 then
                "LogOutput."
                + index.ToString(Globalization.CultureInfo.InvariantCulture)
                + ".log"
            else
                name)
        |> fun logs ->
            match backend with
            | ModConductor.GameContexts.UnityBackend.Mono -> logs
            | ModConductor.GameContexts.UnityBackend.Il2Cpp -> logs @ [ errorLog, "ErrorLog.log" ]

    let private path names =
        LogicalPath.create names |> Result.defaultWith (string >> invalidOp)

    let declarations backend gameRoot =
        let directories =
            [ config, "config"; cache, "cache"; assemblies, "DumpedAssemblies" ]
            @ (match backend with
               | ModConductor.GameContexts.UnityBackend.Mono -> []
               | ModConductor.GameContexts.UnityBackend.Il2Cpp ->
                   [ interop, "interop"; unityLibraries, "unity-libs"; dummy, "dummy" ])

        [ for id, name in directories do
              yield
                  { Id = id
                    Target = WritableTarget.Subtree(gameRoot, PlanPath.At(path [ "BepInEx"; name ])) }
          for id, name in logs backend do
              yield
                  { Id = id
                    Target = WritableTarget.File(gameRoot, path [ "BepInEx"; name ]) } ]

module PackageRoutes =
    let normalDirectories (reviewed: ReviewedComponent) =
        if
            reviewed.Writable
            |> List.exists (fun declaration -> declaration.Id = WorkingPaths.errorLog)
        then
            [ for name in [ "plugins"; "patchers" ] do
                  yield
                      { Root = reviewed.GameRoot
                        Path =
                          LogicalPath.create [ "BepInEx"; name ]
                          |> Result.defaultWith (string >> invalidOp) } ]
        else
            []

    let private same left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private destination role parts =
        match role, parts with
        | PackageRole.Loader prefix, first :: rest when same prefix first && not rest.IsEmpty ->
            rest
        | PackageRole.Loader _, _ -> parts
        | PackageRole.Plugin, first :: rest when same "BepInEx" first -> "BepInEx" :: rest
        | PackageRole.Plugin, first :: _ when
            same "plugins" first || same "patchers" first || same "config" first
            ->
            "BepInEx" :: parts
        | PackageRole.Plugin, _ -> "BepInEx" :: "plugins" :: parts

    let review dataRoot gameRoot policy backend role (selected: SelectedMod) =
        match selected.Version with
        | None -> Error "The selected package version is unavailable."
        | Some version ->
            let files =
                version.Entries
                |> List.fold
                    (fun state entry ->
                        state
                        |> Result.bind (fun files ->
                            LogicalPath.components entry.Path
                            |> destination role
                            |> LogicalPath.create
                            |> Result.mapError (fun _ -> "The package destination is invalid.")
                            |> Result.map (fun target ->
                                { Source = entry.Path
                                  Root = ComponentRoot.GameRoot
                                  Destination = target
                                  Use = ComponentFileUse.Immutable }
                                :: files)))
                    (Ok [])

            files
            |> Result.bind (fun files ->
                ComponentManifests.review
                    dataRoot
                    gameRoot
                    policy
                    { ModId = selected.ModId
                      Version = version
                      Priority = selected.Priority
                      Files = List.rev files }
                |> Result.mapError (fun _ ->
                    "The package routes conflict with their declared locations.")
                |> Result.map (fun reviewed ->
                    match role with
                    | PackageRole.Loader _ ->
                        { reviewed with
                            Writable = WorkingPaths.declarations backend gameRoot }
                    | PackageRole.Plugin -> reviewed))
