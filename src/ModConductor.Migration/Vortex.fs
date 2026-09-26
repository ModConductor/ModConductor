namespace ModConductor.Migration

open System
open System.IO
open System.Threading
open ModConductor.ModLibrary

module Vortex =
    type ProfileChoice =
        { Id: string
          Name: string
          GameId: string }

    type Request =
        { WorkspaceId: Guid
          BackupFile: string
          ProfileId: string
          StagingRoot: string
          DownloadRoot: string }

    open VortexSource
    open VortexJson
    open VortexProfiles
    open VortexMods
    open VortexOrder
    open VortexDownloads

    let profiles backup =
        try
            readProfiles backup
            |> List.map (fun (id, name, gameId) ->
                { Id = id
                  Name = name
                  GameId = gameId })
            |> Ok
        with
        | Refused error -> Error error
        | :? IOException as error -> Error(Error.Unavailable error.Message)
        | :? UnauthorizedAccessException ->
            Error(Error.Unavailable "The Vortex backup file is unavailable.")

    let private readSource (request: Request) =
        let backup = directFile request.BackupFile "Vortex backup file"
        use parsed = document backup
        let root = parsed.RootElement
        backupVersion root
        let persistent = property "persistent" root

        let profile =
            profileEntries root
            |> List.tryFind (fun item -> item.Name = request.ProfileId)
            |> Option.map _.Value
            |> Option.defaultWith (fun () ->
                invalid "Choose a profile from the selected Vortex backup.")

        if tryBoolean "pendingRemove" profile = Some true then
            unsupported "The selected Vortex profile is being removed."

        let profileId = text "id" profile

        if profileId <> request.ProfileId then
            invalid "The selected Vortex profile ID does not match its backup key."

        let stagingRoot, stagingEntries, stagingManifest =
            scanRoot request.StagingRoot "Vortex staging folder"

        let downloadRoot, downloadEntries, downloadManifest =
            scanRoot request.DownloadRoot "Vortex download folder"

        let parsedMods, modStamps, gameId =
            parseMods persistent profile stagingRoot stagingEntries

        let categories = categories persistent gameId
        let knownCategories = categories |> List.map _.SourceId |> Set.ofList

        parsedMods
        |> List.collect (fun (item, _) -> item.CategorySourceIds)
        |> List.tryFind (fun id -> not (knownCategories.Contains id))
        |> Option.iter (fun id -> invalid ("A mod uses missing category " + string id + "."))

        let positions = orderedMods persistent profileId parsedMods

        let artifacts, artifactStamps =
            artifacts persistent gameId downloadRoot downloadEntries parsedMods

        let directMods: Direct.Mod list =
            parsedMods
            |> List.map (fun (item, _) ->
                { Id = item.Id
                  VersionId = item.VersionId
                  Kind = ModKind.Regular
                  Metadata = item.Metadata
                  CategorySourceIds = item.CategorySourceIds
                  Files = item.Files })

        let profileGuid = Guid.NewGuid()

        let verifySource (token: CancellationToken) =
            try
                token.ThrowIfCancellationRequested()
                verify backup
                verifyManifest stagingManifest "Vortex staging folder"
                token.ThrowIfCancellationRequested()
                verifyManifest downloadManifest "Vortex download folder"

                for stamp in modStamps @ artifactStamps do
                    token.ThrowIfCancellationRequested()
                    verify stamp

                Ok()
            with Refused error ->
                Error error

        let source: Direct.Input =
            { Categories = categories
              Mods = directMods
              Profiles =
                [ { Id = profileGuid
                    Name = profileName profile
                    Mods = positions } ]
              SelectedProfile = profileGuid
              Artifacts = artifacts
              Verify = verifySource }

        source

    let private directSource request =
        try
            Ok(readSource request)
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
            (fun () -> directSource request)
            progress
            token
            checkpoint

    let migrate store request progress token =
        migrateAtCheckpoint store request progress token ignore
