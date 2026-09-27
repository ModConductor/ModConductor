namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.Bain
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInstallation
open ModConductor.ModLibrary
open ModConductor.Platform
open ModConductor.Persistence
open ModConductor.Workspaces

module BainFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private reference (artifact: Artifact) : ArtifactRef =
        { WorkspaceId = artifact.WorkspaceId
          Id = artifact.Id
          Revision = artifact.Revision }

    let observe (writer: Utf8JsonWriter) area =
        BainSamples.create area

        let check name value =
            writer.WriteBoolean((name: string), value)

            if not value then
                failwith ("BAIN fixture failed: " + name)

        writer.WriteStartObject("bain")
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let state = Path.Combine(area, "state")
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let original = File.ReadAllBytes(Path.Combine(area, "Rivière textures.zip"))

        let run () =
            use store = new OperationStore(state)
            let workspaces = store.Workspaces :> IWorkspaceState

            let created =
                workspaces.Create(workspace, "BAIN fixture", StorageWorker.select root)
                |> wait
                |> result

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "Everyday" }
            )
            |> wait
            |> result
            |> ignore

            let add name =
                store.Artifacts.Add(
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      Path = Path.Combine(area, name)
                      Storage = ArtifactStorage.Copy },
                    token
                )
                |> wait
                |> result

            let prepare artifact =
                store.Installations.Prepare(reference artifact, token) |> wait

            let openChoices (draft: InstallationDraft) =
                store.Installations.Bain.Open(workspace, draft.Id, draft.Revision) |> result

            let choose name selected (view: PackageChoices) =
                let p =
                    view.Selection.Value.Definition.Packages |> List.find (fun p -> p.Name = name)

                store.Installations.Bain.Choose(
                    workspace,
                    view.Draft.Id,
                    view.Draft.Revision,
                    p.Index,
                    selected
                )
                |> result

            let review (view: PackageChoices) =
                store.Installations.Bain.Review(workspace, view.Draft.Id, view.Draft.Revision)
                |> result

            let back (view: PackageChoices) =
                store.Installations.Bain.Back(workspace, view.Draft.Id, view.Draft.Revision)
                |> result

            let includeFile path included (view: PackageChoices) =
                store.Installations.Bain.Include(
                    workspace,
                    view.Draft.Id,
                    view.Draft.Revision,
                    path,
                    included
                )
                |> result

            let winner path (view: PackageChoices) =
                view.Selection.Value.Files[Destinations.key (
                                               LogicalPath.create path
                                               |> Result.defaultWith (fun error ->
                                                   failwith (string error))
                                           )]

            let packages = add "Rivière textures.zip"
            let draft = prepare packages
            let mutable view = openChoices draft
            let names = view.Selection.Value.Definition.Packages |> List.map _.Name

            let refused =
                store.Installations.Bain.Choose(
                    workspace,
                    view.Draft.Id,
                    view.Draft.Revision,
                    Int32.MaxValue,
                    true
                )

            let unchanged =
                store.Installations.Draft(workspace, view.Draft.Id, view.Draft.Revision)
                |> result

            check
                "UnknownPackageChoiceIsRefusedWithoutChangingDraft"
                (Result.isError refused && unchanged.Revision = view.Draft.Revision)

            check
                "WrapperAndLexicalNamesHaveEditableCoreDefault"
                (draft.Installer = InstallationMode.Bain
                 && names = [ "00 Core"; "02 Banks"; "10 Textures"; "2 Alternatives"; "30 Foam" ]
                 && view.Selection.Value.Selected = set [ 0 ])

            let notes =
                store.Installations.Bain.Notes(workspace, view.Draft.Id, view.Draft.Revision, token)
                |> wait
                |> result

            check
                "NotesAreReadExplicitlyAndBothWizardEntriesAreMetadata"
                (notes.Contains("Rivière textures")
                 && draft.WizardScripts.Length = 2
                 && view.Selection.Value.Definition.Packages
                    |> List.collect _.Files
                    |> List.forall (fun f -> LogicalPath.display f.Destination <> "wizard.txt"))

            view <-
                view
                |> choose "10 Textures" true
                |> choose "2 Alternatives" true
                |> choose "30 Foam" true
                |> review

            let first = winner [ "textures"; "water.dds" ] view

            let expectedOrder =
                view.Selection.Value.Files
                |> Map.toList
                |> List.map (fun (key, f) ->
                    key, LogicalPath.display f.Source, f.Replaces |> List.map LogicalPath.display)

            check
                "LaterLexicalFolderWinsBeforeAnyInstallationEffect"
                (first.Choice = "2 Alternatives"
                 && first.Replaces.Length = 2
                 && (store.Installations.Recent workspace |> wait).IsEmpty
                 && ((store.ModLibrary :> IModLibrary).Scan(workspace, 100) |> wait |> result)
                     .Entries.IsEmpty)

            let old = view.Draft

            view <-
                view
                |> includeFile [ "textures"; "water.dds" ] false
                |> includeFile [ "textures"; "foam.dds" ] false

            view <-
                view
                |> back
                |> choose "2 Alternatives" false
                |> choose "30 Foam" false
                |> choose "30 Foam" true
                |> review

            check
                "BackAndPackageChangesKeepExplicitDestinationExclusions"
                (view.Draft.Files
                 |> List.forall (fun f ->
                     let path = LogicalPath.display f.Destination in
                     path <> "textures/water.dds" && path <> "textures/foam.dds")
                 && (winner [ "textures"; "water.dds" ] view).Choice = "10 Textures")

            let stale =
                store.Installations.Start(workspace, old.Id, old.Revision, Guid.NewGuid())
                |> Result.isError

            check
                "StaleReviewedRevisionCannotPublishOldChoices"
                (stale && (store.Installations.Recent workspace |> wait).IsEmpty)

            store.Installations.CloseDraft(workspace, view.Draft.Id)
            let reversed = add "reversed.zip"

            let other =
                prepare reversed
                |> openChoices
                |> choose "10 Textures" true
                |> choose "2 Alternatives" true
                |> choose "30 Foam" true
                |> review

            let actualOrder =
                other.Selection.Value.Files
                |> Map.toList
                |> List.map (fun (key, f) ->
                    key, LogicalPath.display f.Source, f.Replaces |> List.map LogicalPath.display)

            check "ArchiveEntryOrderDoesNotChangeSubpackagePrecedence" (expectedOrder = actualOrder)
            store.Installations.CloseDraft(workspace, other.Draft.Id)
            let mixed = add "combined.zip"
            let mixedDraft = prepare mixed

            let xml =
                store.Installations.Fomod.Open(
                    workspace,
                    mixedDraft.Id,
                    mixedDraft.Revision,
                    profile
                )
                |> wait
                |> result

            let packageDraft =
                store.Installations.UseInstaller(
                    workspace,
                    xml.Draft.Id,
                    xml.Draft.Revision,
                    InstallationMode.Bain
                )
                |> result

            let selected = packageDraft |> openChoices |> choose "30 Foam" true |> review

            let xmlDraft =
                store.Installations.UseInstaller(
                    workspace,
                    selected.Draft.Id,
                    selected.Draft.Revision,
                    InstallationMode.Fomod
                )
                |> result

            let xmlAgain =
                store.Installations.Fomod.Open(workspace, xmlDraft.Id, xmlDraft.Revision, profile)
                |> wait
                |> result

            check
                "FomodRemainsPreferredAndExplicitModeSwitchClearsOtherChoices"
                (mixedDraft.Installer = InstallationMode.Fomod
                 && xmlAgain.Draft.Files.Length = 1
                 && LogicalPath.display xmlAgain.Draft.Files.Head.Destination = "textures/from-xml.dds")

            store.Installations.CloseDraft(workspace, xmlAgain.Draft.Id)
            let ambiguous = add "ambiguous.zip" |> prepare |> openChoices

            let manual =
                store.Installations.UseInstaller(
                    workspace,
                    ambiguous.Draft.Id,
                    ambiguous.Draft.Revision,
                    InstallationMode.Manual
                )
                |> result

            check
                "AmbiguousPayloadFolderHasManualExitWithoutGuessedPlan"
                (ambiguous.Problem.IsSome
                 && ambiguous.Draft.Plan.IsNone
                 && manual.Installer = InstallationMode.Manual)

            store.Installations.CloseDraft(workspace, manual.Id)
            let simple = add "single.zip" |> prepare

            check
                "SingleDataRootStaysOnExistingQuickLayout"
                (simple.Installer = InstallationMode.Manual
                 && simple.Root = [ "Package"; "00 Core" ]
                 && simple.Plan.IsSome)

            store.Installations.CloseDraft(workspace, simple.Id)
            let current = store.Artifacts.Read(workspace, packages.Id) |> wait |> result
            view <- prepare current |> openChoices

            check
                "ClosingDraftDoesNotRememberPreviousFolderSelections"
                (view.Selection.Value.Selected = set [ 0 ])

            view <-
                view
                |> choose "10 Textures" true
                |> choose "30 Foam" true
                |> review
                |> includeFile [ "textures"; "foam.dds" ] false

            let selectedFiles =
                view.Draft.Files
                |> List.map (fun f -> LogicalPath.display f.Destination)
                |> Set.ofList

            let job =
                store.Installations.Start(
                    workspace,
                    view.Draft.Id,
                    view.Draft.Revision,
                    Guid.NewGuid()
                )
                |> result

            let mutable status = job
            let deadline = DateTime.UtcNow.AddSeconds 15

            while status.State = InstallationState.Running && DateTime.UtcNow < deadline do
                Thread.Sleep 10
                status <- store.Installations.Read(workspace, job.Id) |> wait

            if status.State <> InstallationState.Complete then
                failwith (string status.Problem)

            let version =
                (store.ModLibrary :> IModLibrary).Version(status.VersionId.Value, 0)
                |> wait
                |> result

            let water =
                version.Entries
                |> List.find (fun f -> LogicalPath.display f.Path = "textures/water.dds")

            let linked = store.Artifacts.Read(workspace, packages.Id) |> wait |> result

            check
                "ReviewedSelectedFilesUseExistingImmutablePublicationAndProvenance"
                (selectedFiles = set
                    [ "textures/water.dds"; "meshes/bank.nif"; "Riviere/settings.ini" ]
                 && version.Entries.Length = 3
                 && water.Payload.Length = 8L
                 && linked.Links
                    |> List.exists (fun l ->
                        l.ModId = status.ModId.Value && l.VersionId = status.VersionId.Value))

            check
                "ExternalArchiveAndIgnoredMetadataRemainUnchanged"
                (original = File.ReadAllBytes(Path.Combine(area, "Rivière textures.zip"))
                 && not (File.Exists(Path.Combine(root, "not-run.ini"))))
            // Leave an unconfirmed choice in memory before the normal owner closes.
            let next = prepare linked |> openChoices |> choose "30 Foam" true
            packages.Id, next.Draft, status.VersionId.Value

        let artifactId, abandoned, versionId = run ()
        use restored = new OperationStore(state)
        let artifact = restored.Artifacts.Read(workspace, artifactId) |> wait |> result
        let draft = restored.Installations.Prepare(reference artifact, token) |> wait

        let view =
            restored.Installations.Bain.Open(workspace, draft.Id, draft.Revision) |> result

        check
            "OwnerRestartKeepsPublishedVersionButNotUnconfirmedChoices"
            (view.Draft.Id <> abandoned.Id
             && view.Selection.Value.Selected = set [ 0 ]
             && ((restored.ModLibrary :> IModLibrary).Version(versionId, 0) |> wait |> result)
                 .Entries.Length = 3)

        writer.WriteEndObject()
