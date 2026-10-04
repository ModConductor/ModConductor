namespace ModConductor.Persistence

open System
open System.Threading.Tasks
open ModConductor.HttpDownloads
open ModConductor.Thunderstore

module internal ThunderstoreSource =
    let fromArchive connection transaction artifact =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT sources FROM artifact_downloads WHERE artifact_id=$id"
                [ "$id", box (string artifact) ]

        match query.ExecuteScalar() with
        | :? string as value ->
            match DownloadSource.decode value with
            | DownloadSource.Thunderstore source -> Some source.Reference
            | _ -> None
        | _ -> None

    let metadata connection transaction artifact =
        fromArchive connection transaction artifact
        |> Option.map VersionReference.encode
        |> Option.defaultValue ""

type InstalledThunderstorePackage =
    { Reference: VersionReference
      ModId: Guid }

type ThunderstoreInventory internal (database: StateDatabase) =
    member _.Read(workspace: Guid, package: PackageReference) =
        database.EnqueueInternal(fun () ->
            let prefix = "thunderstore:/" + PackageReference.key package + "/"

            use query =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT id,source_text FROM mods WHERE workspace_id=$workspace AND current_version IS NOT NULL AND substr(source_text,1,length($prefix))=$prefix ORDER BY id"
                    [ "$workspace", box (string workspace); "$prefix", box prefix ]

            use reader = query.ExecuteReader()

            [ while reader.Read() do
                  match VersionReference.tryDecode (reader.GetString 1) with
                  | Some reference ->
                      yield
                          { Reference = reference
                            ModId = Guid.Parse(reader.GetString 0) }
                  | None -> () ])
