// This is a generated file - do not edit.
//
// Generated from modconductor/v1/fnis.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'fnis.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'fnis.pbenum.dart';

class FnisRequest extends $pb.GeneratedMessage {
  factory FnisRequest({
    $core.String? workspaceId,
    $core.String? profileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  FnisRequest._();

  factory FnisRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FnisRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FnisRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FnisRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FnisRequest copyWith(void Function(FnisRequest) updates) =>
      super.copyWith((message) => updates(message as FnisRequest))
          as FnisRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FnisRequest create() => FnisRequest._();
  @$core.override
  FnisRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FnisRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FnisRequest>(create);
  static FnisRequest? _defaultInstance;

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

class FnisState extends $pb.GeneratedMessage {
  factory FnisState({
    FnisPhase? phase,
    $core.String? version,
    $core.String? status,
    $core.String? detail,
    $fixnum.Int64? nexusFileId,
    $core.bool? canInstall,
    $core.bool? canCancel,
    $core.bool? canUpdate,
    $core.bool? canRemove,
    $core.bool? canRecover,
  }) {
    final result = create();
    if (phase != null) result.phase = phase;
    if (version != null) result.version = version;
    if (status != null) result.status = status;
    if (detail != null) result.detail = detail;
    if (nexusFileId != null) result.nexusFileId = nexusFileId;
    if (canInstall != null) result.canInstall = canInstall;
    if (canCancel != null) result.canCancel = canCancel;
    if (canUpdate != null) result.canUpdate = canUpdate;
    if (canRemove != null) result.canRemove = canRemove;
    if (canRecover != null) result.canRecover = canRecover;
    return result;
  }

  FnisState._();

  factory FnisState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FnisState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FnisState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<FnisPhase>(1, _omitFieldNames ? '' : 'phase',
        enumValues: FnisPhase.values)
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'status')
    ..aOS(4, _omitFieldNames ? '' : 'detail')
    ..aInt64(5, _omitFieldNames ? '' : 'nexusFileId')
    ..aOB(6, _omitFieldNames ? '' : 'canInstall')
    ..aOB(7, _omitFieldNames ? '' : 'canCancel')
    ..aOB(8, _omitFieldNames ? '' : 'canUpdate')
    ..aOB(9, _omitFieldNames ? '' : 'canRemove')
    ..aOB(10, _omitFieldNames ? '' : 'canRecover')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FnisState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FnisState copyWith(void Function(FnisState) updates) =>
      super.copyWith((message) => updates(message as FnisState)) as FnisState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FnisState create() => FnisState._();
  @$core.override
  FnisState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FnisState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FnisState>(create);
  static FnisState? _defaultInstance;

  @$pb.TagNumber(1)
  FnisPhase get phase => $_getN(0);
  @$pb.TagNumber(1)
  set phase(FnisPhase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPhase() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhase() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get status => $_getSZ(2);
  @$pb.TagNumber(3)
  set status($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get detail => $_getSZ(3);
  @$pb.TagNumber(4)
  set detail($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDetail() => $_has(3);
  @$pb.TagNumber(4)
  void clearDetail() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get nexusFileId => $_getI64(4);
  @$pb.TagNumber(5)
  set nexusFileId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNexusFileId() => $_has(4);
  @$pb.TagNumber(5)
  void clearNexusFileId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get canInstall => $_getBF(5);
  @$pb.TagNumber(6)
  set canInstall($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCanInstall() => $_has(5);
  @$pb.TagNumber(6)
  void clearCanInstall() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get canCancel => $_getBF(6);
  @$pb.TagNumber(7)
  set canCancel($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCanCancel() => $_has(6);
  @$pb.TagNumber(7)
  void clearCanCancel() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get canUpdate => $_getBF(7);
  @$pb.TagNumber(8)
  set canUpdate($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCanUpdate() => $_has(7);
  @$pb.TagNumber(8)
  void clearCanUpdate() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get canRemove => $_getBF(8);
  @$pb.TagNumber(9)
  set canRemove($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCanRemove() => $_has(8);
  @$pb.TagNumber(9)
  void clearCanRemove() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get canRecover => $_getBF(9);
  @$pb.TagNumber(10)
  set canRecover($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCanRecover() => $_has(9);
  @$pb.TagNumber(10)
  void clearCanRecover() => $_clearField(10);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
