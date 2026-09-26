namespace ModConductor.Persistence

open System
open System.Security.Cryptography
open System.Text
open ModConductor.Fnis

type internal StoredFnisRun =
    { Id: Guid
      WorkspaceId: Guid
      ProfileId: Guid
      Phase: FnisOutputPhase
      Busy: bool
      GenerationId: Guid
      Generator: string
      Fingerprint: string
      OutputModId: Guid
      OutputVersionId: Guid
      ExitCode: int option
      StandardOutput: string
      StandardError: string
      RunLog: string
      Problem: string option }

module internal FnisRunRows =
    let outputId (profile: Guid) =
        let bytes =
            SHA256.HashData(
                Encoding.UTF8.GetBytes("modconductor/fnis-output/" + profile.ToString("N"))
            )
            |> Array.take 16

        bytes[7] <- (bytes[7] &&& 0x0Fuy) ||| 0x50uy
        bytes[8] <- (bytes[8] &&& 0x3Fuy) ||| 0x80uy
        Guid bytes

    let decode bytes =
        if isNull bytes then
            ""
        else
            Encoding.UTF8.GetString(bytes: byte array)

    let readRun (reader: Microsoft.Data.Sqlite.SqliteDataReader) =
        let phase =
            match reader.GetInt64 3 with
            | 0L -> FnisOutputPhase.Running
            | 2L -> FnisOutputPhase.Cancelled
            | 3L -> FnisOutputPhase.Current
            | 7L -> FnisOutputPhase.Abandoned
            | _ -> FnisOutputPhase.Failed

        { Id = Guid.Parse(reader.GetString 0)
          WorkspaceId = Guid.Parse(reader.GetString 1)
          ProfileId = Guid.Parse(reader.GetString 2)
          Phase = phase
          Busy = reader.GetInt64 4 <> 0L
          GenerationId = Guid.Parse(reader.GetString 5)
          Generator = reader.GetString 6
          Fingerprint = reader.GetString 7
          OutputModId = Guid.Parse(reader.GetString 8)
          OutputVersionId = Guid.Parse(reader.GetString 9)
          ExitCode =
            if reader.IsDBNull 10 then
                None
            else
                Some(reader.GetInt32 10)
          StandardOutput = decode (reader.GetFieldValue<byte array> 11)
          StandardError = decode (reader.GetFieldValue<byte array> 12)
          Problem =
            if reader.IsDBNull 13 then
                None
            else
                Some(reader.GetString 13)
          RunLog = decode (reader.GetFieldValue<byte array> 14) }

    let latest connection transaction profile =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT id,workspace_id,profile_id,phase,busy,generation_id,generator,input_fingerprint,output_mod_id,output_version_id,exit_code,stdout,stderr,problem,run_log FROM fnis_runs WHERE profile_id=$profile ORDER BY requested_at DESC LIMIT 1"
                [ "$profile", box (string profile) ]

        use reader = command.ExecuteReader()
        if reader.Read() then Some(readRun reader) else None
