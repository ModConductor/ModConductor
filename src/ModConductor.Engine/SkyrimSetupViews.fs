namespace ModConductor.Engine

open System
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Protocol.V1

module internal SkyrimSetupViews =
    let firstRunInstruction =
        "Start Skyrim once through Steam. Close it, then select Refresh."

    let componentView (name: string) status detail ready active blocked =
        { Id = name.ToLowerInvariant()
          Name = name
          Status = status
          Detail = detail
          UpdateVersion = None
          Installed = ready
          Ready = ready
          Active = active
          Blocked = blocked }

    let evaluateSkse selection stage (state: SkseView) installed =
        let ready = state.Phase = SksePhase.Ready

        let doneSetup =
            match selection with
            | SetupAction.Unchanged -> true
            | SetupAction.Install -> ready
            | SetupAction.Update -> stage <> "skse-start" && ready
            | SetupAction.Remove -> not installed
            | _ -> false

        let active =
            state.Phase = SksePhase.Downloading || state.Phase = SksePhase.Installing

        let blocked =
            state.Phase = SksePhase.Failed
            || state.Phase = SksePhase.Incompatible
            || state.Phase = SksePhase.SourceUnavailable
            || state.Phase = SksePhase.Unavailable

        let item =
            { componentView "SKSE" state.Status state.Detail ready active blocked with
                Id = "skse"
                Installed = installed }

        doneSetup, active, blocked, item

    let evaluateEnb selection stage (state: EnbView) installed =
        let ready = state.Phase = EnbPhase.Ready

        let doneSetup =
            match selection with
            | SetupAction.Unchanged -> true
            | SetupAction.Install -> ready
            | SetupAction.Update -> stage <> "enb-start" && ready
            | SetupAction.Remove -> not installed
            | _ -> false

        let active =
            state.Phase = EnbPhase.Validating
            || state.Phase = EnbPhase.Acquiring
            || state.Phase = EnbPhase.Installing

        let blocked =
            state.Phase = EnbPhase.Blocked
            || state.Phase = EnbPhase.Failed
            || state.Phase = EnbPhase.Conflict
            || state.Phase = EnbPhase.Unavailable

        let item =
            { componentView "ENBSeries" state.Status state.Detail ready active blocked with
                Id = "enb"
                Installed = installed }

        doneSetup, active, blocked, item

    let evaluateFnis
        selection
        stage
        actionId
        installed
        (state: FnisView option)
        (output: FnisInspection option)
        =
        let ready =
            if selection = SetupAction.Unchanged then
                true
            elif selection = SetupAction.Remove then
                not installed
            elif selection = SetupAction.Update && stage = "fnis-start" then
                false
            else
                match state, output with
                | Some state, Some output ->
                    state.Phase = FnisPhase.Ready
                    && output.Phase = ModConductor.Fnis.FnisOutputPhase.Current
                    && (stage <> "fnis-run"
                        || (actionId
                            |> Option.exists (fun action -> output.LatestRunId = Some action)))
                | _ -> false

        let active =
            match state, output with
            | Some state, _ when
                state.Phase = FnisPhase.WaitingForNexus
                || state.Phase = FnisPhase.Downloading
                || state.Phase = FnisPhase.Installing
                ->
                true
            | _, Some output when output.Phase = ModConductor.Fnis.FnisOutputPhase.Running -> true
            | _ -> false

        let blocked =
            match state with
            | Some state ->
                state.Phase = FnisPhase.Failed
                || state.Phase = FnisPhase.RecoveryRequired
                || state.Phase = FnisPhase.SourceUnavailable
                || state.Phase = FnisPhase.Unavailable
                || (output
                    |> Option.exists (fun value ->
                        value.Phase = ModConductor.Fnis.FnisOutputPhase.Failed
                        || value.Phase = ModConductor.Fnis.FnisOutputPhase.Cancelled
                        || value.Phase = ModConductor.Fnis.FnisOutputPhase.Abandoned))
            | None -> false

        let item =
            state
            |> Option.map (fun state ->
                let status, detail =
                    match output with
                    | Some output -> output.Status, output.Detail
                    | None -> state.Status, state.Detail

                { componentView "FNIS" status detail ready active blocked with
                    Id = "fnis"
                    Installed = installed })

        ready, active, blocked, item

    let view phase status detail components selection running start continueSetup active ready =
        { Phase = phase
          Status = status
          Detail = detail
          Components = components
          Selection = selection
          CanStart = start
          CanContinue = continueSetup
          Active = active
          CanCancel = running && not ready
          Ready = ready }

    let fnisExitWarning (output: FnisInspection option) =
        match output with
        | Some value when
            value.Phase = ModConductor.Fnis.FnisOutputPhase.Current
            && (value.ExitCode |> Option.exists ((<>) 0))
            ->
            Some(value.Status, value.Detail)
        | _ -> None

    let unavailable selection status detail =
        view
            SkyrimSetupPhase.Unavailable
            status
            detail
            [ componentView "Skyrim installation" status detail false false true ]
            selection
            false
            false
            false
            false
            false

    let missingFirstRun (binding: GameBinding) =
        let explicitlyMissing =
            binding.NeedsCheck
            && binding.Failure
               |> Option.exists (fun detail ->
                   detail.Contains("first run", StringComparison.OrdinalIgnoreCase))

        match binding.Evidence.Platform with
        | ContextPlatform.Windows -> explicitlyMissing
        | ContextPlatform.Proton ->
            explicitlyMissing
            || (binding.NeedsCheck
                && binding.Failure
                   |> Option.exists (fun detail ->
                       detail.Contains("prefix", StringComparison.OrdinalIgnoreCase)
                       || detail.Contains("Proton data", StringComparison.OrdinalIgnoreCase)
                       || detail.Contains("user folder", StringComparison.OrdinalIgnoreCase)))
