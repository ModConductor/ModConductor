// This is a generated file - do not edit.
//
// Generated from modconductor/v1/downloads.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'downloads.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'downloads.pbenum.dart';

class DownloadStartRequest extends $pb.GeneratedMessage {
  factory DownloadStartRequest({
    $core.String? workspaceId,
    $core.String? id,
    $core.String? name,
    $core.Iterable<$core.String>? sources,
    $fixnum.Int64? expectedLength,
    $core.String? expectedSha256,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (sources != null) result.sources.addAll(sources);
    if (expectedLength != null) result.expectedLength = expectedLength;
    if (expectedSha256 != null) result.expectedSha256 = expectedSha256;
    return result;
  }

  DownloadStartRequest._();

  factory DownloadStartRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadStartRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadStartRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..pPS(4, _omitFieldNames ? '' : 'sources')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'expectedLength', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(6, _omitFieldNames ? '' : 'expectedSha256')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadStartRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadStartRequest copyWith(void Function(DownloadStartRequest) updates) =>
      super.copyWith((message) => updates(message as DownloadStartRequest))
          as DownloadStartRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadStartRequest create() => DownloadStartRequest._();
  @$core.override
  DownloadStartRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadStartRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadStartRequest>(create);
  static DownloadStartRequest? _defaultInstance;

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
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get sources => $_getList(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get expectedLength => $_getI64(4);
  @$pb.TagNumber(5)
  set expectedLength($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExpectedLength() => $_has(4);
  @$pb.TagNumber(5)
  void clearExpectedLength() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get expectedSha256 => $_getSZ(5);
  @$pb.TagNumber(6)
  set expectedSha256($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasExpectedSha256() => $_has(5);
  @$pb.TagNumber(6)
  void clearExpectedSha256() => $_clearField(6);
}

class DownloadControlRequest extends $pb.GeneratedMessage {
  factory DownloadControlRequest({
    $core.String? workspaceId,
    $core.String? id,
    DownloadCommand? command,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    if (command != null) result.command = command;
    return result;
  }

  DownloadControlRequest._();

  factory DownloadControlRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadControlRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadControlRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aE<DownloadCommand>(3, _omitFieldNames ? '' : 'command',
        enumValues: DownloadCommand.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadControlRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadControlRequest copyWith(
          void Function(DownloadControlRequest) updates) =>
      super.copyWith((message) => updates(message as DownloadControlRequest))
          as DownloadControlRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadControlRequest create() => DownloadControlRequest._();
  @$core.override
  DownloadControlRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadControlRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadControlRequest>(create);
  static DownloadControlRequest? _defaultInstance;

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
  DownloadCommand get command => $_getN(2);
  @$pb.TagNumber(3)
  set command(DownloadCommand value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCommand() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommand() => $_clearField(3);
}

class DownloadWatchRequest extends $pb.GeneratedMessage {
  factory DownloadWatchRequest({
    $core.String? workspaceId,
    $core.Iterable<$core.String>? ids,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (ids != null) result.ids.addAll(ids);
    return result;
  }

  DownloadWatchRequest._();

  factory DownloadWatchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadWatchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadWatchRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..pPS(2, _omitFieldNames ? '' : 'ids')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadWatchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadWatchRequest copyWith(void Function(DownloadWatchRequest) updates) =>
      super.copyWith((message) => updates(message as DownloadWatchRequest))
          as DownloadWatchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadWatchRequest create() => DownloadWatchRequest._();
  @$core.override
  DownloadWatchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadWatchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadWatchRequest>(create);
  static DownloadWatchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get ids => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
