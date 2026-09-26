namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ArtifactLibrary
open ModConductor.Fnis
open ModConductor.Nexus

type internal StoredFnisSelection =
    { ArtifactId: Guid option
      WorkspaceId: Guid
      ProfileId: Guid option
      AccountId: string
      Selection: FnisSelection
      CheckedAt: DateTimeOffset }

type internal StoredFnisStatus =
    { WorkspaceId: Guid
      ProfileId: Guid
      Phase: string
      ComponentVersion: string
      Status: string
      Detail: string
      NexusFileId: int64 option
      ArtifactId: Guid option
      CheckedAt: DateTimeOffset }

type internal StoredFnisGenerator =
    { GenerationId: Guid
      ModId: Guid
      VersionId: Guid
      ArtifactId: Guid
      FileName: string
      FileVersion: string
      Executable: string
      ComponentVersion: string
      ArchiveSha256: string
      Provider: string
      Source: string
      Terms: string
      NexusModId: int64
      NexusFileId: int64
      AcquiredAt: DateTimeOffset }

module internal FnisRows =
    let private acquisition =
        function
        | 0L -> FnisAcquisition.Direct
        | 1L -> FnisAcquisition.NexusPage
        | _ -> invalidOp "The saved FNIS acquisition route is invalid."

    let private acquisitionValue =
        function
        | FnisAcquisition.Direct -> 0
        | FnisAcquisition.NexusPage -> 1

    let private optionalInt64 (reader: SqliteDataReader) index =
        if reader.IsDBNull index then
            None
        else
            Some(reader.GetInt64 index)

    let readSelection (reader: SqliteDataReader) artifact profile =
        let file =
            { Id = reader.GetInt64 3
              Name = reader.GetString 4
              Version = reader.GetString 5
              Category = reader.GetString 6
              Description = reader.GetString 7
              Bytes = optionalInt64 reader 8 }

        { ArtifactId = artifact
          WorkspaceId = Guid.Parse(reader.GetString 0)
          ProfileId = profile
          AccountId = reader.GetString 1
          Selection =
            { Release =
                { ModId = reader.GetInt64 2
                  File = file
                  ComponentVersion = Version.Parse(reader.GetString 9) }
              Acquisition = acquisition (reader.GetInt64 10) }
          CheckedAt = DateTimeOffset.Parse(reader.GetString 13) }

    let selectionParameters (value: StoredFnisSelection) =
        let release = value.Selection.Release

        [ "$workspace", box (string value.WorkspaceId)
          "$account", box value.AccountId
          "$nexusMod", box release.ModId
          "$nexusFile", box release.File.Id
          "$name", box release.File.Name
          "$fileVersion", box release.File.Version
          "$category", box release.File.Category
          "$description", box release.File.Description
          "$bytes", release.File.Bytes |> Option.map box |> Option.defaultValue (box DBNull.Value)
          "$component", box (string release.ComponentVersion)
          "$acquisition", box (acquisitionValue value.Selection.Acquisition)
          "$source", box FnisCatalogue.Source
          "$terms", box FnisCatalogue.Terms
          "$checked", box (value.CheckedAt.ToString("O")) ]
