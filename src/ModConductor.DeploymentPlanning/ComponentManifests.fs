namespace ModConductor.DeploymentPlanning

open System
open System.IO
open System.Security.Cryptography
open System.Text
open ModConductor.Platform
open ModConductor.ModLibrary

[<RequireQualifiedAccess>]
type ComponentRoot =
    | GameRoot
    | Data

[<RequireQualifiedAccess>]
type ComponentFileUse =
    | Immutable
    | WritableConfiguration
    | WritableContainingDirectory

type ComponentFile =
    { Source: LogicalPath
      Root: ComponentRoot
      Destination: LogicalPath
      Use: ComponentFileUse }

type ComponentManifest =
    { ModId: Guid
      Version: ModVersion
      Priority: int
      Files: ComponentFile list }

[<RequireQualifiedAccess>]
type ComponentProblem =
    | WrongVersion
    | IncompleteVersion
    | MissingSource of LogicalPath
    | UnknownSource of LogicalPath
    | DuplicateSource of LogicalPath
    | InvalidDestination of ComponentRoot * LogicalPath
    | DuplicateDestination of ComponentRoot * LogicalPath
    | FileDirectoryConflict of ComponentRoot * LogicalPath

type ReviewedComponent =
    { Mod: SelectedMod
      Writable: WritableDeclaration list
      GameRoot: Guid }

module ComponentManifests =
    let private writableId (version: Guid) (file: ComponentFile) =
        use bytes = new MemoryStream()
        use writer = new BinaryWriter(bytes, Encoding.UTF8, true)
        writer.Write "mc-component-working-v1"
        writer.Write(version.ToByteArray())
        writer.Write(LogicalPath.display file.Source)

        writer.Write(
            match file.Root with
            | ComponentRoot.GameRoot -> 1
            | ComponentRoot.Data -> 2
        )

        writer.Write(LogicalPath.display file.Destination)
        writer.Flush()
        Guid(SHA256.HashData(bytes.ToArray()).AsSpan(0, 16))

    let private rootId dataRoot gameRoot =
        function
        | ComponentRoot.GameRoot -> gameRoot
        | ComponentRoot.Data -> dataRoot

    let private key policy (file: ComponentFile) =
        (match file.Root with
         | ComponentRoot.GameRoot -> "game\000"
         | ComponentRoot.Data -> "data\000")
        + TargetPolicy.key policy file.Destination

    let review dataRoot gameRoot policy (manifest: ComponentManifest) =
        let problems = ResizeArray<ComponentProblem>()

        if manifest.Version.ModId <> manifest.ModId then
            problems.Add ComponentProblem.WrongVersion

        if manifest.Version.NextOffset.IsSome then
            problems.Add ComponentProblem.IncompleteVersion

        let entries =
            manifest.Version.Entries |> List.map (fun entry -> entry.Path) |> Set.ofList

        let declared = manifest.Files |> List.map _.Source

        for source in entries do
            if not (List.contains source declared) then
                problems.Add(ComponentProblem.MissingSource source)

        for source in declared do
            if not (entries.Contains source) then
                problems.Add(ComponentProblem.UnknownSource source)

        for source, files in manifest.Files |> List.groupBy _.Source do
            if files.Length <> 1 then
                problems.Add(ComponentProblem.DuplicateSource source)

        let destinations =
            System.Collections.Generic.Dictionary<string, LogicalPath>(TargetPolicy.comparer policy)

        for file in manifest.Files do
            let invalidRootPath =
                match file.Root, LogicalPath.components file.Destination with
                | ComponentRoot.GameRoot, first :: _ ->
                    String.Equals(first, "Data", StringComparison.OrdinalIgnoreCase)
                | _ -> false

            if
                invalidRootPath
                || not (TargetPolicy.problems policy file.Destination).IsEmpty
                || (file.Use = ComponentFileUse.WritableContainingDirectory
                    && (LogicalPath.components file.Destination).Length = 1)
            then
                problems.Add(ComponentProblem.InvalidDestination(file.Root, file.Destination))
            else
                let destinationKey = key policy file

                match destinations.TryGetValue destinationKey with
                | true, existing ->
                    problems.Add(ComponentProblem.DuplicateDestination(file.Root, existing))
                | false, _ -> destinations.Add(destinationKey, file.Destination)

        for file in manifest.Files do
            let parts = LogicalPath.components file.Destination

            for count in 1 .. parts.Length - 1 do
                let parent =
                    LogicalPath.create (List.take count parts)
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid component destination.")

                let parentKey = key policy { file with Destination = parent }

                if destinations.ContainsKey parentKey then
                    problems.Add(ComponentProblem.FileDirectoryConflict(file.Root, parent))

        if problems.Count <> 0 then
            Error(problems |> Seq.distinct |> Seq.sort |> Seq.toList)
        else
            let mappings =
                manifest.Files
                |> List.map (fun file ->
                    { SourcePrefix = PlanPath.At file.Source
                      TargetRoot = rootId dataRoot gameRoot file.Root
                      TargetPrefix = PlanPath.At file.Destination })

            let writable =
                manifest.Files
                |> List.choose (fun file ->
                    match file.Use with
                    | ComponentFileUse.Immutable -> None
                    | ComponentFileUse.WritableConfiguration ->
                        Some
                            { Id = writableId manifest.Version.Id file
                              Target =
                                WritableTarget.File(
                                    rootId dataRoot gameRoot file.Root,
                                    file.Destination
                                ) }
                    | ComponentFileUse.WritableContainingDirectory ->
                        let parts = LogicalPath.components file.Destination

                        let parent =
                            LogicalPath.create (List.take (parts.Length - 1) parts)
                            |> Result.defaultWith (fun _ ->
                                invalidOp "Invalid component destination.")

                        Some
                            { Id = writableId manifest.Version.Id file
                              Target =
                                WritableTarget.Subtree(
                                    rootId dataRoot gameRoot file.Root,
                                    PlanPath.At parent
                                ) })

            Ok
                { Mod =
                    { ModId = manifest.ModId
                      Priority = manifest.Priority
                      Enabled = true
                      Version = Some manifest.Version
                      Mappings = mappings
                      Archives = [] }
                  Writable = writable
                  GameRoot = gameRoot }

    let apply (components: ReviewedComponent list) (input: PlanningInput) =
        let replacements =
            components |> List.map (fun value -> value.Mod.ModId, value) |> Map.ofList

        let mods =
            input.Profile.Mods
            |> List.map (fun selected ->
                match replacements.TryFind selected.ModId with
                | None -> selected
                | Some reviewed ->
                    { reviewed.Mod with
                        Priority = selected.Priority
                        Enabled = selected.Enabled })

        let active = mods |> List.filter _.Enabled |> List.map _.ModId |> Set.ofList

        { input with
            Profile = { input.Profile with Mods = mods }
            Writable =
                input.Writable
                @ (components
                   |> List.filter (fun reviewed -> active.Contains reviewed.Mod.ModId)
                   |> List.collect _.Writable) }
