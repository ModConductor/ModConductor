namespace ModConductor.ProfileGameData

open System
open ModConductor.Bethesda
open ModConductor.Platform

module internal SaveGroupInspection =
    let private result = ProfileDataResultFlow.result
    let private resultTask = ProfileDataResultTask.resultTask

    type ObservedGroup =
        { Entry: ProfileSaveGroupEntry
          Save: StoredDataFile
          Companion: StoredDataFile option }

    let observe (root: DataRoot) name token =
        use folder = HeldDirectory.Open(root.Path, root.Identity)

        result {
            let! entries = SaveGroupPaging.rows root

            let! entry =
                match entries |> List.tryFind (fun row -> row.Id = name) with
                | Some value -> Ok value
                | None -> Error ProfileDataError.NotFound

            if entry.Kind <> ProfileSaveEntryKind.Save || not entry.Actionable then
                return! Error(ProfileDataError.Invalid "Choose an unambiguous Skyrim save first.")

            let file =
                DataFiles.observe folder entry.Name token
                |> Option.defaultWith (fun () -> DataFiles.fail (entry.Name + " changed."))

            let save =
                { Root = root
                  Name = entry.Name
                  File = file }

            let companion =
                entry.Companion
                |> Option.map (fun name ->
                    let file =
                        DataFiles.observe folder name token
                        |> Option.defaultWith (fun () -> DataFiles.fail (name + " changed."))

                    { Root = root
                      Name = name
                      File = file })

            return
                { Entry = entry
                  Save = save
                  Companion = companion }
        }

    let private error =
        function
        | SkyrimSaveError.Malformed detail
        | SkyrimSaveError.Unsupported detail
        | SkyrimSaveError.Limit detail -> detail

    let private diagnostics
        (repository: IProfileDataRepository)
        (plugins: PluginSession)
        (scope: ProfileDataScope)
        (headers: Guid option)
        (metadata: SkyrimSaveMetadata)
        =
        task {
            match headers with
            | None -> return [], Some "Refresh plugins to check this save."
            | Some id ->
                try
                    let! orderResult =
                        PluginOrders.read repository plugins scope.WorkspaceId scope.ProfileId id

                    match orderResult with
                    | Ok order -> return SaveDiagnostics.check order metadata
                    | Error _ -> return [], Some "Refresh plugins to check this save."
                with ProfileDataException _ ->
                    return [], Some "Refresh plugins to check this save."
        }

    let inspect repository plugins (scope: ProfileDataScope) kind name headers token =
        resultTask {
            let! root, path = SaveGroupSource.source scope kind

            let! root =
                match root with
                | Some value -> Ok value
                | None -> Error ProfileDataError.NotFound

            let! group = observe root name token
            use folder = HeldDirectory.Open(group.Save.Root.Path, group.Save.Root.Identity)
            let stream, _ = folder.Read(group.Save.Name, Some group.Save.File.Identity)
            use stream = stream

            match SkyrimSaveReader.read stream token with
            | Error problem ->
                return
                    { Source = kind
                      Path = path
                      Entry = group.Entry
                      Metadata = None
                      MetadataProblem = Some(error problem)
                      PluginIssues = []
                      PluginCheckProblem = None }
            | Ok metadata ->
                let! issues, checkProblem = diagnostics repository plugins scope headers metadata

                return
                    { Source = kind
                      Path = path
                      Entry = group.Entry
                      Metadata = Some metadata
                      MetadataProblem = None
                      PluginIssues = issues
                      PluginCheckProblem = checkProblem }
        }
