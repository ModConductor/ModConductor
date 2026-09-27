namespace ModConductor.Engine

open System.Threading.Tasks
open ModConductor.ArchiveInstallation
open ModConductor.Persistence
open ModConductor.Protocol.V1

type InstallationService(store: InstallationStore) =
    inherit ArchiveInstallation.ArchiveInstallationBase()

    override _.PrepareInstallation(request, context) =
        InstallationWire.guard (fun () ->
            task {
                let! draft =
                    store.Prepare(ArtifactWire.reference request, context.CancellationToken)

                return draft |> InstallationWire.outcome |> InstallationWire.draft
            })

    override _.ChangeInstallationLayout(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id, revision = InstallationWire.reference request.Reference

                let change =
                    match request.ChangeCase with
                    | InstallationLayoutChange.ChangeOneofCase.Root ->
                        LayoutChange.Root(Seq.toList request.Root.Components)
                    | InstallationLayoutChange.ChangeOneofCase.Inclusion ->
                        LayoutChange.Include(
                            Seq.toList request.Inclusion.Source,
                            request.Inclusion.Included
                        )
                    | InstallationLayoutChange.ChangeOneofCase.Destination ->
                        LayoutChange.Destination(
                            Seq.toList request.Destination.Source,
                            Seq.toList request.Destination.Destination
                        )
                    | InstallationLayoutChange.ChangeOneofCase.Metadata ->
                        LayoutChange.Metadata(request.Metadata.Name, request.Metadata.Version)
                    | _ -> ModLibraryWire.reject "Choose a layout change."

                return
                    store.Change(workspace, id, revision, change)
                    |> InstallationWire.outcome
                    |> InstallationWire.draft
            })

    override _.CloseInstallationDraft(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id, _ = InstallationWire.reference request
                store.CloseDraft(workspace, id)
                return InstallationDraftClosed()
            })

    override _.StartInstallation(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let workspace, draft, revision = InstallationWire.reference request.Draft

                return
                    store.Start(workspace, draft, revision, ModLibraryWire.id request.Id)
                    |> InstallationWire.outcome
                    |> InstallationWire.status
            })

    override _.RecentInstallations(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let! entries = store.Recent(ModLibraryWire.id request.WorkspaceId)
                let reply = ArchiveInstallationList()
                reply.Entries.AddRange(entries |> List.map InstallationWire.status)
                return reply
            })

    override _.WatchInstallation(request, stream, context) : Task =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id =
                    ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.Id

                let mutable running = true

                while running && not context.CancellationToken.IsCancellationRequested do
                    let! status = store.Read(workspace, id)

                    do!
                        stream.WriteAsync(
                            InstallationWire.status status,
                            context.CancellationToken
                        )

                    running <- status.State = InstallationState.Running

                    if running then
                        do! store.WaitForChange(workspace, id, status, context.CancellationToken)
            })

    override _.CancelInstallation(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let! status =
                    store.Cancel(
                        ModLibraryWire.id request.WorkspaceId,
                        ModLibraryWire.id request.Id
                    )

                return InstallationWire.status status
            })

    override _.DeleteInstallationFiles(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let! status =
                    store.Discard(
                        ModLibraryWire.id request.WorkspaceId,
                        ModLibraryWire.id request.Id
                    )

                return InstallationWire.status status
            })
