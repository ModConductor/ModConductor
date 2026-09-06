namespace ModConductor.Native.Fixtures

open System.Text.Json
open ModConductor.Platform

module Report =
    let problem =
        function
        | OutsideRoot -> "outside-root"
        | LinkCycle -> "link-cycle"
        | MissingEntry -> "missing-entry"
        | UnsupportedEntry -> "unsupported-entry"
        | FileDirectoryConflict -> "file-directory-conflict"
        | TargetCollision -> "target-collision"
        | InvalidTargetName _ -> "invalid-target-name"
        | LimitExceeded -> "limit-exceeded"
        | NativeError _ -> "native-error"
        | AccessFailure _ -> "access-failure"

    let private kind =
        function
        | EntryKind.RegularFile -> "file"
        | EntryKind.Directory -> "directory"
        | EntryKind.Link -> "link"
        | EntryKind.Other -> "other"

    let identity (writer: Utf8JsonWriter) facts =
        writer.WriteStartObject("identity")

        match facts.File with
        | Known file ->
            writer.WriteBoolean("known", true)

            match file.Device with
            | LinuxDevice(major, minor) ->
                writer.WriteString("device", major.ToString() + ":" + minor.ToString())
            | WindowsVolume serial -> writer.WriteString("device", serial.ToString())

            writer.WriteNumber("low", file.Low)
            writer.WriteNumber("high", file.High)
        | Unknown reason ->
            writer.WriteBoolean("known", false)
            writer.WriteString("reason", reason)

        match facts.Mount with
        | Known mount -> writer.WriteNumber("mount", mount)
        | Unknown reason ->
            writer.WriteNull("mount")
            writer.WriteString("mountUnknown", reason)

        writer.WriteEndObject()

    let preflight (writer: Utf8JsonWriter) (name: string) (report: Preflight) =
        writer.WriteStartObject(name: string)
        writer.WriteString("root", RootSelection.path report.Root |> HostPath.value)
        identity writer (RootSelection.facts report.Root)
        writer.WriteStartArray("entries")

        for entry in report.Entries do
            writer.WriteStartObject()
            writer.WriteString("name", LogicalPath.display entry.Logical)
            writer.WriteString("host", HostPath.value entry.Host)
            writer.WriteString("resolved", HostPath.value entry.Resolved)
            writer.WriteString("kind", kind entry.Kind)
            writer.WriteString("targetKind", kind entry.TargetKind)
            identity writer entry.Facts
            writer.WriteEndObject()

        writer.WriteEndArray()
        writer.WriteStartArray("diagnostics")

        for diagnostic in report.Diagnostics do
            writer.WriteStartObject()
            writer.WriteString("path", diagnostic.Path)
            writer.WriteString("problem", problem diagnostic.Problem)

            match diagnostic.Problem with
            | NativeError error ->
                writer.WriteString("nativeOperation", error.Operation)
                writer.WriteNumber("nativeCode", error.Code)
            | _ -> ()

            writer.WriteEndObject()

        writer.WriteEndArray()
        writer.WriteEndObject()

    let outcome (writer: Utf8JsonWriter) (name: string) =
        function
        | Observed -> writer.WriteString(name, "observed")
        | Refused reason ->
            writer.WriteString(name, "refused")
            writer.WriteString(name + "Reason", reason)
        | NotTested reason ->
            writer.WriteString(name, "unknown")
            writer.WriteString(name + "Reason", reason)

    let capabilities (writer: Utf8JsonWriter) (name: string) (report: FileSystemCapabilities) =
        writer.WriteStartObject(name: string)
        identity writer report.Identity
        outcome writer "write" report.Write
        outcome writer "rename" report.CaseOnlyRename
        outcome writer "hardLink" report.HardLink
        outcome writer "symbolicLink" report.SymbolicLink
        outcome writer "longPath" report.LongPath
        outcome writer "reflink" report.Reflink
        outcome writer "metadataPreservation" report.MetadataPreservation

        match report.DistinctCaseNames with
        | Known value -> writer.WriteBoolean("distinctCaseNames", value)
        | Unknown _ -> writer.WriteNull("distinctCaseNames")

        match report.TestedPathLength with
        | Some value -> writer.WriteNumber("testedPathLength", value)
        | None -> writer.WriteNull("testedPathLength")

        writer.WriteEndObject()
