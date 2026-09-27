namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.ArchiveInstallation
open ModConductor.ArchiveInspection
open ModConductor.ModLibrary
open ModConductor.Platform

module internal UpdateInspection =
    let private required message =
        function
        | Some value -> Ok value
        | None -> Error message

    let read (database: StateDatabase) (access: LibraryAccess) modId expected =
        task {
            let! found =
                database.Enqueue(fun () ->
                    let connection = database.Connection

                    LibraryRows.find connection null modId
                    |> required "The installed mod is unavailable."
                    |> Result.bind (fun row ->
                        if
                            row.Entry.Revision <> expected
                            || MaintenanceClaims.busy connection null modId
                        then
                            Error
                                "The installed mod changed or has another operation in progress."
                        else
                            Ok row)
                    |> Result.bind (fun row ->
                        row.Entry.CurrentVersion
                        |> Option.bind (fun id ->
                            LibraryRows.version
                                connection
                                null
                                id
                                0
                                (ArchiveLimits.Default.Entries + 1))
                        |> required "Save a complete version before updating this mod."
                        |> Result.map (fun version -> row, version))
                    |> Result.bind (fun (row, version) ->
                        if version.Entries.Length > ArchiveLimits.Default.Entries then
                            Error "This mod has too many files for an archive update."
                        else
                            Ok(row, version))
                    |> Result.bind (fun (row, version) ->
                        LibraryRows.library connection null row.Entry.WorkspaceId
                        |> required "The mod library is unavailable."
                        |> Result.map (fun library ->
                            let payloads =
                                version.Entries
                                |> List.map (fun entry ->
                                    entry,
                                    LibraryRows.payload connection null entry.Payload.Id
                                    |> Option.get)

                            row, version, library, payloads)))

            match found with
            | Error why -> return Error why
            | Ok(row, version, library, payloads) ->
                let! root = access.Root row.Entry.WorkspaceId

                match root with
                | Error _ -> return Error "The workspace is unavailable."
                | Ok root ->

                    let! notices =
                        Task.Run(fun () ->
                            use held = LibraryFiles.openLibrary root library

                            for entry, payload in payloads do
                                try
                                    LibraryFiles.verify held payload
                                with :? IOException ->
                                    raise (
                                        InstallationException(
                                            "A stored file changed or is unavailable: "
                                            + LogicalPath.display entry.Path
                                        )
                                    )

                            match row.Entry.SourcePath with
                            | None -> []
                            | Some path ->
                                try
                                    match
                                        LibraryFiles.openSource
                                            root
                                            row
                                            (Set.singleton held.Identity)
                                    with
                                    | Error _ ->
                                        [ "Source folder is unavailable and will not be changed: "
                                          + LogicalPath.display path ]
                                    | Ok source ->
                                        use source = source

                                        match
                                            SourceFiles.scan
                                                source
                                                (Set.singleton held.Identity)
                                                ArchiveLimits.Default.Entries
                                                ignore
                                        with
                                        | Error _ ->
                                            [ "Source folder is unavailable and will not be changed: "
                                              + LogicalPath.display path ]
                                        | Ok(observed, _) ->
                                            let previous =
                                                version.Entries
                                                |> List.map (fun entry ->
                                                    entry.Path, entry.Payload)
                                                |> Map.ofList

                                            [ for file in observed do
                                                  match previous |> Map.tryFind file.Path with
                                                  | None ->
                                                      yield
                                                          "New source file kept: "
                                                          + LogicalPath.display file.Path
                                                  | Some payload when
                                                      payload.Length <> file.Length
                                                      || payload.Sha256 <> file.Sha256
                                                      ->
                                                      yield
                                                          "Changed source file kept: "
                                                          + LogicalPath.display file.Path
                                                  | _ -> ()
                                              yield
                                                  "Source folder stays unchanged: "
                                                  + LogicalPath.display path ]
                                with :? IOException ->
                                    [ "Source folder is unavailable and will not be changed: "
                                      + LogicalPath.display path ])

                    return Ok(row.Entry, version, notices)
        }
