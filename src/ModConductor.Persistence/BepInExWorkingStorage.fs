namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.BepInEx
open ModConductor.Platform
open ModConductor.FilePlanning

module internal BepInExWorkingStorage =
    let private descend (directory: HeldDirectory) parts consume =
        let rec next (directory: HeldDirectory) =
            function
            | [] -> consume directory
            | name :: rest ->
                match directory.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.Directory ->
                    use child = directory.Directory(name, Some entry.Identity)
                    next child rest
                | _ -> Error "Deploy this profile before opening its loader files."

        next directory parts

    let private read (directory: HeldDirectory) name =
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

    let available (root: WorkspaceRoot) (profile: Guid) (id: Guid) directory =
        let path =
            Path.Combine(
                HostPath.value root.Path,
                ".mc-component-working",
                profile.ToString("N"),
                id.ToString("N") + ".working"
            )

        if directory then
            Directory.Exists path
        else
            File.Exists path

    let config (root: WorkspaceRoot) (profile: Guid) action =
        use directory = HeldDirectory.Open(root.Path, root.Identity)

        descend
            directory
            [ ".mc-component-working"
              profile.ToString("N")
              WorkingPaths.config.ToString("N") + ".working" ]
            action

    let readConfig root profile =
        config root profile (fun directory -> read directory "BepInEx.cfg" |> Result.map fst)

    let saveConfig root profile original content =
        config root profile (fun directory ->
            read directory "BepInEx.cfg"
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
                            directory.ReplaceFile(stage, staged, "BepInEx.cfg", Some identity)
                        finally
                            directory.InspectEntry stage
                            |> Option.iter (fun entry ->
                                directory.RemoveFile(stage, entry.Identity)))))

    let readLog (root: WorkspaceRoot) (profile: Guid) =
        use directory = HeldDirectory.Open(root.Path, root.Identity)

        descend directory [ ".mc-component-working"; profile.ToString("N") ] (fun directory ->
            read directory ((fst WorkingPaths.logs.Head).ToString("N") + ".working")
            |> Result.map fst)
