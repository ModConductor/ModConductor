namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Platform

module internal SaveGroups =
    let private result = ProfileDataResultFlow.result

    let private validateSelection (selected: string list) =
        if selected.IsEmpty || selected.Length > 64 then
            Error(ProfileDataError.Invalid "Choose between 1 and 64 current save groups.")
        else
            let unique = Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase)

            if selected |> List.exists (unique.Add >> not) then
                Error(ProfileDataError.Invalid "Choose each save once.")
            else
                Ok()

    let private targetNames action (root: DataRoot) =
        if action = ProfileSaveAction.CopyToProfile then
            use target = HeldDirectory.Open(root.Path, root.Identity)
            target.Names |> Seq.truncate 1000001 |> Seq.toList
        else
            []

    let private filesForGroup
        action
        targetRoot
        collision
        (group: SaveGroupInspection.ObservedGroup)
        =
        let observed = group.Save :: (group.Companion |> Option.toList)

        if
            action = ProfileSaveAction.CopyToProfile
            && observed |> List.exists (fun file -> collision file.Name)
        then
            Error(
                ProfileDataError.Conflict
                    "A save group with this name is already present in the profile."
            )
        else
            let ordered =
                match action with
                | ProfileSaveAction.CopyToProfile -> List.rev observed
                | ProfileSaveAction.DeleteFromProfile -> observed

            ordered
            |> List.map (fun file ->
                { Target = targetRoot
                  Name = file.Name
                  Before =
                    if action = ProfileSaveAction.DeleteFromProfile then
                        Some file.File
                    else
                        None
                  Source =
                    if action = ProfileSaveAction.CopyToProfile then
                        Some file
                    else
                        None })
            |> Ok

    let prepare
        (previewId: Guid)
        (scope: ProfileDataScope)
        (action: ProfileSaveAction)
        (selected: string list)
        (token: CancellationToken)
        =
        result {
            do! validateSelection selected

            let sourceKind =
                match action with
                | ProfileSaveAction.CopyToProfile -> ProfileSaveSource.Global
                | ProfileSaveAction.DeleteFromProfile -> ProfileSaveSource.Profile

            let! sourceRoot, sourcePath = SaveGroupSource.source scope sourceKind

            let! sourceRoot =
                match sourceRoot with
                | Some value -> Ok value
                | None -> Error ProfileDataError.NotFound

            let! targetRoot = SaveGroupSource.profileRoot scope

            if
                action = ProfileSaveAction.CopyToProfile
                && sourceRoot.Identity = targetRoot.Identity
            then
                return!
                    Error(
                        ProfileDataError.Invalid "The global and profile save folders are the same."
                    )

            let! groups =
                selected
                |> ProfileDataResultFlow.traverse (fun name ->
                    SaveGroupInspection.observe sourceRoot name token)

            let names = targetNames action targetRoot

            if names.Length > 1000000 then
                return!
                    Error(
                        ProfileDataError.Unavailable
                            "The profile save folder exceeds one million entries."
                    )

            let collision name =
                names |> List.exists (SaveGroupSource.same name)

            let! files =
                groups
                |> ProfileDataResultFlow.traverse (filesForGroup action targetRoot collision)
                |> Result.map List.concat

            let! binding = SaveGroupSource.title scope

            let destination =
                if action = ProfileSaveAction.CopyToProfile then
                    Some
                        { HostPath = HostPath.value targetRoot.Path
                          WindowsPath = None }
                else
                    None

            let shownFiles =
                groups
                |> List.collect (fun group -> group.Save :: (group.Companion |> Option.toList))
                |> List.map (fun file ->
                    { Name = file.Name
                      Bytes = file.File.Length })

            return
                { PreviewId = previewId
                  Action = action
                  ContextFingerprint = binding.Evidence.Fingerprint
                  Files = files },
                sourcePath,
                destination,
                shownFiles
        }

    let private checkFiles (receipt: SaveActionReceipt) token =
        let grouped = receipt.Files |> List.groupBy _.Target

        for target, files in grouped do
            use folder = HeldDirectory.Open(target.Path, target.Identity)

            for file in files do
                DataFiles.check folder file.Name file.Before token

                file.Source
                |> Option.iter (fun source ->
                    use sourceRoot = HeldDirectory.Open(source.Root.Path, source.Root.Identity)
                    DataFiles.check sourceRoot source.Name (Some source.File) token)

    let checkReceipt scope (receipt: SaveActionReceipt) token =
        result {
            let! binding = SaveGroupSource.title scope

            if binding.Evidence.Fingerprint <> receipt.ContextFingerprint then
                return! Error ProfileDataError.Stale

            checkFiles receipt token
            return ()
        }
