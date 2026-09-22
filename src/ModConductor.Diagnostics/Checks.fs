namespace ModConductor.Diagnostics

open System
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.FilePlanning
open ModConductor.GameLaunching
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module internal Checks =
    let correlation kind id revision : DiagnosticCorrelation =
        { Kind = kind
          Id = id
          Revision = revision }

    let evidence label value : DiagnosticEvidence = { Label = label; Value = value }

    let private baseFinding
        (workspace: Workspace)
        (profile: Profile)
        (game: string)
        (id: string)
        (code: string)
        severity
        (title: string)
        (summary: string)
        (detail: string option)
        (area: string)
        (next: string)
        fixability
        (fixDetail: string)
        correlations
        action
        evidence
        =
        { Id = id
          Code = code
          Severity = severity
          WorkspaceId = workspace.Id
          ProfileId = profile.Id
          WorkspaceName = workspace.Name
          ProfileName = profile.Name
          GameName = game
          Title = title
          Summary = summary
          Detail = detail
          Area = area
          Evidence = evidence |> List.truncate Limits.evidence
          NextAction = next
          Fixability = fixability
          FixDetail = fixDetail
          Correlations = correlations
          Action = action }

    let launch (workspace: Workspace) (profile: Profile) (state: GameLaunchState) =
        match state.Latest, state.Problem with
        | Some run, _ when
            run.Phase = RunPhase.Failed
            || run.Phase = RunPhase.TrackingUnavailable
            || run.Phase = RunPhase.Cancelled
            ->
            let title, summary, code, severity, next, fixDetail, action =
                if run.Phase = RunPhase.TrackingUnavailable then
                    ("Mod Conductor cannot track the game",
                     "The game process can still run.",
                     "launch-tracking-unavailable",
                     DiagnosticSeverity.Error,
                     "Open Game. Check the current game process.",
                     "Mod Conductor cannot track this process",
                     DiagnosticAction.NavigateGame)
                elif run.Phase = RunPhase.Cancelled then
                    ("Mod Conductor canceled the Skyrim launch",
                     "The game did not start.",
                     "launch-cancelled",
                     DiagnosticSeverity.Information,
                     "When you are ready, select Play.",
                     "You do not need to change anything.",
                     DiagnosticAction.CheckAgain)
                else
                    ("Skyrim did not start",
                     "Mod Conductor cannot find the selected game file",
                     "launch-failed",
                     DiagnosticSeverity.Error,
                     "Open Game. Select the installed Skyrim folder.",
                     "Mod Conductor cannot fix this file location",
                     DiagnosticAction.NavigateGame)

            let gameSetup =
                match run.Source with
                | RunSource.Game game ->
                    [ correlation CorrelationKind.GameSetup game.ContextId (Some state.ContextRevision) ]
                | RunSource.Preset _ -> []

            [ baseFinding
                  workspace
                  profile
                  state.Name
                  ("launch:" + run.Id.ToString "N")
                  code
                  severity
                  title
                  summary
                  (if run.Phase = RunPhase.Failed then
                       Some "The launch stopped before a game process started."
                   else
                       None)
                  (profile.Name + " launch")
                  next
                  Fixability.NotFixable
                  fixDetail
                  (correlation CorrelationKind.Launch run.Id (Some run.Revision) :: gameSetup)
                  action
                  [ evidence "Workspace" workspace.Name
                    evidence "Profile" profile.Name
                    evidence "Game" state.Name
                    evidence "Result" title ] ]
        | None, Some _ ->
            [ baseFinding
                  workspace
                  profile
                  state.Name
                  "launch:setup"
                  "launch-setup"
                  DiagnosticSeverity.Error
                  "Mod Conductor cannot use the game setup"
                  "The launch did not start."
                  None
                  (profile.Name + " launch")
                  "Open Game. Check the saved game folder."
                  Fixability.NotFixable
                  "Mod Conductor cannot fix this game setup"
                  []
                  DiagnosticAction.NavigateGame
                  [ evidence "Workspace" workspace.Name; evidence "Profile" profile.Name; evidence "Game" state.Name ] ]
        | _ -> []

    let fileProblems
        (workspace: Workspace)
        (profile: Profile)
        (summary: FilePlanSummary)
        (problems: FileDiagnosticProblem list)
        =
        problems
        |> List.map (fun problem ->
            let tie = problem.Code = "priority-tie"
            let visibleSources = problem.Sources |> List.filter (fun source -> not source.Hidden)
            let fixableTie = tie && visibleSources.Length = 2
            let action =
                if fixableTie then
                    visibleSources
                    |> List.tryHead
                    |> Option.map (fun source -> DiagnosticAction.HideFileCopy(summary.Id, source.Copy))
                    |> Option.defaultValue DiagnosticAction.None
                else
                    DiagnosticAction.None

            let title = if tie then "Two copies have the same priority" else problem.Title
            let area = profile.Name + " mod files"
            let next =
                if fixableTie then
                    "Preview a change that hides one file copy."
                else
                    "Open Mods. Check the mod files."
            let target = problem.Target |> Option.map ModConductor.Platform.LogicalPath.display
            let sourceEvidence =
                problem.Sources
                |> List.truncate 2
                |> List.map (fun source -> evidence source.Name (source.VersionLabel + " · priority " + string source.Priority))

            baseFinding
                workspace profile "Skyrim Special Edition" ("mod-files:" + problem.Id) problem.Code DiagnosticSeverity.Error
                title
                (if tie then "Mod Conductor cannot select one file copy" else problem.Title)
                None
                area next
                (if action = DiagnosticAction.None then Fixability.NotFixable else Fixability.PreviewAvailable)
                (if action = DiagnosticAction.None then "Open the mod files" else "Preview change")
                [ correlation CorrelationKind.ModFiles summary.Id None ] action
                ([ evidence "Workspace" workspace.Name; evidence "Profile" profile.Name ]
                 @ (target |> Option.map (evidence "Target" >> List.singleton) |> Option.defaultValue [])
                 @ sourceEvidence))

    let deployment (workspace: Workspace) (profile: Profile) game (receipt: DeploymentReceipt) =
        if receipt.Phase = DeploymentPhase.Blocked || receipt.Completed < receipt.Total then
            [ baseFinding workspace profile game ("deployment:" + receipt.Id.ToString "N") "deployment-incomplete"
                  DiagnosticSeverity.Error "Deployment did not finish" "Mod Conductor can continue the restore" None
                  (profile.Name + " deployment") "Preview the remaining paths. Then continue the restore."
                  Fixability.PreviewAvailable "Mod Conductor can restore this"
                  [ correlation CorrelationKind.Deployment receipt.Id (Some receipt.Revision) ]
                  (DiagnosticAction.RecoverDeployment(receipt.Id, receipt.Revision))
                  [ evidence "Workspace" workspace.Name; evidence "Profile" profile.Name
                    evidence "Progress" (string receipt.Completed + " of " + string receipt.Total + " changes restored") ] ]
        else []

    let profileData (workspace: Workspace) (profile: Profile) game (state: ProfileDataState) =
        match state.Pending, state.Problem with
        | Some action, _ ->
            [ baseFinding workspace profile game ("profile:" + action.ToString "N") "profile-action-incomplete"
                  DiagnosticSeverity.Warning "A profile change did not finish" "Mod Conductor can continue the saved change." None
                  profile.Name "Open Profiles. Continue the saved change."
                  Fixability.NotFixable "Open the profile tools"
                  [ correlation CorrelationKind.Profile profile.Id (Some state.Revision)
                    correlation CorrelationKind.Action action None ]
                  (DiagnosticAction.ResumeProfileData action)
                  [ evidence "Workspace" workspace.Name; evidence "Profile" profile.Name ] ]
        | None, Some problem ->
            [ baseFinding workspace profile game "profile:problem" "profile-data-problem" DiagnosticSeverity.Warning
                  problem problem None
                  profile.Name "Open Profiles. Check the profile files."
                  Fixability.NotFixable "Open the profile files" [] DiagnosticAction.None
                  [ evidence "Workspace" workspace.Name; evidence "Profile" profile.Name; evidence "Problem" problem ] ]
        | _ -> []
    let skseLog
        (workspace: Workspace)
        (profile: Profile)
        contextId
        contextRevision
        (result: SkseLogResult)
        (owners: Map<string, string>)
        =
        let area = profile.Name + " script extender"

        let correlations =
            [ correlation CorrelationKind.GameSetup contextId (Some contextRevision) ]

        let commonEvidence =
            [ evidence "Workspace" workspace.Name; evidence "Profile" profile.Name ]

        match result with
        | SkseLogResult.Missing ->
            [ baseFinding
                  workspace
                  profile
                  "Skyrim Special Edition"
                  "skse-log:missing"
                  "skse-log-missing"
                  DiagnosticSeverity.Warning
                  "SKSE log was not found"
                  "Mod Conductor cannot check the installed SKSE plugins."
                  None
                  area
                  "Start Skyrim through SKSE. Then run Diagnostics again."
                  Fixability.NotFixable
                  "Start Skyrim to create the log"
                  correlations
                  DiagnosticAction.CheckAgain
                  commonEvidence ]
        | SkseLogResult.Stale modified ->
            [ baseFinding
                  workspace
                  profile
                  "Skyrim Special Edition"
                  "skse-log:stale"
                  "skse-log-stale"
                  DiagnosticSeverity.Warning
                  "SKSE log is out of date"
                  "The log is older than the latest Skyrim launch."
                  None
                  area
                  "Start Skyrim through SKSE. Then run Diagnostics again."
                  Fixability.NotFixable
                  "Start Skyrim to update the log"
                  correlations
                  DiagnosticAction.CheckAgain
                  (commonEvidence @ [ evidence "Log date" (modified.ToString "O") ]) ]
        | SkseLogResult.Malformed detail ->
            [ baseFinding
                  workspace
                  profile
                  "Skyrim Special Edition"
                  "skse-log:malformed"
                  "skse-log-malformed"
                  DiagnosticSeverity.Warning
                  "SKSE log cannot be read"
                  "Mod Conductor cannot check the installed SKSE plugins."
                  (Some detail)
                  area
                  "Start Skyrim through SKSE. Then run Diagnostics again."
                  Fixability.NotFixable
                  "Create a new SKSE log"
                  correlations
                  DiagnosticAction.CheckAgain
                  commonEvidence ]
        | SkseLogResult.Current issues ->
            issues
            |> List.map (fun issue ->
                let incompatible = issue.Problem = SksePluginProblem.Incompatible
                let owner = owners |> Map.tryFind (issue.Name.ToLowerInvariant())

                let title =
                    if incompatible then
                        "SKSE plugin is incompatible"
                    else
                        "SKSE plugin did not load"

                let summary =
                    if incompatible then
                        issue.Name + " is not compatible with the current Skyrim runtime."
                    else
                        issue.Name + " did not load."

                baseFinding
                    workspace
                    profile
                    "Skyrim Special Edition"
                    ("skse-plugin:" + issue.Name.ToLowerInvariant())
                    (if incompatible then
                         "skse-plugin-incompatible"
                     else
                         "skse-plugin-load-failed")
                    DiagnosticSeverity.Error
                    title
                    summary
                    None
                    area
                    "Update or disable this SKSE plugin. Then run Diagnostics again."
                    Fixability.NotFixable
                    "You need to update or disable this plugin"
                    correlations
                    DiagnosticAction.CheckAgain
                    (commonEvidence
                     @ [ evidence "DLL" issue.Name ]
                     @ (owner
                        |> Option.map (evidence "Mod" >> List.singleton)
                        |> Option.defaultValue [])))

    let oldPluginFormats
        (workspace: Workspace)
        (profile: Profile)
        contextId
        contextRevision
        snapshotId
        (plugins: OldPluginFormat list)
        =
        plugins
        |> List.map (fun plugin ->
            baseFinding
                workspace
                profile
                "Skyrim Special Edition"
                ("old-plugin-form:" + plugin.Name.ToLowerInvariant())
                "skyrim-plugin-old-form"
                DiagnosticSeverity.Warning
                "Plugin uses an old form version"
                (plugin.Name + " uses form version " + string plugin.FormVersion + ".")
                None
                (profile.Name + " plugins")
                "Get an updated plugin, or update it with the Creation Kit."
                Fixability.NotFixable
                "Mod Conductor will not change this plugin"
                [ correlation CorrelationKind.GameSetup contextId (Some contextRevision)
                  correlation CorrelationKind.PluginSnapshot snapshotId None ]
                DiagnosticAction.None
                ([ evidence "Workspace" workspace.Name
                   evidence "Profile" profile.Name
                   evidence "Plugin" plugin.Name
                   evidence "Form version" (string plugin.FormVersion) ]
                 @ (plugin.Owner
                    |> Option.map (evidence "Mod" >> List.singleton)
                    |> Option.defaultValue [])))
