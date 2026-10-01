namespace ModConductor.Persistence

open System
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads
open ModConductor.Thunderstore

type ThunderstoreAcquisition
    (reader: IPackageReader, downloads: DownloadSession, artifacts: IArtifactLibrary,
     installations: InstallationStore, inventory: ThunderstoreInventory) =
    let gate = obj()
    let active = HashSet<Guid>()

    member _.Acquire(workspace, reference, observe: ThunderstoreProgress -> Task, token: CancellationToken) = task {
        let admitted = lock gate (fun () -> active.Add workspace)
        if not admitted then return Error Problem.Busy
        else
            try
                let work = ThunderstoreAcquisitionWork(downloads, artifacts, installations, inventory, workspace, observe, token)
                return! work.Run(reader, reference)
            finally lock gate (fun () -> active.Remove workspace |> ignore)
    }
