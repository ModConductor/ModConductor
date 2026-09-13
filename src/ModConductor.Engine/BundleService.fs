namespace ModConductor.Engine

open ModConductor.Persistence
open ModConductor.Protocol.V1

type BundleService(store: BundleStore) =
    inherit BundleInstallation.BundleInstallationBase()

    override _.FindBundle(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let! found =
                    store.Find(ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.Id)

                let response = BundleFound()
                found |> Option.iter (fun b -> response.Bundle <- BundleWire.bundle b)
                return response
            })

    override _.DiscoverBundle(request, context) =
        InstallationWire.guard (fun () ->
            task {
                let! result =
                    store.Discover(BundleWire.artifact request, context.CancellationToken)

                return BundleWire.discovery result
            })

    override _.CreateBundle(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let w, id, r = InstallationWire.reference request.Draft

                return
                    store.Create(w, id, r, request.Entries |> Seq.map int |> List.ofSeq)
                    |> BundleWire.bundle
            })

    override _.ReadBundle(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let r = BundleWire.reference request
                let! result = store.Read(r.WorkspaceId, r.Id)
                return BundleWire.bundle result
            })

    override _.ConfigureBundleMod(request, context) =
        InstallationWire.guard (fun () ->
            task {
                let r = BundleWire.reference request.Reference

                let! result =
                    store.Prepare(r, ModLibraryWire.id request.Mod, context.CancellationToken)

                let! current = store.Read(r.WorkspaceId, r.Id)

                return
                    BundleConfiguration(
                        Bundle = BundleWire.bundle current,
                        Prepared = BundleWire.discovery result
                    )
            })

    override _.ChooseNestedArchives(request, _) =
        InstallationWire.guard (fun () ->
            task {
                if isNull request.Target then
                    ModLibraryWire.reject "Select a mod in this bundle."

                let r = BundleWire.reference request.Target.Reference
                let w, draft, revision = InstallationWire.reference request.Draft

                if w <> r.WorkspaceId then
                    ModLibraryWire.reject "Choose a review in this workspace."

                return
                    store.ChooseNested(
                        r,
                        ModLibraryWire.id request.Target.Mod,
                        draft,
                        revision,
                        request.Entries |> Seq.map int |> List.ofSeq
                    )
                    |> BundleWire.bundle
            })

    override _.RenameBundleMod(request, _) =
        InstallationWire.guard (fun () ->
            task {
                if isNull request.Target then
                    ModLibraryWire.reject "Select a mod in this bundle."

                return
                    store.Rename(
                        BundleWire.reference request.Target.Reference,
                        ModLibraryWire.id request.Target.Mod,
                        request.Name
                    )
                    |> BundleWire.bundle
            })

    override _.MoveBundleMod(request, _) =
        InstallationWire.guard (fun () ->
            task {
                if isNull request.Target then
                    ModLibraryWire.reject "Select a mod in this bundle."

                return
                    store.Move(
                        BundleWire.reference request.Target.Reference,
                        ModLibraryWire.id request.Target.Mod,
                        request.Earlier
                    )
                    |> BundleWire.bundle
            })

    override _.ReadBundleModStatus(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let r = BundleWire.reference request.Reference
                let! result = store.Status(r.WorkspaceId, r.Id, ModLibraryWire.id request.Mod)
                return InstallationWire.status result
            })

    override _.RetryBundleMod(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let! result =
                    store.Retry(
                        BundleWire.reference request.Reference,
                        ModLibraryWire.id request.Mod
                    )

                return BundleWire.bundle result
            })

    override _.DeleteBundleTemporaryFiles(request, _) =
        InstallationWire.guard (fun () ->
            task {
                do! store.Delete(BundleWire.reference request)
                return BundleClosed()
            })
