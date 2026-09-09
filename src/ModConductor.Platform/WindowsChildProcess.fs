namespace ModConductor.Platform

open System
open System.Text
open System.ComponentModel
open System.Runtime.InteropServices
open System.Threading.Tasks

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private ChildSecurity =
    val mutable Length: uint32
    val mutable Descriptor: nativeint
    val mutable Inherit: int

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private ChildStartup =
    val mutable Size: uint32
    val mutable Reserved: nativeint
    val mutable Desktop: nativeint
    val mutable Title: nativeint
    val mutable X: uint32
    val mutable Y: uint32
    val mutable Width: uint32
    val mutable Height: uint32
    val mutable XChars: uint32
    val mutable YChars: uint32
    val mutable Fill: uint32
    val mutable Flags: uint32
    val mutable Show: uint16
    val mutable ReservedCount: uint16
    val mutable ReservedBytes: nativeint
    val mutable Input: nativeint
    val mutable Output: nativeint
    val mutable Error: nativeint
    val mutable Attributes: nativeint

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private ChildInformation =
    val mutable Process: nativeint
    val mutable Thread: nativeint
    val mutable ProcessId: uint32
    val mutable ThreadId: uint32

[<Struct; StructLayout(LayoutKind.Sequential)>]
type private JobAccounting =
    val mutable UserTime: int64
    val mutable KernelTime: int64
    val mutable PeriodUser: int64
    val mutable PeriodKernel: int64
    val mutable PageFaults: uint32
    val mutable Total: uint32
    val mutable Active: uint32
    val mutable Terminated: uint32

