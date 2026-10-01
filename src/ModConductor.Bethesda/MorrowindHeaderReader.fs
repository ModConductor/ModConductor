namespace ModConductor.Bethesda

open System
open System.IO
open System.Text
open System.Threading

module internal MorrowindHeaderReader =
    let private text (bytes: byte array) =
        let zero = Array.IndexOf(bytes, 0uy)
        PluginText.decode (if zero < 0 then bytes else bytes[.. zero - 1])

    let read (name: string) (stream: Stream) (token: CancellationToken) =
        try
            use reader = new BinaryReader(stream, Encoding.UTF8, true)

            let tag () =
                Encoding.ASCII.GetString(reader.ReadBytes 4)

            if stream.Length < 16L || tag () <> "TES3" then
                Error(HeaderError.Unsupported "This file has no supported TES3 header.")
            else
                let length = int64 (reader.ReadUInt32())
                reader.ReadUInt32() |> ignore
                let flags = reader.ReadUInt32()
                let finish = 16L + length

                if length > 8L * 1024L * 1024L then
                    Error(HeaderError.Limit "The TES3 header exceeds the 8 MiB read limit.")
                elif finish > stream.Length then
                    Error(HeaderError.Malformed "The TES3 header ends before its declared size.")
                else
                    let mutable header = None
                    let mutable problem = None
                    let masters = ResizeArray<string>()

                    while problem.IsNone && stream.Position < finish do
                        token.ThrowIfCancellationRequested()

                        if finish - stream.Position < 8L then
                            problem <- Some "A TES3 header subrecord is incomplete."
                        else
                            let signature, size = tag (), int64 (reader.ReadUInt32())
                            let next = stream.Position + size

                            if next > finish then
                                problem <- Some "A TES3 subrecord extends past the header."
                            else
                                match signature with
                                | "HEDR" when size = 300L && header.IsNone ->
                                    let version = reader.ReadSingle()
                                    reader.ReadUInt32() |> ignore
                                    let author = text (reader.ReadBytes 32)
                                    let description = text (reader.ReadBytes 256)
                                    let records = reader.ReadUInt32()
                                    header <- Some(version, author, description, records)
                                | "HEDR" -> problem <- Some "The TES3 HEDR subrecord is invalid."
                                | "MAST" when size > 0L && size <= 65536L ->
                                    let master = text (reader.ReadBytes(int size))

                                    if
                                        String.IsNullOrWhiteSpace master
                                        || master.IndexOfAny([| '/'; '\\' |]) >= 0
                                    then
                                        problem <- Some "A master name is not a file name."
                                    else
                                        masters.Add master
                                | "MAST" -> problem <- Some "The TES3 master name is invalid."
                                | _ -> ()

                                stream.Position <- next

                    match problem, header with
                    | Some message, _ -> Error(HeaderError.Malformed message)
                    | None, None ->
                        Error(HeaderError.Malformed "The TES3 header has no HEDR subrecord.")
                    | None, Some(version, author, description, records) ->
                        let extension = Path.GetExtension(name).ToLowerInvariant()

                        Ok
                            { Extension = extension
                              Flags = flags
                              FormVersion = 0us
                              HeaderVersion = version
                              DeclaredRecords = records
                              Kind =
                                if extension = ".esm" then
                                    PluginKind.Master
                                else
                                    PluginKind.Plugin
                              Localized = false
                              Author = Some author
                              Description = Some description
                              Masters = List.ofSeq masters }
        with
        | :? EndOfStreamException -> Error(HeaderError.Malformed "The TES3 header is incomplete.")
        | :? IOException as error -> Error(HeaderError.Unavailable error.Message)
