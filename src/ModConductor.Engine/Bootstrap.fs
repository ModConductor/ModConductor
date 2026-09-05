namespace ModConductor.Engine

open System
open System.IO
open System.Net
open System.Security.Cryptography
open System.Security.Cryptography.X509Certificates
open System.Threading
open Google.Protobuf
open ModConductor.Protocol.V1

module Bootstrap =
    let readCapability (input: Stream) =
        task {
            use timeout = new CancellationTokenSource(TimeSpan.FromSeconds 10.)
            let bytes = Array.zeroCreate<byte> 65
            do! input.ReadExactlyAsync(bytes.AsMemory(), timeout.Token)

            if
                bytes[64] <> 10uy
                || bytes[..63]
                   |> Array.exists (fun c ->
                       not ((c >= 48uy && c <= 57uy) || (c >= 97uy && c <= 102uy)))
            then
                raise (InvalidDataException("Invalid bootstrap."))

            return bytes[..63]
        }

    let createCertificate (key: RSA) =

        let request =
            CertificateRequest(
                "CN=localhost",
                key,
                HashAlgorithmName.SHA256,
                RSASignaturePadding.Pkcs1
            )

        let names = SubjectAlternativeNameBuilder()
        names.AddDnsName("localhost")
        names.AddIpAddress(IPAddress.Loopback)
        request.CertificateExtensions.Add(names.Build())
        request.CertificateExtensions.Add(X509BasicConstraintsExtension(false, false, 0, true))

        request.CertificateExtensions.Add(
            X509KeyUsageExtension(X509KeyUsageFlags.DigitalSignature, true)
        )

        let usages = OidCollection()
        usages.Add(Oid("1.3.6.1.5.5.7.3.1")) |> ignore
        request.CertificateExtensions.Add(X509EnhancedKeyUsageExtension(usages, true))

        request.CreateSelfSigned(
            DateTimeOffset.UtcNow.AddMinutes(-1.),
            DateTimeOffset.UtcNow.AddHours(12.)
        )

    let announce port (certificate: X509Certificate2) =
        let ready =
            EngineReady(
                ProtocolMajor = 1u,
                Port = uint32 port,
                CertificatePem = ByteString.CopyFromUtf8(certificate.ExportCertificatePem())
            )

        Console.Out.WriteLine(Convert.ToBase64String(ready.ToByteArray()))
        Console.Out.Flush()
