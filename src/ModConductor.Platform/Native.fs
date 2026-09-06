namespace ModConductor.Platform

open System
open System.IO
open System.Runtime.InteropServices
open Microsoft.Win32.SafeHandles

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private StatxTimestamp =
    val mutable Seconds: int64
    val mutable Nanoseconds: uint32
    val mutable Reserved: int32

// Linux statx uses this fixed 256-byte UAPI layout; optional fields require Mask bits.
[<Struct; StructLayout(LayoutKind.Sequential, Size = 256)>]
type private Statx =
    val mutable Mask: uint32
    val mutable BlockSize: uint32
    val mutable Attributes: uint64
    val mutable Links: uint32
    val mutable User: uint32
    val mutable Group: uint32
    val mutable Mode: uint16
    val mutable Padding: uint16
    val mutable Inode: uint64
    val mutable Size: uint64
    val mutable Blocks: uint64
    val mutable AttributesMask: uint64
    val mutable Access: StatxTimestamp
    val mutable Birth: StatxTimestamp
    val mutable Changed: StatxTimestamp
    val mutable Modified: StatxTimestamp
    val mutable RdevMajor: uint32
    val mutable RdevMinor: uint32
    val mutable Major: uint32
    val mutable Minor: uint32
    val mutable Mount: uint64

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private FileId =
    val mutable Volume: uint64
    val mutable Low: uint64
    val mutable High: uint64

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private AttributeTag =
    val mutable Attributes: uint32
    val mutable Tag: uint32

