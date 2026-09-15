namespace ModConductor.Engine

open ModConductor.ModOrganization
open ModConductor.Protocol.V1

module internal InventoryExportWire =
    let scope (value: ModConductor.Protocol.V1.InventoryExportScope) =
        match value with
        | ModConductor.Protocol.V1.InventoryExportScope.Selected ->
            ModConductor.ModOrganization.InventoryExportScope.Selected
        | ModConductor.Protocol.V1.InventoryExportScope.Enabled ->
            ModConductor.ModOrganization.InventoryExportScope.Enabled
        | ModConductor.Protocol.V1.InventoryExportScope.CurrentQuery ->
            ModConductor.ModOrganization.InventoryExportScope.CurrentQuery
        | ModConductor.Protocol.V1.InventoryExportScope.All ->
            ModConductor.ModOrganization.InventoryExportScope.All
        | _ -> ModLibraryWire.reject "Choose which mods to export."

    let field (value: ModConductor.Protocol.V1.InventoryExportField) =
        match value with
        | ModConductor.Protocol.V1.InventoryExportField.ModId ->
            ModConductor.ModOrganization.InventoryExportField.ModId
        | ModConductor.Protocol.V1.InventoryExportField.Name ->
            ModConductor.ModOrganization.InventoryExportField.Name
        | ModConductor.Protocol.V1.InventoryExportField.Kind ->
            ModConductor.ModOrganization.InventoryExportField.Kind
        | ModConductor.Protocol.V1.InventoryExportField.Status ->
            ModConductor.ModOrganization.InventoryExportField.Status
        | ModConductor.Protocol.V1.InventoryExportField.Priority ->
            ModConductor.ModOrganization.InventoryExportField.Priority
        | ModConductor.Protocol.V1.InventoryExportField.Enabled ->
            ModConductor.ModOrganization.InventoryExportField.Enabled
        | ModConductor.Protocol.V1.InventoryExportField.Version ->
            ModConductor.ModOrganization.InventoryExportField.Version
        | ModConductor.Protocol.V1.InventoryExportField.Source ->
            ModConductor.ModOrganization.InventoryExportField.Source
        | ModConductor.Protocol.V1.InventoryExportField.SourcePath ->
            ModConductor.ModOrganization.InventoryExportField.SourcePath
        | ModConductor.Protocol.V1.InventoryExportField.Notes ->
            ModConductor.ModOrganization.InventoryExportField.Notes
        | ModConductor.Protocol.V1.InventoryExportField.Comment ->
            ModConductor.ModOrganization.InventoryExportField.Comment
        | ModConductor.Protocol.V1.InventoryExportField.Categories ->
            ModConductor.ModOrganization.InventoryExportField.Categories
        | _ -> ModLibraryWire.reject "Choose valid CSV columns."

    let encodeField (value: ModConductor.ModOrganization.InventoryExportField) =
        match value with
        | ModConductor.ModOrganization.InventoryExportField.ModId ->
            ModConductor.Protocol.V1.InventoryExportField.ModId
        | ModConductor.ModOrganization.InventoryExportField.Name ->
            ModConductor.Protocol.V1.InventoryExportField.Name
        | ModConductor.ModOrganization.InventoryExportField.Kind ->
            ModConductor.Protocol.V1.InventoryExportField.Kind
        | ModConductor.ModOrganization.InventoryExportField.Status ->
            ModConductor.Protocol.V1.InventoryExportField.Status
        | ModConductor.ModOrganization.InventoryExportField.Priority ->
            ModConductor.Protocol.V1.InventoryExportField.Priority
        | ModConductor.ModOrganization.InventoryExportField.Enabled ->
            ModConductor.Protocol.V1.InventoryExportField.Enabled
        | ModConductor.ModOrganization.InventoryExportField.Version ->
            ModConductor.Protocol.V1.InventoryExportField.Version
        | ModConductor.ModOrganization.InventoryExportField.Source ->
            ModConductor.Protocol.V1.InventoryExportField.Source
        | ModConductor.ModOrganization.InventoryExportField.SourcePath ->
            ModConductor.Protocol.V1.InventoryExportField.SourcePath
        | ModConductor.ModOrganization.InventoryExportField.Notes ->
            ModConductor.Protocol.V1.InventoryExportField.Notes
        | ModConductor.ModOrganization.InventoryExportField.Comment ->
            ModConductor.Protocol.V1.InventoryExportField.Comment
        | ModConductor.ModOrganization.InventoryExportField.Categories ->
            ModConductor.Protocol.V1.InventoryExportField.Categories

    let fault error =
        let code, detail =
            match error with
            | InventoryExportError.InvalidRequest ->
                InventoryExportFaultCode.InvalidRequest, "Select Name or Mod ID."
            | InventoryExportError.NotFound ->
                InventoryExportFaultCode.NotFound, "The export expired. Choose the mods again."
            | InventoryExportError.Stale ->
                InventoryExportFaultCode.Stale,
                "The selected mods changed. Use the current selection."
            | InventoryExportError.Busy ->
                InventoryExportFaultCode.Busy, "Another export action is active."
            | InventoryExportError.LimitExceeded ->
                InventoryExportFaultCode.LimitExceeded,
                "The export is too large. Select fewer mods or columns."
            | InventoryExportError.DestinationUnavailable ->
                InventoryExportFaultCode.DestinationUnavailable,
                "Choose a regular file in an available folder."
            | InventoryExportError.DestinationChanged ->
                InventoryExportFaultCode.DestinationChanged,
                "The destination changed. Choose the location again."
            | InventoryExportError.ReplacementRequired ->
                InventoryExportFaultCode.ReplacementRequired,
                "Select Replace existing file to continue."
            | InventoryExportError.Cancelled ->
                InventoryExportFaultCode.Cancelled, "You canceled the export."
            | InventoryExportError.WriteFailed ->
                InventoryExportFaultCode.WriteFailed, "Mod Conductor cannot write the CSV file."

        InventoryExportFault(Code = code, Detail = detail)
