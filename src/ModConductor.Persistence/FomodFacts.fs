namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Fomod
open ModConductor.ArchiveInstallation
open ModConductor.FilePlanning
open ModConductor.Platform

type internal FomodFactSnapshot =
    { Stamp: SourceStamp
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

        if
            revision <> snapshot.WorkspaceRevision
            || not selected
            || FilePlanRows.stamp connection transaction snapshot.Stamp.ProfileId
               <> Some snapshot.Stamp
        then
            refuse "The selected game or mods changed. Reload the installer before continuing."

    let capture (database: StateDatabase) workspace profile definition =
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
                            Fact.Unknown(
                                "MC cannot check whether "
                                + LogicalPath.display path
                                + " is active."
                            )
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
                  WorkspaceRevision = workspaceRevision
                  Facts = facts }

            do! database.EnqueueInternal(fun () -> current database.Connection null snapshot)
            return snapshot
        }
