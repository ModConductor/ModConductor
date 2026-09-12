namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Platform
open ModConductor.ModLibrary

module internal LibraryEncoding =
    // This is SQLite column encoding, never a wire path or native filename.
    let path value =
        String.Join('\000', LogicalPath.components value)

    let readPath (value: string) =
        LogicalPath.create (value.Split('\000') |> Array.toList)
        |> Result.defaultWith (fun _ -> raise (InvalidDataException("Invalid inventory path.")))

    let identity value =
        let device =
            match value.Device with
            | LinuxDevice(major, minor) -> "L:" + string major + ":" + string minor
            | WindowsVolume serial -> "W:" + string serial

        device + ":" + string value.Low + ":" + string value.High

    let readIdentity (value: string) =
        let parts = value.Split ':'

        match parts with
        | [| "L"; major; minor; low; high |] ->
            { Device = LinuxDevice(UInt32.Parse major, UInt32.Parse minor)
              Low = UInt64.Parse low
              High = UInt64.Parse high }
        | [| "W"; serial; low; high |] ->
            { Device = WindowsVolume(UInt64.Parse serial)
              Low = UInt64.Parse low
              High = UInt64.Parse high }
        | _ -> raise (InvalidDataException("Invalid inventory identity."))

    let kind =
        function
        | ModKind.Regular -> 1
        | ModKind.Separator -> 2
        | ModKind.Backup -> 3
        | ModKind.Unmanaged -> 4
        | ModKind.GeneratedOutput -> 5

    let readKind =
        function
        | 1 -> ModKind.Regular
        | 2 -> ModKind.Separator
        | 3 -> ModKind.Backup
        | 4 -> ModKind.Unmanaged
        | 5 -> ModKind.GeneratedOutput
        | _ -> raise (InvalidDataException("Unknown mod type."))

    let status =
        function
        | InventoryStatus.Ready -> 1
        | InventoryStatus.Detached -> 2
        | InventoryStatus.Changed -> 3
        | InventoryStatus.Unproved -> 4
        | InventoryStatus.Publishing -> 5
        | InventoryStatus.Deleting -> 6

    let readStatus =
        function
        | 1 -> InventoryStatus.Ready
        | 2 -> InventoryStatus.Detached
        | 3 -> InventoryStatus.Changed
        | 4 -> InventoryStatus.Unproved
        | 5 -> InventoryStatus.Publishing
        | 6 -> InventoryStatus.Deleting
        | _ -> raise (InvalidDataException("Unknown inventory status."))
