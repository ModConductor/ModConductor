namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.FilePlanning
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations

module internal GenerationSources =
    let read
        (database: StateDatabase)
        (access: LibraryAccess)
        profile
        roots
        snapshots
        writable
        components
        (retained: SavedProfile option)
        =
        task {
            let! read =
                database.Enqueue(fun () ->
                    use transaction = database.Connection.BeginTransaction(deferred = true)

                    let sources =
                        FilePlanRows.read database.Connection transaction database.OwnerId profile

                    let result =
                        sources
                        |> Result.map (fun sources ->
                            let sources =
                                match retained with
                                | None -> sources
                                | Some saved ->
                                    { sources with
                                        Profile =
                                            GenerationProfile.restore
                                                database.Connection
                                                transaction
                                                sources.Stamp.WorkspaceId
                                                saved
                                        Hidden = saved.Hidden }

                            let planning =
                                ComponentManifests.apply
                                    components
                                    { Profile = sources.Profile
                                      Roots = roots
                                      ReadOnly = snapshots |> List.map _.Snapshot
                                      Writable = writable }

                            let sources =
                                { sources with
                                    Profile = planning.Profile }

                            let saved =
                                retained
                                |> Option.defaultWith (fun () ->
                                    GenerationProfile.capture
                                        database.Connection
                                        transaction
                                        sources)

                            let payloads =
                                sources.Profile.Mods
                                |> List.collect (fun layer ->
                                    layer.Version
                                    |> Option.map (fun version ->
                                        version.Entries
                                        |> List.map (fun entry ->
                                            SourcePin.Mod(layer.ModId, version.Id, entry),
                                            entry.Payload))
                                    |> Option.defaultValue [])

                            let library =
                                LibraryRows.library
                                    database.Connection
                                    transaction
                                    sources.Stamp.WorkspaceId

                            let files =
                                payloads
                                |> List.map (fun (pin, payload) ->
                                    match
                                        LibraryRows.payload
                                            database.Connection
                                            transaction
                                            payload.Id
                                    with
                                    | Some row when row.Payload = payload -> pin, row
                                    | _ ->
                                        RecoveryFiles.fail
                                            "An exact managed payload is unavailable.")

                            sources, planning, library, files, saved)

                    transaction.Commit()
                    result)

            let sources, planning, library, files, saved =
                read
                |> Result.defaultWith (fun _ -> raise (RecoveryException RecoveryError.Stale))

            let! root = access.Root sources.Stamp.WorkspaceId

            let root =
                root
                |> Result.defaultWith (fun _ ->
                    RecoveryFiles.fail "The workspace ownership cannot be checked.")

            let managed =
                match library, files with
                | None, [] -> []
                | Some library, _ ->
                    use held = LibraryFiles.openLibrary root library

                    let directory: Location =
                        { Path =
                            HostPath.create (Path.Combine(HostPath.value root.Path, library.Name))
                            |> Result.defaultWith invalidOp
                          Identity = held.Identity }

                    files
                    |> List.map (fun (pin, payload) ->
                        pin,
                        { Directory = directory
                          Path =
                            GenerationFiles.logical [ LibraryFiles.payloadName payload.Payload.Id ]
                          Identity = payload.Identity
                          OwnerGeneration = None })
                | None, _ -> RecoveryFiles.fail "The recorded library is unavailable."

            let observed =
                snapshots
                |> List.collect (fun (snapshot: SnapshotSource) ->
                    snapshot.Snapshot.Files
                    |> List.map (fun file ->
                        let identity =
                            snapshot.Files.TryFind file.Path
                            |> Option.defaultWith (fun () ->
                                RecoveryFiles.fail "A snapshot file has no observed identity.")

                        let backing =
                            match snapshot.Originals.TryFind file.Path with
                            | Some original ->
                                { Directory =
                                    { Path = original.Root
                                      Identity = original.RootIdentity }
                                  Path = original.Path
                                  Identity = original.Identity
                                  OwnerGeneration = None }
                            | None ->
                                { Directory = snapshot.Directory
                                  Path = file.Path
                                  Identity = identity
                                  OwnerGeneration = None }

                        SourcePin.Snapshot(
                            snapshot.Snapshot.Id,
                            snapshot.Snapshot.Generation,
                            file
                        ),
                        backing))

            return
                { Input =
                    { Planning = planning
                      Hidden = sources.Hidden }
                  Stamp = sources.Stamp
                  Files = Map.ofList (managed @ observed) },
                saved
        }
