namespace ModConductor.Engine

open System
open ModConductor.GameContexts
open ModConductor.Protocol.V1

module internal GameContextWire =
    let platform =
        function
        | ContextPlatform.Windows -> GameContextPlatform.Windows
        | ContextPlatform.Proton -> GameContextPlatform.Proton
        | ContextPlatform.Wine -> GameContextPlatform.Wine
        | ContextPlatform.NativeLinux -> GameContextPlatform.NativeLinux

    let wineSelection (value: WineSelection) =
        WineSelectionInfo(Executable = value.Executable, Prefix = value.Prefix)

    let location =
        function
        | Location.Located(path, exists) ->
            GameLocation(Located = LocatedGameFolder(Path = path, Exists = exists))
        | Location.Unavailable reason -> GameLocation(UnavailableReason = reason)

    let evidence (value: InstallationEvidence) =
        let result =
            GameInstallationEvidence(
                DefinitionId = GameId.value value.DefinitionId,
                DefinitionRevision = uint32 value.DefinitionRevision,
                Platform = platform value.Platform,
                RootPath = value.RootPath,
                Documents = location value.Locations.Documents,
                Saves = location value.Locations.Saves,
                LocalAppData = location value.Locations.LocalAppData,
                CheckedAtUnixMs = value.CheckedAt.ToUnixTimeMilliseconds(),
                Fingerprint = value.Fingerprint
            )

        value.Proton |> Option.iter (fun p -> result.Proton <- ProtonWire.evidence p)

        value.Wine
        |> Option.iter (fun wine ->
            result.Wine <- WineContextEvidence(Selection = wineSelection wine.Selection))

        value.DataPath |> Option.iter (fun path -> result.DataPath <- path)
        value.LauncherPath |> Option.iter (fun path -> result.LauncherPath <- path)

        value.Executable
        |> Option.iter (fun e ->
            result.Executable <-
                GameExecutableEvidence(
                    Path = e.Path,
                    Sha256 = e.Sha256,
                    Length = uint64 e.Length,
                    FileVersion = e.FileVersion,
                    ProductVersion = e.ProductVersion
                ))

        result.Problems.AddRange(
            value.Problems
            |> Seq.map (fun p -> GameValidationProblem(Path = p.Path, Detail = p.Detail))
        )

        result

    let capability (value: CompiledCapability) =
        let kind =
            match value.Kind with
            | CapabilityKind.CoreOutcome -> GameCapabilityKind.CoreOutcome
            | CapabilityKind.GameAdapter -> GameCapabilityKind.GameAdapter
            | CapabilityKind.OptionalLegacy -> GameCapabilityKind.OptionalLegacy
            | CapabilityKind.ObsoleteMechanism -> GameCapabilityKind.ObsoleteMechanism

        let disposition, reason =
            match value.Disposition with
            | CapabilityDisposition.Available -> GameCapabilityDisposition.Available, None
            | CapabilityDisposition.Unavailable reason ->
                GameCapabilityDisposition.Unavailable, Some reason
            | CapabilityDisposition.Unsupported reason ->
                GameCapabilityDisposition.Unsupported, Some reason

        let result =
            GameCapabilityInfo(
                CapabilityId = CapabilityId.value value.Id,
                Revision = uint32 value.Revision,
                Name = value.Name,
                Kind = kind,
                Disposition = disposition
            )

        reason |> Option.iter (fun text -> result.Reason <- text)

        result.Contexts.AddRange(
            value.Contexts
            |> Seq.map (fun supported ->
                let context =
                    GameCapabilityContext(DefinitionId = GameId.value supported.DefinitionId)

                context.Platforms.AddRange(supported.Platforms |> Seq.map platform)
                context)
        )

        result

    let definition (d: GameDefinition) =
        let rules =
            if d.Client = GameClient.Bethesda then
                Some(GameCatalog.rules d.Id)
            else
                None

        let artworkApp =
            if d.SteamAppId <> 0u then
                d.SteamAppId
            elif
                (match d.Id with
                 | GameId.Custom _ -> true
                 | _ -> false)
            then
                0u
            else
                GameCatalog.definitions
                |> List.tryFind (fun row -> row.Name = d.Name && row.SteamAppId <> 0u)
                |> Option.map _.SteamAppId
                |> Option.defaultValue 0u

        let result =
            GameDefinitionInfo(
                DefinitionId = GameId.value d.Id,
                Revision = uint32 d.Revision,
                Name = d.Name,
                Storefront = d.Storefront,
                ThunderstoreCommunity = GameClient.community d,
                DeclaredSteamAppId = d.SteamAppId,
                ArtworkUrl =
                    (if
                         artworkApp = 0u
                         || List.contains
                             d.Id
                             [ GameId.TaleOfTwoWastelandsSteam
                               GameId.NehrimSteam
                               GameId.FalloutLondonSteam ]
                     then
                         ""
                     else
                         "https://cdn.cloudflare.steamstatic.com/steam/apps/"
                         + string artworkApp
                         + "/header.jpg"),
                SettingsIni = (rules |> Option.map _.Ini |> Option.defaultValue ""),
                PluginOrdering =
                    (rules |> Option.map (fun row -> string row.Ordering) |> Option.defaultValue ""),
                SaveExtension = (rules |> Option.bind _.SaveExtension |> Option.defaultValue ""),
                ExtenderName = (rules |> Option.bind _.ExtenderName |> Option.defaultValue ""),
                ExtenderLoader = (rules |> Option.bind _.ExtenderLoader |> Option.defaultValue ""),
                SupportsLightPlugins = (rules |> Option.exists _.SupportsLight),
                SupportsMediumPlugins = (rules |> Option.exists _.SupportsMedium),
                ArchiveInvalidation =
                    (rules
                     |> Option.exists (fun row ->
                         row.Invalidation.IsSome || row.LooseFilesInvalidation))
            )

        let capabilities = CapabilityPolicy.forDeclaration d
        result.Capabilities.AddRange(capabilities |> Seq.map capability)

        result.UnavailableCapabilities.AddRange(
            capabilities
            |> Seq.choose (fun item ->
                match item.Disposition with
                | CapabilityDisposition.Available -> None
                | CapabilityDisposition.Unavailable reason
                | CapabilityDisposition.Unsupported reason ->
                    Some(UnavailableGameCapability(Name = item.Name, Reason = reason)))
        )

        result

    let reply =
        function
        | Ok(value: ModConductor.GameContexts.GameContextState) ->
            let state =
                ModConductor.Protocol.V1.GameContextState(
                    WorkspaceId = value.WorkspaceId.ToString("N"),
                    ProfileId = value.ProfileId.ToString("N"),
                    Revision = uint64 value.Revision
                )

            value.Binding
            |> Option.iter (fun b ->
                let d = GameCatalog.forGame b.GameId

                state.Definition <- definition d

                let binding =
                    GameBindingInfo(
                        BindingId = b.Id.ToString("N"),
                        Path = b.Path,
                        Evidence = evidence b.Evidence,
                        NeedsCheck = b.NeedsCheck
                    )

                b.Proton |> Option.iter (fun p -> binding.Proton <- ProtonWire.selection p)
                b.Wine |> Option.iter (fun wine -> binding.Wine <- wineSelection wine)
                b.Failure |> Option.iter (fun failure -> binding.Failure <- failure)
                state.Binding <- binding)

            GameContextReply(State = state)
        | Error error ->
            let code, detail =
                match error with
                | ContextError.NotFound ->
                    GameContextFaultCode.GameContextFaultNotFound, "The profile was not found."
                | ContextError.StaleRevision ->
                    GameContextFaultCode.GameContextFaultStaleRevision,
                    "The profile installation changed. The folder was not saved."
                | ContextError.WorkspaceUnavailable ->
                    GameContextFaultCode.GameContextFaultWorkspaceUnavailable,
                    "The workspace needs a check before its installation can change."
                | ContextError.Invalid _ ->
                    GameContextFaultCode.GameContextFaultInvalidInstallation,
                    "The installation folder could not be validated."
                | ContextError.Busy ->
                    GameContextFaultCode.GameContextFaultBusy,
                    "An installation check is still in progress. Try again."

            let fault = GameContextFault(Code = code, Detail = detail)

            match error with
            | ContextError.Invalid report -> fault.Candidate <- evidence report
            | ContextError.NotFound
            | ContextError.StaleRevision
            | ContextError.WorkspaceUnavailable
            | ContextError.Busy -> ()

            GameContextReply(Fault = fault)

