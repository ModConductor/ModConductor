namespace ModConductor.Persistence

open System
open ModConductor.Platform
open ModConductor.ModMaintenance
open ModConductor.DeploymentRecovery

type internal DeletionEffect =
    { Sequence: int
      Kind: DeletionFileKind
      Root: HostPath
      RootIdentity: FileIdentity
      Path: LogicalPath
      Identity: FileIdentity option
      Label: string
      Bytes: int64 option }

type internal DeletionState =
    { View: DeletionPreview
      Targets: Guid list
      Versions: Guid list
      Payloads: Guid list
      PrivatePayloads: Guid list
      Artifacts: Guid list
      Effects: DeletionEffect list
      Generations: (Guid * Generation) list }

module internal DeletionQueries =
    let ids connection transaction sql parameters =
        use query = Sqlite.command connection transaction sql parameters
        use reader = query.ExecuteReader()

        [ while reader.Read() do
              yield Guid.Parse(reader.GetString 0) ]

    let targets connection transaction modId =
        modId
        :: ids
            connection
            transaction
            "SELECT id FROM mods WHERE kind=3 AND current_version IN (SELECT id FROM mod_versions WHERE mod_id=$mod) ORDER BY id"
            [ "$mod", box (string modId) ]

    let versions connection transaction targets =
        targets
        |> List.collect (fun modId ->
            ids
                connection
                transaction
                "SELECT id FROM mod_versions WHERE mod_id=$mod ORDER BY id"
                [ "$mod", box (string modId) ])

    let generations connection transaction workspace =
        let contexts =
            ids connection transaction "SELECT id FROM deployment_contexts ORDER BY id" []

        [ for id in contexts do
              let context = DeploymentRows.context connection transaction id |> Option.get

              if context.Roots |> List.exists (fun root -> root.Root.Id = workspace) then
                  for generation in
                      ids
                          connection
                          transaction
                          "SELECT id FROM deployment_generations WHERE context_id=$id ORDER BY id"
                          [ "$id", box (string id) ] do
                      yield
                          context,
                          DeploymentRows.generation connection transaction id generation
                          |> Option.get ]

    let includes targets (generation: Generation) =
        (generation.References
         |> List.exists (function
             | ModConductor.DeploymentPlanning.SourcePin.Mod(id, _, _) -> Set.contains id targets
             | _ -> false))
        || (generation.Provenance
            |> Option.bind _.Profile
            |> Option.exists (fun profile ->
                profile.Mods |> List.exists (fun entry -> targets |> Set.contains entry.ModId)))

    let uses targets (generation: Generation) =
        generation.References
        |> List.exists (function
            | ModConductor.DeploymentPlanning.SourcePin.Mod(id, _, _) -> Set.contains id targets
            | _ -> false)
