namespace ModConductor.DeploymentPlanning

open System
open System.IO
open System.Security.Cryptography
open System.Text
open ModConductor.Platform

/// The identity of one immutable managed copy, never a target-wide rule.
type ModFile =
    { ModId: Guid
      VersionId: Guid
      Path: LogicalPath }

type VisibilityInput =
    { Planning: PlanningInput
      Hidden: Set<ModFile> }

type FileVisibility =
    internal
        { Original: PlanningResult
          BaseFingerprint: string
          Fingerprint: string
          Hidden: Set<ModFile>
          Available: Set<ModFile>
          Copies: Map<ModFile, TargetFile>
          Sources: Map<TargetFile, Contribution list>
          Files: Map<TargetFile, ResolvedFile option> }

module Visibility =
    let copy =
        function
        | SourcePin.Mod(modId, version, entry) ->
            Some
                { ModId = modId
                  VersionId = version
                  Path = entry.Path }
        | SourcePin.Snapshot _ -> None

    let private computeFingerprint original (hidden: Set<ModFile>) =
        use bytes = new MemoryStream()
        use writer = new BinaryWriter(bytes, Encoding.UTF8, true)
        writer.Write "ModConductor file visibility"
        writer.Write(original: string)
        writer.Write hidden.Count

        for entry in hidden do
            writer.Write(entry.ModId.ToString "N")
            writer.Write(entry.VersionId.ToString "N")
            let components = LogicalPath.components entry.Path
            writer.Write components.Length

            for name in components do
                writer.Write name

        writer.Flush()

        SHA256.HashData(bytes.GetBuffer().AsSpan(0, int bytes.Length))
        |> Convert.ToHexStringLower

    let private resolve target hidden sources =
        let eligible =
            sources
            |> List.filter (fun source ->
                copy source.Source |> Option.forall (fun id -> not (Set.contains id hidden)))

        match eligible with
        | [] -> None
        | winner :: alternatives ->
            Some
                { Target = target
                  Winner = winner
                  Alternatives = alternatives
                  Reason = TargetResolution.reason winner alternatives }

    let prepare input =
        let original = Planner.compute input.Planning

        let view =
            match original with
            | PlanningResult.Ready plan -> Planner.view plan
            | PlanningResult.Blocked blocked -> blocked.Draft

        let files =
            view.ReadOnlyFiles
            @ (view.Writable
               |> List.collect (function
                   | WritableProjection.File(_, _, seed) -> Option.toList seed
                   | WritableProjection.Subtree(_, _, _, seeds) -> seeds))

        let sources =
            files
            |> List.map (fun file -> file.Target, file.Winner :: file.Alternatives)
            |> Map.ofList

        let copies =
            sources
            |> Map.toSeq
            |> Seq.collect (fun (target, entries) ->
                entries
                |> Seq.choose (fun entry -> copy entry.Source |> Option.map (fun id -> id, target)))
            |> Map.ofSeq

        let available =
            input.Planning.Profile.Mods
            |> Seq.collect (fun layer ->
                layer.Version
                |> Option.toList
                |> Seq.collect (fun version ->
                    version.Entries
                    |> Seq.map (fun entry ->
                        { ModId = layer.ModId
                          VersionId = version.Id
                          Path = entry.Path })))
            |> Set.ofSeq

        let applicable = Set.intersect available input.Hidden

        { Original = original
          BaseFingerprint = view.Fingerprint
          Fingerprint = computeFingerprint view.Fingerprint applicable
          Hidden = applicable
          Available = available
          Copies = copies
          Sources = sources
          Files = sources |> Map.map (fun target entries -> resolve target applicable entries) }

    let setHidden id hidden plan =
        if not (plan.Available.Contains id) then
            Error id
        else
            let excluded = if hidden then plan.Hidden.Add id else plan.Hidden.Remove id

            let files =
                match plan.Copies.TryFind id with
                | Some target ->
                    plan.Files.Add(target, resolve target excluded plan.Sources[target])
                | None -> plan.Files

            Ok
                { plan with
                    Hidden = excluded
                    Fingerprint = computeFingerprint plan.BaseFingerprint excluded
                    Files = files }

    let fingerprint plan = plan.Fingerprint
    let hidden plan = plan.Hidden
    let original plan = plan.Original
    let files plan = plan.Files

    let sources target plan =
        plan.Sources.TryFind target |> Option.defaultValue []
