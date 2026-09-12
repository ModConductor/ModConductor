namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.ArchiveInstallation
open ModConductor.ArchiveInspection
open ModConductor.ModLibrary
open ModConductor.Platform

module internal UpdateInspection =
    let read (database: StateDatabase) (access: LibraryAccess) modId expected =
        task {
            let! row, version, library, payloads =
                database.Enqueue(fun () ->
                    let connection = database.Connection

                    let row =
                        LibraryRows.find connection null modId
                        |> Option.defaultWith (fun () ->
                            raise (InstallationException "The installed mod is unavailable."))

                    if
                        row.Entry.Revision <> expected
                        || MaintenanceClaims.busy connection null modId
                    then
                        raise (
                            InstallationException
                                "The installed mod changed or has another operation in progress."
                        )

                    let version =
                        row.Entry.CurrentVersion
                        |> Option.bind (fun id ->
                            LibraryRows.version
                                connection
                                null
                                id
                                0
                                (ArchiveLimits.Default.Entries + 1))
                        |> Option.defaultWith (fun () ->
                            raise (
                                InstallationException
                                    "Save a complete version before updating this mod."
                            ))

                    if version.Entries.Length > ArchiveLimits.Default.Entries then
                        raise (
                            InstallationException
                                "This mod has too many files for an archive update."
                        )

                    let library =
                        LibraryRows.library connection null row.Entry.WorkspaceId
                        |> Option.defaultWith (fun () ->
                            raise (InstallationException "The mod library is unavailable."))

                    let payloads =
                        version.Entries
                        |> List.map (fun entry ->
                            entry,
                            LibraryRows.payload connection null entry.Payload.Id |> Option.get)

                    row, version, library, payloads)

            let! root = access.Root row.Entry.WorkspaceId

            let root =
                root
                |> Result.defaultWith (fun _ ->
                    raise (InstallationException "The workspace is unavailable."))

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
                            use source =
                                LibraryFiles.openSource root row (Set.singleton held.Identity)

                            let observed, _ =
                                SourceFiles.scan
                                    source
                                    (Set.singleton held.Identity)
                                    ArchiveLimits.Default.Entries
                                    ignore

                            let previous =
                                version.Entries
                                |> List.map (fun entry -> entry.Path, entry.Payload)
                                |> Map.ofList

                            [ for file in observed do
                                  match previous |> Map.tryFind file.Path with
                                  | None ->
                                      yield
                                          "New source file kept: " + LogicalPath.display file.Path
                                  | Some payload when
                                      payload.Length <> file.Length
                                      || payload.Sha256 <> file.Sha256
                                      ->
                                      yield
                                          "Changed source file kept: "
                                          + LogicalPath.display file.Path
                                  | _ -> ()
                              yield "Source folder stays unchanged: " + LogicalPath.display path ]
                        with :? IOException ->
                            [ "Source folder is unavailable and will not be changed: "
                              + LogicalPath.display path ])

            return row.Entry, version, notices
        }