module internal Native =
    [<DllImport("libc", EntryPoint = "statx", SetLastError = true)>]
    extern int private statx(
        int directory,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string path,
        int flags,
        uint32 mask,
        Statx& result
    )

    [<DllImport("libc", EntryPoint = "realpath", SetLastError = true)>]
    extern nativeint private realpath(
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string path,
        nativeint buffer
    )

    [<DllImport("libc", EntryPoint = "free")>]
    extern void private free(nativeint buffer)

    [<DllImport("libc", EntryPoint = "link", SetLastError = true)>]
    extern int private link(
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string source,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string target
    )

    [<DllImport("kernel32.dll",
                EntryPoint = "CreateFileW",
                CharSet = CharSet.Unicode,
                SetLastError = true)>]
    extern SafeFileHandle private createFile(
        string path,
        uint32 access,
        uint32 share,
        nativeint security,
        uint32 creation,
        uint32 flags,
        nativeint template
    )

    [<DllImport("kernel32.dll", EntryPoint = "GetFileInformationByHandleEx", SetLastError = true)>]
    extern int private fileId(
        SafeFileHandle handle,
        int informationClass,
        FileId& information,
        uint32 size
    )

    [<DllImport("kernel32.dll", EntryPoint = "GetFinalPathNameByHandleW", SetLastError = true)>]
    extern uint32 private finalPath(
        SafeFileHandle handle,
        nativeint buffer,
        uint32 length,
        uint32 flags
    )

    [<DllImport("kernel32.dll",
                EntryPoint = "CreateHardLinkW",
                CharSet = CharSet.Unicode,
                SetLastError = true)>]
    extern int private hardLink(string target, string source, nativeint security)

    [<DllImport("libc", EntryPoint = "open", SetLastError = true)>]
    extern int private openDirectory([<MarshalAs(UnmanagedType.LPUTF8Str)>] string path, int flags)

    [<DllImport("kernel32.dll", EntryPoint = "GetFileInformationByHandleEx", SetLastError = true)>]
    extern int private attributeTag(
        SafeFileHandle handle,
        int informationClass,
        AttributeTag& information,
        uint32 size
    )

    let private error operation =
        let code = Marshal.GetLastPInvokeError()

        if
            (OperatingSystem.IsLinux() && code = 40)
            || (OperatingSystem.IsWindows() && code = 1921)
        then
            Error LinkCycle
        else
            Error(NativeError { Operation = operation; Code = code })

    let private windowsPath path =
        let full = Path.GetFullPath path

        if full.StartsWith("\\\\?\\", StringComparison.Ordinal) then
            full
        elif full.StartsWith("\\\\", StringComparison.Ordinal) then
            "\\\\?\\UNC\\" + full.Substring(2)
        else
            "\\\\?\\" + full

    let private windowsHandle path follow =
        createFile (
            windowsPath path,
            0u,
            7u,
            0n,
            3u,
            (if follow then 0x02000000u else 0x02200000u),
            0n
        )

    let canonical path =
        if OperatingSystem.IsLinux() then
            let pointer = realpath (path, 0n)

            if pointer = 0n then
                error "realpath"
            else
                try
                    Ok(Marshal.PtrToStringUTF8 pointer)
                finally
                    free pointer
        elif OperatingSystem.IsWindows() then
            use handle = windowsHandle path true

            if handle.IsInvalid then
                error "CreateFile"
            else
                let buffer = Marshal.AllocHGlobal(32768 * 2)

                try
                    let length = finalPath (handle, buffer, 32768u, 0u)

                    if length = 0u then
                        error "GetFinalPathNameByHandle"
                    elif length >= 32768u then
                        Error LimitExceeded
                    else
                        let value = Marshal.PtrToStringUni(buffer, int length)

                        if value.StartsWith("\\\\?\\UNC\\", StringComparison.Ordinal) then
                            Ok("\\\\" + value.Substring(8))
                        elif value.StartsWith("\\\\?\\", StringComparison.Ordinal) then
                            Ok(value.Substring(4))
                        else
                            Ok value
                finally
                    Marshal.FreeHGlobal buffer
        else
            Error UnsupportedEntry

    let private linuxFacts (result: Statx) =
        let identity =
            if result.Mask &&& 0x100u <> 0u then
                Known
                    { Device = LinuxDevice(result.Major, result.Minor)
                      Low = result.Inode
                      High = 0UL }
            else
                Unknown "The filesystem did not return a file ID."

        let kind =
            match int result.Mode &&& 0xf000 with
            | 0x8000 -> EntryKind.RegularFile
            | 0x4000 -> EntryKind.Directory
            | 0xa000 -> EntryKind.Link
            | _ -> EntryKind.Other

        Ok
            { File = identity
              Mount =
                (if result.Mask &&& 0x1000u <> 0u then
                     Known result.Mount
                 else
                     Unknown "The filesystem did not return a mount ID.")
              Kind = kind }

    let facts path =
        try
            if OperatingSystem.IsLinux() then
                let mutable result = Unchecked.defaultof<Statx>

                if statx (-100, path, 0x100, 0x1101u, &result) <> 0 then
                    error "statx"
                elif result.Mask &&& 1u = 0u then
                    Error UnsupportedEntry
                else
                    linuxFacts result
            elif OperatingSystem.IsWindows() then
                use handle = windowsHandle path false

                if handle.IsInvalid then
                    error "CreateFile"
                else
                    let mutable result = Unchecked.defaultof<FileId>

                    let identity =
                        if fileId (handle, 18, &result, 24u) <> 0 then
                            Known
                                { Device = WindowsVolume result.Volume
                                  Low = result.Low
                                  High = result.High }
                        else
                            Unknown(
                                "File ID query failed: " + Marshal.GetLastPInvokeError().ToString()
                            )

                    let attributes = File.GetAttributes path

                    let kind =
                        if attributes.HasFlag FileAttributes.ReparsePoint then
                            EntryKind.Link
                        elif attributes.HasFlag FileAttributes.Directory then
                            EntryKind.Directory
                        else
                            EntryKind.RegularFile

                    Ok
                        { File = identity
                          Mount = Unknown "Mount identity is not available from this adapter."
                          Kind = kind }
            else
                Error UnsupportedEntry
        with
        | :? EntryPointNotFoundException -> Error UnsupportedEntry
        | :? DllNotFoundException -> Error UnsupportedEntry

    let createHardLink source target =
        if OperatingSystem.IsLinux() then
            if link (source, target) = 0 then
                Observed
            else
                Refused("link failed: " + Marshal.GetLastPInvokeError().ToString())
        elif OperatingSystem.IsWindows() then
            if hardLink (windowsPath target, windowsPath source, 0n) <> 0 then
                Observed
            else
                Refused("CreateHardLink failed: " + Marshal.GetLastPInvokeError().ToString())
        else
            NotTested "This platform has no hard-link adapter."

    let directoryHandle path =
        if OperatingSystem.IsLinux() then
            let descriptor = openDirectory (path, 0xB0000)

            if descriptor < 0 then
                raise (
                    IOException(
                        "Opening the selected root failed: "
                        + Marshal.GetLastPInvokeError().ToString()
                    )
                )

            new SafeFileHandle(nativeint descriptor, true)
        elif OperatingSystem.IsWindows() then
            let handle = windowsHandle path false

            if handle.IsInvalid then
                handle.Dispose()

                raise (
                    IOException(
                        "Opening the selected root failed: "
                        + Marshal.GetLastPInvokeError().ToString()
                    )
                )

            handle
        else
            raise (PlatformNotSupportedException())

    let readableDirectoryHandle path =
        if OperatingSystem.IsWindows() then
            let handle = createFile (windowsPath path, 0x100081u, 3u, 0n, 3u, 0x02200000u, 0n)

            if handle.IsInvalid then
                handle.Dispose()
                raise (IOException("Opening the selected directory failed."))

            handle
        else
            directoryHandle path

    let handleFacts (handle: SafeFileHandle) =
        if OperatingSystem.IsLinux() then
            let mutable result = Unchecked.defaultof<Statx>

            if statx (int (handle.DangerousGetHandle()), "", 0x1000, 0x1101u, &result) <> 0 then
                error "statx handle"
            elif result.Mask &&& 1u = 0u then
                Error UnsupportedEntry
            else
                linuxFacts result
        elif OperatingSystem.IsWindows() then
            let mutable id = Unchecked.defaultof<FileId>
            let mutable attributes = Unchecked.defaultof<AttributeTag>

            if
                fileId (handle, 18, &id, 24u) = 0
                || attributeTag (handle, 9, &attributes, 8u) = 0
            then
                error "File handle identity"
            else
                Ok
                    { File =
                        Known
                            { Device = WindowsVolume id.Volume
                              Low = id.Low
                              High = id.High }
                      Mount = Unknown "Mount identity is not available from this adapter."
                      Kind =
                        if attributes.Attributes &&& 0x400u <> 0u then
                            EntryKind.Link
                        elif attributes.Attributes &&& 0x10u <> 0u then
                            EntryKind.Directory
                        else
                            EntryKind.RegularFile }
        else
            Error UnsupportedEntry
