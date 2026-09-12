// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_updates.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'archive_installation.pb.dart' as $1;
import 'mod_library.pb.dart' as $2;
import 'mod_updates.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'mod_updates.pbenum.dart';

class PrepareModUpdateRequest extends $pb.GeneratedMessage {
  factory PrepareModUpdateRequest({
    $1.InstallationDraftReference? draft,
    $core.String? modId,
    $fixnum.Int64? revision,
    ModUpdateMode? mode,
    $core.Iterable<$2.ModLogicalPath>? keep,
    $core.String? version,
  }) {
    final result = create();
    if (draft != null) result.draft = draft;
    if (modId != null) result.modId = modId;
    if (revision != null) result.revision = revision;
    if (mode != null) result.mode = mode;
    if (keep != null) result.keep.addAll(keep);
    if (version != null) result.version = version;
    return result;
  }

  PrepareModUpdateRequest._();

  factory PrepareModUpdateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrepareModUpdateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrepareModUpdateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.InstallationDraftReference>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: $1.InstallationDraftReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<ModUpdateMode>(4, _omitFieldNames ? '' : 'mode',
        enumValues: ModUpdateMode.values)
    ..pPM<$2.ModLogicalPath>(5, _omitFieldNames ? '' : 'keep',
        subBuilder: $2.ModLogicalPath.create)
    ..aOS(6, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareModUpdateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareModUpdateRequest copyWith(
          void Function(PrepareModUpdateRequest) updates) =>
      super.copyWith((message) => updates(message as PrepareModUpdateRequest))
          as PrepareModUpdateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrepareModUpdateRequest create() => PrepareModUpdateRequest._();
  @$core.override
  PrepareModUpdateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PrepareModUpdateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrepareModUpdateRequest>(create);
  static PrepareModUpdateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.InstallationDraftReference get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft($1.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.InstallationDraftReference ensureDraft() => $_ensure(0);

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

  @$pb.TagNumber(4)
  ModUpdateMode get mode => $_getN(3);
  @$pb.TagNumber(4)
  set mode(ModUpdateMode value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMode() => $_has(3);
  @$pb.TagNumber(4)
  void clearMode() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$2.ModLogicalPath> get keep => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get version => $_getSZ(5);
  @$pb.TagNumber(6)
  set version($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearVersion() => $_clearField(6);
}

class ModUpdateFile extends $pb.GeneratedMessage {
  factory ModUpdateFile({
    $2.ModLogicalPath? path,
    ModUpdateChange? change,
    $fixnum.Int64? existingBytes,
    $fixnum.Int64? incomingBytes,
    $core.Iterable<$2.ModLogicalPath>? existingPaths,
    $core.bool? hasIncoming,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (change != null) result.change = change;
    if (existingBytes != null) result.existingBytes = existingBytes;
    if (incomingBytes != null) result.incomingBytes = incomingBytes;
    if (existingPaths != null) result.existingPaths.addAll(existingPaths);
    if (hasIncoming != null) result.hasIncoming = hasIncoming;
    return result;
  }

  ModUpdateFile._();

  factory ModUpdateFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModUpdateFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModUpdateFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$2.ModLogicalPath>(1, _omitFieldNames ? '' : 'path',
        subBuilder: $2.ModLogicalPath.create)
    ..aE<ModUpdateChange>(2, _omitFieldNames ? '' : 'change',
        enumValues: ModUpdateChange.values)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'existingBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'incomingBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<$2.ModLogicalPath>(5, _omitFieldNames ? '' : 'existingPaths',
        subBuilder: $2.ModLogicalPath.create)
    ..aOB(6, _omitFieldNames ? '' : 'hasIncoming')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModUpdateFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModUpdateFile copyWith(void Function(ModUpdateFile) updates) =>
      super.copyWith((message) => updates(message as ModUpdateFile))
          as ModUpdateFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModUpdateFile create() => ModUpdateFile._();
  @$core.override
  ModUpdateFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModUpdateFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModUpdateFile>(create);
  static ModUpdateFile? _defaultInstance;

  @$pb.TagNumber(1)
  $2.ModLogicalPath get path => $_getN(0);
  @$pb.TagNumber(1)
  set path($2.ModLogicalPath value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.ModLogicalPath ensurePath() => $_ensure(0);

  @$pb.TagNumber(2)
  ModUpdateChange get change => $_getN(1);
  @$pb.TagNumber(2)
  set change(ModUpdateChange value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasChange() => $_has(1);
  @$pb.TagNumber(2)
  void clearChange() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get existingBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set existingBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExistingBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearExistingBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get incomingBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set incomingBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIncomingBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearIncomingBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$2.ModLogicalPath> get existingPaths => $_getList(4);

  @$pb.TagNumber(6)
  $core.bool get hasIncoming => $_getBF(5);
  @$pb.TagNumber(6)
  set hasIncoming($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHasIncoming() => $_has(5);
  @$pb.TagNumber(6)
  void clearHasIncoming() => $_clearField(6);
}

class ModUpdatePreview extends $pb.GeneratedMessage {
  factory ModUpdatePreview({
    $core.String? id,
    $core.String? workspaceId,
    $core.String? modId,
    $core.String? name,
    $core.String? currentVersion,
    $core.String? nextVersion,
    ModUpdateMode? mode,
    $core.Iterable<ModUpdateFile>? files,
    $core.Iterable<$2.ModLogicalPath>? keep,
    $fixnum.Int64? requiredBytes,
    $core.Iterable<$core.String>? sourceNotices,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (modId != null) result.modId = modId;
    if (name != null) result.name = name;
    if (currentVersion != null) result.currentVersion = currentVersion;
    if (nextVersion != null) result.nextVersion = nextVersion;
    if (mode != null) result.mode = mode;
    if (files != null) result.files.addAll(files);
    if (keep != null) result.keep.addAll(keep);
    if (requiredBytes != null) result.requiredBytes = requiredBytes;
    if (sourceNotices != null) result.sourceNotices.addAll(sourceNotices);
    return result;
  }

  ModUpdatePreview._();

  factory ModUpdatePreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModUpdatePreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModUpdatePreview',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'modId')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'currentVersion')
    ..aOS(6, _omitFieldNames ? '' : 'nextVersion')
    ..aE<ModUpdateMode>(7, _omitFieldNames ? '' : 'mode',
        enumValues: ModUpdateMode.values)
    ..pPM<ModUpdateFile>(8, _omitFieldNames ? '' : 'files',
        subBuilder: ModUpdateFile.create)
    ..pPM<$2.ModLogicalPath>(9, _omitFieldNames ? '' : 'keep',
        subBuilder: $2.ModLogicalPath.create)
    ..a<$fixnum.Int64>(
        10, _omitFieldNames ? '' : 'requiredBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPS(11, _omitFieldNames ? '' : 'sourceNotices')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModUpdatePreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModUpdatePreview copyWith(void Function(ModUpdatePreview) updates) =>
      super.copyWith((message) => updates(message as ModUpdatePreview))
          as ModUpdatePreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModUpdatePreview create() => ModUpdatePreview._();
  @$core.override
  ModUpdatePreview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModUpdatePreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModUpdatePreview>(create);
  static ModUpdatePreview? _defaultInstance;

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
  $core.String get currentVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set currentVersion($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCurrentVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearCurrentVersion() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get nextVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set nextVersion($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNextVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearNextVersion() => $_clearField(6);

  @$pb.TagNumber(7)
  ModUpdateMode get mode => $_getN(6);
  @$pb.TagNumber(7)
  set mode(ModUpdateMode value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMode() => $_has(6);
  @$pb.TagNumber(7)
  void clearMode() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<ModUpdateFile> get files => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbList<$2.ModLogicalPath> get keep => $_getList(8);

  @$pb.TagNumber(10)
  $fixnum.Int64 get requiredBytes => $_getI64(9);
  @$pb.TagNumber(10)
  set requiredBytes($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRequiredBytes() => $_has(9);
  @$pb.TagNumber(10)
  void clearRequiredBytes() => $_clearField(10);

  @$pb.TagNumber(11)
  $pb.PbList<$core.String> get sourceNotices => $_getList(10);
}

class StartModUpdateRequest extends $pb.GeneratedMessage {
  factory StartModUpdateRequest({
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

  StartModUpdateRequest._();

  factory StartModUpdateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartModUpdateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartModUpdateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'previewId')
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartModUpdateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartModUpdateRequest copyWith(
          void Function(StartModUpdateRequest) updates) =>
      super.copyWith((message) => updates(message as StartModUpdateRequest))
          as StartModUpdateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartModUpdateRequest create() => StartModUpdateRequest._();
  @$core.override
  StartModUpdateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartModUpdateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartModUpdateRequest>(create);
  static StartModUpdateRequest? _defaultInstance;

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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
