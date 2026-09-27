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
        getDraft: Guid * Guid * int64 -> Result<InstallationDraft, string>,
        saveDraft: InstallationDraft -> unit
    ) =
    let sessions = Dictionary<Guid, BainSession>()

    let find workspace id revision =
        match getDraft (workspace, id, revision) with
        | Error why -> Error why
        | Ok draft when draft.Installer <> InstallationMode.Bain ->
            Error "Open package folder selection first."
        | Ok draft ->
            match sessions.TryGetValue workspace with
            | true, session when session.Original.Id = draft.Id -> Ok(session, draft)
            | _ -> Error "The package selection changed. Open it again."

    let update (session: BainSession) (draft: InstallationDraft) selection =
        let selected = selection |> Option.map Selection.files |> Option.defaultValue []
        let reviewing = selection |> Option.exists _.Reviewing

        let updated =
            if reviewing && not selected.IsEmpty then
                Layout.selectFiles draft draft.Name draft.Version selected
            else
                Ok
                    { draft with
                        Revision = draft.Revision + 1L
                        Files = selected
                        Plan = None }

        updated
        |> Result.map (fun draft ->
            let view =
                { session.View with
                    Draft = draft
                    Selection = selection
                    Problem = session.View.Input.Problem }

            saveDraft draft
            sessions[draft.Artifact.WorkspaceId] <- { session with View = view }
            view)

    let change workspace id revision action =
        lock gate (fun () ->
            match find workspace id revision with
            | Error why -> Error why
            | Ok(session, draft) ->
                match session.View.Selection with
                | None -> Error "Use the manual layout for this package."
                | Some selection ->
                    action selection
                    |> Result.bind (fun chosen -> update session draft (Some chosen)))

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
            find workspace id revision
            |> Result.bind (fun (session, draft) -> update session draft session.View.Selection))

    member _.Choose(workspace, id, revision, index, selected) =
        change workspace id revision (Selection.choose index selected)

    member _.ChooseAll(workspace, id, revision, selected) =
        change workspace id revision (Selection.chooseAll selected >> Ok)

    member _.Include(workspace, id, revision, path, included) =
        change workspace id revision (Selection.includeFile path included)

    member _.Review(workspace, id, revision) =
        change workspace id revision (fun state -> Ok { state with Reviewing = true })

    member _.Back(workspace, id, revision) =
        change workspace id revision (fun state -> Ok { state with Reviewing = false })

    member _.Manual(workspace, id, revision) =
        lock gate (fun () ->
            find workspace id revision
            |> Result.map (fun (session, _) ->
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

                draft))

    member _.Folder(workspace, id, revision, index) =
        lock gate (fun () ->
            match find workspace id revision with
            | Error why -> Error why
            | Ok(session, draft) ->
                match session.View.Selection with
                | None -> Error "This package has no folder selection."
                | Some state ->
                    match state.Definition.Packages |> List.tryFind (fun p -> p.Index = index) with
                    | None -> Error "Choose a folder from this package."
                    | Some package ->
                        let entries =
                            draft.Manifest.Entries |> List.map (fun e -> e.Index, e) |> Map.ofList

                        let files =
                            package.Files
                            |> List.map (fun file ->
                                let replaced =
                                    state.Files
                                    |> Map.tryFind (Destinations.key file.Destination)
                                    |> Option.filter (fun winner ->
                                        winner.File.Index = file.Index)
                                    |> Option.map _.Replaces
                                    |> Option.defaultValue []

                                { File = file
                                  Source = entries[file.Index].Path
                                  Choice = package.Name
                                  Replaces = replaced })

                        Ok(draft, files))

    member _.Notes(workspace, id, revision, token: CancellationToken) =
        task {
            let found =
                lock gate (fun () ->
                    match find workspace id revision with
                    | Error why -> Error why
                    | Ok(session, draft) ->
                        match session.View.Input.Definition |> Option.bind _.Notes with
                        | None -> Error "This package has no notes."
                        | Some entry when entry.Size > 256L * 1024L ->
                            Error "The package notes exceed the text size limit."
                        | Some entry -> Ok(draft, entry))

            match found with
            | Error why -> return Error why
            | Ok(draft, entry) ->
                let! read =
                    inspection.WithInput(
                        draft.Artifact,
                        draft.Nested,
                        token,
                        fun contents ->
                            use output = new MemoryStream()
                            contents.ReadEntry(entry.Index, fun input -> input.CopyTo output)

                            try
                                UTF8Encoding(false, true)
                                    .GetString(output.ToArray())
                                    .TrimStart('\uFEFF')
                                |> Ok
                            with :? DecoderFallbackException ->
                                Error "The package notes are not UTF-8 text."
                    )

                match read with
                | Error _ ->
                    return Error "The package notes cannot be read. Check the archive location."
                | Ok(Error why) -> return Error why
                | Ok(Ok notes) ->
                    return
                        lock gate (fun () ->
                            find workspace id revision |> Result.map (fun _ -> notes))
        }
