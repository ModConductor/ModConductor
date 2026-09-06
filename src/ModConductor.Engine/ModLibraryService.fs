namespace ModConductor.Engine

open Google.Protobuf
open ModConductor.ModLibrary
open ModConductor.Platform
open ModConductor.Protocol.V2

/// Authenticated feature boundary; RPC disconnection does not cancel durable publication.
type ModLibraryService(library: IModLibrary) =
    inherit ModLibraryOperations.ModLibraryOperationsBase()

    override _.RegisterMod(request, _) =
        task {
            let! result =
                library.Register(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ModId,
                    ModLibraryWire.metadata request.Metadata,
                    ModLibraryWire.registration request
                )

            return ModLibraryWire.modReply result
        }

    override _.EditMod(request, _) =
        task {
            let! result =
                library.Edit(
                    ModLibraryWire.id request.ModId,
                    ModLibraryWire.number request.ExpectedRevision,
                    ModLibraryWire.metadata request.Metadata
                )

            return ModLibraryWire.modReply result
        }

    override _.ReadInventory(request, _) =
        task {
            let after =
                if request.HasAfterModId then
                    Some(ModLibraryWire.id request.AfterModId)
                else
                    None

            let! result = library.Inventory(ModLibraryWire.id request.ProfileId, after)

            return
                match result with
                | Error error -> InventoryReply(Fault = ModLibraryWire.fault error)
                | Ok value ->
                    let page = ModInventoryPage()
                    page.Entries.AddRange(value.Entries |> Seq.map ModLibraryWire.entry)
                    value.NextMod |> Option.iter (fun id -> page.NextModId <- id.ToString("N"))
                    InventoryReply(Page = page)
        }

    override _.ScanInventory(request, _) =
        task {
            let! result =
                library.Scan(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.count request.CandidateLimit
                )

            return
                match result with
                | Error error -> InventoryScanReply(Fault = ModLibraryWire.fault error)
                | Ok value ->
                    let scan = ModInventoryScan(Limited = value.Limited)
                    scan.Entries.AddRange(value.Entries |> Seq.map ModLibraryWire.entry)

                    scan.Unmanaged.AddRange(
                        value.Unmanaged
                        |> Seq.map (fun entry ->
                            UnmanagedModPath(
                                Path = ModLibraryWire.logical entry.Path,
                                Directory = (entry.Kind = EntryKind.Directory),
                                Unsupported =
                                    (entry.Kind = EntryKind.Other || entry.Kind = EntryKind.Link)
                            ))
                    )

                    InventoryScanReply(Scan = scan)
        }

    override _.PublishMod(request, _) =
        task {
            let! result =
                library.Publish(
                    ModLibraryWire.id request.ModId,
                    ModLibraryWire.number request.ExpectedRevision,
                    ModLibraryWire.id request.VersionId
                )

            return ModLibraryWire.modReply result
        }

    override _.ReadPublication(request, _) =
        task {
            let! result = library.Publication(ModLibraryWire.id request.VersionId)
            return ModLibraryWire.publication result
        }

    override _.CancelPublication(request, _) =
        task {
            let! result = library.CancelPublication(ModLibraryWire.id request.VersionId)
            return ModLibraryWire.publication result
        }

    override _.ReadModVersion(request, _) =
        task {
            let! result =
                library.Version(
                    ModLibraryWire.id request.VersionId,
                    ModLibraryWire.count request.Offset
                )

            return
                match result with
                | Error error -> ModVersionReply(Fault = ModLibraryWire.fault error)
                | Ok value ->
                    let version =
                        ModVersionPage(
                            VersionId = value.Id.ToString("N"),
                            ModId = value.ModId.ToString("N")
                        )

                    version.Entries.AddRange(
                        value.Entries
                        |> Seq.map (fun entry ->
                            ModManifestEntry(
                                Path = ModLibraryWire.logical entry.Path,
                                Payload =
                                    ModPayload(
                                        PayloadId = entry.Payload.Id.ToString("N"),
                                        Length = uint64 entry.Payload.Length,
                                        Sha256 = entry.Payload.Sha256
                                    )
                            ))
                    )

                    value.NextOffset |> Option.iter (fun next -> version.NextOffset <- uint32 next)
                    ModVersionReply(Version = version)
        }

    override _.ReadModPayload(request, _) =
        task {
            let! result =
                library.ReadPayload(
                    ModLibraryWire.id request.VersionId,
                    ModLibraryWire.id request.PayloadId,
                    ModLibraryWire.number request.Offset,
                    ModLibraryWire.count request.Count
                )

            return
                match result with
                | Error error -> ModPayloadReply(Fault = ModLibraryWire.fault error)
                | Ok bytes -> ModPayloadReply(Data = ByteString.CopyFrom bytes)
        }
