namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.Threading

type internal EntryRead(source: Stream, expected: int64, token: CancellationToken) =
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

        received
