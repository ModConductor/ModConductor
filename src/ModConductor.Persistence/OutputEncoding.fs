namespace ModConductor.Persistence

open System
open System.IO
open System.Text
open ModConductor.GeneratedOutputs
open ModConductor.Platform

module internal OutputEncoding =
    let private invalid () =
        raise (InvalidDataException "The output action record is invalid.")

    let private guid (w: BinaryWriter) (value: Guid) = w.Write(value.ToByteArray())

    let private readGuid (r: BinaryReader) =
        let bytes = r.ReadBytes 16

        if bytes.Length <> 16 then
            invalid ()

        Guid bytes

    let private option write (w: BinaryWriter) value =
        w.Write(Option.isSome value)
        value |> Option.iter (write w)

    let private readOption read (r: BinaryReader) =
        if r.ReadBoolean() then Some(read r) else None

    let private path (w: BinaryWriter) value = w.Write(LibraryEncoding.path value)

    let private readPath (r: BinaryReader) =
        LibraryEncoding.readPath (r.ReadString())

    let private identity (w: BinaryWriter) value = w.Write(LibraryEncoding.identity value)

    let private readIdentity (r: BinaryReader) =
        LibraryEncoding.readIdentity (r.ReadString())

    let private destination (w: BinaryWriter) =
        function
        | OutputDestination.ExistingMod(id, revision, label) ->
            w.Write 0
            guid w id
            w.Write revision
            w.Write label
        | OutputDestination.NewMod(id, name, label) ->
            w.Write 1
            guid w id
            w.Write name
            w.Write label

    let private readDestination (r: BinaryReader) =
        match r.ReadInt32() with
        | 0 -> OutputDestination.ExistingMod(readGuid r, r.ReadInt64(), r.ReadString())
        | 1 -> OutputDestination.NewMod(readGuid r, r.ReadString(), r.ReadString())
        | _ -> invalid ()

    let private action (w: BinaryWriter) =
        function
        | OutputAction.Keep -> w.Write 0
        | OutputAction.Discard -> w.Write 1
        | OutputAction.MoveToMod value ->
            w.Write 2
            destination w value
        | OutputAction.SaveCopyToMod value ->
            w.Write 3
            destination w value

    let private readAction (r: BinaryReader) =
        match r.ReadInt32() with
        | 0 -> OutputAction.Keep
        | 1 -> OutputAction.Discard
        | 2 -> OutputAction.MoveToMod(readDestination r)
        | 3 -> OutputAction.SaveCopyToMod(readDestination r)
        | _ -> invalid ()

    let private disposition =
        function
        | OutputDisposition.Kept -> 0
        | OutputDisposition.Discarded -> 1
        | OutputDisposition.Moved -> 2
        | OutputDisposition.Copied -> 3
        | OutputDisposition.Changed -> 4
        | OutputDisposition.Pending -> 5

    let private readDisposition =
        function
        | 0 -> OutputDisposition.Kept
        | 1 -> OutputDisposition.Discarded
        | 2 -> OutputDisposition.Moved
        | 3 -> OutputDisposition.Copied
        | 4 -> OutputDisposition.Changed
        | 5 -> OutputDisposition.Pending
        | _ -> invalid ()

    let private observation (w: BinaryWriter) (value: OutputObservation) =
        let location = value.Backing.Location
        guid w location.Id
        w.Write location.Name

        match location.Purpose with
        | OutputPurpose.ToolFolder -> w.Write false
        | OutputPurpose.WritableFile target ->
            w.Write true
            path w target

        w.Write location.Revision

        w.Write(
            match location.State with
            | OutputLocationState.Uninitialized -> 0
            | OutputLocationState.Ready -> 1
            | OutputLocationState.Stopped -> 2
        )

        w.Write location.PhysicalPath
        w.Write(HostPath.value value.Backing.Root)
        identity w value.Backing.RootIdentity
        option path w value.Backing.Path
        path w value.File.Path

        w.Write(
            match value.File.State with
            | OutputFileState.New -> 0
            | OutputFileState.Changed -> 1
            | OutputFileState.Kept -> 2
            | OutputFileState.Absent -> 3
        )

        w.Write value.File.Length
        w.Write value.File.Sha256
        option identity w value.File.Identity
        w.Write value.File.ObservedAt.UtcTicks
        option guid w value.File.DeploymentId
        w.Write value.Modified.Ticks

    let private readObservation scope (r: BinaryReader) =
        let id = readGuid r
        let name = r.ReadString()

        let purpose =
            if r.ReadBoolean() then
                OutputPurpose.WritableFile(readPath r)
            else
                OutputPurpose.ToolFolder

        let revision = r.ReadInt64()

        let state =
            match r.ReadInt32() with
            | 0 -> OutputLocationState.Uninitialized
            | 1 -> OutputLocationState.Ready
            | 2 -> OutputLocationState.Stopped
            | _ -> invalid ()

        let location =
            { Id = id
              WorkspaceId = scope.WorkspaceId
              ContextId = scope.ContextId
              Name = name
              Purpose = purpose
              Revision = revision
              State = state
              PhysicalPath = r.ReadString() }

        let root =
            HostPath.create (r.ReadString()) |> Result.defaultWith (fun _ -> invalid ())

        let rootIdentity = readIdentity r
        let relative = readOption readPath r
        let path = readPath r

        let state =
            match r.ReadInt32() with
            | 0 -> OutputFileState.New
            | 1 -> OutputFileState.Changed
            | 2 -> OutputFileState.Kept
            | 3 -> OutputFileState.Absent
            | _ -> invalid ()

        let file =
            { LocationId = id
              Path = path
              State = state
              Length = r.ReadInt64()
              Sha256 = r.ReadString()
              Identity = readOption readIdentity r
              ObservedAt = DateTimeOffset(r.ReadInt64(), TimeSpan.Zero)
              DeploymentId = readOption readGuid r }

        { File = file
          Backing =
            { Location = location
              Root = root
              RootIdentity = rootIdentity
              Path = relative }
          Modified = DateTime(r.ReadInt64(), DateTimeKind.Utc) }

    let encode (value: OutputActionRecord) =
        use stream = new MemoryStream()
        use w = new BinaryWriter(stream, Encoding.UTF8, true)
        w.Write 2
        guid w value.Id
        guid w value.SnapshotId
        guid w value.Scope.WorkspaceId
        guid w value.Scope.ProfileId
        guid w value.Scope.ContextId
        w.Write value.Scope.Revision
        w.Write value.Scope.ContextRevision
        w.Write value.Scope.Installation
        action w value.Action
        option guid w value.Result.VersionId
        w.Write value.Result.Complete
        w.Write value.Files.Length

        for file in value.Files do
            observation w file

            value.Result.Entries
            |> List.find (fun entry ->
                entry.File.LocationId = file.File.LocationId && entry.File.Path = file.File.Path)
            |> _.Disposition
            |> disposition
            |> w.Write

        w.Flush()

        if stream.Length > int64 (16 * 1024 * 1024) then
            OutputRows.fail OutputError.LimitExceeded

        stream.ToArray()

    let decode (bytes: byte array) =
        if bytes.Length > 16 * 1024 * 1024 then
            invalid ()

        use stream = new MemoryStream(bytes, false)
        use r = new BinaryReader(stream, Encoding.UTF8, true)

        let version = r.ReadInt32()

        if version <> 1 && version <> 2 then
            invalid ()

        let id = readGuid r
        let snapshot = readGuid r

        let scope =
            { WorkspaceId = readGuid r
              ProfileId = if version = 2 then readGuid r else Guid.Empty
              ContextId = readGuid r
              Revision = r.ReadInt64()
              ContextRevision = r.ReadInt64()
              Installation = r.ReadString()
              Locations = []
              Contexts = []
              PendingActions = [] }

        let action = readAction r
        let version = readOption readGuid r
        let complete = r.ReadBoolean()
        let count = r.ReadInt32()

        if count < 0 || count > OutputLimits.selected then
            invalid ()

        let entries =
            [ for _ in 1..count do
                  let file = readObservation scope r in yield file, readDisposition (r.ReadInt32()) ]

        if stream.Position <> stream.Length then
            invalid ()

        { Id = id
          SnapshotId = snapshot
          Scope = scope
          Action = action
          Files = entries |> List.map fst
          Result =
            { Published = false
              Id = id
              VersionId = version
              Complete = complete
              Entries =
                entries
                |> List.map (fun (file, state) ->
                    { File =
                        { LocationId = file.File.LocationId
                          Path = file.File.Path }
                      Disposition = state }) } }
