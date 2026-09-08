namespace ModConductor.Platform

open System
open System.IO
open System.Runtime.InteropServices
open System.Security.AccessControl
open System.Security.Principal
open Microsoft.Win32.SafeHandles

[<Struct; StructLayout(LayoutKind.Sequential, Size = 112)>]
type private StatVfs =
    val mutable BlockSize: uint64
    val mutable FragmentSize: uint64
    val mutable Blocks: uint64
    val mutable Free: uint64
    val mutable Available: uint64

/// Native observations and ordinary write protection for owned generation storage.
module GenerationStorage =
    [<DllImport("libc", SetLastError = true)>]
    extern int private fstatvfs(int fd, StatVfs& result)

    [<DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)>]
    extern int private GetDiskFreeSpaceExW(
        string directory,
        uint64& available,
        uint64& total,
        uint64& free
    )

    let available (path: HostPath) identity =
        use held = HeldDirectory.Open(path, identity)

        if OperatingSystem.IsLinux() && Environment.Is64BitProcess then
            let mutable result = Unchecked.defaultof<StatVfs>

            if fstatvfs (int (held.Handle.DangerousGetHandle()), &result) <> 0 then
                raise (IOException("The storage capacity cannot be read."))

            Checked.(*) (int64 result.Available) (int64 result.FragmentSize)
        elif OperatingSystem.IsWindows() then
            let mutable available = 0UL
            let mutable total = 0UL
            let mutable free = 0UL

            if GetDiskFreeSpaceExW(HostPath.value path, &available, &total, &free) = 0 then
                raise (IOException("The storage capacity cannot be read."))

            int64 (min available (uint64 Int64.MaxValue))
        else
            raise (PlatformNotSupportedException())

    let protectDirectory (path: HostPath) identity =
        use held = HeldDirectory.Open(path, identity)

        if OperatingSystem.IsLinux() then
            File.SetUnixFileMode(held.Handle, UnixFileMode.UserRead ||| UnixFileMode.UserExecute)
        elif OperatingSystem.IsWindows() then
            let directory = DirectoryInfo(HostPath.value path)
            let security = directory.GetAccessControl()
            use user = WindowsIdentity.GetCurrent()

            security.AddAccessRule(
                FileSystemAccessRule(
                    user.User,
                    FileSystemRights.Write
                    ||| FileSystemRights.Delete
                    ||| FileSystemRights.DeleteSubdirectoriesAndFiles,
                    InheritanceFlags.None,
                    PropagationFlags.None,
                    AccessControlType.Deny
                )
            )

            directory.SetAccessControl security
        else
            raise (PlatformNotSupportedException())

    [<DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)>]
    extern SafeFileHandle private CreateFileW(
        string name,
        uint32 access,
        uint32 share,
        nativeint security,
        uint32 creation,
        uint32 flags,
        nativeint template
    )

    [<DllImport("advapi32.dll", SetLastError = true)>]
    extern int private GetKernelObjectSecurity(
        SafeFileHandle handle,
        uint32 information,
        byte[] descriptor,
        uint32 length,
        uint32& needed
    )

    [<DllImport("advapi32.dll", SetLastError = true)>]
    extern int private SetKernelObjectSecurity(
        SafeFileHandle handle,
        uint32 information,
        byte[] descriptor
    )

    let protectLink (root: HeldDirectory) name expected =
        if root.InspectEntry name <> Some expected || expected.Kind <> EntryKind.Link then
            raise (IOException("The prepared link changed before protection."))

        if OperatingSystem.IsWindows() then
            let path = HeldEntries.path root.Handle name
            use entry = CreateFileW(path, 0x60000u, 7u, 0n, 3u, 0x02200000u, 0n)

            if entry.IsInvalid then
                raise (IOException("The link security cannot be opened."))

            match Native.handleFacts entry with
            | Ok { File = Known identity
                   Kind = EntryKind.Link } when identity = expected.Identity -> ()
            | _ -> raise (IOException("The link identity changed before protection."))

            let mutable needed = 0u
            GetKernelObjectSecurity(entry, 4u, null, 0u, &needed) |> ignore

            if needed = 0u || needed > 65536u then
                raise (IOException("The link security is unavailable."))

            let descriptor = Array.zeroCreate<byte> (int needed)

            if GetKernelObjectSecurity(entry, 4u, descriptor, needed, &needed) = 0 then
                raise (IOException("The link security cannot be read."))

            let security = FileSecurity()
            security.SetSecurityDescriptorBinaryForm(descriptor, AccessControlSections.Access)
            use user = WindowsIdentity.GetCurrent()

            security.AddAccessRule(
                FileSystemAccessRule(user.User, FileSystemRights.Delete, AccessControlType.Deny)
            )

            if
                SetKernelObjectSecurity(entry, 4u, security.GetSecurityDescriptorBinaryForm()) = 0
            then
                raise (IOException("The link cannot be protected from ordinary replacement."))
