namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Text
open System.Threading
open ModConductor.Bethesda
open ModConductor.GameContexts
open ModConductor.Platform

module internal SaveGroups =
    type ObservedGroup =
        { Entry: ProfileSaveGroupEntry
          Save: StoredDataFile
          Companion: StoredDataFile option }

    let private same (left: string) (right: string) =
        left.Equals(right, StringComparison.OrdinalIgnoreCase)

    let private title (scope: ProfileDataScope) =
        match scope.Game.Binding with
        | Some binding when
            not binding.NeedsCheck
            && binding.Evidence.Valid
            && binding.Evidence.DefinitionId = Skyrim.definition.Id
            && binding.Evidence.DefinitionRevision = Skyrim.definition.Revision
            && (match binding.Evidence.Platform, binding.Evidence.Proton, binding.Proton with
                | ContextPlatform.Windows, None, None -> true
                | ContextPlatform.Proton, Some evidence, Some selection ->
                    selection.AppId = Skyrim.definition.SteamAppId && evidence.Selection = selection
                | _ -> false)
            ->
            binding
        | _ ->
            raise (
                ProfileDataException(
                    ProfileDataError.Unavailable
                        "Select and refresh the Skyrim Special Edition Steam context first."
                )
            )

    let private profileRoot scope =
        match scope.Profile with
        | Some profile when profile.SavesInitialized && profile.Saves.IsSome -> profile.Saves.Value
        | _ ->
            raise (
                ProfileDataException(
                    ProfileDataError.Invalid
                        "Enable and initialize local saves for this profile first."
                )
            )

    let private locatedRoot (binding: GameBinding) =
        match binding.Evidence.Locations.Saves with
        | Location.Located(path, true) -> Some(DataLocations.root path)
        | Location.Located(_, false) -> None
        | Location.Unavailable reason ->
            raise (ProfileDataException(ProfileDataError.Unavailable reason))

    let private windowsPath (binding: GameBinding) =
        binding.Evidence.Proton
        |> Option.bind (fun proton ->
            proton.Paths
            |> List.tryFind (fun path ->
                path.Name.Equals("Saves", StringComparison.OrdinalIgnoreCase))
            |> Option.bind _.WindowsPath)

    let private source scope source =
        let binding = title scope

        match source with
        | ProfileSaveSource.Profile ->
            let root = profileRoot scope

            Some root,
            { HostPath = HostPath.value root.Path
              WindowsPath = None }
        | ProfileSaveSource.Global ->
            let root = locatedRoot binding

            root,
            { HostPath =
                match binding.Evidence.Locations.Saves with
                | Location.Located(path, _) -> path
                | Location.Unavailable _ -> ""
              WindowsPath = windowsPath binding }

    let private validCursor =
        function
        | None -> true
        | Some value ->
            not (String.IsNullOrWhiteSpace value)
            && value.IndexOfAny([| '/'; '\\'; '\000' |]) < 0

    let private rows (root: DataRoot) =
        use folder = HeldDirectory.Open(root.Path, root.Identity)
        let names = folder.Names |> Seq.truncate 1000001 |> Seq.toArray

        if names.Length > 1000000 then
            raise (
                ProfileDataException(
                    ProfileDataError.Unavailable "The save folder exceeds one million entries."
                )
            )

        Array.sortInPlaceWith (fun left right -> StringComparer.Ordinal.Compare(left, right)) names

        let matches wanted = names |> Array.filter (same wanted)

        let unique wanted =
            match matches wanted with
            | [| value |] -> Some value, None
            | [||] -> None, None
            | _ -> None, Some "Names that differ only by case cannot be grouped safely."

        let regular wanted =
            match unique wanted with
            | None, problem -> None, problem
            | Some actual, _ ->
                match folder.InspectEntry actual with
                | Some found when found.Kind = EntryKind.RegularFile ->
                    let stream, _ = folder.Read(actual, Some found.Identity)
                    use file = stream
                    Some(actual, file.Length), None
                | _ -> None, Some "The matching save companion is not a regular file."

        [ for name in names do
              let entry = folder.InspectEntry name
              let extension = Path.GetExtension name

              let pairedSkse =
                  extension.Equals(".skse", StringComparison.OrdinalIgnoreCase)
                  && entry |> Option.exists (fun value -> value.Kind = EntryKind.RegularFile)
                  && (regular (Path.GetFileNameWithoutExtension(name) + ".ess") |> fst).IsSome

              if not pairedSkse then
                  match entry with
                  | Some value when value.Kind = EntryKind.Directory ->
                      yield
                          { Id = name
                            Name = name
                            Kind = ProfileSaveEntryKind.Directory
                            Bytes = 0L
                            Companion = None
                            CompanionBytes = 0L
                            Actionable = false
                            Problem = None }
                  | Some value when value.Kind = EntryKind.RegularFile ->
                      let stream, _ = folder.Read(name, Some value.Identity)
                      use file = stream

                      if extension.Equals(".ess", StringComparison.OrdinalIgnoreCase) then
                          let _, ownProblem = unique name

                          let companion, companionProblem =
                              regular (Path.GetFileNameWithoutExtension(name) + ".skse")

                          let problem = ownProblem |> Option.orElse companionProblem

                          yield
                              { Id = name
                                Name = name
                                Kind = ProfileSaveEntryKind.Save
                                Bytes = file.Length
                                Companion = companion |> Option.map fst
                                CompanionBytes =
                                  companion |> Option.map snd |> Option.defaultValue 0L
                                Actionable = problem.IsNone
                                Problem = problem }
                      else
                          yield
                              { Id = name
                                Name = name
                                Kind = ProfileSaveEntryKind.Other
                                Bytes = file.Length
                                Companion = None
                                CompanionBytes = 0L
                                Actionable = false
                                Problem = None }
                  | Some _ ->
                      yield
                          { Id = name
                            Name = name
                            Kind = ProfileSaveEntryKind.Other
                            Bytes = 0L
                            Companion = None
                            CompanionBytes = 0L
                            Actionable = false
                            Problem = Some "This entry type is not supported." }
                  | None -> () ]

    let page scope kind after =
        if not (validCursor after) then
            raise (ProfileDataException(ProfileDataError.Invalid "Choose a current save page."))

        let root, path = source scope kind

        match root with
        | None ->
            { Source = kind
              Path = path
              Entries = []
              Next = None }
        | Some root ->
            let available =
                rows root
                |> List.filter (fun row ->
                    after
                    |> Option.forall (fun previous ->
                        StringComparer.Ordinal.Compare(row.Id, previous) > 0))

            let page = ResizeArray<ProfileSaveGroupEntry>()
            let mutable cost = 0
            let mutable consumed = 0

            for row in available do
                let rowCost =
                    160
                    + Encoding.UTF8.GetByteCount row.Name
                    + (row.Companion
                       |> Option.map Encoding.UTF8.GetByteCount
                       |> Option.defaultValue 0)

                if page.Count < 32 && cost + rowCost <= 240 * 1024 then
                    page.Add row
                    cost <- cost + rowCost
                    consumed <- consumed + 1

            { Source = kind
              Path = path
              Entries = List.ofSeq page
              Next =
                if consumed > 0 && consumed < available.Length then
                    Some available[consumed - 1].Id
                else
                    None }

    let private observe (root: DataRoot) name token =
        use folder = HeldDirectory.Open(root.Path, root.Identity)

        let entry =
            rows root
            |> List.tryFind (fun row -> row.Id = name)
            |> Option.defaultWith (fun () -> raise (ProfileDataException ProfileDataError.NotFound))

        if entry.Kind <> ProfileSaveEntryKind.Save || not entry.Actionable then
            raise (
                ProfileDataException(
                    ProfileDataError.Invalid "Choose an unambiguous Skyrim save first."
                )
            )

        let file =
            DataFiles.observe folder entry.Name token
            |> Option.defaultWith (fun () -> DataFiles.fail (entry.Name + " changed."))

        let save =
            { Root = root
              Name = entry.Name
              File = file }

        let companion =
            entry.Companion
            |> Option.map (fun name ->
                let file =
                    DataFiles.observe folder name token
                    |> Option.defaultWith (fun () -> DataFiles.fail (name + " changed."))

                { Root = root
                  Name = name
                  File = file })

        { Entry = entry
          Save = save
          Companion = companion }

    let private error =
        function
        | SkyrimSaveError.Malformed detail
        | SkyrimSaveError.Unsupported detail
        | SkyrimSaveError.Limit detail -> detail

    let private diagnostics
        (repository: IProfileDataRepository)
        (plugins: PluginSession)
        (scope: ProfileDataScope)
        (headers: Guid option)
        (metadata: SkyrimSaveMetadata)
        =
        task {
            match headers with
            | None -> return [], Some "Refresh plugins to check this save."
            | Some id ->
                try
                    let! order =
                        PluginOrders.read repository plugins scope.WorkspaceId scope.ProfileId id

                    if
                        order.Headers.Stale
                        || not order.Headers.Problems.IsEmpty
                        || order.Pending
                        || order.ExternalChanged
                        || order.Problem.IsSome
                    then
                        return [], Some "Refresh plugins to check this save."
                    else
                        let entries =
                            order.Headers.Entries
                            |> List.filter (fun row -> row.Winner.IsSome && row.Ambiguity.IsNone)

                        let settings = order.View.Order.Entries

                        let issue name : SavePluginIssue option =
                            match entries |> List.tryFind (fun row -> same row.Name name) with
                            | None ->
                                Some(
                                    { Name = name
                                      State = SavePluginState.Missing
                                      Source = None }
                                    : SavePluginIssue
                                )
                            | Some entry ->
                                match settings |> List.tryFind (fun row -> same row.Name name) with
                                | Some setting when setting.Enabled = Some false ->
                                    Some(
                                        { Name = name
                                          State = SavePluginState.Inactive
                                          Source =
                                            entry.Winner
                                            |> Option.map (fun (source: PluginSource) ->
                                                if source.Version = "" then
                                                    source.Name
                                                else
                                                    source.Name + " " + source.Version) }
                                        : SavePluginIssue
                                    )
                                | _ -> None

                        return
                            (metadata.FullPlugins @ metadata.LightPlugins) |> List.choose issue,
                            None
                with ProfileDataException _ ->
                    return [], Some "Refresh plugins to check this save."
        }

    let inspect repository plugins (scope: ProfileDataScope) kind name headers token =
        task {
            let root, path = source scope kind

            let root =
                root
                |> Option.defaultWith (fun () ->
                    raise (ProfileDataException ProfileDataError.NotFound))

            let group = observe root name token
            use folder = HeldDirectory.Open(group.Save.Root.Path, group.Save.Root.Identity)
            let stream, _ = folder.Read(group.Save.Name, Some group.Save.File.Identity)
            use stream = stream

            match SkyrimSaveReader.read stream token with
            | Error problem ->
                return
                    { Source = kind
                      Path = path
                      Entry = group.Entry
                      Metadata = None
                      MetadataProblem = Some(error problem)
                      PluginIssues = []
                      PluginCheckProblem = None }
            | Ok metadata ->
                let! issues, checkProblem = diagnostics repository plugins scope headers metadata

                return
                    { Source = kind
                      Path = path
                      Entry = group.Entry
                      Metadata = Some metadata
                      MetadataProblem = None
                      PluginIssues = issues
                      PluginCheckProblem = checkProblem }
        }

    let prepare
        (previewId: Guid)
        (scope: ProfileDataScope)
        (action: ProfileSaveAction)
        (selected: string list)
        (token: CancellationToken)
        =
        if selected.IsEmpty || selected.Length > 64 then
            raise (
                ProfileDataException(
                    ProfileDataError.Invalid "Choose between 1 and 64 current save groups."
                )
            )

        let unique = Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase)

        if selected |> List.exists (unique.Add >> not) then
            raise (ProfileDataException(ProfileDataError.Invalid "Choose each save once."))

        let sourceKind =
            match action with
            | ProfileSaveAction.CopyToProfile -> ProfileSaveSource.Global
            | ProfileSaveAction.DeleteFromProfile -> ProfileSaveSource.Profile

        let sourceRoot, sourcePath = source scope sourceKind

        let sourceRoot =
            sourceRoot
            |> Option.defaultWith (fun () -> raise (ProfileDataException ProfileDataError.NotFound))

        let targetRoot = profileRoot scope

        if
            action = ProfileSaveAction.CopyToProfile
            && sourceRoot.Identity = targetRoot.Identity
        then
            raise (
                ProfileDataException(
                    ProfileDataError.Invalid "The global and profile save folders are the same."
                )
            )

        let groups = selected |> List.map (fun name -> observe sourceRoot name token)

        let targetNames =
            if action = ProfileSaveAction.CopyToProfile then
                use target = HeldDirectory.Open(targetRoot.Path, targetRoot.Identity)
                target.Names |> Seq.truncate 1000001 |> Seq.toList
            else
                []

        if targetNames.Length > 1000000 then
            raise (
                ProfileDataException(
                    ProfileDataError.Unavailable
                        "The profile save folder exceeds one million entries."
                )
            )

        let collision name = targetNames |> List.exists (same name)

        let files =
            groups
            |> List.collect (fun group ->
                let observed = group.Save :: (group.Companion |> Option.toList)

                if
                    action = ProfileSaveAction.CopyToProfile
                    && observed |> List.exists (fun file -> collision file.Name)
                then
                    raise (
                        ProfileDataException(
                            ProfileDataError.Conflict
                                "A save group with this name is already present in the profile."
                        )
                    )

                let ordered =
                    match action with
                    | ProfileSaveAction.CopyToProfile -> List.rev observed
                    | ProfileSaveAction.DeleteFromProfile -> observed

                ordered
                |> List.map (fun file ->
                    { Target = targetRoot
                      Name = file.Name
                      Before =
                        if action = ProfileSaveAction.DeleteFromProfile then
                            Some file.File
                        else
                            None
                      Source =
                        if action = ProfileSaveAction.CopyToProfile then
                            Some file
                        else
                            None }))

        let binding = title scope

        let destination =
            if action = ProfileSaveAction.CopyToProfile then
                Some
                    { HostPath = HostPath.value targetRoot.Path
                      WindowsPath = None }
            else
                None

        let shownFiles =
            groups
            |> List.collect (fun group -> group.Save :: (group.Companion |> Option.toList))
            |> List.map (fun file ->
                { Name = file.Name
                  Bytes = file.File.Length })

        { PreviewId = previewId
          Action = action
          ContextFingerprint = binding.Evidence.Fingerprint
          Files = files },
        sourcePath,
        destination,
        shownFiles

    let checkReceipt scope (receipt: SaveActionReceipt) token =
        let binding = title scope

        if binding.Evidence.Fingerprint <> receipt.ContextFingerprint then
            raise (ProfileDataException ProfileDataError.Stale)

        let grouped = receipt.Files |> List.groupBy _.Target

        for target, files in grouped do
            use folder = HeldDirectory.Open(target.Path, target.Identity)

            for file in files do
                DataFiles.check folder file.Name file.Before token

                file.Source
                |> Option.iter (fun source ->
                    use sourceRoot = HeldDirectory.Open(source.Root.Path, source.Root.Identity)
                    DataFiles.check sourceRoot source.Name (Some source.File) token)
