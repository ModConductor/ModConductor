namespace ModConductor.Persistence

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.ArchiveInstallation
open ModConductor.ArchiveInspection

type internal InstallationPayloads(database: StateDatabase, access: LibraryAccess) =
    let connection = database.Connection
    let wait (value: Task<'a>) = value.GetAwaiter().GetResult()
    let db action = database.EnqueueInternal action |> wait
    let refuse message = raise (InstallationException message)

    let openLibrary workspace =
        let root =
            access.Root workspace
            |> wait
            |> Result.defaultWith (fun _ -> refuse "The workspace is unavailable.")

        let library =
            access.PrepareLibrary(root, ignore)
            |> wait
            |> Result.defaultWith (fun _ -> refuse "The mod library is unavailable.")

        LibraryFiles.openLibrary root library

    member _.Write
        (id, plan: InstallationPlan, contents: ArchiveContents, token: CancellationToken, checkpoint) =
        use library = openLibrary plan.Artifact.WorkspaceId

        let files =
            db (fun () -> InstallationRows.files connection null id)
            |> List.map (fun file -> file.Index, file)
            |> Map.ofList

        checkpoint "before-extraction"

        contents.ReadEntries(
            plan.Files |> List.map _.Index,
            fun (index, source) ->
                token.ThrowIfCancellationRequested()
                let file = files[index]

                let output, identity = library.Create(LibraryFiles.payloadName file.PayloadId)

                use output = output

                db (fun () ->
                    Sqlite.execute
                        connection
                        null
                        "UPDATE installation_files SET identity=$identity WHERE installation_id=$id AND entry_index=$index"
                        [ "$id", box (string id)
                          "$index", box index
                          "$identity", box (LibraryEncoding.identity identity) ])

                use hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256)
                let buffer = Array.zeroCreate<byte> 65536
                let mutable reading = true

                let mutable digest = None

                try
                    while reading do
                        token.ThrowIfCancellationRequested()
                        let count = source.Read(buffer, 0, buffer.Length)

                        if count = 0 then
                            reading <- false
                        else
                            try
                                output.Write(buffer, 0, count)
                            with :? IOException ->
                                refuse
                                    "The temporary files cannot be written. Check free space and folder access."

                            hash.AppendData(buffer, 0, count)
                            checkpoint "bytes"

                    output.Flush(true)
                    digest <- Some(hash.GetHashAndReset() |> Convert.ToHexStringLower)
                finally
                    db (fun () ->
                        Sqlite.execute
                            connection
                            null
                            "UPDATE installation_files SET length=$length,digest=$digest WHERE installation_id=$id AND entry_index=$index"
                            [ "$id", box (string id)
                              "$index", box index
                              "$length", box output.Length
                              "$digest",
                              digest |> Option.map box |> Option.defaultValue (box DBNull.Value) ])

                checkpoint "file-observed"
        )

    member _.Delete(workspace, id) =
        let files = db (fun () -> InstallationRows.files connection null id)
        let stored = db (fun () -> LibraryRows.library connection null workspace)

        match stored with
        | Some row when row.Identity.IsSome ->
            let root =
                access.Root workspace
                |> wait
                |> Result.defaultWith (fun _ -> refuse "The workspace is unavailable.")

            use library = LibraryFiles.openLibrary root row

            for file in files do
                ArtifactFiles.remove library (LibraryFiles.payloadName file.PayloadId) file.Identity

                db (fun () ->
                    Sqlite.execute
                        connection
                        null
                        "DELETE FROM installation_files WHERE installation_id=$id AND entry_index=$index"
                        [ "$id", box (string id); "$index", box file.Index ])
        | _ when files |> List.forall (fun file -> file.Identity.IsNone) ->
            db (fun () ->
                Sqlite.execute
                    connection
                    null
                    "DELETE FROM installation_files WHERE installation_id=$id"
                    [ "$id", box (string id) ])
        | _ -> refuse "The temporary files cannot be found in the owned mod library."
