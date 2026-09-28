namespace ModConductor.Fnis

open System
open System.Buffers.Binary
open System.Security.Cryptography
open System.Text
open ModConductor.Platform

module FnisFreshness =
    let private extension (path: LogicalPath) =
        IO.Path.GetExtension(LogicalPath.display path).ToLowerInvariant()

    let relevant (path: LogicalPath) =
        let components = LogicalPath.components path |> List.map _.ToLowerInvariant()

        let file = List.last components

        let underActors =
            match components with
            | "meshes" :: "actors" :: _ -> true
            | _ -> false

        let descriptor =
            file.Contains("fnis", StringComparison.Ordinal)
            || file.Contains("behavior", StringComparison.Ordinal)
            || file.Contains("patch", StringComparison.Ordinal)
            || file.Contains("skeleton", StringComparison.Ordinal)

        underActors
        && (List.contains (extension path) [ ".hkx"; ".nif"; ".txt"; ".lst"; ".xml" ]
            || descriptor)

    let compute policy (files: FnisInputFile list) =
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256

        let writeNumber value =
            let bytes = Array.zeroCreate<byte> 8
            BinaryPrimitives.WriteInt64LittleEndian(bytes, value)
            hash.AppendData bytes

        let writeText (value: string) =
            let bytes = Encoding.UTF8.GetBytes value
            writeNumber (int64 bytes.Length)
            hash.AppendData bytes

        files
        |> List.map (fun file -> TargetPolicy.key policy file.Path, file)
        |> List.sortWith (fun (left, _) (right, _) ->
            (TargetPolicy.comparer policy).Compare(left, right))
        |> List.iter (fun (path, file) ->
            writeText path
            writeNumber file.Length
            writeText (file.Sha256.ToLowerInvariant()))

        hash.GetHashAndReset() |> Convert.ToHexStringLower
