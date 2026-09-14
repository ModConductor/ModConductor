namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.Numerics
open System.Threading

module internal XxHash32 =
    [<Literal>]
    let private P1 = 2654435761u

    [<Literal>]
    let private P2 = 2246822519u

    [<Literal>]
    let private P3 = 3266489917u

    [<Literal>]
    let private P4 = 668265263u

    [<Literal>]
    let private P5 = 374761393u

    let private u32 (bytes: byte[]) offset =
        uint32 bytes[offset]
        ||| (uint32 bytes[offset + 1] <<< 8)
        ||| (uint32 bytes[offset + 2] <<< 16)
        ||| (uint32 bytes[offset + 3] <<< 24)

    let private round accumulator input =
        BitOperations.RotateLeft(accumulator + input * P2, 13) * P1

    type State() =
        let memory = Array.zeroCreate<byte> 16
        let mutable memoryLength = 0
        let mutable total = 0UL
        let mutable v1 = P1 + P2
        let mutable v2 = P2
        let mutable v3 = 0u
        let mutable v4 = 0u - P1

        let stripe bytes offset =
            v1 <- round v1 (u32 bytes offset)
            v2 <- round v2 (u32 bytes (offset + 4))
            v3 <- round v3 (u32 bytes (offset + 8))
            v4 <- round v4 (u32 bytes (offset + 12))

        member _.Update(bytes: byte[], offset: int, count: int) =
            if offset < 0 || count < 0 || offset > bytes.Length - count then
                invalidArg (nameof count) "The hash input range is invalid."

            total <- total + uint64 count
            let mutable source = offset
            let finish = offset + count

            if memoryLength + count < 16 then
                Array.Copy(bytes, source, memory, memoryLength, count)
                memoryLength <- memoryLength + count
            else
                if memoryLength > 0 then
                    let needed = 16 - memoryLength
                    Array.Copy(bytes, source, memory, memoryLength, needed)
                    stripe memory 0
                    source <- source + needed
                    memoryLength <- 0

                while source <= finish - 16 do
                    stripe bytes source
                    source <- source + 16

                memoryLength <- finish - source

                if memoryLength > 0 then
                    Array.Copy(bytes, source, memory, 0, memoryLength)

        member _.Digest() =
            let mutable hash =
                if total >= 16UL then
                    BitOperations.RotateLeft(v1, 1)
                    + BitOperations.RotateLeft(v2, 7)
                    + BitOperations.RotateLeft(v3, 12)
                    + BitOperations.RotateLeft(v4, 18)
                else
                    P5

            hash <- hash + uint32 total
            let mutable offset = 0

            while offset <= memoryLength - 4 do
                hash <- BitOperations.RotateLeft(hash + u32 memory offset * P3, 17) * P4
                offset <- offset + 4

            while offset < memoryLength do
                hash <- BitOperations.RotateLeft(hash + uint32 memory[offset] * P5, 11) * P1
                offset <- offset + 1

            hash <- hash ^^^ (hash >>> 15)
            hash <- hash * P2
            hash <- hash ^^^ (hash >>> 13)
            hash <- hash * P3
            hash ^^^ (hash >>> 16)

    let hash bytes =
        let state = State()
        state.Update(bytes, 0, bytes.Length)
        state.Digest()

