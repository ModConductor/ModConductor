namespace ModConductor.DeploymentPlanning

open System
open System.Collections.Generic
open ModConductor.Platform

module internal PlanningPaths =
    let components =
        function
        | PlanPath.Root -> []
        | PlanPath.At path -> LogicalPath.components path

    let logical parts =
        match LogicalPath.create parts with
        | Ok path -> path
        | Error _ -> invalidOp "Mapped components must form a logical path."

    let location =
        function
        | [] -> PlanPath.Root
        | parts -> PlanPath.At(logical parts)

    let exactPrefix prefix path =
        let expected, actual = components prefix, LogicalPath.components path

        expected.Length <= actual.Length
        && List.forall2
            (fun a b -> String.Equals(a, b, StringComparison.Ordinal))
            expected
            (List.take expected.Length actual)

    let rank precedence =
        let tier =
            match precedence.Tier with
            | LayerTier.Base -> 0
            | LayerTier.Secondary -> 1
            | LayerTier.Mod -> 2

        tier, precedence.Priority

    let sourcePath =
        function
        | SourcePin.Mod(_, _, entry) -> entry.Path
        | SourcePin.Snapshot(_, _, file) -> file.Path

    let targetOrder (target: TargetFile) =
        target.Root, LogicalPath.components target.Path

    let prefixes path =
        let parts = LogicalPath.components path
        [ for count in 1 .. parts.Length - 1 -> logical (List.take count parts) ]

    let table<'T> policy =
        Dictionary<string, 'T>(TargetPolicy.comparer policy)

    let key policy path = TargetPolicy.key policy path

    let locationKey policy =
        function
        | PlanPath.Root -> ""
        | PlanPath.At path -> key policy path

    let rootOf =
        function
        | WritableTarget.File(root, _)
        | WritableTarget.Subtree(root, _) -> root

    let pathOf =
        function
        | WritableTarget.File(_, path) -> PlanPath.At path
        | WritableTarget.Subtree(_, path) -> path

    let sortedContributions values =
        values
        |> List.sortBy (fun item ->
            let tier, priority = rank item.Precedence

            -tier,
            -(int64 priority),
            item.LayerId,
            LogicalPath.components (sourcePath item.Source),
            item.Source)
