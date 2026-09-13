namespace ModConductor.Persistence

open System
open System.IO
open System.Collections.Generic
open System.Threading
open ModConductor.Fomod
open ModConductor.ArchiveInstallation
open ModConductor.ArchiveInspection

[<NoEquality; NoComparison>]
type internal FomodSession =
    { View: InstallerChoices
      Facts: FomodFactSnapshot option
      Original: InstallationDraft
      Images: Dictionary<int, byte[]> }

type FomodDrafts
    internal
    (
        database: StateDatabase,
        access: LibraryAccess,
        inspection: Inspection,
        gate: obj,
        getDraft: Guid * Guid * int64 -> InstallationDraft,
        saveDraft: InstallationDraft -> unit
    ) =
    let inputs = Dictionary<Guid, InstallerInput>()
    let sessions = Dictionary<Guid, FomodSession>()
    let refuse text = raise (FomodException text)

    let find workspace id revision =
        let current = getDraft (workspace, id, revision)

        match sessions.TryGetValue workspace with
        | true, session when
            session.View.Draft.Id = current.Id && session.View.Draft.Revision = revision
            ->
            session
        | _ -> refuse "The installer choices changed. Open the installer again."

    let snapshot (session: FomodSession) (draft: InstallationDraft) (wizard: Wizard) =
        let mutable problem = wizard.Problem

        let planned =
            if wizard.Current.IsNone && problem.IsNone then
                try
                    Some(
                        Planning.build
                            session.View.Definition.Value
                            session.Facts.Value.Facts
                            wizard
                    )
                with :? FomodException as error ->
                    problem <- Some error.Message
                    None
            else
                None

        let draft =
            match planned with
            | Some planned ->
                Layout.selectFiles
                    draft
                    planned.Name
                    planned.Version
                    (planned.Files |> List.map _.File)
            | None ->
                { draft with
                    Revision = draft.Revision + 1L
                    Plan = None }

        let flags =
            wizard.Current
            |> Option.map Choices.flags
            |> Option.orElseWith (fun () -> wizard.Past |> List.tryLast |> Option.map Choices.flags)
            |> Option.defaultValue Map.empty

        let visible =
            session.View.Definition.Value.Steps
            |> List.filter (fun step ->
                wizard.Past |> List.exists (fun page -> page.Step.Index = step.Index)
                || (wizard.Current |> Option.exists (fun page -> page.Step.Index = step.Index))
                || Conditions.evaluate session.Facts.Value.Facts flags step.Visible
                   <> Fact.Known false)
            |> List.length

        let view =
            { session.View with
                Draft = draft
                Wizard = Some wizard
                Planned = planned
                VisibleSteps = visible
                Problem = problem }

        let next = { session with View = view }
        saveDraft draft
        sessions[draft.Artifact.WorkspaceId] <- next
        view

    let change workspace id revision update =
        lock gate (fun () ->
            let session = find workspace id revision

            let wizard =
                session.View.Wizard
                |> Option.defaultWith (fun () ->
                    refuse "Use the manual layout for this installer.")

            snapshot session session.View.Draft (update session wizard))

    member internal _.Prepared(draft: InstallationDraft, input) =
        inputs[draft.Artifact.WorkspaceId] <- input
        sessions.Remove draft.Artifact.WorkspaceId |> ignore

    member internal _.Close workspace =
        inputs.Remove workspace |> ignore
        sessions.Remove workspace |> ignore

    member internal _.Check connection transaction workspace =
        match sessions.TryGetValue workspace with
        | true, session -> session.Facts |> Option.iter (FomodFacts.current connection transaction)
        | _ -> ()

    member _.Open(workspace, id, revision, profile) =
        task {
            let draft, original, input =
                lock gate (fun () ->
                    let draft = getDraft (workspace, id, revision)

                    if draft.Installer <> InstallationMode.Fomod then
                        refuse "Open the XML installer first."

                    match inputs.TryGetValue workspace with
                    | true, input ->
                        let original =
                            match sessions.TryGetValue workspace with
                            | true, session -> session.Original
                            | _ -> draft

                        draft, original, input
                    | _ -> refuse "This archive has no installer choices.")

            match input with
            | InstallerInput.Absent -> return refuse "This archive has no installer choices."
            | InstallerInput.Unavailable problem ->
                return
                    lock gate (fun () ->
                        getDraft (workspace, id, revision) |> ignore

                        let draft =
                            { draft with
                                Revision = draft.Revision + 1L
                                Plan = None }

                        let view =
                            { Draft = draft
                              ProfileId = profile
                              Definition = None
                              Wizard = None
                              Planned = None
                              VisibleSteps = 0
                              Problem = Some problem }

                        saveDraft draft

                        sessions[workspace] <-
                            { View = view
                              Facts = None
                              Original = original
                              Images = Dictionary() }

                        view)
            | InstallerInput.Xml definition ->
                let! facts = FomodFacts.capture database access workspace profile definition

                return
                    lock gate (fun () ->
                        getDraft (workspace, id, revision) |> ignore

                        let view =
                            { Draft = draft
                              ProfileId = profile
                              Definition = Some definition
                              Wizard = None
                              Planned = None
                              VisibleSteps = 0
                              Problem = None }

                        let session =
                            { View = view
                              Facts = Some facts
                              Original = original
                              Images = Dictionary() }

                        snapshot session draft (Choices.beginChoices definition facts.Facts))
        }

    member _.Read(workspace, id, revision) =
        lock gate (fun () -> (find workspace id revision).View)

    member _.Choose(workspace, id, revision, optionId, selected) =
        change workspace id revision (fun _ wizard -> Choices.choose optionId selected wizard)

    member _.Back(workspace, id, revision) =
        change workspace id revision (fun _ wizard -> Choices.back wizard)

    member _.Next(workspace, id, revision) =
        change workspace id revision (fun session wizard ->
            let next =
                Choices.next session.View.Definition.Value session.Facts.Value.Facts wizard

            if next.Current.IsNone && next.Problem.IsNone then
                database
                    .EnqueueInternal(fun () ->
                        FomodFacts.current database.Connection null session.Facts.Value)
                    .GetAwaiter()
                    .GetResult()

            next)

    member _.Manual(workspace, id, revision) =
        lock gate (fun () ->
            let current = getDraft (workspace, id, revision)

            let original =
                match sessions.TryGetValue workspace with
                | true, session -> session.Original
                | _ -> current

            let chosen =
                Layout.selectFiles original original.Name original.Version original.Files

            let draft =
                { chosen with
                    Revision = revision + 1L
                    Root = original.Root
                    Installer = InstallationMode.Manual }

            saveDraft draft
            sessions.Remove workspace |> ignore
            draft)

    member _.Image(workspace, id, revision, path: string list, token: CancellationToken) =
        task {
            let session, entry =
                lock gate (fun () ->
                    let session = find workspace id revision

                    let definition =
                        session.View.Definition
                        |> Option.defaultWith (fun () -> refuse "No installer image is available.")

                    let allowed =
                        definition.Image
                        |> Option.toList
                        |> List.append (
                            definition.Steps
                            |> List.collect _.Groups
                            |> List.collect _.Options
                            |> List.choose _.Image
                        )

                    if not (List.contains path allowed) then
                        refuse "Choose an image from this installer."

                    let entry =
                        ArchiveInput.image definition path
                        |> Option.defaultWith (fun () ->
                            refuse "This installer image is not available.")

                    session, entry)

            let cached =
                lock gate (fun () ->
                    match session.Images.TryGetValue entry.Index with
                    | true, bytes -> Some bytes
                    | _ -> None)

            match cached with
            | Some bytes -> return bytes
            | None ->
                let! loaded =
                    inspection.WithInput(
                        session.View.Draft.Artifact,
                        session.View.Draft.Nested,
                        token,
                        fun contents ->
                            use output = new MemoryStream()
                            contents.ReadEntry(entry.Index, fun input -> input.CopyTo output)
                            output.ToArray()
                    )

                let bytes =
                    loaded
                    |> Result.defaultWith (fun _ ->
                        refuse "The installer image cannot be read. Check the archive location.")

                return
                    lock gate (fun () ->
                        find workspace id revision |> ignore

                        if
                            (session.Images.Values |> Seq.sumBy _.Length) + bytes.Length > 16
                                                                                           * 1024
                                                                                           * 1024
                        then
                            session.Images.Clear()

                        session.Images[entry.Index] <- bytes
                        bytes)
        }
