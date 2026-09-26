namespace ModConductor.Loot

open System
open System.Collections.Generic
open ModConductor.ProfileGameData

module internal Proposal =
    let private sortedOrder (value: ProfilePluginOrder) (sorted: string list) =
        let pending = ResizeArray(sorted)
        let mutable position = 0

        value.View.Order.Entries
        |> List.map (fun row ->
            if row.Enabled = Some true then
                let name = pending[position]
                position <- position + 1
                name
            else
                row.Name)

    let private moves current sorted =
        let positions = Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)
        sorted |> List.iteri (fun index name -> positions.Add(name, index + 1))

        current
        |> List.mapi (fun index name ->
            let next = positions[name]

            if next = index + 1 then
                None
            else
                Some
                    { Plugin = name
                      Current = index + 1
                      Proposed = next
                      Reason = "LOOT order" })
        |> List.choose id

    let create (value: ProfilePluginOrder) fingerprint metadata (response: LootJson.Response) =
        let current = value.View.Order.Entries |> List.map _.Name
        let sorted = sortedOrder value response.Sorted

        { Id = Guid.NewGuid()
          Expected = value.Reference
          HeadersId = value.Headers.Id
          SourceFingerprint = fingerprint
          CreatedAt = DateTimeOffset.UtcNow
          Current = current
          Sorted = sorted
          Moves = moves current sorted
          Messages = response.Messages
          Metadata = metadata
          HelperVersion = response.HelperRevision
          LiblootVersion = response.LiblootVersion
          LiblootRevision = response.LiblootRevision }
