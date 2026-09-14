namespace ModConductor.ProfileGameData

open System
open System.Security.Cryptography
open System.Threading
open ModConductor.Bethesda
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.Platform

type internal ArchivePolicyProfileInput =
    { Scope: ProfileDataScope
      IniName: string
      IniFile: DataFile option
      IniBytes: byte array
      IniStamp: ArchivePolicyIniStamp
      Policy: ArchivePolicyInput option }

module internal ArchivePolicies =
    let private settings (scope: ProfileDataScope) =
        match scope.Game.Binding with
        | Some value when value.Evidence.DefinitionId = Skyrim.definition.Id -> ()
        | _ ->
            raise (
                ProfileDataException(
                    ProfileDataError.Unavailable
                        "Archive changes require a checked Skyrim Special Edition game folder."
                )
            )

        scope.Profile
        |> Option.filter (fun value ->
            value.Options.Settings && value.SettingsInitialized && value.Settings.IsSome)
        |> Option.defaultWith (fun () ->
            raise (
                ProfileDataException(
                    ProfileDataError.Unavailable
                        "Enable and initialize profile settings before changing Skyrim archives."
                )
            ))

    let private ini (scope: ProfileDataScope) token =
        let profile = settings scope
        let root = profile.Settings.Value
        use held = HeldDirectory.Open(root.Path, root.Identity)

        let actual =
            DataLocations.iniNames held
            |> List.find (fun (declared, _) -> declared = "Skyrim.ini")
            |> snd

        let observed = DataFiles.observe held actual token
        let bytes = DataFiles.readIni held actual observed token |> Option.defaultValue [||]

        let stamp =
            { Identity = observed |> Option.map _.Identity
              Length = bytes.LongLength
              Sha256 =
                Convert.ToHexString(SHA256.HashData bytes).ToLowerInvariant() }
            : ArchivePolicyIniStamp

        actual, observed, bytes, stamp

    let private input scope (headers: PluginSnapshot) token =
        let actual, observed, bytes, stamp = ini scope token
        let pluginInput = PluginInputs.read scope headers.Entries token
        let saved = scope.Profile |> Option.bind _.PluginOrder
        let order = OrderRules.reconcile pluginInput.Facts headers.Entries pluginInput.Bytes saved
        let view = OrderRules.inspect pluginInput.Facts headers.Entries order

        { Scope = scope
          IniName = actual
          IniFile = observed
          IniBytes = bytes
          IniStamp = stamp
          Policy =
            Some
                { Headers = headers
                  Order = view
                  Explicit = Ini.archiveEntries bytes
                  Ini = stamp } }

    let private reference (scope: ProfileDataScope) =
        { WorkspaceId = scope.WorkspaceId
          ProfileId = scope.ProfileId
          ContextId =
            scope.Context
            |> Option.map _.Id
            |> Option.defaultWith (fun () ->
                DataLocations.id scope.WorkspaceId (DataLocations.documents scope.Game))
          Revision = scope.Context |> Option.map _.Revision |> Option.defaultValue 0L }
        : ProfileDataRef

    let private view
        (repository: IProfileDataRepository)
        (input: ArchivePolicyProfileInput)
        (snapshot: ArchivePolicySnapshot)
        =
        task {
            let currentStamp = input.IniStamp

            let snapshot =
                { snapshot with
                    Stale = snapshot.Stale || snapshot.Ini <> currentStamp }

            let pending = input.Scope.Context |> Option.bind _.Pending
            let! action =
                match pending with
                | Some id -> repository.Action(input.Scope.WorkspaceId, id)
                | None -> System.Threading.Tasks.Task.FromResult None

            let saved = input.Scope.Profile |> Option.bind _.ArchiveList |> Option.isSome

            let applied =
                saved
                && input.Scope.Context
                   |> Option.bind _.Applied
                   |> Option.exists (fun value ->
                       value.ProfileId = input.Scope.ProfileId && value.Options.Settings)

            return
                { Reference = reference input.Scope
                  Snapshot = snapshot
                  IniName = input.IniName
                  Saved = saved
                  Applied = applied
                  Pending = pending.IsSome
                  Problem = action |> Option.bind _.Problem }
        }

    let scan
        (repository: IProfileDataRepository)
        (plugins: PluginSession)
        (archives: ArchivePolicySession)
        (workspace: Guid)
        (profile: Guid)
        (headers: Guid)
        token
        =
        task {
            let! header = PluginOrders.headers plugins workspace profile headers
            let! scope = repository.Read(workspace, profile)
            let input = input scope header token
            let! result = archives.Scan(profile, input.Policy.Value, token)

            match result with
            | Ok snapshot -> return! view repository input snapshot
            | Error FilePlanError.Busy ->
                return raise (ProfileDataException ProfileDataError.Busy)
            | Error FilePlanError.Cancelled ->
                return raise (ProfileDataException ProfileDataError.Cancelled)
            | Error FilePlanError.Stale
            | Error FilePlanError.Expired ->
                return raise (ProfileDataException ProfileDataError.Stale)
            | Error(FilePlanError.ContextUnavailable detail)
            | Error(FilePlanError.FileUnavailable detail)
            | Error(FilePlanError.LimitExceeded detail) ->
                return raise (ProfileDataException(ProfileDataError.Unavailable detail))
            | Error _ ->
                return
                    raise (
                        ProfileDataException(
                            ProfileDataError.Invalid
                                "The current archive sources cannot be resolved."
                        )
                    )
        }

    let read
        (repository: IProfileDataRepository)
        (archives: ArchivePolicySession)
        (workspace: Guid)
        (profile: Guid)
        (snapshot: Guid)
        token
        =
        task {
            let! result = archives.Read snapshot

            match result with
            | Ok snapshot when
                snapshot.Stamp.WorkspaceId = workspace && snapshot.Stamp.ProfileId = profile
                ->
                let! scope = repository.Read(workspace, profile)
                let actual, observed, bytes, stamp = ini scope token

                let input =
                    { Scope = scope
                      IniName = actual
                      IniFile = observed
                      IniBytes = bytes
                      IniStamp = stamp
                      Policy = None }

                return! view repository input snapshot
            | Ok _
            | Error FilePlanError.Stale
            | Error FilePlanError.Expired ->
                return raise (ProfileDataException ProfileDataError.Stale)
            | Error FilePlanError.Busy ->
                return raise (ProfileDataException ProfileDataError.Busy)
            | Error _ ->
                return
                    raise (
                        ProfileDataException(
                            ProfileDataError.Unavailable
                                "Refresh the current archive sources and try again."
                        )
                    )
        }

    let prepareApply
        (repository: IProfileDataRepository)
        (archives: ArchivePolicySession)
        (expected: ProfileDataRef)
        (snapshotId: Guid)
        token
        =
        task {
            let! result = archives.Read snapshotId

            let snapshot =
                match result with
                | Ok value when
                    value.Stamp.WorkspaceId = expected.WorkspaceId
                    && value.Stamp.ProfileId = expected.ProfileId
                    && not value.Stale
                    ->
                    value
                | _ -> raise (ProfileDataException ProfileDataError.Stale)

            match snapshot.BlockingProblems with
            | detail :: _ ->
                raise (ProfileDataException(ProfileDataError.Invalid detail))
            | [] -> ()

            let! verified = archives.Verify(snapshot, token)

            match verified with
            | Ok() -> ()
            | Error FilePlanError.Cancelled ->
                raise (ProfileDataException ProfileDataError.Cancelled)
            | Error FilePlanError.Busy ->
                raise (ProfileDataException ProfileDataError.Busy)
            | Error FilePlanError.Stale
            | Error FilePlanError.Expired ->
                raise (ProfileDataException ProfileDataError.Stale)
            | Error(FilePlanError.FileUnavailable detail)
            | Error(FilePlanError.ContextUnavailable detail)
            | Error(FilePlanError.LimitExceeded detail) ->
                raise (ProfileDataException(ProfileDataError.Unavailable detail))
            | Error _ ->
                raise (ProfileDataException ProfileDataError.Stale)

            let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
            let actual, observed, bytes, stamp = ini scope token

            if reference scope <> expected || stamp <> snapshot.Ini then
                raise (ProfileDataException ProfileDataError.Stale)

            return
                scope,
                { SnapshotId = snapshotId
                  Names = snapshot.ExplicitNames
                  Stamp = snapshot.Stamp
                  IniName = actual
                  Ini = observed }
        }
