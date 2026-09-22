// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_deletion.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class DeleteModRequest extends $pb.GeneratedMessage {
  factory DeleteModRequest({
    $core.String? workspaceId,
    $core.String? modId,
    $fixnum.Int64? revision,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (modId != null) result.modId = modId;
    if (revision != null) result.revision = revision;
    return result;
  }

  DeleteModRequest._();

  factory DeleteModRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteModRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteModRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteModRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteModRequest copyWith(void Function(DeleteModRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteModRequest))
          as DeleteModRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteModRequest create() => DeleteModRequest._();
  @$core.override
  DeleteModRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteModRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteModRequest>(create);
  static DeleteModRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get revision => $_getI64(2);
  @$pb.TagNumber(3)
  set revision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevision() => $_clearField(3);
}

class ModDeleted extends $pb.GeneratedMessage {
  factory ModDeleted() => create();

  ModDeleted._();

  factory ModDeleted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModDeleted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModDeleted',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeleted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeleted copyWith(void Function(ModDeleted) updates) =>
      super.copyWith((message) => updates(message as ModDeleted)) as ModDeleted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModDeleted create() => ModDeleted._();
  @$core.override
  ModDeleted createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModDeleted getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModDeleted>(create);
  static ModDeleted? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
