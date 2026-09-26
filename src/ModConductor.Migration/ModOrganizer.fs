namespace ModConductor.Migration

open System
open System.IO
open System.Threading

module ModOrganizer =
    open ModOrganizerInput
    open ModOrganizerSettings
    open ModOrganizerMods
    open ModOrganizerProfiles
    open ModOrganizerDownloads

    let private readSource folder =
        let sourceFolder = Path.GetFullPath folder
        let iniPath = Path.Combine(sourceFolder, "ModOrganizer.ini")

        if not (File.Exists iniPath) then
            refuse (
                Error.InvalidSource "Choose a Mod Organizer folder that contains ModOrganizer.ini."
            )

        let iniStamp = directFile iniPath
        let settings = ini (text iniStamp)
        let basePath = path sourceFolder sourceFolder "base_directory" settings

        let modsPath = path basePath "mods" "mod_directory" settings
        let profilesPath = path basePath "profiles" "profiles_directory" settings
        let downloadsPath = path basePath "downloads" "download_directory" settings
        let selected = setting "General" "selected_profile" "" settings

        if String.IsNullOrWhiteSpace selected then
            refuse (Error.InvalidSource "ModOrganizer.ini does not select a profile.")

        let categories, categoryStamps, categoryAbsent =
            readCategories sourceFolder basePath

        let modsRoot, modEntries, modsManifest = scanRoot modsPath
        let mods, modStamps, installationFiles, installedIds = readMods modsRoot modEntries
        let profileRoot, profileEntries, profilesManifest = scanRoot profilesPath

        let profiles, selectedProfile, profileStamps =
            readProfiles profileRoot profileEntries mods selected

        let artifacts, artifactStamps, downloadManifest, downloadAbsent =
            if pathExists downloadsPath then
                let downloadRoot, downloadEntries, manifest = scanRoot downloadsPath

                let artifacts, stamps =
                    readArtifacts downloadRoot downloadEntries installationFiles installedIds

                artifacts, stamps, Some manifest, []
            else
                [], [], None, [ downloadsPath ]

        let knownCategories = categories |> List.map _.SourceId |> Set.ofList

        mods
        |> List.collect _.CategorySourceIds
        |> List.tryFind (fun id -> not (knownCategories.Contains id))
        |> Option.iter (fun id ->
            refuse (Error.InvalidSource("A mod uses missing category " + string id + ".")))

        { Categories = categories
          Mods = mods
          Profiles = profiles
          SelectedProfile = selectedProfile
          Artifacts = artifacts
          Stamps = iniStamp :: (categoryStamps @ modStamps @ profileStamps @ artifactStamps)
          Manifests = modsManifest :: profilesManifest :: (downloadManifest |> Option.toList)
          AbsentPaths = categoryAbsent @ downloadAbsent }

    let private directSource folder =
        try
            let source = readSource folder

            let mods: Direct.Mod list =
                source.Mods
                |> List.map (fun (item: SourceMod) ->
                    { Id = item.Id
                      VersionId = item.VersionId
                      Kind = item.Kind
                      Metadata = item.Metadata
                      CategorySourceIds = item.CategorySourceIds
                      Files = item.Files |> List.map transferFile })

            let profiles: Direct.Profile list =
                source.Profiles
                |> List.map (fun (item: SourceProfile) ->
                    { Id = item.Id
                      Name = item.Name
                      Mods = item.Mods })

            let artifacts: Direct.Artifact list =
                source.Artifacts
                |> List.map (fun (item: SourceArtifact) ->
                    { Id = item.Id
                      OriginalName = item.OriginalName
                      OriginalPath = item.OriginalPath
                      File = transferFile item.File
                      Partial = item.Partial
                      Sources = item.Sources
                      InstalledMod = item.InstalledMod })

            let verifySource (token: CancellationToken) =
                try
                    for manifest in source.Manifests do
                        token.ThrowIfCancellationRequested()
                        verifyManifest manifest

                    for path in source.AbsentPaths do
                        token.ThrowIfCancellationRequested()

                        if pathExists path then
                            refuse Error.SourceChanged

                    for stamp in source.Stamps do
                        token.ThrowIfCancellationRequested()
                        verify stamp

                    Ok()
                with Refused error ->
                    Error error

            let direct: Direct.Input =
                { Categories = source.Categories
                  Mods = mods
                  Profiles = profiles
                  SelectedProfile = source.SelectedProfile
                  Artifacts = artifacts
                  Verify = verifySource }

            Ok direct
        with Refused error ->
            Error error

    let internal migrateAtCheckpoint
        (store: IStore)
        (request: Request)
        (progress: Progress -> unit)
        (token: CancellationToken)
        checkpoint
        =
        Direct.migrateAtCheckpoint
            store
            request.WorkspaceId
            (fun () -> directSource request.SourceFolder)
            progress
            token
            checkpoint

    let migrate store request progress token =
        migrateAtCheckpoint store request progress token ignore
