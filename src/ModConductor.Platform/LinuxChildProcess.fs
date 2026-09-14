namespace ModConductor.Platform

open System
open System.IO
open System.ComponentModel
open System.Runtime.InteropServices
open System.Threading.Tasks

// glibc Linux x64 spawn types. The selected native adapter is qualified on this ABI.
[<Struct; StructLayout(LayoutKind.Sequential, Size = 336)>]
type private SpawnAttributes =
    val mutable Flags: int16

[<Struct; StructLayout(LayoutKind.Sequential, Size = 80)>]
type private SpawnActions =
    val mutable Allocated: int

module internal LinuxChildProcess =
    [<DllImport("libc")>]
    extern int private posix_spawnattr_init(SpawnAttributes& attributes)

    [<DllImport("libc")>]
    extern int private posix_spawnattr_destroy(SpawnAttributes& attributes)

    [<DllImport("libc")>]
    extern int private posix_spawnattr_setflags(SpawnAttributes& attributes, int16 flags)

    [<DllImport("libc")>]
    extern int private posix_spawnattr_setpgroup(SpawnAttributes& attributes, int group)

    [<DllImport("libc")>]
    extern int private posix_spawn_file_actions_init(SpawnActions& actions)

    [<DllImport("libc")>]
    extern int private posix_spawn_file_actions_destroy(SpawnActions& actions)

    [<DllImport("libc")>]
    extern int private posix_spawn_file_actions_addopen(
        SpawnActions& actions,
        int fd,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string path,
        int flags,
        uint32 mode
    )

    [<DllImport("libc")>]
    extern int private posix_spawn_file_actions_addchdir_np(
        SpawnActions& actions,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string path
    )

    [<DllImport("libc")>]
    extern int private posix_spawn_file_actions_addclosefrom_np(SpawnActions& actions, int fd)

    [<DllImport("libc")>]
    extern int private posix_spawn(
        int& pid,
        [<MarshalAs(UnmanagedType.LPUTF8Str)>] string path,
        SpawnActions& actions,
        SpawnAttributes& attributes,
        nativeint argv,
        nativeint environment
    )

    [<DllImport("libc", SetLastError = true)>]
    extern int private waitpid(int pid, int& status, int options)

    [<DllImport("libc", SetLastError = true)>]
    extern int private kill(int pid, int signal)

    let private check code =
        if code <> 0 then
            raise (Win32Exception code)

    type private Strings(values: string array) =
        let strings = values |> Array.map Marshal.StringToCoTaskMemUTF8
        let pointer = Marshal.AllocHGlobal((strings.Length + 1) * IntPtr.Size)

        do
            for i in 0 .. strings.Length - 1 do
                Marshal.WriteIntPtr(pointer, i * IntPtr.Size, strings[i])

            Marshal.WriteIntPtr(pointer, strings.Length * IntPtr.Size, 0n)

        member _.Pointer = pointer

        interface IDisposable with
            member _.Dispose() =
                for value in strings do
                    Marshal.FreeCoTaskMem value

                Marshal.FreeHGlobal pointer

    let private stat pid =
        use reader = new StreamReader("/proc/" + string pid + "/stat")
        let buffer = Array.zeroCreate<char> 8192
        let count = reader.ReadBlock(buffer, 0, buffer.Length)

        if count = buffer.Length then
            raise (IOException "The native process observation exceeds its read limit.")

        let text = String(buffer, 0, count)
        let ending = text.LastIndexOf(')')

        if ending < 0 then
            raise (IOException "The native process identity is unavailable.")

        let fields =
            text.Substring(ending + 2).Split(' ', StringSplitOptions.RemoveEmptyEntries)

        if fields.Length < 20 then
            raise (IOException "The native process identity is incomplete.")

        fields[0], Int32.Parse fields[2], Int64.Parse fields[19]

    let private reap pid =
        Task.Run<int>(
            Func<int>(fun () ->
                let mutable status = 0
                let mutable result = waitpid (pid, &status, 0)

                while result = -1 && Marshal.GetLastPInvokeError() = 4 do
                    result <- waitpid (pid, &status, 0)

                if result = -1 then
                    raise (Win32Exception(Marshal.GetLastPInvokeError()))

                if status &&& 127 = 0 then
                    (status >>> 8) &&& 255
                else
                    128 + (status &&& 127))
        )

    let startWithStreams (streams: NativeStreamFiles option) (request: NativeLaunch) =
        if RuntimeInformation.ProcessArchitecture <> Architecture.X64 then
            raise (
                PlatformNotSupportedException
                    "Native launch is not qualified for this Linux architecture."
            )

        let mutable attributes = Unchecked.defaultof<SpawnAttributes>
        check (posix_spawnattr_init &attributes)

        try
            let mutable actions = Unchecked.defaultof<SpawnActions>
            check (posix_spawn_file_actions_init &actions)

            try
                check (posix_spawnattr_setflags (&attributes, 2s))
                check (posix_spawnattr_setpgroup (&attributes, 0))
                check (posix_spawn_file_actions_addchdir_np (&actions, request.WorkingDirectory))

                let paths =
                    match streams with
                    | None -> [| "/dev/null"; "/dev/null"; "/dev/null" |]
                    | Some value -> [| value.Input; value.Output; value.Error |]

                for fd in 0..2 do
                    check (
                        posix_spawn_file_actions_addopen (
                            &actions,
                            fd,
                            paths[fd],
                            (if fd = 0 then 0 else 577),
                            (if fd = 0 then 0u else 384u)
                        )
                    )

                check (posix_spawn_file_actions_addclosefrom_np (&actions, 3))
                use argv = new Strings(Array.ofList (request.Executable :: request.Arguments))
                use environment = new Strings(ChildEnvironment.build request.Environment)
                let mutable pid = 0

                check (
                    posix_spawn (
                        &pid,
                        request.Executable,
                        &actions,
                        &attributes,
                        argv.Pointer,
                        environment.Pointer
                    )
                )
                // The direct child is not reaped until this identity read has completed.
                let identity =
                    try
                        let _, _, born = stat pid in Some born
                    with :? IOException ->
                        None

                let exited = reap pid
                let mutable disposed = false

                { new INativeRun with
                    member _.ProcessId = pid
                    member _.Scope = "Linux process group"
                    member _.RootExit = exited

                    member _.TerminateScope() =
                        if disposed then
                            raise (ObjectDisposedException "native run")

                        match identity with
                        | Some expected ->
                            try
                                let _, _, born = stat pid

                                if born <> expected then
                                    raise (
                                        IOException
                                            "The original process group can no longer be identified."
                                    )
                            with
                            | :? FileNotFoundException
                            | :? DirectoryNotFoundException -> ()
                        | None ->
                            raise (IOException "The original process identity was not observed.")

                        let result = kill (-pid, 9)
                        let code = if result = 0 then 0 else Marshal.GetLastPInvokeError()

                        if code <> 0 && code <> 3 then
                            raise (Win32Exception code)

                    member _.Observe() =
                        if disposed then
                            raise (ObjectDisposedException "native run")

                        match identity with
                        | Some expected ->
                            try
                                let _, _, born = stat pid

                                if born <> expected then
                                    raise (
                                        IOException
                                            "The original process group can no longer be identified."
                                    )
                            with
                            | :? FileNotFoundException
                            | :? DirectoryNotFoundException -> ()
                        | None ->
                            raise (IOException "The original process identity was not observed.")

                        let exists = kill (-pid, 0)
                        let code = if exists = 0 then 0 else Marshal.GetLastPInvokeError()

                        if code <> 0 && code <> 3 then
                            raise (Win32Exception code)

                        let mutable active = 0

                        if exists = 0 then
                            let mutable examined = 0

                            for directory in Directory.EnumerateDirectories "/proc" do
                                match Int32.TryParse(Path.GetFileName directory) with
                                | true, candidate ->
                                    examined <- examined + 1

                                    if examined > 65536 then
                                        raise (
                                            IOException
                                                "The native process observation exceeds its entry limit."
                                        )

                                    try
                                        let state, group, _ = stat candidate

                                        if group = pid && state <> "Z" then
                                            active <- active + 1
                                    with
                                    | :? FileNotFoundException
                                    | :? DirectoryNotFoundException -> ()
                                | _ -> ()
                            // A census alone is not proof that a group ended, including during fork/reaping.
                            ()

                        { RootExitCode =
                            if exited.IsCompleted then
                                Some(exited.GetAwaiter().GetResult())
                            else
                                None
                          ActiveProcesses = if exists = 0 && active = 0 then None else Some active
                          ScopeEnded = code = 3 }

                    member _.Dispose() = disposed <- true }
            finally
                posix_spawn_file_actions_destroy &actions |> ignore
        finally
            posix_spawnattr_destroy &attributes |> ignore

    let start request = startWithStreams None request
