namespace ModConductor.Persistence

open System
open System.Collections.Generic
open System.IO
open System.IO.Compression
open System.Security.Cryptography

module internal ProfileTransportZip =
    let private timestamp = DateTimeOffset(1980, 1, 1, 0, 0, 0, TimeSpan.Zero)
    let private limit = 64L * 1024L * 1024L * 1024L

    let private referenced (profile: PortableProfile) =
        [ for value in profile.Mods do
              yield! value.Files
          yield! profile.Settings
          yield! profile.Saves
          yield! profile.Artwork |> Option.toList ]
        |> List.map (fun file ->
            match file.Content with
            | PortableContent.Payload(memberName, _, _)
            | PortableContent.Patch(memberName, _, _, _) -> memberName)

    let private invalid () =
        raise (InvalidDataException "The profile ZIP is invalid.")

    let private checkMembers (zip: ZipArchive) (profile: PortableProfile) =
        let expected = "profile.json" :: referenced profile
        let actual = zip.Entries |> Seq.map _.FullName |> Seq.toList

        if
            actual.Length <> (actual |> List.distinct).Length
            || expected.Length <> (expected |> List.distinct).Length
            || Set.ofList actual <> Set.ofList expected
            || zip.Entries
               |> Seq.exists (fun entry -> entry.Length < 0L || entry.Length > limit)
        then
            invalid ()

    let private copyBounded (source: Stream) (target: Stream) length =
        let buffer = Array.zeroCreate<byte> 65536
        let mutable total = 0L
        let mutable reading = true

        while reading do
            let count = source.Read(buffer, 0, buffer.Length)

            if count = 0 then
                reading <- false
            else
                total <- total + int64 count

                if total > length then
                    invalid ()

                target.Write(buffer, 0, count)

        if total <> length then
            invalid ()

    let write destination (profile: PortableProfile) (content: Map<string, string>) =
        let metadata = ProfileTransportJson.write profile
        let members = referenced profile |> List.sort

        if
            members.Length <> (members |> List.distinct).Length
            || Set.ofList members <> (content |> Map.keys |> Set.ofSeq)
        then
            invalid ()

        if File.Exists destination then
            raise (
                InvalidDataException
                    "Choose a new .mcprof file name. The existing file was not changed."
            )

        let folder = Path.GetDirectoryName(Path.GetFullPath destination)
        let temporary = Path.Combine(folder, "." + Guid.NewGuid().ToString("N") + ".mcprof")

        try
            let create () =
                use output =
                    new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None)

                use zip = new ZipArchive(output, ZipArchiveMode.Create, leaveOpen = true)

                let add name compression (source: Stream) =
                    let entry = zip.CreateEntry(name, compression)
                    entry.LastWriteTime <- timestamp
                    entry.ExternalAttributes <- 0
                    use target = entry.Open()
                    source.CopyTo target

                use json = new MemoryStream(metadata, writable = false)
                add "profile.json" CompressionLevel.Optimal json

                for name in members do
                    let file = content[name]
                    use source = File.OpenRead file
                    add name CompressionLevel.NoCompression source

                zip.Dispose()
                output.Flush(true)

            create ()
            File.Move(temporary, destination)
        finally
            if File.Exists temporary then
                File.Delete temporary

    type Bundle(path: string) =
        let zip = ZipFile.OpenRead path

        let profile =
            try
                let entry = zip.GetEntry "profile.json"

                if isNull entry || entry.Length > 16L * 1024L * 1024L then
                    invalid ()

                use source = entry.Open()
                use bytes = new MemoryStream()
                copyBounded source bytes entry.Length
                let value = ProfileTransportJson.read (bytes.ToArray())
                checkMembers zip value
                value
            with error ->
                zip.Dispose()
                raise error

        member _.Profile = profile

        member _.Copy(memberName: string, destination: string, expectedSha: string option) =
            let entry = zip.GetEntry memberName

            if isNull entry || File.Exists destination then
                invalid ()

            use source = entry.Open()

            use target =
                new FileStream(
                    destination,
                    FileMode.CreateNew,
                    FileAccess.ReadWrite,
                    FileShare.None
                )

            copyBounded source target entry.Length
            target.Flush(true)

            match expectedSha with
            | Some expected ->
                target.Position <- 0L
                let observed = SHA256.HashData target |> Convert.ToHexStringLower

                if not (String.Equals(expected, observed, StringComparison.OrdinalIgnoreCase)) then
                    raise (InvalidDataException "The profile payload changed.")
            | None -> ()

        interface IDisposable with
            member _.Dispose() = zip.Dispose()
