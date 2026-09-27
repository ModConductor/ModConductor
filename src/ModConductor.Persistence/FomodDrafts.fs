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
        getDraftResult: Guid * Guid * int64 -> Result<InstallationDraft, string>,
        saveDraft: InstallationDraft -> unit
    ) =
    let inputs = Dictionary<Guid, InstallerInput>()
    let sessions = Dictionary<Guid, FomodSession>()

    let findResult workspace id revision =
        getDraftResult (workspace, id, revision)
        |> Result.bind (fun current ->
            match sessions.TryGetValue workspace with
            | true, session when
                session.View.Draft.Id = current.Id && session.View.Draft.Revision = revision
                ->
                Ok session
            | _ -> Error "The installer choices changed. Open the installer again.")

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
            findResult workspace id revision
            |> Result.bind (fun session ->
                match session.View.Wizard with
                | None -> Error "Use the manual layout for this installer."
                | Some wizard -> Ok(snapshot session session.View.Draft (update session wizard))))

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
            let found =
                lock gate (fun () ->
                    getDraftResult (workspace, id, revision)
                    |> Result.bind (fun draft ->
                        if draft.Installer <> InstallationMode.Fomod then
                            Error "Open the XML installer first."
                        else
                            match inputs.TryGetValue workspace with
                            | true, input ->
                                let original =
                                    match sessions.TryGetValue workspace with
                                    | true, session -> session.Original
                                    | _ -> draft

                                Ok(draft, original, input)
                            | _ -> Error "This archive has no installer choices."))

            match found with
            | Error why -> return Error why
            | Ok(_, _, InstallerInput.Absent) ->
                return Error "This archive has no installer choices."
            | Ok(draft, original, InstallerInput.Unavailable problem) ->
                return
                    lock gate (fun () ->
                        getDraftResult (workspace, id, revision)
                        |> Result.map (fun _ ->
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

                            view))
            | Ok(draft, original, InstallerInput.Xml definition) ->
                let! facts = FomodFacts.capture database access workspace profile definition

                return
                    lock gate (fun () ->
                        getDraftResult (workspace, id, revision)
                        |> Result.map (fun _ ->
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

                            snapshot session draft (Choices.beginChoices definition facts.Facts)))
        }

    member _.Read(workspace, id, revision) =
        lock gate (fun () -> findResult workspace id revision |> Result.map _.View)

    member _.Choose(workspace, id, revision, optionId, selected) =
        lock gate (fun () ->
            match findResult workspace id revision with
            | Error why -> Error why
            | Ok session ->
                match session.View.Wizard with
                | None -> Error "Use the manual layout for this installer."
                | Some wizard ->
                    Choices.choose optionId selected wizard
                    |> Result.map (snapshot session session.View.Draft))

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
            getDraftResult (workspace, id, revision)
            |> Result.map (fun current ->
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
                draft))

    member _.Image(workspace, id, revision, path: string list, token: CancellationToken) =
        task {
            let found =
                lock gate (fun () ->
                    findResult workspace id revision
                    |> Result.bind (fun session ->
                        match session.View.Definition with
                        | None -> Error "No installer image is available."
                        | Some definition ->
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
                                Error "Choose an image from this installer."
                            else
                                match ArchiveInput.image definition path with
                                | None -> Error "This installer image is not available."
                                | Some entry -> Ok(session, entry)))

            match found with
            | Error why -> return Error why
            | Ok(session, entry) ->
                let cached =
                    lock gate (fun () ->
                        match session.Images.TryGetValue entry.Index with
                        | true, bytes -> Some bytes
                        | _ -> None)

                match cached with
                | Some bytes -> return Ok bytes
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

                    return
                        match loaded with
                        | Error _ ->
                            Error "The installer image cannot be read. Check the archive location."
                        | Ok bytes ->
                            lock gate (fun () ->
                                findResult workspace id revision
                                |> Result.map (fun _ ->
                                    if
                                        (session.Images.Values |> Seq.sumBy _.Length)
                                        + bytes.Length > 16 * 1024 * 1024
                                    then
                                        session.Images.Clear()

                                    session.Images[entry.Index] <- bytes
                                    bytes))
        }