type GameContextService(contexts: IGameContexts) =
    inherit GameContextOperations.GameContextOperationsBase()

    override _.ReadGameContext(request, _) =
        task {
            let! result =
                contexts.Read(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId
                )

            return GameContextWire.reply result
        }

    override _.SaveGameContext(request, _) =
        task {
            if request.Path.Length > 4096 then
                ModLibraryWire.reject "The installation path is too long."

            let! result =
                let game =
                    GameCatalog.tryParse request.GameId
                    |> Option.defaultWith (fun () -> ModLibraryWire.reject "Select a known game.")

                contexts.Save(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId,
                    ModLibraryWire.number request.ExpectedRevision,
                    { GameId = game
                      Path = request.Path
                      Proton = ProtonWire.readSelection request.Proton
                      Wine =
                        if isNull request.Wine then
                            None
                        else
                            let path (value: string) =
                                if value <> "" && not (IO.Path.IsPathFullyQualified value) then
                                    ModLibraryWire.reject "Select an absolute Wine path."

                                value

                            Some
                                { Executable = path request.Wine.Executable
                                  Prefix = path request.Wine.Prefix } }
                )

            return GameContextWire.reply result
        }

    override _.RefreshGameContext(request, _) =
        task {
            let! result =
                contexts.Refresh(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId,
                    ModLibraryWire.number request.ExpectedRevision
                )

            return GameContextWire.reply result
        }
