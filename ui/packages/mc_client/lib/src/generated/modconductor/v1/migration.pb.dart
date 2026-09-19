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

class MigrateRequest extends $pb.GeneratedMessage {
  factory MigrateRequest({
    $core.String? workspaceId,
    Manager? manager,
    $core.String? sourceFolder,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (manager != null) result.manager = manager;
    if (sourceFolder != null) result.sourceFolder = sourceFolder;
    return result;
  }

  MigrateRequest._();

  factory MigrateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aE<Manager>(2, _omitFieldNames ? '' : 'manager',
        enumValues: Manager.values)
    ..aOS(3, _omitFieldNames ? '' : 'sourceFolder')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateRequest copyWith(void Function(MigrateRequest) updates) =>
      super.copyWith((message) => updates(message as MigrateRequest))
          as MigrateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrateRequest create() => MigrateRequest._();
  @$core.override
  MigrateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrateRequest>(create);
  static MigrateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  Manager get manager => $_getN(1);
  @$pb.TagNumber(2)
  set manager(Manager value) => $_setField(2, value);
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

class MigrateProgress extends $pb.GeneratedMessage {
  factory MigrateProgress({
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

  MigrateProgress._();

  factory MigrateProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrateProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrateProgress',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'completed', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'total', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateProgress copyWith(void Function(MigrateProgress) updates) =>
      super.copyWith((message) => updates(message as MigrateProgress))
          as MigrateProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrateProgress create() => MigrateProgress._();
  @$core.override
  MigrateProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrateProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrateProgress>(create);
  static MigrateProgress? _defaultInstance;

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

class MigrateError extends $pb.GeneratedMessage {
  factory MigrateError({
    MigrateErrorCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  MigrateError._();

  factory MigrateError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrateError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrateError',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<MigrateErrorCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: MigrateErrorCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateError copyWith(void Function(MigrateError) updates) =>
      super.copyWith((message) => updates(message as MigrateError))
          as MigrateError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrateError create() => MigrateError._();
  @$core.override
  MigrateError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrateError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrateError>(create);
  static MigrateError? _defaultInstance;

  @$pb.TagNumber(1)
  MigrateErrorCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(MigrateErrorCode value) => $_setField(1, value);
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

class MigrateResult extends $pb.GeneratedMessage {
  factory MigrateResult({
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

  MigrateResult._();

  factory MigrateResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrateResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrateResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aI(2, _omitFieldNames ? '' : 'profiles', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'mods', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'artifacts', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateResult copyWith(void Function(MigrateResult) updates) =>
      super.copyWith((message) => updates(message as MigrateResult))
          as MigrateResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrateResult create() => MigrateResult._();
  @$core.override
  MigrateResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrateResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrateResult>(create);
  static MigrateResult? _defaultInstance;

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

enum MigrateEvent_Event { progress, error, result, notSet }

class MigrateEvent extends $pb.GeneratedMessage {
  factory MigrateEvent({
    MigrateProgress? progress,
    MigrateError? error,
    MigrateResult? result,
  }) {
    final result$ = create();
    if (progress != null) result$.progress = progress;
    if (error != null) result$.error = error;
    if (result != null) result$.result = result;
    return result$;
  }

  MigrateEvent._();

  factory MigrateEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrateEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, MigrateEvent_Event>
      _MigrateEvent_EventByTag = {
    1: MigrateEvent_Event.progress,
    2: MigrateEvent_Event.error,
    3: MigrateEvent_Event.result,
    0: MigrateEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrateEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<MigrateProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: MigrateProgress.create)
    ..aOM<MigrateError>(2, _omitFieldNames ? '' : 'error',
        subBuilder: MigrateError.create)
    ..aOM<MigrateResult>(3, _omitFieldNames ? '' : 'result',
        subBuilder: MigrateResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrateEvent copyWith(void Function(MigrateEvent) updates) =>
      super.copyWith((message) => updates(message as MigrateEvent))
          as MigrateEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrateEvent create() => MigrateEvent._();
  @$core.override
  MigrateEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MigrateEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrateEvent>(create);
  static MigrateEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  MigrateEvent_Event whichEvent() => _MigrateEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  MigrateProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(MigrateProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  MigrateProgress ensureProgress() => $_ensure(0);

  @$pb.TagNumber(2)
  MigrateError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(MigrateError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  MigrateError ensureError() => $_ensure(1);

  @$pb.TagNumber(3)
  MigrateResult get result => $_getN(2);
  @$pb.TagNumber(3)
  set result(MigrateResult value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasResult() => $_has(2);
  @$pb.TagNumber(3)
  void clearResult() => $_clearField(3);
  @$pb.TagNumber(3)
  MigrateResult ensureResult() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
