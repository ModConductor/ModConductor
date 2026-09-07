namespace ModConductor.Engine

open System
open System.Threading.Tasks
open Grpc.Core
open ModConductor.Platform
open ModConductor.Workspaces
open ModConductor.Protocol.V1

module private WorkspaceWire =
    let reject message =
        raise (RpcException(Status(StatusCode.InvalidArgument, message)))

    let id value =
        match Guid.TryParseExact(value, "N") with
        | true, id when id <> Guid.Empty -> id
        | _ -> reject "Invalid workspace or profile ID."

    let revision value =
        if value > uint64 Int64.MaxValue then
            reject "Invalid revision."

        int64 value

    let root value =
        match HostPath.create value with
        | Error detail -> Error(WorkspaceError.InvalidRoot detail)
        | Ok path ->
            match RootSelection.select path with
            | Ok root -> Ok root
            | Error _ ->
                Error(
                    WorkspaceError.InvalidRoot
                        "The selected folder is unavailable or is not a directory."
                )

    let profile (value: ModConductor.Workspaces.Profile) =
        ProfileInfo(ProfileId = value.Id.ToString("N"), Name = value.Name)

    let workspace (value: Workspace) =
        let result =
            WorkspaceInfo(
                WorkspaceId = value.Id.ToString("N"),
                Name = value.Name,
                Path = HostPath.value value.Path,
                Revision = uint64 value.Revision
            )

        value.SelectedProfile
        |> Option.iter (fun item -> result.SelectedProfile <- profile item)

        value.PendingRoot
        |> Option.iter (fun issue ->
            result.PendingRoot <-
                PendingWorkspaceRoot(
                    ReceiptRevision = uint64 issue.ReceiptRevision,
                    Reason =
                        match issue.Reason with
                        | RootIssueReason.IncompleteCreation ->
                            WorkspaceRootIssueReason.IncompleteCreation
                        | RootIssueReason.OwnershipUnproved ->
                            WorkspaceRootIssueReason.OwnershipUnproved
                        | RootIssueReason.IdentityUnverified ->
                            WorkspaceRootIssueReason.IdentityUnverified
                ))

        result

    let fault error =
        let code, detail =
            match error with
            | WorkspaceError.NotFound ->
                WorkspaceFaultCode.NotFound, "The workspace or profile was not found."
            | WorkspaceError.StaleRevision ->
                WorkspaceFaultCode.StaleRevision, "The workspace changed."
            | WorkspaceError.IdentityConflict ->
                WorkspaceFaultCode.IdentityConflict,
                "The workspace folder or identity does not match. Existing files were left unchanged."
            | WorkspaceError.SelectedProfile ->
                WorkspaceFaultCode.SelectedProfile, "Select another profile before deletion."
            | WorkspaceError.InvalidName ->
                WorkspaceFaultCode.InvalidName, "Enter a name of 1 to 256 characters."
            | WorkspaceError.InvalidRoot detail -> WorkspaceFaultCode.InvalidRoot, detail
            | WorkspaceError.RootUnresolved ->
                WorkspaceFaultCode.RootUnresolved,
                "Workspace creation needs a check before more changes."
            | WorkspaceError.Busy ->
                WorkspaceFaultCode.Busy, "A workspace change is still in progress."

        WorkspaceFault(Code = code, Detail = detail)

    let pageReply =
        function
        | Error error -> WorkspaceReply(Fault = fault error)
        | Ok(value: ModConductor.Workspaces.WorkspacePage) ->
            let page =
                ModConductor.Protocol.V1.WorkspacePage(Workspace = workspace value.Workspace)

            page.Profiles.AddRange(value.Profiles |> Seq.map profile)

            value.NextProfile
            |> Option.iter (fun next -> page.NextProfileId <- next.ToString("N"))

            WorkspaceReply(Page = page)

    let changeReply =
        function
        | Error error -> ProfileReply(Fault = fault error)
        | Ok(value: ModConductor.Workspaces.ProfileChange) ->
            let change =
                ModConductor.Protocol.V1.ProfileChange(Workspace = workspace value.Workspace)

            value.Changed |> Option.iter (fun item -> change.Changed <- profile item)

            value.Deleted
            |> Option.iter (fun item -> change.DeletedProfileId <- item.ToString("N"))

            ProfileReply(Change = change)

    let edit (request: EditProfileRequest) =
        let value (profile: ProfileInfo) : ModConductor.Workspaces.Profile =
            { Id = id profile.ProfileId
              Name = profile.Name }

        match request.EditCase with
        | EditProfileRequest.EditOneofCase.CreateProfile ->
            ProfileEdit.Create(value request.CreateProfile)
        | EditProfileRequest.EditOneofCase.CloneProfile ->
            ProfileEdit.Clone(
                id request.CloneProfile.SourceProfileId,
                value request.CloneProfile.Copy
            )
        | EditProfileRequest.EditOneofCase.RenameProfile ->
            ProfileEdit.Rename(id request.RenameProfile.ProfileId, request.RenameProfile.Name)
        | EditProfileRequest.EditOneofCase.SelectProfileId ->
            ProfileEdit.Select(id request.SelectProfileId)
        | EditProfileRequest.EditOneofCase.DeleteProfileId ->
            ProfileEdit.Delete(id request.DeleteProfileId)
        | _ -> reject "Choose a profile action."

    let execute action =
        task {
            try
                return! action ()
            with :? ModConductor.Operations.CapacityException ->
                return
                    raise (
                        RpcException(
                            Status(StatusCode.ResourceExhausted, "The workspace queue is full.")
                        )
                    )
        }

