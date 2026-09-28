namespace ModConductor.Persistence

open System
open System.Collections.Generic
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.Platform

module internal ProfileTransportBases =
    let reconstruct
        (inspection: Inspection)
        (artifacts: IArtifactLibrary)
        workspace
        (baseVersion: ProfileArchiveBase)
        (token: CancellationToken)
        =
        task {
            let! found = artifacts.Read(workspace, baseVersion.ArtifactId)

            match found with
            | Error _ -> return None
            | Ok artifact when
                artifact.Sha256 <> Some baseVersion.ArchiveSha256
                || artifact.Length <> Some baseVersion.ArchiveLength
                ->
                return None
            | Ok artifact ->
                let reference =
                    { ArtifactRef.WorkspaceId = workspace
                      Id = artifact.Id
                      Revision = artifact.Revision }

                let! inspected = inspection.Inspect(reference, token)

                match inspected with
                | Error _ -> return None
                | Ok manifest when manifest.Sha256 <> baseVersion.ArchiveSha256 -> return None
                | Ok manifest ->
                        let entries = manifest.Entries |> List.filter (fun entry -> not entry.Directory)

                        let selected =
                            baseVersion.Files
                            |> List.map (fun file ->
                                let destination = LogicalPath.components file.Path
                                let matching =
                                    entries
                                    |> List.filter (fun entry ->
                                        let source = LogicalPath.components entry.Path
                                        source.Length >= baseVersion.Root.Length + destination.Length
                                        && (source |> List.take baseVersion.Root.Length) = baseVersion.Root
                                        && (source |> List.skip (source.Length - destination.Length)) = destination
                                        && entry.Size = file.Payload.Length)

                                match matching with
                                | [ entry ] ->
                                    Some
                                        { ArchiveIndex = entry.Index
                                          Destination = destination }
                                | _ -> None)

                        if selected |> List.exists Option.isNone then
                            return None
                        else
                            let selected = selected |> List.choose id

                            if
                                selected.Length = 0
                                || (selected |> List.map _.ArchiveIndex |> List.distinct).Length
                                   <> selected.Length
                            then
                                return None
                            else
                                let expected =
                                    List.zip selected baseVersion.Files
                                    |> List.map (fun (selected, file) ->
                                        selected.ArchiveIndex, file.Payload.Sha256)
                                    |> Map.ofList

                                let! verified =
                                    inspection.WithContents(
                                        reference,
                                        token,
                                        fun contents ->
                                            let actual = Dictionary<int, string>()

                                            contents.ReadEntries(
                                                selected |> List.map _.ArchiveIndex,
                                                fun (index, stream) ->
                                                    actual[index] <-
                                                        SHA256.HashData stream
                                                        |> Convert.ToHexStringLower
                                            )

                                            expected
                                            |> Map.forall (fun index sha ->
                                                match actual.TryGetValue index with
                                                | true, found -> String.Equals(sha, found, StringComparison.OrdinalIgnoreCase)
                                                | _ -> false)
                                    )

                                return
                                    if verified = Ok true then
                                        Some
                                            { ArchiveName = baseVersion.ArchiveName
                                              ArchiveSha256 = baseVersion.ArchiveSha256
                                              ArchiveLength = baseVersion.ArchiveLength
                                              Root = baseVersion.Root
                                              Selected = selected }
                                    else
                                        None
        }
