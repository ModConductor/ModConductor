namespace ModConductor.Credentials

open System.Runtime.InteropServices

module internal LinuxNative =
    [<DllImport("libsecret-1.so.0")>]
    extern nativeint secret_service_get_sync(int flags, nativeint cancel, nativeint& error)

    [<DllImport("libsecret-1.so.0")>]
    extern nativeint secret_collection_for_alias_sync(
        nativeint service,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string alias,
        int flags,
        nativeint cancel,
        nativeint& error
    )

    [<DllImport("libsecret-1.so.0")>]
    extern int secret_collection_get_locked(nativeint collection)

    [<DllImport("libsecret-1.so.0")>]
    extern nativeint secret_value_new(
        byte[] data,
        nativeint length,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string contentType
    )

    [<DllImport("libsecret-1.so.0")>]
    extern void secret_value_unref(nativeint value)

    [<DllImport("libsecret-1.so.0")>]
    extern nativeint secret_value_get(nativeint value, unativeint& length)

    [<DllImport("libsecret-1.so.0")>]
    extern nativeint secret_item_create_sync(
        nativeint collection,
        nativeint schema,
        nativeint attributes,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string label,
        nativeint value,
        int flags,
        nativeint cancel,
        nativeint& error
    )

    [<DllImport("libsecret-1.so.0")>]
    extern nativeint secret_service_search_sync(
        nativeint service,
        nativeint schema,
        nativeint attributes,
        int flags,
        nativeint cancel,
        nativeint& error
    )

    [<DllImport("libsecret-1.so.0")>]
    extern int secret_item_load_secret_sync(nativeint item, nativeint cancel, nativeint& error)

    [<DllImport("libsecret-1.so.0")>]
    extern nativeint secret_item_get_secret(nativeint item)

    [<DllImport("libsecret-1.so.0")>]
    extern int secret_item_delete_sync(nativeint item, nativeint cancel, nativeint& error)

    [<DllImport("libglib-2.0.so.0")>]
    extern nativeint g_hash_table_new(nativeint hash, nativeint equal)

    [<DllImport("libglib-2.0.so.0")>]
    extern int g_hash_table_insert(nativeint table, nativeint key, nativeint value)

    [<DllImport("libglib-2.0.so.0")>]
    extern void g_hash_table_destroy(nativeint table)

    [<DllImport("libglib-2.0.so.0")>]
    extern void g_list_free(nativeint list)

    [<DllImport("libglib-2.0.so.0")>]
    extern void g_error_free(nativeint error)

    [<DllImport("libgobject-2.0.so.0")>]
    extern void g_object_unref(nativeint value)

    [<DllImport("libgio-2.0.so.0")>]
    extern nativeint g_cancellable_new()

    [<DllImport("libgio-2.0.so.0")>]
    extern void g_cancellable_cancel(nativeint value)

    [<DllImport("libsecret-1.so.0")>]
    extern int secret_item_get_locked(nativeint item)

    [<DllImport("libgio-2.0.so.0")>]
    extern uint32 g_io_error_quark()

    [<DllImport("libgio-2.0.so.0")>]
    extern uint32 g_dbus_error_quark()

    [<DllImport("libsecret-1.so.0")>]
    extern uint32 secret_error_get_quark()
