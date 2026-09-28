namespace ModConductor.Platform

open System
open System.IO
open System.Runtime.InteropServices
open Microsoft.Win32.SafeHandles

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private UnicodeName =
    val mutable Length: uint16
    val mutable MaximumLength: uint16
    val mutable Buffer: nativeint

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private ObjectAttributes =
    val mutable Length: uint32
    val mutable Root: nativeint
    val mutable Name: nativeint
    val mutable Attributes: uint32
    val mutable Security: nativeint
    val mutable Quality: nativeint

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private IoStatus =
    val mutable Status: nativeint
    val mutable Information: unativeint

module internal RelativeFile =

    [<DllImport("libc", EntryPoint = "openat", SetLastError = true)>]
    extern int private openAt(
        int directory,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string name,
        int flags,
        uint32 mode
    )

    [<DllImport("libc", EntryPoint = "mkdirat", SetLastError = true)>]
    extern int private mkdirAt(
        int directory,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string name,
        uint32 mode
    )

    [<DllImport("ntdll.dll", EntryPoint = "NtCreateFile")>]
    extern int private createFile(
        nativeint& handle,
        uint32 access,
        ObjectAttributes& attributes,
        IoStatus& status,
        nativeint allocation,
        uint32 fileAttributes,
        uint32 share,
        uint32 disposition,
        uint32 options,
        nativeint ea,
        uint32 eaLength
    )

    let private openEntry (root: SafeFileHandle) name directory create writable =
        if
            String.IsNullOrEmpty name
            || name = "."
            || name = ".."
            || name.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0
        then
            invalidArg "name" "Use one native filename component."

        if OperatingSystem.IsLinux() then
            if
                directory
                && create
                && mkdirAt (int (root.DangerousGetHandle()), name, 0x1C0u) <> 0
            then
                raise (
                    IOException(
                        "Creating the library folder failed: "
                        + Marshal.GetLastPInvokeError().ToString()
                    )
                )

            let flags =
                0xA0800
                ||| (if directory then 0x10000
                     elif create then 0xC2
                     elif writable then 2
                     else 0)

            let descriptor = openAt (int (root.DangerousGetHandle()), name, flags, 0x180u)

            if descriptor < 0 && Marshal.GetLastPInvokeError() = 2 then
                raise (FileNotFoundException("The selected entry is missing."))

            if descriptor < 0 then
                raise (
                    IOException(
                        "Opening the root identity file failed: "
                        + Marshal.GetLastPInvokeError().ToString()
                    )
                )

            new SafeFileHandle(nativeint descriptor, true)
        elif OperatingSystem.IsWindows() then
            let characters = Marshal.StringToHGlobalUni name
            let unicode = Marshal.AllocHGlobal(Marshal.SizeOf<UnicodeName>())

            try
                let mutable text = Unchecked.defaultof<UnicodeName>
                text.Length <- uint16 (name.Length * 2)
                text.MaximumLength <- text.Length
                text.Buffer <- characters
                Marshal.StructureToPtr<UnicodeName>(text, unicode, false)
                let mutable attributes = Unchecked.defaultof<ObjectAttributes>
                attributes.Length <- uint32 (Marshal.SizeOf<ObjectAttributes>())
                attributes.Root <- root.DangerousGetHandle()
                attributes.Name <- unicode
                attributes.Attributes <- 0x40u
                let mutable status = Unchecked.defaultof<IoStatus>
                let mutable handle = 0n

                let result =
                    createFile (
                        &handle,
                        (if directory then 0x100081u
                         elif create || writable then 0x100183u
                         else 0x100081u),
                        &attributes,
                        &status,
                        0n,
                        (if directory then 0x10u else 0x80u),
                        // A held directory must permit its own checked rename on Windows.
                        (if directory then 7u else 1u),
                        (if create then 2u else 1u),
                        (if directory then 0x200021u else 0x200060u),
                        0n,
                        0u
                    )

                if result = -1073741772 || result = -1073741766 then
                    raise (FileNotFoundException("The selected entry is missing."))

                if result < 0 then
                    raise (
                        IOException(
                            "Opening the root identity file failed: " + result.ToString("X8")
                        )
                    )

                new SafeFileHandle(handle, true)
            finally
                Marshal.FreeHGlobal unicode
                Marshal.FreeHGlobal characters
        else
            raise (PlatformNotSupportedException())

    let openChild root name directory create =
        openEntry root name directory create false

    let openMetadata (root: SafeFileHandle) name =
        if OperatingSystem.IsLinux() then
            if
                String.IsNullOrEmpty name
                || name = "."
                || name = ".."
                || name.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0
            then
                invalidArg "name" "Use one native filename component."

            let descriptor = openAt (int (root.DangerousGetHandle()), name, 0x2A0000, 0u)

            if descriptor < 0 then
                raise (
                    IOException(
                        "Opening file metadata failed: " + string (Marshal.GetLastPInvokeError())
                    )
                )

            new SafeFileHandle(nativeint descriptor, true)
        elif OperatingSystem.IsWindows() then
            openEntry root name false false false
        else
            raise (PlatformNotSupportedException())

    let openWritable root name = openEntry root name false false true
