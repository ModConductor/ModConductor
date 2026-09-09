namespace ModConductor.Deployment

open System
open System.Security.Cryptography
open System.Text
open ModConductor

module SourceIdentity =
    let token (value: FilePlanning.SourceStamp) =
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256

        let number (value: int64) =
            let bytes = Array.zeroCreate<byte> 8
            Buffers.Binary.BinaryPrimitives.WriteInt64LittleEndian(bytes, value)
            hash.AppendData bytes

        let id (value: Guid) = hash.AppendData(value.ToByteArray())
        id value.WorkspaceId
        id value.ProfileId
        number value.SelectionRevision
        number value.ContextRevision
        number value.ExclusionRevision
        number value.OutputRevision
        number (int64 value.Versions.Length)

        for modId, version in value.Versions do
            id modId

            match version with
            | None -> number 0L
            | Some version ->
                number 1L
                id version

        match value.Deployment with
        | None -> number 0L
        | Some value ->
            let bytes = Encoding.UTF8.GetBytes value in
            number 1L
            number (int64 bytes.Length)
            hash.AppendData bytes

        Convert.ToHexStringLower(hash.GetHashAndReset())
