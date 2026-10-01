namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Threading
open ModConductor.Persistence

module ProfileDeltaFixtures =
    let samples () =
        let basis = Array.zeroCreate<byte> (4 * 1024 * 1024)
        Random(106).NextBytes basis
        let edited = Array.copy basis
        edited[8192..8221] <- Array.create 30 0uy
        edited[2097152..2101247] <- Array.create 4096 0xFFuy

        [ "binary.bin", basis, edited
          "emptied.bin", [| 1uy; 2uy; 3uy |], Array.empty
          "filled.bin", Array.empty, [| 0uy; 1uy; 2uy; 3uy; 0xFFuy |] ]

    let cancelledExport (store: OperationStore) workspace profile area =
        use cancelled = new CancellationTokenSource()
        cancelled.Cancel()
        let output = Path.Combine(area, "cancelled.mcprof")

        let observed =
            try
                store.ProfileTransport.Export(workspace, profile, output, false, cancelled.Token)
                |> StorageWorker.wait
                |> ignore

                false
            with :? OperationCanceledException ->
                true

        let staging = Path.Combine(area, "state", "profile-transport")

        observed
        && not (File.Exists output)
        && (Directory.EnumerateFileSystemEntries(staging) |> Seq.isEmpty)
