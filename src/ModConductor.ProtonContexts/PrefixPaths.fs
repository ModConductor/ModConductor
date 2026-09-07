namespace ModConductor.ProtonContexts

open System
open System.IO
open ModConductor.Platform
open ModConductor.GameContexts

module internal PrefixPaths =
    let resolve root identity (components: string list) file =
        use held =
            HeldDirectory.Open(HostPath.create root |> Result.defaultWith invalidOp, identity)

        let rec walk (directory: HeldDirectory) current remaining links =
            match remaining with
            | [] -> current, true
            | part :: rest ->
                if
                    part = ""
                    || part = "."
                    || part = ".."
                    || part.Contains('/')
                    || part.Contains('\000')
                then
                    raise (IOException "The prefix path contains an invalid component.")

                let names = directory.Names |> Seq.truncate 4097 |> Seq.toList

                if names.Length > 4096 then
                    raise (IOException "A prefix folder contains too many entries to check.")

                match
                    names
                    |> List.filter (fun n ->
                        String.Equals(n, part, StringComparison.OrdinalIgnoreCase))
                with
                | [] -> Path.Combine(Array.ofList (current :: part :: rest)), false
                | [ name ] ->
                    match directory.ReadLink name with
                    | Some target ->
                        if links >= 32 then
                            raise (IOException "The prefix path contains a link cycle.")

                        let path = Path.GetFullPath(target, current)

                        if not (PrefixFiles.contained root path) then
                            raise (
                                IOException "The user folder points outside the selected prefix."
                            )

                        let relative = Path.GetRelativePath(root, path)

                        let next =
                            if relative = "." then
                                []
                            else
                                relative.Split('/') |> List.ofArray

                        walk held root (next @ rest) (links + 1)
                    | None ->
                        let path = Path.Combine(current, name)

                        if rest.IsEmpty && file then
                            use input = fst (directory.Read(name, None))
                            path, true
                        else
                            use child = directory.Directory(name, None)
                            walk child path rest links
                | _ ->
                    raise (
                        IOException "The Windows path has ambiguous names in the selected prefix."
                    )

        walk held root components 0

    let locations
        (definition: GameDefinition)
        prefix
        identity
        (registry: string -> string -> WineRegistry.StringValue option)
        =
        let environment name =
            registry "Volatile Environment" name
            |> Option.orElseWith (fun () -> registry "Environment" name)
            |> Option.map _.Text

        let user = environment "USERPROFILE"

        let expand (value: string) =
            let mutable expanded = value

            for name in [ "USERPROFILE"; "HOMEDRIVE"; "HOMEPATH" ] do
                match environment name with
                | None -> ()
                | Some replacement ->
                    expanded <-
                        expanded.Replace(
                            "%" + name + "%",
                            replacement,
                            StringComparison.OrdinalIgnoreCase
                        )

            if expanded.Contains('%') then
                raise (IOException "A user folder uses an unknown prefix variable.")

            expanded

        let parse (value: string) =
            if
                value.Length < 3
                || not (Char.IsAsciiLetter value[0])
                || value[1] <> ':'
                || (value[2] <> '\\' && value[2] <> '/')
            then
                raise (IOException "The prefix user folder is not an absolute Windows drive path.")

            let parts =
                value.Substring(3).Split([| '\\'; '/' |], StringSplitOptions.RemoveEmptyEntries)
                |> List.ofArray

            if parts |> List.exists (fun p -> p = "." || p = ".." || p.Contains(':')) then
                raise (IOException "The prefix user folder contains an invalid Windows path.")

            ("dosdevices" :: (string (Char.ToLowerInvariant value[0]) + ":") :: parts)

        match user with
        | None ->
            raise (IOException "The prefix registry does not identify its Windows user profile.")
        | Some profile ->
            let _, exists = resolve prefix identity (parse (expand profile)) false

            if not exists then
                raise (IOException "The prefix Windows user profile folder was not found.")

        let shell name =
            registry
                "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders"
                name
            |> Option.orElseWith (fun () ->
                registry
                    "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders"
                    name)

        let locate label key components file =
            let mutable windows = None

            let location =
                try
                    match shell key with
                    | None ->
                        Location.Unavailable
                            "The prefix registry does not declare this user folder."
                    | Some value ->
                        let basePath = if value.Expand then expand value.Text else value.Text

                        let combined =
                            basePath.TrimEnd('\\', '/')
                            + "\\"
                            + String.Join("\\", (components: string list))

                        windows <- Some combined
                        let path, exists = resolve prefix identity (parse combined) file
                        Location.Located(path, exists)
                with :? IOException as e ->
                    Location.Unavailable e.Message

            { Name = label
              WindowsPath = windows
              HostLocation = location }

        [ yield locate "Documents" "Personal" definition.Documents false
          yield locate "Saves" "Personal" definition.Saves false
          yield locate "Local AppData" "Local AppData" definition.LocalAppData false
          for name in definition.IniFiles do
              yield locate name "Personal" (definition.Documents @ [ name ]) true ]
