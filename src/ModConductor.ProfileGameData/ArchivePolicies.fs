namespace ModConductor.ProfileGameData

open System
open ModConductor.Bethesda
open ModConductor.FilePlanning

module internal ArchivePolicies =
    let private resultTask = ProfileDataResultTask.resultTask

    let private scanError =
        function
        | FilePlanError.Busy -> ProfileDataError.Busy
        | FilePlanError.Cancelled -> ProfileDataError.Cancelled
        | FilePlanError.Stale
        | FilePlanError.Expired -> ProfileDataError.Stale
        | FilePlanError.ContextUnavailable detail
        | FilePlanError.FileUnavailable detail
        | FilePlanError.LimitExceeded detail -> ProfileDataError.Unavailable detail
        | _ -> ProfileDataError.Invalid "The current archive sources cannot be resolved."

    let private readError =
        function
        | FilePlanError.Stale
        | FilePlanError.Expired -> ProfileDataError.Stale
        | FilePlanError.Busy -> ProfileDataError.Busy
        | _ -> ProfileDataError.Unavailable "Refresh the current archive sources and try again."

    let private verifyError =
        function
        | FilePlanError.Cancelled -> ProfileDataError.Cancelled
        | FilePlanError.Busy -> ProfileDataError.Busy
        | FilePlanError.Stale
        | FilePlanError.Expired -> ProfileDataError.Stale
        | FilePlanError.FileUnavailable detail
        | FilePlanError.ContextUnavailable detail
        | FilePlanError.LimitExceeded detail -> ProfileDataError.Unavailable detail
        | _ -> ProfileDataError.Stale

    let scan
        (repository: IProfileDataRepository)
        (plugins: PluginSession)
        (archives: ArchivePolicySession)
        (workspace: Guid)
        (profile: Guid)
        (headers: Guid)
        token
        =
        resultTask {
            let! headerResult = PluginOrders.headers plugins workspace profile headers
            let! header = headerResult
            let! scopeResult = repository.Read(workspace, profile)
            let! scope = scopeResult
            let! input = ArchivePolicyProjection.input scope header token
            let! scanned = archives.Scan(profile, input.Policy.Value, token)
            let! snapshot = scanned |> Result.mapError scanError

            let! policyResult =
                ArchivePolicyProjection.view repository archives input snapshot token

            let! policy = policyResult
            return policy
        }

    let read
        (repository: IProfileDataRepository)
        (archives: ArchivePolicySession)
        (workspace: Guid)
        (profile: Guid)
        (snapshot: Guid)
        token
        =
        resultTask {
            let! result = archives.Read snapshot

            match result with
            | Ok snapshot when
                snapshot.Stamp.WorkspaceId = workspace && snapshot.Stamp.ProfileId = profile
                ->
                let! scopeResult = repository.Read(workspace, profile)
                let! scope = scopeResult
                let! actual, observed, bytes, stamp = ArchivePolicyProjection.ini scope token

                let input =
                    { Scope = scope
                      IniName = actual
                      IniFile = observed
                      IniBytes = bytes
                      IniStamp = stamp
                      Policy = None }

                let! policyResult =
                    ArchivePolicyProjection.view repository archives input snapshot token

                let! policy = policyResult
                return policy
            | Ok _ -> return! Error ProfileDataError.Stale
            | Error error -> return! Error(readError error)
        }

    let prepareApply
        (repository: IProfileDataRepository)
        (archives: ArchivePolicySession)
        (expected: ProfileDataRef)
        (snapshotId: Guid)
        token
        =
        resultTask {
            let! result = archives.Read snapshotId

            let! snapshot =
                match result with
                | Ok value when
                    value.Stamp.WorkspaceId = expected.WorkspaceId
                    && value.Stamp.ProfileId = expected.ProfileId
                    && not value.Stale
                    ->
                    Ok value
                | _ -> Error ProfileDataError.Stale

            let! scopeResult = repository.Read(expected.WorkspaceId, expected.ProfileId)
            let! scope = scopeResult
            let! actual, observed, bytes, stamp = ArchivePolicyProjection.ini scope token

            let! reference = ArchivePolicyProjection.reference scope

            if reference <> expected || stamp <> snapshot.Ini then
                return! Error ProfileDataError.Stale

            let! changes = ArchivePolicyProjection.delta archives scope snapshot token

            if changes.IsEmpty then
                return scope, None
            else
                match snapshot.BlockingProblems with
                | detail :: _ -> return! Error(ProfileDataError.Invalid detail)
                | [] -> ()

                let! verified = archives.Verify(snapshot, token)
                let! () = verified |> Result.mapError verifyError
                do! IniArchives.validateNames snapshot.ExplicitNames

                return
                    scope,
                    Some
                        { SnapshotId = snapshotId
                          Names = snapshot.ExplicitNames
                          Stamp = snapshot.Stamp
                          IniName = actual
                          Ini = observed }
        }
