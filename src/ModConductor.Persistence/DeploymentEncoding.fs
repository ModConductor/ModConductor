namespace ModConductor.Persistence

open System
open System.IO
open System.Text
open System.Security.Cryptography
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

module internal DeploymentEncoding =
    open DeploymentValueEncoding
    open DeploymentGenerationEncoding

    let limit = DeploymentValueEncoding.limit
    let corrupt = DeploymentValueEncoding.corrupt

    let phase =
        function
        | ReceiptPhase.Applying -> 0
        | ReceiptPhase.Restoring -> 1
        | ReceiptPhase.Complete -> 2
        | ReceiptPhase.Restored -> 3
        | ReceiptPhase.Blocked -> 4

    let private readPhase =
        function
        | 0 -> ReceiptPhase.Applying
        | 1 -> ReceiptPhase.Restoring
        | 2 -> ReceiptPhase.Complete
        | 3 -> ReceiptPhase.Restored
        | 4 -> ReceiptPhase.Blocked
        | _ -> corrupt ()

    let private state (w: BinaryWriter) =
        function
        | EntryState.Missing -> w.Write 0
        | EntryState.Link(s, e) ->
            w.Write 1
            spec w s
            option entry w e
        | EntryState.Original o ->
            w.Write 2
            original w o

    let private readState (r: BinaryReader) =
        match r.ReadInt32() with
        | 0 -> EntryState.Missing
        | 1 -> let s = readSpec r in EntryState.Link(s, readOption readEntry r)
        | 2 -> EntryState.Original(readOriginal r)
        | _ -> corrupt ()

    let private change (w: BinaryWriter) (v: EntryChange) =
        target w v.Target
        state w v.Before
        state w v.After

        w.Write(
            match v.Phase with
            | EntryPhase.Pending -> 0
            | EntryPhase.RemoveIntent -> 1
            | EntryPhase.Cleared -> 2
            | EntryPhase.InstallIntent -> 3
            | EntryPhase.Installed -> 4
            | EntryPhase.RestoreIntent -> 5
            | EntryPhase.Restored -> 6
        )

        option entry w v.Observed
        option entry w v.RestoredEntry

    let private readChange (r: BinaryReader) : EntryChange =
        { Target = readTarget r
          Before = readState r
          After = readState r
          Phase =
            (match r.ReadInt32() with
             | 0 -> EntryPhase.Pending
             | 1 -> EntryPhase.RemoveIntent
             | 2 -> EntryPhase.Cleared
             | 3 -> EntryPhase.InstallIntent
             | 4 -> EntryPhase.Installed
             | 5 -> EntryPhase.RestoreIntent
             | 6 -> EntryPhase.Restored
             | _ -> corrupt ())
          Observed = readOption readEntry r
          RestoredEntry = readOption readEntry r }

    let private parentChange w (value: ParentChange) =
        target w value.Target
        option identity w value.Before
        boolean w value.Desired
        option identity w value.Observed
        option identity w value.Restored

        w.Write(
            match value.Phase with
            | EntryPhase.Pending -> 0
            | EntryPhase.RemoveIntent -> 1
            | EntryPhase.Cleared -> 2
            | EntryPhase.InstallIntent -> 3
            | EntryPhase.Installed -> 4
            | EntryPhase.RestoreIntent -> 5
            | EntryPhase.Restored -> 6
        )

    let private readParentChange r : ParentChange =
        { Target = readTarget r
          Before = readOption readIdentity r
          Desired = readBoolean r
          Observed = readOption readIdentity r
          Restored = readOption readIdentity r
          Phase =
            match r.ReadInt32() with
            | 0 -> EntryPhase.Pending
            | 1 -> EntryPhase.RemoveIntent
            | 2 -> EntryPhase.Cleared
            | 3 -> EntryPhase.InstallIntent
            | 4 -> EntryPhase.Installed
            | 5 -> EntryPhase.RestoreIntent
            | 6 -> EntryPhase.Restored
            | _ -> corrupt () }

    let private receipt (w: BinaryWriter) (v: Receipt) =
        guid w v.Id

        w.Write(
            match v.Model with
            | DeploymentModel.SymbolicLinkGeneration -> 1
        )

        context w v.Context
        guid w v.Proposed
        option guid w v.Previous
        w.Write v.PlanFingerprint
        w.Write v.Revision
        w.Write(phase v.Phase)
        list change w v.Changes
        list original w v.Originals
        w.Write v.Detail
        list parentChange w v.Parents

    let private readReceipt version (r: BinaryReader) : Receipt =
        { Id = readGuid r
          Model =
            (match r.ReadInt32() with
             | 1 -> DeploymentModel.SymbolicLinkGeneration
             | _ -> corrupt ())
          Context = readContext version r
          Proposed = readGuid r
          Previous = readOption readGuid r
          PlanFingerprint = r.ReadString()
          Revision = r.ReadInt64()
          Phase = readPhase (r.ReadInt32())
          Changes = readList readChange r
          Originals = readList readOriginal r
          Detail = r.ReadString()
          Parents = if version >= 2 then readList readParentChange r else [] }

    let private encode version write value =
        use stream = new MemoryStream()
        use writer = new BinaryWriter(stream, UTF8Encoding(false, true), true)
        writer.Write(version: int)
        write writer value
        writer.Flush()

        if stream.Length > int64 limit then
            raise (RecoveryException RecoveryError.Limit)

        stream.ToArray()

    let private decode read (bytes: byte[]) =
        if bytes.Length > limit then
            corrupt ()

        try
            use stream = new MemoryStream(bytes, false)
            use reader = new BinaryReader(stream, UTF8Encoding(false, true))

            let version = reader.ReadInt32()

            if version < 1 || version > 5 then
                corrupt ()

            let value = read version reader

            if stream.Position <> stream.Length then
                corrupt ()

            value
        with
        | :? IOException
        | :? ArgumentException
        | :? FormatException
        | :? OverflowException -> corrupt ()

    let contextBytes value = encode 2 context value
    let receiptBytes value = encode 2 receipt value
    let generationBytes value = encode 5 generation value

    let contextFrom bytes =
        decode (fun version r -> if version > 2 then corrupt () else readContext version r) bytes

    let receiptFrom bytes =
        decode (fun version r -> if version > 2 then corrupt () else readReceipt version r) bytes

    let generationFrom bytes = decode readGeneration bytes

    let hash (bytes: byte[]) =
        Convert.ToHexStringLower(SHA256.HashData bytes)
