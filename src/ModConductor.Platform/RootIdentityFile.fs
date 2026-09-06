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

module RootIdentityFile =
    let name = ".mod-conductor-root"

    [<DllImport("libc", EntryPoint = "openat", SetLastError = true)>]
    extern int private openAt(
        int directory,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string name,
        int flags,
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

    let private openFile (root: SafeFileHandle) create =
        if OperatingSystem.IsLinux() then
            let flags = 0xA0800 ||| (if create then 0xC1 else 0)
            let descriptor = openAt (int (root.DangerousGetHandle()), name, flags, 0x180u)

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
                        (if create then 0x100082u else 0x100081u),
                        &attributes,
                        &status,
                        0n,
                        0x80u,
                        1u,
                        (if create then 2u else 1u),
                        0x200060u,
                        0n,
                        0u
                    )

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

    let private identity kind handle =
        match Native.handleFacts handle with
        | Ok { File = Known id; Kind = actual } when kind = actual -> id
        | _ -> raise (IOException("The held object identity is not available or its type changed."))

    let private openRoot path expectedIdentity =
        let handle = Native.directoryHandle (HostPath.value path)

        try
            let actual = identity EntryKind.Directory handle

            if expectedIdentity <> actual then
                raise (IOException("The selected root changed."))

            handle
        with _ ->
            handle.Dispose()
            reraise ()

    let private checkContents (contents: byte array) =
        if isNull contents || contents.Length = 0 || contents.Length > 256 then
            invalidArg "contents" "Use a root identity record of 1 to 256 bytes."

    let validateRoot path expectedIdentity =
        use directory = openRoot path expectedIdentity
        ()

    let create path rootIdentity (contents: byte array) =
        checkContents contents
        use directory = openRoot path rootIdentity
        use handle = openFile directory true
        use file = new FileStream(handle, FileAccess.Write)
        file.Write contents
        file.Flush true
        identity EntryKind.RegularFile handle

    let matches path rootIdentity expectedIdentity (contents: byte array) =
        checkContents contents
        use directory = openRoot path rootIdentity
        use handle = openFile directory false

        if identity EntryKind.RegularFile handle <> expectedIdentity then
            false
        else
            use file = new FileStream(handle, FileAccess.Read)
            let observed = Array.zeroCreate<byte> (contents.Length + 1)
            let mutable count = 0
            let mutable reading = true

            while reading && count < observed.Length do
                let read = file.Read(observed, count, observed.Length - count)
                if read = 0 then reading <- false else count <- count + read

            count = contents.Length && observed[0 .. count - 1] = contents
