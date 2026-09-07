namespace ModConductor.Engine

open System
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Protocol.V1

module internal ProfileModWire =
    let selection (id: Guid) state =
        let result = ProfileModSelection(ModId = id.ToString("N"))

        match state with
        | SelectionState.Managed(priority, enabled) ->
            result.Managed <- ManagedProfileMod(Priority = uint32 priority, Enabled = enabled)
        | SelectionState.Separator priority ->
            result.Separator <- OrderedProfileMod(Priority = uint32 priority)
        | SelectionState.Locked restriction ->
            result.Locked <-
                match restriction with
                | SelectionRestriction.Backup -> ProfileModRestriction.Backup
                | SelectionRestriction.Unmanaged -> ProfileModRestriction.Unmanaged
                | SelectionRestriction.Automatic -> ProfileModRestriction.Automatic

        result

    let position (row: OrderedMod) =
        selection
            row.Id
            (match row.Enabled with
             | Some enabled -> SelectionState.Managed(row.Priority, enabled)
             | None -> SelectionState.Separator row.Priority)

    let fault error =
        let result = ModLibraryWire.fault error

        match error with
        | LibraryError.StaleRevision -> result.Detail <- "The profile changed. Reload its mods."
        | LibraryError.NotFound -> result.Detail <- "The profile or a selected mod was not found."
        | LibraryError.IdentityConflict -> result.Detail <- "Choose each mod only once."
        | LibraryError.InvalidMetadata
        | LibraryError.InvalidSource
        | LibraryError.UnprovedOwnership
        | LibraryError.SourceChanged
        | LibraryError.UnsupportedAction
        | LibraryError.Busy
        | LibraryError.LimitExceeded
        | LibraryError.FileUnavailable
        | LibraryError.Cancelled -> ()

        result

    let edit (request: ChangeProfileModsRequest) =
        match request.EditCase with
        | ChangeProfileModsRequest.EditOneofCase.Enabled -> SelectionEdit.Enable request.Enabled
        | ChangeProfileModsRequest.EditOneofCase.Move ->
            match request.Move with
            | ProfileModMove.Up -> SelectionEdit.MoveUp
            | ProfileModMove.Down -> SelectionEdit.MoveDown
            | _ -> ModLibraryWire.reject "Choose a move direction."
        | _ -> ModLibraryWire.reject "Choose an enable or move action."

type ProfileModService(selection: IModSelection) =
    inherit ProfileModOperations.ProfileModOperationsBase()

    override _.ChangeProfileMods(request, _) =
        task {
            if request.ModIds.Count > 512 then
                ModLibraryWire.reject "Too many selected mods."

            let! result =
                selection.Change(
                    ModLibraryWire.id request.ProfileId,
                    ModLibraryWire.number request.ExpectedRevision,
                    request.ModIds |> Seq.map ModLibraryWire.id |> List.ofSeq,
                    ProfileModWire.edit request
                )

            return
                match result with
                | Error error -> ProfileModsChangeReply(Fault = ProfileModWire.fault error)
                | Ok value ->
                    let delta =
                        ProfileModsDelta(
                            Revision = uint64 value.Revision,
                            EnabledCount = uint32 value.EnabledCount
                        )

                    delta.Changed.AddRange(value.Changed |> Seq.map ProfileModWire.position)
                    ProfileModsChangeReply(Delta = delta)
        }
