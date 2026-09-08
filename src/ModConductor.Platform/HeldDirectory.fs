namespace ModConductor.Platform

open System
open System.IO
open System.Runtime.InteropServices
open Microsoft.Win32.SafeHandles

module private DirectoryNames =
    [<DllImport("libc", SetLastError = true)>]
    extern int dup(int descriptor)

    [<DllImport("libc", SetLastError = true)>]
    extern nativeint fdopendir(int descriptor)

    [<DllImport("libc", SetLastError = true)>]
    extern nativeint readdir(nativeint directory)

    [<DllImport("libc")>]
    extern void rewinddir(nativeint directory)

    [<DllImport("libc")>]
    extern int closedir(nativeint directory)

    [<DllImport("libc")>]
    extern int close(int descriptor)

    [<DllImport("kernel32.dll", EntryPoint = "GetFileInformationByHandleEx", SetLastError = true)>]
    extern int windowsNames(
        SafeFileHandle handle,
        int informationClass,
        nativeint buffer,
        uint32 size
    )

    let enumerate (handle: SafeFileHandle) =
        seq {
            if OperatingSystem.IsLinux() then
                let descriptor = dup (int (handle.DangerousGetHandle()))

                if descriptor < 0 then
                    raise (IOException("Opening the directory listing failed."))

                let directory = fdopendir descriptor

                if directory = 0n then
                    close descriptor |> ignore
                    raise (IOException("Reading the directory failed."))

                try
                    rewinddir directory
                    let mutable reading = true

                    while reading do
                        Marshal.SetLastPInvokeError 0
                        let entry = readdir directory

                        if entry = 0n then
                            if Marshal.GetLastPInvokeError() <> 0 then
                                raise (IOException("Reading the directory failed."))

                            reading <- false
                        else
                            // Linux x64 dirent: inode, offset, record length, type, then name.
                            let name = Marshal.PtrToStringUTF8(entry + 19n)

                            if name <> "." && name <> ".." then
                                yield name
                finally
                    closedir directory |> ignore
            elif OperatingSystem.IsWindows() then
                let buffer = Marshal.AllocHGlobal 65536

                try
                    let mutable reading = true
                    let mutable restart = true

                    while reading do
                        let result =
                            windowsNames (handle, (if restart then 11 else 10), buffer, 65536u)

                        restart <- false

                        if result = 0 then
                            if Marshal.GetLastPInvokeError() <> 18 then
                                raise (IOException("Reading the directory failed."))

                            reading <- false
                        else
                            let mutable offset = 0
                            let mutable more = true

                            while more do
                                let entry = buffer + nativeint offset
                                let length = Marshal.ReadInt32(entry, 60)
                                let name = Marshal.PtrToStringUni(entry + 104n, length / 2)

                                if name <> "." && name <> ".." then
                                    yield name

                                let next = Marshal.ReadInt32 entry
                                more <- next <> 0
                                offset <- offset + next
                finally
                    Marshal.FreeHGlobal buffer
            else
                raise (PlatformNotSupportedException())
        }

module private DirectoryLinks =
    [<DllImport("libc", SetLastError = true)>]
    extern nativeint readlinkat(int directory, string name, [<Out>] byte[] target, unativeint size)

    let read (handle: SafeFileHandle) (name: string) =
        if not (OperatingSystem.IsLinux()) then
            raise (PlatformNotSupportedException())

        if
            name = ""
            || name = "."
            || name = ".."
            || name.Contains('/')
            || name.Contains('\000')
        then
            invalidArg (nameof name) "Select one directory entry."

        let bytes = Array.zeroCreate<byte> 4097

        let count =
            readlinkat (int (handle.DangerousGetHandle()), name, bytes, unativeint bytes.Length)

        if count < 0n then
            match Marshal.GetLastPInvokeError() with
            | 2
            | 22 -> None
            | _ -> raise (IOException "Reading the directory link failed.")
        elif count >= nativeint bytes.Length then
            raise (IOException "The directory link is too long.")
        else
            Some(System.Text.UTF8Encoding(false, true).GetString(bytes, 0, int count))

/// A held directory is a file-operation boundary, not authority over unregistered children.
type HeldDirectory private (handle: SafeFileHandle) =
    let identity kind child =
        match Native.handleFacts child with
        | Ok { File = Known id; Kind = actual } when actual = kind -> id
        | _ -> raise (IOException("The held object identity is not available or its type changed."))

    member _.Identity = identity EntryKind.Directory handle
    member _.Names = DirectoryNames.enumerate handle
    member _.ReadLink(name) = DirectoryLinks.read handle name
    member internal _.Handle = handle
    member _.InspectEntry(name) = HeldEntries.inspect handle name

    member _.CreateLink(name, target, directory) =
        HeldEntries.createLink handle name target directory

    member _.RemoveLink(name, expected) =
        HeldEntries.removeLink handle name expected

    member _.RemoveFile(name, expected) =
        HeldEntries.removeFile handle name expected

    member _.RemoveDirectory(name, expected) =
        HeldEntries.removeDirectory handle name expected

    member _.MoveOriginal(name, expected, destination: HeldDirectory, target) =
        HeldEntries.moveOriginal handle name destination.Handle target expected

    member _.Directory(name, expected: FileIdentity option) =
        let child = RelativeFile.openChild handle name true false

        try
            let actual = identity EntryKind.Directory child

            if expected |> Option.exists ((<>) actual) then
                raise (IOException("The folder changed."))

            new HeldDirectory(child)
        with _ ->
            child.Dispose()
            reraise ()

    member _.CreateDirectory(name) =
        let child = RelativeFile.openChild handle name true true

        try
            identity EntryKind.Directory child |> ignore
            new HeldDirectory(child)
        with _ ->
            child.Dispose()
            reraise ()

    member _.Read(name, expected: FileIdentity option) =
        let child = RelativeFile.openChild handle name false false

        try
            let actual = identity EntryKind.RegularFile child

            if expected |> Option.exists ((<>) actual) then
                raise (IOException("The file changed."))

            new FileStream(child, FileAccess.Read), actual
        with _ ->
            child.Dispose()
            reraise ()

    member _.Create(name) =
        let child = RelativeFile.openChild handle name false true

        try
            let actual = identity EntryKind.RegularFile child
            new FileStream(child, FileAccess.ReadWrite), actual
        with _ ->
            child.Dispose()
            reraise ()

    static member Open(path, expected) =
        let handle = Native.readableDirectoryHandle (HostPath.value path)

        try
            let directory = new HeldDirectory(handle)

            if directory.Identity <> expected then
                raise (IOException("The selected root changed."))

            directory
        with _ ->
            handle.Dispose()
            reraise ()

    interface IDisposable with
        member _.Dispose() = handle.Dispose()