type WorkspaceService(state: IWorkspaceState) =
    inherit WorkspaceOperations.WorkspaceOperationsBase()
    let selection = new System.Threading.SemaphoreSlim(2, 2)

    let selected path action =
        WorkspaceWire.execute (fun () ->
            task {
                if not (selection.Wait(0)) then
                    return WorkspaceWire.pageReply (Error WorkspaceError.Busy)
                else
                    try
                        let! root = Task.Run(fun () -> WorkspaceWire.root path)

                        match root with
                        | Error error -> return WorkspaceWire.pageReply (Error error)
                        | Ok root ->
                            let! result = action root
                            return WorkspaceWire.pageReply result
                    finally
                        selection.Release() |> ignore
            })

    override _.CreateWorkspace(request, _) =
        if request.ExpectedRevision <> 0UL then
            Task.FromResult(WorkspaceWire.pageReply (Error WorkspaceError.StaleRevision))
        else
            let id = WorkspaceWire.id request.WorkspaceId
            selected request.Path (fun root -> state.Create(id, request.Name, root))

    override _.OpenWorkspace(request, _) = selected request.Path state.Open

    override _.ReadWorkspace(request, _) =
        WorkspaceWire.execute (fun () ->
            task {
                let after =
                    if request.HasAfterProfileId then
                        Some(WorkspaceWire.id request.AfterProfileId)
                    else
                        None

                let! result = state.Read(WorkspaceWire.id request.WorkspaceId, after)
                return WorkspaceWire.pageReply result
            })

    override _.EditProfile(request, _) =
        WorkspaceWire.execute (fun () ->
            task {
                let! result =
                    state.Edit(
                        WorkspaceWire.id request.WorkspaceId,
                        WorkspaceWire.revision request.ExpectedRevision,
                        WorkspaceWire.edit request
                    )

                return WorkspaceWire.changeReply result
            })

    override _.CheckWorkspace(request, _) =
        WorkspaceWire.execute (fun () ->
            task {
                let! result =
                    state.Check(
                        WorkspaceWire.id request.WorkspaceId,
                        WorkspaceWire.revision request.ExpectedReceiptRevision
                    )

                return WorkspaceWire.pageReply result
            })

    override _.RecentWorkspaces(request, _) =
        WorkspaceWire.execute (fun () ->
            task {
                let after =
                    if request.HasAfterWorkspaceId then
                        Some(WorkspaceWire.id request.AfterWorkspaceId)
                    else
                        None

                let! result = state.Recent after
                let reply = RecentWorkspacesReply()
                reply.Workspaces.AddRange(result.Workspaces |> Seq.map WorkspaceWire.workspace)

                result.NextWorkspace
                |> Option.iter (fun next -> reply.NextWorkspaceId <- next.ToString("N"))

                return reply
            })
