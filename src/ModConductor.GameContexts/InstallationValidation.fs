namespace ModConductor.GameContexts

open System
open System.IO
open System.Security.Cryptography
open ModConductor.Platform

module InstallationValidation =
    let private locations () =
        if OperatingSystem.IsWindows() then
            let locate folder components =
                let root =
                    Environment.GetFolderPath(folder, Environment.SpecialFolderOption.DoNotVerify)

                if String.IsNullOrEmpty root then
                    Location.Unavailable "The Windows user folder is unavailable."
                else
                    let path = Path.Combine(Array.ofList (root :: components))
                    Location.Located(path, Directory.Exists path)

            { Documents =
                locate
                    Environment.SpecialFolder.MyDocuments
                    [ "My Games"; "Skyrim Special Edition" ]
              Saves =
                locate
                    Environment.SpecialFolder.MyDocuments
                    [ "My Games"; "Skyrim Special Edition"; "Saves" ]
              LocalAppData =
                locate Environment.SpecialFolder.LocalApplicationData [ "Skyrim Special Edition" ] }
        else
            let unavailable =
                Location.Unavailable "Save and settings locations require a Proton context."

            { Documents = unavailable
              Saves = unavailable
              LocalAppData = unavailable }

    let inspect candidate =
        let problems = ResizeArray<ValidationProblem>()
        let mutable rootIdentity = None
        let mutable dataIdentity = None
        let mutable dataPath = None
        let mutable executable = None
        let mutable launcher = None

        let problem path detail =
            problems.Add { Path = path; Detail = detail }

        let mutable resolved = candidate

        try
            let root =
                HostPath.create candidate
                |> Result.mapError (fun _ -> "Select an absolute installation folder.")
                |> Result.bind (fun path ->
                    RootSelection.select path
                    |> Result.mapError (fun _ -> "The installation folder is unavailable."))

            match root with
            | Error detail -> problem candidate detail
            | Ok selected ->
                resolved <- RootSelection.path selected |> HostPath.value

                match (RootSelection.facts selected).File with
                | Unknown _ -> problem candidate "The installation folder identity is unavailable."
                | Known identity ->
                    use directory = HeldDirectory.Open(RootSelection.path selected, identity)
                    rootIdentity <- Some directory.Identity
                    let names = directory.Names |> Seq.truncate 4097 |> Seq.toList

                    if names.Length > 4096 then
                        problem
                            candidate
                            "The installation folder contains too many entries to check."
                    else
                        let name expected required =
                            match
                                names
                                |> List.filter (fun name ->
                                    String.Equals(
                                        name,
                                        expected,
                                        StringComparison.OrdinalIgnoreCase
                                    ))
                            with
                            | [ name ] -> Some name
                            | [] ->
                                if required then
                                    problem expected (expected + " was not found in this folder.")

                                None
                            | _ ->
                                problem expected (expected + " has ambiguous names in this folder.")
                                None

                        name Skyrim.definition.Data true
                        |> Option.iter (fun name ->
                            try
                                use data = directory.Directory(name, None)
                                dataIdentity <- Some data.Identity
                                dataPath <- Some(Path.Combine(resolved, name))
                            with :? IOException ->
                                problem name "The Data folder is unavailable or is a link.")

                        name Skyrim.definition.Launcher false
                        |> Option.iter (fun name ->
                            try
                                use file = fst (directory.Read(name, None))
                                launcher <- Some(Path.Combine(resolved, name))
                            with :? IOException ->
                                ())

                        name Skyrim.definition.Executable true
                        |> Option.iter (fun name ->
                            try
                                let stream, identity = directory.Read(name, None)
                                use file = stream
                                let length = file.Length

                                if length > 512L * 1024L * 1024L then
                                    raise (InvalidDataException())

                                let modified = File.GetLastWriteTimeUtc file.SafeFileHandle
                                let version, product = PeVersion.read file
                                file.Position <- 0L
                                let hash = SHA256.HashData file |> Convert.ToHexStringLower

                                if
                                    file.Length <> length
                                    || File.GetLastWriteTimeUtc file.SafeFileHandle <> modified
                                then
                                    problem name "The executable changed during the check."
                                else
                                    use current = fst (directory.Read(name, Some identity))

                                    executable <-
                                        Some
                                            { Path = Path.Combine(resolved, name)
                                              Identity = identity
                                              Length = length
                                              Sha256 = hash
                                              FileVersion = version
                                              ProductVersion = product }
                            with
                            | :? InvalidDataException ->
                                problem
                                    name
                                    "The executable has invalid or unsupported version data."
                            | :? IOException ->
                                problem
                                    name
                                    "The executable is unavailable or changed during the check.")

                        match
                            HostPath.create candidate
                            |> Result.bind (fun path ->
                                RootSelection.select path
                                |> Result.mapError (fun _ -> "unavailable"))
                        with
                        | Ok currentRoot when
                            (RootSelection.facts currentRoot).File = Known identity
                            ->
                            ()
                        | Ok _
                        | Error _ ->
                            problem
                                candidate
                                "The selected installation path changed during the check."

                        use current = HeldDirectory.Open(RootSelection.path selected, identity)

                        if current.Identity <> directory.Identity then
                            problem candidate "The installation folder changed during the check."

                        match dataIdentity with
                        | Some expected ->
                            use currentData =
                                directory.Directory(Path.GetFileName dataPath.Value, Some expected)

                            ()
                        | None -> ()
        with
        | :? UnauthorizedAccessException ->
            problem candidate "The installation folder cannot be read."
        | :? IOException -> problem candidate "The installation folder changed or cannot be read."

        let report =
            { DefinitionId = Skyrim.definition.Id
              DefinitionRevision = Skyrim.definition.Revision
              Platform =
                if OperatingSystem.IsWindows() then
                    ContextPlatform.Windows
                else
                    ContextPlatform.Proton
              RootPath = resolved
              RootIdentity = rootIdentity
              DataPath = dataPath
              DataIdentity = dataIdentity
              Executable = executable
              LauncherPath = launcher
              Locations = locations ()
              Problems = List.ofSeq problems
              CheckedAt =
                DateTimeOffset.FromUnixTimeMilliseconds(
                    DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
                )
              Fingerprint = "" }

        { report with
            Fingerprint = ContextIdentity.fingerprint report }
