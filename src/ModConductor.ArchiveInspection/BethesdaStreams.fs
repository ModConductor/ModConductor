namespace ModConductor.ArchiveInspection

open System
open System.IO

[<AbstractClass>]
type internal ReadOnlyStream() =
    inherit Stream()
    override _.CanRead = true
    override _.CanSeek = false
    override _.CanWrite = false
    override _.Flush() = ()
    override _.Seek(_, _) = raise (NotSupportedException())
    override _.SetLength _ = raise (NotSupportedException())
    override _.Write(_, _, _) = raise (NotSupportedException())

    override _.Position
        with get () = raise (NotSupportedException())
        and set _ = raise (NotSupportedException())

/// A non-owning bounded view over the current position of a verified source stream.
type internal SegmentStream(source: Stream, length: int64) =
    inherit ReadOnlyStream()
    let mutable remaining = length
    member _.Remaining = remaining
    override _.Length = length

    override _.Read(buffer, offset, count) =
        if count = 0 || remaining = 0L then
            0
        else
            let wanted = int (min (int64 count) remaining)
            let received = source.Read(buffer, offset, wanted)

            if received = 0 then
                raise (EndOfStreamException "The archive data range is truncated.")

            remaining <- remaining - int64 received
            received

/// Enforces the declared expanded length of one independently decoded component.
type internal ExactStream(source: Stream, expected: int64) =
    inherit ReadOnlyStream()
    let mutable read = 0L
    let probe = Array.zeroCreate<byte> 1
    override _.Length = expected

    override _.Position
        with get () = read
        and set _ = raise (NotSupportedException())

    override _.Read(buffer, offset, count) =
        if count = 0 then
            0
        elif read = expected then
            if source.Read(probe, 0, 1) <> 0 then
                raise (InvalidDataException "The archive entry size does not match its data.")

            0
        else
            let wanted = int (min (int64 count) (expected - read))
            let received = source.Read(buffer, offset, wanted)

            if received = 0 then
                raise (InvalidDataException "The archive entry size does not match its data.")

            read <- read + int64 received
            received

    override _.Dispose(disposing) =
        if disposing then
            source.Dispose()

        base.Dispose(disposing)

/// Opens each component only when the preceding component is exhausted.
type internal SequenceStream(factories: (unit -> Stream) list, length: int64) =
    inherit ReadOnlyStream()
    let mutable remaining = factories
    let mutable current: Stream = null
    let mutable position = 0L

    let rec read buffer offset count =
        if isNull current then
            match remaining with
            | [] -> 0
            | factory :: rest ->
                remaining <- rest
                current <- factory ()
                read buffer offset count
        else
            let received = current.Read(buffer, offset, count)

            if received <> 0 then
                position <- position + int64 received
                received
            else
                current.Dispose()
                current <- null
                read buffer offset count

    override _.Length = length

    override _.Position
        with get () = position
        and set _ = raise (NotSupportedException())

    override _.Read(buffer, offset, count) =
        if count = 0 then 0 else read buffer offset count

    override _.Dispose(disposing) =
        if disposing && not (isNull current) then
            current.Dispose()

        base.Dispose(disposing)
