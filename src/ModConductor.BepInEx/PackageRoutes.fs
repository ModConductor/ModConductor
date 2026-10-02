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

    let logs =
        [ Guid "18921d2b-c276-41d5-a0bc-38eceecf09d0", "LogOutput.log"
          Guid "b382b085-cffe-4615-ab34-b12b21db045f", "LogOutput.log.1"
          Guid "d060cc9e-fda2-4c7d-adb7-399c3362b849", "LogOutput.log.2"
          Guid "b0878edb-8526-40d5-bc9e-4c63b7948697", "LogOutput.log.3"
          Guid "b4e824b3-e988-4bf8-b0d5-3154d323b804", "LogOutput.log.4" ]

    let private path names =
        LogicalPath.create names |> Result.defaultWith (string >> invalidOp)

    let declarations gameRoot =
        [ for id, name in [ config, "config"; cache, "cache"; assemblies, "DumpedAssemblies" ] do
              yield
                  { Id = id
                    Target = WritableTarget.Subtree(gameRoot, PlanPath.At(path [ "BepInEx"; name ])) }
          for id, name in logs do
              yield
                  { Id = id
                    Target = WritableTarget.File(gameRoot, path [ "BepInEx"; name ]) } ]

module PackageRoutes =
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

    let review dataRoot gameRoot policy role (selected: SelectedMod) =
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
                            Writable = WorkingPaths.declarations gameRoot }
                    | PackageRole.Plugin -> reviewed))
