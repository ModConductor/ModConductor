// This is a generated file - do not edit.
//
// Generated from modconductor/v1/enb.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'enb.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'enb.pbenum.dart';

class EnbRequest extends $pb.GeneratedMessage {
  factory EnbRequest({
    $core.String? workspaceId,
    $core.String? profileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  EnbRequest._();

  factory EnbRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EnbRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnbRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnbRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnbRequest copyWith(void Function(EnbRequest) updates) =>
      super.copyWith((message) => updates(message as EnbRequest)) as EnbRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnbRequest create() => EnbRequest._();
  @$core.override
  EnbRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EnbRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnbRequest>(create);
  static EnbRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get profileId => $_getSZ(1);
  @$pb.TagNumber(2)
  set profileId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProfileId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProfileId() => $_clearField(2);
}

class EnbArchiveRequest extends $pb.GeneratedMessage {
  factory EnbArchiveRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? operationId,
    $core.String? path,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (operationId != null) result.operationId = operationId;
    if (path != null) result.path = path;
    return result;
  }

  EnbArchiveRequest._();

  factory EnbArchiveRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EnbArchiveRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnbArchiveRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'operationId')
    ..aOS(4, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnbArchiveRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnbArchiveRequest copyWith(void Function(EnbArchiveRequest) updates) =>
      super.copyWith((message) => updates(message as EnbArchiveRequest))
          as EnbArchiveRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnbArchiveRequest create() => EnbArchiveRequest._();
  @$core.override
  EnbArchiveRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EnbArchiveRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnbArchiveRequest>(create);
  static EnbArchiveRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get profileId => $_getSZ(1);
  @$pb.TagNumber(2)
  set profileId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProfileId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProfileId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get operationId => $_getSZ(2);
  @$pb.TagNumber(3)
  set operationId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOperationId() => $_has(2);
  @$pb.TagNumber(3)
  void clearOperationId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get path => $_getSZ(3);
  @$pb.TagNumber(4)
  set path($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearPath() => $_clearField(4);
}

class EnbState extends $pb.GeneratedMessage {
  factory EnbState({
    EnbPhase? phase,
    $core.String? status,
    $core.String? detail,
    $core.String? runtimeVersion,
    $core.String? presetVersion,
    $core.bool? canOpenAuthorPage,
    $core.bool? canSelectArchive,
    $core.bool? canCancel,
  }) {
    final result = create();
    if (phase != null) result.phase = phase;
    if (status != null) result.status = status;
    if (detail != null) result.detail = detail;
    if (runtimeVersion != null) result.runtimeVersion = runtimeVersion;
    if (presetVersion != null) result.presetVersion = presetVersion;
    if (canOpenAuthorPage != null) result.canOpenAuthorPage = canOpenAuthorPage;
    if (canSelectArchive != null) result.canSelectArchive = canSelectArchive;
    if (canCancel != null) result.canCancel = canCancel;
    return result;
  }

  EnbState._();

  factory EnbState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EnbState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnbState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<EnbPhase>(1, _omitFieldNames ? '' : 'phase',
        enumValues: EnbPhase.values)
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'detail')
    ..aOS(4, _omitFieldNames ? '' : 'runtimeVersion')
    ..aOS(5, _omitFieldNames ? '' : 'presetVersion')
    ..aOB(6, _omitFieldNames ? '' : 'canOpenAuthorPage')
    ..aOB(7, _omitFieldNames ? '' : 'canSelectArchive')
    ..aOB(8, _omitFieldNames ? '' : 'canCancel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnbState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnbState copyWith(void Function(EnbState) updates) =>
      super.copyWith((message) => updates(message as EnbState)) as EnbState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnbState create() => EnbState._();
  @$core.override
  EnbState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EnbState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EnbState>(create);
  static EnbState? _defaultInstance;

  @$pb.TagNumber(1)
  EnbPhase get phase => $_getN(0);
  @$pb.TagNumber(1)
  set phase(EnbPhase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPhase() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhase() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get detail => $_getSZ(2);
  @$pb.TagNumber(3)
  set detail($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDetail() => $_has(2);
  @$pb.TagNumber(3)
  void clearDetail() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get runtimeVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set runtimeVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRuntimeVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearRuntimeVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get presetVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set presetVersion($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPresetVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearPresetVersion() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get canOpenAuthorPage => $_getBF(5);
  @$pb.TagNumber(6)
  set canOpenAuthorPage($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCanOpenAuthorPage() => $_has(5);
  @$pb.TagNumber(6)
  void clearCanOpenAuthorPage() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get canSelectArchive => $_getBF(6);
  @$pb.TagNumber(7)
  set canSelectArchive($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCanSelectArchive() => $_has(6);
  @$pb.TagNumber(7)
  void clearCanSelectArchive() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get canCancel => $_getBF(7);
  @$pb.TagNumber(8)
  set canCancel($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCanCancel() => $_has(7);
  @$pb.TagNumber(8)
  void clearCanCancel() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
