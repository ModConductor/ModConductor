namespace ModConductor.Diagnostics

open System
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.FilePlanning
open ModConductor.GameLaunching
open ModConductor.Operations
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module internal Checks =
    let correlation kind id revision =
        { Kind = kind
          Id = id
          Revision = revision }

    let evidence label value = { Label = label; Value = value }

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
        | Some run, _ when run.Phase = RunPhase.Failed || run.Phase = RunPhase.TrackingUnavailable ->
            let title, summary, code =
                if run.Phase = RunPhase.TrackingUnavailable then
                    "Mod Conductor cannot track the game", "The game process can still run.", "launch-tracking-unavailable"
                else
                    "Skyrim did not start", "Mod Conductor cannot find the selected game file", "launch-failed"

            [ baseFinding
                  workspace
                  profile
                  state.Name
                  ("launch:" + run.Id.ToString "N")
                  code
                  DiagnosticSeverity.Error
                  title
                  summary
                  (if run.Phase = RunPhase.Failed then
                       Some "The launch stopped before a game process started."
                   else
                       None)
                  (profile.Name + " launch")
                  "Open Game. Select the installed Skyrim folder."
                  Fixability.NotFixable
                  "Mod Conductor cannot fix this file location"
                  [ correlation CorrelationKind.Launch (run.Id.ToString "N") (Some run.Revision)
                    correlation CorrelationKind.GameSetup state.SourceToken (Some state.ContextRevision) ]
                  DiagnosticAction.NavigateGame
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
                  [ correlation CorrelationKind.GameSetup state.SourceToken (Some state.ContextRevision) ]
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

            let title = if tie then "Two copies have the same priority" else "Mod files need attention"
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
                (if tie then "Mod Conductor cannot select one file copy" else "The current mod files contain a problem.")
                None
                area next
                (if action = DiagnosticAction.None then Fixability.NotFixable else Fixability.PreviewAvailable)
                (if action = DiagnosticAction.None then "You need to fix this" else "Mod Conductor can fix this")
                [ correlation CorrelationKind.ModFiles (summary.Id.ToString "N") None ] action
                ([ evidence "Workspace" workspace.Name; evidence "Profile" profile.Name ]
                 @ (target |> Option.map (evidence "Target" >> List.singleton) |> Option.defaultValue [])
                 @ sourceEvidence))

    let deployment (workspace: Workspace) (profile: Profile) game (receipt: DeploymentReceipt) =
        if receipt.Phase = DeploymentPhase.Blocked || receipt.Completed < receipt.Total then
            [ baseFinding workspace profile game ("deployment:" + receipt.Id.ToString "N") "deployment-incomplete"
                  DiagnosticSeverity.Error "Deployment did not finish" "Mod Conductor can continue the restore" None
                  (profile.Name + " deployment") "Preview the remaining paths. Then continue the restore."
                  Fixability.PreviewAvailable "Mod Conductor can restore this"
                  [ correlation CorrelationKind.Deployment (receipt.Id.ToString "N") (Some receipt.Revision) ]
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
                  [ correlation CorrelationKind.Profile (profile.Id.ToString "N") (Some state.Revision)
                    correlation CorrelationKind.Action (action.ToString "N") None ]
                  (DiagnosticAction.ResumeProfileData action)
                  [ evidence "Workspace" workspace.Name; evidence "Profile" profile.Name ] ]
        | None, Some _ ->
            [ baseFinding workspace profile game "profile:problem" "profile-data-problem" DiagnosticSeverity.Warning
                  "Profile files need attention" "Mod Conductor cannot use the current profile files." None
                  profile.Name "Open Profiles. Check the profile files."
                  Fixability.NotFixable "You need to fix this" [] DiagnosticAction.None
                  [ evidence "Workspace" workspace.Name; evidence "Profile" profile.Name ] ]
        | _ -> []

    let operation (workspace: Workspace) (profile: Profile) game (value: Snapshot) =
        if value.Phase = Phase.Interrupted || value.Phase = Phase.Stale || value.Phase = Phase.Cancelled then
            [ baseFinding workspace profile game ("action:" + value.Request.Id) "action-incomplete" DiagnosticSeverity.Warning
                  "An action did not finish" "The saved action needs attention." None profile.Name
                  "Run Diagnostics again after you continue or cancel the action."
                  Fixability.NotFixable "Open the related tool"
                  [ correlation CorrelationKind.Action value.Request.Id (Some value.ResultRevision) ] DiagnosticAction.None
                  [ evidence "Workspace" workspace.Name; evidence "Profile" profile.Name; evidence "Progress" (string value.Progress + " of " + string value.Request.Count) ] ]
        else []
