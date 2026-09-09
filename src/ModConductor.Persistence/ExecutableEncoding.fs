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

    let readPhase =
        function
        | 0 -> RunPhase.Starting
        | 1 -> RunPhase.Running
        | 2 -> RunPhase.WaitingForChildren
        | 3 -> RunPhase.Finished
        | 4 -> RunPhase.Failed
        | 5 -> RunPhase.Detached
        | 6 -> RunPhase.TrackingUnavailable
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

    let encodeRun (value: ExecutableRun) =
        encode
            (fun w v ->
                guid w v.Request.Id
                guid w v.Request.WorkspaceId
                w.Write v.Request.WorkspaceRevision
                guid w v.Request.PresetId
                w.Write v.Request.PresetRevision
                w.Write v.Revision
                preset w v.Preset
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
                let request =
                    { Id = readGuid r
                      WorkspaceId = readGuid r
                      WorkspaceRevision = r.ReadInt64()
                      PresetId = readGuid r
                      PresetRevision = r.ReadInt64() }

                { Request = request
                  Revision = r.ReadInt64()
                  Preset = readPreset r
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
