namespace ModConductor.Persistence

open System.IO
open ModConductor.ProfileGameData

module internal ProfileDataEncoding =
    open ProfileDataValueEncoding

    let context =
        encode (fun writer (value: ProfileDataContext) ->
            guid writer value.Id
            guid writer value.WorkspaceId
            writer.Write value.Revision
            root writer value.Workspace
            root writer value.Documents
            option root writer value.Storage
            option root writer value.OriginalsRoot
            option applied writer value.Applied
            option guid writer value.Pending
            option root writer value.PluginRoot
            option root writer value.PluginOriginals
            option (option stored) writer value.PluginObserved)

    let readContext =
        decode (fun version reader ->
            { Id = readGuid reader
              WorkspaceId = readGuid reader
              Revision = reader.ReadInt64()
              Workspace = readRoot reader
              Documents = readRoot reader
              Storage = readOption readRoot reader
              OriginalsRoot = readOption readRoot reader
              Applied = readOption (readApplied version) reader
              Pending = readOption readGuid reader
              PluginRoot = if version >= 2 then readOption readRoot reader else None
              PluginOriginals = if version >= 2 then readOption readRoot reader else None
              PluginObserved =
                if version >= 2 then
                    readOption (readOption readStored) reader
                else
                    None }
            : ProfileDataContext)

    let profile =
        encode (fun writer (value: PrivateProfileData) ->
            guid writer value.ProfileId
            writer.Write value.Revision
            options writer value.Options
            option root writer value.Root
            option root writer value.Settings
            option root writer value.Saves
            writer.Write value.SettingsInitialized
            writer.Write value.SavesInitialized
            option pluginOrder writer value.PluginOrder)

    let readProfile =
        decode (fun version reader ->
            { ProfileId = readGuid reader
              Revision = reader.ReadInt64()
              Options = readOptions reader
              Root = readOption readRoot reader
              Settings = readOption readRoot reader
              Saves = readOption readRoot reader
              SettingsInitialized = reader.ReadBoolean()
              SavesInitialized = reader.ReadBoolean()
              PluginOrder =
                if version >= 2 then
                    readOption readPluginOrder reader
                else
                    None }
            : PrivateProfileData)

    let private change writer (value: ProfileDataFilesEffect) =
        root writer value.Target
        root writer value.Backups
        text writer value.Change.Name
        option file writer value.Change.Before
        option stored writer value.Change.Replacement
        text writer value.Change.BackupName

    let private readChange reader : ProfileDataFilesEffect =
        { Target = readRoot reader
          Backups = readRoot reader
          Change =
            { Name = readText reader
              Before = readOption readFile reader
              Replacement = readOption readStored reader
              BackupName = readText reader } }

    let private link (writer: BinaryWriter) =
        function
        | SaveLinkEffect.Unchanged -> writer.Write 0
        | SaveLinkEffect.Remove value ->
            writer.Write 1
            identity writer value
        | SaveLinkEffect.Create value ->
            writer.Write 2
            root writer value
        | SaveLinkEffect.Replace(previous, value) ->
            writer.Write 3
            identity writer previous
            root writer value

    let private readLink (reader: BinaryReader) =
        match reader.ReadInt32() with
        | 0 -> SaveLinkEffect.Unchanged
        | 1 -> SaveLinkEffect.Remove(readIdentity reader)
        | 2 -> SaveLinkEffect.Create(readRoot reader)
        | 3 ->
            let previous = readIdentity reader
            SaveLinkEffect.Replace(previous, readRoot reader)
        | _ -> invalid ()

    let private kind (writer: BinaryWriter) =
        function
        | ProfileDataActionKind.Edit(value, initial, files) ->
            writer.Write 0
            options writer value

            writer.Write(
                match initial with
                | InitialSaves.Empty -> 0
                | InitialSaves.CopyGlobal -> 1
            )

            writer.Write(
                match files with
                | DisabledFiles.Keep -> 0
                | DisabledFiles.Delete -> 1
            )
        | ProfileDataActionKind.Apply -> writer.Write 1
        | ProfileDataActionKind.Restore -> writer.Write 2
        | ProfileDataActionKind.Clone(target, name, revision) ->
            writer.Write 3
            guid writer target
            text writer name
            writer.Write revision
        | ProfileDataActionKind.Delete revision ->
            writer.Write 4
            writer.Write revision

    let private readKind (reader: BinaryReader) =
        match reader.ReadInt32() with
        | 0 ->
            let value = readOptions reader

            let initial =
                match reader.ReadInt32() with
                | 0 -> InitialSaves.Empty
                | 1 -> InitialSaves.CopyGlobal
                | _ -> invalid ()

            let files =
                match reader.ReadInt32() with
                | 0 -> DisabledFiles.Keep
                | 1 -> DisabledFiles.Delete
                | _ -> invalid ()

            ProfileDataActionKind.Edit(value, initial, files)
        | 1 -> ProfileDataActionKind.Apply
        | 2 -> ProfileDataActionKind.Restore
        | 3 ->
            let id = readGuid reader
            let name = readText reader
            ProfileDataActionKind.Clone(id, name, reader.ReadInt64())
        | 4 -> ProfileDataActionKind.Delete(reader.ReadInt64())
        | _ -> invalid ()

    let private writePrivate (writer: BinaryWriter) value =
        let bytes = profile value
        writer.Write bytes.Length
        writer.Write bytes

    let private readPrivate (reader: BinaryReader) =
        let length = reader.ReadInt32()

        if length < 0 || length > 16 * 1024 * 1024 then
            invalid ()

        readProfile (reader.ReadBytes length)

    let private directory writer (value: ProfileDataDirectoryRemoval) =
        root writer value.Parent
        text writer value.Name
        identity writer value.Identity

    let private readDirectory reader : ProfileDataDirectoryRemoval =
        { Parent = readRoot reader
          Name = readText reader
          Identity = readIdentity reader }

    let private deletion writer (value: ProfileDataDeletion) =
        list stored writer value.Files
        list directory writer value.Directories
        writer.Write value.CompletedFiles
        writer.Write value.CompletedDirectories

    let private readDeletion reader : ProfileDataDeletion =
        { Files = readList readStored reader
          Directories = readList readDirectory reader
          CompletedFiles = reader.ReadInt32()
          CompletedDirectories = reader.ReadInt32() }

    let action =
        encode (fun writer (value: ProfileDataActionRecord) ->
            guid writer value.Id
            guid writer value.ContextId
            guid writer value.ProfileId
            writer.Write value.ExpectedRevision
            kind writer value.Kind
            option deletion writer value.Deletion
            option writePrivate writer value.CloneTarget
            writer.Write value.Prepared
            option root writer value.WorkspaceStage
            option root writer value.DocumentsStage
            list change writer value.Files
            writer.Write value.CompletedFiles
            link writer value.Link
            writer.Write value.LinkRemoved
            option identity writer value.LinkCreated
            option applied writer value.Proposed
            writer.Write value.Complete
            option text writer value.Problem
            option root writer value.PluginStage)

    let readAction =
        decode (fun version reader ->
            { Id = readGuid reader
              ContextId = readGuid reader
              ProfileId = readGuid reader
              ExpectedRevision = reader.ReadInt64()
              Kind = readKind reader
              Deletion = readOption readDeletion reader
              CloneTarget = readOption readPrivate reader
              Prepared = reader.ReadBoolean()
              WorkspaceStage = readOption readRoot reader
              DocumentsStage = readOption readRoot reader
              Files = readList readChange reader
              CompletedFiles = reader.ReadInt32()
              Link = readLink reader
              LinkRemoved = reader.ReadBoolean()
              LinkCreated = readOption readIdentity reader
              Proposed = readOption (readApplied version) reader
              Complete = reader.ReadBoolean()
              Problem = readOption readText reader
              PluginStage = if version >= 2 then readOption readRoot reader else None }
            : ProfileDataActionRecord)
