namespace ModConductor.Engine

open System.Threading.Tasks
open ModConductor.ModMaintenance
open ModConductor.Persistence
open ModConductor.Protocol.V1

type DeletionService(store: DeletionStore) =
    inherit ModDeletion.ModDeletionBase()

    override _.PrepareModDeletion(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let! value =
                    store.Prepare(
                        ModLibraryWire.id request.WorkspaceId,
                        ModLibraryWire.id request.ModId,
                        ModLibraryWire.number request.Revision
                    )

                return DeletionWire.preview value
            })

    override _.CloseModDeletionPreview(request, _) =
        InstallationWire.guard (fun () ->
            task {
                store.ClosePreview(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.Id
                )

                return ModDeletionPreviewClosed()
            })

    override _.StartModDeletion(request, _) =
        InstallationWire.guard (fun () ->
            task {
                return
                    store.Start(
                        ModLibraryWire.id request.WorkspaceId,
                        ModLibraryWire.id request.PreviewId,
                        ModLibraryWire.id request.Id
                    )
                    |> DeletionWire.status
            })

    override _.ContinueModDeletion(request, _) =
        InstallationWire.guard (fun () ->
            task {
                return
                    store.Continue(
                        ModLibraryWire.id request.WorkspaceId,
                        ModLibraryWire.id request.Id
                    )
                    |> DeletionWire.status
            })

    override _.RecentModDeletions(request, _) =
        InstallationWire.guard (fun () ->
            task {
                let! values = store.Recent(ModLibraryWire.id request.WorkspaceId)
                let reply = ModDeletionList()
                reply.Entries.AddRange(values |> List.map DeletionWire.status)
                return reply
            })

    override _.WatchModDeletion(request, stream, context) : Task =
        InstallationWire.guard (fun () ->
            task {
                let workspace, id =
                    ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.Id

                let mutable running = true

                while running && not context.CancellationToken.IsCancellationRequested do
                    let! value = store.Read(workspace, id)
                    do! stream.WriteAsync(DeletionWire.status value, context.CancellationToken)
                    running <- value.Phase = DeletionPhase.Running

                    if running then
                        do! Task.Delay(500, context.CancellationToken)
            })
