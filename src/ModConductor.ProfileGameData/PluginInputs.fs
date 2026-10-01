namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Security.Cryptography
open System.Text
open System.Threading
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.Bethesda

type internal PluginInputs =
    { Root: DataRoot option
      Path: string
      File: StoredDataFile option
      Bytes: byte array
      LoadOrder: byte array
      Ordering: PluginOrdering
      Activation: PluginActivation
      TestOverride: bool
      Facts: PluginOrderFacts }

module internal PluginInputs =
    let fileName = "Plugins.txt"

    let private name (root: HeldDirectory) declared =
        match
            root.Names
            |> Seq.filter (fun value ->
                String.Equals(value, declared, StringComparison.OrdinalIgnoreCase))
            |> Seq.toList
        with
        | [] -> declared
        | [ actual ] -> actual
        | _ -> DataFiles.fail (declared + " has more than one matching filename.")

    let readFile (root: DataRoot) declared (token: CancellationToken) =
        use held = HeldDirectory.Open(root.Path, root.Identity)
        let actual = name held declared

        match held.InspectEntry actual with
        | None -> actual, None, [||]
        | Some entry when entry.Kind = EntryKind.RegularFile ->
            let stream, identity = held.Read(actual, Some entry.Identity)
            use stream = stream

            let maximum =
                if declared.EndsWith(".ini", StringComparison.OrdinalIgnoreCase) then
                    16 * OrderDocument.maxBytes
                else
                    OrderDocument.maxBytes

            if stream.Length > int64 maximum then
                raise (IOException(declared + " exceeds the read limit."))

            let bytes = Array.zeroCreate<byte> (int stream.Length)
            stream.ReadExactly(bytes.AsSpan())
            token.ThrowIfCancellationRequested()

            let file =
                { Root = root
                  Name = actual
                  File =
                    { Identity = identity
                      Length = bytes.LongLength
                      Sha256 = Convert.ToHexString(SHA256.HashData bytes).ToLowerInvariant() } }

            actual, Some file, bytes
        | Some _ -> DataFiles.fail (declared + " is not a regular file.")

    let creationFile (game: GameContextState) token =
        let binding = game.Binding.Value
        let rules = GameCatalog.rules binding.GameId

        let installation =
            { Path = HostPath.create binding.Evidence.RootPath |> Result.defaultWith invalidOp
              Identity = binding.Evidence.RootIdentity.Value }

        match rules.CreationFile with
        | None -> [||]
        | Some name ->
            let primary =
                if binding.GameId <> GameId.StarfieldSteam then
                    None
                else
                    match binding.Evidence.Locations.Documents with
                    | Location.Located(path, _) when Directory.Exists path ->
                        let root =
                            DataLocations.root path
                            |> Result.defaultWith (ProfileDataException >> raise)

                        let _, file, bytes = readFile root name token
                        file |> Option.map (fun _ -> bytes)
                    | _ -> None

            primary
            |> Option.defaultWith (fun () ->
                let _, _, bytes = readFile installation name token in bytes)

    let private location (game: GameContextState) =
        match game.Binding with
        | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
            match binding.Evidence.Locations.LocalAppData with
            | Location.Located(path, _) -> Ok path
            | Location.Unavailable reason -> Error(ProfileDataError.Unavailable reason)
        | _ -> Error(ProfileDataError.Unavailable "Select and refresh the game installation first.")

    let read (scope: ProfileDataScope) (headers: PluginEntry list) token =
        ProfileDataResultFlow.result {
            let! selected = location scope.Game

            let! root =
                if Directory.Exists selected || File.Exists selected then
                    DataLocations.root selected |> Result.map Some
                else
                    Ok None

            scope.Context
            |> Option.bind _.PluginRoot
            |> Option.iter (fun previous ->
                if Some previous <> root then
                    DataFiles.fail
                        "The plugin list folder changed. Restore the previous context first.")

            let binding = scope.Game.Binding.Value

            let rules =
                GameCatalog.runtimeRules
                    binding.GameId
                    binding.Evidence.Executable.Value.FileVersion

            let pluginFile =
                if rules.Activation = PluginActivation.MorrowindIni then
                    rules.Ini
                else
                    fileName

            let _, file, bytes =
                match root with
                | Some root -> readFile root pluginFile token
                | None -> pluginFile, None, [||]

            let _, _, loadOrder =
                match root, rules.Activation with
                | Some root, PluginActivation.Plain -> readFile root "loadorder.txt" token
                | _ -> "loadorder.txt", None, [||]

            let ccc = creationFile scope.Game token

            let installed name =
                headers
                |> List.exists (fun entry ->
                    entry.Name.Equals(name, StringComparison.OrdinalIgnoreCase))

            let creation =
                UTF8Encoding(false, true)
                    .GetString(ccc)
                    .Split([| '\r'; '\n' |], StringSplitOptions.RemoveEmptyEntries)
                |> Array.map _.Trim()
                |> Array.filter (fun name -> not (name.StartsWith "#"))
                |> Array.filter installed
                |> Array.toList

            let context = scope.Context

            let settingsFile =
                if rules.TestFilesOverride then
                    (GameCatalog.forGame binding.GameId).IniFiles
                    |> List.find (fun name ->
                        name.EndsWith("Custom.ini", StringComparison.OrdinalIgnoreCase))
                else
                    rules.Ini

            let documentSettings () =
                DataLocations.documents scope.Game
                |> Result.map (fun documents ->
                    let _, _, bytes = readFile documents settingsFile token
                    bytes)

            let! settings =
                match scope.Profile with
                | Some profile when profile.Options.Settings && profile.SettingsInitialized ->
                    match context |> Option.bind _.Applied with
                    | Some active when
                        active.ProfileId = profile.ProfileId && active.Options.Settings
                        ->
                        documentSettings ()
                    | _ ->
                        let _, _, bytes = readFile profile.Settings.Value settingsFile token
                        Ok bytes
                | _ ->
                    match context with
                    | Some context ->
                        SettingsSource.globalSettings scope.Game context token
                        |> Result.map (fun files ->
                            files
                            |> List.tryFind (fun (name, _) -> name = settingsFile)
                            |> Option.bind snd
                            |> Option.defaultValue [||])
                    | None ->
                        match binding.Evidence.Locations.Documents with
                        | Location.Located(path, _) when
                            not (Directory.Exists path || File.Exists path)
                            ->
                            Ok [||]
                        | _ -> documentSettings ()

            let tests = Ini.testFiles settings
            let overriding = rules.TestFilesOverride && not tests.IsEmpty
            let creation = if overriding then [] else creation

            let enforced =
                if
                    binding.GameId = GameId.StarfieldSteam
                    || binding.GameId = GameId.OblivionRemasteredSteam
                then
                    (rules.Official |> List.filter installed) @ creation
                else
                    []

            return
                { Root = root
                  Path = selected
                  File = file
                  Bytes =
                    if overriding then
                        Encoding.UTF8.GetBytes(String.concat "\r\n" (tests |> List.map ((+) "*")))
                    else
                        bytes
                  LoadOrder = loadOrder
                  Ordering = rules.Ordering
                  Activation = rules.Activation
                  TestOverride = overriding
                  Facts =
                    { Early = rules.Official @ creation
                      DefaultEnabled = rules.Official @ creation
                      Required =
                        ((rules.Primary @ enforced |> List.distinctBy _.ToUpperInvariant())
                         |> List.map (fun name -> name, PluginRequirement.Engine))
                        @ (tests |> List.map (fun name -> name, PluginRequirement.SkyrimIni))
                      Implicit =
                        rules.Implicit
                        @ (if binding.GameId = GameId.StarfieldSteam then
                               creation
                           else
                               []) } }
        }

    let ensureRoot (input: PluginInputs) =
        match input.Root with
        | Some root -> Ok root
        | None ->
            DataLocations.root (Path.GetDirectoryName input.Path)
            |> Result.map (fun parent -> DataLocations.child parent (Path.GetFileName input.Path))
