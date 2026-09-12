namespace ModConductor.Fomod

open System
open System.Xml.Linq
open ModConductor.ArchiveInspection

module XmlModel =
    open XmlValues

    let private optionType value =
        match value with
        | "Required" -> OptionType.Required
        | "Recommended" -> OptionType.Recommended
        | "Optional" -> OptionType.Optional
        | "NotUsable" -> OptionType.NotUsable
        | "CouldBeUsable" -> OptionType.CouldBeUsable
        | _ -> refuse ("The installer has an unsupported option type: " + value)

    let private groupType value =
        match value with
        | "SelectAny" -> GroupType.Any
        | "SelectAll" -> GroupType.All
        | "SelectAtLeastOne" -> GroupType.AtLeastOne
        | "SelectAtMostOne" -> GroupType.AtMostOne
        | "SelectExactlyOne" -> GroupType.ExactlyOne
        | _ -> refuse ("The installer has an unsupported choice group: " + value)

    let private typed (node: XElement) =
        shape [] [ "name" ] node
        optionType (required "name" node)

    let private always = Condition.All []

    let rec private condition depth (node: XElement) =
        if depth > 32 then
            refuse "The installer conditions are too deeply nested. Use the manual layout."

        match node.Name.LocalName with
        | "fileDependency" ->
            shape [] [ "file"; "state" ] node

            let state =
                match required "state" node with
                | "Missing" -> FileState.Missing
                | "Inactive" -> FileState.Inactive
                | "Active" -> FileState.Active
                | _ -> refuse "The installer contains an unsupported file state."

            Condition.File(logical (required "file" node), state)
        | "flagDependency" ->
            shape [] [ "flag"; "value" ] node
            Condition.Flag(required "flag" node, optional "value" "" node)
        | "gameDependency"
        | "fommDependency"
        | "foseDependency" as kind ->
            shape [] [ "version" ] node
            let value = required "version" node

            match kind with
            | "gameDependency" -> Condition.GameVersion value
            | "fommDependency" -> Condition.FommVersion value
            | _ -> Condition.ExtenderVersion value
        | _ ->
            shape
                [ "fileDependency"
                  "flagDependency"
                  "gameDependency"
                  "fommDependency"
                  "foseDependency"
                  "dependencies" ]
                [ "operator" ]
                node

            let values = node.Elements() |> Seq.map (condition (depth + 1)) |> Seq.toList

            match optional "operator" "And" node with
            | "And" -> Condition.All values
            | "Or" -> Condition.Any values
            | _ -> refuse "The installer contains an unsupported condition operator."

    let private dependency name node =
        child name node |> Option.map (condition 0) |> Option.defaultValue always

    let private image name node =
        child name node
        |> Option.bind (fun value ->
            shape [] [ "path"; "showImage"; "showFade"; "height" ] value

            if boolean "showImage" true value then
                attribute "path" value |> Option.map (path false)
            else
                None)

    let read root manifest (node: XElement) =
        if node.Name <> xn "config" then
            refuse "This is not a supported FOMOD XML installer. Use the manual layout."

        let schema =
            node.Attribute(
                XName.Get("noNamespaceSchemaLocation", "http://www.w3.org/2001/XMLSchema-instance")
            )

        if
            not (isNull schema)
            && not (
                schema.Value.EndsWith("ModConfig5.0.xsd", StringComparison.OrdinalIgnoreCase)
                || schema.Value.EndsWith("XmlScript5.0.xsd", StringComparison.OrdinalIgnoreCase)
            )
        then
            refuse "This FOMOD schema version is not supported. Use the manual layout."

        shape
            [ "moduleName"
              "moduleImage"
              "moduleDependencies"
              "requiredInstallFiles"
              "installSteps"
              "conditionalFileInstalls" ]
            []
            node

        let mutable mappingId, optionId, groupCount = 0, 0, 0

        let mappings (parent: XElement) =
            shape [ "file"; "folder" ] [] parent

            [ for item in parent.Elements() do
                  shape
                      []
                      [ "source"; "destination"; "alwaysInstall"; "installIfUsable"; "priority" ]
                      item

                  mappingId <- mappingId + 1

                  if mappingId > 20000 then
                      refuse "The installer contains too many file mappings."

                  let source =
                      attribute "source" item
                      |> Option.defaultWith (fun () ->
                          refuse "The installer is missing source. Use the manual layout.")

                  let destination = optional "destination" source item
                  let folder = item.Name.LocalName = "folder"

                  yield
                      { Order = mappingId
                        Source = path folder source
                        Destination = path true destination
                        AppendName =
                          not folder
                          && (destination = ""
                              || destination.EndsWith('/')
                              || destination.EndsWith('\\'))
                        Folder = folder
                        Priority = number "priority" 0 item
                        Always = boolean "alwaysInstall" false item
                        IfUsable = boolean "installIfUsable" false item } ]

        let descriptor (parent: XElement) =
            shape [ "type"; "dependencyType" ] [] parent

            match child "type" parent, child "dependencyType" parent with
            | Some value, None -> TypeDescriptor.Fixed(typed value)
            | None, Some value ->
                shape [ "defaultType"; "patterns" ] [] value
                let fallback = requiredChild "defaultType" value |> typed
                let patterns = requiredChild "patterns" value
                shape [ "pattern" ] [] patterns

                let values =
                    [ for item in children "pattern" patterns do
                          shape [ "dependencies"; "type" ] [] item

                          yield
                              condition 0 (requiredChild "dependencies" item),
                              typed (requiredChild "type" item) ]

                TypeDescriptor.Dependent(fallback, values)
            | _ -> refuse "The installer option has no supported type."

        let parseOption (item: XElement) =
            shape
                [ "description"; "image"; "files"; "conditionFlags"; "typeDescriptor" ]
                [ "name" ]
                item

            optionId <- optionId + 1

            if optionId > 4096 then
                refuse "The installer contains too many choices."

            let flags =
                child "conditionFlags" item
                |> Option.map (fun parent ->
                    shape [ "flag" ] [] parent

                    [ for flag in children "flag" parent do
                          shape [] [ "name" ] flag
                          yield required "name" flag, flag.Value ])
                |> Option.defaultValue []

            { Id = optionId
              Name = required "name" item
              Description = text "description" "" item
              Image = image "image" item
              Files = child "files" item |> Option.map mappings |> Option.defaultValue []
              Flags = flags
              Type = descriptor (requiredChild "typeDescriptor" item) }

        let parseGroup (item: XElement) =
            shape [ "plugins" ] [ "name"; "type" ] item
            groupCount <- groupCount + 1

            if groupCount > 512 then
                refuse "The installer contains too many choice groups."

            let plugins = requiredChild "plugins" item
            shape [ "plugin" ] [ "order" ] plugins

            { Name = required "name" item
              Kind = groupType (required "type" item)
              Options =
                children "plugin" plugins
                |> List.map parseOption
                |> order (fun option -> option.Name) plugins }

        let requiredFiles =
            child "requiredInstallFiles" node
            |> Option.map mappings
            |> Option.defaultValue []

        let steps =
            child "installSteps" node
            |> Option.map (fun parent ->
                shape [ "installStep" ] [ "order" ] parent
                let steps = children "installStep" parent

                if steps.Length > 128 then
                    refuse "The installer contains too many steps."

                steps
                |> List.map (fun item ->
                    shape [ "visible"; "optionalFileGroups" ] [ "name" ] item
                    let groups = requiredChild "optionalFileGroups" item
                    shape [ "group" ] [ "order" ] groups

                    { Index = 0
                      Name = required "name" item
                      Visible = dependency "visible" item
                      Groups =
                        children "group" groups
                        |> List.map parseGroup
                        |> order (fun group -> group.Name) groups })
                |> order (fun step -> step.Name) parent
                |> List.mapi (fun index step -> { step with Index = index }))
            |> Option.defaultValue []

        let conditional =
            child "conditionalFileInstalls" node
            |> Option.map (fun value ->
                shape [ "patterns" ] [] value
                let patterns = requiredChild "patterns" value
                shape [ "pattern" ] [] patterns

                [ for item in children "pattern" patterns do
                      shape [ "dependencies"; "files" ] [] item

                      yield
                          condition 0 (requiredChild "dependencies" item),
                          mappings (requiredChild "files" item) ])
            |> Option.defaultValue []

        { Name = text "moduleName" "" node
          Version = ""
          Root = root
          Image = image "moduleImage" node
          Dependency = dependency "moduleDependencies" node
          Required = requiredFiles
          Steps = steps
          Conditional = conditional
          Manifest = manifest }
