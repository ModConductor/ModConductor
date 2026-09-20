namespace ModConductor.GameContexts

open System
open System.IO
open System.Security.Cryptography
open System.Text
open ModConductor.Platform

module ComponentRoots =
    let private identity (writer: BinaryWriter) (value: FileIdentity) =
        match value.Device with
        | LinuxDevice(major, minor) ->
            writer.Write 1
            writer.Write major
            writer.Write minor
        | WindowsVolume serial ->
            writer.Write 2
            writer.Write serial

        writer.Write value.Low
        writer.Write value.High

    let gameRootId (workspace: Guid) (evidence: InstallationEvidence) =
        if
            not evidence.Valid
            || evidence.DefinitionId <> Skyrim.definition.Id
            || evidence.DefinitionRevision <> Skyrim.definition.Revision
        then
            Error "Select a checked Skyrim installation."
        else
            use bytes = new MemoryStream()
            use writer = new BinaryWriter(bytes, Encoding.UTF8, true)
            writer.Write "mc-skyrim-game-root-v1"
            writer.Write(workspace.ToByteArray())
            writer.Write evidence.DefinitionId
            writer.Write evidence.RootPath
            identity writer evidence.RootIdentity.Value
            writer.Flush()
            let value = Guid(SHA256.HashData(bytes.ToArray()).AsSpan(0, 16))

            if value = workspace then
                invalidOp "The component target identities collided."

            Ok value
