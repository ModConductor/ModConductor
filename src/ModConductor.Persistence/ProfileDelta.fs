namespace ModConductor.Persistence

open System
open System.Diagnostics
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks

module internal ProfileDelta =
    let private version executable =
        let start = ProcessStartInfo(executable)
        start.ArgumentList.Add "-V"
        start.UseShellExecute <- false
        start.RedirectStandardError <- true
        start.RedirectStandardOutput <- true
        start.Environment.Remove "XDELTA" |> ignore
        use child = Process.Start start
        let output = child.StandardError.ReadToEnd() + child.StandardOutput.ReadToEnd()
        child.WaitForExit()

        if
            child.ExitCode <> 0
            || not (output.Contains("version 3.2.0", StringComparison.Ordinal))
            || not (output.Contains("Apache", StringComparison.Ordinal))
        then
            raise (InvalidDataException "The bundled xdelta3 3.2.0 codec is unavailable.")

    let private run executable arguments (token: CancellationToken) =
        task {
            let start = ProcessStartInfo(executable)
            start.UseShellExecute <- false
            start.RedirectStandardError <- true
            start.RedirectStandardOutput <- true
            start.Environment.Remove "XDELTA" |> ignore
            arguments |> List.iter start.ArgumentList.Add
            use child = Process.Start start
            let error = child.StandardError.ReadToEndAsync(token)
            let output = child.StandardOutput.ReadToEndAsync(token)

            try
                do! child.WaitForExitAsync token
            with :? OperationCanceledException as canceled ->
                child.Kill(entireProcessTree = true)
                do! child.WaitForExitAsync()
                raise canceled

            let! stderr = error
            let! stdout = output

            if child.ExitCode <> 0 then
                raise (InvalidDataException("The profile patch failed: " + stderr + stdout))
        }

    let private checkHeader patch =
        use stream = File.OpenRead patch
        let header = Array.zeroCreate<byte> 5

        if
            stream.Read(header, 0, header.Length) <> header.Length
            || header[0..2] <> [| 0xD6uy; 0xC3uy; 0xC4uy |]
            || header[3] <> 0uy
            || (header[4] &&& 0x04uy) <> 0uy
        then
            raise (InvalidDataException "The profile patch is not bare VCDIFF.")

    let private checkFile path expected length =
        use input = File.OpenRead path

        if input.Length <> length then
            raise (InvalidDataException "The profile file length does not match its metadata.")

        let digest = SHA256.HashData input |> Convert.ToHexStringLower

        if not (String.Equals(digest, expected, StringComparison.OrdinalIgnoreCase)) then
            raise (InvalidDataException "The profile file does not match its exact source.")

    let encode executable baseFile baseSha edited editedSha editedLength patch token =
        task {
            version executable
            checkFile baseFile baseSha (FileInfo(baseFile).Length)
            checkFile edited editedSha editedLength

            do! run executable [ "-a"; "-A"; "-D"; "-R"; "-e"; "-s"; baseFile; edited; patch ] token

            checkHeader patch
        }

    let decode executable baseFile baseSha patch edited editedSha editedLength token =
        task {
            version executable
            checkFile baseFile baseSha (FileInfo(baseFile).Length)
            checkHeader patch
            do! run executable [ "-a"; "-D"; "-R"; "-d"; "-s"; baseFile; patch; edited ] token
            checkFile edited editedSha editedLength
        }
