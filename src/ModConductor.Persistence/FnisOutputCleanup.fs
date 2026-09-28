namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.DeploymentPlanning
open ModConductor.ModLibrary
open ModConductor.Platform

module internal FnisOutputCleanup =
    let private ids connection transaction sql args =
        use query = Sqlite.command connection transaction sql args
        use reader = query.ExecuteReader()

        [ while reader.Read() do
              yield Guid.Parse(reader.GetString 0) ]

    let private pinned connection transaction modId version =
        let selected =
            Sqlite.number
                connection
                transaction
                "SELECT (SELECT count(*) FROM mods WHERE id=$mod AND current_version=$version)+(SELECT count(*) FROM fnis_outputs WHERE mod_id=$mod AND version_id=$version)"
                [ "$mod", box (string modId); "$version", box (string version) ] > 0L

        let referenced =
            use query =
                Sqlite.command
                    connection
                    transaction
                    "SELECT context_id,id,saved FROM deployment_generations"
                    []

            use reader = query.ExecuteReader()

            let generations =
                [ while reader.Read() do
                      yield
                          Guid.Parse(reader.GetString 0),
                          Guid.Parse(reader.GetString 1),
                          reader.GetInt64 2 = 1L ]

            reader.Close()

            generations
            |> List.exists (fun (contextId, generationId, saved) ->
                let context = DeploymentRows.context connection transaction contextId

                let active =
                    context |> Option.exists (fun value -> value.Active = Some generationId)

                if not saved && not active then
                    false
                else
                    let generation =
                        DeploymentRows.generation connection transaction contextId generationId

                    generation
                    |> Option.exists (fun value ->
                        (value.References
                         |> List.exists (function
                             | SourcePin.Mod(id, selected, _) -> id = modId && selected = version
                             | _ -> false))
                        || (value.Provenance
                            |> Option.bind _.Profile
                            |> Option.exists (fun profile ->
                                profile.Mods
                                |> List.exists (fun row ->
                                    row.ModId = modId && row.VersionId = Some version)))))

        selected || referenced

    let pruneVersion (database: StateDatabase) (access: LibraryAccess) workspace modId version =
        task {
            let! snapshot =
                database.Enqueue(fun () ->
                    let connection = database.Connection
                    use transaction = connection.BeginTransaction(deferred = true)

                    let result =
                        if pinned connection transaction modId version then
                            None
                        else
                            let payloads =
                                ids
                                    connection
                                    transaction
                                    "SELECT id FROM mod_payloads WHERE publication_id=$version UNION SELECT payload_id FROM mod_manifest WHERE version_id=$version"
                                    [ "$version", box (string version) ]

                            let exclusive =
                                payloads
                                |> List.filter (fun id ->
                                    Sqlite.number
                                        connection
                                        transaction
                                        "SELECT count(*) FROM mod_manifest WHERE payload_id=$id AND version_id<>$version"
                                        [ "$id", box (string id)
                                          "$version", box (string version) ] = 0L)

                            Some exclusive

                    transaction.Commit()
                    result)

            match snapshot with
            | None -> return false
            | Some exclusive ->
                if not exclusive.IsEmpty then
                    let! root = access.Root workspace

                    let root =
                        root
                        |> Result.defaultWith (fun _ ->
                            raise (IOException "The FNIS output library is unavailable."))

                    let! library =
                        database.Enqueue(fun () ->
                            LibraryRows.library database.Connection null workspace)

                    let library =
                        library
                        |> Option.defaultWith (fun () ->
                            raise (IOException "The FNIS output library is unavailable."))

                    use directory = LibraryFiles.openLibrary root library

                    for id in exclusive do
                        let name = LibraryFiles.payloadName id

                        match directory.InspectEntry name with
                        | Some entry when entry.Kind = EntryKind.RegularFile ->
                            directory.RemoveFile(name, entry.Identity)
                        | None -> ()
                        | Some _ -> raise (IOException "The FNIS output file changed.")

                do!
                    database.EnqueueInternal(fun () ->
                        let connection = database.Connection
                        use transaction = connection.BeginTransaction(deferred = false)

                        Sqlite.execute
                            connection
                            transaction
                            "DELETE FROM hidden_mod_files WHERE version_id=$version; DELETE FROM mod_manifest WHERE version_id=$version"
                            [ "$version", box (string version) ]

                        let shared =
                            ids
                                connection
                                transaction
                                "SELECT id FROM mod_payloads WHERE publication_id=$version"
                                [ "$version", box (string version) ]

                        for id in shared do
                            if List.contains id exclusive then
                                Sqlite.execute
                                    connection
                                    transaction
                                    "DELETE FROM mod_payloads WHERE id=$id"
                                    [ "$id", box (string id) ]
                            else
                                Sqlite.execute
                                    connection
                                    transaction
                                    "UPDATE mod_payloads SET publication_id=(SELECT version_id FROM mod_manifest WHERE payload_id=$id LIMIT 1) WHERE id=$id"
                                    [ "$id", box (string id) ]

                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE mod_version_origins SET source_version=NULL WHERE source_version=$version; DELETE FROM mod_version_origins WHERE version_id=$version; DELETE FROM mod_versions WHERE id=$version"
                            [ "$version", box (string version) ]

                        Sqlite.execute
                            connection
                            transaction
                            "DELETE FROM mods WHERE id=$mod AND kind=5 AND current_version IS NULL AND NOT EXISTS(SELECT 1 FROM mod_versions WHERE mod_id=$mod) AND NOT EXISTS(SELECT 1 FROM fnis_outputs WHERE mod_id=$mod)"
                            [ "$mod", box (string modId) ]

                        transaction.Commit())

                return true
        }

    let removeProfileFiles (database: StateDatabase) (access: LibraryAccess) workspace profile =
        task {
            let! output =
                database.Enqueue(fun () ->
                    let connection = database.Connection
                    use transaction = connection.BeginTransaction(deferred = true)

                    use command =
                        Sqlite.command
                            connection
                            transaction
                            "SELECT output_mod_id FROM fnis_runs WHERE profile_id=$profile AND workspace_id=$workspace UNION SELECT mod_id FROM fnis_outputs WHERE profile_id=$profile AND workspace_id=$workspace UNION SELECT id FROM mods WHERE id=$output AND workspace_id=$workspace AND kind=5 LIMIT 1"
                            [ "$profile", box (string profile)
                              "$workspace", box (string workspace)
                              "$output", box (string (FnisRunRows.outputId profile)) ]

                    let modId =
                        match command.ExecuteScalar() with
                        | :? string as id -> Some(Guid.Parse id)
                        | _ -> None

                    let payloads =
                        modId
                        |> Option.map (fun id ->
                            ids
                                connection
                                transaction
                                "SELECT DISTINCT p.id FROM mod_payloads p JOIN mod_versions v ON v.id=p.publication_id WHERE v.mod_id=$mod AND NOT EXISTS(SELECT 1 FROM mod_manifest m JOIN mod_versions other ON other.id=m.version_id WHERE m.payload_id=p.id AND other.mod_id<>$mod)"
                                [ "$mod", box (string id) ])
                        |> Option.defaultValue []

                    transaction.Commit()
                    modId, payloads)

            let modId, payloads = output

            if not payloads.IsEmpty then
                let! root = access.Root workspace

                let root =
                    root
                    |> Result.defaultWith (fun _ ->
                        raise (IOException "The FNIS output library is unavailable."))

                let! library =
                    database.Enqueue(fun () ->
                        LibraryRows.library database.Connection null workspace)

                let library =
                    library
                    |> Option.defaultWith (fun () ->
                        raise (IOException "The FNIS output library is unavailable."))

                use directory = LibraryFiles.openLibrary root library

                for id in payloads do
                    let name = LibraryFiles.payloadName id

                    match directory.InspectEntry name with
                    | Some entry when entry.Kind = EntryKind.RegularFile ->
                        directory.RemoveFile(name, entry.Identity)
                    | None -> ()
                    | Some _ -> raise (IOException "The FNIS output file changed.")

            return modId
        }

    let removeProfileRows connection transaction modId =
        let args = [ "$mod", box (string modId) ]

        let versions =
            ids connection transaction "SELECT id FROM mod_versions WHERE mod_id=$mod" args

        Sqlite.execute
            connection
            transaction
            "UPDATE mods SET current_version=NULL WHERE id=$mod"
            args

        for version in versions do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM hidden_mod_files WHERE version_id=$version; DELETE FROM mod_manifest WHERE version_id=$version; UPDATE mod_version_origins SET source_version=NULL WHERE source_version=$version; DELETE FROM mod_version_origins WHERE version_id=$version"
                [ "$version", box (string version) ]

        let payloads =
            ids
                connection
                transaction
                "SELECT p.id FROM mod_payloads p JOIN mod_versions v ON v.id=p.publication_id WHERE v.mod_id=$mod"
                args

        for id in payloads do
            let owner =
                use query =
                    Sqlite.command
                        connection
                        transaction
                        "SELECT version_id FROM mod_manifest WHERE payload_id=$id LIMIT 1"
                        [ "$id", box (string id) ]

                match query.ExecuteScalar() with
                | :? string as version -> Some version
                | _ -> None

            match owner with
            | Some version ->
                Sqlite.execute
                    connection
                    transaction
                    "UPDATE mod_payloads SET publication_id=$version WHERE id=$id"
                    [ "$version", box version; "$id", box (string id) ]
            | None ->
                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM mod_payloads WHERE id=$id"
                    [ "$id", box (string id) ]

        for version in versions do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM mod_versions WHERE id=$version"
                [ "$version", box (string version) ]

        Sqlite.execute connection transaction "DELETE FROM mods WHERE id=$mod" args
