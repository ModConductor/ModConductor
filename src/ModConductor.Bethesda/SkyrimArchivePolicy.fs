namespace ModConductor.Bethesda

open System
open System.Collections.Generic
open System.IO
open ModConductor.GameContexts

type internal ArchiveCandidate =
    { Name: string
      Source: PluginSource option
      Format: string option
      Problem: string option }

module internal SkyrimArchivePolicy =
    let private same left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private set (values: string seq) =
        HashSet<string>(values, StringComparer.OrdinalIgnoreCase)

    let private associatedNames (rules: GameRules) (plugin: string) =
        let stem = Path.GetFileNameWithoutExtension plugin

        if rules.Activation = PluginActivation.MorrowindIni then
            []
        elif rules.ArchiveFormats |> List.exists (fun format -> format.StartsWith "BA2") then
            [ stem + " - Main.ba2"; stem + " - Textures.ba2" ]
        elif rules.SupportsLight then
            [ stem + ".bsa"; stem + " - Textures.bsa" ]
        else
            [ stem + ".bsa" ]

    let resolve (input: ArchivePolicyInput) (candidates: ArchiveCandidate list) =
        let rules = GameCatalog.rules input.GameId

        let candidates =
            match rules.Invalidation with
            | Some(name, version) when
                input.Explicit |> List.exists (fun entry -> same entry.Name name)
                ->
                { Name = name
                  Source = None
                  Format = Some("BSA v" + string version)
                  Problem = None }
                :: candidates
                |> List.distinctBy (fun row -> row.Name.ToUpperInvariant())
            | _ -> candidates

        let problems = ResizeArray<string>()
        let blocking = ResizeArray<string>()

        for issue in input.Order.Issues do
            blocking.Add issue.Detail

        for problem in input.Headers.Problems do
            blocking.Add problem

        let requiredNames =
            if GameCatalog.isSkyrimSE input.GameId then
                SkyrimArchives.required
            elif rules.Activation = PluginActivation.MorrowindIni then
                [ "Morrowind.bsa" ]
            else
                []

        let required = set requiredNames
        let explicit = Dictionary<string, ExplicitArchive>(StringComparer.OrdinalIgnoreCase)
        let duplicates = HashSet<string>(StringComparer.OrdinalIgnoreCase)

        for entry in input.Explicit do
            if not (explicit.TryAdd(entry.Name, entry)) && duplicates.Add entry.Name then
                problems.Add(entry.Name + " is repeated in the game archive list.")

        let desired = ResizeArray<string>()

        for name in requiredNames do
            desired.Add name

        for entry in input.Explicit do
            if
                not (required.Contains entry.Name)
                && same explicit[entry.Name].Name entry.Name
                && not (desired |> Seq.exists (same entry.Name))
            then
                desired.Add entry.Name

        let associated = Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)

        for setting in input.Order.Order.Entries do
            if setting.Enabled = Some true then
                for name in associatedNames rules setting.Name do
                    associated.TryAdd(name, setting.Name) |> ignore

        let byName = Dictionary<string, ArchiveCandidate>(StringComparer.OrdinalIgnoreCase)

        for candidate in candidates do
            match byName.TryGetValue candidate.Name with
            | false, _ -> byName.Add(candidate.Name, candidate)
            | true, existing ->
                byName[candidate.Name] <-
                    { Name = existing.Name
                      Source = None
                      Format = None
                      Problem =
                        Some("More than one planned Data file has this archive name ignoring case.") }

        let names = ResizeArray<string>()
        names.AddRange desired

        for setting in input.Order.Order.Entries do
            if setting.Enabled = Some true then
                for name in associatedNames rules setting.Name do
                    if byName.ContainsKey name && not (names |> Seq.exists (same name)) then
                        names.Add byName[name].Name

        for candidate in candidates |> List.sortBy (fun value -> value.Name.ToUpperInvariant()) do
            if not (names |> Seq.exists (same candidate.Name)) then
                names.Add candidate.Name

        let entries =
            [ for name in names do
                  let candidate =
                      match byName.TryGetValue name with
                      | true, value -> Some value
                      | _ -> None

                  let explicitEntry =
                      match explicit.TryGetValue name with
                      | true, value -> Some value
                      | _ -> None

                  let plugin =
                      match associated.TryGetValue name with
                      | true, value -> Some value
                      | _ -> None

                  let isRequired = required.Contains name
                  let intended = isRequired || explicitEntry.IsSome || plugin.IsSome

                  let bsa =
                      name.EndsWith(".bsa", StringComparison.OrdinalIgnoreCase)
                      || name.EndsWith(".ba2", StringComparison.OrdinalIgnoreCase)

                  let supported =
                      bsa
                      && candidate
                         |> Option.bind _.Format
                         |> Option.exists (fun format ->
                             rules.ArchiveFormats
                             |> List.exists (fun expected ->
                                 same expected format
                                 || format.StartsWith(
                                     expected + " ",
                                     StringComparison.OrdinalIgnoreCase
                                 )))

                  let sourceProblem = candidate |> Option.bind _.Problem

                  let state, problem =
                      match candidate, bsa, supported, sourceProblem, intended with
                      | None, _, _, _, true ->
                          ArchivePolicyState.Unavailable,
                          Some("The listed archive is not in the planned Data folder.")
                      | Some _, false, _, _, true ->
                          ArchivePolicyState.Unsupported,
                          Some("This archive format is not loaded by the selected game.")
                      | Some _, true, false, Some detail, true ->
                          ArchivePolicyState.Unavailable, Some detail
                      | Some _, true, false, None, true ->
                          ArchivePolicyState.Unsupported,
                          Some("This archive version is not supported for the selected game.")
                      | Some _, true, true, None, true -> ArchivePolicyState.Active, None
                      | Some _, _, _, Some detail, false ->
                          ArchivePolicyState.Unavailable, Some detail
                      | Some _, false, _, _, false ->
                          ArchivePolicyState.Unsupported,
                          Some("This archive format is not loaded by the selected game.")
                      | _ -> ArchivePolicyState.Inactive, None

                  let rowName = candidate |> Option.map _.Name |> Option.defaultValue name

                  let reasons =
                      [ if isRequired then
                            "Required in " + rules.Ini
                        if explicitEntry.IsSome then
                            "Explicit in " + rules.Ini
                        match plugin with
                        | Some value -> "Enabled with " + value
                        | None -> () ]

                  match problem with
                  | Some detail when isRequired || plugin.IsSome ->
                      blocking.Add(rowName + ": " + detail)
                  | Some detail when explicitEntry.IsSome -> problems.Add(rowName + ": " + detail)
                  | _ -> ()

                  yield
                      { Name = rowName
                        Position =
                          desired
                          |> Seq.tryFindIndex (same name)
                          |> Option.map ((+) 1)
                          |> Option.orElseWith (fun () ->
                              if state = ArchivePolicyState.Active then
                                  names |> Seq.tryFindIndex (same name) |> Option.map ((+) 1)
                              else
                                  None)
                        State = state
                        Required = isRequired
                        Explicit = explicitEntry
                        AssociatedPlugin = plugin
                        Reasons = reasons
                        Source = candidate |> Option.bind _.Source
                        Format = candidate |> Option.bind _.Format
                        Problem = problem } ]

        { Id = Guid.NewGuid()
          Stamp = input.Headers.Stamp
          ObservedAt = DateTimeOffset.UtcNow
          Stale = false
          Ini = input.Ini
          Entries = entries
          ExplicitNames = List.ofSeq desired
          Problems = List.ofSeq problems |> List.distinct
          BlockingProblems = List.ofSeq blocking |> List.distinct }
