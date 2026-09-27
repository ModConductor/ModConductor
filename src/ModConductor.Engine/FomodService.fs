namespace ModConductor.Engine

open Google.Protobuf
open ModConductor.Persistence
open ModConductor.Protocol.V1

type FomodService(store: InstallationStore) =
    inherit FomodInstallation.FomodInstallationBase()

    override _.OpenChoices(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id, revision = InstallationWire.reference request.Draft

                let! value =
                    store.Fomod.Open(workspace, id, revision, ModLibraryWire.id request.ProfileId)

                return FomodWire.choices value
            })

    override _.ReadChoices(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id, revision = InstallationWire.reference request
                return store.Fomod.Read(workspace, id, revision) |> FomodWire.choices
            })

    override _.ChangeChoice(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id, revision = InstallationWire.reference request.Draft

                return
                    store.Fomod.Choose(
                        workspace,
                        id,
                        revision,
                        int request.OptionId,
                        request.Selected
                    )
                    |> InstallationWire.outcome
                    |> FomodWire.choices
            })

    override _.NextStep(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id, revision = InstallationWire.reference request
                return store.Fomod.Next(workspace, id, revision) |> FomodWire.choices
            })

    override _.PreviousStep(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id, revision = InstallationWire.reference request
                return store.Fomod.Back(workspace, id, revision) |> FomodWire.choices
            })

    override _.UseManualLayout(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id, revision = InstallationWire.reference request
                return store.Fomod.Manual(workspace, id, revision) |> InstallationWire.draft
            })

    override _.ReadChoiceImage(request, context) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id, revision = InstallationWire.reference request.Draft

                let! bytes =
                    store.Fomod.Image(
                        workspace,
                        id,
                        revision,
                        List.ofSeq request.Path,
                        context.CancellationToken
                    )

                return FomodImage(Content = ByteString.CopyFrom bytes)
            })
