namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary

module ArchivePreviewRaceFixtures =
    let private hash bytes =
        SHA256.HashData(bytes: byte array) |> Convert.ToHexStringLower

    let private zip (payload: string) =
        use output = new MemoryStream()

        do
            use archive = new ZipArchive(output, ZipArchiveMode.Create, true)
            let entry = archive.CreateEntry("docs/readme.txt", CompressionLevel.NoCompression)
            entry.LastWriteTime <- DateTimeOffset(2026, 9, 14, 0, 0, 0, TimeSpan.Zero)
            use stream = entry.Open()
            stream.Write(Encoding.UTF8.GetBytes payload)

        output.ToArray()

    type private MutationReadStream(inner: Stream, mutate: unit -> unit) =
        inherit Stream()
        let mutable triggered = false

        let trigger () =
            if not triggered then
                triggered <- true
                mutate ()

        override _.CanRead = inner.CanRead
        override _.CanSeek = inner.CanSeek
        override _.CanWrite = false
        override _.Length = inner.Length

        override _.Position
            with get () = inner.Position
            and set value = inner.Position <- value

        override _.Flush() = ()

        override _.Read(buffer, offset, count) =
            trigger ()
            inner.Read(buffer, offset, count)

        override _.Read(buffer: Span<byte>) =
            trigger ()
            inner.Read buffer

        override _.ReadByte() =
            trigger ()
            inner.ReadByte()

        override _.Seek(offset, origin) = inner.Seek(offset, origin)
        override _.SetLength _ = raise (NotSupportedException())
        override _.Write(_, _, _) = raise (NotSupportedException())

        override _.Dispose(disposing) =
            if disposing then
                inner.Dispose()

            base.Dispose disposing

    type private SwitchingSource(reference: ArtifactRef, initial: byte array, changed: byte array) =
        let expected = hash initial
        let mutable current = initial
        let mutable calls = 0
        let mutable mutated = false

        member _.Calls = calls
        member _.Mutated = mutated

        interface IArtifactSource with
            member _.ReadVerified<'a>
                (actual: ArtifactRef, token: CancellationToken, consume: Artifact * Stream -> 'a)
                : Task<Result<'a, ArtifactError>> =
                task {
                    calls <- calls + 1
                    token.ThrowIfCancellationRequested()

                    if actual <> reference || hash current <> expected then
                        return Error ArtifactError.Stale
                    else
                        let artifact =
                            { Id = reference.Id
                              WorkspaceId = reference.WorkspaceId
                              Revision = reference.Revision
                              OriginalName = "race.zip"
                              OriginalPath = "fixture/race.zip"
                              Path = "fixture/race.zip"
                              Storage = ArtifactStorage.Reference
                              State = ArtifactState.Ready
                              Length = Some(int64 current.Length)
                              Sha256 = Some expected
                              Problem = None
                              Links = []
                              CanRetry = false
                              CanLocate = false
                              CanDeleteCopy = false
                              CanRemove = false
                              Download = None }

                        let bytes = current
                        let inner = new MemoryStream(bytes, false)

                        use stream =
                            if calls = 1 then
                                new MutationReadStream(
                                    inner,
                                    fun () ->
                                        current <- changed
                                        mutated <- true
                                )
                                :> Stream
                            else
                                inner :> Stream

                        return Ok(consume (artifact, stream))
                }

    let observe (writer: Utf8JsonWriter) =
        let initial = zip "before mutation\n"
        let changed = zip "after mutation!\n"

        if initial.Length <> changed.Length then
            invalidOp "The race fixture archives must have equal length."

        let valid (bytes: byte array) (expected: string) =
            use stream = new MemoryStream(bytes, false)
            let inspection = Inspection(Unchecked.defaultof<IArtifactSource>)

            inspection.WithOwnedStream(
                hash bytes,
                stream,
                CancellationToken.None,
                fun contents ->
                    let entry =
                        contents.Manifest.Entries |> List.find (fun value -> not value.Directory)

                    use content = new MemoryStream()
                    contents.ReadEntry(entry.Index, fun input -> input.CopyTo content)

                    entry.Size = int64 (Encoding.UTF8.GetByteCount expected)
                    && Encoding.UTF8.GetString(content.ToArray()) = expected
            )

        let bothValid =
            valid initial "before mutation\n" && valid changed "after mutation!\n"

        let reference =
            { WorkspaceId = Guid.NewGuid()
              Id = Guid.NewGuid()
              Revision = 1L }

        let source = SwitchingSource(reference, initial, changed)
        let inspection = Inspection(source)

        let result =
            inspection.WithRevalidatedContents(
                reference,
                CancellationToken.None,
                fun contents ->
                    let entry =
                        contents.Manifest.Entries |> List.find (fun value -> not value.Directory)

                    use content = new MemoryStream()
                    contents.ReadEntry(entry.Index, fun stream -> stream.CopyTo content)
                    Encoding.UTF8.GetString(content.ToArray())
            )
            |> StorageWorker.wait

        writer.WriteBoolean("sameLengthValidArchives", bothValid && initial.Length = changed.Length)
        writer.WriteBoolean("mutationOccurredDuringArchiveRead", source.Mutated)
        writer.WriteBoolean("containerWasRevalidated", source.Calls = 2)

        let refused =
            match result with
            | Error ArtifactError.Stale -> true
            | _ -> false

        writer.WriteBoolean("readyPayloadWasNotPublished", refused)
