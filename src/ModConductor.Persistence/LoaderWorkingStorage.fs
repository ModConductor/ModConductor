namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Platform
open ModConductor.FilePlanning

module internal LoaderWorkingStorage =
    let path (root: WorkspaceRoot) (profile: Guid) (id: Guid) =
        Path.Combine(
            HostPath.value root.Path,
            ".mc-component-working",
            profile.ToString("N"),
            id.ToString("N") + ".working"
        )

    let available root profile id directory =
        let target = path root profile id

        if directory then
            Directory.Exists target
        else
            File.Exists target

    let within (root: WorkspaceRoot) (profile: Guid) (id: Guid) directory consume =
        use held = HeldDirectory.Open(root.Path, root.Identity)

        let rec descend (parent: HeldDirectory) =
            function
            | [] ->
                consume
                    parent
                    (if directory then
                         None
                     else
                         Some(id.ToString("N") + ".working"))
            | name :: rest ->
                match parent.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.Directory ->
                    use child = parent.Directory(name, Some entry.Identity)
                    descend child rest
                | _ -> Error "Deploy this profile before opening its loader files."

        descend
            held
            ([ ".mc-component-working"; profile.ToString("N") ]
             @ (if directory then [ id.ToString("N") + ".working" ] else []))

    let read (directory: HeldDirectory) name =
        match directory.InspectEntry name with
        | Some entry when entry.Kind = EntryKind.RegularFile ->
            let stream, _ = directory.Read(name, Some entry.Identity)
            use stream = stream

            if stream.Length > int64 TextDocuments.bytesLimit then
                Error "This loader file is too large for the text editor."
            else
                let bytes = Array.zeroCreate<byte> (int stream.Length)
                stream.ReadExactly bytes
                Ok(bytes, entry)
        | _ -> Error "This loader file is not available yet."

    let save (directory: HeldDirectory) name original content =
        read directory name
        |> Result.bind (fun (current, identity) ->
            if current <> original then
                Error "The loader settings changed. Read them again before saving."
            else
                TextDocuments.editable current
                |> Result.bind (fun document -> TextDocuments.encode document content)
                |> Result.map (fun bytes ->
                    let stage = Guid.NewGuid().ToString("N") + ".cfg"

                    let staged =
                        let stream, staged = directory.Create stage
                        use stream = stream
                        stream.Write bytes
                        stream.Flush true
                        staged

                    try
                        directory.ReplaceFile(stage, staged, name, Some identity)
                    finally
                        directory.InspectEntry stage
                        |> Option.iter (fun entry -> directory.RemoveFile(stage, entry.Identity))))
