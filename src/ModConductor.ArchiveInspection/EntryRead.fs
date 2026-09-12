namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.Threading

/// Counts bytes delivered to the consumer; dependency-internal work is not governed here.
type internal EntryRead
    (source: Stream, expected: int64, count: int64 -> unit, token: CancellationToken) =
    inherit Stream()
    let mutable read = 0L
    override _.CanRead = true
    override _.CanWrite = false
    override _.CanSeek = false
    override _.Length = expected

    override _.Position
        with get () = read
        and set _ = raise (NotSupportedException())

    override _.Flush() = ()
    override _.Seek(_, _) = raise (NotSupportedException())
    override _.SetLength _ = raise (NotSupportedException())
    override _.Write(_, _, _) = raise (NotSupportedException())

    override _.Read(buffer, offset, length) =
        token.ThrowIfCancellationRequested()
        let received = source.Read(buffer, offset, length)
        read <- read + int64 received
        count (int64 received)

        if read > expected || (length > 0 && received = 0 && read <> expected) then
            raise (InvalidDataException "The archive entry size does not match its data.")

        received
