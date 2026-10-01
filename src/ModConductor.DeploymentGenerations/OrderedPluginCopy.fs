namespace ModConductor.DeploymentGenerations

open System
open System.IO
open System.Threading
open ModConductor.Platform
open ModConductor.DeploymentRecovery

module internal OrderedPluginCopy =
    let private writable (path: string) =
        if OperatingSystem.IsWindows() then
            File.SetAttributes(path, FileAttributes.Normal)
        else
            File.SetUnixFileMode(path, UnixFileMode.UserRead ||| UnixFileMode.UserWrite)

    let private finish parent name expectedLength (modified: DateTime) =
        let entry = (parent: HeldDirectory).InspectFile(name, None)

        if entry.Length <> expectedLength then
            RecoveryFiles.fail "A copied plugin changed length."

        use stream = parent.Write(name, entry.Identity)
        File.SetLastWriteTimeUtc(stream.SafeFileHandle, modified)
        stream.Flush true

        if OperatingSystem.IsWindows() then
            File.SetAttributes(stream.SafeFileHandle, FileAttributes.ReadOnly)
        else
            File.SetUnixFileMode(stream.SafeFileHandle, UnixFileMode.UserRead)

        entry.Identity

    let copy (token: CancellationToken) pin source destination path modified =
        token.ThrowIfCancellationRequested()
        GenerationFiles.verify pin source
        let input = RecoveryFiles.path source.Directory source.Path
        let output = RecoveryFiles.path destination path

        GenerationFiles.withCreatedParent destination path (fun parent name ->
            File.Copy(input, output, false)
            token.ThrowIfCancellationRequested()
            GenerationFiles.verify pin source
            writable output
            finish parent name (GenerationFiles.length pin) modified)
