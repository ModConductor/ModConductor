namespace ModConductor.Desktop

open System
open System.IO

module StateLease =
    let acquire directory =
        let directory = Path.GetFullPath directory
        Directory.CreateDirectory directory |> ignore

        let stream =
            new FileStream(
                Path.Combine(directory, "desktop-owner.lock"),
                FileMode.OpenOrCreate,
                FileAccess.ReadWrite,
                FileShare.None
            )

        try
            if OperatingSystem.IsLinux() then
                stream.Lock(0L, 1L)

            stream
        with _ ->
            stream.Dispose()
            reraise ()
