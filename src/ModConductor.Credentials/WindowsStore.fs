namespace ModConductor.Credentials

open System
open System.Runtime.InteropServices

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private NativeCredential =
    val mutable Flags: uint32
    val mutable Type: uint32
    val mutable TargetName: nativeint
    val mutable Comment: nativeint
    val mutable LastWritten: int64
    val mutable BlobSize: uint32
    val mutable Blob: nativeint
    val mutable Persist: uint32
    val mutable AttributeCount: uint32
    val mutable Attributes: nativeint
    val mutable TargetAlias: nativeint
    val mutable UserName: nativeint

module private WindowsCredentials =
    [<DllImport("advapi32.dll",
                EntryPoint = "CredReadW",
                CharSet = CharSet.Unicode,
                SetLastError = true)>]
    extern int read(string target, uint32 kind, uint32 flags, nativeint& credential)

    [<DllImport("advapi32.dll",
                EntryPoint = "CredWriteW",
                CharSet = CharSet.Unicode,
                SetLastError = true)>]
    extern int write(NativeCredential& credential, uint32 flags)

    [<DllImport("advapi32.dll",
                EntryPoint = "CredDeleteW",
                CharSet = CharSet.Unicode,
                SetLastError = true)>]
    extern int delete(string target, uint32 kind, uint32 flags)

    [<DllImport("advapi32.dll", EntryPoint = "CredFree")>]
    extern void free(nativeint value)

    let target = "ModConductor/NexusMods"

    let error =
        function
        | 5 -> StorageProblem.Denied
        | 1312 -> StorageProblem.Unavailable
        | _ -> StorageProblem.Failed

    let clear pointer count =
        for offset in 0 .. count - 1 do
            Marshal.WriteByte(pointer, offset, 0uy)

    let withCredential action =
        let mutable pointer = 0n

        if read (target, 1u, 0u, &pointer) = 0 then
            match Marshal.GetLastPInvokeError() with
            | 1168 -> Ok None
            | code -> Error(error code)
        else
            let credential = Marshal.PtrToStructure<NativeCredential> pointer

            try
                Ok(Some(action credential))
            finally
                clear credential.Blob (int credential.BlobSize)
                free pointer

type WindowsCredentialStore() =
    interface ICredentialStore with
        member _.Kind = StorageKind.CredentialManager

        member _.Inspect token =
            token.ThrowIfCancellationRequested()

            match WindowsCredentials.withCredential (fun _ -> ()) with
            | Ok value ->
                { Saved =
                    (if value.IsSome then
                         SavedPresence.Present
                     else
                         SavedPresence.Absent)
                  Problem = None }
            | Error problem ->
                { Saved = SavedPresence.Unknown
                  Problem = Some problem }

        member _.Read token =
            token.ThrowIfCancellationRequested()

            WindowsCredentials.withCredential (fun credential ->
                let bytes = Array.zeroCreate<byte> (int credential.BlobSize)
                Marshal.Copy(credential.Blob, bytes, 0, bytes.Length)
                bytes)

        member _.Save(data, token) =
            token.ThrowIfCancellationRequested()

            if data.Length > 2560 then
                Error StorageProblem.TooLarge
            else
                let name = Marshal.StringToCoTaskMemUni WindowsCredentials.target
                let blob = Marshal.AllocCoTaskMem data.Length

                try
                    Marshal.Copy(data, 0, blob, data.Length)
                    let mutable credential = Unchecked.defaultof<NativeCredential>
                    credential.Type <- 1u
                    credential.TargetName <- name
                    credential.BlobSize <- uint32 data.Length
                    credential.Blob <- blob
                    credential.Persist <- 2u

                    if WindowsCredentials.write (&credential, 0u) <> 0 then
                        Ok()
                    else
                        Error(WindowsCredentials.error (Marshal.GetLastPInvokeError()))
                finally
                    WindowsCredentials.clear blob data.Length
                    Marshal.FreeCoTaskMem blob
                    Marshal.FreeCoTaskMem name

        member _.Delete token =
            token.ThrowIfCancellationRequested()

            if WindowsCredentials.delete (WindowsCredentials.target, 1u, 0u) <> 0 then
                Ok()
            else
                match Marshal.GetLastPInvokeError() with
                | 1168 -> Ok()
                | code -> Error(WindowsCredentials.error code)
