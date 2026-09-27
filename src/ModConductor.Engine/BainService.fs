namespace ModConductor.Engine

open ModConductor.ArchiveInstallation
open ModConductor.Persistence
open ModConductor.Protocol.V1

type BainService(store: InstallationStore) =
    inherit BainInstallation.BainInstallationBase()

    override _.OpenPackageChoices(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let w, id, r = InstallationWire.reference request
                return store.Bain.Open(w, id, r) |> InstallationWire.outcome |> BainWire.choices
            })

    override _.SelectPackageFolder(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let w, id, r = InstallationWire.reference request.Reference

                return
                    store.Bain.Choose(w, id, r, int request.Index, request.Selected)
                    |> InstallationWire.outcome
                    |> BainWire.choices
            })

    override _.SelectAllPackageFolders(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let w, id, r = InstallationWire.reference request.Reference

                return
                    store.Bain.ChooseAll(w, id, r, request.Selected)
                    |> InstallationWire.outcome
                    |> BainWire.choices
            })

    override _.IncludePackageFile(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let w, id, r = InstallationWire.reference request.Reference

                return
                    store.Bain.Include(w, id, r, List.ofSeq request.Path, request.Included)
                    |> InstallationWire.outcome
                    |> BainWire.choices
            })

    override _.ReviewPackageFiles(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let w, id, r = InstallationWire.reference request
                return store.Bain.Review(w, id, r) |> InstallationWire.outcome |> BainWire.choices
            })

    override _.BackToPackageFolders(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let w, id, r = InstallationWire.reference request
                return store.Bain.Back(w, id, r) |> InstallationWire.outcome |> BainWire.choices
            })

    override _.ReadPackageFolder(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let w, id, r = InstallationWire.reference request.Reference

                return
                    store.Bain.Folder(w, id, r, int request.Index)
                    |> InstallationWire.outcome
                    |> BainWire.folder
            })

    override _.ReadPackageNotes(request, context) =
        InstallationWire.guard (fun () ->
            task {
                let w, id, r = InstallationWire.reference request
                let! notes = store.Bain.Notes(w, id, r, context.CancellationToken)
                return BainPackageNotes(Text = InstallationWire.outcome notes)
            })

    override _.SelectArchiveInstaller(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let w, id, r = InstallationWire.reference request.Reference

                let mode =
                    match request.Installer with
                    | ArchiveInstaller.Manual -> InstallationMode.Manual
                    | ArchiveInstaller.Fomod -> InstallationMode.Fomod
                    | ArchiveInstaller.Bain -> InstallationMode.Bain
                    | _ -> ModLibraryWire.reject "Choose an available installer."

                return
                    store.UseInstaller(w, id, r, mode)
                    |> InstallationWire.outcome
                    |> InstallationWire.draft
            })
