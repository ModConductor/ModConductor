namespace ModConductor.ProfileGameData

open System
open System.Text
open ModConductor.Platform

module internal SaveBrowsing =
    let page (root: DataRoot option) (path: string list) after =
        let valid (name: string) =
            not (String.IsNullOrWhiteSpace name)
            && name <> "."
            && name <> ".."
            && name.IndexOfAny([| '/'; '\\'; '\000' |]) < 0

        let rec read (folder: HeldDirectory) =
            function
            | part :: rest ->
                use child = folder.Directory(part, None)
                read child rest
            | [] ->
                let names = folder.Names |> Seq.truncate 1000001 |> Seq.toArray

                if names.Length > 1000000 then
                    Error(
                        ProfileDataError.Unavailable "The folder exceeds the supported file count."
                    )
                else
                    Array.sortInPlaceWith (fun a b -> StringComparer.Ordinal.Compare(a, b)) names

                    let available =
                        names
                        |> Array.filter (fun name ->
                            after
                            |> Option.forall (fun previous ->
                                StringComparer.Ordinal.Compare(name, previous) > 0))

                    let rows = ResizeArray<ProfileSaveEntry>()
                    let mutable bytes = 0
                    let mutable consumed = 0
                    let mutable full = false
                    let mutable problem = None

                    for name in available do
                        if not full && problem.IsNone then
                            let cost = 64 + Encoding.UTF8.GetByteCount name

                            if cost > 240 * 1024 then
                                problem <-
                                    Some(
                                        ProfileDataError.Unavailable
                                            "A filename exceeds the supported page size."
                                    )
                            elif rows.Count = 32 || bytes + cost > 240 * 1024 then
                                full <- true
                            else
                                match folder.InspectEntry name with
                                | Some entry when entry.Kind = EntryKind.Directory ->
                                    rows.Add
                                        { Name = name
                                          Directory = true
                                          Bytes = 0L }
                                | Some entry when entry.Kind = EntryKind.RegularFile ->
                                    let stream, _ = folder.Read(name, Some entry.Identity)
                                    use file = stream

                                    rows.Add
                                        { Name = name
                                          Directory = false
                                          Bytes = file.Length }
                                | Some _ ->
                                    problem <-
                                        Some(
                                            ProfileDataError.Unavailable
                                                "The private save folder contains an unsupported entry."
                                        )
                                | None -> ()

                                bytes <- bytes + cost
                                consumed <- consumed + 1

                    match problem with
                    | Some error -> Error error
                    | None ->
                        Ok
                            { Entries = List.ofSeq rows
                              Next =
                                if consumed < available.Length && consumed > 0 then
                                    Some available[consumed - 1]
                                else
                                    None }

        if
            path.Length > 128
            || not (List.forall valid path)
            || Option.exists (valid >> not) after
        then
            Error(ProfileDataError.Invalid "Choose a folder inside the private saves.")
        else
            match root with
            | None -> Ok { Entries = []; Next = None }
            | Some root ->
                use folder = HeldDirectory.Open(root.Path, root.Identity)
                read folder path
