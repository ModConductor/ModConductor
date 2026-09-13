namespace ModConductor.Credentials

open System
open System.Runtime.InteropServices
open System.Threading

exception private NativeFailure of StorageProblem

module private SecretService =
    let check ok error =
        if error <> 0n then
            let domain = uint32 (Marshal.ReadInt32(error, 0))
            let code = Marshal.ReadInt32(error, 4)
            LinuxNative.g_error_free error

            let problem =
                if domain = LinuxNative.g_io_error_quark () then
                    match code with
                    | 19 -> StorageProblem.Cancelled
                    | 24 -> StorageProblem.TimedOut
                    | 14 -> StorageProblem.Denied
                    | _ -> StorageProblem.Failed
                elif domain = LinuxNative.g_dbus_error_quark () then
                    match code with
                    | 2
                    | 3 -> StorageProblem.Unavailable
                    | 9
                    | 10 -> StorageProblem.Denied
                    | 4
                    | 12 -> StorageProblem.TimedOut
                    | _ -> StorageProblem.Failed
                elif domain = LinuxNative.secret_error_get_quark () && code = 2 then
                    StorageProblem.Locked
                else
                    StorageProblem.Failed

            raise (NativeFailure problem)

        if not ok then
            raise (NativeFailure StorageProblem.Unavailable)

    let run (token: CancellationToken) action =
        try
            token.ThrowIfCancellationRequested()
            let cancel = LinuxNative.g_cancellable_new ()

            try
                use registration = token.Register(fun () -> LinuxNative.g_cancellable_cancel cancel)
                let mutable error = 0n
                let service = LinuxNative.secret_service_get_sync (0, cancel, &error)
                check (service <> 0n) error

                try
                    Ok(action service cancel)
                finally
                    LinuxNative.g_object_unref service
            finally
                LinuxNative.g_object_unref cancel
        with
        | NativeFailure problem -> Error problem
        | :? DllNotFoundException
        | :? EntryPointNotFoundException -> Error StorageProblem.Unavailable
        | :? OperationCanceledException -> Error StorageProblem.Cancelled

    let attributes action =
        let library = NativeLibrary.Load "libglib-2.0.so.0"

        try
            let table =
                LinuxNative.g_hash_table_new (
                    NativeLibrary.GetExport(library, "g_str_hash"),
                    NativeLibrary.GetExport(library, "g_str_equal")
                )

            let strings =
                [ "application"; "ModConductor"; "provider"; "NexusMods" ]
                |> List.map Marshal.StringToCoTaskMemUTF8

            try
                LinuxNative.g_hash_table_insert (table, strings[0], strings[1]) |> ignore
                LinuxNative.g_hash_table_insert (table, strings[2], strings[3]) |> ignore
                action table
            finally
                LinuxNative.g_hash_table_destroy table

                for value in strings do
                    Marshal.FreeCoTaskMem value
        finally
            NativeLibrary.Free library

    let collection service cancel action =
        let mutable error = 0n

        let collection =
            LinuxNative.secret_collection_for_alias_sync (service, "default", 0, cancel, &error)

        check (collection <> 0n) error

        try
            action collection
        finally
            LinuxNative.g_object_unref collection

    let search service cancel action =
        attributes (fun table ->
            let mutable error = 0n
            // ALL returns locked metadata without UNLOCK or LOAD_SECRETS.
            let items =
                LinuxNative.secret_service_search_sync (service, 0n, table, 2, cancel, &error)

            check true error

            try
                let found = ResizeArray<nativeint>()
                let mutable next = items

                while next <> 0n do
                    found.Add(Marshal.ReadIntPtr next)
                    next <- Marshal.ReadIntPtr(next, IntPtr.Size)

                action (List.ofSeq found)
            finally
                let mutable next = items

                while next <> 0n do
                    LinuxNative.g_object_unref (Marshal.ReadIntPtr next)
                    next <- Marshal.ReadIntPtr(next, IntPtr.Size)

                LinuxNative.g_list_free items)

    let unlocked item =
        if LinuxNative.secret_item_get_locked item <> 0 then
            raise (NativeFailure StorageProblem.Locked)

/// Requires libsecret at runtime; absent native support remains an explicit capability.
type SecretServiceStore() =
    interface ICredentialStore with
        member _.Kind = StorageKind.SecretService

        member _.Inspect token =
            match
                SecretService.run token (fun service cancel ->
                    SecretService.search service cancel (fun items ->
                        match items with
                        | [] ->
                            SecretService.collection service cancel (fun collection ->
                                { Saved = SavedPresence.Absent
                                  Problem =
                                    if
                                        LinuxNative.secret_collection_get_locked collection <> 0
                                    then
                                        Some StorageProblem.Locked
                                    else
                                        None })
                        | _ ->
                            { Saved = SavedPresence.Present
                              Problem =
                                if
                                    items
                                    |> List.exists (fun item ->
                                        LinuxNative.secret_item_get_locked item <> 0)
                                then
                                    Some StorageProblem.Locked
                                else
                                    None }))
            with
            | Ok status -> status
            | Error problem ->
                { Saved = SavedPresence.Unknown
                  Problem = Some problem }

        member _.Save(data, token) =
            SecretService.run token (fun service cancel ->
                SecretService.collection service cancel (fun collection ->
                    if LinuxNative.secret_collection_get_locked collection <> 0 then
                        raise (NativeFailure StorageProblem.Locked)

                    SecretService.attributes (fun attributes ->
                        let value =
                            LinuxNative.secret_value_new (
                                data,
                                nativeint data.Length,
                                "application/octet-stream"
                            )

                        try
                            let mutable error = 0n

                            let item =
                                LinuxNative.secret_item_create_sync (
                                    collection,
                                    0n,
                                    attributes,
                                    "Mod Conductor — Nexus Mods",
                                    value,
                                    2,
                                    cancel,
                                    &error
                                )

                            SecretService.check (item <> 0n) error
                            LinuxNative.g_object_unref item
                        finally
                            LinuxNative.secret_value_unref value)))

        member _.Read token =
            SecretService.run token (fun service cancel ->
                SecretService.search service cancel (function
                    | [] -> None
                    | item :: _ ->
                        SecretService.unlocked item
                        let mutable error = 0n

                        SecretService.check
                            (LinuxNative.secret_item_load_secret_sync (item, cancel, &error) <> 0)
                            error

                        let value = LinuxNative.secret_item_get_secret item
                        SecretService.check (value <> 0n) 0n

                        try
                            let mutable length = 0un
                            let pointer = LinuxNative.secret_value_get (value, &length)
                            let data = Array.zeroCreate<byte> (int length)
                            Marshal.Copy(pointer, data, 0, data.Length)
                            Some data
                        finally
                            LinuxNative.secret_value_unref value))

        member _.Delete token =
            SecretService.run token (fun service cancel ->
                SecretService.search service cancel (fun items ->
                    for item in items do
                        SecretService.unlocked item
                        let mutable error = 0n

                        SecretService.check
                            (LinuxNative.secret_item_delete_sync (item, cancel, &error) <> 0)
                            error))
