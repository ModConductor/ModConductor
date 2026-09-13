namespace ModConductor.Desktop

open System
open System.IO
open System.IO.Pipes
open System.Net.Sockets
open System.Runtime.InteropServices
open System.Security.Cryptography
open System.Text
open System.Threading
open System.Threading.Tasks

module private IngressNative =
    [<Struct; StructLayout(LayoutKind.Sequential)>]
    type Peer =
        val mutable Pid: int
        val mutable Uid: uint32
        val mutable Gid: uint32

    [<DllImport("libc", SetLastError = true)>]
    extern int getsockopt(int fd, int level, int option, Peer& peer, uint32& size)

    [<DllImport("libc")>]
    extern uint32 getuid()

    [<DllImport("kernel32.dll", SetLastError = true)>]
    extern bool GetNamedPipeClientProcessId(nativeint pipe, uint32& pid)

type PrivateIngressDescriptor =
    { Endpoint: string
      Capability: byte array
      ProcessId: int }

type PrivateIngress(accept: Guid * string -> bool, dismiss: Guid -> unit) =
    let lifetime = new CancellationTokenSource()
    let capability = RandomNumberGenerator.GetBytes 32
    let gate = obj ()
    let mutable runner = 0
    let windows = OperatingSystem.IsWindows()

    let directory =
        if windows then
            None
        else
            Some(Directory.CreateTempSubdirectory("mc-nxm-"))

    let endpoint =
        match directory with
        | Some value ->
            File.SetUnixFileMode(
                value.FullName,
                UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
            )

            Path.Combine(value.FullName, "ingress")
        | None -> "mod-conductor-nxm-" + Guid.NewGuid().ToString("N")

    let listener =
        if windows then
            None
        else
            let socket =
                new Socket(AddressFamily.Unix, SocketType.Stream, ProtocolType.Unspecified)

            socket.Bind(UnixDomainSocketEndPoint endpoint)
            File.SetUnixFileMode(endpoint, UnixFileMode.UserRead ||| UnixFileMode.UserWrite)
            socket.Listen 1
            Some socket

    let matches pid =
        lock gate (fun () -> runner > 0 && runner = pid)

    let frame (stream: Stream) token =
        task {
            let header = Array.zeroCreate<byte> 53
            do! stream.ReadExactlyAsync(header.AsMemory(), token)
            let count = BitConverter.ToInt32(header, 49)

            if
                header[0] = 2uy
                && count = 0
                && CryptographicOperations.FixedTimeEquals(
                    header.AsSpan(1, 32),
                    capability.AsSpan()
                )
            then
                let id = Guid(header.AsSpan(33, 16))
                dismiss id
                do! stream.WriteAsync(id.ToByteArray().AsMemory(), token)
            elif
                header[0] = 1uy
                && count > 0
                && count <= 4096
                && CryptographicOperations.FixedTimeEquals(
                    header.AsSpan(1, 32),
                    capability.AsSpan()
                )
            then
                let payload = Array.zeroCreate<byte> count

                try
                    do! stream.ReadExactlyAsync(payload.AsMemory(), token)
                    let id = Guid(header.AsSpan(33, 16))
                    let text = UTF8Encoding(false, true).GetString payload
                    let accepted = accept (id, text)

                    let reply =
                        if accepted then
                            id.ToByteArray()
                        else
                            Array.zeroCreate<byte> 16

                    do! stream.WriteAsync(reply.AsMemory(), token)
                finally
                    CryptographicOperations.ZeroMemory payload
        }

    let run () =
        task {
            while not lifetime.IsCancellationRequested do
                try
                    if windows then
                        use pipe =
                            new NamedPipeServerStream(
                                endpoint,
                                PipeDirection.InOut,
                                1,
                                PipeTransmissionMode.Byte,
                                PipeOptions.Asynchronous ||| PipeOptions.CurrentUserOnly
                            )

                        do! pipe.WaitForConnectionAsync lifetime.Token
                        use timeout = CancellationTokenSource.CreateLinkedTokenSource lifetime.Token
                        timeout.CancelAfter(TimeSpan.FromSeconds 5.)
                        let mutable pid = 0u

                        if
                            IngressNative.GetNamedPipeClientProcessId(
                                pipe.SafePipeHandle.DangerousGetHandle(),
                                &pid
                            )
                            && matches (int pid)
                        then
                            do! frame pipe timeout.Token
                    else
                        use! client = listener.Value.AcceptAsync lifetime.Token
                        use timeout = CancellationTokenSource.CreateLinkedTokenSource lifetime.Token
                        timeout.CancelAfter(TimeSpan.FromSeconds 5.)
                        let mutable peer = Unchecked.defaultof<IngressNative.Peer>
                        let mutable size = 12u

                        if
                            IngressNative.getsockopt (int client.Handle, 1, 17, &peer, &size) = 0
                            && peer.Uid = IngressNative.getuid ()
                            && matches peer.Pid
                        then
                            use stream = new NetworkStream(client, false)
                            do! frame stream timeout.Token
                with
                | :? IOException
                | :? SocketException
                | :? OperationCanceledException
                | :? DecoderFallbackException -> ()
        }

    let running = run ()

    member _.Configure pid =
        lock gate (fun () ->
            if lifetime.IsCancellationRequested || pid <= 0 || (runner <> 0 && runner <> pid) then
                invalidOp "The desktop connection is unavailable."

            runner <- pid

            { Endpoint = endpoint
              Capability = Array.copy capability
              ProcessId = Environment.ProcessId })

    member _.Stop() =
        lifetime.Cancel()
        running

    interface IDisposable with
        member _.Dispose() =
            lifetime.Cancel()
            running.GetAwaiter().GetResult()
            listener |> Option.iter (fun socket -> socket.Dispose())

            match directory with
            | Some value ->
                File.Delete endpoint
                value.Delete()
            | None -> ()

            CryptographicOperations.ZeroMemory capability
            lifetime.Dispose()
