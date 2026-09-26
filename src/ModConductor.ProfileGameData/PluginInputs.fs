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
                if declared.Equals("Skyrim.ini", StringComparison.OrdinalIgnoreCase) then
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

            let root =
                if Directory.Exists selected || File.Exists selected then
                    Some(DataLocations.root selected)
                else
                    None

            scope.Context
            |> Option.bind _.PluginRoot
            |> Option.iter (fun previous ->
                if Some previous <> root then
                    DataFiles.fail
                        "The plugin list folder changed. Restore the previous context first.")

            let _, file, bytes =
                match root with
                | Some root -> readFile root fileName token
                | None -> fileName, None, [||]

            let binding = scope.Game.Binding.Value

            let gameRoot =
                { Path = HostPath.create binding.Evidence.RootPath |> Result.defaultWith invalidOp
                  Identity = binding.Evidence.RootIdentity.Value }

            let _, _, ccc = readFile gameRoot "Skyrim.ccc" token

            let installed name =
                headers
                |> List.exists (fun entry ->
                    entry.Name.Equals(name, StringComparison.OrdinalIgnoreCase))

            let creation =
                UTF8Encoding(false, true)
                    .GetString(ccc)
                    .Split([| '\r'; '\n' |], StringSplitOptions.RemoveEmptyEntries)
                |> Array.map _.Trim()
                |> Array.filter installed
                |> Array.toList

            let context = scope.Context

            let! settings =
                match scope.Profile with
                | Some profile when profile.Options.Settings && profile.SettingsInitialized ->
                    match context |> Option.bind _.Applied with
                    | Some active when
                        active.ProfileId = profile.ProfileId && active.Options.Settings
                        ->
                        let documents = DataLocations.documents scope.Game
                        let _, _, bytes = readFile documents "Skyrim.ini" token
                        Ok bytes
                    | _ ->
                        let _, _, bytes = readFile profile.Settings.Value "Skyrim.ini" token
                        Ok bytes
                | _ ->
                    match context with
                    | Some context ->
                        SettingsSource.globalSettings context token
                        |> Result.map (fun files ->
                            files
                            |> List.tryFind (fun (name, _) -> name = "Skyrim.ini")
                            |> Option.bind snd
                            |> Option.defaultValue [||])
                    | None ->
                        match binding.Evidence.Locations.Documents with
                        | Location.Located(path, _) when
                            not (Directory.Exists path || File.Exists path)
                            ->
                            Ok [||]
                        | _ ->
                            let _, _, bytes =
                                readFile (DataLocations.documents scope.Game) "Skyrim.ini" token

                            Ok bytes

            return
                { Root = root
                  Path = selected
                  File = file
                  Bytes = bytes
                  Facts =
                    { Early = OrderRules.baseFiles @ creation
                      DefaultEnabled = OrderRules.baseFiles @ creation
                      Required =
                        (OrderRules.mandatoryFiles
                         |> List.map (fun name -> name, PluginRequirement.Engine))
                        @ (Ini.testFiles settings
                           |> List.map (fun name -> name, PluginRequirement.SkyrimIni))
                      Implicit = OrderRules.mandatoryFiles } }
        }

    let ensureRoot (input: PluginInputs) =
        match input.Root with
        | Some root -> root
        | None ->
            let parent = DataLocations.root (Path.GetDirectoryName input.Path)
            DataLocations.child parent (Path.GetFileName input.Path)
