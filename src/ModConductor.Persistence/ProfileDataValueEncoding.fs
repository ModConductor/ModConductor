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

    let original writer (value: GlobalIni) =
        text writer value.Name
        option stored writer value.Original

    let readOriginal reader : GlobalIni =
        { Name = readText reader
          Original = readOption readStored reader }

    let applied writer (value: AppliedProfileData) =
        guid writer value.ProfileId
        options writer value.Options
        list original writer value.Originals
        option patch writer value.SaveOverride
        option identity writer value.SaveLink

    let readApplied reader : AppliedProfileData =
        { ProfileId = readGuid reader
          Options = readOptions reader
          Originals = readList readOriginal reader
          SaveOverride = readOption readPatch reader
          SaveLink = readOption readIdentity reader }

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
            invalid ()

        let value = read reader

        if stream.Position <> stream.Length then
            invalid ()

        value
