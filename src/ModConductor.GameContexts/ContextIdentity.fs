namespace ModConductor.GameContexts

open System
open System.IO
open System.Security.Cryptography
open ModConductor.Platform

module ContextIdentity =
    let fingerprint (evidence: InstallationEvidence) =
        use bytes = new MemoryStream()
        use writer = new BinaryWriter(bytes, System.Text.Encoding.UTF8, true)
        let text (value: string) = writer.Write value

        let identity value =
            match value with
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

        let location =
            function
            | Location.Located(path, exists) ->
                writer.Write 1
                text path
                writer.Write exists
            | Location.Unavailable reason ->
                writer.Write 2
                text reason

        text (GameId.value evidence.DefinitionId)
        writer.Write evidence.DefinitionRevision

        writer.Write(
            match evidence.Platform with
            | ContextPlatform.Windows -> 1
            | ContextPlatform.Proton -> 2
        )

        text evidence.RootPath
        identity evidence.RootIdentity
        text (Option.defaultValue "" evidence.DataPath)
        identity evidence.DataIdentity

        match evidence.Executable with
        | None -> writer.Write false
        | Some value ->
            writer.Write true
            text value.Path
            identity (Some value.Identity)
            writer.Write value.Length
            text value.Sha256
            text value.FileVersion
            text value.ProductVersion

        text (Option.defaultValue "" evidence.LauncherPath)
        location evidence.Locations.Documents
        location evidence.Locations.Saves
        location evidence.Locations.LocalAppData

        match evidence.Proton with
        | None -> writer.Write false
        | Some p ->
            writer.Write true
            writer.Write p.Selection.AppId

            match p.Selection.Association with
            | ProtonAssociation.Manual -> writer.Write 0
            | ProtonAssociation.Steam(root, library) ->
                writer.Write 1
                text root
                text library

            text p.Selection.CompatData
            text p.Selection.RuntimeDirectory
            text p.Selection.ToolId
            text p.PrefixPath
            identity (Some p.PrefixIdentity)
            identity (Some p.CompatDataIdentity)
            identity (Some p.RuntimeIdentity)
            text p.RuntimeName
            text p.RuntimeVersion
            text (Option.defaultValue "" p.PrefixVersion)
            text (Option.defaultValue "" p.PerGameTool)
            text (Option.defaultValue "" p.GlobalTool)
            text (Option.defaultValue "" p.MappingProblem)

            let file (f: ContextFileEvidence) =
                text f.Path
                identity (Some f.Identity)
                text f.Sha256

            match p.Launch with
            | Error reason ->
                writer.Write false
                text reason
            | Ok launch ->
                writer.Write true
                text launch.Executable
                writer.Write launch.Arguments.Length
                launch.Arguments |> List.iter text
                text launch.SteamRoot
                writer.Write launch.Libraries.Length
                launch.Libraries |> List.iter text

            file p.Launcher
            writer.Write p.Metadata.Length
            p.Metadata |> List.iter file
            writer.Write p.Paths.Length

            for path in p.Paths do
                text path.Name
                text (Option.defaultValue "" path.WindowsPath)
                location path.HostLocation

        writer.Write evidence.Problems.Length

        for issue in evidence.Problems do
            text issue.Path
            text issue.Detail

        writer.Flush()
        SHA256.HashData(bytes.ToArray()) |> Convert.ToHexStringLower
