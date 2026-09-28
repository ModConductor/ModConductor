namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ArchiveInstallation
open ModConductor.ArtifactLibrary
open ModConductor.ModLibrary
open ModConductor.Platform

type internal ProfileTransportImportMod
    (
        database: StateDatabase,
        access: LibraryAccess,
        library: ModLibraryStore,
        installations: InstallationStore,
        artifacts: IArtifactLibrary,
        directory: string
    ) =
    let codec = Path.Combine(AppContext.BaseDirectory, if OperatingSystem.IsWindows() then "xdelta3.exe" else "xdelta3")

    let metadata (value: PortableMod) =
        { ModMetadata.Name = value.Name
          Notes = value.Notes
          Comment = value.Comment
          Version = value.Version
          Source = ""
          Categories =
            value.Categories
            |> List.map (fun label ->
                { CategoryReference.Id = Guid.NewGuid()
                  Label = label
                  Missing = true }) }

    let problem = function
        | Ok value -> value
        | Error _ -> raise (InvalidDataException "The imported profile files could not be restored.")

    let baseVersion workspace (value: PortableMod) artifact token =
        task {
            let! found = artifacts.Read(workspace, artifact)
            let source = problem found
            let expected = value.Base.Value

            if source.Sha256 <> Some expected.ArchiveSha256 || source.Length <> Some expected.ArchiveLength then
                raise (InvalidDataException("The exact archive for " + value.Name + " is unavailable."))

            let reference =
                { ArtifactRef.WorkspaceId = workspace
                  Id = artifact
                  Revision = source.Revision }

            let! prepared = installations.Prepare(reference, token)
            let prepared = problem prepared

            let manual =
                if prepared.Installer = InstallationMode.Manual then prepared
                else installations.UseInstaller(workspace, prepared.Id, prepared.Revision, InstallationMode.Manual) |> problem

            let withRoot =
                if expected.Root.IsEmpty then manual
                else
                    installations.Change(workspace, manual.Id, manual.Revision, LayoutChange.Root expected.Root)
                    |> problem

            let selected =
                expected.Selected
                |> List.map (fun file ->
                    { SelectedFile.Index = file.ArchiveIndex
                      Destination = LogicalPath.create file.Destination |> problem })

            let reviewed =
                installations.SelectReviewed(workspace, withRoot.Id, withRoot.Revision, value.Name, value.Version, selected)
                |> problem

            let started = installations.Start(workspace, reviewed.Id, reviewed.Revision, Guid.NewGuid()) |> problem
            let! completed = installations.UntilStopped(workspace, started.Id, started, token)
            let completed = problem completed

            if completed.State <> InstallationState.Complete then
                raise (InvalidDataException("The exact archive for " + value.Name + " did not install: " + defaultArg completed.Problem "Installation stopped."))

            do!
                database.Enqueue(fun () ->
                    use transaction = database.Connection.BeginTransaction(deferred = false)
                    Sqlite.execute
                        database.Connection
                        transaction
                        "UPDATE archive_installations SET archive_name=$name WHERE workspace_id=$workspace AND id=$id AND state=2"
                        [ "$name", box expected.ArchiveName
                          "$workspace", box (string workspace)
                          "$id", box (string completed.Id) ]
                    transaction.Commit())

            return completed.ModId.Value, completed.VersionId.Value
        }

    let createMod workspace id (value: PortableMod) =
        database.Enqueue(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = false)
            InventoryOutput.createFromOutputs database.Connection transaction workspace id (metadata value) |> ignore
            transaction.Commit()
            id)

    let copyBase workspace version path destination =
        task {
            let! source =
                database.Enqueue(fun () ->
                    LibraryRows.version database.Connection null version 0 100001
                    |> Option.bind (fun value -> value.Entries |> List.tryFind (fun item -> LogicalPath.components item.Path = path))
                    |> Option.bind (fun value ->
                        match
                            LibraryRows.library database.Connection null workspace,
                            LibraryRows.payload database.Connection null value.Payload.Id
                        with
                        | Some library, Some payload -> Some(library, payload)
                        | _ -> None))

            match source with
            | None -> return raise (InvalidDataException "A recorded patch base is unavailable.")
            | Some(library, payload) ->
                let! root = access.Root workspace
                let root = problem root
                use folder = LibraryFiles.openLibrary root library
                LibraryFiles.verify folder payload
                let input, _ = folder.Read(LibraryFiles.payloadName payload.Payload.Id, Some payload.Identity)
                use input = input
                use output = new FileStream(destination, FileMode.CreateNew, FileAccess.Write, FileShare.None)
                do! input.CopyToAsync output
                do! output.FlushAsync()
                return payload.Payload.Sha256
        }

    let stageFile (bundle: ProfileTransportZip.Bundle) workspace (value: PortableFile) stage baseVersion token =
        task {
            let target = Path.Combine(stage, String.Join(Path.DirectorySeparatorChar, value.Path))
            Directory.CreateDirectory(Path.GetDirectoryName target) |> ignore

            match value.Content with
            | PortableContent.Payload(memberName, sha, _) -> bundle.Copy(memberName, target, Some sha)
            | PortableContent.Patch(memberName, baseSha, sha, length) ->
                let version = baseVersion |> Option.defaultWith (fun () -> raise (InvalidDataException "A patch has no exact base."))
                let baseFile = Path.Combine(stage, Guid.NewGuid().ToString("N") + ".base")
                let patch = Path.Combine(stage, Guid.NewGuid().ToString("N") + ".patch")
                let! observed = copyBase workspace version value.Path baseFile

                if observed <> baseSha then
                    raise (InvalidDataException "The recorded patch base changed.")

                bundle.Copy(memberName, patch, None)
                do! ProfileDelta.decode codec baseFile baseSha patch target sha length token
                File.Delete baseFile
                File.Delete patch
            return ()
        }

    let compose workspace modId baseVersion (value: PortableMod) stage (token: CancellationToken) =
        task {
            let selected = RootSelection.select (HostPath.create stage |> problem) |> problem
            let root = RootSelection.path selected
            let identity =
                match (RootSelection.facts selected).File with
                | Known identity -> identity
                | Unknown _ -> raise (InvalidDataException "The imported files are unavailable.")

            use folder = HeldDirectory.Open(root, identity)
            let scanned = SourceFiles.scan folder Set.empty 100000 (fun () -> token.ThrowIfCancellationRequested())
            let files = scanned |> Result.mapError _.Error |> problem
            let files = fst files

            let! row = database.Enqueue(fun () -> LibraryRows.find database.Connection null modId)
            let row = row |> Option.defaultWith (fun () -> raise (InvalidDataException "The imported mod is unavailable."))

            let input =
                { ActionId = Guid.NewGuid()
                  SourceVersion = baseVersion
                  VersionLabel = value.Version
                  Policy = ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                  Files =
                    files
                    |> List.map (fun file ->
                        { Target = file.Path
                          Root = root
                          RootIdentity = identity
                          File = file })
                  Bytes = []
                  Deleted = value.Deleted |> List.map (LogicalPath.create >> problem) }

            let version = Guid.NewGuid()

            let! published =
                access.Run(fun () ->
                    library.PublicationOwner.Compose(modId, row.Entry.Revision, version, input, token, ignore, ignore, ignore))

            return (problem published).CurrentVersion.Value
        }

    member _.Import(workspace, profile, (value: PortableMod), artifact: Guid option, bundle: ProfileTransportZip.Bundle, (token: CancellationToken)) =
        task {
            token.ThrowIfCancellationRequested()

            if value.Kind <> "regular" && value.Kind <> "fnis-output" && value.Kind <> "generated-output" then
                return raise (InvalidDataException "The profile contains an unsupported mod kind.")
            else
                let! modId, baseVersion =
                    task {
                        match value.Base, artifact with
                        | Some _, Some source ->
                            let! id, version = baseVersion workspace value source token
                            return id, Some version
                        | Some _, None ->
                            return raise (InvalidDataException("The exact archive for " + value.Name + " is required."))
                        | None, _ ->
                            let id =
                                if value.Kind = "fnis-output" then FnisRunRows.outputId profile else Guid.NewGuid()

                            let! id = createMod workspace id value
                            return id, None
                    }

                let stage = Path.Combine(directory, "profile-transport", Guid.NewGuid().ToString("N"))
                Directory.CreateDirectory stage |> ignore

                try
                    for file in value.Files do
                        do! stageFile bundle workspace file stage baseVersion token

                    let! version =
                        if value.Files.IsEmpty && value.Deleted.IsEmpty && baseVersion.IsSome then
                            Task.FromResult baseVersion.Value
                        else
                            compose workspace modId baseVersion value stage token

                    let! revision =
                        database.Enqueue(fun () ->
                            (LibraryRows.find database.Connection null modId).Value.Entry.Revision)

                    let! edited = (library :> IModLibrary).Edit(modId, revision, metadata value)

                    problem edited |> ignore

                    do!
                        database.Enqueue(fun () ->
                            use transaction = database.Connection.BeginTransaction(deferred = false)

                            if value.Kind = "fnis-output" || value.Kind = "generated-output" then
                                Sqlite.execute
                                    database.Connection
                                    transaction
                                    "UPDATE mods SET kind=5 WHERE id=$mod AND workspace_id=$workspace AND current_version=$version AND kind=1; DELETE FROM profile_mods WHERE mod_id=$mod; UPDATE profiles SET selection_revision=selection_revision+1 WHERE workspace_id=$workspace"
                                    [ "$mod", box (string modId)
                                      "$workspace", box (string workspace)
                                      "$version", box (string version) ]

                            for path in value.Hidden do
                                Sqlite.execute
                                    database.Connection
                                    transaction
                                    "INSERT INTO hidden_mod_files(workspace_id,mod_id,version_id,path,hidden) VALUES($workspace,$mod,$version,$path,1)"
                                    [ "$workspace", box (string workspace)
                                      "$mod", box (string modId)
                                      "$version", box (string version)
                                      "$path", box (LibraryEncoding.path (LogicalPath.create path |> problem)) ]

                            match value.Source with
                            | Some source ->
                                NexusOriginRows.save
                                    database.Connection
                                    transaction
                                    version
                                    { Game = source.Game; Mod = source.ModId }
                                    { Id = source.FileId; Version = source.FileVersion; Manual = true }
                            | None -> ()

                            transaction.Commit())

                    return modId, Some version
                finally
                    Directory.Delete(stage, true)
        }
