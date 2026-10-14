namespace ModConductor.ArchiveInspection

open System
open ModConductor.Platform

module internal ArchiveNames =
    let refuse message =
        raise (ArchiveInspectionException message)

    let parse (name: string) =
        name.Replace('\\', '/').Split('/', StringSplitOptions.RemoveEmptyEntries)
        |> Array.toList
        |> LogicalPath.create
        |> Result.defaultWith (fun _ ->
            refuse "An archive path cannot be represented in the source tree.")