/// A bounded decoder for one standard LZ4 frame.
type internal Lz4FrameStream(source: SegmentStream, expected: int64, token: CancellationToken) =
    inherit ReadOnlyStream()

    let invalid () =
        raise (InvalidDataException "The LZ4 frame is malformed.")

    let unsupported () =
        raise (NotSupportedException "This LZ4 frame variant is not supported.")

    let readExact count =
        let bytes = Array.zeroCreate<byte> count
        let mutable offset = 0

        while offset < count do
            token.ThrowIfCancellationRequested()
            let received = source.Read(bytes, offset, count - offset)

            if received = 0 then
                invalid ()

            offset <- offset + received

        bytes

    let readU32 () =
        let value = readExact 4

        uint32 value[0]
        ||| (uint32 value[1] <<< 8)
        ||| (uint32 value[2] <<< 16)
        ||| (uint32 value[3] <<< 24)

    let magic = readU32 ()

    do
        if magic >= 0x184D2A50u && magic <= 0x184D2A5Fu then
            unsupported ()

        if magic <> 0x184D2204u then
            invalid ()

    let descriptorStart = readExact 2
    let flags = descriptorStart[0]
    let blockDescriptor = descriptorStart[1]

    do
        if flags &&& 0xC0uy <> 0x40uy || flags &&& 0x02uy <> 0uy then
            unsupported ()

        if flags &&& 0x01uy <> 0uy then
            unsupported ()

        if blockDescriptor &&& 0x8Fuy <> 0uy then
            unsupported ()

    let independent = flags &&& 0x20uy <> 0uy
    let blockChecksum = flags &&& 0x10uy <> 0uy
    let hasContentSize = flags &&& 0x08uy <> 0uy
    let contentChecksum = flags &&& 0x04uy <> 0uy

    let blockMaximum =
        match (blockDescriptor >>> 4) &&& 0x07uy with
        | 4uy -> 64 * 1024
        | 5uy -> 256 * 1024
        | 6uy -> 1024 * 1024
        | 7uy -> 4 * 1024 * 1024
        | _ -> unsupported ()

    let descriptor = ResizeArray<byte>(descriptorStart)

    let declaredContentSize =
        if hasContentSize then
            let bytes = readExact 8
            descriptor.AddRange bytes
            let mutable value = 0UL

            for i in 0..7 do
                value <- value ||| (uint64 bytes[i] <<< (8 * i))

            Some value
        else
            None

    do
        let checksum = readExact 1

        if checksum[0] <> byte ((XxHash32.hash (descriptor.ToArray()) >>> 8) &&& 0xFFu) then
            invalid ()

        match declaredContentSize with
        | Some value when value <> uint64 expected -> invalid ()
        | _ -> ()

    let contentHash = XxHash32.State()
    let mutable history = Array.empty<byte>
    let mutable block = Array.empty<byte>
    let mutable blockOffset = 0
    let mutable produced = 0L
    let mutable finished = false

    let appendHistory (decoded: byte[]) =
        if independent then
            history <- Array.empty
        elif decoded.Length >= 65536 then
            history <- decoded[decoded.Length - 65536 ..]
        else
            let keep = min history.Length (65536 - decoded.Length)
            let next = Array.zeroCreate<byte> (keep + decoded.Length)

            if keep > 0 then
                Array.Copy(history, history.Length - keep, next, 0, keep)

            Array.Copy(decoded, 0, next, keep, decoded.Length)
            history <- next

    let decodeBlock (encoded: byte[]) =
        let decoded = Array.zeroCreate<byte> blockMaximum
        let mutable input = 0
        let mutable output = 0

        let length initial =
            let mutable value = initial

            if initial = 15 then
                let mutable more = 255

                while more = 255 do
                    if input >= encoded.Length then
                        invalid ()

                    more <- int encoded[input]
                    input <- input + 1
                    value <- value + more

            value

        while input < encoded.Length do
            let tokenByte = encoded[input]
            input <- input + 1
            let literals = length (int (tokenByte >>> 4))

            if literals > encoded.Length - input || literals > decoded.Length - output then
                invalid ()

            Array.Copy(encoded, input, decoded, output, literals)
            input <- input + literals
            output <- output + literals

            if input < encoded.Length then
                if input > encoded.Length - 2 then
                    invalid ()

                let distance = int encoded[input] ||| (int encoded[input + 1] <<< 8)
                input <- input + 2

                if distance = 0 || distance > history.Length + output then
                    invalid ()

                let matches = length (int (tokenByte &&& 0x0Fuy)) + 4

                if matches > decoded.Length - output then
                    invalid ()

                for _ in 1..matches do
                    let referenced = output - distance

                    decoded[output] <-
                        if referenced >= 0 then
                            decoded[referenced]
                        else
                            history[history.Length + referenced]

                    output <- output + 1
            elif tokenByte &&& 0x0Fuy <> 0uy then
                invalid ()

        if output = 0 then Array.empty else decoded[.. output - 1]

    let finishFrame () =
        if contentChecksum then
            if readU32 () <> contentHash.Digest() then
                invalid ()

        if source.Remaining <> 0L then
            unsupported ()

        if produced <> expected then
            invalid ()

        finished <- true

    let nextBlock () =
        token.ThrowIfCancellationRequested()
        let header = readU32 ()

        if header = 0u then
            finishFrame ()
            false
        else
            let uncompressed = header &&& 0x80000000u <> 0u
            let encodedLength = int (header &&& 0x7FFFFFFFu)

            if encodedLength = 0 || encodedLength > blockMaximum then
                invalid ()

            let encoded = readExact encodedLength

            if blockChecksum && readU32 () <> XxHash32.hash encoded then
                invalid ()

            if independent then
                history <- Array.empty

            let decoded = if uncompressed then encoded else decodeBlock encoded

            if decoded.Length = 0 || decoded.Length > blockMaximum then
                invalid ()

            produced <- produced + int64 decoded.Length

            if produced > expected then
                invalid ()

            contentHash.Update(decoded, 0, decoded.Length)
            appendHistory decoded
            block <- decoded
            blockOffset <- 0
            true

    override _.Length = expected

    override _.Position
        with get () = produced - int64 (block.Length - blockOffset)
        and set _ = raise (NotSupportedException())

    override _.Read(buffer, offset, count) =
        token.ThrowIfCancellationRequested()

        if offset < 0 || count < 0 || offset > buffer.Length - count then
            invalidArg (nameof count) "The read range is invalid."

        if count = 0 || finished then
            0
        else
            let mutable copied = 0

            while copied < count && not finished do
                if blockOffset = block.Length then
                    if not (nextBlock ()) then
                        ()
                else
                    let take = min (count - copied) (block.Length - blockOffset)
                    Array.Copy(block, blockOffset, buffer, offset + copied, take)
                    blockOffset <- blockOffset + take
                    copied <- copied + take

            copied
