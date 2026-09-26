part of 'app.dart';

enum _PreferenceScope { application, workspace }

typedef _Preferences = ({
  AppearancePreference appearance,
  double textScale,
  double interfaceScale,
  ContrastPreference contrast,
});

class _PreferenceTextScaler extends TextScaler {
  const _PreferenceTextScaler(this.platform, this.multiplier);

  final TextScaler platform;
  final double multiplier;

  @override
  double scale(double fontSize) => platform.scale(fontSize) * multiplier;

  @override
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) =>
      other is _PreferenceTextScaler &&
      other.platform == platform &&
      other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(platform, multiplier);
}

const _defaultPreferences = (
  appearance: AppearancePreference.system,
  textScale: 1.0,
  interfaceScale: 1.0,
  contrast: ContrastPreference.system,
);

class _SettingsFormState {
  _Preferences applied = _defaultPreferences;
  _Preferences draft = _defaultPreferences;
  bool inheritsApplied = true;
  bool inheritsDraft = true;
  bool hasConfirmed = false;
  bool loaded = false;
  bool loading = false;
  bool saving = false;
  String? problem;
  String? diagnostic;
  DateTime? savedAt;
  int generation = 0;

  void reset() {
    generation++;
    applied = draft = _defaultPreferences;
    inheritsApplied = inheritsDraft = true;
    hasConfirmed = loaded = loading = saving = false;
    problem = diagnostic = null;
    savedAt = null;
  }

  void accept(SettingsSnapshot snapshot) {
    applied = draft = _preferences(snapshot);
    inheritsApplied = inheritsDraft = snapshot.inheritsApplication;
    hasConfirmed = true;
    loaded = true;
    loading = saving = false;
    problem = diagnostic = null;
  }

  void cancel() {
    draft = applied;
    inheritsDraft = inheritsApplied;
    problem = null;
  }
}

ThemeMode _themeMode(AppearancePreference value) => switch (value) {
  AppearancePreference.system => ThemeMode.system,
  AppearancePreference.light => ThemeMode.light,
  AppearancePreference.dark => ThemeMode.dark,
};

_Preferences _preferences(SettingsSnapshot value) => (
  appearance: value.presentation.appearance,
  textScale: value.presentation.textScale,
  interfaceScale: value.presentation.interfaceScale,
  contrast: value.presentation.contrast,
);

SettingsSnapshot _snapshot(_Preferences value, {required bool inherits}) =>
    SettingsSnapshot(
      presentation: PresentationPreferences(
        appearance: value.appearance,
        textScale: value.textScale,
        interfaceScale: value.interfaceScale,
        contrast: value.contrast,
      ),
      inheritsApplication: inherits,
    );

