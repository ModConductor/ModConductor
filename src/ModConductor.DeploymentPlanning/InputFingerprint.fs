namespace ModConductor.DeploymentPlanning

open System
open System.Buffers.Binary
open System.Security.Cryptography
open ModConductor.Platform
open ModConductor.ModLibrary

module internal InputFingerprint =
    let compute (input: PlanningInput) =
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256

        let number (value: int64) =
            let bytes = Array.zeroCreate<byte> 8
            BinaryPrimitives.WriteInt64LittleEndian(bytes.AsSpan(), value)
            hash.AppendData bytes

        let text (value: string) =
            number (int64 value.Length)
            let bytes = Array.zeroCreate<byte> (value.Length * 2)

            value
            |> Seq.iteri (fun index character ->
                BinaryPrimitives.WriteUInt16LittleEndian(
                    bytes.AsSpan(index * 2, 2),
                    uint16 character
                ))

            hash.AppendData bytes

        let id (value: Guid) = text (value.ToString "N")
        let flag value = number (if value then 1L else 0L)

        let items write values =
            number (int64 (List.length values))
            values |> List.iter write

        let path value =
            LogicalPath.components value |> items text

        let location value =
            PlanningPaths.components value |> items text

        let optional write =
            function
            | None -> number 0L
            | Some value ->
                number 1L
                write value

        let mappings values =
            values
            |> List.sort
            |> items (fun mapping ->
                location mapping.SourcePrefix
                id mapping.TargetRoot
                location mapping.TargetPrefix)

        let archives values =
            values
            |> List.sort
            |> items (fun annotation ->
                path annotation.Container
                text annotation.CapabilityId
                text annotation.CapabilityRevision)

        let content length (digest: string) =
            number length
            text (digest.ToUpperInvariant())

        let fileIdentity value =
            match value.Device with
            | LinuxDevice(major, minor) ->
                number 0L
                number (int64 major)
                number (int64 minor)
            | WindowsVolume serial ->
                number 1L
                number (int64 serial)

            number (int64 value.Low)
            number (int64 value.High)

        let snapshotIdentity =
            function
            | SnapshotFileIdentity.Metadata metadata ->
                number 0L
                fileIdentity metadata.Identity
                number metadata.Length
                number (metadata.Modified.ToUniversalTime().Ticks)
            | SnapshotFileIdentity.Content(length, digest) ->
                number 1L
                content length digest

        let entry (value: ManifestEntry) =
            path value.Path
            id value.Payload.Id
            content value.Payload.Length value.Payload.Sha256

        text "ModConductor deployment plan"
        id input.Profile.ProfileId
        number input.Profile.Revision
        flag input.Profile.Complete

        input.Roots
        |> List.sort
        |> items (fun root ->
            id root.Id

            number (
                match root.Policy.Case with
                | Sensitive -> 0L
                | Insensitive -> 1L
            )

            number (
                match root.Policy.Unicode with
                | Preserve -> 0L
                | CanonicalComposition -> 1L
            )

            number (
                match root.Policy.Names with
                | Posix -> 0L
                | Windows -> 1L
            ))

        input.Profile.Mods
        |> List.filter _.Enabled
        |> List.sort
        |> items (fun layer ->
            id layer.ModId
            number (int64 layer.Priority)

            layer.Version
            |> optional (fun version ->
                id version.Id
                id version.ModId
                version.NextOffset |> optional (int64 >> number)
                version.Entries |> List.sort |> items entry)

            mappings layer.Mappings
            archives layer.Archives)

        input.ReadOnly
        |> List.sort
        |> items (fun layer ->
            id layer.Id
            text layer.Generation

            number (
                match layer.Kind with
                | ReadOnlyLayerKind.Base -> 0L
                | ReadOnlyLayerKind.Secondary -> 1L
            )

            number (int64 layer.Priority)
            flag layer.Complete

            layer.Files
            |> List.sort
            |> items (fun file ->
                path file.Path
                snapshotIdentity file.Identity)

            mappings layer.Mappings
            archives layer.Archives)

        input.Writable
        |> List.sort
        |> items (fun sink ->
            id sink.Id

            match sink.Target with
            | WritableTarget.File(root, value) ->
                number 0L
                id root
                path value
            | WritableTarget.Subtree(root, value) ->
                number 1L
                id root
                location value)

        hash.GetHashAndReset() |> Convert.ToHexStringLower
