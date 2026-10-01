namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.GameContexts
open ModConductor.Bethesda
open ModConductor.Deployment
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Workspaces
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform

module BethesdaRuntimeSwitchFixtures =
    let private get value =
        StorageWorker.wait value
        |> Result.defaultWith (fun error ->
            let detail =
                match box error with
                | :? DeploymentError as error ->
                    match error with
                    | DeploymentError.Blocked detail
                    | DeploymentError.Unavailable detail -> detail
                    | other -> other.ToString()
                | :? ProfileDataError as error ->
                    match error with
                    | ProfileDataError.Invalid detail
                    | ProfileDataError.Conflict detail
                    | ProfileDataError.Unavailable detail -> detail
                    | other -> other.ToString()
                | _ -> error.ToString()

            invalidOp ("Bethesda family request failed: " + detail))

    let private getData operation value =
        StorageWorker.wait value
        |> Result.defaultWith (fun error ->
            let detail =
                match error with
                | ProfileDataError.Invalid message
                | ProfileDataError.Unavailable message
                | ProfileDataError.Conflict message -> message
                | other -> other.ToString()

            invalidOp (operation + ": " + detail))

    let private token = CancellationToken.None

    let saves
        (store: OperationStore)
        workspace
        profile
        game
        root
        (rules: GameRules)
        (deploy: unit -> string)
        =
        let mutable saves = true

        if rules.GameSaves.IsSome then
            let shared = Path.Combine(game, rules.GameSaves.Value)
            let link = Path.Combine(root, rules.GameSaves.Value)
            saves <- Directory.ResolveLinkTarget(link, true).FullName = shared

            let change value =
                let current = store.ProfileGameData.Read(workspace, profile) |> get

                store.ProfileGameData.Edit(
                    { Id = Guid.NewGuid()
                      Expected = current.Reference
                      Options = { current.Options with Saves = value }
                      InitialSaves = InitialSaves.Empty
                      DisabledFiles = DisabledFiles.Keep },
                    ignore,
                    token
                )
                |> get
                |> ignore

            change true
            deploy () |> ignore
            let privatePath = (store.ProfileGameData.Read(workspace, profile) |> get).SavesPath
            saves <- saves && Directory.ResolveLinkTarget(link, true).FullName = privatePath
            File.WriteAllText(Path.Combine(link, "Profile.ess"), "private save")
            change false
            deploy () |> ignore

            saves <-
                saves
                && Directory.ResolveLinkTarget(link, true).FullName = shared
                && File.Exists(Path.Combine(privatePath, "Profile.ess"))
                && not (File.Exists(Path.Combine(shared, "Profile.ess")))

        saves

    let starfield
        (store: OperationStore)
        (ws: IWorkspaceState)
        workspace
        profile
        game
        proton
        output
        (deploy: unit -> string)
        (definition: GameDefinition)
        =
        let mutable sharedRestore = true

        if definition.Id = GameId.StarfieldSteam then
            let state = store.Deployments.Read profile |> get

            let prepared =
                store.Deployments.PrepareRetained(
                    Guid.NewGuid(),
                    state.Sources,
                    None,
                    ignore,
                    token
                )
                |> get

            store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, token)
            |> get
            |> ignore

            sharedRestore <-
                File.ReadAllText(Path.Combine(output, "User.txt")) = "preserved user file"
                && isNull (File.ResolveLinkTarget(Path.Combine(output, "User.txt"), false))
                && not (File.Exists(Path.Combine(output, "Example.esp")))
                && not (File.Exists(Path.Combine(output, "Starfield.esm")))
                && File.ReadAllText(Path.Combine(output, "meshes", "keep.txt")) = "user nested file"

            deploy () |> ignore
            let other = Guid.NewGuid()
            let workspaceState = ws.Read(workspace, None) |> get

            ws.Edit(
                workspace,
                workspaceState.Workspace.Revision,
                ProfileEdit.Create { Id = other; Name = "Other" }
            )
            |> get
            |> ignore

            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    other,
                    0L,
                    { GameId = definition.Id
                      Path = game
                      Proton = Some proton
                      Wine = None }
                )
            |> get
            |> ignore

            let otherState = store.Deployments.Read other |> get

            let otherPrepared =
                store.Deployments.Prepare(Guid.NewGuid(), otherState.Sources, ignore, token)
                |> get

            store.Deployments.Activate(otherPrepared.Id, otherPrepared.Sources, ignore, token)
            |> get
            |> ignore

            sharedRestore <-
                sharedRestore
                && File.ReadAllText(Path.Combine(output, "User.txt")) = "preserved user file"
                && not (File.Exists(Path.Combine(output, "Example.esp")))

            deploy () |> ignore

            sharedRestore <-
                sharedRestore
                && File.ReadAllText(Path.Combine(output, "User.txt")) = "mod replacement"

        sharedRestore

    let remastered
        (store: OperationStore)
        workspace
        profile
        modId
        root
        (deploy: unit -> string)
        (definition: GameDefinition)
        =
        if definition.Id <> GameId.OblivionRemasteredSteam then
            true
        else
            let saved = (store.Deployments.Read profile |> get).ActiveGeneration.Value
            let library = store.ModLibrary :> IModLibrary

            let modEntry =
                (library.Scan(workspace, 100) |> get).Entries
                |> List.find (fun row -> row.Id = modId)

            let workspaceState =
                (store.Workspaces :> IWorkspaceState).Read(workspace, None) |> get

            let source =
                Path.Combine(
                    HostPath.value workspaceState.Workspace.Path,
                    "mod",
                    "Paks",
                    "Example.pak"
                )

            File.WriteAllText(source, "new mod content")
            library.Publish(modId, modEntry.Revision, Guid.NewGuid()) |> get |> ignore
            deploy () |> ignore

            let output =
                Path.Combine(root, "OblivionRemastered", "Content", "Paks", "Example.pak")

            let latest = File.ReadAllText output = "new mod content"
            let current = store.Deployments.Read profile |> get

            let prepared =
                store.Deployments.PrepareRetained(
                    Guid.NewGuid(),
                    current.Sources,
                    Some saved,
                    ignore,
                    token
                )
                |> get

            store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, token)
            |> get
            |> ignore

            latest && File.ReadAllText output = "mod content"
