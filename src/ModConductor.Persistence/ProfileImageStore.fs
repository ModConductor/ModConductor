namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Workspaces

type ProfileImageStore internal (database: StateDatabase, directory: string) =
    let folder (workspace: Guid) =
        Path.Combine(directory, "profile-images", workspace.ToString("N"))

    let path workspace (profile: Guid) =
        Path.Combine(folder workspace, profile.ToString("N") + ".image")

    let exists workspace profile =
        database.Enqueue(fun () ->
            let count =
                Sqlite.number
                    database.Connection
                    null
                    "SELECT count(*) FROM profiles WHERE workspace_id=$workspace AND id=$profile"
                    [ "$workspace", box (string workspace); "$profile", box (string profile) ]

            count = 1L)

    let replace (target: string) (source: string) =
        Directory.CreateDirectory(Path.GetDirectoryName target) |> ignore
        let temporary = target + "." + Guid.NewGuid().ToString("N") + ".tmp"

        try
            File.Copy(source, temporary)
            File.Move(temporary, target, true)
        finally
            if File.Exists temporary then
                File.Delete temporary

    let remove target =
        try
            File.Delete target
        with :? DirectoryNotFoundException ->
            ()

    member _.Clone(workspace, source, target) =
        task {
            let sourcePath = path workspace source
            let targetPath = path workspace target

            try
                if File.Exists sourcePath then
                    replace targetPath sourcePath
                else
                    remove targetPath

                return Ok()
            with
            | :? IOException
            | :? UnauthorizedAccessException ->
                return Error(WorkspaceError.ProfileData "The profile image could not be copied.")
        }

    member _.Remove(workspace, profile) =
        try
            remove (path workspace profile)
            Ok()
        with
        | :? IOException
        | :? UnauthorizedAccessException ->
            Error(WorkspaceError.ProfileData "The profile image could not be removed.")

    interface IProfileImages with
        member _.Read(workspace, profile) =
            task {
                let! found = exists workspace profile

                if not found then
                    return Error WorkspaceError.NotFound
                else
                    try
                        let image = path workspace profile

                        return Ok(if File.Exists image then Some image else None)
                    with
                    | :? IOException
                    | :? UnauthorizedAccessException -> return Ok None
            }

        member _.Set(workspace, profile, source) =
            database.Enqueue(fun () ->
                let found =
                    Sqlite.number
                        database.Connection
                        null
                        "SELECT count(*) FROM profiles WHERE workspace_id=$workspace AND id=$profile"
                        [ "$workspace", box (string workspace); "$profile", box (string profile) ]

                let found = found = 1L

                if not found then
                    Error WorkspaceError.NotFound
                else
                    try
                        match source with
                        | Some value when Path.IsPathFullyQualified value ->
                            replace (path workspace profile) value
                        | Some _ -> invalidArg "source" "Choose an image from a local folder."
                        | None -> remove (path workspace profile)

                        Ok()
                    with
                    | :? IOException
                    | :? UnauthorizedAccessException ->
                        Error(WorkspaceError.ProfileData "The profile image could not be saved.")
                    | :? ArgumentException ->
                        Error(WorkspaceError.ProfileData "Choose an image from a local folder."))
