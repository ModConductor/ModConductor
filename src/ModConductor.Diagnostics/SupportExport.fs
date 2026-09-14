namespace ModConductor.Diagnostics

open System
open System.Buffers
open System.Text.Json

module internal SupportExport =
    let private severity =
        function
        | DiagnosticSeverity.Information -> "information"
        | DiagnosticSeverity.Warning -> "warning"
        | DiagnosticSeverity.Error -> "error"

    let private correlation =
        function
        | CorrelationKind.Launch -> "launch"
        | CorrelationKind.ModFiles -> "mod-files"
        | CorrelationKind.GameSetup -> "game-setup"
        | CorrelationKind.Deployment -> "deployment"
        | CorrelationKind.Profile -> "profile"
        | CorrelationKind.Action -> "action"

    let write (snapshot: DiagnosticSnapshot) =
        let bytes = ArrayBufferWriter<byte>()
        use writer = new Utf8JsonWriter(bytes, JsonWriterOptions(Indented = true))
        writer.WriteStartObject()
        writer.WriteString("format", "mod-conductor-support-1")
        writer.WriteString("capturedAtUtc", snapshot.CapturedAt.UtcDateTime)
        writer.WriteString("workspaceId", snapshot.WorkspaceId.ToString "N")
        writer.WriteString("profileId", snapshot.ProfileId.ToString "N")
        writer.WriteString("operatingSystem", Environment.OSVersion.Platform.ToString())
        writer.WriteString("architecture", System.Runtime.InteropServices.RuntimeInformation.ProcessArchitecture.ToString())
        writer.WriteStartArray("problems")

        for finding in snapshot.Findings |> List.truncate Limits.findings do
            writer.WriteStartObject()
            writer.WriteString("code", finding.Code)
            writer.WriteString("severity", severity finding.Severity)
            writer.WriteStartArray("ids")

            for value in finding.Correlations do
                writer.WriteStartObject()
                writer.WriteString("kind", correlation value.Kind)
                writer.WriteString("id", value.Id.ToString "N")
                value.Revision |> Option.iter (fun revision -> writer.WriteNumber("revision", revision))
                writer.WriteEndObject()

            writer.WriteEndArray()
            writer.WriteEndObject()

        writer.WriteEndArray()
        writer.WriteEndObject()
        writer.Flush()

        if bytes.WrittenCount > Limits.exportBytes then
            Error DiagnosticError.Oversized
        else
            Ok
                { FileName = "mod-conductor-support.json"
                  Content = bytes.WrittenSpan.ToArray() }
