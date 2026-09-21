namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Executables

module internal ExecutableEncoding =
    let phase =
        function
        | RunPhase.Starting -> 0
        | RunPhase.Running -> 1
        | RunPhase.WaitingForChildren -> 2
        | RunPhase.Finished -> 3
        | RunPhase.Failed -> 4
        | RunPhase.Detached -> 5
        | RunPhase.TrackingUnavailable -> 6
        | RunPhase.Cancelled -> 7

    let readPhase =
        function
        | 0 -> RunPhase.Starting
        | 1 -> RunPhase.Running
        | 2 -> RunPhase.WaitingForChildren
        | 3 -> RunPhase.Finished
        | 4 -> RunPhase.Failed
        | 5 -> RunPhase.Detached
        | 6 -> RunPhase.TrackingUnavailable
        | 7 -> RunPhase.Cancelled
        | _ -> raise (InvalidDataException "The executable run phase is invalid.")

    let private guid (w: BinaryWriter) (v: Guid) = w.Write(v.ToByteArray())
    let private readGuid (r: BinaryReader) = Guid(r.ReadBytes 16)

    let private opt write (w: BinaryWriter) value =
        w.Write(Option.isSome value)
        value |> Option.iter (write w)

    let private readOpt read (r: BinaryReader) =
        if r.ReadBoolean() then Some(read r) else None

    let private text (w: BinaryWriter) (s: string) = w.Write s
    let private integer (w: BinaryWriter) (v: int) = w.Write v

    let private preset (w: BinaryWriter) (v: ExecutablePreset) =
        guid w v.Id
        guid w v.WorkspaceId
        w.Write v.Revision
        w.Write v.Name
        w.Write v.Launch.Executable
        w.Write v.Launch.WorkingDirectory
        w.Write v.Launch.Arguments.Length

        for value in v.Launch.Arguments do
            w.Write value

        w.Write v.Launch.Environment.Length

        for name, value in v.Launch.Environment do
            w.Write name
            opt text w value

    let private readPreset (r: BinaryReader) =
        let id, workspace, revision, name =
            readGuid r, readGuid r, r.ReadInt64(), r.ReadString()

        let executable, directory = r.ReadString(), r.ReadString()
        let args = [ for _ in 1 .. r.ReadInt32() -> r.ReadString() ]

        let environment =
            [ for _ in 1 .. r.ReadInt32() -> r.ReadString(), readOpt (fun r -> r.ReadString()) r ]

        { Id = id
          WorkspaceId = workspace
          Revision = revision
          Name = name
          Launch =
            { Executable = executable
              WorkingDirectory = directory
              Arguments = args
              Environment = environment } }

    let private encode write value =
        use stream = new MemoryStream()
        use writer = new BinaryWriter(stream)
        writer.Write 1
        write writer value
        writer.Flush()
        Convert.ToBase64String(stream.ToArray())

    let private decode read value =
        use stream = new MemoryStream(Convert.FromBase64String value)
        use reader = new BinaryReader(stream)

        if reader.ReadInt32() <> 1 then
            raise (InvalidDataException "The executable record version is unsupported.")

        let result = read reader

        if stream.Position <> stream.Length then
            raise (InvalidDataException "The executable record has trailing data.")

        result

    let encodePreset value = encode preset value

    let decodePreset value = decode readPreset value

    let private nativeRequest (w: BinaryWriter) (v: RunRequest) =
        guid w v.Id
        guid w v.WorkspaceId
        w.Write v.WorkspaceRevision
        guid w v.PresetId
        w.Write v.PresetRevision

    let private readRequest (r: BinaryReader) : RunRequest =
        { Id = readGuid r
          WorkspaceId = readGuid r
          WorkspaceRevision = r.ReadInt64()
          PresetId = readGuid r
          PresetRevision = r.ReadInt64() }

    let private launch (w: BinaryWriter) (v: ModConductor.Platform.NativeLaunch) =
        w.Write v.Executable
        w.Write v.WorkingDirectory
        w.Write v.Arguments.Length
        v.Arguments |> List.iter (text w)
        w.Write v.Environment.Length

        for name, value in v.Environment do
            text w name
            opt text w value

    let private readLaunch (r: BinaryReader) : ModConductor.Platform.NativeLaunch =
        let executable, directory = r.ReadString(), r.ReadString()
        let args = [ for _ in 1 .. r.ReadInt32() -> r.ReadString() ]

        let env =
            [ for _ in 1 .. r.ReadInt32() -> r.ReadString(), readOpt (fun r -> r.ReadString()) r ]

        { Executable = executable
          WorkingDirectory = directory
          Arguments = args
          Environment = env }

    let private game (w: BinaryWriter) (v: GameRun) =
        guid w v.Request.Id
        guid w v.Request.WorkspaceId
        w.Write v.Request.WorkspaceRevision
        guid w v.Request.ProfileId
        w.Write v.Request.ContextRevision
        text w v.Request.SourceToken
        guid w v.ContextId
        text w v.Name
        text w v.GameDirectory
        text w v.Runtime
        launch w v.Launch

        w.Write(
            match v.Preparation.Phase with
            | GamePreparationPhase.Preparing -> 0
            | GamePreparationPhase.Applying -> 1
            | GamePreparationPhase.Ready -> 2
            | GamePreparationPhase.ProfileData -> 3
        )

        w.Write v.Preparation.Completed
        w.Write v.Preparation.Total

        opt
            (fun w (files: AppliedGameFiles) ->
                guid w files.ReceiptId
                guid w files.GenerationId
                text w files.Fingerprint)
            w
            v.Files

        w.Write v.ProfileDataRevision

        opt
            (fun w (value: AppliedProfileData) ->
                guid w value.ReceiptId
                w.Write value.Revision
                w.Write value.CompletedFiles
                w.Write value.Complete)
            w
            v.ProfileData

    let private readGame (r: BinaryReader) : GameRun =
        let request =
            { Id = readGuid r
              WorkspaceId = readGuid r
              WorkspaceRevision = r.ReadInt64()
              ProfileId = readGuid r
              ContextRevision = r.ReadInt64()
              SourceToken = r.ReadString() }

        let context, name, directory, runtime =
            readGuid r, r.ReadString(), r.ReadString(), r.ReadString()

        let launch = readLaunch r

        let phase =
            match r.ReadInt32() with
            | 0 -> GamePreparationPhase.Preparing
            | 1 -> GamePreparationPhase.Applying
            | 2 -> GamePreparationPhase.Ready
            | 3 -> GamePreparationPhase.ProfileData
            | _ -> raise (InvalidDataException "The game preparation phase is invalid.")

        let completed, total = r.ReadInt32(), r.ReadInt32()

        { Request = request
          ContextId = context
          Name = name
          GameDirectory = directory
          Runtime = runtime
          Launch = launch
          Preparation =
            { Phase = phase
              Completed = completed
              Total = total }
          Files =
            readOpt
                (fun r ->
                    { ReceiptId = readGuid r
                      GenerationId = readGuid r
                      Fingerprint = r.ReadString() })
                r
          ProfileDataRevision = r.ReadInt64()
          ProfileData =
            readOpt
                (fun r ->
                    { ReceiptId = readGuid r
                      Revision = r.ReadInt64()
                      CompletedFiles = r.ReadInt32()
                      Complete = r.ReadBoolean() }
                    : AppliedProfileData)
                r }

    let encodeRun (value: ExecutableRun) =
        encode
            (fun w v ->
                match v.Source with
                | RunSource.Preset(request, value) ->
                    w.Write 0
                    nativeRequest w request
                    preset w value
                | RunSource.Game value ->
                    w.Write 1
                    game w value

                w.Write v.Revision
                opt guid w v.ProfileId
                opt text w v.ProfileName
                w.Write(v.RequestedAt.ToString("O"))
                w.Write(phase v.Phase)
                opt integer w v.ProcessId
                opt text w v.Scope
                opt integer w v.RootExitCode
                opt integer w v.ActiveProcesses
                opt text w v.Problem)
            value

    let decodeRun value =
        decode
            (fun r ->
                let source =
                    match r.ReadInt32() with
                    | 0 -> RunSource.Preset(readRequest r, readPreset r)
                    | 1 -> RunSource.Game(readGame r)
                    | _ -> raise (InvalidDataException "The run source is invalid.")

                { Source = source
                  Revision = r.ReadInt64()
                  ProfileId = readOpt readGuid r
                  ProfileName = readOpt (fun r -> r.ReadString()) r
                  RequestedAt = DateTimeOffset.Parse(r.ReadString())
                  Phase = readPhase (r.ReadInt32())
                  ProcessId = readOpt (fun r -> r.ReadInt32()) r
                  Scope = readOpt (fun r -> r.ReadString()) r
                  RootExitCode = readOpt (fun r -> r.ReadInt32()) r
                  ActiveProcesses = readOpt (fun r -> r.ReadInt32()) r
                  Problem = readOpt (fun r -> r.ReadString()) r })
            value
