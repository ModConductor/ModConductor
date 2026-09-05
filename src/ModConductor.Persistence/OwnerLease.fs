namespace ModConductor.Persistence

open System
open System.IO

module internal OwnerLease =
    let reserve directory =
        Directory.CreateDirectory directory |> ignore
        let id = Guid.NewGuid().ToString("N")
        let path = Path.Combine(directory, id + ".lease")
        let pending = Path.Combine(directory, id + ".pending")

        let lease =
            new FileStream(pending, FileMode.CreateNew, FileAccess.ReadWrite, FileShare.Delete)

        try
            if OperatingSystem.IsLinux() then
                lease.Lock(0L, 1L)

            lease.Flush(true)
            File.Move(pending, path)
            id, path, lease
        with _ ->
            lease.Dispose()
            File.Delete pending
            reraise ()

    let recover directory currentOwner recoverOwner =
        for path in Directory.EnumerateFiles(directory, "*.lease") do
            match Guid.TryParseExact(Path.GetFileNameWithoutExtension path, "N") with
            | true, id when id.ToString("N") <> currentOwner ->
                let lease =
                    try
                        let stream =
                            new FileStream(
                                path,
                                FileMode.Open,
                                FileAccess.ReadWrite,
                                FileShare.Delete
                            )

                        try
                            if OperatingSystem.IsLinux() then
                                stream.Lock(0L, 1L)

                            Some stream
                        with _ ->
                            stream.Dispose()
                            reraise ()
                    with
                    | :? FileNotFoundException -> None
                    | :? IOException as error when
                        error.HResult &&& 0xffff = 32 || error.HResult &&& 0xffff = 11
                        ->
                        None

                match lease with
                | Some lease ->
                    use owned = lease

                    recoverOwner (id.ToString("N"))

                    File.Delete path
                | None -> ()
            | true, _
            | false, _ -> ()
