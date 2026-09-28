import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/settings.pbgrpc.dart' as wire;

enum AppearancePreference { system, light, dark }

enum ContrastPreference { system, standard, high }

class PresentationPreferences {
  const PresentationPreferences({
    required this.appearance,
    required this.textScale,
    this.interfaceScale = 1,
    required this.contrast,
  });

  final AppearancePreference appearance;
  final double textScale;
  final double interfaceScale;
  final ContrastPreference contrast;

  @override
  bool operator ==(Object other) =>
      other is PresentationPreferences &&
      appearance == other.appearance &&
      textScale == other.textScale &&
      interfaceScale == other.interfaceScale &&
      contrast == other.contrast;

  @override
  int get hashCode =>
      Object.hash(appearance, textScale, interfaceScale, contrast);
}

class SettingsSnapshot {
  const SettingsSnapshot({
    required this.presentation,
    required this.inheritsApplication,
    this.checkUpdatesOnStartup = true,
  });

  final PresentationPreferences presentation;
  final bool inheritsApplication;
  final bool checkUpdatesOnStartup;

  @override
  bool operator ==(Object other) =>
      other is SettingsSnapshot &&
      presentation == other.presentation &&
      inheritsApplication == other.inheritsApplication &&
      checkUpdatesOnStartup == other.checkUpdatesOnStartup;

  @override
  int get hashCode =>
      Object.hash(presentation, inheritsApplication, checkUpdatesOnStartup);
}

enum SettingsFault {
  invalidScope,
  invalidDocument,
  unsupportedVersion,
  invalidValue,
  unavailable,
  workspaceNotFound,
}

class SettingsException implements Exception {
  const SettingsException(this.fault, this.detail);
  final SettingsFault fault;
  final String detail;
}

abstract interface class SettingsClient {
  Future<SettingsSnapshot> readApplication();
  Future<SettingsSnapshot> readWorkspace(String workspaceId);
  Future<SettingsSnapshot> saveApplication(SettingsSnapshot settings);
  Future<SettingsSnapshot> saveWorkspace(
    String workspaceId,
    SettingsSnapshot settings,
  );
}

class GrpcSettingsClient implements SettingsClient {
  GrpcSettingsClient(ClientChannel channel, CallOptions options)
    : _wire = wire.SettingsOperationsClient(channel, options: options);

  final wire.SettingsOperationsClient _wire;

  wire.SettingsTarget _application() => wire.SettingsTarget(application: true);
  wire.SettingsTarget _workspace(String id) =>
      wire.SettingsTarget(workspaceId: id);

  @override
  Future<SettingsSnapshot> readApplication() async => _reply(
    await _wire.readSettings(wire.ReadSettingsRequest(target: _application())),
  );

  @override
  Future<SettingsSnapshot> readWorkspace(String workspaceId) async => _reply(
    await _wire.readSettings(
      wire.ReadSettingsRequest(target: _workspace(workspaceId)),
    ),
  );

  @override
  Future<SettingsSnapshot> saveApplication(SettingsSnapshot settings) async =>
      _reply(
        await _wire.saveSettings(
          wire.SaveSettingsRequest(
            target: _application(),
            settings: _encode(settings),
          ),
        ),
      );

  @override
  Future<SettingsSnapshot> saveWorkspace(
    String workspaceId,
    SettingsSnapshot settings,
  ) async => _reply(
    await _wire.saveSettings(
      wire.SaveSettingsRequest(
        target: _workspace(workspaceId),
        settings: _encode(settings),
      ),
    ),
  );
}

wire.SettingsSnapshot _encode(SettingsSnapshot value) => wire.SettingsSnapshot(
  presentation: wire.PresentationSettings(
    appearance: switch (value.presentation.appearance) {
      AppearancePreference.system =>
        wire.AppearancePreference.APPEARANCE_PREFERENCE_SYSTEM,
      AppearancePreference.light =>
        wire.AppearancePreference.APPEARANCE_PREFERENCE_LIGHT,
      AppearancePreference.dark =>
        wire.AppearancePreference.APPEARANCE_PREFERENCE_DARK,
    },
    textScale: value.presentation.textScale,
    interfaceScale: value.presentation.interfaceScale,
    contrast: switch (value.presentation.contrast) {
      ContrastPreference.system =>
        wire.ContrastPreference.CONTRAST_PREFERENCE_SYSTEM,
      ContrastPreference.standard =>
        wire.ContrastPreference.CONTRAST_PREFERENCE_STANDARD,
      ContrastPreference.high =>
        wire.ContrastPreference.CONTRAST_PREFERENCE_HIGH,
    },
  ),
  inheritsApplication: value.inheritsApplication,
  checkUpdatesOnStartup: value.checkUpdatesOnStartup,
);

SettingsSnapshot _decode(wire.SettingsSnapshot value) => SettingsSnapshot(
  presentation: PresentationPreferences(
    appearance: switch (value.presentation.appearance) {
      wire.AppearancePreference.APPEARANCE_PREFERENCE_SYSTEM =>
        AppearancePreference.system,
      wire.AppearancePreference.APPEARANCE_PREFERENCE_LIGHT =>
        AppearancePreference.light,
      wire.AppearancePreference.APPEARANCE_PREFERENCE_DARK =>
        AppearancePreference.dark,
      _ => throw const FormatException('Unsupported appearance preference.'),
    },
    textScale: value.presentation.textScale,
    interfaceScale: value.presentation.interfaceScale == 0
        ? 1
        : value.presentation.interfaceScale,
    contrast: switch (value.presentation.contrast) {
      wire.ContrastPreference.CONTRAST_PREFERENCE_SYSTEM =>
        ContrastPreference.system,
      wire.ContrastPreference.CONTRAST_PREFERENCE_STANDARD =>
        ContrastPreference.standard,
      wire.ContrastPreference.CONTRAST_PREFERENCE_HIGH =>
        ContrastPreference.high,
      _ => throw const FormatException('Unsupported contrast preference.'),
    },
  ),
  inheritsApplication: value.inheritsApplication,
  checkUpdatesOnStartup: value.hasCheckUpdatesOnStartup()
      ? value.checkUpdatesOnStartup
      : true,
);

SettingsSnapshot _reply(wire.SettingsReply reply) =>
    switch (reply.whichOutcome()) {
      wire.SettingsReply_Outcome.settings => _decode(reply.settings),
      wire.SettingsReply_Outcome.fault => throw SettingsException(
        switch (reply.fault.code) {
          wire.SettingsFaultCode.SETTINGS_FAULT_CODE_INVALID_SCOPE =>
            SettingsFault.invalidScope,
          wire.SettingsFaultCode.SETTINGS_FAULT_CODE_INVALID_DOCUMENT =>
            SettingsFault.invalidDocument,
          wire.SettingsFaultCode.SETTINGS_FAULT_CODE_UNSUPPORTED_VERSION =>
            SettingsFault.unsupportedVersion,
          wire.SettingsFaultCode.SETTINGS_FAULT_CODE_INVALID_VALUE =>
            SettingsFault.invalidValue,
          wire.SettingsFaultCode.SETTINGS_FAULT_CODE_UNAVAILABLE =>
            SettingsFault.unavailable,
          wire.SettingsFaultCode.SETTINGS_FAULT_CODE_WORKSPACE_NOT_FOUND =>
            SettingsFault.workspaceNotFound,
          _ => throw const FormatException('Unsupported settings failure.'),
        },
        reply.fault.detail,
      ),
      wire.SettingsReply_Outcome.notSet => throw const FormatException(
        'Missing settings result.',
      ),
    };
