namespace ModConductor.FilePlanning

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module CandidateFiles =
    let internal observe
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
        let mutable limitReached = false

        let add target source =
            if found.Count >= limit then
                limitReached <- true
            else
                found.Add { Target = target; Source = source }

        use names = root.Names.GetEnumerator()

        while not limitReached && names.MoveNext() do
            token.ThrowIfCancellationRequested()
            let name = names.Current

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

        use originals = (projection.Originals :> seq<_>).GetEnumerator()

        while not limitReached && originals.MoveNext() do
            let logical, original = originals.Current.Key, originals.Current.Value

            if predicate logical then
                add logical original

        if limitReached then
            Error(FilePlanError.LimitExceeded "The plugin scan exceeds its candidate limit.")
        else
            Ok(List.ofSeq found)

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

                        match observed with
                        | Error error -> return Error error
                        | Ok candidates ->
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
                                    candidates

                            return Ok { Sources = sources; Plan = plan }
        }

    let openObserved source = GameInventory.readSource source |> fst
