namespace ModConductor.ModOrganization

open System
open System.Collections.Generic
open System.Globalization
open System.IO
open System.Text
open System.Threading
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform
open ModConductor.Workspaces

module InventoryExportCsv =
    let maximumRows = 100000
    let maximumBytes = 64L * 1024L * 1024L

    let fields =
        [ InventoryExportField.ModId
          InventoryExportField.Name
          InventoryExportField.Kind
          InventoryExportField.Status
          InventoryExportField.Priority
          InventoryExportField.Enabled
          InventoryExportField.Version
          InventoryExportField.Source
          InventoryExportField.SourcePath
          InventoryExportField.Notes
          InventoryExportField.Comment
          InventoryExportField.Categories ]

    let header =
        function
        | InventoryExportField.ModId -> "mod_id"
        | InventoryExportField.Name -> "name"
        | InventoryExportField.Kind -> "kind"
        | InventoryExportField.Status -> "status"
        | InventoryExportField.Priority -> "priority"
        | InventoryExportField.Enabled -> "enabled"
        | InventoryExportField.Version -> "version"
        | InventoryExportField.Source -> "source"
        | InventoryExportField.SourcePath -> "source_path"
        | InventoryExportField.Notes -> "notes"
        | InventoryExportField.Comment -> "comment"
        | InventoryExportField.Categories -> "categories"

    let canonical requested =
        let selected = Set.ofList requested
        fields |> List.filter (fun field -> Set.contains field selected)

    let private formulaPrefix (value: string) =
        let mutable index = 0

        while index < value.Length
              && int value[index] <= 0x7f
              && Char.IsWhiteSpace value[index] do
            index <- index + 1

        if index < value.Length && "=+-@".Contains value[index] then
            "'" + value
        else
            value

    let private quote (value: string) =
        "\"" + value.Replace("\"", "\"\"") + "\""

    let private kind =
        function
        | ModKind.Regular -> "regular"
        | ModKind.Separator -> "separator"
        | ModKind.Backup -> "backup"
        | ModKind.Unmanaged -> "unmanaged"
        | ModKind.GeneratedOutput -> "generated_output"

    let private status =
        function
        | InventoryStatus.Ready -> "ready"
        | InventoryStatus.Detached -> "detached"
        | InventoryStatus.Changed -> "changed"
        | InventoryStatus.Unproved -> "unproved"
        | InventoryStatus.Publishing -> "publishing"

    let private priority =
        function
        | SelectionState.Managed(value, _)
        | SelectionState.Separator value -> string (value + 1)
        | SelectionState.Locked _ -> ""

    let private enabled =
        function
        | SelectionState.Managed(_, value) -> if value then "true" else "false"
        | SelectionState.Separator _
        | SelectionState.Locked _ -> ""

    let private categories (values: CategoryReference list) =
        values
        |> List.sortBy _.Id
        |> List.map (fun value -> value.Label + " [" + value.Id.ToString("N") + "]")
        |> String.concat " | "

    let private value field (row: OrganizedMod) =
        let modValue = row.Entry.Mod

        match field with
        | InventoryExportField.ModId -> modValue.Id.ToString("N"), false
        | InventoryExportField.Name -> modValue.Metadata.Name, true
        | InventoryExportField.Kind -> kind modValue.Kind, false
        | InventoryExportField.Status -> status modValue.Status, false
        | InventoryExportField.Priority -> priority row.Entry.Selection, false
        | InventoryExportField.Enabled -> enabled row.Entry.Selection, false
        | InventoryExportField.Version -> modValue.Metadata.Version, true
        | InventoryExportField.Source -> modValue.Metadata.Source, true
        | InventoryExportField.SourcePath ->
            modValue.SourcePath |> Option.map LogicalPath.display |> Option.defaultValue "", true
        | InventoryExportField.Notes -> modValue.Metadata.Notes, true
        | InventoryExportField.Comment -> modValue.Metadata.Comment, true
        | InventoryExportField.Categories -> categories modValue.Metadata.Categories, true

    let private line values =
        values
        |> List.map (fun (value, untrusted) ->
            value |> (if untrusted then formulaPrefix else id) |> quote)
        |> String.concat ","

    let headerLine selected =
        selected |> List.map (header >> fun value -> value, false) |> line

    let rowLine selected row =
        selected |> List.map (fun field -> value field row) |> line

    let byteLength selected rows =
        let utf8 = UTF8Encoding(false, true)
        let mutable total = int64 (utf8.GetByteCount(headerLine selected) + 2)

        for row in rows do
            total <- total + int64 (utf8.GetByteCount(rowLine selected row) + 2)

        total

    let write
        (output: FileStream)
        selected
        rows
        (progress: InventoryExportProgress -> Task)
        (token: CancellationToken)
        =
        task {
            use writer = new StreamWriter(output, UTF8Encoding(false, true), 16384, true)
            writer.NewLine <- "\r\n"
            do! writer.WriteLineAsync((headerLine selected).AsMemory(), token)
            let mutable written = 0
            let total = List.length rows

            for row in rows do
                token.ThrowIfCancellationRequested()
                do! writer.WriteLineAsync((rowLine selected row).AsMemory(), token)
                written <- written + 1

                if written = total || written % 32 = 0 then
                    do! progress { Written = written; Total = total }

            do! writer.FlushAsync token
            return output.Position
        }
