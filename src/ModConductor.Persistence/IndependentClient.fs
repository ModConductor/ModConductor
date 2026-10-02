namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.GameContexts
open ModConductor.DeploymentRecovery
open ModConductor.Platform

/// Only the declared client executable is copied. Unity assets remain ordinary read-only projections.
module internal IndependentClient =
    let prepare (evidence: InstallationEvidence) (target: Location) =
        if GameClient.independentExecutable (GameCatalog.forGame evidence.DefinitionId) then
            let selected = evidence.Executable.Value
            let name = Path.GetFileName selected.Path

            use source =
                HeldDirectory.Open(
                    HostPath.create evidence.RootPath |> Result.defaultWith invalidOp,
                    evidence.RootIdentity.Value
                )

            use owned = HeldDirectory.Open(target.Path, target.Identity)
            let observed = source.InspectFile(name, Some selected.Identity)
            let destination = Path.Combine(HostPath.value target.Path, name)

            let unchanged =
                match owned.InspectEntry name with
                | None -> false
                | Some entry when entry.Kind = EntryKind.RegularFile ->
                    let current = owned.InspectFile(name, Some entry.Identity)
                    current.Length = observed.Length && current.Modified = observed.Modified
                | _ -> raise (IOException "The owned client executable is not a regular file.")

            if not unchanged then
                let stage = name + "." + Guid.NewGuid().ToString("N") + ".copy"
                let staged = Path.Combine(HostPath.value target.Path, stage)

                try
                    File.Copy(selected.Path, staged)

                    if OperatingSystem.IsLinux() then
                        File.SetUnixFileMode(staged, File.GetUnixFileMode selected.Path)

                    let current = source.InspectFile(name, Some selected.Identity)

                    if
                        current.Length <> observed.Length || current.Modified <> observed.Modified
                    then
                        raise (
                            IOException "The selected client executable changed during the copy."
                        )

                    File.Move(staged, destination, true)
                finally
                    if File.Exists staged then
                        File.Delete staged
