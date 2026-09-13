namespace ModConductor.Native.Fixtures

open System
open System.Diagnostics
open System.IO
open System.Text.Json
open System.Threading.Tasks
open ModConductor.Credentials
open ModConductor.Desktop
open ModConductor.Nexus

module NxmDeliveryFixtures =
    let observe (writer: Utf8JsonWriter) executable area =
        use credentials = new CredentialSession(NexusMemoryStore())

        use session =
            new NexusSession(
                credentials,
                None,
                ({ new IOAuthHandoff with
                    member _.Listen(_, _) =
                        failwith "No OAuth in the delivery fixture."

                    member _.Open(_, _) =
                        failwith "No browser in the delivery fixture." }),
                (fun _ -> Task.CompletedTask)
            )

        use ingress =
            new PrivateIngress(
                (fun (id, input) -> session.AcceptNxm(id, input)),
                session.DismissNxm
            )

        Directory.CreateDirectory area |> ignore

        let start =
            ProcessStartInfo(
                executable,
                RedirectStandardInput = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false
            )

        start.ArgumentList.Add area
        use child = Process.Start start
        let descriptor = ingress.Configure child.Id
        child.StandardInput.WriteLine descriptor.Endpoint
        child.StandardInput.WriteLine(Convert.ToHexString descriptor.Capability)
        child.StandardInput.WriteLine descriptor.ProcessId
        child.StandardInput.Flush()
        let stderr = child.StandardError.ReadToEndAsync()
        let mutable finished = false

        while not finished do
            let line =
                child.StandardOutput
                    .ReadLineAsync()
                    .WaitAsync(TimeSpan.FromSeconds 20.)
                    .GetAwaiter()
                    .GetResult()

            if isNull line then
                finished <- true
            else
                let parts = line.Split(' ', 2)

                let reply =
                    match parts[0] with
                    | "dismiss" ->
                        session.DismissNxm(Guid.Parse parts[1])
                        "ok"
                    | "present" ->
                        if session.ReadNxm(Guid.Parse parts[1]) |> Result.isOk then
                            "yes"
                        else
                            "no"
                    | "capacity" ->
                        let ids = Array.init 16 (fun _ -> Guid.NewGuid())

                        let admitted =
                            ids
                            |> Array.forall (fun id ->
                                session.AcceptNxm(id, "nxm://skyrimspecialedition/mods/1/files/1"))

                        ids |> Array.iter session.DismissNxm
                        if admitted then "16" else "full"
                    | "passed" ->
                        writer.WriteBoolean(parts[1], true)
                        writer.Flush()
                        "ok"
                    | _ -> failwith "Unexpected native delivery fixture command."

                child.StandardInput.WriteLine reply
                child.StandardInput.Flush()

        child.WaitForExitAsync().WaitAsync(TimeSpan.FromSeconds 10.).GetAwaiter().GetResult()
        let error = stderr.GetAwaiter().GetResult()

        if child.ExitCode <> 0 || error <> "" then
            failwith ("Native delivery fixture failed: " + error)
