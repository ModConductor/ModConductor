namespace ModConductor.ProfileGameData

open System
open System.Collections.Generic
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

module internal ArchivePolicyProjection =
    let private same (left: string) (right: string) =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private namesEqual left right =
        List.length left = List.length right && List.forall2 same left right

    let explicitNames bytes =
        let names = HashSet<string>(StringComparer.OrdinalIgnoreCase)

        [ for name in SkyrimArchives.required do
              if names.Add name then
                  yield name
          for entry in Ini.archiveEntries bytes do
              if names.Add entry.Name then
                  yield entry.Name ]

    let private changes (before: string list) (after: string list) =
        let previous = HashSet<string>(before, StringComparer.OrdinalIgnoreCase)
        let current = HashSet<string>(after, StringComparer.OrdinalIgnoreCase)
        let beforeCommon = before |> List.filter current.Contains
        let afterCommon = after |> List.filter previous.Contains
        let priorPositions = Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)
        let nextPositions = Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)
        beforeCommon |> List.iteri (fun index name -> priorPositions[name] <- index)
        after |> List.iteri (fun index name -> nextPositions[name] <- index + 1)

        [ for name in after do
              if not (previous.Contains name) then
                  yield "Added " + name
          for name in before do
              if not (current.Contains name) then
                  yield "Removed " + name
          for index, name in afterCommon |> List.indexed do
              if priorPositions[name] <> index then
                  yield "Moved " + name + " to position " + string nextPositions[name] ]

    let private activeDocuments (scope: ProfileDataScope) token =
        let active =
            scope.Context
            |> Option.bind _.Applied
            |> Option.exists (fun value ->
                value.ProfileId = scope.ProfileId && value.Options.Settings)

        if active then
            let root = scope.Context.Value.Documents
            use held = HeldDirectory.Open(root.Path, root.Identity)

            let actual =
                DataLocations.iniNames held
                |> List.find (fun (declared, _) -> declared = "Skyrim.ini")
                |> snd

            let file = DataFiles.observe held actual token
            let bytes = DataFiles.readIni held actual file token |> Option.defaultValue [||]
            Some(Ini.archiveEntries bytes |> List.map _.Name)
        else
            None

    let delta
        (archives: ArchivePolicySession)
        (scope: ProfileDataScope)
        (snapshot: ArchivePolicySnapshot)
        token
        =
        let before =
            archives.ObservedNames scope.ProfileId
            |> Option.defaultValue snapshot.ExplicitNames

        let edited = changes before snapshot.ExplicitNames

        if edited.IsEmpty then
            []
        else
            match activeDocuments scope token with
            | Some actual when not (namesEqual actual snapshot.ExplicitNames) -> edited
            | _ -> []

    let private settings (scope: ProfileDataScope) =
        match scope.Game.Binding with
        | Some value when value.Evidence.DefinitionId = Skyrim.definition.Id ->
            match scope.Profile with
            | Some profile when
                profile.Options.Settings
                && profile.SettingsInitialized
                && profile.Settings.IsSome
                ->
                Ok profile
            | _ ->
                Error(
                    ProfileDataError.Unavailable
                        "Enable and initialize profile settings before changing Skyrim archives."
                )
        | _ ->
            Error(
                ProfileDataError.Unavailable
                    "Archive changes require a checked Skyrim Special Edition game folder."
            )

    let ini (scope: ProfileDataScope) token =
        settings scope
        |> Result.map (fun profile ->
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
                  Sha256 = Convert.ToHexString(SHA256.HashData bytes).ToLowerInvariant() }
                : ArchivePolicyIniStamp

            actual, observed, bytes, stamp)

    let input scope (headers: PluginSnapshot) token =
        ProfileDataResultFlow.result {
            let! actual, observed, bytes, stamp = ini scope token
            let! pluginInput = PluginInputs.read scope headers.Entries token
            let saved = scope.Profile |> Option.bind _.PluginOrder

            let order =
                OrderRules.reconcile pluginInput.Facts headers.Entries pluginInput.Bytes saved

            let view = OrderRules.inspect pluginInput.Facts headers.Entries order

            return
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
        }

    let reference (scope: ProfileDataScope) =
        { WorkspaceId = scope.WorkspaceId
          ProfileId = scope.ProfileId
          ContextId =
            scope.Context
            |> Option.map _.Id
            |> Option.defaultWith (fun () ->
                DataLocations.id scope.WorkspaceId (DataLocations.documents scope.Game))
          Revision = scope.Context |> Option.map _.Revision |> Option.defaultValue 0L }
        : ProfileDataRef

    let view
        (repository: IProfileDataRepository)
        (archives: ArchivePolicySession)
        (input: ArchivePolicyProfileInput)
        (snapshot: ArchivePolicySnapshot)
        token
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

            let changes = delta archives input.Scope snapshot token

            return
                { Reference = reference input.Scope
                  Snapshot = snapshot
                  IniName = input.IniName
                  Saved = saved
                  Applied = changes.IsEmpty
                  Changes = changes
                  Pending = pending.IsSome
                  Problem = action |> Option.bind _.Problem }
        }
