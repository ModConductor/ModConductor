namespace ModConductor.Persistence

open System
open System.IO
open Microsoft.Data.Sqlite
open ModConductor.Platform

module internal WorkspaceRows =
    let private device =
        function
        | LinuxDevice(major, minor) -> 1, string major + ":" + string minor
        | WindowsVolume volume -> 2, string volume

    let private readDevice kind (value: string) =
        match kind with
        | 1 ->
            let parts = value.Split(':')
            LinuxDevice(UInt32.Parse parts[0], UInt32.Parse parts[1])
        | 2 -> WindowsVolume(UInt64.Parse value)
        | _ -> raise (InvalidDataException("Unknown root device identity."))

    let private encodePhase =
        function
        | RootCreationPhase.Intent -> 1
        | RootCreationPhase.Observed -> 2
        | RootCreationPhase.Complete -> 3
        | RootCreationPhase.Unresolved -> 4

    let private readPhase =
        function
        | 1 -> RootCreationPhase.Intent
        | 2 -> RootCreationPhase.Observed
        | 3 -> RootCreationPhase.Complete
        | 4 -> RootCreationPhase.Unresolved
        | _ -> raise (InvalidDataException("Unknown root creation phase."))

    let find connection transaction id =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT w.id,w.path,w.device_kind,w.device,w.file_low,w.file_high,w.revision,r.revision,r.phase,r.marker_device_kind,r.marker_device,r.marker_low,r.marker_high,r.detail,r.owner,r.busy,r.abandoned,r.marker FROM workspace_roots w JOIN root_creation_receipts r ON w.id=r.id WHERE w.id=$id"
                [ "$id", box (id.ToString()) ]

        use reader = command.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let device = readDevice (reader.GetInt32 2) (reader.GetString 3)

            let file device first =
                { Device = device
                  Low = UInt64.Parse(reader.GetString first)
                  High = UInt64.Parse(reader.GetString(first + 1)) }

            Some
                { Receipt =
                    { Workspace =
                        { Id = Guid.Parse(reader.GetString 0)
                          Path =
                            HostPath.create (reader.GetString 1) |> Result.defaultWith invalidOp
                          Identity = file device 4
                          Revision = reader.GetInt64 6 }
                      Revision = reader.GetInt64 7
                      Phase = readPhase (reader.GetInt32 8)
                      MarkerIdentity =
                        if reader.IsDBNull 9 then
                            None
                        else
                            Some(file (readDevice (reader.GetInt32 9) (reader.GetString 10)) 11)
                      Detail = reader.GetString 13 }
                  Owner = reader.GetString 14
                  Busy = reader.GetBoolean 15
                  Abandoned = reader.GetBoolean 16
                  Marker = Guid.Parse(reader.GetString 17) }

    let prepare (connection: SqliteConnection) owner id expected (root: SelectedRoot) =
        use transaction = connection.BeginTransaction(deferred = false)

        let result =
            match find connection transaction id, (RootSelection.facts root).File with
            | Some row, Known identity when
                row.Receipt.Workspace.Identity = identity
                && row.Receipt.Workspace.Path = RootSelection.path root
                ->
                if expected = 0L then
                    Ok row.Receipt
                else
                    Error WorkspaceFailure.StaleRevision
            | Some _, _ -> Error WorkspaceFailure.IdentityConflict
            | None, Unknown _ -> Error WorkspaceFailure.InvalidRoot
            | None, Known _ when expected <> 0L -> Error WorkspaceFailure.StaleRevision
            | None, Known identity ->
                let kind, device = device identity.Device
                let path = RootSelection.path root

                let parameters =
                    [ "$id", box (id.ToString())
                      "$path", box (HostPath.value path)
                      "$kind", box kind
                      "$device", box device
                      "$low", box (string identity.Low)
                      "$high", box (string identity.High) ]

                let existing =
                    Sqlite.number
                        connection
                        transaction
                        "SELECT count(*) FROM workspace_roots WHERE device_kind=$kind AND device=$device AND file_low=$low AND file_high=$high"
                        parameters

                if existing <> 0L then
                    Error WorkspaceFailure.IdentityConflict
                else
                    Sqlite.execute
                        connection
                        transaction
                        "INSERT INTO workspace_roots VALUES($id,$path,$kind,$device,$low,$high,0)"
                        parameters

                    Sqlite.execute
                        connection
                        transaction
                        "INSERT INTO root_creation_receipts VALUES($id,$owner,$marker,1,1,0,0,NULL,NULL,NULL,NULL,'')"
                        [ "$id", box (id.ToString())
                          "$owner", box owner
                          "$marker", box (Guid.NewGuid().ToString()) ]

                    Ok (find connection transaction id |> Option.get).Receipt

        transaction.Commit()
        result

    let claim (connection: SqliteConnection) owner id expected recovery phase =
        use transaction = connection.BeginTransaction(deferred = false)

        let result =
            match find connection transaction id with
            | None -> Error WorkspaceFailure.NotFound
            | Some row when row.Receipt.Revision <> expected -> Error WorkspaceFailure.StaleRevision
            | Some row when row.Receipt.Phase = RootCreationPhase.Complete -> Ok row
            | Some row when recovery && row.Owner <> owner && not row.Abandoned ->
                Error WorkspaceFailure.Busy
            | Some row when
                not recovery
                && (row.Owner <> owner || row.Busy || row.Abandoned || row.Receipt.Phase <> phase)
                ->
                Error WorkspaceFailure.Busy
            | Some _ ->
                Sqlite.execute
                    connection
                    transaction
                    "UPDATE root_creation_receipts SET owner=$owner,busy=1,abandoned=0,revision=revision+1 WHERE id=$id"
                    [ "$id", box (id.ToString()); "$owner", box owner ]

                Ok(find connection transaction id |> Option.get)

        transaction.Commit()
        result

    let finish
        (connection: SqliteConnection)
        owner
        (row: RootCreationRow)
        phase
        fileIdentity
        detail
        =
        use transaction = connection.BeginTransaction(deferred = false)
        let id = row.Receipt.Workspace.Id

        let result =
            match find connection transaction id with
            | Some current when
                current.Owner = owner
                && current.Receipt.Revision = row.Receipt.Revision
                && current.Busy
                ->
                let kind, device, low, high =
                    match fileIdentity with
                    | Some id ->
                        let kind, name = device id.Device
                        box kind, box name, box (string id.Low), box (string id.High)
                    | None -> box DBNull.Value, box DBNull.Value, box DBNull.Value, box DBNull.Value

                Sqlite.execute
                    connection
                    transaction
                    "UPDATE root_creation_receipts SET phase=$phase,marker_device_kind=$kind,marker_device=$device,marker_low=$low,marker_high=$high,detail=$detail,busy=0,revision=revision+1 WHERE id=$id"
                    [ "$id", box (id.ToString())
                      "$phase", box (encodePhase phase)
                      "$kind", kind
                      "$device", device
                      "$low", low
                      "$high", high
                      "$detail", box detail ]

                if phase = RootCreationPhase.Complete then
                    Sqlite.execute
                        connection
                        transaction
                        "UPDATE workspace_roots SET revision=revision+1 WHERE id=$id"
                        [ "$id", box (id.ToString()) ]

                Ok (find connection transaction id |> Option.get).Receipt
            | Some _ -> Error WorkspaceFailure.StaleRevision
            | None -> Error WorkspaceFailure.NotFound

        transaction.Commit()
        result
