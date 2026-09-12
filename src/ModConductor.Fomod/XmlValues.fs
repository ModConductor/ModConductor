namespace ModConductor.Fomod

open System
open System.IO
open System.Xml
open System.Xml.Linq
open ModConductor.Platform

module internal XmlValues =
    let refuse message = raise (FomodException message)
    let xn value = XName.Get value

    let child name (node: XElement) =
        match node.Elements(xn name) |> Seq.toList with
        | [] -> None
        | [ value ] -> Some value
        | _ -> refuse ("The installer repeats " + name + ". Use the manual layout.")

    let children name (node: XElement) = node.Elements(xn name) |> Seq.toList

    let attribute name (node: XElement) =
        node.Attribute(xn name) |> Option.ofObj |> Option.map _.Value

    let optional name fallback node =
        attribute name node |> Option.defaultValue fallback

    let required name node =
        attribute name node
        |> Option.filter (String.IsNullOrWhiteSpace >> not)
        |> Option.defaultWith (fun () ->
            refuse ("The installer is missing " + name + ". Use the manual layout."))

    let text name fallback node =
        child name node |> Option.map _.Value |> Option.defaultValue fallback

    let requiredChild name node =
        child name node
        |> Option.defaultWith (fun () ->
            refuse ("The installer is missing " + name + ". Use the manual layout."))

    let shape elements attributes (node: XElement) =
        for element in node.Elements() do
            if
                element.Name.NamespaceName <> ""
                || not (List.contains element.Name.LocalName elements)
            then
                refuse (
                    "This installer feature is not supported: "
                    + element.Name.LocalName
                    + ". Use the manual layout."
                )

        for attribute in node.Attributes() do
            if
                not attribute.IsNamespaceDeclaration
                && not (
                    attribute.Name.NamespaceName = "http://www.w3.org/2001/XMLSchema-instance"
                    && attribute.Name.LocalName = "noNamespaceSchemaLocation"
                    && node.Name.LocalName = "config"
                )
                && (attribute.Name.NamespaceName <> ""
                    || not (List.contains attribute.Name.LocalName attributes))
            then
                refuse (
                    "This installer attribute is not supported: "
                    + attribute.Name.LocalName
                    + ". Use the manual layout."
                )

    let boolean name fallback node =
        match attribute name node with
        | None -> fallback
        | Some "true"
        | Some "1" -> true
        | Some "false"
        | Some "0" -> false
        | Some _ -> refuse ("The installer has an invalid " + name + " value.")

    let number name fallback node =
        match attribute name node with
        | None -> fallback
        | Some value ->
            match Int32.TryParse value with
            | true, value -> value
            | _ -> refuse ("The installer has an invalid " + name + " value.")

    let path allowEmpty (value: string) =
        let value = value.Replace('\\', '/')

        if value = "" && allowEmpty then
            []
        else
            let parts = value.TrimEnd('/').Split('/') |> Array.toList

            LogicalPath.create parts
            |> Result.map LogicalPath.components
            |> Result.defaultWith (fun _ ->
                refuse "The installer contains an unsafe path. Use the manual layout.")

    let logical value =
        path false value
        |> LogicalPath.create
        |> Result.defaultWith (fun _ -> invalidOp "Invalid checked path")

    let order nameOf node values =
        match optional "order" "Ascending" node with
        | "Explicit" -> values
        | "Ascending" ->
            values
            |> List.sortWith (fun a b -> StringComparer.Ordinal.Compare(nameOf a, nameOf b))
        | "Descending" ->
            values
            |> List.sortWith (fun a b -> StringComparer.Ordinal.Compare(nameOf b, nameOf a))
        | _ -> refuse "The installer has an unsupported sort order."

    let document maxCharacters (stream: Stream) =
        let settings =
            XmlReaderSettings(
                DtdProcessing = DtdProcessing.Prohibit,
                XmlResolver = null,
                MaxCharactersInDocument = maxCharacters,
                CloseInput = false
            )

        use reader = XmlReader.Create(stream, settings)
        let document = XDocument.Load(reader, LoadOptions.None)

        if isNull document.Root then
            refuse "The installer XML is empty. Download a fresh copy or use the manual layout."

        document.Root
