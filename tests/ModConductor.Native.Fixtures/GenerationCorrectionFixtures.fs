namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.Cryptography
open System.Text.Json
open System.Threading
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations

module internal GenerationCorrectionFixtures =
    let private path = DeploymentFixtureData.path
    let private location = DeploymentFixtureData.location

    let private refused action =
        try
            action () |> ignore
            false
        with RecoveryException _ ->
            true

    let private capacity (writer: Utf8JsonWriter) primary =
        let real = location primary
        // These identities label controlled cost buckets; no native operation uses them.
        let bucket n =
            { real with
                Identity =
                    { real.Identity with
                        Device = LinuxDevice(900u, uint32 n) } }

        let first, second = Guid.NewGuid(), Guid.NewGuid()

        let roots =
            [ { Root =
                  { Id = first
                    Policy = TargetPolicy.linux }
                Directory = bucket 1
                Originals = bucket 1 }
              { Root =
                  { Id = second
                    Policy = TargetPolicy.linux }
                Directory = bucket 2
                Originals = bucket 2 } ]

        let request: BuildRequest =
            { Id = Guid.NewGuid()
              Storage = bucket 3
              SecondaryStorage = bucket 4
              Roots = roots
              Working = []
              Previous = None
              Processes = [] }

        let file root index length =
            let target =
                { Root = root
                  Path = path (string index + ".txt") }

            let contribution =
                { LayerId = Guid.NewGuid()
                  Precedence =
                    { Tier = LayerTier.Secondary
                      Priority = 0 }
                  Source =
                    SourcePin.Snapshot(
                        Guid.NewGuid(),
                        "controlled",
                        { Path = target.Path
                          Identity = SnapshotFileIdentity.Content(length, String.replicate 64 "0") }
                    )
                  MappedTarget = target
                  Archives = [] }

            { Target = target
              Winner = contribution
              Alternatives = []
              Reason = WinnerReason.OnlyContribution }

        let one = file first 0 0L

        let required files secondary bindings =
            GenerationCapacity.required request files secondary bindings []

        let baseline = required [ one ] [ one ] []

        let limit (root: Location) =
            baseline
            |> List.find (fun (location, _) -> location.Identity.Device = root.Identity.Device)
            |> snd

        let many = [ for n in 1..20 -> file first n 0L ]

        let secondaryLimited (location: Location) =
            if location.Identity.Device = request.SecondaryStorage.Identity.Device then
                limit location
            else
                Int64.MaxValue

        writer.WriteBoolean(
            "secondaryEntriesCharged",
            refused (fun () ->
                required (one :: many) (one :: many) []
                |> GenerationCapacity.check secondaryLimited)
        )

        let noNewSecondaryCapacity (location: Location) =
            if location.Identity.Device = request.SecondaryStorage.Identity.Device then
                0L
            else
                Int64.MaxValue

        writer.WriteBoolean(
            "reusedSecondaryNeedsNoCopyCapacity",
            not (
                refused (fun () ->
                    required [ one ] [] [] |> GenerationCapacity.check noNewSecondaryCapacity)
            )
        )

        let secondOnly = file second 30 0L
        let independent = required [ secondOnly ] [] []

        let secondLimit =
            independent
            |> List.find (fun (location, _) ->
                location.Identity.Device = (bucket 2).Identity.Device)
            |> snd

        let separatelyAvailable (location: Location) =
            if location.Identity.Device = (bucket 2).Identity.Device then
                secondLimit
            else
                Int64.MaxValue

        writer.WriteBoolean(
            "targetCostsRemainOnTheirDevice",
            not (
                refused (fun () ->
                    required (secondOnly :: many) [] []
                    |> GenerationCapacity.check separatelyAvailable)
            )
        )

        let empty = required [] [] []

        let firstLimit =
            empty
            |> List.find (fun (location, _) ->
                location.Identity.Device = (bucket 1).Identity.Device)
            |> snd

        let working =
            { Declaration = Guid.NewGuid()
              Initialized = false
              Root = bucket 5
              Path = path "settings.ini" }

        let workingLimited (location: Location) =
            if location.Identity.Device = (bucket 1).Identity.Device then
                firstLimit
            else
                Int64.MaxValue

        writer.WriteBoolean(
            "workingActivationCharged",
            refused (fun () ->
                required
                    []
                    []
                    [ (working,
                       { Root = first
                         Path = path "settings.ini" },
                       false,
                       []) ]
                |> GenerationCapacity.check workingLimited)
        )

        writer.WriteBoolean(
            "capacityOverflowRefused",
            refused (fun () ->
                required [ file first 40 Int64.MaxValue ] [ file first 41 Int64.MaxValue ] [])
        )

    let private seeds (writer: Utf8JsonWriter) primary =
        let area =
            Directory.CreateDirectory(Path.Combine(primary, "seed-publication")).FullName

        let sourceRoot =
            Directory.CreateDirectory(Path.Combine(area, "source")).FullName |> location

        let destination =
            Directory.CreateDirectory(Path.Combine(area, "working")).FullName |> location

        let bytes = Array.init (1024 * 1024) (fun index -> byte (index % 251))
        let sourcePath = RecoveryFiles.path sourceRoot (path "seed.bin")
        File.WriteAllBytes(sourcePath, bytes)

        let identity =
            RecoveryFiles.withParent sourceRoot (path "seed.bin") (fun parent name ->
                (parent.InspectEntry name).Value.Identity)

        let source =
            { Directory = sourceRoot
              Path = path "seed.bin"
              Identity = identity
              OwnerGeneration = None }

        let hash =
            GenerationFiles.read source (fun stream ->
                SHA256.HashData stream |> Convert.ToHexStringLower)

        let pin =
            SourcePin.Snapshot(
                Guid.NewGuid(),
                "seed",
                { Path = path "seed.bin"
                  Identity = SnapshotFileIdentity.Content(int64 bytes.Length, hash) }
            )

        let final = path "settings.bin"
        let finalPath = RecoveryFiles.path destination final
        use cancellation = new CancellationTokenSource()
        let mutable observedBytes = 0L

        let cancelled =
            try
                GenerationFiles.seedAtCheckpoint
                    cancellation.Token
                    pin
                    source
                    destination
                    final
                    (fun count ->
                        observedBytes <- count
                        cancellation.Cancel())
                |> ignore

                false
            with :? OperationCanceledException ->
                true

        writer.WriteBoolean(
            "partialSeedNotPublished",
            cancelled
            && observedBytes > 0L
            && observedBytes < int64 bytes.Length
            && not (File.Exists finalPath)
        )

        GenerationFiles.seed CancellationToken.None pin source destination final
        |> ignore

        writer.WriteBoolean("seedRetryPublishesComplete", File.ReadAllBytes(finalPath) = bytes)
        let competing = path "preserved.bin"
        let competingPath = RecoveryFiles.path destination competing
        let mutable supplied = false

        let refused =
            try
                GenerationFiles.seedAtCheckpoint
                    CancellationToken.None
                    pin
                    source
                    destination
                    competing
                    (fun _ ->
                        if not supplied then
                            File.WriteAllText(competingPath, "pre-existing working data")
                            supplied <- true)
                |> ignore

                false
            with :? IOException ->
                true

        writer.WriteBoolean(
            "seedPublicationNeverOverwrites",
            refused && File.ReadAllText(competingPath) = "pre-existing working data"
        )

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject("generationCorrections")
        capacity writer primary
        seeds writer primary
        writer.WriteEndObject()
