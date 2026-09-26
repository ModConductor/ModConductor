namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.FilePlanning

type internal ConfigurationPreview =
    { Public: ProfileConfigurationDocument
      Root: DataRoot
      Before: DataFile option
      Bytes: byte array }

module internal ConfigurationFiles =
    let private result = ProfileDataResultFlow.result

    let private declared name =
        match
            Skyrim.definition.IniFiles
            |> List.tryFind (fun value -> value.Equals(name, StringComparison.OrdinalIgnoreCase))
        with
        | Some value -> Ok value
        | None -> Error(ProfileDataError.Invalid "Choose a supported profile settings file.")

    let private settings (scope: ProfileDataScope) =
        match scope.Profile with
        | Some profile when profile.SettingsInitialized && profile.Settings.IsSome ->
            Ok profile.Settings.Value
        | _ ->
            Error(
                ProfileDataError.Unavailable
                    "Turn on local game settings before editing profile files."
            )

    let actualName (held: HeldDirectory) name =
        result {
            let! canonical = declared name

            let matches =
                held.Names
                |> Seq.filter (fun actual ->
                    actual.Equals(canonical, StringComparison.OrdinalIgnoreCase))
                |> Seq.toList

            match matches with
            | [] -> return canonical
            | [ actual ] -> return actual
            | _ -> return DataFiles.fail (canonical + " has more than one matching filename.")
        }

    let private entry (held: HeldDirectory) (token: CancellationToken) name =
        result {
            token.ThrowIfCancellationRequested()
            let! actual = actualName held name
            let file = DataFiles.observe held actual token

            return
                { Name = name
                  Exists = file.IsSome
                  Bytes = file |> Option.map _.Length |> Option.defaultValue 0L }
        }

    let list (scope: ProfileDataScope) (token: CancellationToken) =
        result {
            let! root = settings scope
            use held = HeldDirectory.Open(root.Path, root.Identity)

            return! Skyrim.definition.IniFiles |> ProfileDataResultFlow.traverse (entry held token)
        }

    let read (scope: ProfileDataScope) expected name token =
        result {
            let! root = settings scope
            use held = HeldDirectory.Open(root.Path, root.Identity)
            let! actual = actualName held name
            let before = DataFiles.observe held actual token
            let bytes = DataFiles.readIni held actual before token |> Option.defaultValue [||]

            let! document =
                TextDocuments.editable bytes |> Result.mapError ProfileDataError.Unavailable

            let! canonical = declared name

            let publicValue =
                { PreviewId = Guid.NewGuid()
                  Expected = expected
                  Name = canonical
                  Exists = before.IsSome
                  Length = before |> Option.map _.Length |> Option.defaultValue 0L
                  Sha256 = before |> Option.map _.Sha256
                  Document = document }

            return
                { Public = publicValue
                  Root = root
                  Before = before
                  Bytes = bytes }
        }

    let check (scope: ProfileDataScope) (preview: ConfigurationPreview) token =
        result {
            let! root = settings scope

            if root <> preview.Root then
                return! Error ProfileDataError.Stale

            use held = HeldDirectory.Open(root.Path, root.Identity)
            let! actual = actualName held preview.Public.Name

            if actual <> preview.Public.Name && preview.Before.IsNone then
                DataFiles.fail (preview.Public.Name + " changed.")

            DataFiles.check held actual preview.Before token
        }
