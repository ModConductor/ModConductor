namespace ModConductor.Persistence

open System
open ModConductor.Executables
open ModConductor.GeneratedOutputs
open ModConductor.ModLibrary
open ModConductor.Platform

/// Resolves storage without reading generated file contents. Deployment owns capture.
type internal ToolOutputStore
    (database: StateDatabase, library: ModLibraryStore, outputs: IGeneratedOutputs) =
    let failure =
        ExecutableError.Unavailable "The profile output folder is unavailable."

    let validate (location: OutputLocation) =
        task {
            let! root = library.Access.Root location.WorkspaceId

            match root with
            | Error _ -> return Error failure
            | Ok root ->
                let! stored =
                    database.Enqueue(fun () ->
                        OutputRows.find database.Connection null root location.Id)

                try
                    match stored |> Option.bind _.RootIdentity with
                    | None -> return Error failure
                    | Some identity ->
                        use directory =
                            HeldDirectory.Open(
                                HostPath.create location.PhysicalPath
                                |> Result.defaultWith invalidOp,
                                identity
                            )

                        return Ok()
                with
                | :? IO.IOException
                | :? UnauthorizedAccessException -> return Error failure
        }

    let register profile (location: OutputLocation) =
        task {
            let! existing =
                database.Enqueue(fun () -> LibraryRows.find database.Connection null location.Id)

            let! registered =
                match existing with
                | Some row when
                    row.Entry.WorkspaceId = location.WorkspaceId
                    && row.Entry.Kind = ModKind.GeneratedOutput
                    && (row.Entry.SourcePath |> Option.map LogicalPath.components) = Some
                        [ IO.Path.GetFileName location.PhysicalPath ]
                    ->
                    System.Threading.Tasks.Task.FromResult(Ok row.Entry)
                | Some _ ->
                    System.Threading.Tasks.Task.FromResult(Error LibraryError.IdentityConflict)
                | None ->
                    (library :> IModLibrary)
                        .Register(
                            location.WorkspaceId,
                            location.Id,
                            { Name = location.Name
                              Version = ""
                              Notes = ""
                              Comment = ""
                              Source = ""
                              Categories = [] },
                            Registration.NativeDirectory(
                                ModKind.GeneratedOutput,
                                HostPath.create location.PhysicalPath
                                |> Result.defaultWith invalidOp
                            )
                        )

            match registered with
            | Error _ -> return Error failure
            | Ok _ ->
                do!
                    database.Enqueue(fun () ->
                        let connection = database.Connection
                        use transaction = connection.BeginTransaction(deferred = false)

                        if
                            SelectionRows.find connection transaction profile location.Id
                            |> Option.isNone
                        then
                            Sqlite.execute
                                connection
                                transaction
                                "INSERT INTO profile_mods(profile_id,mod_id,priority,enabled) SELECT $profile,$mod,COALESCE(MAX(priority)+1,0),1 FROM profile_mods WHERE profile_id=$profile"
                                [ "$profile", box (string profile)
                                  "$mod", box (string location.Id) ]

                            Sqlite.execute
                                connection
                                transaction
                                "UPDATE profiles SET selection_revision=selection_revision+1 WHERE id=$profile"
                                [ "$profile", box (string profile) ]

                        transaction.Commit())

                return Ok location.PhysicalPath
        }

    member _.Resolve(workspace, profile, name: string option) =
        task {
            match name with
            | None -> return Ok None
            | Some name ->
                let! read = outputs.Read(workspace, profile, None)

                match read with
                | Error _ -> return Error failure
                | Ok scope ->
                    let matching =
                        scope.Locations
                        |> List.filter (fun location ->
                            location.Name = name && location.Purpose = OutputPurpose.ToolFolder)

                    let! location =
                        match matching with
                        | [] -> outputs.Add(Guid.NewGuid(), scope, name, OutputPurpose.ToolFolder)
                        | [ location ] when location.State = OutputLocationState.Ready ->
                            System.Threading.Tasks.Task.FromResult(Ok location)
                        | _ ->
                            System.Threading.Tasks.Task.FromResult(
                                Error(
                                    OutputError.Invalid
                                        "Choose an available, unambiguous output folder."
                                )
                            )

                    match location with
                    | Error _ -> return Error failure
                    | Ok location ->
                        let! ownership = validate location

                        match ownership with
                        | Error error -> return Error error
                        | Ok() ->
                            let! registered = register profile location
                            return registered |> Result.map Some
        }
