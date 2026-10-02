namespace ModConductor.GameCatalogue

open System
open System.IO
open Tomlyn
open ModConductor.GameContexts
open ModConductor.GameCatalogue.Serialization

module PortableDefinition =
    let read id text =
        try
            let values = CatalogueToml.Deserialize(text).Games

            if values.Length <> 1 || values[0].Id <> id then
                Error "The portable game definition has another identity."
            else
                match GameId.tryParse id with
                | Some(GameId.Custom _) -> Definition.validate values[0]
                | _ -> Error "The portable game definition needs a custom identity."
        with :? TomlException ->
            Error "The portable game definition could not be read."

type Catalogue(directory: string) =
    let gate = obj ()
    let path = Path.Combine(directory, "games.toml")

    let mutable rows =
        if File.Exists path then
            CatalogueToml.Deserialize(File.ReadAllText path).Games
        else
            [||]

    let publish () =
        rows |> Array.map Definition.toGame |> Array.toList |> GameCatalog.replaceCustom

    let encode values =
        CatalogueToml.Serialize(CatalogueDocument(Games = values))

    do
        for row in rows do
            match Definition.validate row, GameId.tryParse row.Id with
            | Ok _, Some(GameId.Custom _) -> ()
            | _ -> invalidOp "The custom game catalogue is invalid."

        publish ()

    member _.Read id =
        lock gate (fun () ->
            rows
            |> Array.tryFind (fun row -> row.Id = id)
            |> Option.map (fun row -> CatalogueToml.Deserialize(encode [| row |]).Games[0]))

    member _.Save(d: GameDocument) =
        lock gate (fun () ->
            match Definition.validate d with
            | Error problem -> Error problem
            | Ok _ ->
                let existing = rows |> Array.tryFind (fun row -> row.Id = d.Id)

                if existing |> Option.exists (fun row -> row.Revision <> d.Revision) then
                    Error "This game definition changed. Reopen it before saving."
                else
                    match d.Id, existing with
                    | "", _ ->
                        d.Id <- GameId.value (GameId.Custom(Guid.NewGuid()))
                        d.Revision <- 1
                    | _, Some row -> d.Revision <- row.Revision + 1
                    | _, None -> ()

                    match GameId.tryParse d.Id with
                    | Some(GameId.Custom _) ->
                        let values =
                            Array.append (rows |> Array.filter (fun row -> row.Id <> d.Id)) [| d |]

                        Directory.CreateDirectory directory |> ignore
                        let temporary = path + ".new"
                        File.WriteAllText(temporary, encode values)
                        File.Move(temporary, path, true)
                        rows <- CatalogueToml.Deserialize(encode values).Games
                        publish ()
                        Ok(Definition.toGame d)
                    | _ -> Error "Select a custom game identity.")

    member this.Portable id =
        this.Read id |> Option.map (fun row -> encode [| row |])

    member this.Import(id, text: string) =
        match PortableDefinition.read id text with
        | Error problem -> Error problem
        | Ok value ->
            match this.Read id with
            | Some existing when encode [| existing |] <> encode [| value |] ->
                Error "A different game definition already uses this identity."
            | Some _ -> Ok()
            | None -> this.Save value |> Result.map ignore
