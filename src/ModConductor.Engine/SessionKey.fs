namespace ModConductor.Engine

open System
open System.IO
open System.Runtime.Versioning
open System.Security.Cryptography

[<Sealed>]
type SessionKey(key: RSA, release: unit -> unit) =
    member _.Rsa = key

    interface IDisposable with
        member _.Dispose() =
            key.Dispose()
            release ()

[<SupportedOSPlatform("windows")>]
module private WindowsSessionKey =
    let private provider = CngProvider.MicrosoftSoftwareKeyStorageProvider

    let private keyName (id: Guid) =
        "ModConductor.Session." + id.ToString("N")

    let private removeKey id =
        let name = keyName id

        if CngKey.Exists(name, provider, CngKeyOpenOptions.None) then
            use key = CngKey.Open(name, provider, CngKeyOpenOptions.None)
            key.Delete()

    let private tryAcquire path =
        try
            Some(new FileStream(path, FileMode.Open, FileAccess.ReadWrite, FileShare.Delete))
        with
        | :? FileNotFoundException -> None
        | :? IOException as error when error.HResult &&& 0xffff = 32 -> None

    let private cleanAbandoned directory =
        for path in Directory.EnumerateFiles(directory, "*.lease") do
            match Guid.TryParseExact(Path.GetFileNameWithoutExtension path, "N") with
            | true, id ->
                match tryAcquire path with
                | Some lease ->
                    use owned = lease
                    removeKey id
                    File.Delete path
                | None -> ()
            | false, _ -> ()

    let create () =
        let directory =
            Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "ModConductor",
                "session-keys"
            )

        Directory.CreateDirectory directory |> ignore
        cleanAbandoned directory
        let id = Guid.NewGuid()
        let path = Path.Combine(directory, id.ToString("N") + ".lease")

        let lease =
            new FileStream(
                path,
                FileMode.CreateNew,
                FileAccess.ReadWrite,
                FileShare.Delete,
                1,
                FileOptions.WriteThrough
            )

        let mutable created: CngKey option = None

        try
            lease.Flush(true)

            let parameters =
                CngKeyCreationParameters(
                    Provider = provider,
                    KeyUsage = CngKeyUsages.Signing,
                    ExportPolicy = CngExportPolicies.None
                )

            parameters.Parameters.Add(
                CngProperty("Length", BitConverter.GetBytes 2048, CngPropertyOptions.None)
            )

            let key = CngKey.Create(CngAlgorithm.Rsa, keyName id, parameters)
            created <- Some key
            let rsa = new RSACng(key)

            new SessionKey(
                rsa,
                fun () ->
                    try
                        key.Delete()
                        File.Delete path
                    finally
                        key.Dispose()
                        lease.Dispose()
            )
        with _ ->
            try
                match created with
                | Some key ->
                    use owned = key
                    key.Delete()
                | None -> ()

                File.Delete path
            finally
                lease.Dispose()

            reraise ()

module SessionKey =
    let create () =
        if OperatingSystem.IsWindows() then
            WindowsSessionKey.create ()
        else
            new SessionKey(RSA.Create(2048), ignore)
