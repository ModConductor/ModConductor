namespace ModConductor.Deployment

open System
open System.IO
open System.Text
open System.Security.Cryptography
open ModConductor.Platform
open ModConductor.GameContexts

module internal DeploymentContextId =
    let private encode action =
        use bytes = new MemoryStream()
        use writer = new BinaryWriter(bytes, Encoding.UTF8, true)
        action writer
        writer.Flush()
        SHA256.HashData(bytes.GetBuffer().AsSpan(0, int bytes.Length))

    let private fingerprintFor (marker: string) (evidence: InstallationEvidence) =
        encode (fun writer ->
            let identity =
                function
                | None -> writer.Write false
                | Some value ->
                    writer.Write true

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

            writer.Write marker
            writer.Write(GameId.value evidence.DefinitionId)
            writer.Write evidence.RootPath
            identity evidence.RootIdentity
            writer.Write(defaultArg evidence.DataPath "")
            identity evidence.DataIdentity)
        |> Convert.ToHexStringLower

    let fingerprint evidence =
        fingerprintFor "mc-profile-game-view-v2" evidence

    let legacyFingerprint evidence =
        fingerprintFor "mc-data-target-v1" evidence

    let create (workspace: Guid) (profile: Guid) (fingerprint: string) =
        let digest =
            encode (fun writer ->
                writer.Write "mc-game-deployment-v1"
                writer.Write(workspace.ToByteArray())
                writer.Write(profile.ToByteArray())
                writer.Write fingerprint)

        Guid(digest.AsSpan(0, 16))
