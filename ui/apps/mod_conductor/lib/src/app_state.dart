part of 'app.dart';

abstract class _AppStateBase extends State<ModConductorApp> {
  final _requestShellKey = GlobalKey();
  final _modalSpaceWaiters = <Completer<void>>[];
  int? _presentedRequestId;
  bool _requestPresentationScheduled = false;
  bool _requestDialogOpen = false;
  DesktopRequests? _dialogRequests;
  ModalRoute<dynamic>? _requestDialogRoute;
  _Destination _destination = _Destination.workspaces;
  _PreferenceScope _preferenceScope = _PreferenceScope.application;
  final _applicationSettings = _SettingsFormState();
  final _workspaceSettings = _SettingsFormState();
  String? _settingsWorkspaceId;
  String? _settingsProfileId;
  final _workspacesFocus = FocusNode(debugLabel: 'Workspaces navigation');
  final _preferencesFocus = FocusNode(debugLabel: 'Preferences navigation');
  final _detailsFocus = FocusNode(debugLabel: 'Active preferences');
  final _quitFocus = FocusNode(debugLabel: 'Quit');
  final _workspaces = WorkspaceController();
  final _mods = ModLibraryController();
  final _game = GameContextController();
  final _files = FilePlansController();
  final _diagnostics = DiagnosticsController();
  final _plugins = PluginsController();
  final _sortOrder = SortOrderController();
  final _archives = ArchivePolicyController();
  final _outputs = OutputController();
  final _artifacts = ArtifactController();
  final _nexusDetails = ModNexusController();
  bool _discoverMods = false;
  NexusFileRequest? _nexusFileRequest;
  int _nexusFileRevision = 0;
  final _discoveryTrackedChanges = ValueNotifier<int>(0);
  final _discoveryLocalChanges = ValueNotifier<int>(0);
  final _deployments = DeploymentController();
  final _executables = ExecutablesController();
  final _play = GamePlayController();
  final _profileData = ProfileDataController();
  bool _skseLaunchCheckStarted = false;
  final _skseProfilesWithoutInstall = <String>{};
  SkyrimSetupClient? _setupEventClient;
  StreamSubscription<SkyrimSetupStatus>? _setupEvents;
  Timer? _setupReconnect;
  String? _setupEventWorkspace, _setupEventProfile;
  SkyrimSetupStatus? _observedSetup;
  int _setupEventEpoch = 0;
  final _detachedInstallations =
      <String, StreamSubscription<InstallationStatus>>{};
  final _installationRetries = <String, Timer>{};
  String? _installationWorkspace, _installationProfile;
  InstallationsClient? _installationClient;
  int _installationEpoch = 0;
  int? _selectionRevision, _catalogueRevision;
  int? _contextRevision;
  void _navigate(_Destination value, {bool focus = true}) {
    setState(() => _destination = value);
    if (value == _Destination.workspaces && _nexusDetails.viewing) {
      unawaited(_nexusDetails.readAccount());
    }
    if (focus) {
      (value == _Destination.workspaces ? _workspacesFocus : _preferencesFocus)
          .requestFocus();
    }
  }
}
