// This is a generated file - do not edit.
//
// Generated from modconductor/v1/settings.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'settings.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'settings.pbenum.dart';

enum SettingsTarget_Target { application, workspaceId, notSet }

class SettingsTarget extends $pb.GeneratedMessage {
  factory SettingsTarget({
    $core.bool? application,
    $core.String? workspaceId,
  }) {
    final result = create();
    if (application != null) result.application = application;
    if (workspaceId != null) result.workspaceId = workspaceId;
    return result;
  }

  SettingsTarget._();

  factory SettingsTarget.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SettingsTarget.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SettingsTarget_Target>
      _SettingsTarget_TargetByTag = {
    1: SettingsTarget_Target.application,
    2: SettingsTarget_Target.workspaceId,
    0: SettingsTarget_Target.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SettingsTarget',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'application')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SettingsTarget clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SettingsTarget copyWith(void Function(SettingsTarget) updates) =>
      super.copyWith((message) => updates(message as SettingsTarget))
          as SettingsTarget;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SettingsTarget create() => SettingsTarget._();
  @$core.override
  SettingsTarget createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SettingsTarget getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SettingsTarget>(create);
  static SettingsTarget? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  SettingsTarget_Target whichTarget() =>
      _SettingsTarget_TargetByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearTarget() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.bool get application => $_getBF(0);
  @$pb.TagNumber(1)
  set application($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasApplication() => $_has(0);
  @$pb.TagNumber(1)
  void clearApplication() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => $_clearField(2);
}

class PresentationSettings extends $pb.GeneratedMessage {
  factory PresentationSettings({
    AppearancePreference? appearance,
    $core.double? textScale,
    ContrastPreference? contrast,
    $core.double? interfaceScale,
  }) {
    final result = create();
    if (appearance != null) result.appearance = appearance;
    if (textScale != null) result.textScale = textScale;
    if (contrast != null) result.contrast = contrast;
    if (interfaceScale != null) result.interfaceScale = interfaceScale;
    return result;
  }

  PresentationSettings._();

  factory PresentationSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PresentationSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PresentationSettings',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<AppearancePreference>(1, _omitFieldNames ? '' : 'appearance',
        enumValues: AppearancePreference.values)
    ..aD(2, _omitFieldNames ? '' : 'textScale')
    ..aE<ContrastPreference>(3, _omitFieldNames ? '' : 'contrast',
        enumValues: ContrastPreference.values)
    ..aD(4, _omitFieldNames ? '' : 'interfaceScale')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresentationSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresentationSettings copyWith(void Function(PresentationSettings) updates) =>
      super.copyWith((message) => updates(message as PresentationSettings))
          as PresentationSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PresentationSettings create() => PresentationSettings._();
  @$core.override
  PresentationSettings createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PresentationSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PresentationSettings>(create);
  static PresentationSettings? _defaultInstance;

  @$pb.TagNumber(1)
  AppearancePreference get appearance => $_getN(0);
  @$pb.TagNumber(1)
  set appearance(AppearancePreference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAppearance() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppearance() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get textScale => $_getN(1);
  @$pb.TagNumber(2)
  set textScale($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTextScale() => $_has(1);
  @$pb.TagNumber(2)
  void clearTextScale() => $_clearField(2);

  @$pb.TagNumber(3)
  ContrastPreference get contrast => $_getN(2);
  @$pb.TagNumber(3)
  set contrast(ContrastPreference value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasContrast() => $_has(2);
  @$pb.TagNumber(3)
  void clearContrast() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get interfaceScale => $_getN(3);
  @$pb.TagNumber(4)
  set interfaceScale($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInterfaceScale() => $_has(3);
  @$pb.TagNumber(4)
  void clearInterfaceScale() => $_clearField(4);
}

class SettingsSnapshot extends $pb.GeneratedMessage {
  factory SettingsSnapshot({
    PresentationSettings? presentation,
    $core.bool? inheritsApplication,
    $core.bool? checkUpdatesOnStartup,
  }) {
    final result = create();
    if (presentation != null) result.presentation = presentation;
    if (inheritsApplication != null)
      result.inheritsApplication = inheritsApplication;
    if (checkUpdatesOnStartup != null)
      result.checkUpdatesOnStartup = checkUpdatesOnStartup;
    return result;
  }

  SettingsSnapshot._();

  factory SettingsSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SettingsSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SettingsSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<PresentationSettings>(1, _omitFieldNames ? '' : 'presentation',
        subBuilder: PresentationSettings.create)
    ..aOB(2, _omitFieldNames ? '' : 'inheritsApplication')
    ..aOB(3, _omitFieldNames ? '' : 'checkUpdatesOnStartup')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SettingsSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SettingsSnapshot copyWith(void Function(SettingsSnapshot) updates) =>
      super.copyWith((message) => updates(message as SettingsSnapshot))
          as SettingsSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SettingsSnapshot create() => SettingsSnapshot._();
  @$core.override
  SettingsSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SettingsSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SettingsSnapshot>(create);
  static SettingsSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  PresentationSettings get presentation => $_getN(0);
  @$pb.TagNumber(1)
  set presentation(PresentationSettings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPresentation() => $_has(0);
  @$pb.TagNumber(1)
  void clearPresentation() => $_clearField(1);
  @$pb.TagNumber(1)
  PresentationSettings ensurePresentation() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get inheritsApplication => $_getBF(1);
  @$pb.TagNumber(2)
  set inheritsApplication($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInheritsApplication() => $_has(1);
  @$pb.TagNumber(2)
  void clearInheritsApplication() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get checkUpdatesOnStartup => $_getBF(2);
  @$pb.TagNumber(3)
  set checkUpdatesOnStartup($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCheckUpdatesOnStartup() => $_has(2);
  @$pb.TagNumber(3)
  void clearCheckUpdatesOnStartup() => $_clearField(3);
}

class SettingsFault extends $pb.GeneratedMessage {
  factory SettingsFault({
    SettingsFaultCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  SettingsFault._();

  factory SettingsFault.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SettingsFault.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SettingsFault',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<SettingsFaultCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: SettingsFaultCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SettingsFault clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SettingsFault copyWith(void Function(SettingsFault) updates) =>
      super.copyWith((message) => updates(message as SettingsFault))
          as SettingsFault;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SettingsFault create() => SettingsFault._();
  @$core.override
  SettingsFault createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SettingsFault getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SettingsFault>(create);
  static SettingsFault? _defaultInstance;

  @$pb.TagNumber(1)
  SettingsFaultCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(SettingsFaultCode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get detail => $_getSZ(1);
  @$pb.TagNumber(2)
  set detail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDetail() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetail() => $_clearField(2);
}

class ReadSettingsRequest extends $pb.GeneratedMessage {
  factory ReadSettingsRequest({
    SettingsTarget? target,
  }) {
    final result = create();
    if (target != null) result.target = target;
    return result;
  }

  ReadSettingsRequest._();

  factory ReadSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadSettingsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<SettingsTarget>(1, _omitFieldNames ? '' : 'target',
        subBuilder: SettingsTarget.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadSettingsRequest copyWith(void Function(ReadSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as ReadSettingsRequest))
          as ReadSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadSettingsRequest create() => ReadSettingsRequest._();
  @$core.override
  ReadSettingsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadSettingsRequest>(create);
  static ReadSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SettingsTarget get target => $_getN(0);
  @$pb.TagNumber(1)
  set target(SettingsTarget value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);
  @$pb.TagNumber(1)
  SettingsTarget ensureTarget() => $_ensure(0);
}

class SaveSettingsRequest extends $pb.GeneratedMessage {
  factory SaveSettingsRequest({
    SettingsTarget? target,
    SettingsSnapshot? settings,
  }) {
    final result = create();
    if (target != null) result.target = target;
    if (settings != null) result.settings = settings;
    return result;
  }

  SaveSettingsRequest._();

  factory SaveSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveSettingsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<SettingsTarget>(1, _omitFieldNames ? '' : 'target',
        subBuilder: SettingsTarget.create)
    ..aOM<SettingsSnapshot>(2, _omitFieldNames ? '' : 'settings',
        subBuilder: SettingsSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveSettingsRequest copyWith(void Function(SaveSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as SaveSettingsRequest))
          as SaveSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveSettingsRequest create() => SaveSettingsRequest._();
  @$core.override
  SaveSettingsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveSettingsRequest>(create);
  static SaveSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SettingsTarget get target => $_getN(0);
  @$pb.TagNumber(1)
  set target(SettingsTarget value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);
  @$pb.TagNumber(1)
  SettingsTarget ensureTarget() => $_ensure(0);

  @$pb.TagNumber(2)
  SettingsSnapshot get settings => $_getN(1);
  @$pb.TagNumber(2)
  set settings(SettingsSnapshot value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSettings() => $_has(1);
  @$pb.TagNumber(2)
  void clearSettings() => $_clearField(2);
  @$pb.TagNumber(2)
  SettingsSnapshot ensureSettings() => $_ensure(1);
}

enum SettingsReply_Outcome { settings, fault, notSet }

class SettingsReply extends $pb.GeneratedMessage {
  factory SettingsReply({
    SettingsSnapshot? settings,
    SettingsFault? fault,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    if (fault != null) result.fault = fault;
    return result;
  }

  SettingsReply._();

  factory SettingsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SettingsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SettingsReply_Outcome>
      _SettingsReply_OutcomeByTag = {
    1: SettingsReply_Outcome.settings,
    2: SettingsReply_Outcome.fault,
    0: SettingsReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SettingsReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<SettingsSnapshot>(1, _omitFieldNames ? '' : 'settings',
        subBuilder: SettingsSnapshot.create)
    ..aOM<SettingsFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: SettingsFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SettingsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SettingsReply copyWith(void Function(SettingsReply) updates) =>
      super.copyWith((message) => updates(message as SettingsReply))
          as SettingsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SettingsReply create() => SettingsReply._();
  @$core.override
  SettingsReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SettingsReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SettingsReply>(create);
  static SettingsReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  SettingsReply_Outcome whichOutcome() =>
      _SettingsReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SettingsSnapshot get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(SettingsSnapshot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  SettingsSnapshot ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  SettingsFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(SettingsFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  SettingsFault ensureFault() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
