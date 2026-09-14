namespace ModConductor.Engine

open System.Threading.Channels
open ModConductor.FilePlanning
open ModConductor.Protocol.V1

type FilePlanService(plans: IFilePlans) =
    inherit FilePlanOperations.FilePlanOperationsBase()

    override _.OpenFilePlan(request, context) =
        task {
            let! result = plans.Open(ModLibraryWire.id request.ProfileId, context.CancellationToken)
            return FilePlanWire.reply result
        }

    override _.ReadFilePlan(request, _) =
        task {
            let! result = plans.Read(ModLibraryWire.id request.SnapshotId)
            return FilePlanWire.reply result
        }

    override _.ReadFilePlanChildren(request, _) =
        task {
            if request.Filter.Length > 4096 then
                ModLibraryWire.reject "The file filter is too long."

            let parent =
                if isNull request.Parent then
                    None
                else
                    Some(ModLibraryWire.path request.Parent)

            let! result =
                plans.Children(
                    ModLibraryWire.id request.SnapshotId,
                    parent,
                    request.Filter,
                    FilePlanWire.readCursor request.Cursor
                )

            return FilePlanWire.page result
        }

    override _.ReadFilePlanProblems(request, _) =
        task {
            let! result =
                plans.Problems(
                    ModLibraryWire.id request.SnapshotId,
                    FilePlanWire.readCursor request.Cursor
                )

            return FilePlanWire.problems result
        }

    override _.InspectFilePlanTarget(request, _) =
        task {
            let! result =
                plans.Inspect(
                    ModLibraryWire.id request.SnapshotId,
                    ModLibraryWire.path request.Target,
                    FilePlanWire.readCursor request.Cursor
                )

            return FilePlanWire.inspection result
        }

    override _.InspectSavedFile(request, _) =
        task {
            let! result =
                plans.InspectCopy(
                    ModLibraryWire.id request.SnapshotId,
                    FilePlanWire.readCopy request.Copy
                )

            return FilePlanWire.inspection result
        }

    override _.ChangeFileVisibility(request, context) =
        task {
            let! result =
                plans.Change(
                    ModLibraryWire.id request.SnapshotId,
                    FilePlanWire.readCopy request.Copy,
                    request.Hidden,
                    context.CancellationToken
                )

            return FilePlanWire.change result
        }

    override _.PreviewFileSource(request, context) =
        task {
            let! result =
                plans.Preview(
                    ModLibraryWire.id request.SnapshotId,
                    FilePlanWire.readSource request.Source,
                    FilePlanWire.readRepresentation request.Representation,
                    context.CancellationToken
                )

            return FilePlanWire.preview result
        }

    override _.OpenManagedText(request, context) =
        task {
            let source = FilePlanWire.readSource (FilePreviewSource(Managed = request.Source))

            match source with
            | FilePreviewSource.ManagedCopy source ->
                let! result =
                    plans.OpenManagedText(
                        ModLibraryWire.id request.SnapshotId,
                        source,
                        context.CancellationToken
                    )

                return FilePlanWire.managedText result
            | _ -> return invalidOp "Managed source conversion failed."
        }

    override _.SaveManagedText(request, context) =
        task {
            let source = FilePlanWire.readSource (FilePreviewSource(Managed = request.Source))

            match source with
            | FilePreviewSource.ManagedCopy source ->
                let! result =
                    plans.SaveManagedText(
                        ModLibraryWire.id request.SnapshotId,
                        ModLibraryWire.id request.Id,
                        source,
                        request.Content,
                        context.CancellationToken
                    )

                return FilePlanWire.managedTextEdit result
            | _ -> return invalidOp "Managed source conversion failed."
        }

    override _.AbandonManagedText(request, _) =
        task {
            let! result = plans.AbandonManagedText(ModLibraryWire.id request.Id)
            return FilePlanWire.managedTextAbandon result
        }

    override _.ReadFileVisibilityHistory(request, _) =
        task {
            let before =
                if request.HasBeforeId then
                    Some(ModLibraryWire.number request.BeforeId)
                else
                    None

            let! result =
                plans.History(
                    ModLibraryWire.id request.SnapshotId,
                    FilePlanWire.readCopy request.Copy,
                    before
                )

            return FilePlanWire.history result
        }

    override _.AcquireFilePlan(request, output, context) =
        task {
            let profile = ModLibraryWire.id request.ProfileId

            let options =
                BoundedChannelOptions(
                    1,
                    FullMode = BoundedChannelFullMode.DropOldest,
                    SingleReader = true,
                    SingleWriter = true
                )

            let events = Channel.CreateBounded<FilePlanLoadEvent> options

            let producer =
                task {
                    try
                        let progress (value: AcquisitionProgress) =
                            events.Writer.TryWrite(
                                FilePlanLoadEvent(
                                    Progress =
                                        FilePlanLoadProgress(
                                            Files = uint32 value.Files,
                                            TotalFiles = uint32 value.TotalFiles,
                                            Bytes = uint64 value.Bytes,
                                            TotalBytes = uint64 value.TotalBytes
                                        )
                                )
                            )
                            |> ignore

                        let! result =
                            plans.Acquire(
                                profile,
                                request.Refresh,
                                progress,
                                context.CancellationToken
                            )

                        events.Writer.TryWrite(
                            FilePlanLoadEvent(Finished = FilePlanWire.reply result)
                        )
                        |> ignore

                        events.Writer.TryComplete() |> ignore
                    with error ->
                        events.Writer.TryComplete error |> ignore
                }

            let mutable available = true

            while available do
                let! more = events.Reader.WaitToReadAsync(context.CancellationToken)
                available <- more

                if more then
                    let mutable item = Unchecked.defaultof<FilePlanLoadEvent>

                    while events.Reader.TryRead(&item) do
                        do! output.WriteAsync(item, context.CancellationToken)

            do! producer
        }
