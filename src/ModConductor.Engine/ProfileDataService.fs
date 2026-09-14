namespace ModConductor.Engine

open System
open System.Threading.Channels
open ModConductor
open ModConductor.ProfileGameData

type ProfileDataService(profiles: IProfileGameData) =
    inherit Protocol.V1.ProfileDataOperations.ProfileDataOperationsBase()

    let send context output action =
        ProfileActionStream.send
            context
            output
            (fun (value: ProfileDataProgress) ->
                Protocol.V1.ProfileDataEvent(
                    Progress =
                        Protocol.V1.ProfileDataProgress(
                            Files = uint32 value.Files,
                            Bytes = uint64 value.Bytes
                        )
                ))
            ProfileDataWire.finished
            action

    let source =
        function
        | Protocol.V1.ProfileSaveSource.Global -> ProfileSaveSource.Global
        | Protocol.V1.ProfileSaveSource.Profile -> ProfileSaveSource.Profile
        | _ -> ModLibraryWire.reject "Choose global or profile saves."

    let sourceWire =
        function
        | ProfileSaveSource.Global -> Protocol.V1.ProfileSaveSource.Global
        | ProfileSaveSource.Profile -> Protocol.V1.ProfileSaveSource.Profile

    let pathWire (value: ProfileSavePath) =
        let path = Protocol.V1.ProfileSavePath(HostPath = value.HostPath)
        value.WindowsPath |> Option.iter (fun value -> path.WindowsPath <- value)
        path

    let groupWire (value: ProfileSaveGroupEntry) =
        let kind =
            match value.Kind with
            | ProfileSaveEntryKind.Save -> Protocol.V1.ProfileSaveEntryKind.Save
            | ProfileSaveEntryKind.Directory -> Protocol.V1.ProfileSaveEntryKind.Directory
            | ProfileSaveEntryKind.Other -> Protocol.V1.ProfileSaveEntryKind.Other

        let entry =
            Protocol.V1.ProfileSaveGroupEntry(
                Id = value.Id,
                Name = value.Name,
                Kind = kind,
                Bytes = uint64 value.Bytes,
                CompanionBytes = uint64 value.CompanionBytes,
                Actionable = value.Actionable
            )

        value.Companion |> Option.iter (fun value -> entry.Companion <- value)
        value.Problem |> Option.iter (fun value -> entry.Problem <- value)
        entry

    let metadataWire (value: ModConductor.Bethesda.SkyrimSaveMetadata) =
        let compression =
            match value.Compression with
            | ModConductor.Bethesda.SkyrimSaveCompression.Uncompressed ->
                Protocol.V1.SkyrimSaveCompression.Uncompressed
            | ModConductor.Bethesda.SkyrimSaveCompression.Zlib ->
                Protocol.V1.SkyrimSaveCompression.Zlib
            | ModConductor.Bethesda.SkyrimSaveCompression.Lz4 ->
                Protocol.V1.SkyrimSaveCompression.Lz4

        let metadata =
            Protocol.V1.SkyrimSaveMetadata(
                HeaderVersion = value.HeaderVersion,
                FormVersion = uint32 value.FormVersion,
                Compression = compression,
                SaveNumber = value.SaveNumber,
                Character = value.Character,
                Level = value.Level,
                Location = value.Location,
                GameTime = value.GameTime
            )

        value.FullPlugins |> List.iter (fun plugin -> metadata.FullPlugins.Add(plugin))

        value.LightPlugins
        |> List.iter (fun plugin -> metadata.LightPlugins.Add(plugin))

        metadata

    let action =
        function
        | Protocol.V1.ProfileSaveAction.CopyToProfile -> ProfileSaveAction.CopyToProfile
        | Protocol.V1.ProfileSaveAction.DeleteFromProfile -> ProfileSaveAction.DeleteFromProfile
        | _ -> ModLibraryWire.reject "Choose copy or delete."

    let actionWire =
        function
        | ProfileSaveAction.CopyToProfile -> Protocol.V1.ProfileSaveAction.CopyToProfile
        | ProfileSaveAction.DeleteFromProfile -> Protocol.V1.ProfileSaveAction.DeleteFromProfile

    override _.ListProfileSaves(request, _) =
        task {
            let! result =
                profiles.SaveFiles(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId,
                    List.ofSeq request.Path,
                    if request.HasAfter then Some request.After else None
                )

            match result with
            | Error error ->
                return Protocol.V1.ProfileSaveReply(Problem = ProfileDataWire.problem error)
            | Ok value ->
                let page = Protocol.V1.ProfileSavePage()

                for entry in value.Entries do
                    page.Entries.Add(
                        Protocol.V1.ProfileSaveEntry(
                            Name = entry.Name,
                            Directory = entry.Directory,
                            Bytes = uint64 entry.Bytes
                        )
                    )

                value.Next |> Option.iter (fun next -> page.Next <- next)
                return Protocol.V1.ProfileSaveReply(Page = page)
        }

    override _.ListSaveGroups(request, _) =
        task {
            let! result =
                profiles.SaveGroups(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId,
                    source request.Source,
                    if request.HasAfter then Some request.After else None
                )

            match result with
            | Error error ->
                return Protocol.V1.ProfileSaveGroupReply(Problem = ProfileDataWire.problem error)
            | Ok value ->
                let page =
                    Protocol.V1.ProfileSaveGroupPage(
                        Source = sourceWire value.Source,
                        Path = pathWire value.Path
                    )

                value.Entries |> List.iter (groupWire >> page.Entries.Add)
                value.Next |> Option.iter (fun value -> page.Next <- value)
                return Protocol.V1.ProfileSaveGroupReply(Page = page)
        }

    override _.InspectSave(request, context) =
        task {
            let! result =
                profiles.InspectSave(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId,
                    source request.Source,
                    request.Name,
                    (if request.HasHeadersId then
                         Some(ModLibraryWire.id request.HeadersId)
                     else
                         None),
                    context.CancellationToken
                )

            match result with
            | Error error ->
                return Protocol.V1.ProfileSaveInspectReply(Problem = ProfileDataWire.problem error)
            | Ok value ->
                let inspection =
                    Protocol.V1.ProfileSaveInspection(
                        Source = sourceWire value.Source,
                        Path = pathWire value.Path,
                        Entry = groupWire value.Entry
                    )

                value.Metadata
                |> Option.iter (metadataWire >> fun value -> inspection.Metadata <- value)

                value.MetadataProblem
                |> Option.iter (fun value -> inspection.MetadataProblem <- value)

                value.PluginCheckProblem
                |> Option.iter (fun value -> inspection.PluginCheckProblem <- value)

                for issue in value.PluginIssues do
                    let wire =
                        Protocol.V1.SavePluginIssue(
                            Name = issue.Name,
                            State =
                                match issue.State with
                                | SavePluginState.Missing -> Protocol.V1.SavePluginState.Missing
                                | SavePluginState.Inactive -> Protocol.V1.SavePluginState.Inactive
                        )

                    issue.Source |> Option.iter (fun value -> wire.Source <- value)
                    inspection.PluginIssues.Add wire

                return Protocol.V1.ProfileSaveInspectReply(Inspection = inspection)
        }

    override _.PreviewSaveAction(request, context) =
        if isNull request.Expected then
            ModLibraryWire.reject "Read the profile saves first."

        task {
            let! result =
                profiles.PreviewSaveAction(
                    ProfileDataWire.readReference request.Expected,
                    action request.Action,
                    List.ofSeq request.Names,
                    context.CancellationToken
                )

            match result with
            | Error error ->
                return
                    Protocol.V1.ProfileSaveActionPreviewReply(
                        Problem = ProfileDataWire.problem error
                    )
            | Ok value ->
                let preview =
                    Protocol.V1.ProfileSaveActionPreview(
                        Id = value.Id.ToString("N"),
                        Expected = ProfileDataWire.reference value.Expected,
                        Action = actionWire value.Action,
                        Source = pathWire value.Source,
                        Bytes = uint64 value.Bytes
                    )

                value.Destination
                |> Option.iter (pathWire >> fun value -> preview.Destination <- value)

                for file in value.Files do
                    preview.Files.Add(
                        Protocol.V1.ProfileSaveActionFile(
                            Name = file.Name,
                            Bytes = uint64 file.Bytes
                        )
                    )

                return Protocol.V1.ProfileSaveActionPreviewReply(Preview = preview)
        }

    override _.ApplySaveAction(request, output, context) =
        if isNull request.Expected then
            ModLibraryWire.reject "Read the profile saves first."

        send context output (fun progress ->
            profiles.ApplySaveAction(
                ModLibraryWire.id request.Id,
                ModLibraryWire.id request.PreviewId,
                ProfileDataWire.readReference request.Expected,
                progress,
                context.CancellationToken
            ))

    override _.ReadProfileData(request, _) =
        task {
            let! result =
                profiles.Read(
                    ModLibraryWire.id request.WorkspaceId,
                    ModLibraryWire.id request.ProfileId
                )

            return ProfileDataWire.reply result
        }

    override _.EditProfileData(request, output, context) =
        if isNull request.Options then
            ModLibraryWire.reject "Choose the profile options."

        let initial =
            match request.InitialSaves with
            | Protocol.V1.InitialProfileSaves.Empty -> InitialSaves.Empty
            | Protocol.V1.InitialProfileSaves.CopyGlobal -> InitialSaves.CopyGlobal
            | _ -> ModLibraryWire.reject "Choose how the local saves start."

        let disabled =
            match request.DisabledFiles with
            | Protocol.V1.DisabledProfileFiles.Keep -> DisabledFiles.Keep
            | Protocol.V1.DisabledProfileFiles.Delete -> DisabledFiles.Delete
            | _ -> ModLibraryWire.reject "Choose whether to keep the local files."

        let edit =
            { Id = ModLibraryWire.id request.Id
              Expected = ProfileDataWire.readReference request.Expected
              Options =
                { Settings = request.Options.Settings
                  Saves = request.Options.Saves }
              InitialSaves = initial
              DisabledFiles = disabled }

        send context output (fun progress ->
            profiles.Edit(edit, progress, context.CancellationToken))

    override _.RestoreProfileData(request, output, context) =
        let id = ModLibraryWire.id request.Id
        let expected = ProfileDataWire.readReference request.Expected
        send context output (fun _ -> profiles.Restore(id, expected, context.CancellationToken))

    override _.ResumeProfileData(request, output, context) =
        let workspace, id =
            ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.Id

        send context output (fun _ -> profiles.Resume(workspace, id, context.CancellationToken))
