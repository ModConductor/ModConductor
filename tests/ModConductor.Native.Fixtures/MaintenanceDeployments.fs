namespace ModConductor.Native.Fixtures

open System
open System.IO
open Microsoft.Data.Sqlite
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.Persistence

module internal MaintenanceDeployments =
    let database state =
        let connection =
            new SqliteConnection(
                SqliteConnectionStringBuilder(
                    DataSource = Path.Combine(state, "state.db"),
                    Pooling = false
                )
                    .ConnectionString
            )

        connection.Open()
        connection

    let save state root workspace profile (version: ModVersion) area =
        use connection = database state
        let library = LibraryRows.library connection null workspace |> Option.get
        let backing = DeploymentFixtureData.location (Path.Combine(root, library.Name))

        let folder =
            Directory.CreateDirectory(Path.Combine(area, Guid.NewGuid().ToString("N"))).FullName

        let directory = DeploymentFixtureData.location folder

        let targetRoot =
            { Id = workspace
              Policy = TargetPolicy.windows }

        let files =
            version.Entries
            |> List.map (fun entry ->
                let payload = LibraryRows.payload connection null entry.Payload.Id |> Option.get
                let target = { Root = workspace; Path = entry.Path }
                let name = string entry.Payload.Id
                use held = HeldDirectory.Open(directory.Path, directory.Identity)

                let source =
                    Path.Combine(
                        HostPath.value backing.Path,
                        LibraryFiles.payloadName entry.Payload.Id
                    )

                let link = held.CreateLink(name, source, false)
                GenerationStorage.protectLink held name link

                { Target = target
                  Path = DeploymentFixtureData.path name
                  Identity = link.Identity
                  Length = entry.Payload.Length
                  Sha256 = Some entry.Payload.Sha256
                  Backing =
                    Some
                        { Directory = backing
                          Path =
                            DeploymentFixtureData.path (LibraryFiles.payloadName entry.Payload.Id)
                          Identity = payload.Identity
                          OwnerGeneration = None } })

        GenerationStorage.protectDirectory directory.Path directory.Identity

        let generation =
            { Id = Guid.NewGuid()
              Directory = directory
              Files = files
              References =
                version.Entries
                |> List.map (fun entry -> SourcePin.Mod(version.ModId, version.Id, entry))
              PlanFingerprint = "maintenance-owned-fixture"
              Writable = []
              Roots = [ targetRoot ]
              Observed = []
              Working = []
              NativeTargets = Map.empty
              Provenance =
                Some
                    { PreparedAt = DateTimeOffset.UtcNow
                      Profile =
                        Some
                            { Id = profile
                              Name = "Everyday"
                              Revision = 1L
                              Mods =
                                [ { ModId = version.ModId
                                    VersionId = Some version.Id
                                    Priority = 0
                                    Enabled = true } ]
                              Hidden = Set.empty } } }

        let location name =
            DeploymentFixtureData.location (
                Directory.CreateDirectory(Path.Combine(area, name)).FullName
            )

        let context =
            { Id = Guid.NewGuid()
              Fingerprint = "maintenance-owned-fixture"
              Roots =
                [ { Root = targetRoot
                    Directory = location "game"
                    Originals = location "originals" } ]
              Revision = 0L
              Active = None
              Links = []
              Directories = []
              Originals = []
              Pending = None }

        use transaction = connection.BeginTransaction()
        DeploymentRows.writeContext connection transaction context
        DeploymentRows.writeGeneration connection transaction context.Id generation
        transaction.Commit()
        context, generation

    let active state (context: Context) value =
        use connection = database state
        DeploymentRows.writeContext connection null { context with Active = value }

    let unavailable state context generation retained =
        use connection = database state

        let value =
            DeploymentRows.generation connection null context generation |> Option.get

        let reason = MaintenanceClaims.unavailable connection null context generation
        let entry = SavedDeployments.describe None reason value

        not entry.CanRestore
        && reason.IsSome
        && value.References.IsEmpty
        && (value.Files
            |> List.forall (fun file ->
                file.Backing
                |> Option.exists (fun backing ->
                    retained
                    |> List.exists (fun id ->
                        LogicalPath.components backing.Path = [ LibraryFiles.payloadName id ]))))

    let sharePayload state (version: ModVersion) (entry: ManifestEntry) =
        use connection = database state

        Sqlite.execute
            connection
            null
            "UPDATE mod_manifest SET payload_id=$payload WHERE version_id=$version AND path=$path"
            [ "$payload", box (string entry.Payload.Id)
              "$version", box (string version.Id)
              "$path", box (LibraryEncoding.path entry.Path) ]

    let selection state profile =
        use connection = database state

        let revision =
            Sqlite.number
                connection
                null
                "SELECT selection_revision FROM profiles WHERE id=$id"
                [ "$id", box (string profile) ]

        revision, SelectionRows.all connection null profile
