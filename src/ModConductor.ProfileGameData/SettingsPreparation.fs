namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Platform
open ModConductor.GameContexts

module internal SettingsPreparation =
    let private readStored (file: StoredDataFile) token =
        use root = HeldDirectory.Open(file.Root.Path, file.Root.Identity)
        DataFiles.readIni root file.Name (Some file.File) token

    let private settingsRoot (profile: PrivateProfileData) =
        profile.Settings
        |> Option.defaultWith (fun () ->
            raise (
                ProfileDataException(
                    ProfileDataError.Unavailable "The profile settings folder is not initialized."
                )
            ))

    let globalSettings (context: ProfileDataContext) token =
        use documents =
            HeldDirectory.Open(context.Documents.Path, context.Documents.Identity)

        let originals = context.Applied |> Option.map _.Originals |> Option.defaultValue []

        DataLocations.iniNames documents
        |> List.map (fun (declared, actual) ->
            let bytes =
                match
                    originals
                    |> List.tryFind (fun value ->
                        value.Name.Equals(actual, StringComparison.OrdinalIgnoreCase))
                with
                | Some original when context.Applied.Value.Options.Settings ->
                    original.Original |> Option.bind (fun file -> readStored file token)
                | _ ->
                    let observed = DataFiles.observe documents actual token
                    let current = DataFiles.readIni documents actual observed token

                    match context.Applied |> Option.bind _.SaveOverride, current with
                    | Some patch, Some bytes when declared = "Skyrim.ini" -> Ini.remove patch bytes
                    | _ -> current

            declared, bytes)

    let prepare
        (context: ProfileDataContext)
        (incoming: PrivateProfileData option)
        (outgoing: PrivateProfileData option)
        (workspaceStage: DataRoot)
        (documentsStage: DataRoot)
        (token: CancellationToken)
        =
        use documents =
            HeldDirectory.Open(context.Documents.Path, context.Documents.Identity)

        use staging = HeldDirectory.Open(documentsStage.Path, documentsStage.Identity)

        use privateStaging =
            HeldDirectory.Open(workspaceStage.Path, workspaceStage.Identity)

        let effects = ResizeArray<ProfileDataFilesEffect>()
        let originals = ResizeArray<GlobalIni>()
        let old = context.Applied

        let nextOptions =
            incoming
            |> Option.map _.Options
            |> Option.defaultValue { Settings = false; Saves = false }

        let mutable nextPatch = None

        let nextSettings =
            incoming
            |> Option.filter (fun _ -> nextOptions.Settings)
            |> Option.map settingsRoot

        for declared, actual in DataLocations.iniNames documents do
            token.ThrowIfCancellationRequested()
            let before = DataFiles.observe documents actual token
            let current = DataFiles.readIni documents actual before token

            let canonical =
                match old |> Option.bind _.SaveOverride, current with
                | Some patch, Some bytes when declared = "Skyrim.ini" -> Ini.remove patch bytes
                | _ -> current

            match old, outgoing with
            | Some active, Some profile when active.Options.Settings ->
                let root = settingsRoot profile
                use privateFiles = HeldDirectory.Open(root.Path, root.Identity)

                let replacement =
                    canonical
                    |> Option.map (fun bytes ->
                        let name = "capture-" + declared

                        { Root = workspaceStage
                          Name = name
                          File = DataFiles.stage privateStaging name bytes token })

                effects.Add
                    { Target = root
                      Backups = workspaceStage
                      Change =
                        { Name = declared
                          Before = DataFiles.observe privateFiles declared token
                          Replacement = replacement
                          BackupName = "previous-" + declared } }
            | _ -> ()

            let previousOriginal =
                old
                |> Option.bind (fun value ->
                    value.Originals
                    |> List.tryFind (fun file ->
                        file.Name.Equals(actual, StringComparison.OrdinalIgnoreCase)))

            let originalBytes =
                previousOriginal
                |> Option.bind _.Original
                |> Option.bind (fun value -> readStored value token)

            let globalBytes =
                if old |> Option.exists (fun value -> value.Options.Settings) then
                    originalBytes
                else
                    canonical

            let incomingBytes =
                match nextSettings with
                | Some _ when
                    old
                    |> Option.exists (fun value ->
                        incoming.Value.ProfileId = value.ProfileId && value.Options.Settings)
                    ->
                    canonical
                | Some root ->
                    use privateFiles = HeldDirectory.Open(root.Path, root.Identity)
                    let observed = DataFiles.observe privateFiles declared token
                    DataFiles.readIni privateFiles declared observed token
                | None -> globalBytes

            let desired =
                if nextOptions.Saves && declared = "Skyrim.ini" then
                    let bytes, patch = Ini.apply (DataEffects.linkName context + "\\") incomingBytes
                    nextPatch <- Some patch
                    Some bytes
                else
                    incomingBytes

            let wasManaged =
                old
                |> Option.exists (fun value ->
                    value.Options.Settings || (value.Options.Saves && declared = "Skyrim.ini"))

            let managed = nextOptions.Settings || (nextOptions.Saves && declared = "Skyrim.ini")

            if wasManaged || managed then
                let original =
                    match previousOriginal with
                    | Some original when originalBytes = globalBytes -> original
                    | Some _ ->
                        { Name = actual
                          Original =
                            globalBytes
                            |> Option.map (fun bytes ->
                                let name = "global-" + declared

                                { Root = documentsStage
                                  Name = name
                                  File = DataFiles.stage staging name bytes token }) }
                    | None ->
                        { Name = actual
                          Original =
                            before
                            |> Option.map (fun file ->
                                { Root = documentsStage
                                  Name = "before-" + declared
                                  File = file }) }

                if managed then
                    originals.Add original

                let replacement =
                    if not managed && desired = globalBytes then
                        original.Original
                    else
                        desired
                        |> Option.map (fun bytes ->
                            let name = "apply-" + declared

                            { Root = documentsStage
                              Name = name
                              File = DataFiles.stage staging name bytes token })

                effects.Add
                    { Target = context.Documents
                      Backups = documentsStage
                      Change =
                        { Name = actual
                          Before = before
                          Replacement = replacement
                          BackupName = "before-" + declared } }

        let proposed =
            incoming
            |> Option.filter (fun _ ->
                nextOptions.Settings || nextOptions.Saves || incoming.Value.PluginOrder.IsSome)
            |> Option.map (fun profile ->
                { ProfileId = profile.ProfileId
                  Options = nextOptions
                  Originals = List.ofSeq originals
                  SaveOverride = nextPatch
                  SaveLink = None
                  Plugins = None })

        let previousLink = old |> Option.bind _.SaveLink

        let target =
            incoming |> Option.filter (fun _ -> nextOptions.Saves) |> Option.bind _.Saves

        let link =
            match previousLink, target with
            | None, None -> SaveLinkEffect.Unchanged
            | Some previous, None -> SaveLinkEffect.Remove previous
            | None, Some target -> SaveLinkEffect.Create target
            | Some previous, Some target -> SaveLinkEffect.Replace(previous, target)

        List.ofSeq effects, link, proposed
