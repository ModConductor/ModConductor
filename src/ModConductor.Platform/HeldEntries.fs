namespace ModConductor.Platform

open System
open System.IO
open System.Runtime.InteropServices
open System.Text
open Microsoft.Win32.SafeHandles

type HeldEntry =
    { Identity: FileIdentity
      Kind: EntryKind
      LinkTarget: string option
      DirectoryLink: bool option }

module internal HeldEntries =
    [<DllImport("kernel32.dll",
                EntryPoint = "GetFinalPathNameByHandleW",
                CharSet = CharSet.Unicode,
                SetLastError = true)>]
    extern uint32 private finalPath(
        SafeFileHandle handle,
        StringBuilder path,
        uint32 length,
        uint32 flags
    )

    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern int private DeviceIoControl(
        SafeFileHandle handle,
        uint32 code,
        nativeint input,
        uint32 inputSize,
        byte[] output,
        uint32 outputSize,
        uint32& returned,
        nativeint overlapped
    )

    [<DllImport("libc", SetLastError = true)>]
    extern int private symlinkat(string target, int directory, string name)

    [<DllImport("libc", SetLastError = true)>]
    extern int private unlinkat(int directory, string name, int flags)

    [<DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)>]
    extern int private DeleteFileW(string name)

    [<DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)>]
    extern int private RemoveDirectoryW(string name)

    [<DllImport("libc", SetLastError = true)>]
    extern int private renameat2(
        int source,
        string name,
        int destination,
        string target,
        uint32 flags
    )

    let private nameCheck (name: string) =
        if
            String.IsNullOrEmpty name
            || name = "."
            || name = ".."
            || name.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0
        then
            invalidArg (nameof name) "Select one native directory entry."

    let path (handle: SafeFileHandle) name =
        nameCheck name

        if OperatingSystem.IsLinux() then
            "/proc/self/fd/" + string (handle.DangerousGetHandle()) + "/" + name
        elif OperatingSystem.IsWindows() then
            let text = StringBuilder(32768)
            let count = finalPath (handle, text, uint32 text.Capacity, 0u)

            if count = 0u || count >= uint32 text.Capacity then
                raise (IOException "The held directory path is unavailable.")

            Path.Combine(text.ToString(), name)
        else
            raise (PlatformNotSupportedException())

    let inspect handle name =
        let child = path handle name

        match Native.facts child with
        | Error(NativeError failure) when
            failure.Code = 2 || (OperatingSystem.IsWindows() && failure.Code = 3)
            ->
            None
        | Error _ -> raise (IOException "The directory entry cannot be inspected.")
        | Ok { File = Unknown _ } ->
            raise (IOException "The directory entry has no stable identity.")
        | Ok { File = Known identity; Kind = kind } ->
            let target, directory =
                if kind <> EntryKind.Link then
                    None, None
                elif OperatingSystem.IsWindows() then
                    use entry = Native.directoryHandle child
                    let bytes = Array.zeroCreate<byte> 16384
                    let mutable count = 0u

                    if
                        DeviceIoControl(
                            entry,
                            0x900A8u,
                            0n,
                            0u,
                            bytes,
                            uint32 bytes.Length,
                            &count,
                            0n
                        ) = 0
                        || count < 20u
                    then
                        raise (IOException "The link data is unavailable.")

                    if BitConverter.ToUInt32(bytes, 0) <> 0xA000000Cu then
                        None, None
                    else
                        let info: FileSystemInfo =
                            if File.GetAttributes(child).HasFlag FileAttributes.Directory then
                                DirectoryInfo(child)
                            else
                                FileInfo(child)

                        Some info.LinkTarget, Some(info.Attributes.HasFlag FileAttributes.Directory)
                else
                    Some(FileInfo(child).LinkTarget), None

            Some
                { Identity = identity
                  Kind = kind
                  LinkTarget = target
                  DirectoryLink = directory }

    let createLink (handle: SafeFileHandle) name (target: string) directory =
        nameCheck name

        if String.IsNullOrEmpty target || target.Contains('\000') then
            invalidArg (nameof target) "Select a link target."

        if OperatingSystem.IsLinux() then
            if symlinkat (target, int (handle.DangerousGetHandle()), name) <> 0 then
                raise (
                    IOException(
                        "Creating the symbolic link failed: "
                        + string (Marshal.GetLastPInvokeError())
                    )
                )
        elif directory then
            Directory.CreateSymbolicLink(path handle name, target) |> ignore
        else
            File.CreateSymbolicLink(path handle name, target) |> ignore

        inspect handle name
        |> Option.defaultWith (fun () -> raise (IOException "The created link is missing."))

    let removeLink (handle: SafeFileHandle) name (expected: HeldEntry) =
        match inspect handle name with
        | Some actual when
            actual = expected && actual.Kind = EntryKind.Link && actual.LinkTarget.IsSome
            ->
            if OperatingSystem.IsLinux() then
                if unlinkat (int (handle.DangerousGetHandle()), name, 0) <> 0 then
                    raise (IOException "Removing the owned link failed.")
            elif actual.DirectoryLink = Some true then
                Directory.Delete(path handle name, false)
            else
                File.Delete(path handle name)
        | _ -> raise (IOException "The owned link changed; it was left untouched.")

    let unlink (handle: SafeFileHandle) name =
        nameCheck name

        if OperatingSystem.IsLinux() then
            if unlinkat (int (handle.DangerousGetHandle()), name, 0) <> 0 then
                match Marshal.GetLastPInvokeError() with
                | 2 -> ()
                | error -> raise (IOException("Removing the owned entry failed: " + string error))
        elif OperatingSystem.IsWindows() then
            let child = path handle name

            if DeleteFileW child = 0 then
                match Marshal.GetLastPInvokeError() with
                | 2
                | 3 -> ()
                | _ when RemoveDirectoryW child <> 0 -> ()
                | _ ->
                    raise (
                        IOException(
                            "Removing the owned entry failed: "
                            + string (Marshal.GetLastPInvokeError())
                        )
                    )
        else
            raise (PlatformNotSupportedException())

    let removeFile (handle: SafeFileHandle) name expected =
        match inspect handle name with
        | Some actual when actual.Kind = EntryKind.RegularFile && actual.Identity = expected ->
            if OperatingSystem.IsLinux() then
                if unlinkat (int (handle.DangerousGetHandle()), name, 0) <> 0 then
                    raise (IOException "Removing the owned file failed.")
            else
                let file = path handle name
                let attributes = File.GetAttributes file

                if attributes.HasFlag FileAttributes.ReadOnly then
                    File.SetAttributes(file, attributes &&& ~~~FileAttributes.ReadOnly)

                File.Delete file
        | _ -> raise (IOException "The owned file changed; it was left untouched.")

    let removeDirectory (handle: SafeFileHandle) name expected =
        match inspect handle name with
        | Some actual when actual.Kind = EntryKind.Directory && actual.Identity = expected ->
            if OperatingSystem.IsLinux() then
                if unlinkat (int (handle.DangerousGetHandle()), name, 0x200) <> 0 then
                    raise (IOException "Removing the empty owned directory failed.")
            else
                Directory.Delete(path handle name, false)
        | _ -> raise (IOException "The owned directory changed; it was left untouched.")

    let moveOriginal
        (source: SafeFileHandle)
        name
        (destination: SafeFileHandle)
        target
        (expected: HeldEntry)
        =
        nameCheck name
        nameCheck target

        if inspect source name <> Some expected then
            raise (IOException "The original entry changed.")

        if inspect destination target |> Option.isSome then
            raise (IOException "The original destination is occupied.")

        match Native.handleFacts destination with
        | Ok { File = Known identity } when identity.Device = expected.Identity.Device -> ()
        | _ -> raise (IOException "Original preservation requires the same volume.")

        if OperatingSystem.IsLinux() then
            if
                renameat2 (
                    int (source.DangerousGetHandle()),
                    name,
                    int (destination.DangerousGetHandle()),
                    target,
                    1u
                )
                <> 0
            then
                raise (IOException "Moving the original without replacement failed.")
        elif expected.Kind = EntryKind.Directory then
            Directory.Move(path source name, path destination target)
        else
            File.Move(path source name, path destination target, false)

    let replaceFile
        (directory: SafeFileHandle)
        sourceName
        sourceIdentity
        destinationName
        (destination: HeldEntry option)
        =
        nameCheck sourceName
        nameCheck destinationName

        match inspect directory sourceName with
        | Some source when
            source.Kind = EntryKind.RegularFile && source.Identity = sourceIdentity
            -> ()
        | _ -> raise (IOException "The staged file changed.")

        if inspect directory destinationName <> destination then
            raise (IOException "The destination changed.")

        if destination |> Option.exists (fun value -> value.Kind <> EntryKind.RegularFile) then
            raise (IOException "The destination is not a regular file.")

        if OperatingSystem.IsLinux() then
            if
                renameat2 (
                    int (directory.DangerousGetHandle()),
                    sourceName,
                    int (directory.DangerousGetHandle()),
                    destinationName,
                    (if destination.IsNone then 1u else 0u)
                )
                <> 0
            then
                raise (IOException "The staged file could not replace the destination.")
        elif OperatingSystem.IsWindows() then
            File.Move(
                path directory sourceName,
                path directory destinationName,
                destination.IsSome
            )
        else
            raise (PlatformNotSupportedException())