mixin _SettingsScope on _AppStateBase {
  _Preferences get _effectivePreferences =>
      _settingsWorkspaceId != null &&
          _workspaceSettings.hasConfirmed &&
          !_workspaceSettings.inheritsApplied
      ? _workspaceSettings.applied
      : _applicationSettings.applied;

  _SettingsFormState get _selectedSettings =>
      _preferenceScope == _PreferenceScope.application
      ? _applicationSettings
      : _workspaceSettings;
  bool get _selectedSettingsLoaded =>
      _selectedSettings.loaded &&
      (_preferenceScope == _PreferenceScope.application ||
          !_workspaceSettings.inheritsDraft ||
          _applicationSettings.loaded);

  bool get _selectedSettingsLoading =>
      _selectedSettings.loading ||
      (_preferenceScope == _PreferenceScope.workspace &&
          _workspaceSettings.inheritsDraft &&
          _applicationSettings.loading);

  String? get _selectedSettingsProblem =>
      _selectedSettings.problem ??
      (_preferenceScope == _PreferenceScope.workspace &&
              _workspaceSettings.inheritsDraft &&
              !_applicationSettings.loaded
          ? _applicationSettings.problem
          : null);

  _Preferences get _selectedApplied =>
      _preferenceScope == _PreferenceScope.application
      ? _applicationSettings.applied
      : _workspaceSettings.inheritsApplied
      ? _applicationSettings.applied
      : _workspaceSettings.applied;

  _Preferences get _selectedDraft =>
      _preferenceScope == _PreferenceScope.application
      ? _applicationSettings.draft
      : _workspaceSettings.inheritsDraft
      ? _applicationSettings.applied
      : _workspaceSettings.draft;

  bool get _selectedInherits =>
      _preferenceScope == _PreferenceScope.workspace &&
      _workspaceSettings.inheritsDraft;

  String _settingsDiagnostic(Object error) => error is SettingsException
      ? '${error.fault.name}: ${error.detail}'
      : '${error.runtimeType}: $error';

  String? get _settingsHelpDiagnostic {
    final failures = <String>[
      if (_applicationSettings.problem != null &&
          _applicationSettings.diagnostic != null)
        'Application: ${_applicationSettings.diagnostic}',
      if (_workspaceSettings.problem != null &&
          _workspaceSettings.diagnostic != null &&
          _settingsWorkspaceId != null)
        'Workspace: ${_workspaceSettings.diagnostic}',
    ];
    return failures.isEmpty ? null : failures.join('\n');
  }

  Future<void> _loadSettings(
    _PreferenceScope scope, {
    String? workspaceId,
  }) async {
    final form = scope == _PreferenceScope.application
        ? _applicationSettings
        : _workspaceSettings;
    final client = widget.settings;
    final generation = ++form.generation;
    setState(() {
      form.loaded = false;
      form.loading = client != null;
      form.saving = false;
      form.problem = client == null ? 'load' : null;
      form.diagnostic = client == null
          ? 'Engine connection unavailable.'
          : null;
      form.savedAt = null;
    });
    if (client == null) return;
    bool current() =>
        mounted &&
        generation == form.generation &&
        client == widget.settings &&
        (scope == _PreferenceScope.application ||
            workspaceId == _settingsWorkspaceId);
    try {
      final loaded = scope == _PreferenceScope.application
          ? await client.readApplication()
          : await client.readWorkspace(workspaceId!);
      if (!current()) return;
      setState(() => form.accept(loaded));
    } on Exception catch (error) {
      if (!current()) return;
      setState(() {
        form.loading = false;
        form.problem = 'load';
        form.diagnostic = _settingsDiagnostic(error);
      });
    }
  }

  Future<void> _loadApplicationSettings() =>
      _loadSettings(_PreferenceScope.application);

  Future<void> _loadWorkspaceSettings(
    String? workspaceId, {
    bool force = false,
  }) async {
    if (_settingsWorkspaceId == workspaceId && !force) return;
    if (_settingsWorkspaceId != workspaceId) {
      _settingsWorkspaceId = workspaceId;
      _workspaceSettings.reset();
    }
    if (workspaceId == null) {
      if (mounted) {
        setState(() {
          if (_preferenceScope == _PreferenceScope.workspace) {
            _preferenceScope = _PreferenceScope.application;
          }
        });
      }
      return;
    }
    await _loadSettings(_PreferenceScope.workspace, workspaceId: workspaceId);
  }

  void _selectPreferenceScope(_PreferenceScope value) {
    if (value == _preferenceScope) return;
    setState(() {
      for (final form in [_applicationSettings, _workspaceSettings]) {
        form.generation++;
        if (form.loading || form.saving) form.loaded = false;
        form.loading = form.saving = false;
      }
      _selectedSettings.cancel();
      _preferenceScope = value;
      _selectedSettings.cancel();
    });
    if (!_applicationSettings.loaded) {
      unawaited(_loadApplicationSettings());
    }
    if (value == _PreferenceScope.workspace && !_workspaceSettings.loaded) {
      unawaited(_loadWorkspaceSettings(_settingsWorkspaceId, force: true));
    }
  }

  void _changePreferenceDraft(_Preferences value) => setState(() {
    _selectedSettings.draft = value;
    _selectedSettings.savedAt = null;
  });

  Future<void> _retrySettings() {
    if (widget.settings == null) {
      widget.onRetry?.call();
      return Future.value();
    }
    return _preferenceScope == _PreferenceScope.application ||
            (_preferenceScope == _PreferenceScope.workspace &&
                _workspaceSettings.loaded &&
                _workspaceSettings.inheritsDraft &&
                !_applicationSettings.loaded)
        ? _loadApplicationSettings()
        : _loadWorkspaceSettings(_settingsWorkspaceId, force: true);
  }

  Future<bool> _persistPreferences(
    _PreferenceScope scope,
    _Preferences value, {
    required bool inherits,
    bool allowUnselectedScope = false,
  }) async {
    final client = widget.settings;
    final workspaceId = scope == _PreferenceScope.workspace
        ? _settingsWorkspaceId
        : null;
    final form = scope == _PreferenceScope.application
        ? _applicationSettings
        : _workspaceSettings;
    if (client == null ||
        !form.loaded ||
        form.saving ||
        (scope == _PreferenceScope.workspace && workspaceId == null)) {
      return false;
    }
    final generation = ++form.generation;
    setState(() {
      form.saving = true;
      form.problem = null;
      form.savedAt = null;
    });
    bool current() =>
        mounted &&
        generation == form.generation &&
        (allowUnselectedScope || scope == _preferenceScope) &&
        workspaceId ==
            (scope == _PreferenceScope.workspace
                ? _settingsWorkspaceId
                : null) &&
        client == widget.settings;
    try {
      final saved = scope == _PreferenceScope.application
          ? await client.saveApplication(_snapshot(value, inherits: false))
          : await client.saveWorkspace(
              workspaceId!,
              _snapshot(value, inherits: inherits),
            );
      if (!current()) return false;
      setState(() {
        form.accept(saved);
        form.savedAt = DateTime.now();
      });
      return true;
    } on Exception catch (error) {
      if (current()) {
        setState(() {
          form.saving = false;
          form.problem = 'save';
          form.diagnostic = _settingsDiagnostic(error);
        });
      }
      return false;
    }
  }

  Future<void> _savePreferences() async {
    await _persistPreferences(
      _preferenceScope,
      _selectedDraft,
      inherits: _selectedInherits,
    );
  }

  void _cancelPreferences() => setState(() => _selectedSettings.cancel());

  Future<void> _quickTheme(AppearancePreference value) async {
    final scope =
        _settingsWorkspaceId != null &&
            _workspaceSettings.loaded &&
            !_workspaceSettings.inheritsApplied
        ? _PreferenceScope.workspace
        : _PreferenceScope.application;
    final form = scope == _PreferenceScope.application
        ? _applicationSettings
        : _workspaceSettings;
    if (!form.loaded) return;
    final current = form.applied;
    await _persistPreferences(
      scope,
      (
        appearance: value,
        textScale: current.textScale,
        interfaceScale: current.interfaceScale,
        contrast: current.contrast,
      ),
      inherits: false,
      allowUnselectedScope: true,
    );
  }
}
