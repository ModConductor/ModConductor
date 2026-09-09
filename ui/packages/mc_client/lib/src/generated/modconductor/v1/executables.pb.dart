// This is a generated file - do not edit.
//
// Generated from modconductor/v1/executables.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'executables.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'executables.pbenum.dart';

class ExecutableEnvironmentSetting extends $pb.GeneratedMessage {
  factory ExecutableEnvironmentSetting({
    $core.String? name,
    $core.String? value,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (value != null) result.value = value;
    return result;
  }

  ExecutableEnvironmentSetting._();

  factory ExecutableEnvironmentSetting.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutableEnvironmentSetting.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutableEnvironmentSetting',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableEnvironmentSetting clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableEnvironmentSetting copyWith(
          void Function(ExecutableEnvironmentSetting) updates) =>
      super.copyWith(
              (message) => updates(message as ExecutableEnvironmentSetting))
          as ExecutableEnvironmentSetting;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutableEnvironmentSetting create() =>
      ExecutableEnvironmentSetting._();
  @$core.override
  ExecutableEnvironmentSetting createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutableEnvironmentSetting getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutableEnvironmentSetting>(create);
  static ExecutableEnvironmentSetting? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

class ExecutablePreset extends $pb.GeneratedMessage {
  factory ExecutablePreset({
    $core.String? id,
    $core.String? workspaceId,
    $fixnum.Int64? revision,
    $core.String? name,
    $core.String? executable,
    $core.String? workingDirectory,
    $core.Iterable<$core.String>? arguments,
    $core.Iterable<ExecutableEnvironmentSetting>? environment,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (revision != null) result.revision = revision;
    if (name != null) result.name = name;
    if (executable != null) result.executable = executable;
    if (workingDirectory != null) result.workingDirectory = workingDirectory;
    if (arguments != null) result.arguments.addAll(arguments);
    if (environment != null) result.environment.addAll(environment);
    return result;
  }

  ExecutablePreset._();

  factory ExecutablePreset.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutablePreset.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutablePreset',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'executable')
    ..aOS(6, _omitFieldNames ? '' : 'workingDirectory')
    ..pPS(7, _omitFieldNames ? '' : 'arguments')
    ..pPM<ExecutableEnvironmentSetting>(8, _omitFieldNames ? '' : 'environment',
        subBuilder: ExecutableEnvironmentSetting.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutablePreset clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutablePreset copyWith(void Function(ExecutablePreset) updates) =>
      super.copyWith((message) => updates(message as ExecutablePreset))
          as ExecutablePreset;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutablePreset create() => ExecutablePreset._();
  @$core.override
  ExecutablePreset createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutablePreset getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutablePreset>(create);
  static ExecutablePreset? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get revision => $_getI64(2);
  @$pb.TagNumber(3)
  set revision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get executable => $_getSZ(4);
  @$pb.TagNumber(5)
  set executable($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExecutable() => $_has(4);
  @$pb.TagNumber(5)
  void clearExecutable() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get workingDirectory => $_getSZ(5);
  @$pb.TagNumber(6)
  set workingDirectory($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWorkingDirectory() => $_has(5);
  @$pb.TagNumber(6)
  void clearWorkingDirectory() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get arguments => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<ExecutableEnvironmentSetting> get environment => $_getList(7);
}

class ExecutablePageRequest extends $pb.GeneratedMessage {
  factory ExecutablePageRequest({
    $core.String? workspaceId,
    $core.String? afterId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (afterId != null) result.afterId = afterId;
    return result;
  }

  ExecutablePageRequest._();

  factory ExecutablePageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutablePageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutablePageRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'afterId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutablePageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutablePageRequest copyWith(
          void Function(ExecutablePageRequest) updates) =>
      super.copyWith((message) => updates(message as ExecutablePageRequest))
          as ExecutablePageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutablePageRequest create() => ExecutablePageRequest._();
  @$core.override
  ExecutablePageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutablePageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutablePageRequest>(create);
  static ExecutablePageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get afterId => $_getSZ(1);
  @$pb.TagNumber(2)
  set afterId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAfterId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAfterId() => $_clearField(2);
}

class ExecutablePresetRef extends $pb.GeneratedMessage {
  factory ExecutablePresetRef({
    $core.String? workspaceId,
    $core.String? id,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    return result;
  }

  ExecutablePresetRef._();

  factory ExecutablePresetRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutablePresetRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutablePresetRef',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutablePresetRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutablePresetRef copyWith(void Function(ExecutablePresetRef) updates) =>
      super.copyWith((message) => updates(message as ExecutablePresetRef))
          as ExecutablePresetRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutablePresetRef create() => ExecutablePresetRef._();
  @$core.override
  ExecutablePresetRef createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutablePresetRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutablePresetRef>(create);
  static ExecutablePresetRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);
}

class DeleteExecutablePresetRequest extends $pb.GeneratedMessage {
  factory DeleteExecutablePresetRequest({
    $core.String? workspaceId,
    $core.String? id,
    $fixnum.Int64? expectedRevision,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    return result;
  }

  DeleteExecutablePresetRequest._();

  factory DeleteExecutablePresetRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteExecutablePresetRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteExecutablePresetRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteExecutablePresetRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteExecutablePresetRequest copyWith(
          void Function(DeleteExecutablePresetRequest) updates) =>
      super.copyWith(
              (message) => updates(message as DeleteExecutablePresetRequest))
          as DeleteExecutablePresetRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteExecutablePresetRequest create() =>
      DeleteExecutablePresetRequest._();
  @$core.override
  DeleteExecutablePresetRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteExecutablePresetRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteExecutablePresetRequest>(create);
  static DeleteExecutablePresetRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get expectedRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpectedRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpectedRevision() => $_clearField(3);
}

class ExecutableRunRequest extends $pb.GeneratedMessage {
  factory ExecutableRunRequest({
    $core.String? id,
    $core.String? workspaceId,
    $fixnum.Int64? workspaceRevision,
    $core.String? presetId,
    $fixnum.Int64? presetRevision,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (workspaceRevision != null) result.workspaceRevision = workspaceRevision;
    if (presetId != null) result.presetId = presetId;
    if (presetRevision != null) result.presetRevision = presetRevision;
    return result;
  }

  ExecutableRunRequest._();

  factory ExecutableRunRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutableRunRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutableRunRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'workspaceRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'presetId')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'presetRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableRunRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableRunRequest copyWith(void Function(ExecutableRunRequest) updates) =>
      super.copyWith((message) => updates(message as ExecutableRunRequest))
          as ExecutableRunRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutableRunRequest create() => ExecutableRunRequest._();
  @$core.override
  ExecutableRunRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutableRunRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutableRunRequest>(create);
  static ExecutableRunRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get workspaceRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set workspaceRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWorkspaceRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearWorkspaceRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get presetId => $_getSZ(3);
  @$pb.TagNumber(4)
  set presetId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPresetId() => $_has(3);
  @$pb.TagNumber(4)
  void clearPresetId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get presetRevision => $_getI64(4);
  @$pb.TagNumber(5)
  set presetRevision($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPresetRevision() => $_has(4);
  @$pb.TagNumber(5)
  void clearPresetRevision() => $_clearField(5);
}

class ExecutableRunRef extends $pb.GeneratedMessage {
  factory ExecutableRunRef({
    $core.String? workspaceId,
    $core.String? id,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    return result;
  }

  ExecutableRunRef._();

  factory ExecutableRunRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutableRunRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutableRunRef',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableRunRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableRunRef copyWith(void Function(ExecutableRunRef) updates) =>
      super.copyWith((message) => updates(message as ExecutableRunRef))
          as ExecutableRunRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutableRunRef create() => ExecutableRunRef._();
  @$core.override
  ExecutableRunRef createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutableRunRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutableRunRef>(create);
  static ExecutableRunRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);
}

class ExecutableRun extends $pb.GeneratedMessage {
  factory ExecutableRun({
    ExecutableRunRequest? request,
    $fixnum.Int64? revision,
    ExecutablePreset? preset,
    $core.String? profileId,
    $core.String? profileName,
    $core.String? requestedAt,
    ExecutableRunPhase? phase,
    $core.int? processId,
    $core.String? scope,
    $core.int? rootExitCode,
    $core.int? observedProcessCount,
    $core.String? problem,
    GameRunInfo? game,
  }) {
    final result = create();
    if (request != null) result.request = request;
    if (revision != null) result.revision = revision;
    if (preset != null) result.preset = preset;
    if (profileId != null) result.profileId = profileId;
    if (profileName != null) result.profileName = profileName;
    if (requestedAt != null) result.requestedAt = requestedAt;
    if (phase != null) result.phase = phase;
    if (processId != null) result.processId = processId;
    if (scope != null) result.scope = scope;
    if (rootExitCode != null) result.rootExitCode = rootExitCode;
    if (observedProcessCount != null)
      result.observedProcessCount = observedProcessCount;
    if (problem != null) result.problem = problem;
    if (game != null) result.game = game;
    return result;
  }

  ExecutableRun._();

  factory ExecutableRun.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutableRun.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutableRun',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ExecutableRunRequest>(1, _omitFieldNames ? '' : 'request',
        subBuilder: ExecutableRunRequest.create)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<ExecutablePreset>(3, _omitFieldNames ? '' : 'preset',
        subBuilder: ExecutablePreset.create)
    ..aOS(4, _omitFieldNames ? '' : 'profileId')
    ..aOS(5, _omitFieldNames ? '' : 'profileName')
    ..aOS(6, _omitFieldNames ? '' : 'requestedAt')
    ..aE<ExecutableRunPhase>(7, _omitFieldNames ? '' : 'phase',
        enumValues: ExecutableRunPhase.values)
    ..aI(8, _omitFieldNames ? '' : 'processId', fieldType: $pb.PbFieldType.OU3)
    ..aOS(9, _omitFieldNames ? '' : 'scope')
    ..aI(10, _omitFieldNames ? '' : 'rootExitCode')
    ..aI(11, _omitFieldNames ? '' : 'observedProcessCount',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(12, _omitFieldNames ? '' : 'problem')
    ..aOM<GameRunInfo>(13, _omitFieldNames ? '' : 'game',
        subBuilder: GameRunInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableRun clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableRun copyWith(void Function(ExecutableRun) updates) =>
      super.copyWith((message) => updates(message as ExecutableRun))
          as ExecutableRun;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutableRun create() => ExecutableRun._();
  @$core.override
  ExecutableRun createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutableRun getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutableRun>(create);
  static ExecutableRun? _defaultInstance;

  @$pb.TagNumber(1)
  ExecutableRunRequest get request => $_getN(0);
  @$pb.TagNumber(1)
  set request(ExecutableRunRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequest() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequest() => $_clearField(1);
  @$pb.TagNumber(1)
  ExecutableRunRequest ensureRequest() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revision => $_getI64(1);
  @$pb.TagNumber(2)
  set revision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  ExecutablePreset get preset => $_getN(2);
  @$pb.TagNumber(3)
  set preset(ExecutablePreset value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPreset() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreset() => $_clearField(3);
  @$pb.TagNumber(3)
  ExecutablePreset ensurePreset() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get profileId => $_getSZ(3);
  @$pb.TagNumber(4)
  set profileId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProfileId() => $_has(3);
  @$pb.TagNumber(4)
  void clearProfileId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get profileName => $_getSZ(4);
  @$pb.TagNumber(5)
  set profileName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProfileName() => $_has(4);
  @$pb.TagNumber(5)
  void clearProfileName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get requestedAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set requestedAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRequestedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearRequestedAt() => $_clearField(6);

  @$pb.TagNumber(7)
  ExecutableRunPhase get phase => $_getN(6);
  @$pb.TagNumber(7)
  set phase(ExecutableRunPhase value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPhase() => $_has(6);
  @$pb.TagNumber(7)
  void clearPhase() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get processId => $_getIZ(7);
  @$pb.TagNumber(8)
  set processId($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasProcessId() => $_has(7);
  @$pb.TagNumber(8)
  void clearProcessId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get scope => $_getSZ(8);
  @$pb.TagNumber(9)
  set scope($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasScope() => $_has(8);
  @$pb.TagNumber(9)
  void clearScope() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get rootExitCode => $_getIZ(9);
  @$pb.TagNumber(10)
  set rootExitCode($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRootExitCode() => $_has(9);
  @$pb.TagNumber(10)
  void clearRootExitCode() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get observedProcessCount => $_getIZ(10);
  @$pb.TagNumber(11)
  set observedProcessCount($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasObservedProcessCount() => $_has(10);
  @$pb.TagNumber(11)
  void clearObservedProcessCount() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get problem => $_getSZ(11);
  @$pb.TagNumber(12)
  set problem($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasProblem() => $_has(11);
  @$pb.TagNumber(12)
  void clearProblem() => $_clearField(12);

  @$pb.TagNumber(13)
  GameRunInfo get game => $_getN(12);
  @$pb.TagNumber(13)
  set game(GameRunInfo value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasGame() => $_has(12);
  @$pb.TagNumber(13)
  void clearGame() => $_clearField(13);
  @$pb.TagNumber(13)
  GameRunInfo ensureGame() => $_ensure(12);
}

class ExecutableProblem extends $pb.GeneratedMessage {
  factory ExecutableProblem({
    ExecutableProblemCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  ExecutableProblem._();

  factory ExecutableProblem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutableProblem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutableProblem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<ExecutableProblemCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: ExecutableProblemCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableProblem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableProblem copyWith(void Function(ExecutableProblem) updates) =>
      super.copyWith((message) => updates(message as ExecutableProblem))
          as ExecutableProblem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutableProblem create() => ExecutableProblem._();
  @$core.override
  ExecutableProblem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutableProblem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutableProblem>(create);
  static ExecutableProblem? _defaultInstance;

  @$pb.TagNumber(1)
  ExecutableProblemCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ExecutableProblemCode value) => $_setField(1, value);
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

enum ExecutablePresetReply_Result { preset, problem, notSet }

class ExecutablePresetReply extends $pb.GeneratedMessage {
  factory ExecutablePresetReply({
    ExecutablePreset? preset,
    ExecutableProblem? problem,
  }) {
    final result = create();
    if (preset != null) result.preset = preset;
    if (problem != null) result.problem = problem;
    return result;
  }

  ExecutablePresetReply._();

  factory ExecutablePresetReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutablePresetReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ExecutablePresetReply_Result>
      _ExecutablePresetReply_ResultByTag = {
    1: ExecutablePresetReply_Result.preset,
    2: ExecutablePresetReply_Result.problem,
    0: ExecutablePresetReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutablePresetReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ExecutablePreset>(1, _omitFieldNames ? '' : 'preset',
        subBuilder: ExecutablePreset.create)
    ..aOM<ExecutableProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: ExecutableProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutablePresetReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutablePresetReply copyWith(
          void Function(ExecutablePresetReply) updates) =>
      super.copyWith((message) => updates(message as ExecutablePresetReply))
          as ExecutablePresetReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutablePresetReply create() => ExecutablePresetReply._();
  @$core.override
  ExecutablePresetReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutablePresetReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutablePresetReply>(create);
  static ExecutablePresetReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ExecutablePresetReply_Result whichResult() =>
      _ExecutablePresetReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ExecutablePreset get preset => $_getN(0);
  @$pb.TagNumber(1)
  set preset(ExecutablePreset value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreset() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreset() => $_clearField(1);
  @$pb.TagNumber(1)
  ExecutablePreset ensurePreset() => $_ensure(0);

  @$pb.TagNumber(2)
  ExecutableProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem(ExecutableProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  ExecutableProblem ensureProblem() => $_ensure(1);
}

class ExecutableMutationReply extends $pb.GeneratedMessage {
  factory ExecutableMutationReply({
    ExecutableProblem? problem,
  }) {
    final result = create();
    if (problem != null) result.problem = problem;
    return result;
  }

  ExecutableMutationReply._();

  factory ExecutableMutationReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutableMutationReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutableMutationReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ExecutableProblem>(1, _omitFieldNames ? '' : 'problem',
        subBuilder: ExecutableProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableMutationReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableMutationReply copyWith(
          void Function(ExecutableMutationReply) updates) =>
      super.copyWith((message) => updates(message as ExecutableMutationReply))
          as ExecutableMutationReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutableMutationReply create() => ExecutableMutationReply._();
  @$core.override
  ExecutableMutationReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutableMutationReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutableMutationReply>(create);
  static ExecutableMutationReply? _defaultInstance;

  @$pb.TagNumber(1)
  ExecutableProblem get problem => $_getN(0);
  @$pb.TagNumber(1)
  set problem(ExecutableProblem value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProblem() => $_has(0);
  @$pb.TagNumber(1)
  void clearProblem() => $_clearField(1);
  @$pb.TagNumber(1)
  ExecutableProblem ensureProblem() => $_ensure(0);
}

class ExecutablePresetPageReply extends $pb.GeneratedMessage {
  factory ExecutablePresetPageReply({
    $core.Iterable<ExecutablePreset>? presets,
    $core.String? nextId,
    ExecutableProblem? problem,
    $core.Iterable<ExecutableRun>? latestRuns,
  }) {
    final result = create();
    if (presets != null) result.presets.addAll(presets);
    if (nextId != null) result.nextId = nextId;
    if (problem != null) result.problem = problem;
    if (latestRuns != null) result.latestRuns.addAll(latestRuns);
    return result;
  }

  ExecutablePresetPageReply._();

  factory ExecutablePresetPageReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutablePresetPageReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutablePresetPageReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<ExecutablePreset>(1, _omitFieldNames ? '' : 'presets',
        subBuilder: ExecutablePreset.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextId')
    ..aOM<ExecutableProblem>(3, _omitFieldNames ? '' : 'problem',
        subBuilder: ExecutableProblem.create)
    ..pPM<ExecutableRun>(4, _omitFieldNames ? '' : 'latestRuns',
        subBuilder: ExecutableRun.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutablePresetPageReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutablePresetPageReply copyWith(
          void Function(ExecutablePresetPageReply) updates) =>
      super.copyWith((message) => updates(message as ExecutablePresetPageReply))
          as ExecutablePresetPageReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutablePresetPageReply create() => ExecutablePresetPageReply._();
  @$core.override
  ExecutablePresetPageReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutablePresetPageReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutablePresetPageReply>(create);
  static ExecutablePresetPageReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ExecutablePreset> get presets => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextId => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextId() => $_clearField(2);

  @$pb.TagNumber(3)
  ExecutableProblem get problem => $_getN(2);
  @$pb.TagNumber(3)
  set problem(ExecutableProblem value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProblem() => $_has(2);
  @$pb.TagNumber(3)
  void clearProblem() => $_clearField(3);
  @$pb.TagNumber(3)
  ExecutableProblem ensureProblem() => $_ensure(2);

  @$pb.TagNumber(4)
  $pb.PbList<ExecutableRun> get latestRuns => $_getList(3);
}

enum ExecutableRunReply_Result { run, problem, notSet }

class ExecutableRunReply extends $pb.GeneratedMessage {
  factory ExecutableRunReply({
    ExecutableRun? run,
    ExecutableProblem? problem,
  }) {
    final result = create();
    if (run != null) result.run = run;
    if (problem != null) result.problem = problem;
    return result;
  }

  ExecutableRunReply._();

  factory ExecutableRunReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutableRunReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ExecutableRunReply_Result>
      _ExecutableRunReply_ResultByTag = {
    1: ExecutableRunReply_Result.run,
    2: ExecutableRunReply_Result.problem,
    0: ExecutableRunReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutableRunReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ExecutableRun>(1, _omitFieldNames ? '' : 'run',
        subBuilder: ExecutableRun.create)
    ..aOM<ExecutableProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: ExecutableProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableRunReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableRunReply copyWith(void Function(ExecutableRunReply) updates) =>
      super.copyWith((message) => updates(message as ExecutableRunReply))
          as ExecutableRunReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutableRunReply create() => ExecutableRunReply._();
  @$core.override
  ExecutableRunReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutableRunReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutableRunReply>(create);
  static ExecutableRunReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ExecutableRunReply_Result whichResult() =>
      _ExecutableRunReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ExecutableRun get run => $_getN(0);
  @$pb.TagNumber(1)
  set run(ExecutableRun value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRun() => $_has(0);
  @$pb.TagNumber(1)
  void clearRun() => $_clearField(1);
  @$pb.TagNumber(1)
  ExecutableRun ensureRun() => $_ensure(0);

  @$pb.TagNumber(2)
  ExecutableProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem(ExecutableProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  ExecutableProblem ensureProblem() => $_ensure(1);
}

class ExecutableRunPageReply extends $pb.GeneratedMessage {
  factory ExecutableRunPageReply({
    $core.Iterable<ExecutableRun>? runs,
    $core.String? nextId,
    ExecutableProblem? problem,
  }) {
    final result = create();
    if (runs != null) result.runs.addAll(runs);
    if (nextId != null) result.nextId = nextId;
    if (problem != null) result.problem = problem;
    return result;
  }

  ExecutableRunPageReply._();

  factory ExecutableRunPageReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExecutableRunPageReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecutableRunPageReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<ExecutableRun>(1, _omitFieldNames ? '' : 'runs',
        subBuilder: ExecutableRun.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextId')
    ..aOM<ExecutableProblem>(3, _omitFieldNames ? '' : 'problem',
        subBuilder: ExecutableProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableRunPageReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutableRunPageReply copyWith(
          void Function(ExecutableRunPageReply) updates) =>
      super.copyWith((message) => updates(message as ExecutableRunPageReply))
          as ExecutableRunPageReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutableRunPageReply create() => ExecutableRunPageReply._();
  @$core.override
  ExecutableRunPageReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExecutableRunPageReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExecutableRunPageReply>(create);
  static ExecutableRunPageReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ExecutableRun> get runs => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextId => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextId() => $_clearField(2);

  @$pb.TagNumber(3)
  ExecutableProblem get problem => $_getN(2);
  @$pb.TagNumber(3)
  set problem(ExecutableProblem value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProblem() => $_has(2);
  @$pb.TagNumber(3)
  void clearProblem() => $_clearField(3);
  @$pb.TagNumber(3)
  ExecutableProblem ensureProblem() => $_ensure(2);
}

class GameRunRequest extends $pb.GeneratedMessage {
  factory GameRunRequest({
    $core.String? id,
    $core.String? workspaceId,
    $fixnum.Int64? workspaceRevision,
    $core.String? profileId,
    $fixnum.Int64? contextRevision,
    $core.String? sourceToken,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (workspaceRevision != null) result.workspaceRevision = workspaceRevision;
    if (profileId != null) result.profileId = profileId;
    if (contextRevision != null) result.contextRevision = contextRevision;
    if (sourceToken != null) result.sourceToken = sourceToken;
    return result;
  }

  GameRunRequest._();

  factory GameRunRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameRunRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameRunRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'workspaceRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'profileId')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'contextRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(6, _omitFieldNames ? '' : 'sourceToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameRunRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameRunRequest copyWith(void Function(GameRunRequest) updates) =>
      super.copyWith((message) => updates(message as GameRunRequest))
          as GameRunRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameRunRequest create() => GameRunRequest._();
  @$core.override
  GameRunRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameRunRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameRunRequest>(create);
  static GameRunRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get workspaceRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set workspaceRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWorkspaceRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearWorkspaceRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get profileId => $_getSZ(3);
  @$pb.TagNumber(4)
  set profileId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProfileId() => $_has(3);
  @$pb.TagNumber(4)
  void clearProfileId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get contextRevision => $_getI64(4);
  @$pb.TagNumber(5)
  set contextRevision($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContextRevision() => $_has(4);
  @$pb.TagNumber(5)
  void clearContextRevision() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get sourceToken => $_getSZ(5);
  @$pb.TagNumber(6)
  set sourceToken($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSourceToken() => $_has(5);
  @$pb.TagNumber(6)
  void clearSourceToken() => $_clearField(6);
}

class GameRunFiles extends $pb.GeneratedMessage {
  factory GameRunFiles({
    $core.String? receiptId,
    $core.String? generationId,
    $core.String? fingerprint,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    if (generationId != null) result.generationId = generationId;
    if (fingerprint != null) result.fingerprint = fingerprint;
    return result;
  }

  GameRunFiles._();

  factory GameRunFiles.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameRunFiles.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameRunFiles',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'receiptId')
    ..aOS(2, _omitFieldNames ? '' : 'generationId')
    ..aOS(3, _omitFieldNames ? '' : 'fingerprint')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameRunFiles clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameRunFiles copyWith(void Function(GameRunFiles) updates) =>
      super.copyWith((message) => updates(message as GameRunFiles))
          as GameRunFiles;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameRunFiles create() => GameRunFiles._();
  @$core.override
  GameRunFiles createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameRunFiles getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameRunFiles>(create);
  static GameRunFiles? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get receiptId => $_getSZ(0);
  @$pb.TagNumber(1)
  set receiptId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get generationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set generationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGenerationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGenerationId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fingerprint => $_getSZ(2);
  @$pb.TagNumber(3)
  set fingerprint($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFingerprint() => $_has(2);
  @$pb.TagNumber(3)
  void clearFingerprint() => $_clearField(3);
}

class GameRunProfileData extends $pb.GeneratedMessage {
  factory GameRunProfileData({
    $core.String? receiptId,
    $fixnum.Int64? revision,
    $core.int? completedFiles,
    $core.bool? complete,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    if (revision != null) result.revision = revision;
    if (completedFiles != null) result.completedFiles = completedFiles;
    if (complete != null) result.complete = complete;
    return result;
  }

  GameRunProfileData._();

  factory GameRunProfileData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameRunProfileData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameRunProfileData',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'receiptId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(3, _omitFieldNames ? '' : 'completedFiles',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(4, _omitFieldNames ? '' : 'complete')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameRunProfileData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameRunProfileData copyWith(void Function(GameRunProfileData) updates) =>
      super.copyWith((message) => updates(message as GameRunProfileData))
          as GameRunProfileData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameRunProfileData create() => GameRunProfileData._();
  @$core.override
  GameRunProfileData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameRunProfileData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameRunProfileData>(create);
  static GameRunProfileData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get receiptId => $_getSZ(0);
  @$pb.TagNumber(1)
  set receiptId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revision => $_getI64(1);
  @$pb.TagNumber(2)
  set revision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get completedFiles => $_getIZ(2);
  @$pb.TagNumber(3)
  set completedFiles($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCompletedFiles() => $_has(2);
  @$pb.TagNumber(3)
  void clearCompletedFiles() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get complete => $_getBF(3);
  @$pb.TagNumber(4)
  set complete($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasComplete() => $_has(3);
  @$pb.TagNumber(4)
  void clearComplete() => $_clearField(4);
}

class GameRunInfo extends $pb.GeneratedMessage {
  factory GameRunInfo({
    GameRunRequest? request,
    $core.String? contextId,
    $core.String? name,
    $core.String? gameDirectory,
    $core.String? runtime,
    $core.String? executable,
    $core.Iterable<$core.String>? arguments,
    $core.String? workingDirectory,
    $core.Iterable<ExecutableEnvironmentSetting>? environment,
    GamePreparationPhase? preparation,
    $core.int? completed,
    $core.int? total,
    GameRunFiles? files,
    $fixnum.Int64? profileDataRevision,
    GameRunProfileData? profileData,
  }) {
    final result = create();
    if (request != null) result.request = request;
    if (contextId != null) result.contextId = contextId;
    if (name != null) result.name = name;
    if (gameDirectory != null) result.gameDirectory = gameDirectory;
    if (runtime != null) result.runtime = runtime;
    if (executable != null) result.executable = executable;
    if (arguments != null) result.arguments.addAll(arguments);
    if (workingDirectory != null) result.workingDirectory = workingDirectory;
    if (environment != null) result.environment.addAll(environment);
    if (preparation != null) result.preparation = preparation;
    if (completed != null) result.completed = completed;
    if (total != null) result.total = total;
    if (files != null) result.files = files;
    if (profileDataRevision != null)
      result.profileDataRevision = profileDataRevision;
    if (profileData != null) result.profileData = profileData;
    return result;
  }

  GameRunInfo._();

  factory GameRunInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameRunInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameRunInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<GameRunRequest>(1, _omitFieldNames ? '' : 'request',
        subBuilder: GameRunRequest.create)
    ..aOS(2, _omitFieldNames ? '' : 'contextId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'gameDirectory')
    ..aOS(5, _omitFieldNames ? '' : 'runtime')
    ..aOS(6, _omitFieldNames ? '' : 'executable')
    ..pPS(7, _omitFieldNames ? '' : 'arguments')
    ..aOS(8, _omitFieldNames ? '' : 'workingDirectory')
    ..pPM<ExecutableEnvironmentSetting>(9, _omitFieldNames ? '' : 'environment',
        subBuilder: ExecutableEnvironmentSetting.create)
    ..aE<GamePreparationPhase>(10, _omitFieldNames ? '' : 'preparation',
        enumValues: GamePreparationPhase.values)
    ..aI(11, _omitFieldNames ? '' : 'completed', fieldType: $pb.PbFieldType.OU3)
    ..aI(12, _omitFieldNames ? '' : 'total', fieldType: $pb.PbFieldType.OU3)
    ..aOM<GameRunFiles>(13, _omitFieldNames ? '' : 'files',
        subBuilder: GameRunFiles.create)
    ..a<$fixnum.Int64>(
        14, _omitFieldNames ? '' : 'profileDataRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<GameRunProfileData>(15, _omitFieldNames ? '' : 'profileData',
        subBuilder: GameRunProfileData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameRunInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameRunInfo copyWith(void Function(GameRunInfo) updates) =>
      super.copyWith((message) => updates(message as GameRunInfo))
          as GameRunInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameRunInfo create() => GameRunInfo._();
  @$core.override
  GameRunInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameRunInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameRunInfo>(create);
  static GameRunInfo? _defaultInstance;

  @$pb.TagNumber(1)
  GameRunRequest get request => $_getN(0);
  @$pb.TagNumber(1)
  set request(GameRunRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequest() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequest() => $_clearField(1);
  @$pb.TagNumber(1)
  GameRunRequest ensureRequest() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get contextId => $_getSZ(1);
  @$pb.TagNumber(2)
  set contextId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContextId() => $_has(1);
  @$pb.TagNumber(2)
  void clearContextId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get gameDirectory => $_getSZ(3);
  @$pb.TagNumber(4)
  set gameDirectory($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGameDirectory() => $_has(3);
  @$pb.TagNumber(4)
  void clearGameDirectory() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get runtime => $_getSZ(4);
  @$pb.TagNumber(5)
  set runtime($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRuntime() => $_has(4);
  @$pb.TagNumber(5)
  void clearRuntime() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get executable => $_getSZ(5);
  @$pb.TagNumber(6)
  set executable($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasExecutable() => $_has(5);
  @$pb.TagNumber(6)
  void clearExecutable() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get arguments => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get workingDirectory => $_getSZ(7);
  @$pb.TagNumber(8)
  set workingDirectory($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWorkingDirectory() => $_has(7);
  @$pb.TagNumber(8)
  void clearWorkingDirectory() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<ExecutableEnvironmentSetting> get environment => $_getList(8);

  @$pb.TagNumber(10)
  GamePreparationPhase get preparation => $_getN(9);
  @$pb.TagNumber(10)
  set preparation(GamePreparationPhase value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPreparation() => $_has(9);
  @$pb.TagNumber(10)
  void clearPreparation() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get completed => $_getIZ(10);
  @$pb.TagNumber(11)
  set completed($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCompleted() => $_has(10);
  @$pb.TagNumber(11)
  void clearCompleted() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get total => $_getIZ(11);
  @$pb.TagNumber(12)
  set total($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasTotal() => $_has(11);
  @$pb.TagNumber(12)
  void clearTotal() => $_clearField(12);

  @$pb.TagNumber(13)
  GameRunFiles get files => $_getN(12);
  @$pb.TagNumber(13)
  set files(GameRunFiles value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasFiles() => $_has(12);
  @$pb.TagNumber(13)
  void clearFiles() => $_clearField(13);
  @$pb.TagNumber(13)
  GameRunFiles ensureFiles() => $_ensure(12);

  @$pb.TagNumber(14)
  $fixnum.Int64 get profileDataRevision => $_getI64(13);
  @$pb.TagNumber(14)
  set profileDataRevision($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasProfileDataRevision() => $_has(13);
  @$pb.TagNumber(14)
  void clearProfileDataRevision() => $_clearField(14);

  @$pb.TagNumber(15)
  GameRunProfileData get profileData => $_getN(14);
  @$pb.TagNumber(15)
  set profileData(GameRunProfileData value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasProfileData() => $_has(14);
  @$pb.TagNumber(15)
  void clearProfileData() => $_clearField(15);
  @$pb.TagNumber(15)
  GameRunProfileData ensureProfileData() => $_ensure(14);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
