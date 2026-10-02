namespace ModConductor.GameContexts

open System
open System.IO
open System.Security.Cryptography
open System.Reflection.PortableExecutable
open ModConductor.Platform

module InstallationValidation =
    let locations (definition: GameDefinition) =
        if not (GameCatalog.isBethesda definition.Id) then
            let unavailable =
                Location.Unavailable
                    "Game saves and global settings are not managed by Mod Conductor."

            { Documents = unavailable
              Saves = unavailable
              LocalAppData = unavailable }
        elif OperatingSystem.IsWindows() then
            let locate folder components =
                let root =
                    Environment.GetFolderPath(folder, Environment.SpecialFolderOption.DoNotVerify)

                if String.IsNullOrEmpty root then
                    Location.Unavailable "The Windows user folder is unavailable."
                else
                    let path = Path.Combine(Array.ofList (root :: components))
                    Location.Located(path, Directory.Exists path)

            { Documents = locate Environment.SpecialFolder.MyDocuments definition.Documents
              Saves =
                if definition.Id = GameId.OblivionRemasteredSteam then
                    let home = Environment.GetFolderPath Environment.SpecialFolder.UserProfile

                    let path =
                        (Path.Combine(home, "Documents"), definition.Saves)
                        ||> List.fold (fun parent name -> Path.Combine(parent, name))

                    Location.Located(path, Directory.Exists path)
                else
                    locate Environment.SpecialFolder.MyDocuments definition.Saves
              LocalAppData =
                locate Environment.SpecialFolder.LocalApplicationData definition.LocalAppData }
        else
            let unavailable =
                Location.Unavailable "Select a runtime to locate saves and settings."

            { Documents = unavailable
              Saves = unavailable
              LocalAppData = unavailable }

    let private dataLocation (root: HeldDirectory) rootPath (relative: string) =
        let rec descend (parent: HeldDirectory) path =
            function
            | [] -> path, parent.Identity
            | expected :: rest ->
                let actual =
                    parent.Names
                    |> Seq.filter (fun name ->
                        name.Equals(expected, StringComparison.OrdinalIgnoreCase))
                    |> Seq.toList

                match actual with
                | [ name ] ->
                    use child = parent.Directory(name, None)
                    descend child (Path.Combine(path, name)) rest
                | _ -> raise (IOException(relative + " was not found or has ambiguous names."))

        relative.Split([| '/'; '\\' |], StringSplitOptions.RemoveEmptyEntries)
        |> Array.toList
        |> descend root rootPath

    let inspect (definition: GameDefinition) candidate =
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

                        try
                            let found, identity = dataLocation directory resolved definition.Data
                            dataIdentity <- Some identity
                            dataPath <- Some found
                        with :? IOException ->
                            problem
                                definition.Data
                                "The content folder is unavailable or is a link."

                        name definition.Launcher false
                        |> Option.iter (fun name ->
                            try
                                use file = fst (directory.Read(name, None))
                                launcher <- Some(Path.Combine(resolved, name))
                            with :? IOException ->
                                ())

                        let client = GameClient.executable (OperatingSystem.IsLinux()) definition

                        Some client
                        |> Option.iter (fun name ->
                            try
                                match InstallationPaths.read directory name None with
                                | Error detail -> problem name detail
                                | Ok(stream, identity, actual) ->
                                    use file = stream
                                    let length = file.Length

                                    if length > 512L * 1024L * 1024L then
                                        raise (InvalidDataException())

                                    let modified = File.GetLastWriteTimeUtc file.SafeFileHandle

                                    let version, product =
                                        match GameClient.mono definition with
                                        | Some client ->
                                            match
                                                UnityMonoValidation.inspect
                                                    definition
                                                    client
                                                    resolved
                                                    file
                                                    (OperatingSystem.IsLinux())
                                            with
                                            | Ok unity -> unity, unity
                                            | Error detail ->
                                                problem name detail
                                                "", ""
                                        | None when (GameClient.unreal definition).IsSome ->
                                            use pe = new PEReader(file, PEStreamOptions.LeaveOpen)

                                            if
                                                pe.PEHeaders.CoffHeader.Machine <> Machine.Amd64
                                            then
                                                problem
                                                    name
                                                    "Select the Windows x64 Unreal client."

                                            "", ""
                                        | None -> PeVersion.read file

                                    file.Position <- 0L
                                    let hash = SHA256.HashData file |> Convert.ToHexStringLower

                                    if
                                        file.Length <> length
                                        || File.GetLastWriteTimeUtc file.SafeFileHandle <> modified
                                    then
                                        problem name "The executable changed during the check."
                                    else
                                        match
                                            InstallationPaths.read directory name (Some identity)
                                        with
                                        | Error detail -> problem name detail
                                        | Ok(current, _, _) ->
                                            use current = current

                                            executable <-
                                                Some
                                                    { Path = Path.Combine(resolved, actual)
                                                      Identity = identity
                                                      Length = length
                                                      Sha256 = hash
                                                      FileVersion = version
                                                      ProductVersion = product }
                            with
                            | :? BadImageFormatException ->
                                problem name "The game executable has an unsupported format."
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
                            let _, actual = dataLocation directory resolved definition.Data

                            if actual <> expected then
                                problem
                                    definition.Data
                                    "The content folder changed during the check."

                            ()
                        | None -> ()
        with
        | :? UnauthorizedAccessException ->
            problem candidate "The installation folder cannot be read."
        | :? IOException -> problem candidate "The installation folder changed or cannot be read."

        let report =
            { DefinitionId = definition.Id
              DefinitionRevision = definition.Revision
              Platform =
                if OperatingSystem.IsWindows() then
                    ContextPlatform.Windows
                elif (GameClient.mono definition).IsSome then
                    ContextPlatform.NativeLinux
                elif definition.SteamAppId <> 0u then
                    ContextPlatform.Proton
                else
                    ContextPlatform.Wine
              RootPath = resolved
              RootIdentity = rootIdentity
              DataPath = dataPath
              DataIdentity = dataIdentity
              Executable = executable
              LauncherPath = launcher
              Proton = None
              Wine = None
              Locations =
                locations (
                    GameCatalog.forRuntime
                        definition.Id
                        (executable |> Option.map _.FileVersion |> Option.defaultValue "")
                )
              Problems = List.ofSeq problems
              CheckedAt =
                DateTimeOffset.FromUnixTimeMilliseconds(
                    DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
                )
              Fingerprint = "" }

        let report =
            { report with
                Locations = GameLocations.apply definition.Id resolved report.Locations }

        { report with
            Fingerprint = ContextIdentity.fingerprint report }
