// This is a generated file - do not edit.
//
// Generated from modconductor/v1/credentials.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'credentials.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'credentials.pbenum.dart';

class CredentialStatusRequest extends $pb.GeneratedMessage {
  factory CredentialStatusRequest() => create();

  CredentialStatusRequest._();

  factory CredentialStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CredentialStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CredentialStatusRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CredentialStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CredentialStatusRequest copyWith(
          void Function(CredentialStatusRequest) updates) =>
      super.copyWith((message) => updates(message as CredentialStatusRequest))
          as CredentialStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CredentialStatusRequest create() => CredentialStatusRequest._();
  @$core.override
  CredentialStatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CredentialStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CredentialStatusRequest>(create);
  static CredentialStatusRequest? _defaultInstance;
}

class CredentialModeRequest extends $pb.GeneratedMessage {
  factory CredentialModeRequest({
    CredentialStorageMode? mode,
  }) {
    final result = create();
    if (mode != null) result.mode = mode;
    return result;
  }

  CredentialModeRequest._();

  factory CredentialModeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CredentialModeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CredentialModeRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<CredentialStorageMode>(1, _omitFieldNames ? '' : 'mode',
        enumValues: CredentialStorageMode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CredentialModeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CredentialModeRequest copyWith(
          void Function(CredentialModeRequest) updates) =>
      super.copyWith((message) => updates(message as CredentialModeRequest))
          as CredentialModeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CredentialModeRequest create() => CredentialModeRequest._();
  @$core.override
  CredentialModeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CredentialModeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CredentialModeRequest>(create);
  static CredentialModeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  CredentialStorageMode get mode => $_getN(0);
  @$pb.TagNumber(1)
  set mode(CredentialStorageMode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearMode() => $_clearField(1);
}

class CredentialStorageStatus extends $pb.GeneratedMessage {
  factory CredentialStorageStatus({
    CredentialStorageKind? storage,
    CredentialStorageMode? mode,
    CredentialPresence? saved,
    $core.bool? hasSession,
    CredentialStorageProblem? problem,
    CredentialStorageProblem? removalProblem,
    $core.String? diagnosticReport,
  }) {
    final result = create();
    if (storage != null) result.storage = storage;
    if (mode != null) result.mode = mode;
    if (saved != null) result.saved = saved;
    if (hasSession != null) result.hasSession = hasSession;
    if (problem != null) result.problem = problem;
    if (removalProblem != null) result.removalProblem = removalProblem;
    if (diagnosticReport != null) result.diagnosticReport = diagnosticReport;
    return result;
  }

  CredentialStorageStatus._();

  factory CredentialStorageStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CredentialStorageStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CredentialStorageStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<CredentialStorageKind>(1, _omitFieldNames ? '' : 'storage',
        enumValues: CredentialStorageKind.values)
    ..aE<CredentialStorageMode>(2, _omitFieldNames ? '' : 'mode',
        enumValues: CredentialStorageMode.values)
    ..aE<CredentialPresence>(3, _omitFieldNames ? '' : 'saved',
        enumValues: CredentialPresence.values)
    ..aOB(4, _omitFieldNames ? '' : 'hasSession')
    ..aE<CredentialStorageProblem>(5, _omitFieldNames ? '' : 'problem',
        enumValues: CredentialStorageProblem.values)
    ..aE<CredentialStorageProblem>(6, _omitFieldNames ? '' : 'removalProblem',
        enumValues: CredentialStorageProblem.values)
    ..aOS(7, _omitFieldNames ? '' : 'diagnosticReport')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CredentialStorageStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CredentialStorageStatus copyWith(
          void Function(CredentialStorageStatus) updates) =>
      super.copyWith((message) => updates(message as CredentialStorageStatus))
          as CredentialStorageStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CredentialStorageStatus create() => CredentialStorageStatus._();
  @$core.override
  CredentialStorageStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CredentialStorageStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CredentialStorageStatus>(create);
  static CredentialStorageStatus? _defaultInstance;

  @$pb.TagNumber(1)
  CredentialStorageKind get storage => $_getN(0);
  @$pb.TagNumber(1)
  set storage(CredentialStorageKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStorage() => $_has(0);
  @$pb.TagNumber(1)
  void clearStorage() => $_clearField(1);

  @$pb.TagNumber(2)
  CredentialStorageMode get mode => $_getN(1);
  @$pb.TagNumber(2)
  set mode(CredentialStorageMode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => $_clearField(2);

  @$pb.TagNumber(3)
  CredentialPresence get saved => $_getN(2);
  @$pb.TagNumber(3)
  set saved(CredentialPresence value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSaved() => $_has(2);
  @$pb.TagNumber(3)
  void clearSaved() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get hasSession => $_getBF(3);
  @$pb.TagNumber(4)
  set hasSession($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHasSession() => $_has(3);
  @$pb.TagNumber(4)
  void clearHasSession() => $_clearField(4);

  @$pb.TagNumber(5)
  CredentialStorageProblem get problem => $_getN(4);
  @$pb.TagNumber(5)
  set problem(CredentialStorageProblem value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasProblem() => $_has(4);
  @$pb.TagNumber(5)
  void clearProblem() => $_clearField(5);

  @$pb.TagNumber(6)
  CredentialStorageProblem get removalProblem => $_getN(5);
  @$pb.TagNumber(6)
  set removalProblem(CredentialStorageProblem value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRemovalProblem() => $_has(5);
  @$pb.TagNumber(6)
  void clearRemovalProblem() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get diagnosticReport => $_getSZ(6);
  @$pb.TagNumber(7)
  set diagnosticReport($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDiagnosticReport() => $_has(6);
  @$pb.TagNumber(7)
  void clearDiagnosticReport() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
