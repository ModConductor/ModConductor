namespace ModConductor.Persistence

open System
open System.IO
open System.Text
open System.Threading
open System.Collections.Generic
open ModConductor.ArchiveInspection
open ModConductor.Platform
open ModConductor.Bain
open ModConductor.ArchiveInstallation

[<NoEquality; NoComparison>]
type internal BainSession =
    { Original: InstallationDraft
      View: PackageChoices }

type BainDrafts
    internal
    (
        inspection: Inspection,
        gate: obj,
        getDraft: Guid * Guid * int64 -> InstallationDraft,
        saveDraft: InstallationDraft -> unit
    ) =
    let sessions = Dictionary<Guid, BainSession>()

    let find workspace id revision =
        let draft = getDraft (workspace, id, revision)

        if draft.Installer <> InstallationMode.Bain then
            raise (InstallationException "Open package folder selection first.")

        match sessions.TryGetValue workspace with
        | true, session when session.Original.Id = draft.Id -> session, draft
        | _ -> raise (InstallationException "The package selection changed. Open it again.")

    let update (session: BainSession) (draft: InstallationDraft) selection =
        let selected = selection |> Option.map Selection.files |> Option.defaultValue []
        let reviewing = selection |> Option.exists _.Reviewing

        let draft =
            if reviewing && not selected.IsEmpty then
                Layout.selectFiles draft draft.Name draft.Version selected
            else
                { draft with
                    Revision = draft.Revision + 1L
                    Files = selected
                    Plan = None }

        let view =
            { session.View with
                Draft = draft
                Selection = selection
                Problem = session.View.Input.Problem }

        saveDraft draft
        sessions[draft.Artifact.WorkspaceId] <- { session with View = view }
        view

    let change workspace id revision action =
        lock gate (fun () ->
            let session, draft = find workspace id revision

            let selection =
                session.View.Selection
                |> Option.defaultWith (fun () ->
                    raise (InstallationException "Use the manual layout for this package."))

            update session draft (Some(action selection)))

    member internal _.Prepared(draft: InstallationDraft, input: PackageInput) =
        sessions[draft.Artifact.WorkspaceId] <-
            { Original = draft
              View =
                { Draft = draft
                  Input = input
                  Selection = input.Definition |> Option.map Selection.create
                  Problem = input.Problem } }

    member internal _.Close workspace = sessions.Remove workspace |> ignore

    member _.Open(workspace, id, revision) =
        lock gate (fun () ->
            let session, draft = find workspace id revision
            update session draft session.View.Selection)

    member _.Choose(workspace, id, revision, index, selected) =
        change workspace id revision (Selection.choose index selected)

    member _.ChooseAll(workspace, id, revision, selected) =
        change workspace id revision (Selection.chooseAll selected)

    member _.Include(workspace, id, revision, path, included) =
        change workspace id revision (Selection.includeFile path included)

    member _.Review(workspace, id, revision) =
        change workspace id revision (fun state -> { state with Reviewing = true })

    member _.Back(workspace, id, revision) =
        change workspace id revision (fun state -> { state with Reviewing = false })

    member _.Manual(workspace, id, revision) =
        lock gate (fun () ->
            let session, _ = find workspace id revision
            let original = session.Original

            let draft =
                { original with
                    Revision = revision + 1L
                    Installer = InstallationMode.Manual }

            saveDraft draft

            sessions[workspace] <-
                { session with
                    View =
                        { session.View with
                            Draft = draft
                            Selection =
                                session.View.Input.Definition |> Option.map Selection.create } }

            draft)

    member _.Folder(workspace, id, revision, index) =
        lock gate (fun () ->
            let session, draft = find workspace id revision

            let state =
                session.View.Selection
                |> Option.defaultWith (fun () ->
                    raise (InstallationException "This package has no folder selection."))

            let package =
                state.Definition.Packages
                |> List.tryFind (fun p -> p.Index = index)
                |> Option.defaultWith (fun () ->
                    raise (InstallationException "Choose a folder from this package."))

            let entries = draft.Manifest.Entries |> List.map (fun e -> e.Index, e) |> Map.ofList

            let files =
                package.Files
                |> List.map (fun file ->
                    let replaced =
                        state.Files
                        |> Map.tryFind (Destinations.key file.Destination)
                        |> Option.filter (fun winner -> winner.File.Index = file.Index)
                        |> Option.map _.Replaces
                        |> Option.defaultValue []

                    { File = file
                      Source = entries[file.Index].Path
                      Choice = package.Name
                      Replaces = replaced })

            draft, files)

    member _.Notes(workspace, id, revision, token: CancellationToken) =
        task {
            let draft, entry =
                lock gate (fun () ->
                    let session, draft = find workspace id revision

                    let entry =
                        session.View.Input.Definition
                        |> Option.bind _.Notes
                        |> Option.defaultWith (fun () ->
                            raise (InstallationException "This package has no notes."))

                    if entry.Size > 256L * 1024L then
                        raise (
                            InstallationException "The package notes exceed the text size limit."
                        )

                    draft, entry)

            let! result =
                inspection.WithContents(
                    draft.Artifact,
                    token,
                    fun contents ->
                        use output = new MemoryStream()
                        contents.ReadEntry(entry.Index, fun input -> input.CopyTo output)

                        try
                            UTF8Encoding(false, true)
                                .GetString(output.ToArray())
                                .TrimStart('\uFEFF')
                        with :? DecoderFallbackException ->
                            raise (InstallationException "The package notes are not UTF-8 text.")
                )

            let notes =
                result
                |> Result.defaultWith (fun _ ->
                    raise (
                        InstallationException
                            "The package notes cannot be read. Check the archive location."
                    ))

            return
                lock gate (fun () ->
                    find workspace id revision |> ignore
                    notes)
        }
