namespace ModConductor.FilePlanning

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module CandidateFiles =
    let private observe
        (evidence: ModConductor.GameContexts.InstallationEvidence)
        (projection: GameProjection)
        predicate
        limit
        (token: CancellationToken)
        =
        let path =
            evidence.DataPath
            |> Option.bind (HostPath.create >> Result.toOption)
            |> Option.get

        let identity = evidence.DataIdentity |> Option.get
        use root = HeldDirectory.Open(path, identity)

        let links =
            projection.Links |> List.map (fun link -> link.Path, link.Entry) |> Map.ofList

        let found = ResizeArray<ObservedCandidate>()

        let add target source =
            if found.Count >= limit then
                raise (ScanLimitException "The plugin scan exceeds its candidate limit.")

            found.Add { Target = target; Source = source }

        for name in root.Names do
            token.ThrowIfCancellationRequested()

            match LogicalPath.create [ name ] with
            | Error _ -> ()
            | Ok logical when predicate logical && not (links.ContainsKey logical) ->
                match root.InspectEntry name with
                | None -> raise (IOException "A plugin file disappeared during the scan.")
                | Some entry ->
                    add
                        logical
                        { Root = path
                          RootIdentity = identity
                          Path = logical
                          Identity = entry.Identity }
            | Ok _ -> ()

        for KeyValue(logical, original) in projection.Originals do
            if predicate logical then
                add logical original

        List.ofSeq found

    let acquire (repository: IFileCandidateRepository) profile predicate limit token =
        task {
            let! loaded = repository.Read profile

            match loaded with
            | Error error -> return Error error
            | Ok sources ->
                match PlanSnapshot.context sources with
                | Error error -> return Error error
                | Ok evidence ->
                    let! projected = repository.CandidateProjection(sources.Stamp, predicate, token)

                    match projected with
                    | Error error -> return Error error
                    | Ok projection ->
                        let! observed =
                            Task.Run(
                                (fun () -> observe evidence projection predicate limit token),
                                token
                            )

                        let plan =
                            Candidates.resolve
                                { Planning =
                                    { Profile = sources.Profile
                                      Roots =
                                        [ { Id = sources.Stamp.WorkspaceId
                                            Policy =
                                              ModConductor.GameContexts.Skyrim.definition.TargetPolicy } ]
                                      ReadOnly = []
                                      Writable = sources.Writable }
                                  Hidden = sources.Hidden }
                                sources.Stamp.WorkspaceId
                                observed

                        return Ok { Sources = sources; Plan = plan }
        }

    let openObserved source = GameInventory.readSource source |> fst
