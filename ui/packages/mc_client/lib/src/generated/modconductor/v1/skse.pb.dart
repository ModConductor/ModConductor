// This is a generated file - do not edit.
//
// Generated from modconductor/v1/skse.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'skse.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'skse.pbenum.dart';

class SkseRequest extends $pb.GeneratedMessage {
  factory SkseRequest({
    $core.String? workspaceId,
    $core.String? profileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  SkseRequest._();

  factory SkseRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkseRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkseRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkseRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkseRequest copyWith(void Function(SkseRequest) updates) =>
      super.copyWith((message) => updates(message as SkseRequest))
          as SkseRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkseRequest create() => SkseRequest._();
  @$core.override
  SkseRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkseRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkseRequest>(create);
  static SkseRequest? _defaultInstance;

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

class SkseState extends $pb.GeneratedMessage {
  factory SkseState({
    SksePhase? phase,
    $core.String? gameVersion,
    $core.String? componentVersion,
    $core.String? status,
    $core.String? detail,
    $fixnum.Int64? nexusFileId,
  }) {
    final result = create();
    if (phase != null) result.phase = phase;
    if (gameVersion != null) result.gameVersion = gameVersion;
    if (componentVersion != null) result.componentVersion = componentVersion;
    if (status != null) result.status = status;
    if (detail != null) result.detail = detail;
    if (nexusFileId != null) result.nexusFileId = nexusFileId;
    return result;
  }

  SkseState._();

  factory SkseState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkseState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkseState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<SksePhase>(1, _omitFieldNames ? '' : 'phase',
        enumValues: SksePhase.values)
    ..aOS(2, _omitFieldNames ? '' : 'gameVersion')
    ..aOS(3, _omitFieldNames ? '' : 'componentVersion')
    ..aOS(4, _omitFieldNames ? '' : 'status')
    ..aOS(5, _omitFieldNames ? '' : 'detail')
    ..aInt64(6, _omitFieldNames ? '' : 'nexusFileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkseState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkseState copyWith(void Function(SkseState) updates) =>
      super.copyWith((message) => updates(message as SkseState)) as SkseState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkseState create() => SkseState._();
  @$core.override
  SkseState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkseState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SkseState>(create);
  static SkseState? _defaultInstance;

  @$pb.TagNumber(1)
  SksePhase get phase => $_getN(0);
  @$pb.TagNumber(1)
  set phase(SksePhase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPhase() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhase() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get gameVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set gameVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGameVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearGameVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get componentVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set componentVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasComponentVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearComponentVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get status => $_getSZ(3);
  @$pb.TagNumber(4)
  set status($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatus() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get detail => $_getSZ(4);
  @$pb.TagNumber(5)
  set detail($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDetail() => $_has(4);
  @$pb.TagNumber(5)
  void clearDetail() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get nexusFileId => $_getI64(5);
  @$pb.TagNumber(6)
  set nexusFileId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNexusFileId() => $_has(5);
  @$pb.TagNumber(6)
  void clearNexusFileId() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
