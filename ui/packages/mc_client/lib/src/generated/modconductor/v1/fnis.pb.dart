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

class FnisRunRequest extends $pb.GeneratedMessage {
  factory FnisRunRequest({
    $core.String? id,
    $core.String? workspaceId,
    $core.String? profileId,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  FnisRunRequest._();

  factory FnisRunRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FnisRunRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FnisRunRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FnisRunRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FnisRunRequest copyWith(void Function(FnisRunRequest) updates) =>
      super.copyWith((message) => updates(message as FnisRunRequest))
          as FnisRunRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FnisRunRequest create() => FnisRunRequest._();
  @$core.override
  FnisRunRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FnisRunRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FnisRunRequest>(create);
  static FnisRunRequest? _defaultInstance;

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
  $core.String get profileId => $_getSZ(2);
  @$pb.TagNumber(3)
  set profileId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProfileId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfileId() => $_clearField(3);
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
    FnisOutputPhase? outputPhase,
    $core.String? outputStatus,
    $core.String? outputDetail,
    $core.bool? canRun,
    $core.bool? canCancelRun,
    $core.String? runId,
    $core.int? exitCode,
    $core.String? standardOutput,
    $core.String? standardError,
    $core.String? runLog,
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
    if (outputPhase != null) result.outputPhase = outputPhase;
    if (outputStatus != null) result.outputStatus = outputStatus;
    if (outputDetail != null) result.outputDetail = outputDetail;
    if (canRun != null) result.canRun = canRun;
    if (canCancelRun != null) result.canCancelRun = canCancelRun;
    if (runId != null) result.runId = runId;
    if (exitCode != null) result.exitCode = exitCode;
    if (standardOutput != null) result.standardOutput = standardOutput;
    if (standardError != null) result.standardError = standardError;
    if (runLog != null) result.runLog = runLog;
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
    ..aE<FnisOutputPhase>(11, _omitFieldNames ? '' : 'outputPhase',
        enumValues: FnisOutputPhase.values)
    ..aOS(12, _omitFieldNames ? '' : 'outputStatus')
    ..aOS(13, _omitFieldNames ? '' : 'outputDetail')
    ..aOB(14, _omitFieldNames ? '' : 'canRun')
    ..aOB(15, _omitFieldNames ? '' : 'canCancelRun')
    ..aOS(16, _omitFieldNames ? '' : 'runId')
    ..aI(17, _omitFieldNames ? '' : 'exitCode')
    ..aOS(18, _omitFieldNames ? '' : 'standardOutput')
    ..aOS(19, _omitFieldNames ? '' : 'standardError')
    ..aOS(20, _omitFieldNames ? '' : 'runLog')
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

  @$pb.TagNumber(11)
  FnisOutputPhase get outputPhase => $_getN(10);
  @$pb.TagNumber(11)
  set outputPhase(FnisOutputPhase value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasOutputPhase() => $_has(10);
  @$pb.TagNumber(11)
  void clearOutputPhase() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get outputStatus => $_getSZ(11);
  @$pb.TagNumber(12)
  set outputStatus($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasOutputStatus() => $_has(11);
  @$pb.TagNumber(12)
  void clearOutputStatus() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get outputDetail => $_getSZ(12);
  @$pb.TagNumber(13)
  set outputDetail($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasOutputDetail() => $_has(12);
  @$pb.TagNumber(13)
  void clearOutputDetail() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get canRun => $_getBF(13);
  @$pb.TagNumber(14)
  set canRun($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCanRun() => $_has(13);
  @$pb.TagNumber(14)
  void clearCanRun() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.bool get canCancelRun => $_getBF(14);
  @$pb.TagNumber(15)
  set canCancelRun($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCanCancelRun() => $_has(14);
  @$pb.TagNumber(15)
  void clearCanCancelRun() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get runId => $_getSZ(15);
  @$pb.TagNumber(16)
  set runId($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasRunId() => $_has(15);
  @$pb.TagNumber(16)
  void clearRunId() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.int get exitCode => $_getIZ(16);
  @$pb.TagNumber(17)
  set exitCode($core.int value) => $_setSignedInt32(16, value);
  @$pb.TagNumber(17)
  $core.bool hasExitCode() => $_has(16);
  @$pb.TagNumber(17)
  void clearExitCode() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get standardOutput => $_getSZ(17);
  @$pb.TagNumber(18)
  set standardOutput($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasStandardOutput() => $_has(17);
  @$pb.TagNumber(18)
  void clearStandardOutput() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get standardError => $_getSZ(18);
  @$pb.TagNumber(19)
  set standardError($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasStandardError() => $_has(18);
  @$pb.TagNumber(19)
  void clearStandardError() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get runLog => $_getSZ(19);
  @$pb.TagNumber(20)
  set runLog($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasRunLog() => $_has(19);
  @$pb.TagNumber(20)
  void clearRunLog() => $_clearField(20);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
