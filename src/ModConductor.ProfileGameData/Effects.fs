namespace ModConductor.ProfileGameData

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform

module internal DataEffects =
    let linkName (context: ProfileDataContext) =
        ".mod-conductor-saves-" + context.Id.ToString("N")

    let private matchingLink (directory: HeldDirectory) name identity =
        match directory.InspectEntry name with
        | Some entry when
            entry.Kind = EntryKind.Link
            && entry.Identity = identity
            && entry.LinkTarget.IsSome
            ->
            entry
        | _ -> DataFiles.fail "The profile save link changed. It was left untouched."

    let run
        (context: ProfileDataContext)
        (initial: ProfileDataActionRecord)
        (save: ProfileDataActionRecord -> Task<unit>)
        (token: CancellationToken)
        (checkpoint: string -> unit)
        =
        task {
            use documents =
                HeldDirectory.Open(context.Documents.Path, context.Documents.Identity)

            use workspace =
                HeldDirectory.Open(context.Workspace.Path, context.Workspace.Identity)

            let mutable action = initial

            for index, effect in action.Files |> List.indexed do
                token.ThrowIfCancellationRequested()
                use target = HeldDirectory.Open(effect.Target.Path, effect.Target.Identity)
                use backups = HeldDirectory.Open(effect.Backups.Path, effect.Backups.Identity)
                DataFiles.apply target backups effect.Change token checkpoint

                if index >= action.CompletedFiles then
                    action <-
                        { action with
                            CompletedFiles = index + 1 }

                    do! save action
                    checkpoint "file-recorded"

            let name = linkName context

            let previous, next =
                match action.Link with
                | SaveLinkEffect.Unchanged -> None, None
                | SaveLinkEffect.Remove previous -> Some previous, None
                | SaveLinkEffect.Create target -> None, Some target
                | SaveLinkEffect.Replace(previous, target) -> Some previous, Some target

            match previous with
            | Some identity when not action.LinkRemoved ->
                match documents.InspectEntry name with
                | None -> ()
                | Some _ -> documents.RemoveLink(name, matchingLink documents name identity)

                checkpoint "link-removed"
                action <- { action with LinkRemoved = true }
                do! save action
            | _ -> ()

            match next with
            | Some target ->
                use backing = HeldDirectory.Open(target.Path, target.Identity)

                match action.LinkCreated with
                | Some identity ->
                    let entry = matchingLink documents name identity

                    if entry.LinkTarget <> Some(HostPath.value target.Path) then
                        DataFiles.fail "The profile save link has a different destination."
                | None ->
                    if documents.InspectEntry name |> Option.isSome then
                        DataFiles.fail
                            "The save link has no recorded identity. Review it before continuing."

                    let created = documents.CreateLink(name, HostPath.value target.Path, true)
                    checkpoint "link-created"

                    action <-
                        { action with
                            LinkCreated = Some created.Identity }

                    do! save action
            | None -> ()

            return action
        }
