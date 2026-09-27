namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.Platform
open ModConductor.Fomod
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInstallation
open ModConductor.ModLibrary
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Workspaces

module FomodFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let observe (writer: Utf8JsonWriter) area =
        Directory.CreateDirectory area |> ignore

        let check name value =
            writer.WriteBoolean((name: string), value)

            if not value then
                failwith ("FOMOD fixture failed: " + name)

        writer.WriteStartObject("fomod")

        let state = Path.Combine(area, "state")
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        use store = new OperationStore(state)
        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "FOMOD fixture", StorageWorker.select root)
            |> wait
            |> result

        let selected =
            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "Everyday" }
            )
            |> wait
            |> result

        let game = Path.Combine(area, "game")
        GameContextFixtures.create game 104
        File.WriteAllText(Path.Combine(game, "Data", "base.txt"), "base")

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                profile,
                0L,
                { GameId = GameId.SkyrimSpecialEditionSteam
                  Path = game
                  Proton = None }
            )
        |> wait
        |> result
        |> ignore

        let source =
            Directory.CreateDirectory(Path.Combine(root, "Inactive mod", "textures")).FullName

        File.WriteAllText(Path.Combine(source, "inactive.dds"), "inactive")
        let library = store.ModLibrary :> IModLibrary

        let helper =
            library.Register(
                workspace,
                Guid.NewGuid(),
                { Name = "Inactive mod"
                  Version = "1"
                  Notes = ""
                  Comment = ""
                  Source = ""
                  Categories = [] },
                Registration.Directory(
                    ModKind.Regular,
                    LogicalPath.create [ "Inactive mod" ] |> result
                )
            )
            |> wait
            |> result

        library.Publish(helper.Id, helper.Revision, Guid.NewGuid())
        |> wait
        |> result
        |> ignore

        let path = Path.Combine(area, "choices.zip")
        FomodSamples.create path FomodSamples.choices
        let original = File.ReadAllBytes path

        let add path =
            store.Artifacts.Add(
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  Path = path
                  Storage = ArtifactStorage.Copy },
                token
            )
            |> wait
            |> result

        let artifact = add path

        let reference =
            { ArtifactRef.WorkspaceId = workspace
              Id = artifact.Id
              Revision = artifact.Revision }

        let draft = store.Installations.Prepare(reference, token) |> wait |> result

        let mutable view =
            store.Installations.Fomod.Open(workspace, draft.Id, draft.Revision, profile)
            |> wait
            |> result

        let next () =
            view <-
                store.Installations.Fomod.Next(workspace, view.Draft.Id, view.Draft.Revision)
                |> result

        let back () =
            view <-
                store.Installations.Fomod.Back(workspace, view.Draft.Id, view.Draft.Revision)
                |> result

        let choose name value =
            let option =
                view.Wizard.Value.Current.Value.Groups
                |> List.collect _.Options
                |> List.find (fun o -> o.Option.Name = name)

            view <-
                store.Installations.Fomod.Choose(
                    workspace,
                    view.Draft.Id,
                    view.Draft.Revision,
                    option.Option.Id,
                    value
                )
                |> result

        next ()

        let staleRevision = draft.Revision

        let staleRequests =
            [ store.Installations.Fomod.Open(workspace, draft.Id, staleRevision, profile)
              |> wait
              |> Result.isError
              store.Installations.Fomod.Read(workspace, draft.Id, staleRevision)
              |> Result.isError
              store.Installations.Fomod.Back(workspace, draft.Id, staleRevision)
              |> Result.isError
              store.Installations.Fomod.Next(workspace, draft.Id, staleRevision)
              |> Result.isError
              store.Installations.Fomod.Manual(workspace, draft.Id, staleRevision)
              |> Result.isError
              store.Installations.Fomod.Image(workspace, draft.Id, staleRevision, [], token)
              |> wait
              |> Result.isError ]

        let current =
            store.Installations.Fomod.Read(workspace, view.Draft.Id, view.Draft.Revision)
            |> result

        check
            "StaleInstallerActionsAreRefusedWithoutChangingChoices"
            (List.forall id staleRequests && current.Draft.Revision = view.Draft.Revision)

        let refused =
            store.Installations.Fomod.Choose(
                workspace,
                view.Draft.Id,
                view.Draft.Revision,
                Int32.MaxValue,
                true
            )

        check
            "UnknownInstallerChoiceIsRefusedWithoutChangingDraft"
            (Result.isError refused
             && (store.Installations.Fomod.Read(workspace, view.Draft.Id, view.Draft.Revision)
                 |> result)
                 .Draft.Revision = view.Draft.Revision)

        check
            "UnconfirmedCardinalityCreatesNoInstallation"
            (view.Problem.IsSome && (store.Installations.Recent workspace |> wait).IsEmpty)

        choose "2K textures" true
        next ()

        check
            "KnownFactsAndIrrelevantUnknownAllowChoices"
            (view.Wizard.Value.Current.Value.Step.Name = "Patches" && view.Problem.IsNone)

        next ()
        check "RequiredPatchSelectionBlocksNext" view.Problem.IsSome
        choose "Waterfalls" true
        choose "Gloss" true
        next ()
        choose "Clear water" true
        next ()

        check
            "ConditionalStepProducesReviewWithoutEffects"
            (view.Planned.IsSome && (store.Installations.Recent workspace |> wait).IsEmpty)

        back ()
        back ()
        choose "Waterfalls" false
        choose "Riverbanks" true
        next ()

        check
            "BacktrackingDropsHiddenStepFiles"
            (view.Planned.IsSome
             && not (
                 view.Planned.Value.Files
                 |> List.exists (fun f ->
                     LogicalPath.display f.File.Destination = "textures/foam.dds")
             ))

        let preview = view

        let changed =
            workspaces.Edit(
                workspace,
                selected.Workspace.Revision,
                ProfileEdit.Create { Id = Guid.NewGuid(); Name = "Other" }
            )
            |> wait
            |> result

        let stale =
            store.Installations.Start(workspace, view.Draft.Id, view.Draft.Revision, Guid.NewGuid())
            |> Result.isError

        check
            "ChangedWorkspaceRejectsConfirmationBeforeEffects"
            (stale && (store.Installations.Recent workspace |> wait).IsEmpty)

        view <-
            store.Installations.Fomod.Open(workspace, view.Draft.Id, view.Draft.Revision, profile)
            |> wait
            |> result

        choose "2K textures" true
        next ()
        choose "Riverbanks" true
        choose "Gloss" true
        next ()
        let planned = view.Planned.Value.Files

        let outputs =
            planned
            |> List.map (fun f -> LogicalPath.display f.File.Destination)
            |> Set.ofList

        check
            "FlagsPrioritiesAndInstallFlagsProduceExactManifest"
            (outputs = set
                [ "textures/water.dds"
                  "textures/second.dds"
                  "meshes/banks.nif"
                  "gloss.txt"
                  "Riviere/settings.ini"
                  "textures/detail.dds"
                  "usable.txt"
                  "always.txt"
                  "Riviere/patch.ini" ]
             && (planned
                 |> List.find (fun f ->
                     LogicalPath.display f.File.Destination = "textures/water.dds"))
                 .Replaces.Length = 1)

        let started =
            store.Installations.Start(workspace, view.Draft.Id, view.Draft.Revision, Guid.NewGuid())
            |> result

        let deadline = DateTime.UtcNow.AddSeconds 15
        let mutable status = started

        while status.State = InstallationState.Running && DateTime.UtcNow < deadline do
            Thread.Sleep 10
            status <- store.Installations.Read(workspace, started.Id) |> wait

        if status.State <> InstallationState.Complete then
            failwith (string status.Problem)

        let version = library.Version(status.VersionId.Value, 0) |> wait |> result

        let water =
            version.Entries
            |> List.find (fun e -> LogicalPath.display e.Path = "textures/water.dds")

        let second =
            version.Entries
            |> List.find (fun e -> LogicalPath.display e.Path = "textures/second.dds")

        check
            "OneSourcePublishesSharedPayloadAtBothDestinations"
            (water.Payload.Id = second.Payload.Id
             && water.Payload.Length = 5L
             && version.Entries.Length = outputs.Count)

        let linked = store.Artifacts.Read(workspace, artifact.Id) |> wait |> result

        check
            "PublicationKeepsTypedArchiveOriginAndProvenance"
            (linked.Links
             |> List.exists (fun l ->
                 l.ModId = status.ModId.Value && l.VersionId = status.VersionId.Value))

        check
            "ArchiveAndSyntheticGameFilesRemainUnchanged"
            (File.ReadAllBytes(path) = original
             && File.ReadAllText(Path.Combine(game, "Data", "base.txt")) = "base")

        store.Installations.CloseDraft(workspace, view.Draft.Id)

        let ordinaryError name xml =
            let path = Path.Combine(area, name + ".zip")
            FomodSamples.create path xml
            let archive = add path

            let draft =
                store.Installations.Prepare(
                    { WorkspaceId = workspace
                      Id = archive.Id
                      Revision = archive.Revision },
                    token
                )
                |> wait
                |> result

            let draft =
                if draft.Installer = InstallationMode.Fomod then
                    draft
                else
                    store.Installations.UseInstaller(
                        workspace,
                        draft.Id,
                        draft.Revision,
                        InstallationMode.Fomod
                    )
                    |> result

            let view =
                store.Installations.Fomod.Open(workspace, draft.Id, draft.Revision, profile)
                |> wait
                |> result

            let manual =
                store.Installations.UseInstaller(
                    workspace,
                    view.Draft.Id,
                    view.Draft.Revision,
                    InstallationMode.Manual
                )
                |> result

            store.Installations.CloseDraft(workspace, manual.Id)
            view.Problem.IsSome && manual.Installer = InstallationMode.Manual

        check
            "ExternalEntityAndMalformedXmlHaveManualExit"
            (ordinaryError
                "entity"
                ("<!DOCTYPE config [<!ENTITY read SYSTEM 'file:///unread-fixture'>]><config><moduleName>&read;</moduleName></config>")
             && ordinaryError "malformed" "<config>")

        check
            "OutcomeDependentPluginUnknownDoesNotInstall"
            (ordinaryError
                "plugin"
                "<config><moduleName>Unknown</moduleName><moduleDependencies><fileDependency file='Unknown.esp' state='Active'/></moduleDependencies><requiredInstallFiles><file source='gloss.txt'/></requiredInstallFiles></config>")

        let modEntry =
            (library.Scan(workspace, 100) |> wait |> result).Entries
            |> List.find (fun entry -> entry.Id = status.ModId.Value)

        store.Deletions.Delete(workspace, modEntry.Id, modEntry.Revision) |> wait

        check
            "OwnedDeletionRemovesFomodPayloadsWithoutDanglingMappings"
            ((library.Scan(workspace, 100) |> wait |> result).Entries
             |> List.forall (fun entry -> entry.Id <> modEntry.Id))

        writer.WriteEndObject()