module internal WindowsChildProcess =
    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern bool private CloseHandle(nativeint handle)

    [<DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)>]
    extern nativeint private CreateFileW(
        string name,
        uint32 access,
        uint32 share,
        ChildSecurity& security,
        uint32 creation,
        uint32 flags,
        nativeint template
    )

    [<DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)>]
    extern nativeint private CreateJobObjectW(nativeint attributes, string name)

    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern bool private AssignProcessToJobObject(nativeint job, nativeint child)

    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern bool private QueryInformationJobObject(
        nativeint job,
        int kind,
        JobAccounting& result,
        uint32 length,
        nativeint returned
    )

    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern bool private InitializeProcThreadAttributeList(
        nativeint list,
        int count,
        uint32 flags,
        unativeint& size
    )

    [<DllImport("kernel32.dll")>]
    extern void private DeleteProcThreadAttributeList(nativeint list)

    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern bool private UpdateProcThreadAttribute(
        nativeint list,
        uint32 flags,
        unativeint attribute,
        nativeint value,
        unativeint size,
        nativeint previous,
        nativeint returned
    )

    [<DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)>]
    extern bool private CreateProcessW(
        string application,
        StringBuilder command,
        nativeint processAttributes,
        nativeint threadAttributes,
        bool inheritHandles,
        uint32 flags,
        nativeint environment,
        string directory,
        ChildStartup& startup,
        ChildInformation& childHandle
    )

    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern uint32 private ResumeThread(nativeint thread)

    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern bool private TerminateProcess(nativeint childHandle, uint32 code)

    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern uint32 private WaitForSingleObject(nativeint handle, uint32 milliseconds)

    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern bool private GetExitCodeProcess(nativeint childHandle, uint32& code)

    let private check result =
        if not result then
            raise (Win32Exception(Marshal.GetLastPInvokeError()))

    let private close value =
        if value <> 0n && value <> -1n then
            CloseHandle value |> ignore

    let private argument (value: string) =
        let text = StringBuilder("\"")
        let mutable slashes = 0

        for c in value do
            if c = '\\' then
                slashes <- slashes + 1
            else
                text.Append('\\', (if c = '"' then slashes * 2 + 1 else slashes)).Append(c)
                |> ignore

                slashes <- 0

        text.Append('\\', slashes * 2).Append('"').ToString()

    let start (request: NativeLaunch) =
        let command =
            String.Join(" ", request.Executable :: request.Arguments |> List.map argument)

        if command.Length >= 32767 then
            invalidArg "arguments" "The Windows command line exceeds the native limit."

        let job = CreateJobObjectW(0n, null)

        if job = 0n then
            raise (Win32Exception(Marshal.GetLastPInvokeError()))

        let mutable transferred = false

        try
            let mutable security = Unchecked.defaultof<ChildSecurity>
            security.Length <- uint32 (Marshal.SizeOf<ChildSecurity>())
            security.Inherit <- 1
            let handles = ResizeArray<nativeint>()

            try
                for access in [ 0x80000000u; 0x40000000u; 0x40000000u ] do
                    let handle = CreateFileW("NUL", access, 3u, &security, 3u, 0u, 0n)

                    if handle = -1n then
                        raise (Win32Exception(Marshal.GetLastPInvokeError()))

                    handles.Add handle

                let mutable size = 0un
                InitializeProcThreadAttributeList(0n, 1, 0u, &size) |> ignore

                if size = 0un then
                    raise (Win32Exception(Marshal.GetLastPInvokeError()))

                let attributes = Marshal.AllocHGlobal(nativeint size)
                let handleList = Marshal.AllocHGlobal(IntPtr.Size * 3)

                let environment =
                    Marshal.StringToHGlobalUni(
                        String.Join("\000", ChildEnvironment.build request.Environment) + "\000\000"
                    )

                let mutable initialized = false

                try
                    check (InitializeProcThreadAttributeList(attributes, 1, 0u, &size))
                    initialized <- true

                    for i in 0..2 do
                        Marshal.WriteIntPtr(handleList, i * IntPtr.Size, handles[i])

                    check (
                        UpdateProcThreadAttribute(
                            attributes,
                            0u,
                            0x20002un,
                            handleList,
                            unativeint (IntPtr.Size * 3),
                            0n,
                            0n
                        )
                    )

                    let mutable startup = Unchecked.defaultof<ChildStartup>
                    startup.Size <- uint32 (Marshal.SizeOf<ChildStartup>())
                    startup.Flags <- 0x100u
                    startup.Input <- handles[0]
                    startup.Output <- handles[1]
                    startup.Error <- handles[2]
                    startup.Attributes <- attributes
                    let mutable info = Unchecked.defaultof<ChildInformation>

                    check (
                        CreateProcessW(
                            request.Executable,
                            StringBuilder(command),
                            0n,
                            0n,
                            true,
                            0x08080404u,
                            environment,
                            request.WorkingDirectory,
                            &startup,
                            &info
                        )
                    )

                    let mutable resumed = false

                    try
                        check (AssignProcessToJobObject(job, info.Process))

                        if ResumeThread(info.Thread) = UInt32.MaxValue then
                            raise (Win32Exception(Marshal.GetLastPInvokeError()))

                        resumed <- true
                        close info.Thread
                        let childHandle = info.Process
                        let processId = int info.ProcessId

                        let exited =
                            Task.Run<int>(
                                Func<int>(fun () ->
                                    try
                                        if
                                            WaitForSingleObject(childHandle, UInt32.MaxValue) <> 0u
                                        then
                                            raise (Win32Exception(Marshal.GetLastPInvokeError()))

                                        let mutable code = 0u
                                        check (GetExitCodeProcess(childHandle, &code))
                                        int code
                                    finally
                                        close childHandle)
                            )

                        let mutable disposed = false
                        let gate = obj ()
                        transferred <- true

                        { new INativeRun with
                            member _.ProcessId = processId
                            member _.Scope = "Windows job"
                            member _.RootExit = exited

                            member _.Observe() =
                                lock gate (fun () ->
                                    if disposed then
                                        raise (ObjectDisposedException "native run")

                                    let mutable accounting = Unchecked.defaultof<JobAccounting>

                                    check (
                                        QueryInformationJobObject(
                                            job,
                                            1,
                                            &accounting,
                                            uint32 (Marshal.SizeOf<JobAccounting>()),
                                            0n
                                        )
                                    )

                                    { RootExitCode =
                                        if exited.IsCompleted then
                                            Some(exited.GetAwaiter().GetResult())
                                        else
                                            None
                                      ActiveProcesses = Some(int accounting.Active)
                                      ScopeEnded = accounting.Active = 0u })

                            member _.Dispose() =
                                lock gate (fun () ->
                                    if not disposed then
                                        disposed <- true
                                        close job) }
                    finally
                        if not resumed then
                            // Only a new never-resumed childHandle is removed when launch setup fails.
                            let terminated = TerminateProcess(info.Process, 1u)

                            if terminated then
                                WaitForSingleObject(info.Process, UInt32.MaxValue) |> ignore

                            close info.Thread
                            close info.Process
                finally
                    if initialized then
                        DeleteProcThreadAttributeList attributes

                    Marshal.FreeHGlobal attributes
                    Marshal.FreeHGlobal handleList
                    Marshal.FreeHGlobal environment
            finally
                for handle in handles do
                    close handle
        finally
            if not transferred then
                close job
