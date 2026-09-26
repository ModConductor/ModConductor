namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Fomod
open ModConductor.ArchiveInstallation
open ModConductor.FilePlanning
open ModConductor.Platform

type internal FomodFactSnapshot =
    { Stamp: SourceStamp
      ProfileData: (Guid * int64) option
      WorkspaceRevision: int64
      Facts: Facts }

module internal FomodFacts =
    let private refuse message = raise (FomodException message)

    let private plugin path =
        [ ".esp"; ".esm"; ".esl" ]
        |> List.contains (Path.GetExtension(LogicalPath.display path).ToLowerInvariant())

    let current connection transaction (snapshot: FomodFactSnapshot) =
        let selected =
            Sqlite.number
                connection
                transaction
                "SELECT count(*) FROM workspaces WHERE id=$workspace AND selected_profile=$profile"
                [ "$workspace", box (string snapshot.Stamp.WorkspaceId)
                  "$profile", box (string snapshot.Stamp.ProfileId) ] = 1L

        let revision =
            Sqlite.number
                connection
                transaction
                "SELECT revision FROM workspaces WHERE id=$id"
                [ "$id", box (string snapshot.Stamp.WorkspaceId) ]

        snapshot.ProfileData
        |> Option.iter (fun (context, revision) ->
            let current =
                ProfileDataRows.context connection transaction context
                |> Option.map _.Revision
                |> Option.defaultValue 0L

            if current <> revision then
                refuse "The plugin order changed. Reload the installer before continuing.")

        if
            revision <> snapshot.WorkspaceRevision
            || not selected
            || FilePlanRows.stamp connection transaction snapshot.Stamp.ProfileId
               <> Some snapshot.Stamp
        then
            refuse "The selected game or mods changed. Reload the installer before continuing."

    let capture (database: StateDatabase) access workspace profile definition =
        task {
            let! sources =
                database.EnqueueInternal(fun () ->
                    FilePlanRows.read database.Connection null database.OwnerId profile
                    |> Result.defaultWith (fun _ ->
                        refuse
                            "The selected profile files cannot be checked. Reload the installer."))

            if sources.Stamp.WorkspaceId <> workspace then
                refuse "Choose a profile in this workspace."

            let! workspaceRevision =
                database.EnqueueInternal(fun () ->
                    Sqlite.number
                        database.Connection
                        null
                        "SELECT revision FROM workspaces WHERE id=$id"
                        [ "$id", box (string workspace) ])

            let paths = Conditions.filePaths definition

            let! pluginOrder =
                task {
                    if paths |> List.exists plugin then
                        let reader =
                            ModConductor.Bethesda.PluginSession(
                                FilePlanRepository(database, access)
                            )

                        try
                            let! scanned = reader.Observe(profile, Threading.CancellationToken.None)

                            match scanned with
                            | Ok headers when not headers.Stale ->
                                try
                                    let repository =
                                        ProfileDataRepository(database, access)
                                        :> ModConductor.ProfileGameData.IProfileDataRepository

                                    let! scope = repository.Read(workspace, profile)

                                    let inputs =
                                        ModConductor.ProfileGameData.PluginInputs.read
                                            scope
                                            headers.Entries
                                            Threading.CancellationToken.None

                                    return
                                        inputs
                                        |> Result.toOption
                                        |> Option.map (fun value ->
                                            ModConductor.ProfileGameData.PluginOrders.view
                                                scope
                                                headers
                                                value)
                                with
                                | ModConductor.ProfileGameData.ProfileDataException _ -> return None
                                | :? IOException -> return None
                                | :? UnauthorizedAccessException -> return None
                            | _ -> return None
                        finally
                            reader.TryClose() |> ignore
                    else
                        return None
                }

            let pluginFact path =
                let name = LogicalPath.display path

                let unknown () =
                    Fact.Unknown("MC cannot check whether " + name + " is active.")

                match pluginOrder with
                | Some order when
                    not order.Pending
                    && not order.ExternalChanged
                    && order.View.Issues.IsEmpty
                    && order.Headers.Problems.IsEmpty
                    ->
                    match
                        order.Headers.Entries
                        |> List.tryFind (fun entry ->
                            entry.Name.Equals(name, StringComparison.OrdinalIgnoreCase))
                    with
                    | Some entry when Result.isError entry.Header -> unknown ()
                    | Some _ ->
                        match
                            order.View.Order.Entries
                            |> List.tryFind (fun entry ->
                                entry.Name.Equals(name, StringComparison.OrdinalIgnoreCase))
                        with
                        | Some entry when entry.Enabled = Some true -> Fact.Known FileState.Active
                        | Some entry when entry.Enabled = Some false ->
                            Fact.Known FileState.Inactive
                        | _ -> unknown ()
                    | None -> Fact.Known FileState.Missing
                | _ -> unknown ()

            let nonPlugin = paths |> List.filter (plugin >> not)
            let enabled = System.Collections.Generic.HashSet<string>()
            let disabled = System.Collections.Generic.HashSet<string>()
            let mutable incomplete = false

            for selected in sources.Profile.Mods do
                match selected.Version with
                | None -> incomplete <- true
                | Some version ->
                    for entry in version.Entries do
                        let hidden =
                            sources.Hidden.Contains
                                { ModId = selected.ModId
                                  VersionId = version.Id
                                  Path = entry.Path }

                        if not hidden then
                            if selected.Enabled then
                                enabled.Add(Destinations.key entry.Path) |> ignore
                            else
                                disabled.Add(Destinations.key entry.Path) |> ignore

            let toObserve =
                nonPlugin
                |> List.filter (fun path -> not (enabled.Contains(Destinations.key path)))

            let! game =
                if toObserve.IsEmpty then
                    System.Threading.Tasks.Task.FromResult Map.empty
                else
                    System.Threading.Tasks.Task.Run(fun () ->
                        FomodGameFacts.observe sources.Context.Binding toObserve)

            let values =
                paths
                |> List.map (fun path ->
                    let key = Destinations.key path

                    let value =
                        if plugin path then
                            pluginFact path
                        elif enabled.Contains key then
                            Fact.Known FileState.Active
                        else
                            match game[path] with
                            | Fact.Known FileState.Active -> Fact.Known FileState.Active
                            | Fact.Unknown why -> Fact.Unknown why
                            | _ when incomplete ->
                                Fact.Unknown
                                    "Some mods have no published files to check. Publish their files or use the manual layout."
                            | _ when disabled.Contains key -> Fact.Known FileState.Inactive
                            | _ -> Fact.Known FileState.Missing

                    key, value)
                |> Map.ofList

            let gameVersion =
                sources.Context.Binding
                |> Option.filter (fun binding -> not binding.NeedsCheck && binding.Evidence.Valid)
                |> Option.bind _.Evidence.Executable
                |> Option.map (fun executable -> Fact.Known executable.FileVersion)
                |> Option.defaultValue (
                    Fact.Unknown
                        "The game version cannot be checked. Refresh the game context or use the manual layout."
                )

            let facts =
                { GameVersion = gameVersion
                  Files = values
                  FommVersion =
                    Fact.Unknown "MC cannot check the required FOMM version. Use the manual layout."
                  ExtenderVersion =
                    Fact.Unknown
                        "MC cannot check the required script extender version. Use the manual layout." }

            let snapshot =
                { Stamp = sources.Stamp
                  ProfileData =
                    pluginOrder
                    |> Option.map (fun value -> value.Reference.ContextId, value.Reference.Revision)
                  WorkspaceRevision = workspaceRevision
                  Facts = facts }

            do! database.EnqueueInternal(fun () -> current database.Connection null snapshot)
            return snapshot
        }
