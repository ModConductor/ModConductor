namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Text
open ModConductor.Platform

module internal SaveGroupPaging =
    let private result = ProfileDataResultFlow.result

    let private validCursor =
        function
        | None -> true
        | Some value ->
            not (String.IsNullOrWhiteSpace value)
            && value.IndexOfAny([| '/'; '\\'; '\000' |]) < 0

    let private unique (names: string array) wanted =
        match names |> Array.filter (SaveGroupSource.same wanted) with
        | [| value |] -> Some value, None
        | [||] -> None, None
        | _ -> None, Some "Names that differ only by case cannot be grouped safely."

    let private regular (folder: HeldDirectory) names wanted =
        match unique names wanted with
        | None, problem -> None, problem
        | Some actual, _ ->
            match folder.InspectEntry actual with
            | Some found when found.Kind = EntryKind.RegularFile ->
                let stream, _ = folder.Read(actual, Some found.Identity)
                use file = stream
                Some(actual, file.Length), None
            | _ -> None, Some "The matching save companion is not a regular file."

    let private opaque name kind bytes problem =
        { Id = name
          Name = name
          Kind = kind
          Bytes = bytes
          Companion = None
          CompanionBytes = 0L
          Actionable = false
          Problem = problem }

    let private saveRow (folder: HeldDirectory) names name identity =
        let stream, _ = folder.Read(name, Some identity)
        use file = stream
        let _, ownProblem = unique names name

        let companion, companionProblem =
            regular folder names (Path.GetFileNameWithoutExtension(name) + ".skse")

        let problem = ownProblem |> Option.orElse companionProblem

        { Id = name
          Name = name
          Kind = ProfileSaveEntryKind.Save
          Bytes = file.Length
          Companion = companion |> Option.map fst
          CompanionBytes = companion |> Option.map snd |> Option.defaultValue 0L
          Actionable = problem.IsNone
          Problem = problem }

    let private row (folder: HeldDirectory) names name =
        let entry = folder.InspectEntry name
        let extension = Path.GetExtension name

        let pairedSkse =
            extension.Equals(".skse", StringComparison.OrdinalIgnoreCase)
            && (entry |> Option.exists (fun value -> value.Kind = EntryKind.RegularFile))
            && (regular folder names (Path.GetFileNameWithoutExtension(name) + ".ess")
                |> fst
                |> Option.isSome)

        if pairedSkse then
            None
        else
            match entry with
            | Some value when value.Kind = EntryKind.Directory ->
                opaque name ProfileSaveEntryKind.Directory 0L None |> Some
            | Some value when value.Kind = EntryKind.RegularFile ->
                if extension.Equals(".ess", StringComparison.OrdinalIgnoreCase) then
                    saveRow folder names name value.Identity |> Some
                else
                    let stream, _ = folder.Read(name, Some value.Identity)
                    use file = stream
                    opaque name ProfileSaveEntryKind.Other file.Length None |> Some
            | Some _ ->
                opaque name ProfileSaveEntryKind.Other 0L (Some "This entry type is not supported.")
                |> Some
            | None -> None

    let rows (root: DataRoot) =
        use folder = HeldDirectory.Open(root.Path, root.Identity)
        let names = folder.Names |> Seq.truncate 1000001 |> Seq.toArray

        if names.Length > 1000000 then
            Error(ProfileDataError.Unavailable "The save folder exceeds one million entries.")
        else
            Array.sortInPlaceWith
                (fun left right -> StringComparer.Ordinal.Compare(left, right))
                names

            names |> Array.choose (row folder names) |> Array.toList |> Ok

    let private pageEntries (available: ProfileSaveGroupEntry list) =
        let page = ResizeArray<ProfileSaveGroupEntry>()
        let mutable cost = 0
        let mutable consumed = 0

        for row in available do
            let rowCost =
                160
                + Encoding.UTF8.GetByteCount row.Name
                + (row.Companion |> Option.map Encoding.UTF8.GetByteCount |> Option.defaultValue 0)

            if page.Count < 32 && cost + rowCost <= 240 * 1024 then
                page.Add row
                cost <- cost + rowCost
                consumed <- consumed + 1

        let next =
            if consumed > 0 && consumed < List.length available then
                Some available[consumed - 1].Id
            else
                None

        List.ofSeq page, next

    let page scope kind after =
        result {
            if not (validCursor after) then
                return! Error(ProfileDataError.Invalid "Choose a current save page.")

            let! root, path = SaveGroupSource.source scope kind

            match root with
            | None ->
                return
                    { Source = kind
                      Path = path
                      Entries = []
                      Next = None }
            | Some root ->
                let! current = rows root

                let available =
                    current
                    |> List.filter (fun row ->
                        after
                        |> Option.forall (fun previous ->
                            StringComparer.Ordinal.Compare(row.Id, previous) > 0))

                let entries, next = pageEntries available

                return
                    { Source = kind
                      Path = path
                      Entries = entries
                      Next = next }
        }
