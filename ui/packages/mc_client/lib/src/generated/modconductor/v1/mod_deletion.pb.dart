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

import 'mod_deletion.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'mod_deletion.pbenum.dart';

class PrepareModDeletionRequest extends $pb.GeneratedMessage {
  factory PrepareModDeletionRequest({
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

  PrepareModDeletionRequest._();

  factory PrepareModDeletionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrepareModDeletionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrepareModDeletionRequest',
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
  PrepareModDeletionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareModDeletionRequest copyWith(
          void Function(PrepareModDeletionRequest) updates) =>
      super.copyWith((message) => updates(message as PrepareModDeletionRequest))
          as PrepareModDeletionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrepareModDeletionRequest create() => PrepareModDeletionRequest._();
  @$core.override
  PrepareModDeletionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PrepareModDeletionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrepareModDeletionRequest>(create);
  static PrepareModDeletionRequest? _defaultInstance;

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

class ModDeletionReference extends $pb.GeneratedMessage {
  factory ModDeletionReference({
    $core.String? workspaceId,
    $core.String? id,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    return result;
  }

  ModDeletionReference._();

  factory ModDeletionReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModDeletionReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModDeletionReference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionReference copyWith(void Function(ModDeletionReference) updates) =>
      super.copyWith((message) => updates(message as ModDeletionReference))
          as ModDeletionReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModDeletionReference create() => ModDeletionReference._();
  @$core.override
  ModDeletionReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModDeletionReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModDeletionReference>(create);
  static ModDeletionReference? _defaultInstance;

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

class ModDeletionWorkspace extends $pb.GeneratedMessage {
  factory ModDeletionWorkspace({
    $core.String? workspaceId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    return result;
  }

  ModDeletionWorkspace._();

  factory ModDeletionWorkspace.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModDeletionWorkspace.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModDeletionWorkspace',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionWorkspace clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionWorkspace copyWith(void Function(ModDeletionWorkspace) updates) =>
      super.copyWith((message) => updates(message as ModDeletionWorkspace))
          as ModDeletionWorkspace;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModDeletionWorkspace create() => ModDeletionWorkspace._();
  @$core.override
  ModDeletionWorkspace createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModDeletionWorkspace getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModDeletionWorkspace>(create);
  static ModDeletionWorkspace? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);
}

class ModDeletionPreviewClosed extends $pb.GeneratedMessage {
  factory ModDeletionPreviewClosed() => create();

  ModDeletionPreviewClosed._();

  factory ModDeletionPreviewClosed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModDeletionPreviewClosed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModDeletionPreviewClosed',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionPreviewClosed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionPreviewClosed copyWith(
          void Function(ModDeletionPreviewClosed) updates) =>
      super.copyWith((message) => updates(message as ModDeletionPreviewClosed))
          as ModDeletionPreviewClosed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModDeletionPreviewClosed create() => ModDeletionPreviewClosed._();
  @$core.override
  ModDeletionPreviewClosed createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModDeletionPreviewClosed getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModDeletionPreviewClosed>(create);
  static ModDeletionPreviewClosed? _defaultInstance;
}

class StartModDeletionRequest extends $pb.GeneratedMessage {
  factory StartModDeletionRequest({
    $core.String? workspaceId,
    $core.String? previewId,
    $core.String? id,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (previewId != null) result.previewId = previewId;
    if (id != null) result.id = id;
    return result;
  }

  StartModDeletionRequest._();

  factory StartModDeletionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartModDeletionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartModDeletionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'previewId')
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartModDeletionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartModDeletionRequest copyWith(
          void Function(StartModDeletionRequest) updates) =>
      super.copyWith((message) => updates(message as StartModDeletionRequest))
          as StartModDeletionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartModDeletionRequest create() => StartModDeletionRequest._();
  @$core.override
  StartModDeletionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartModDeletionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartModDeletionRequest>(create);
  static StartModDeletionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get previewId => $_getSZ(1);
  @$pb.TagNumber(2)
  set previewId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPreviewId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreviewId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => $_clearField(3);
}

class ModDeletionFile extends $pb.GeneratedMessage {
  factory ModDeletionFile({
    $core.String? label,
    ModDeletionFileKind? kind,
    $fixnum.Int64? bytes,
    $core.bool? shared,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (kind != null) result.kind = kind;
    if (bytes != null) result.bytes = bytes;
    if (shared != null) result.shared = shared;
    return result;
  }

  ModDeletionFile._();

  factory ModDeletionFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModDeletionFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModDeletionFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aE<ModDeletionFileKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: ModDeletionFileKind.values)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(4, _omitFieldNames ? '' : 'shared')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionFile copyWith(void Function(ModDeletionFile) updates) =>
      super.copyWith((message) => updates(message as ModDeletionFile))
          as ModDeletionFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModDeletionFile create() => ModDeletionFile._();
  @$core.override
  ModDeletionFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModDeletionFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModDeletionFile>(create);
  static ModDeletionFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  ModDeletionFileKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(ModDeletionFileKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get bytes => $_getI64(2);
  @$pb.TagNumber(3)
  set bytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get shared => $_getBF(3);
  @$pb.TagNumber(4)
  set shared($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasShared() => $_has(3);
  @$pb.TagNumber(4)
  void clearShared() => $_clearField(4);
}

class ModDeletionProfile extends $pb.GeneratedMessage {
  factory ModDeletionProfile({
    $core.String? id,
    $core.String? name,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    return result;
  }

  ModDeletionProfile._();

  factory ModDeletionProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModDeletionProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModDeletionProfile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionProfile copyWith(void Function(ModDeletionProfile) updates) =>
      super.copyWith((message) => updates(message as ModDeletionProfile))
          as ModDeletionProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModDeletionProfile create() => ModDeletionProfile._();
  @$core.override
  ModDeletionProfile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModDeletionProfile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModDeletionProfile>(create);
  static ModDeletionProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class ModDeletionDeployment extends $pb.GeneratedMessage {
  factory ModDeletionDeployment({
    $core.String? contextId,
    $core.String? id,
    $core.String? name,
    $fixnum.Int64? preparedAtUnixMs,
    $core.bool? active,
  }) {
    final result = create();
    if (contextId != null) result.contextId = contextId;
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (preparedAtUnixMs != null) result.preparedAtUnixMs = preparedAtUnixMs;
    if (active != null) result.active = active;
    return result;
  }

  ModDeletionDeployment._();

  factory ModDeletionDeployment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModDeletionDeployment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModDeletionDeployment',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'contextId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aInt64(4, _omitFieldNames ? '' : 'preparedAtUnixMs')
    ..aOB(5, _omitFieldNames ? '' : 'active')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionDeployment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionDeployment copyWith(
          void Function(ModDeletionDeployment) updates) =>
      super.copyWith((message) => updates(message as ModDeletionDeployment))
          as ModDeletionDeployment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModDeletionDeployment create() => ModDeletionDeployment._();
  @$core.override
  ModDeletionDeployment createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModDeletionDeployment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModDeletionDeployment>(create);
  static ModDeletionDeployment? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get contextId => $_getSZ(0);
  @$pb.TagNumber(1)
  set contextId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContextId() => $_has(0);
  @$pb.TagNumber(1)
  void clearContextId() => $_clearField(1);

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
  $fixnum.Int64 get preparedAtUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set preparedAtUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPreparedAtUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearPreparedAtUnixMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get active => $_getBF(4);
  @$pb.TagNumber(5)
  set active($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasActive() => $_has(4);
  @$pb.TagNumber(5)
  void clearActive() => $_clearField(5);
}

class ModDeletionPreview extends $pb.GeneratedMessage {
  factory ModDeletionPreview({
    $core.String? id,
    $core.String? workspaceId,
    $core.String? modId,
    $fixnum.Int64? revision,
    $core.String? name,
    $core.int? versions,
    $core.Iterable<$core.String>? backups,
    $core.Iterable<ModDeletionProfile>? profiles,
    $core.Iterable<ModDeletionDeployment>? deployments,
    $core.Iterable<ModDeletionFile>? files,
    $core.Iterable<$core.String>? external,
    $core.String? blocked,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (modId != null) result.modId = modId;
    if (revision != null) result.revision = revision;
    if (name != null) result.name = name;
    if (versions != null) result.versions = versions;
    if (backups != null) result.backups.addAll(backups);
    if (profiles != null) result.profiles.addAll(profiles);
    if (deployments != null) result.deployments.addAll(deployments);
    if (files != null) result.files.addAll(files);
    if (external != null) result.external.addAll(external);
    if (blocked != null) result.blocked = blocked;
    return result;
  }

  ModDeletionPreview._();

  factory ModDeletionPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModDeletionPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModDeletionPreview',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(5, _omitFieldNames ? '' : 'name')
    ..aI(6, _omitFieldNames ? '' : 'versions', fieldType: $pb.PbFieldType.OU3)
    ..pPS(7, _omitFieldNames ? '' : 'backups')
    ..pPM<ModDeletionProfile>(8, _omitFieldNames ? '' : 'profiles',
        subBuilder: ModDeletionProfile.create)
    ..pPM<ModDeletionDeployment>(9, _omitFieldNames ? '' : 'deployments',
        subBuilder: ModDeletionDeployment.create)
    ..pPM<ModDeletionFile>(10, _omitFieldNames ? '' : 'files',
        subBuilder: ModDeletionFile.create)
    ..pPS(11, _omitFieldNames ? '' : 'external')
    ..aOS(12, _omitFieldNames ? '' : 'blocked')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionPreview copyWith(void Function(ModDeletionPreview) updates) =>
      super.copyWith((message) => updates(message as ModDeletionPreview))
          as ModDeletionPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModDeletionPreview create() => ModDeletionPreview._();
  @$core.override
  ModDeletionPreview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModDeletionPreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModDeletionPreview>(create);
  static ModDeletionPreview? _defaultInstance;

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
  $core.String get modId => $_getSZ(2);
  @$pb.TagNumber(3)
  set modId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModId() => $_has(2);
  @$pb.TagNumber(3)
  void clearModId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get revision => $_getI64(3);
  @$pb.TagNumber(4)
  set revision($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRevision() => $_has(3);
  @$pb.TagNumber(4)
  void clearRevision() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get versions => $_getIZ(5);
  @$pb.TagNumber(6)
  set versions($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVersions() => $_has(5);
  @$pb.TagNumber(6)
  void clearVersions() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get backups => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<ModDeletionProfile> get profiles => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbList<ModDeletionDeployment> get deployments => $_getList(8);

  @$pb.TagNumber(10)
  $pb.PbList<ModDeletionFile> get files => $_getList(9);

  @$pb.TagNumber(11)
  $pb.PbList<$core.String> get external => $_getList(10);

  @$pb.TagNumber(12)
  $core.String get blocked => $_getSZ(11);
  @$pb.TagNumber(12)
  set blocked($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasBlocked() => $_has(11);
  @$pb.TagNumber(12)
  void clearBlocked() => $_clearField(12);
}

class ModDeletionStatus extends $pb.GeneratedMessage {
  factory ModDeletionStatus({
    $core.String? id,
    $core.String? workspaceId,
    $core.String? modId,
    $core.String? name,
    ModDeletionPhase? phase,
    $core.int? remaining,
    $core.String? problem,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (modId != null) result.modId = modId;
    if (name != null) result.name = name;
    if (phase != null) result.phase = phase;
    if (remaining != null) result.remaining = remaining;
    if (problem != null) result.problem = problem;
    return result;
  }

  ModDeletionStatus._();

  factory ModDeletionStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModDeletionStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModDeletionStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'modId')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aE<ModDeletionPhase>(5, _omitFieldNames ? '' : 'phase',
        enumValues: ModDeletionPhase.values)
    ..aI(6, _omitFieldNames ? '' : 'remaining', fieldType: $pb.PbFieldType.OU3)
    ..aOS(7, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionStatus copyWith(void Function(ModDeletionStatus) updates) =>
      super.copyWith((message) => updates(message as ModDeletionStatus))
          as ModDeletionStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModDeletionStatus create() => ModDeletionStatus._();
  @$core.override
  ModDeletionStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModDeletionStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModDeletionStatus>(create);
  static ModDeletionStatus? _defaultInstance;

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
  $core.String get modId => $_getSZ(2);
  @$pb.TagNumber(3)
  set modId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModId() => $_has(2);
  @$pb.TagNumber(3)
  void clearModId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  ModDeletionPhase get phase => $_getN(4);
  @$pb.TagNumber(5)
  set phase(ModDeletionPhase value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPhase() => $_has(4);
  @$pb.TagNumber(5)
  void clearPhase() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get remaining => $_getIZ(5);
  @$pb.TagNumber(6)
  set remaining($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRemaining() => $_has(5);
  @$pb.TagNumber(6)
  void clearRemaining() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get problem => $_getSZ(6);
  @$pb.TagNumber(7)
  set problem($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProblem() => $_has(6);
  @$pb.TagNumber(7)
  void clearProblem() => $_clearField(7);
}

class ModDeletionList extends $pb.GeneratedMessage {
  factory ModDeletionList({
    $core.Iterable<ModDeletionStatus>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  ModDeletionList._();

  factory ModDeletionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModDeletionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModDeletionList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<ModDeletionStatus>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: ModDeletionStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModDeletionList copyWith(void Function(ModDeletionList) updates) =>
      super.copyWith((message) => updates(message as ModDeletionList))
          as ModDeletionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModDeletionList create() => ModDeletionList._();
  @$core.override
  ModDeletionList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModDeletionList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModDeletionList>(create);
  static ModDeletionList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ModDeletionStatus> get entries => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
