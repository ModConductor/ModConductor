namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Nexus
open ModConductor.Thunderstore
open ModConductor.Persistence
open ModConductor.Protocol.V1

type ThunderstoreService(reader: IPackageReader, inventory: ThunderstoreInventory, acquisition: ModConductor.Persistence.ThunderstoreAcquisition, handoff: IOAuthHandoff) =
    inherit Thunderstore.ThunderstoreBase()
    let selected reference (version: string option) token = task {
        let! latest = reader.Details(reference, None, token)
        match latest with
        | Error error -> return Error error
        | Ok latest when version.IsNone || version = Some latest.Reference.Version -> return Ok(latest, latest.Reference.Version)
        | Ok latest ->
            let! exact = reader.Details(reference, version, token)
            return exact |> Result.map (fun exact -> exact, latest.Reference.Version)
    }
    let readDetails workspace reference version token = task {
        let! result = selected reference version token
        match result with
        | Error error -> return Error error
        | Ok(source, latest) ->
            let! choices = reader.Versions(reference, token)
            match choices with
            | Error error -> return Error error
            | Ok choices ->
                let! existing = inventory.Read(workspace, reference)
                let value = ThunderstoreWire.details source latest choices existing
                for dependency in source.Dependencies do
                    let! existing = inventory.Read(workspace, dependency.Reference.Package)
                    let item = ThunderstoreDependency(Reference = ThunderstoreWire.reference dependency.Reference, Available = dependency.Available)
                    dependency.Icon |> Option.iter (fun uri -> item.IconUrl <- uri.AbsoluteUri)
                    item.Installed.AddRange(existing |> List.map ThunderstoreWire.installed)
                    value.Dependencies.Add item
                return Ok value
    }
    override _.SearchThunderstore(request, context) = task {
        match ThunderstoreWire.workspace request.WorkspaceId with
        | None -> return ThunderstoreSearchReply(Failure = ThunderstoreWire.failure Problem.InvalidRequest)
        | Some workspace ->
            let! result = reader.Search(request.Community, request.Query, request.Ordering, request.Page, context.CancellationToken)
            match result with
            | Error error -> return ThunderstoreSearchReply(Failure = ThunderstoreWire.failure error)
            | Ok page ->
                let value = ThunderstorePackages(Count = page.Count)
                page.Next |> Option.iter (fun next -> value.NextPage <- next)
                for row in page.Entries do
                    let! existing = inventory.Read(workspace, row.Package)
                    value.Entries.Add(ThunderstoreWire.preview row existing)
                return ThunderstoreSearchReply(Packages = value)
    }
    override _.ReadThunderstorePackage(request, context) = task {
        match ThunderstoreWire.workspace request.WorkspaceId with
        | None -> return ThunderstorePackageReply(Failure = ThunderstoreWire.failure Problem.InvalidRequest)
        | Some workspace ->
            let! result = readDetails workspace (ThunderstoreWire.readPackage request.Package) (if request.HasVersion then Some request.Version else None) context.CancellationToken
            match result with
            | Ok value -> return ThunderstorePackageReply(Package = value)
            | Error error -> return ThunderstorePackageReply(Failure = ThunderstoreWire.failure error)
    }
    override _.AcquireThunderstorePackage(request, stream, context) : Task = task {
        let reference = ThunderstoreWire.readReference request.Reference
        use cancellation = CancellationTokenSource.CreateLinkedTokenSource(context.CancellationToken)
        let emit progress : Task = task {
            try do! stream.WriteAsync(ThunderstoreWire.progress progress, cancellation.Token)
            with
            | :? Grpc.Core.RpcException
            | :? System.IO.IOException ->
                cancellation.Cancel()
                cancellation.Token.ThrowIfCancellationRequested()
        }
        match ThunderstoreWire.workspace request.WorkspaceId with
        | None -> do! stream.WriteAsync(ThunderstoreAcquisition(Failure = ThunderstoreWire.failure Problem.InvalidRequest), context.CancellationToken)
        | Some workspace when VersionReference.valid reference ->
            let! result = acquisition.Acquire(workspace, reference, emit, cancellation.Token)
            if not cancellation.IsCancellationRequested then
                let value = ThunderstoreAcquisition(Reference = request.Reference, Stage = "complete")
                match result with
                | Ok entries -> value.Completed <- entries.Length; value.Packages <- entries.Length
                | Error error -> value.Stage <- "stopped"; value.Failure <- ThunderstoreWire.failure error
                do! stream.WriteAsync(value, context.CancellationToken)
        | Some _ -> do! stream.WriteAsync(ThunderstoreAcquisition(Failure = ThunderstoreWire.failure Problem.InvalidRequest), context.CancellationToken)
    }
    override _.OpenThunderstorePage(request, context) = task {
        let reference = ThunderstoreWire.readPackage request
        if PackageReference.valid reference then
            do! handoff.Open(Uri("https://thunderstore.io/c/" + reference.Community + "/p/" + reference.Namespace + "/" + reference.Name + "/"), context.CancellationToken)
        return ThunderstoreOpened()
    }
