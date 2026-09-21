namespace ModConductor.Persistence

open System
open System.IO
open System.Text
open ModConductor.Platform
open ModConductor.ProfileGameData

module internal ProfileDataValueEncoding =
    let invalid () =
        raise (InvalidDataException "The profile settings record is invalid.")

    let text (writer: BinaryWriter) (value: string) = writer.Write value
    let readText (reader: BinaryReader) = reader.ReadString()
    let guid (writer: BinaryWriter) (value: Guid) = writer.Write(value.ToByteArray())

    let readGuid (reader: BinaryReader) =
        let bytes = reader.ReadBytes 16

        if bytes.Length <> 16 then
            invalid ()

        Guid bytes

    let option write (writer: BinaryWriter) value =
        writer.Write(Option.isSome value)
        value |> Option.iter (write writer)

    let readOption read (reader: BinaryReader) =
        if reader.ReadBoolean() then Some(read reader) else None

    let list write (writer: BinaryWriter) values =
        writer.Write(List.length values)
        values |> List.iter (write writer)

    let readList read (reader: BinaryReader) =
        let count = reader.ReadInt32()

        if count < 0 || count > 1000000 then
            invalid ()

        [ for _ in 1..count -> read reader ]

    let identity writer value =
        text writer (LibraryEncoding.identity value)

    let readIdentity reader =
        readText reader |> LibraryEncoding.readIdentity

    let root writer (value: DataRoot) =
        text writer (HostPath.value value.Path)
        identity writer value.Identity

    let readRoot reader : DataRoot =
        { Path = readText reader |> HostPath.create |> Result.defaultWith (fun _ -> invalid ())
          Identity = readIdentity reader }

    let file (writer: BinaryWriter) (value: DataFile) =
        identity writer value.Identity
        writer.Write value.Length
        text writer value.Sha256

    let readFile (reader: BinaryReader) : DataFile =
        { Identity = readIdentity reader
          Length = reader.ReadInt64()
          Sha256 = readText reader }

    let stored writer (value: StoredDataFile) =
        root writer value.Root
        text writer value.Name
        file writer value.File

    let readStored reader : StoredDataFile =
        { Root = readRoot reader
          Name = readText reader
          File = readFile reader }

    let options (writer: BinaryWriter) (value: ProfileDataOptions) =
        writer.Write value.Settings
        writer.Write value.Saves

    let readOptions (reader: BinaryReader) : ProfileDataOptions =
        { Settings = reader.ReadBoolean()
          Saves = reader.ReadBoolean() }

    let patch (writer: BinaryWriter) (value: SavePathOverride) =
        text writer value.Value
        option text writer value.PreviousLine
        writer.Write value.AddedSection
        writer.Write value.AddedSeparator
        writer.Write value.AbsentFile

    let readPatch (reader: BinaryReader) : SavePathOverride =
        { Value = readText reader
          PreviousLine = readOption readText reader
          AddedSection = reader.ReadBoolean()
          AddedSeparator = reader.ReadBoolean()
          AbsentFile = reader.ReadBoolean() }

    let archiveLine (writer: BinaryWriter) (value: ArchiveLineOverride) =
        text writer value.Key
        text writer value.Value
        option text writer value.PreviousLine

    let readArchiveLine (reader: BinaryReader) : ArchiveLineOverride =
        { Key = readText reader
          Value = readText reader
          PreviousLine = readOption readText reader }

    let archivePatch (writer: BinaryWriter) (value: ArchiveListOverride) =
        list archiveLine writer value.Lines
        writer.Write value.AddedSection

        match value.Separator with
        | IniSeparatorOverride.None -> writer.Write 0
        | IniSeparatorOverride.SectionHeader previous ->
            writer.Write 1
            text writer previous
        | IniSeparatorOverride.FileTail previous ->
            writer.Write 2
            text writer previous

        writer.Write value.AbsentFile

    let readArchivePatch (reader: BinaryReader) : ArchiveListOverride =
        let lines = readList readArchiveLine reader
        let added = reader.ReadBoolean()

        let separator =
            match reader.ReadInt32() with
            | 0 -> IniSeparatorOverride.None
            | 1 -> IniSeparatorOverride.SectionHeader(readText reader)
            | 2 -> IniSeparatorOverride.FileTail(readText reader)
            | _ -> invalid ()

        { Lines = lines
          AddedSection = added
          Separator = separator
          AbsentFile = reader.ReadBoolean() }

    let archiveReceipt (writer: BinaryWriter) (value: ArchiveListReceipt) =
        archivePatch writer value.Profile
        option archivePatch writer value.Documents

    let readArchiveReceipt (reader: BinaryReader) : ArchiveListReceipt =
        { Profile = readArchivePatch reader
          Documents = readOption readArchivePatch reader }

    let sourceStamp (writer: BinaryWriter) (value: ModConductor.FilePlanning.SourceStamp) =
        guid writer value.WorkspaceId
        guid writer value.ProfileId
        writer.Write value.SelectionRevision
        writer.Write value.ContextRevision
        writer.Write value.ExclusionRevision
        writer.Write value.OutputRevision

        list
            (fun writer (modId, version) ->
                guid writer modId
                option guid writer version)
            writer
            value.Versions

        option text writer value.Deployment

    let readSourceStamp (reader: BinaryReader) : ModConductor.FilePlanning.SourceStamp =
        { WorkspaceId = readGuid reader
          ProfileId = readGuid reader
          SelectionRevision = reader.ReadInt64()
          ContextRevision = reader.ReadInt64()
          ExclusionRevision = reader.ReadInt64()
          OutputRevision = reader.ReadInt64()
          Versions = readList (fun reader -> readGuid reader, readOption readGuid reader) reader
          Deployment = readOption readText reader }

    let original writer (value: GlobalIni) =
        text writer value.Name
        option stored writer value.Original

    let readOriginal reader : GlobalIni =
        { Name = readText reader
          Original = readOption readStored reader }

    let pluginOrder (writer: BinaryWriter) (value: ModConductor.Bethesda.PluginOrder) =
        writer.Write value.Document.Length
        writer.Write value.Document

        list
            (fun writer (row: ModConductor.Bethesda.PluginSetting) ->
                text writer row.Name

                option
                    (fun (writer: BinaryWriter) (enabled: bool) -> writer.Write enabled)
                    writer
                    row.Enabled

                option
                    (fun (writer: BinaryWriter) (index: int) -> writer.Write index)
                    writer
                    row.LockedIndex)
            writer
            value.Entries

    let readPluginOrder (reader: BinaryReader) : ModConductor.Bethesda.PluginOrder =
        let count = reader.ReadInt32()

        if count < 0 || count > ModConductor.Bethesda.OrderDocument.maxBytes then
            invalid ()

        let bytes = reader.ReadBytes count

        if bytes.Length <> count then
            invalid ()

        { Document = bytes
          Entries =
            readList
                (fun reader ->
                    { Name = readText reader
                      Enabled =
                        readOption (fun (reader: BinaryReader) -> reader.ReadBoolean()) reader
                      LockedIndex =
                        readOption (fun (reader: BinaryReader) -> reader.ReadInt32()) reader }
                    : ModConductor.Bethesda.PluginSetting)
                reader }

    let appliedPlugins (writer: BinaryWriter) (value: AppliedPluginOrder) =
        option stored writer value.Original
        writer.Write value.ProfileRevision

    let readAppliedPlugins (reader: BinaryReader) : AppliedPluginOrder =
        { Original = readOption readStored reader
          ProfileRevision = reader.ReadInt64() }

    let applied writer (value: AppliedProfileData) =
        guid writer value.ProfileId
        options writer value.Options
        list original writer value.Originals
        option patch writer value.SaveOverride
        option identity writer value.SaveLink
        option appliedPlugins writer value.Plugins

    let readApplied reader : AppliedProfileData =
        { ProfileId = readGuid reader
          Options = readOptions reader
          Originals = readList readOriginal reader
          SaveOverride = readOption readPatch reader
          SaveLink = readOption readIdentity reader
          Plugins = readOption readAppliedPlugins reader }

    let encode write value =
        use stream = new MemoryStream()
        use writer = new BinaryWriter(stream, UTF8Encoding(false, true), true)
        writer.Write 1
        write writer value
        writer.Flush()

        if stream.Length > 16L * 1024L * 1024L then
            invalid ()

        stream.ToArray()

    let decode read (bytes: byte array) =
        if bytes.Length > 16 * 1024 * 1024 then
            invalid ()

        use stream = new MemoryStream(bytes, false)
        use reader = new BinaryReader(stream, UTF8Encoding(false, true), true)

        if reader.ReadInt32() <> 1 then
            raise (InvalidDataException "The profile settings record version is unsupported.")

        let value = read reader

        if stream.Position <> stream.Length then
            invalid ()

        value
