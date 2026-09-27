namespace ModConductor.Engine

open System
open System.Threading
open ModConductor.Executables
open ModConductor.Fnis
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Protocol.V1
open ModConductor.Skse

type SkyrimSetupComponentView =
    { Id: string
      Name: string
      Status: string
      Detail: string
      UpdateVersion: string option
      Installed: bool
      Ready: bool
      Active: bool
      Blocked: bool }

type internal SkyrimSetupView =
    { Phase: SkyrimSetupPhase
      Status: string
      Detail: string
      Components: SkyrimSetupComponentView list
      Selection: ModConductor.Persistence.SetupSelection
      CanStart: bool
      CanContinue: bool
      Active: bool
      CanCancel: bool
      Ready: bool }

type internal SkyrimSetupDependencies =
    { PrepareSkse:
        Guid
            -> Guid
            -> SkseReleaseChoice option
            -> System.Threading.Tasks.Task<Result<unit, SkseProblem>>
      ReviewSkse: Guid -> Guid -> System.Threading.Tasks.Task<Result<SkseReview, SkseProblem>>
      ClearPreparedSkse: Guid -> Guid -> unit
      ReadSkse: Guid -> Guid -> System.Threading.Tasks.Task<SkseView>
      StartSkse: Guid -> Guid -> System.Threading.Tasks.Task<SkseView>
      RemoveSkse:
          Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<Result<SkseView, string>>
      CancelSkse: Guid -> Guid -> System.Threading.Tasks.Task<SkseView>
      ReadEnb: Guid -> Guid -> System.Threading.Tasks.Task<EnbView>
      RemoveEnb: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<EnbView>
      SelectEnb:
          Guid
              -> Guid
              -> Guid
              -> string
              -> CancellationToken
              -> System.Threading.Tasks.Task<EnbView>
      CancelEnb: Guid -> Guid -> System.Threading.Tasks.Task<EnbView>
      RecoverEnb: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<EnbView>
      ReadFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      InstallFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      UpdateFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      RemoveFnis: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<FnisView>
      CancelFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      RecoverFnis: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<FnisView>
      InspectFnis:
          Guid
              -> Guid
              -> CancellationToken
              -> System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>
      RunFnis:
          ModConductor.Fnis.FnisRunRequest
              -> CancellationToken
              -> System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>
      CancelFnisRun:
          Guid -> Guid -> System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>
      ReadLaunch:
          Guid
              -> Guid
              -> System.Threading.Tasks.Task<
                  Result<ModConductor.GameLaunching.GameLaunchState, ExecutableError>
               >
      PluginPreflight:
          Guid
              -> Guid
              -> CancellationToken
              -> System.Threading.Tasks.Task<Result<unit, ProfileDataError>> }

module internal SkyrimSetupDependencies =
    let production
        (skse: SkseCoordinator)
        (enb: EnbCoordinator)
        (fnis: FnisCoordinator)
        (execution: IFnisExecution)
        (launches: IGameLaunching)
        (pluginOrders: IProfilePluginOrders)
        =
        { PrepareSkse = fun workspace profile choice -> skse.Prepare(workspace, profile, choice)
          ReviewSkse = fun workspace profile -> skse.Review(workspace, profile)
          ClearPreparedSkse = fun workspace profile -> skse.ClearPrepared(workspace, profile)
          ReadSkse = fun workspace profile -> skse.Read(workspace, profile)
          StartSkse = fun workspace profile -> skse.StartPrepared(workspace, profile)
          RemoveSkse = fun workspace profile token -> skse.Remove(workspace, profile, token)
          CancelSkse = fun workspace profile -> skse.Cancel(workspace, profile)
          ReadEnb = fun workspace profile -> enb.Read(workspace, profile)
          RemoveEnb =
            fun workspace profile token -> enb.Remove(workspace, profile, token, runtimeOnly = true)
          SelectEnb =
            fun workspace profile operation path token ->
                enb.SelectRuntimeArchive(workspace, profile, operation, path, token)
          CancelEnb = fun workspace profile -> enb.Cancel(workspace, profile)
          RecoverEnb = fun workspace profile token -> enb.Recover(workspace, profile, token)
          ReadFnis = fun workspace profile -> fnis.Read(workspace, profile)
          InstallFnis = fun workspace profile -> fnis.Install(workspace, profile)
          UpdateFnis = fun workspace profile -> fnis.Update(workspace, profile)
          RemoveFnis = fun workspace profile token -> fnis.Remove(workspace, profile, token)
          CancelFnis = fun workspace profile -> fnis.Cancel(workspace, profile)
          RecoverFnis = fun workspace profile token -> fnis.Recover(workspace, profile, token)
          InspectFnis = fun workspace profile token -> execution.Inspect(workspace, profile, token)
          RunFnis = fun request token -> execution.Run(request, token)
          CancelFnisRun = fun workspace profile -> execution.Cancel(workspace, profile)
          ReadLaunch = fun workspace profile -> launches.Read(workspace, profile)
          PluginPreflight =
            fun workspace profile token ->
                pluginOrders.PreflightForLaunch(workspace, profile, token) }
