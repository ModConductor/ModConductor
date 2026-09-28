namespace ModConductor.Bethesda

open System
open System.Collections.Generic
open System.IO

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

    let private associatedNames (plugin: string) =
        let stem = Path.GetFileNameWithoutExtension plugin
        [ stem + ".bsa"; stem + " - Textures.bsa" ]

    let resolve (input: ArchivePolicyInput) (candidates: ArchiveCandidate list) =
        let problems = ResizeArray<string>()
        let blocking = ResizeArray<string>()

        for issue in input.Order.Issues do
            blocking.Add issue.Detail

        for problem in input.Headers.Problems do
            blocking.Add problem

        let required = set SkyrimArchives.required
        let explicit = Dictionary<string, ExplicitArchive>(StringComparer.OrdinalIgnoreCase)
        let duplicates = HashSet<string>(StringComparer.OrdinalIgnoreCase)

        for entry in input.Explicit do
            if not (explicit.TryAdd(entry.Name, entry)) && duplicates.Add entry.Name then
                problems.Add(entry.Name + " is repeated in the Skyrim archive list.")

        let desired = ResizeArray<string>()

        for name in SkyrimArchives.required do
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
                for name in associatedNames setting.Name do
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
                for name in associatedNames setting.Name do
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
                  let bsa = name.EndsWith(".bsa", StringComparison.OrdinalIgnoreCase)

                  let supported =
                      bsa && candidate |> Option.bind _.Format |> Option.exists (same "BSA v105")

                  let sourceProblem = candidate |> Option.bind _.Problem

                  let state, problem =
                      match candidate, bsa, supported, sourceProblem, intended with
                      | None, _, _, _, true ->
                          ArchivePolicyState.Unavailable,
                          Some("The listed archive is not in the planned Data folder.")
                      | Some _, false, _, _, true ->
                          ArchivePolicyState.Unsupported,
                          Some("BA2 archives are not loaded by Skyrim Special Edition.")
                      | Some _, true, false, Some detail, true ->
                          ArchivePolicyState.Unavailable, Some detail
                      | Some _, true, false, None, true ->
                          ArchivePolicyState.Unsupported,
                          Some("This BSA version is not supported for Skyrim Special Edition.")
                      | Some _, true, true, None, true -> ArchivePolicyState.Active, None
                      | Some _, _, _, Some detail, false ->
                          ArchivePolicyState.Unavailable, Some detail
                      | Some _, false, _, _, false ->
                          ArchivePolicyState.Unsupported,
                          Some("BA2 archives are not loaded by Skyrim Special Edition.")
                      | _ -> ArchivePolicyState.Inactive, None

                  let rowName = candidate |> Option.map _.Name |> Option.defaultValue name

                  let reasons =
                      [ if isRequired then
                            "Required in Skyrim.ini"
                        if explicitEntry.IsSome then
                            "Explicit in Skyrim.ini"
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
