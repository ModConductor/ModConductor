namespace ModConductor.Native.Fixtures

open ModConductor.ModOrganization
open ModConductor.Persistence

module InventoryObservations =
    let query =
        { Text = ""
          Mode = FilterMode.All
          Filters = []
          View = OrganizationView.Flat
          Sort = OrganizationSort.Priority }

    let read (store: OperationStore) profile =
        (store.ModOrganization :> IModOrganization).Query(profile, query, None, None)
        |> StorageWorker.wait
        |> StorageWorker.result
