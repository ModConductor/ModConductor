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

    let legacyRootId (workspace: Guid) (evidence: InstallationEvidence) =
        match evidence.RootIdentity with
        | None -> None
        | Some rootIdentity ->
            use bytes = new MemoryStream()
            use writer = new BinaryWriter(bytes, Encoding.UTF8, true)

            writer.Write(
                if (GameClient.mono (GameCatalog.forGame evidence.DefinitionId)).IsSome then
                    "mc-unity-mono-game-root-v1"
                elif (GameClient.il2cpp (GameCatalog.forGame evidence.DefinitionId)).IsSome then
                    "mc-unity-il2cpp-game-root-v1"
                elif (GameClient.unreal (GameCatalog.forGame evidence.DefinitionId)).IsSome then
                    "mc-unreal-game-root-v1"
                elif GameCatalog.isSkyrimSE evidence.DefinitionId then
                    "mc-skyrim-game-root-v1"
                else
                    "mc-bethesda-game-root-v1"
            )

            writer.Write(workspace.ToByteArray())
            writer.Write(GameId.value evidence.DefinitionId)
            writer.Write evidence.RootPath
            identity writer rootIdentity
            writer.Flush()
            let value = Guid(SHA256.HashData(bytes.ToArray()).AsSpan(0, 16))

            if value = workspace then
                invalidOp "The component target identities collided."

            Some value

    let logicalRootId (workspace: Guid) (evidence: InstallationEvidence) =
        use bytes = new MemoryStream()
        use writer = new BinaryWriter(bytes, Encoding.UTF8, true)
        writer.Write "mc-component-root-v2"
        writer.Write(workspace.ToByteArray())
        writer.Write(GameId.value evidence.DefinitionId)
        writer.Write evidence.RootPath
        writer.Flush()
        Guid(SHA256.HashData(bytes.ToArray()).AsSpan(0, 16))

    let registeredRootId (binding: GameBinding) =
        if
            not binding.Evidence.Valid
            || binding.Evidence.DefinitionRevision
               <> (GameCatalog.forGame binding.Evidence.DefinitionId).Revision
        then
            Error "Select a checked game installation."
        else
            Ok binding.ComponentRoot
