namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.ModLibrary

module internal InventoryOutput =
    let private createOutput connection transaction workspace id kind metadata =
        if id = Guid.Empty then
            raise (InvalidDataException "The mod identity is empty.")

        let metadata =
            InventoryPolicy.metadata metadata
            |> Result.defaultWith (fun _ ->
                raise (InvalidDataException "The mod metadata is invalid."))

        if LibraryRows.find connection transaction id |> Option.isSome then
            raise (InvalidDataException "The mod identity is already in use.")

        Sqlite.execute
            connection
            transaction
            "INSERT INTO mods VALUES($id,$workspace,$kind,$name,$notes,$comment,$version,$source,0,NULL,NULL,NULL,1)"
            (LibraryRows.metadataParameters metadata
             @ [ "$id", box (string id)
                 "$workspace", box (string workspace)
                 "$kind", box (LibraryEncoding.kind kind) ])

        if kind = ModKind.Regular then
            SelectionRows.registered connection transaction workspace id kind

        (LibraryRows.find connection transaction id |> Option.get).Entry

    let createFromOutputs connection transaction workspace id metadata =
        createOutput connection transaction workspace id ModKind.Regular metadata

    let createFnisOutput connection transaction workspace id metadata =
        createOutput connection transaction workspace id ModKind.GeneratedOutput metadata
