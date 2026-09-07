namespace ModConductor.GameContexts

open System
open System.Buffers.Binary
open System.IO
open System.Text

module internal PeVersion =
    let private invalid () =
        raise (InvalidDataException("The executable has invalid or unsupported version data."))

    let read (stream: FileStream) =
        let length = stream.Length

        let read offset count =
            if offset < 0L || count < 0 || int64 count > length - offset then
                invalid ()

            let bytes = Array.zeroCreate<byte> count
            stream.Position <- offset
            stream.ReadExactly bytes
            bytes

        let u16 (bytes: byte array) offset =
            if offset < 0 || offset > bytes.Length - 2 then
                invalid ()

            BinaryPrimitives.ReadUInt16LittleEndian(bytes.AsSpan(offset, 2))

        let u32 (bytes: byte array) offset =
            if offset < 0 || offset > bytes.Length - 4 then
                invalid ()

            BinaryPrimitives.ReadUInt32LittleEndian(bytes.AsSpan(offset, 4))

        let dos = read 0L 64

        if u16 dos 0 <> 0x5A4Dus then
            invalid ()

        let pe = int64 (u32 dos 60)
        let header = read pe 24

        if u32 header 0 <> 0x4550u || u16 header 4 <> 0x8664us then
            invalid ()

        let count = int (u16 header 6)
        let optionalSize = int (u16 header 20)

        if count < 1 || count > 96 || optionalSize < 136 || optionalSize > 4096 then
            invalid ()

        let optional = read (pe + 24L) optionalSize

        if u16 optional 0 <> 0x20Bus || u32 optional 108 < 3u then
            invalid ()

        let resourceRva = int64 (u32 optional 128)
        let resourceSize = int64 (u32 optional 132)

        if resourceRva = 0L || resourceSize < 16L || resourceSize > 16L * 1024L * 1024L then
            invalid ()

        let sections = read (pe + 24L + int64 optionalSize) (count * 40)

        let map rva size =
            let matches =
                [ for i in 0 .. count - 1 do
                      let position = i * 40
                      let start = int64 (u32 sections (position + 12))
                      let rawSize = int64 (u32 sections (position + 16))
                      let raw = int64 (u32 sections (position + 20))
                      let delta = rva - start

                      if delta >= 0L && size <= rawSize - delta then
                          let offset = raw + delta

                          if offset < 0L || size > length - offset then
                              invalid ()

                          yield offset ]

            match matches with
            | [ offset ] -> offset
            | _ -> invalid ()

        let resource = read (map resourceRva resourceSize) (int resourceSize)
        let versions = ResizeArray<string * string>()
        let visited = System.Collections.Generic.HashSet<int>()
        let mutable entries = 0

        let boundedOffset value =
            if value > uint32 Int32.MaxValue then
                invalid ()

            int value

        let version rva size =
            if size < 92u || size > 65536u then
                invalid ()

            let bytes = read (map (int64 rva) (int64 size)) (int size)
            let total = int (u16 bytes 0)

            if total < 92 || total > bytes.Length || u16 bytes 2 <> 52us || u16 bytes 4 <> 0us then
                invalid ()

            let key = Encoding.Unicode.GetString(bytes, 6, 32)

            if
                key <> "VS_VERSION_INFO\000"
                || u32 bytes 40 <> 0xFEEF04BDu
                || u32 bytes 44 <> 0x10000u
            then
                invalid ()

            let number offset =
                let high, low = u32 bytes offset, u32 bytes (offset + 4)
                String.Join(".", [| high >>> 16; high &&& 65535u; low >>> 16; low &&& 65535u |])

            versions.Add(number 48, number 56)

        let rec directory offset depth =
            if depth > 2 || not (visited.Add offset) then
                invalid ()

            let named = int (u16 resource (offset + 12))
            let ids = int (u16 resource (offset + 14))
            let total = named + ids
            entries <- entries + total

            if
                entries > 4096
                || offset < 0
                || offset > resource.Length - 16
                || total > (resource.Length - offset - 16) / 8
            then
                invalid ()

            for i in 0 .. total - 1 do
                let pos = offset + 16 + i * 8
                let name = u32 resource pos
                let target = u32 resource (pos + 4)

                if depth > 0 || name = 16u then
                    let child = boundedOffset (target &&& 0x7FFFFFFFu)

                    if target &&& 0x80000000u <> 0u then
                        directory child (depth + 1)
                    elif depth = 2 then
                        let rva, size = u32 resource child, u32 resource (child + 4)

                        if child > resource.Length - 16 then
                            invalid ()

                        version rva size
                    else
                        invalid ()

        directory 0 0

        match versions |> Seq.distinct |> Seq.toList with
        | [ value ] -> value
        | _ -> invalid ()
