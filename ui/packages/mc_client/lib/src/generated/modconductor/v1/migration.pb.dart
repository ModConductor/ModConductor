// This is a generated file - do not edit.
//
// Generated from modconductor/v1/migration.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'migration.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'migration.pbenum.dart';

class MigrationRequest extends $pb.GeneratedMessage {
  factory MigrationRequest({
    $core.String? workspaceId,
    MigrationManager? manager,
    $core.String? sourceFolder,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (manager != null) result.manager = manager;
    if (sourceFolder != null) result.sourceFolder = sourceFolder;
    return result;
  }

  MigrationRequest._();

  factory MigrationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aE<MigrationManager>(2, _omitFieldNames ? '' : 'manager',
        enumValues: MigrationManager.values)
    ..aOS(3, _omitFieldNames ? '' : 'sourceFolder')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationRequest copyWith(void Function(MigrationRequest) updates) =>
      super.copyWith((message) => updates(message as MigrationRequest))
          as MigrationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrationRequest create() => MigrationRequest._();
  @$core.override
  MigrationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrationRequest>(create);
  static MigrationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  MigrationManager get manager => $_getN(1);
  @$pb.TagNumber(2)
  set manager(MigrationManager value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasManager() => $_has(1);
  @$pb.TagNumber(2)
  void clearManager() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sourceFolder => $_getSZ(2);
  @$pb.TagNumber(3)
  set sourceFolder($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSourceFolder() => $_has(2);
  @$pb.TagNumber(3)
  void clearSourceFolder() => $_clearField(3);
}

class MigrationProgress extends $pb.GeneratedMessage {
  factory MigrationProgress({
    $core.int? completed,
    $core.int? total,
    $core.String? message,
  }) {
    final result = create();
    if (completed != null) result.completed = completed;
    if (total != null) result.total = total;
    if (message != null) result.message = message;
    return result;
  }

  MigrationProgress._();

  factory MigrationProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrationProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrationProgress',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'completed', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'total', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationProgress copyWith(void Function(MigrationProgress) updates) =>
      super.copyWith((message) => updates(message as MigrationProgress))
          as MigrationProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrationProgress create() => MigrationProgress._();
  @$core.override
  MigrationProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrationProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrationProgress>(create);
  static MigrationProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get completed => $_getIZ(0);
  @$pb.TagNumber(1)
  set completed($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCompleted() => $_has(0);
  @$pb.TagNumber(1)
  void clearCompleted() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

class MigrationError extends $pb.GeneratedMessage {
  factory MigrationError({
    MigrationErrorCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  MigrationError._();

  factory MigrationError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrationError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrationError',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<MigrationErrorCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: MigrationErrorCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationError copyWith(void Function(MigrationError) updates) =>
      super.copyWith((message) => updates(message as MigrationError))
          as MigrationError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrationError create() => MigrationError._();
  @$core.override
  MigrationError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrationError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrationError>(create);
  static MigrationError? _defaultInstance;

  @$pb.TagNumber(1)
  MigrationErrorCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(MigrationErrorCode value) => $_setField(1, value);
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

class MigrationResult extends $pb.GeneratedMessage {
  factory MigrationResult({
    $core.String? workspaceId,
    $core.int? profiles,
    $core.int? mods,
    $core.int? artifacts,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profiles != null) result.profiles = profiles;
    if (mods != null) result.mods = mods;
    if (artifacts != null) result.artifacts = artifacts;
    return result;
  }

  MigrationResult._();

  factory MigrationResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrationResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrationResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aI(2, _omitFieldNames ? '' : 'profiles', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'mods', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'artifacts', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationResult copyWith(void Function(MigrationResult) updates) =>
      super.copyWith((message) => updates(message as MigrationResult))
          as MigrationResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrationResult create() => MigrationResult._();
  @$core.override
  MigrationResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrationResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrationResult>(create);
  static MigrationResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get profiles => $_getIZ(1);
  @$pb.TagNumber(2)
  set profiles($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProfiles() => $_has(1);
  @$pb.TagNumber(2)
  void clearProfiles() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get mods => $_getIZ(2);
  @$pb.TagNumber(3)
  set mods($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMods() => $_has(2);
  @$pb.TagNumber(3)
  void clearMods() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get artifacts => $_getIZ(3);
  @$pb.TagNumber(4)
  set artifacts($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasArtifacts() => $_has(3);
  @$pb.TagNumber(4)
  void clearArtifacts() => $_clearField(4);
}

enum MigrationEvent_Event { progress, error, result, notSet }

class MigrationEvent extends $pb.GeneratedMessage {
  factory MigrationEvent({
    MigrationProgress? progress,
    MigrationError? error,
    MigrationResult? result,
  }) {
    final result$ = create();
    if (progress != null) result$.progress = progress;
    if (error != null) result$.error = error;
    if (result != null) result$.result = result;
    return result$;
  }

  MigrationEvent._();

  factory MigrationEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrationEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, MigrationEvent_Event>
      _MigrationEvent_EventByTag = {
    1: MigrationEvent_Event.progress,
    2: MigrationEvent_Event.error,
    3: MigrationEvent_Event.result,
    0: MigrationEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrationEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<MigrationProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: MigrationProgress.create)
    ..aOM<MigrationError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: MigrationError.create)
    ..aOM<MigrationResult>(3, _omitFieldNames ? '' : 'result',
        subBuilder: MigrationResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationEvent copyWith(void Function(MigrationEvent) updates) =>
      super.copyWith((message) => updates(message as MigrationEvent))
          as MigrationEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrationEvent create() => MigrationEvent._();
  @$core.override
  MigrationEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrationEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrationEvent>(create);
  static MigrationEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  MigrationEvent_Event whichEvent() =>
      _MigrationEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  MigrationProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(MigrationProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  MigrationProgress ensureProgress() => $_ensure(0);

  @$pb.TagNumber(2)
  MigrationError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(MigrationError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  MigrationError ensureError() => $_ensure(1);

  @$pb.TagNumber(3)
  MigrationResult get result => $_getN(2);
  @$pb.TagNumber(3)
  set result(MigrationResult value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasResult() => $_has(2);
  @$pb.TagNumber(3)
  void clearResult() => $_clearField(3);
  @$pb.TagNumber(3)
  MigrationResult ensureResult() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
