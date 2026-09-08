namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.AccessControl
open System.Security.Principal

module internal GenerationCleanup =
    /// Restores only the owned fixture's permissions after all protection assertions.
    let normalize root =
        let rec walk (path: string) =
            let attributes = File.GetAttributes path
            let link = attributes.HasFlag FileAttributes.ReparsePoint
            let directory = attributes.HasFlag FileAttributes.Directory

            if OperatingSystem.IsWindows() then
                use user = WindowsIdentity.GetCurrent()

                if directory then
                    let info = DirectoryInfo path
                    let security = info.GetAccessControl()

                    security.RemoveAccessRuleSpecific(
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

                    info.SetAccessControl security
                elif link then
                    let info = FileInfo path
                    let security = info.GetAccessControl()

                    security.RemoveAccessRuleSpecific(
                        FileSystemAccessRule(
                            user.User,
                            FileSystemRights.Delete,
                            AccessControlType.Deny
                        )
                    )

                    info.SetAccessControl security
                elif attributes.HasFlag FileAttributes.ReadOnly then
                    File.SetAttributes(path, attributes &&& ~~~FileAttributes.ReadOnly)
            elif directory && not link then
                File.SetUnixFileMode(
                    path,
                    UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
                )

            if directory && not link then
                for child in Directory.GetFileSystemEntries path do
                    walk child

        walk root
