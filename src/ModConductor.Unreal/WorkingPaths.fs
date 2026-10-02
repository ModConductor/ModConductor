namespace ModConductor.Unreal

open System
open System.IO
open System.Security.Cryptography
open System.Text
open ModConductor.GameContexts
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module WorkingPaths =
    let parts (path: string) =
        path.Replace('\\', '/').Split('/', StringSplitOptions.RemoveEmptyEntries)
        |> Array.toList

    let binary (definition: GameDefinition) =
        parts definition.Executable |> List.rev |> List.tail |> List.rev

    let logical names =
        LogicalPath.create names |> Result.defaultWith (string >> invalidOp)

    let id (loader: UnrealLoaderDeclaration) relative =
        Guid(
            SHA256
                .HashData(
                    Encoding.UTF8.GetBytes("mc-unreal-working-v1:" + loader.Id + ":" + relative)
                )
                .AsSpan(0, 16)
        )

    let settings (definition: GameDefinition) (client: UnrealClient) =
        match client.Loader.Mechanism with
        | UnrealModMechanism.CookedPlugins layout -> layout.Configs, true
        | UnrealModMechanism.UE4SS layout ->
            String.concat "/" (binary definition @ parts layout.SettingsFile), false

    let log (definition: GameDefinition) (client: UnrealClient) =
        match client.Loader.Mechanism with
        | UnrealModMechanism.CookedPlugins _ -> client.LogDirectory + "/game.log"
        | UnrealModMechanism.UE4SS layout ->
            String.concat "/" (binary definition @ parts layout.Log)

    let declarations definition client gameRoot =
        let settings, directory = settings definition client

        let make relative directory =
            let path = logical (parts relative)

            { Id = id client.Loader relative
              Target =
                if directory then
                    WritableTarget.Subtree(gameRoot, PlanPath.At path)
                else
                    WritableTarget.File(gameRoot, path) }

        [ make settings directory
          match client.Loader.Mechanism with
          | UnrealModMechanism.CookedPlugins _ -> make client.LogDirectory true
          | UnrealModMechanism.UE4SS layout ->
              make (log definition client) false

              for path in layout.Cache do
                  let relative, directory =
                      match path with
                      | LoaderWorkingPath.File relative -> relative, false
                      | LoaderWorkingPath.Directory relative -> relative, true

                  make (String.concat "/" (binary definition @ parts relative)) directory ]

    let exclusions definition client =
        client.Excluded
        @ [ client.LogDirectory ]
        @ (match client.Loader.Mechanism with
           | UnrealModMechanism.CookedPlugins layout ->
               [ layout.Mods; layout.GameFeatures; layout.Configs ]
           | UnrealModMechanism.UE4SS layout ->
               let cache =
                   layout.Cache
                   |> List.map (function
                       | LoaderWorkingPath.File relative
                       | LoaderWorkingPath.Directory relative -> relative)

               layout.Proxy
               :: layout.Core
               :: layout.Mods
               :: layout.SettingsFile
               :: layout.Log
               :: cache
               |> List.map (fun relative -> String.concat "/" (binary definition @ parts relative)))
