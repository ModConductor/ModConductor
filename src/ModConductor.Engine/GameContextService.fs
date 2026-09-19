namespace ModConductor.Engine

open ModConductor.GameContexts
open ModConductor.Protocol.V1

module private GameContextWire =
    let platform =
        function
        | ContextPlatform.Windows -> GameContextPlatform.Windows
        | ContextPlatform.Proton -> GameContextPlatform.Proton

    let location =
        function
        | Location.Located(path, exists) ->
            GameLocation(Located = LocatedGameFolder(Path = path, Exists = exists))
        | Location.Unavailable reason -> GameLocation(UnavailableReason = reason)

    let evidence (value: InstallationEvidence) =
        let result =
            GameInstallationEvidence(
                DefinitionId = value.DefinitionId,
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
                let context = GameCapabilityContext(DefinitionId = supported.DefinitionId)
                context.Platforms.AddRange(supported.Platforms |> Seq.map platform)
                context)
        )

        result

    let reply =
        function
        | Ok(value: ModConductor.GameContexts.GameContextState) ->
            let d = Skyrim.definition

            let state =
                ModConductor.Protocol.V1.GameContextState(
                    WorkspaceId = value.WorkspaceId.ToString("N"),
                    Revision = uint64 value.Revision,
                    Definition =
                        GameDefinitionInfo(
                            DefinitionId = d.Id,
                            Revision = uint32 d.Revision,
                            Name = d.Name,
                            Storefront = d.Storefront,
                            DeclaredSteamAppId = d.SteamAppId
                        )
                )

            let capabilities = CapabilityPolicy.forUsers d.Id
            state.Definition.Capabilities.AddRange(capabilities |> Seq.map capability)

            state.Definition.UnavailableCapabilities.AddRange(
                capabilities
                |> Seq.choose (fun item ->
                    match item.Disposition with
                    | CapabilityDisposition.Available -> None
                    | CapabilityDisposition.Unavailable reason
                    | CapabilityDisposition.Unsupported reason ->
                        Some(UnavailableGameCapability(Name = item.Name, Reason = reason)))
            )

            value.Binding
            |> Option.iter (fun b ->
                let binding =
                    GameBindingInfo(
                        BindingId = b.Id.ToString("N"),
                        Path = b.Path,
                        Evidence = evidence b.Evidence,
                        NeedsCheck = b.NeedsCheck
                    )

                b.Proton |> Option.iter (fun p -> binding.Proton <- ProtonWire.selection p)
                b.Failure |> Option.iter (fun failure -> binding.Failure <- failure)
                state.Binding <- binding)

            GameContextReply(State = state)
        | Error error ->
            let code, detail =
                match error with
                | ContextError.NotFound ->
                    GameContextFaultCode.GameContextFaultNotFound,
                    "The workspace installation was not found."
                | ContextError.StaleRevision ->
                    GameContextFaultCode.GameContextFaultStaleRevision,
                    "The workspace installation changed. Your folder was not saved."
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
            let! result = contexts.Read(ModLibraryWire.id request.WorkspaceId)
            return GameContextWire.reply result
        }

    override _.SaveGameContext(request, _) =
        task {
            if request.Path.Length > 4096 then
                ModLibraryWire.reject "The installation path is too long."

            let! result =
                contexts.Save(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.number request.ExpectedRevision,
                    { Path = request.Path
                      Proton = ProtonWire.readSelection request.Proton }
                )

            return GameContextWire.reply result
        }

    override _.RefreshGameContext(request, _) =
        task {
            let! result =
                contexts.Refresh(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.number request.ExpectedRevision
                )

            return GameContextWire.reply result
        }
