// This is a generated file - do not edit.
//
// Generated from modconductor/v1/file_plans.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'file_plans.pbenum.dart';
import 'mod_library.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'file_plans.pbenum.dart';

class ManagedFileCopy extends $pb.GeneratedMessage {
  factory ManagedFileCopy({
    $core.String? modId,
    $core.String? versionId,
    $1.ModLogicalPath? path,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (versionId != null) result.versionId = versionId;
    if (path != null) result.path = path;
    return result;
  }

  ManagedFileCopy._();

  factory ManagedFileCopy.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ManagedFileCopy.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ManagedFileCopy',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..aOS(2, _omitFieldNames ? '' : 'versionId')
    ..aOM<$1.ModLogicalPath>(3, _omitFieldNames ? '' : 'path',
        subBuilder: $1.ModLogicalPath.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManagedFileCopy clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManagedFileCopy copyWith(void Function(ManagedFileCopy) updates) =>
      super.copyWith((message) => updates(message as ManagedFileCopy))
          as ManagedFileCopy;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ManagedFileCopy create() => ManagedFileCopy._();
  @$core.override
  ManagedFileCopy createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ManagedFileCopy getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ManagedFileCopy>(create);
  static ManagedFileCopy? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get versionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set versionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.ModLogicalPath get path => $_getN(2);
  @$pb.TagNumber(3)
  set path($1.ModLogicalPath value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearPath() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.ModLogicalPath ensurePath() => $_ensure(2);
}

class FilePlanCursor extends $pb.GeneratedMessage {
  factory FilePlanCursor({
    $core.String? identity,
    $core.int? offset,
  }) {
    final result = create();
    if (identity != null) result.identity = identity;
    if (offset != null) result.offset = offset;
    return result;
  }

  FilePlanCursor._();

  factory FilePlanCursor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanCursor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanCursor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'identity')
    ..aI(2, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanCursor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanCursor copyWith(void Function(FilePlanCursor) updates) =>
      super.copyWith((message) => updates(message as FilePlanCursor))
          as FilePlanCursor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanCursor create() => FilePlanCursor._();
  @$core.override
  FilePlanCursor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanCursor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanCursor>(create);
  static FilePlanCursor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get identity => $_getSZ(0);
  @$pb.TagNumber(1)
  set identity($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdentity() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdentity() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get offset => $_getIZ(1);
  @$pb.TagNumber(2)
  set offset($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);
}

class OpenFilePlanRequest extends $pb.GeneratedMessage {
  factory OpenFilePlanRequest({
    $core.String? profileId,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  OpenFilePlanRequest._();

  factory OpenFilePlanRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenFilePlanRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenFilePlanRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenFilePlanRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenFilePlanRequest copyWith(void Function(OpenFilePlanRequest) updates) =>
      super.copyWith((message) => updates(message as OpenFilePlanRequest))
          as OpenFilePlanRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenFilePlanRequest create() => OpenFilePlanRequest._();
  @$core.override
  OpenFilePlanRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenFilePlanRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenFilePlanRequest>(create);
  static OpenFilePlanRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);
}

class AcquireFilePlanRequest extends $pb.GeneratedMessage {
  factory AcquireFilePlanRequest({
    $core.String? profileId,
    $core.bool? refresh,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (refresh != null) result.refresh = refresh;
    return result;
  }

  AcquireFilePlanRequest._();

  factory AcquireFilePlanRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireFilePlanRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcquireFilePlanRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOB(2, _omitFieldNames ? '' : 'refresh')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireFilePlanRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireFilePlanRequest copyWith(
          void Function(AcquireFilePlanRequest) updates) =>
      super.copyWith((message) => updates(message as AcquireFilePlanRequest))
          as AcquireFilePlanRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireFilePlanRequest create() => AcquireFilePlanRequest._();
  @$core.override
  AcquireFilePlanRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireFilePlanRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcquireFilePlanRequest>(create);
  static AcquireFilePlanRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get refresh => $_getBF(1);
  @$pb.TagNumber(2)
  set refresh($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRefresh() => $_has(1);
  @$pb.TagNumber(2)
  void clearRefresh() => $_clearField(2);
}

class FilePlanRequest extends $pb.GeneratedMessage {
  factory FilePlanRequest({
    $core.String? snapshotId,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    return result;
  }

  FilePlanRequest._();

  factory FilePlanRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanRequest copyWith(void Function(FilePlanRequest) updates) =>
      super.copyWith((message) => updates(message as FilePlanRequest))
          as FilePlanRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanRequest create() => FilePlanRequest._();
  @$core.override
  FilePlanRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanRequest>(create);
  static FilePlanRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);
}

class FilePlanChildrenRequest extends $pb.GeneratedMessage {
  factory FilePlanChildrenRequest({
    $core.String? snapshotId,
    $1.ModLogicalPath? parent,
    $core.String? filter,
    FilePlanCursor? cursor,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (parent != null) result.parent = parent;
    if (filter != null) result.filter = filter;
    if (cursor != null) result.cursor = cursor;
    return result;
  }

  FilePlanChildrenRequest._();

  factory FilePlanChildrenRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanChildrenRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanChildrenRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..aOM<$1.ModLogicalPath>(2, _omitFieldNames ? '' : 'parent',
        subBuilder: $1.ModLogicalPath.create)
    ..aOS(3, _omitFieldNames ? '' : 'filter')
    ..aOM<FilePlanCursor>(4, _omitFieldNames ? '' : 'cursor',
        subBuilder: FilePlanCursor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanChildrenRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanChildrenRequest copyWith(
          void Function(FilePlanChildrenRequest) updates) =>
      super.copyWith((message) => updates(message as FilePlanChildrenRequest))
          as FilePlanChildrenRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanChildrenRequest create() => FilePlanChildrenRequest._();
  @$core.override
  FilePlanChildrenRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanChildrenRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanChildrenRequest>(create);
  static FilePlanChildrenRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.ModLogicalPath get parent => $_getN(1);
  @$pb.TagNumber(2)
  set parent($1.ModLogicalPath value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasParent() => $_has(1);
  @$pb.TagNumber(2)
  void clearParent() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLogicalPath ensureParent() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get filter => $_getSZ(2);
  @$pb.TagNumber(3)
  set filter($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilter() => $_clearField(3);

  @$pb.TagNumber(4)
  FilePlanCursor get cursor => $_getN(3);
  @$pb.TagNumber(4)
  set cursor(FilePlanCursor value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCursor() => $_has(3);
  @$pb.TagNumber(4)
  void clearCursor() => $_clearField(4);
  @$pb.TagNumber(4)
  FilePlanCursor ensureCursor() => $_ensure(3);
}

class FilePlanProblemsRequest extends $pb.GeneratedMessage {
  factory FilePlanProblemsRequest({
    $core.String? snapshotId,
    FilePlanCursor? cursor,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (cursor != null) result.cursor = cursor;
    return result;
  }

  FilePlanProblemsRequest._();

  factory FilePlanProblemsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanProblemsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanProblemsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..aOM<FilePlanCursor>(2, _omitFieldNames ? '' : 'cursor',
        subBuilder: FilePlanCursor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanProblemsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanProblemsRequest copyWith(
          void Function(FilePlanProblemsRequest) updates) =>
      super.copyWith((message) => updates(message as FilePlanProblemsRequest))
          as FilePlanProblemsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanProblemsRequest create() => FilePlanProblemsRequest._();
  @$core.override
  FilePlanProblemsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanProblemsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanProblemsRequest>(create);
  static FilePlanProblemsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);

  @$pb.TagNumber(2)
  FilePlanCursor get cursor => $_getN(1);
  @$pb.TagNumber(2)
  set cursor(FilePlanCursor value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCursor() => $_has(1);
  @$pb.TagNumber(2)
  void clearCursor() => $_clearField(2);
  @$pb.TagNumber(2)
  FilePlanCursor ensureCursor() => $_ensure(1);
}

class InspectFilePlanRequest extends $pb.GeneratedMessage {
  factory InspectFilePlanRequest({
    $core.String? snapshotId,
    $1.ModLogicalPath? target,
    FilePlanCursor? cursor,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (target != null) result.target = target;
    if (cursor != null) result.cursor = cursor;
    return result;
  }

  InspectFilePlanRequest._();

  factory InspectFilePlanRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InspectFilePlanRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InspectFilePlanRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..aOM<$1.ModLogicalPath>(2, _omitFieldNames ? '' : 'target',
        subBuilder: $1.ModLogicalPath.create)
    ..aOM<FilePlanCursor>(3, _omitFieldNames ? '' : 'cursor',
        subBuilder: FilePlanCursor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectFilePlanRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectFilePlanRequest copyWith(
          void Function(InspectFilePlanRequest) updates) =>
      super.copyWith((message) => updates(message as InspectFilePlanRequest))
          as InspectFilePlanRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InspectFilePlanRequest create() => InspectFilePlanRequest._();
  @$core.override
  InspectFilePlanRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InspectFilePlanRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InspectFilePlanRequest>(create);
  static InspectFilePlanRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.ModLogicalPath get target => $_getN(1);
  @$pb.TagNumber(2)
  set target($1.ModLogicalPath value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTarget() => $_has(1);
  @$pb.TagNumber(2)
  void clearTarget() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLogicalPath ensureTarget() => $_ensure(1);

  @$pb.TagNumber(3)
  FilePlanCursor get cursor => $_getN(2);
  @$pb.TagNumber(3)
  set cursor(FilePlanCursor value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCursor() => $_has(2);
  @$pb.TagNumber(3)
  void clearCursor() => $_clearField(3);
  @$pb.TagNumber(3)
  FilePlanCursor ensureCursor() => $_ensure(2);
}

class InspectSavedFileRequest extends $pb.GeneratedMessage {
  factory InspectSavedFileRequest({
    $core.String? snapshotId,
    ManagedFileCopy? copy,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (copy != null) result.copy = copy;
    return result;
  }

  InspectSavedFileRequest._();

  factory InspectSavedFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InspectSavedFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InspectSavedFileRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..aOM<ManagedFileCopy>(2, _omitFieldNames ? '' : 'copy',
        subBuilder: ManagedFileCopy.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectSavedFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectSavedFileRequest copyWith(
          void Function(InspectSavedFileRequest) updates) =>
      super.copyWith((message) => updates(message as InspectSavedFileRequest))
          as InspectSavedFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InspectSavedFileRequest create() => InspectSavedFileRequest._();
  @$core.override
  InspectSavedFileRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InspectSavedFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InspectSavedFileRequest>(create);
  static InspectSavedFileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);

  @$pb.TagNumber(2)
  ManagedFileCopy get copy => $_getN(1);
  @$pb.TagNumber(2)
  set copy(ManagedFileCopy value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCopy() => $_has(1);
  @$pb.TagNumber(2)
  void clearCopy() => $_clearField(2);
  @$pb.TagNumber(2)
  ManagedFileCopy ensureCopy() => $_ensure(1);
}

class ChangeFileVisibilityRequest extends $pb.GeneratedMessage {
  factory ChangeFileVisibilityRequest({
    $core.String? snapshotId,
    ManagedFileCopy? copy,
    $core.bool? hidden,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (copy != null) result.copy = copy;
    if (hidden != null) result.hidden = hidden;
    return result;
  }

  ChangeFileVisibilityRequest._();

  factory ChangeFileVisibilityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangeFileVisibilityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeFileVisibilityRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..aOM<ManagedFileCopy>(2, _omitFieldNames ? '' : 'copy',
        subBuilder: ManagedFileCopy.create)
    ..aOB(3, _omitFieldNames ? '' : 'hidden')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeFileVisibilityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeFileVisibilityRequest copyWith(
          void Function(ChangeFileVisibilityRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ChangeFileVisibilityRequest))
          as ChangeFileVisibilityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeFileVisibilityRequest create() =>
      ChangeFileVisibilityRequest._();
  @$core.override
  ChangeFileVisibilityRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChangeFileVisibilityRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeFileVisibilityRequest>(create);
  static ChangeFileVisibilityRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);

  @$pb.TagNumber(2)
  ManagedFileCopy get copy => $_getN(1);
  @$pb.TagNumber(2)
  set copy(ManagedFileCopy value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCopy() => $_has(1);
  @$pb.TagNumber(2)
  void clearCopy() => $_clearField(2);
  @$pb.TagNumber(2)
  ManagedFileCopy ensureCopy() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get hidden => $_getBF(2);
  @$pb.TagNumber(3)
  set hidden($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHidden() => $_has(2);
  @$pb.TagNumber(3)
  void clearHidden() => $_clearField(3);
}

class FileVisibilityHistoryRequest extends $pb.GeneratedMessage {
  factory FileVisibilityHistoryRequest({
    $core.String? snapshotId,
    ManagedFileCopy? copy,
    $fixnum.Int64? beforeId,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (copy != null) result.copy = copy;
    if (beforeId != null) result.beforeId = beforeId;
    return result;
  }

  FileVisibilityHistoryRequest._();

  factory FileVisibilityHistoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileVisibilityHistoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileVisibilityHistoryRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..aOM<ManagedFileCopy>(2, _omitFieldNames ? '' : 'copy',
        subBuilder: ManagedFileCopy.create)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'beforeId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityHistoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityHistoryRequest copyWith(
          void Function(FileVisibilityHistoryRequest) updates) =>
      super.copyWith(
              (message) => updates(message as FileVisibilityHistoryRequest))
          as FileVisibilityHistoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileVisibilityHistoryRequest create() =>
      FileVisibilityHistoryRequest._();
  @$core.override
  FileVisibilityHistoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileVisibilityHistoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileVisibilityHistoryRequest>(create);
  static FileVisibilityHistoryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);

  @$pb.TagNumber(2)
  ManagedFileCopy get copy => $_getN(1);
  @$pb.TagNumber(2)
  set copy(ManagedFileCopy value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCopy() => $_has(1);
  @$pb.TagNumber(2)
  void clearCopy() => $_clearField(2);
  @$pb.TagNumber(2)
  ManagedFileCopy ensureCopy() => $_ensure(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get beforeId => $_getI64(2);
  @$pb.TagNumber(3)
  set beforeId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBeforeId() => $_has(2);
  @$pb.TagNumber(3)
  void clearBeforeId() => $_clearField(3);
}

class FilePlanState extends $pb.GeneratedMessage {
  factory FilePlanState({
    $core.String? snapshotId,
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? fingerprint,
    $core.bool? loaded,
    $core.bool? stale,
    $core.int? plannedFiles,
    $core.int? absentTargets,
    $core.int? inspectedFiles,
    $core.Iterable<$core.String>? problems,
    $core.int? problemCount,
    $fixnum.Int64? observedAtUnixMs,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (loaded != null) result.loaded = loaded;
    if (stale != null) result.stale = stale;
    if (plannedFiles != null) result.plannedFiles = plannedFiles;
    if (absentTargets != null) result.absentTargets = absentTargets;
    if (inspectedFiles != null) result.inspectedFiles = inspectedFiles;
    if (problems != null) result.problems.addAll(problems);
    if (problemCount != null) result.problemCount = problemCount;
    if (observedAtUnixMs != null) result.observedAtUnixMs = observedAtUnixMs;
    return result;
  }

  FilePlanState._();

  factory FilePlanState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'profileId')
    ..aOS(4, _omitFieldNames ? '' : 'fingerprint')
    ..aOB(5, _omitFieldNames ? '' : 'loaded')
    ..aOB(6, _omitFieldNames ? '' : 'stale')
    ..aI(7, _omitFieldNames ? '' : 'plannedFiles',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'absentTargets',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(9, _omitFieldNames ? '' : 'inspectedFiles',
        fieldType: $pb.PbFieldType.OU3)
    ..pPS(10, _omitFieldNames ? '' : 'problems')
    ..aI(11, _omitFieldNames ? '' : 'problemCount',
        fieldType: $pb.PbFieldType.OU3)
    ..aInt64(12, _omitFieldNames ? '' : 'observedAtUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanState copyWith(void Function(FilePlanState) updates) =>
      super.copyWith((message) => updates(message as FilePlanState))
          as FilePlanState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanState create() => FilePlanState._();
  @$core.override
  FilePlanState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanState>(create);
  static FilePlanState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);

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

  @$pb.TagNumber(4)
  $core.String get fingerprint => $_getSZ(3);
  @$pb.TagNumber(4)
  set fingerprint($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFingerprint() => $_has(3);
  @$pb.TagNumber(4)
  void clearFingerprint() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get loaded => $_getBF(4);
  @$pb.TagNumber(5)
  set loaded($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLoaded() => $_has(4);
  @$pb.TagNumber(5)
  void clearLoaded() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get stale => $_getBF(5);
  @$pb.TagNumber(6)
  set stale($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasStale() => $_has(5);
  @$pb.TagNumber(6)
  void clearStale() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get plannedFiles => $_getIZ(6);
  @$pb.TagNumber(7)
  set plannedFiles($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPlannedFiles() => $_has(6);
  @$pb.TagNumber(7)
  void clearPlannedFiles() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get absentTargets => $_getIZ(7);
  @$pb.TagNumber(8)
  set absentTargets($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAbsentTargets() => $_has(7);
  @$pb.TagNumber(8)
  void clearAbsentTargets() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get inspectedFiles => $_getIZ(8);
  @$pb.TagNumber(9)
  set inspectedFiles($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasInspectedFiles() => $_has(8);
  @$pb.TagNumber(9)
  void clearInspectedFiles() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get problems => $_getList(9);

  @$pb.TagNumber(11)
  $core.int get problemCount => $_getIZ(10);
  @$pb.TagNumber(11)
  set problemCount($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasProblemCount() => $_has(10);
  @$pb.TagNumber(11)
  void clearProblemCount() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get observedAtUnixMs => $_getI64(11);
  @$pb.TagNumber(12)
  set observedAtUnixMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasObservedAtUnixMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearObservedAtUnixMs() => $_clearField(12);
}

class PlannedFileNode extends $pb.GeneratedMessage {
  factory PlannedFileNode({
    $1.ModLogicalPath? path,
    $core.bool? directory,
    PlannedFileDisposition? disposition,
    $core.String? sourceName,
    $core.int? copies,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (directory != null) result.directory = directory;
    if (disposition != null) result.disposition = disposition;
    if (sourceName != null) result.sourceName = sourceName;
    if (copies != null) result.copies = copies;
    return result;
  }

  PlannedFileNode._();

  factory PlannedFileNode.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlannedFileNode.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlannedFileNode',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.ModLogicalPath>(1, _omitFieldNames ? '' : 'path',
        subBuilder: $1.ModLogicalPath.create)
    ..aOB(2, _omitFieldNames ? '' : 'directory')
    ..aE<PlannedFileDisposition>(3, _omitFieldNames ? '' : 'disposition',
        enumValues: PlannedFileDisposition.values)
    ..aOS(4, _omitFieldNames ? '' : 'sourceName')
    ..aI(5, _omitFieldNames ? '' : 'copies', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlannedFileNode clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlannedFileNode copyWith(void Function(PlannedFileNode) updates) =>
      super.copyWith((message) => updates(message as PlannedFileNode))
          as PlannedFileNode;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlannedFileNode create() => PlannedFileNode._();
  @$core.override
  PlannedFileNode createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlannedFileNode getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlannedFileNode>(create);
  static PlannedFileNode? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ModLogicalPath get path => $_getN(0);
  @$pb.TagNumber(1)
  set path($1.ModLogicalPath value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ModLogicalPath ensurePath() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get directory => $_getBF(1);
  @$pb.TagNumber(2)
  set directory($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDirectory() => $_has(1);
  @$pb.TagNumber(2)
  void clearDirectory() => $_clearField(2);

  @$pb.TagNumber(3)
  PlannedFileDisposition get disposition => $_getN(2);
  @$pb.TagNumber(3)
  set disposition(PlannedFileDisposition value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDisposition() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisposition() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sourceName => $_getSZ(3);
  @$pb.TagNumber(4)
  set sourceName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSourceName() => $_has(3);
  @$pb.TagNumber(4)
  void clearSourceName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get copies => $_getIZ(4);
  @$pb.TagNumber(5)
  set copies($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCopies() => $_has(4);
  @$pb.TagNumber(5)
  void clearCopies() => $_clearField(5);
}

class PlannedFilePage extends $pb.GeneratedMessage {
  factory PlannedFilePage({
    FilePlanState? state,
    $core.Iterable<PlannedFileNode>? nodes,
    FilePlanCursor? next,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (nodes != null) result.nodes.addAll(nodes);
    if (next != null) result.next = next;
    return result;
  }

  PlannedFilePage._();

  factory PlannedFilePage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlannedFilePage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlannedFilePage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<FilePlanState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: FilePlanState.create)
    ..pPM<PlannedFileNode>(2, _omitFieldNames ? '' : 'nodes',
        subBuilder: PlannedFileNode.create)
    ..aOM<FilePlanCursor>(3, _omitFieldNames ? '' : 'next',
        subBuilder: FilePlanCursor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlannedFilePage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlannedFilePage copyWith(void Function(PlannedFilePage) updates) =>
      super.copyWith((message) => updates(message as PlannedFilePage))
          as PlannedFilePage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlannedFilePage create() => PlannedFilePage._();
  @$core.override
  PlannedFilePage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlannedFilePage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlannedFilePage>(create);
  static PlannedFilePage? _defaultInstance;

  @$pb.TagNumber(1)
  FilePlanState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(FilePlanState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  FilePlanState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<PlannedFileNode> get nodes => $_getList(1);

  @$pb.TagNumber(3)
  FilePlanCursor get next => $_getN(2);
  @$pb.TagNumber(3)
  set next(FilePlanCursor value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNext() => $_has(2);
  @$pb.TagNumber(3)
  void clearNext() => $_clearField(3);
  @$pb.TagNumber(3)
  FilePlanCursor ensureNext() => $_ensure(2);
}

class InspectedFileCopy extends $pb.GeneratedMessage {
  factory InspectedFileCopy({
    ManagedFileCopy? copy,
    $1.ModLogicalPath? sourcePath,
    $core.String? name,
    $core.String? versionLabel,
    $core.int? priority,
    $core.bool? enabled,
    $core.bool? hidden,
    $core.bool? winner,
    $core.bool? historical,
    $fixnum.Int64? length,
    $core.String? sha256,
    $core.bool? canHide,
    $core.bool? canUnhide,
  }) {
    final result = create();
    if (copy != null) result.copy = copy;
    if (sourcePath != null) result.sourcePath = sourcePath;
    if (name != null) result.name = name;
    if (versionLabel != null) result.versionLabel = versionLabel;
    if (priority != null) result.priority = priority;
    if (enabled != null) result.enabled = enabled;
    if (hidden != null) result.hidden = hidden;
    if (winner != null) result.winner = winner;
    if (historical != null) result.historical = historical;
    if (length != null) result.length = length;
    if (sha256 != null) result.sha256 = sha256;
    if (canHide != null) result.canHide = canHide;
    if (canUnhide != null) result.canUnhide = canUnhide;
    return result;
  }

  InspectedFileCopy._();

  factory InspectedFileCopy.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InspectedFileCopy.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InspectedFileCopy',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ManagedFileCopy>(1, _omitFieldNames ? '' : 'copy',
        subBuilder: ManagedFileCopy.create)
    ..aOM<$1.ModLogicalPath>(2, _omitFieldNames ? '' : 'sourcePath',
        subBuilder: $1.ModLogicalPath.create)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'versionLabel')
    ..aI(5, _omitFieldNames ? '' : 'priority', fieldType: $pb.PbFieldType.OU3)
    ..aOB(6, _omitFieldNames ? '' : 'enabled')
    ..aOB(7, _omitFieldNames ? '' : 'hidden')
    ..aOB(8, _omitFieldNames ? '' : 'winner')
    ..aOB(9, _omitFieldNames ? '' : 'historical')
    ..a<$fixnum.Int64>(10, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(11, _omitFieldNames ? '' : 'sha256')
    ..aOB(12, _omitFieldNames ? '' : 'canHide')
    ..aOB(13, _omitFieldNames ? '' : 'canUnhide')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectedFileCopy clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectedFileCopy copyWith(void Function(InspectedFileCopy) updates) =>
      super.copyWith((message) => updates(message as InspectedFileCopy))
          as InspectedFileCopy;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InspectedFileCopy create() => InspectedFileCopy._();
  @$core.override
  InspectedFileCopy createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InspectedFileCopy getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InspectedFileCopy>(create);
  static InspectedFileCopy? _defaultInstance;

  @$pb.TagNumber(1)
  ManagedFileCopy get copy => $_getN(0);
  @$pb.TagNumber(1)
  set copy(ManagedFileCopy value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCopy() => $_has(0);
  @$pb.TagNumber(1)
  void clearCopy() => $_clearField(1);
  @$pb.TagNumber(1)
  ManagedFileCopy ensureCopy() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ModLogicalPath get sourcePath => $_getN(1);
  @$pb.TagNumber(2)
  set sourcePath($1.ModLogicalPath value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSourcePath() => $_has(1);
  @$pb.TagNumber(2)
  void clearSourcePath() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLogicalPath ensureSourcePath() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get versionLabel => $_getSZ(3);
  @$pb.TagNumber(4)
  set versionLabel($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVersionLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersionLabel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get priority => $_getIZ(4);
  @$pb.TagNumber(5)
  set priority($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPriority() => $_has(4);
  @$pb.TagNumber(5)
  void clearPriority() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get enabled => $_getBF(5);
  @$pb.TagNumber(6)
  set enabled($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEnabled() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnabled() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get hidden => $_getBF(6);
  @$pb.TagNumber(7)
  set hidden($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHidden() => $_has(6);
  @$pb.TagNumber(7)
  void clearHidden() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get winner => $_getBF(7);
  @$pb.TagNumber(8)
  set winner($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWinner() => $_has(7);
  @$pb.TagNumber(8)
  void clearWinner() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get historical => $_getBF(8);
  @$pb.TagNumber(9)
  set historical($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHistorical() => $_has(8);
  @$pb.TagNumber(9)
  void clearHistorical() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get length => $_getI64(9);
  @$pb.TagNumber(10)
  set length($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLength() => $_has(9);
  @$pb.TagNumber(10)
  void clearLength() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get sha256 => $_getSZ(10);
  @$pb.TagNumber(11)
  set sha256($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSha256() => $_has(10);
  @$pb.TagNumber(11)
  void clearSha256() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get canHide => $_getBF(11);
  @$pb.TagNumber(12)
  set canHide($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCanHide() => $_has(11);
  @$pb.TagNumber(12)
  void clearCanHide() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get canUnhide => $_getBF(12);
  @$pb.TagNumber(13)
  set canUnhide($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCanUnhide() => $_has(12);
  @$pb.TagNumber(13)
  void clearCanUnhide() => $_clearField(13);
}

class PlannedFileInspection extends $pb.GeneratedMessage {
  factory PlannedFileInspection({
    FilePlanState? state,
    $1.ModLogicalPath? target,
    $core.Iterable<InspectedFileCopy>? copies,
    FilePlanCursor? next,
    InspectedFileCopy? focusedCopy,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (target != null) result.target = target;
    if (copies != null) result.copies.addAll(copies);
    if (next != null) result.next = next;
    if (focusedCopy != null) result.focusedCopy = focusedCopy;
    return result;
  }

  PlannedFileInspection._();

  factory PlannedFileInspection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlannedFileInspection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlannedFileInspection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<FilePlanState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: FilePlanState.create)
    ..aOM<$1.ModLogicalPath>(2, _omitFieldNames ? '' : 'target',
        subBuilder: $1.ModLogicalPath.create)
    ..pPM<InspectedFileCopy>(3, _omitFieldNames ? '' : 'copies',
        subBuilder: InspectedFileCopy.create)
    ..aOM<FilePlanCursor>(4, _omitFieldNames ? '' : 'next',
        subBuilder: FilePlanCursor.create)
    ..aOM<InspectedFileCopy>(5, _omitFieldNames ? '' : 'focusedCopy',
        subBuilder: InspectedFileCopy.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlannedFileInspection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlannedFileInspection copyWith(
          void Function(PlannedFileInspection) updates) =>
      super.copyWith((message) => updates(message as PlannedFileInspection))
          as PlannedFileInspection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlannedFileInspection create() => PlannedFileInspection._();
  @$core.override
  PlannedFileInspection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlannedFileInspection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlannedFileInspection>(create);
  static PlannedFileInspection? _defaultInstance;

  @$pb.TagNumber(1)
  FilePlanState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(FilePlanState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  FilePlanState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ModLogicalPath get target => $_getN(1);
  @$pb.TagNumber(2)
  set target($1.ModLogicalPath value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTarget() => $_has(1);
  @$pb.TagNumber(2)
  void clearTarget() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLogicalPath ensureTarget() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<InspectedFileCopy> get copies => $_getList(2);

  @$pb.TagNumber(4)
  FilePlanCursor get next => $_getN(3);
  @$pb.TagNumber(4)
  set next(FilePlanCursor value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasNext() => $_has(3);
  @$pb.TagNumber(4)
  void clearNext() => $_clearField(4);
  @$pb.TagNumber(4)
  FilePlanCursor ensureNext() => $_ensure(3);

  @$pb.TagNumber(5)
  InspectedFileCopy get focusedCopy => $_getN(4);
  @$pb.TagNumber(5)
  set focusedCopy(InspectedFileCopy value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasFocusedCopy() => $_has(4);
  @$pb.TagNumber(5)
  void clearFocusedCopy() => $_clearField(5);
  @$pb.TagNumber(5)
  InspectedFileCopy ensureFocusedCopy() => $_ensure(4);
}

class FileVisibilityChange extends $pb.GeneratedMessage {
  factory FileVisibilityChange({
    FilePlanState? state,
    PlannedFileNode? changed,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (changed != null) result.changed = changed;
    return result;
  }

  FileVisibilityChange._();

  factory FileVisibilityChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileVisibilityChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileVisibilityChange',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<FilePlanState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: FilePlanState.create)
    ..aOM<PlannedFileNode>(2, _omitFieldNames ? '' : 'changed',
        subBuilder: PlannedFileNode.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityChange copyWith(void Function(FileVisibilityChange) updates) =>
      super.copyWith((message) => updates(message as FileVisibilityChange))
          as FileVisibilityChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileVisibilityChange create() => FileVisibilityChange._();
  @$core.override
  FileVisibilityChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileVisibilityChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileVisibilityChange>(create);
  static FileVisibilityChange? _defaultInstance;

  @$pb.TagNumber(1)
  FilePlanState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(FilePlanState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  FilePlanState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  PlannedFileNode get changed => $_getN(1);
  @$pb.TagNumber(2)
  set changed(PlannedFileNode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasChanged() => $_has(1);
  @$pb.TagNumber(2)
  void clearChanged() => $_clearField(2);
  @$pb.TagNumber(2)
  PlannedFileNode ensureChanged() => $_ensure(1);
}

class FileVisibilityAudit extends $pb.GeneratedMessage {
  factory FileVisibilityAudit({
    $fixnum.Int64? id,
    ManagedFileCopy? copy,
    $core.bool? hidden,
    $core.bool? beforeHidden,
    $core.String? profileId,
    $core.String? beforeFingerprint,
    $core.String? afterFingerprint,
    $fixnum.Int64? recordedAtUnixMs,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (copy != null) result.copy = copy;
    if (hidden != null) result.hidden = hidden;
    if (beforeHidden != null) result.beforeHidden = beforeHidden;
    if (profileId != null) result.profileId = profileId;
    if (beforeFingerprint != null) result.beforeFingerprint = beforeFingerprint;
    if (afterFingerprint != null) result.afterFingerprint = afterFingerprint;
    if (recordedAtUnixMs != null) result.recordedAtUnixMs = recordedAtUnixMs;
    return result;
  }

  FileVisibilityAudit._();

  factory FileVisibilityAudit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileVisibilityAudit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileVisibilityAudit',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<ManagedFileCopy>(2, _omitFieldNames ? '' : 'copy',
        subBuilder: ManagedFileCopy.create)
    ..aOB(3, _omitFieldNames ? '' : 'hidden')
    ..aOB(4, _omitFieldNames ? '' : 'beforeHidden')
    ..aOS(5, _omitFieldNames ? '' : 'profileId')
    ..aOS(6, _omitFieldNames ? '' : 'beforeFingerprint')
    ..aOS(7, _omitFieldNames ? '' : 'afterFingerprint')
    ..aInt64(8, _omitFieldNames ? '' : 'recordedAtUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityAudit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityAudit copyWith(void Function(FileVisibilityAudit) updates) =>
      super.copyWith((message) => updates(message as FileVisibilityAudit))
          as FileVisibilityAudit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileVisibilityAudit create() => FileVisibilityAudit._();
  @$core.override
  FileVisibilityAudit createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileVisibilityAudit getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileVisibilityAudit>(create);
  static FileVisibilityAudit? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ManagedFileCopy get copy => $_getN(1);
  @$pb.TagNumber(2)
  set copy(ManagedFileCopy value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCopy() => $_has(1);
  @$pb.TagNumber(2)
  void clearCopy() => $_clearField(2);
  @$pb.TagNumber(2)
  ManagedFileCopy ensureCopy() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get hidden => $_getBF(2);
  @$pb.TagNumber(3)
  set hidden($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHidden() => $_has(2);
  @$pb.TagNumber(3)
  void clearHidden() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get beforeHidden => $_getBF(3);
  @$pb.TagNumber(4)
  set beforeHidden($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBeforeHidden() => $_has(3);
  @$pb.TagNumber(4)
  void clearBeforeHidden() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get profileId => $_getSZ(4);
  @$pb.TagNumber(5)
  set profileId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProfileId() => $_has(4);
  @$pb.TagNumber(5)
  void clearProfileId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get beforeFingerprint => $_getSZ(5);
  @$pb.TagNumber(6)
  set beforeFingerprint($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBeforeFingerprint() => $_has(5);
  @$pb.TagNumber(6)
  void clearBeforeFingerprint() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get afterFingerprint => $_getSZ(6);
  @$pb.TagNumber(7)
  set afterFingerprint($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAfterFingerprint() => $_has(6);
  @$pb.TagNumber(7)
  void clearAfterFingerprint() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get recordedAtUnixMs => $_getI64(7);
  @$pb.TagNumber(8)
  set recordedAtUnixMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRecordedAtUnixMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearRecordedAtUnixMs() => $_clearField(8);
}

class FileVisibilityHistory extends $pb.GeneratedMessage {
  factory FileVisibilityHistory({
    $core.Iterable<FileVisibilityAudit>? changes,
    $fixnum.Int64? nextBeforeId,
  }) {
    final result = create();
    if (changes != null) result.changes.addAll(changes);
    if (nextBeforeId != null) result.nextBeforeId = nextBeforeId;
    return result;
  }

  FileVisibilityHistory._();

  factory FileVisibilityHistory.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileVisibilityHistory.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileVisibilityHistory',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<FileVisibilityAudit>(1, _omitFieldNames ? '' : 'changes',
        subBuilder: FileVisibilityAudit.create)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'nextBeforeId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityHistory clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityHistory copyWith(
          void Function(FileVisibilityHistory) updates) =>
      super.copyWith((message) => updates(message as FileVisibilityHistory))
          as FileVisibilityHistory;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileVisibilityHistory create() => FileVisibilityHistory._();
  @$core.override
  FileVisibilityHistory createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileVisibilityHistory getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileVisibilityHistory>(create);
  static FileVisibilityHistory? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<FileVisibilityAudit> get changes => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get nextBeforeId => $_getI64(1);
  @$pb.TagNumber(2)
  set nextBeforeId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextBeforeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextBeforeId() => $_clearField(2);
}

class FilePlanProblems extends $pb.GeneratedMessage {
  factory FilePlanProblems({
    $core.Iterable<$core.String>? problems,
    FilePlanCursor? next,
  }) {
    final result = create();
    if (problems != null) result.problems.addAll(problems);
    if (next != null) result.next = next;
    return result;
  }

  FilePlanProblems._();

  factory FilePlanProblems.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanProblems.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanProblems',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'problems')
    ..aOM<FilePlanCursor>(2, _omitFieldNames ? '' : 'next',
        subBuilder: FilePlanCursor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanProblems clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanProblems copyWith(void Function(FilePlanProblems) updates) =>
      super.copyWith((message) => updates(message as FilePlanProblems))
          as FilePlanProblems;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanProblems create() => FilePlanProblems._();
  @$core.override
  FilePlanProblems createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanProblems getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanProblems>(create);
  static FilePlanProblems? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get problems => $_getList(0);

  @$pb.TagNumber(2)
  FilePlanCursor get next => $_getN(1);
  @$pb.TagNumber(2)
  set next(FilePlanCursor value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNext() => $_has(1);
  @$pb.TagNumber(2)
  void clearNext() => $_clearField(2);
  @$pb.TagNumber(2)
  FilePlanCursor ensureNext() => $_ensure(1);
}

class FilePlanFault extends $pb.GeneratedMessage {
  factory FilePlanFault({
    FilePlanFaultCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  FilePlanFault._();

  factory FilePlanFault.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanFault.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanFault',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<FilePlanFaultCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: FilePlanFaultCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanFault clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanFault copyWith(void Function(FilePlanFault) updates) =>
      super.copyWith((message) => updates(message as FilePlanFault))
          as FilePlanFault;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanFault create() => FilePlanFault._();
  @$core.override
  FilePlanFault createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanFault getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanFault>(create);
  static FilePlanFault? _defaultInstance;

  @$pb.TagNumber(1)
  FilePlanFaultCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(FilePlanFaultCode value) => $_setField(1, value);
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

enum FilePlanReply_Outcome { state, fault, notSet }

class FilePlanReply extends $pb.GeneratedMessage {
  factory FilePlanReply({
    FilePlanState? state,
    FilePlanFault? fault,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (fault != null) result.fault = fault;
    return result;
  }

  FilePlanReply._();

  factory FilePlanReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, FilePlanReply_Outcome>
      _FilePlanReply_OutcomeByTag = {
    1: FilePlanReply_Outcome.state,
    2: FilePlanReply_Outcome.fault,
    0: FilePlanReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<FilePlanState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: FilePlanState.create)
    ..aOM<FilePlanFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: FilePlanFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanReply copyWith(void Function(FilePlanReply) updates) =>
      super.copyWith((message) => updates(message as FilePlanReply))
          as FilePlanReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanReply create() => FilePlanReply._();
  @$core.override
  FilePlanReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanReply>(create);
  static FilePlanReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  FilePlanReply_Outcome whichOutcome() =>
      _FilePlanReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  FilePlanState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(FilePlanState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  FilePlanState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  FilePlanFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(FilePlanFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  FilePlanFault ensureFault() => $_ensure(1);
}

enum FilePlanPageReply_Outcome { page, fault, notSet }

class FilePlanPageReply extends $pb.GeneratedMessage {
  factory FilePlanPageReply({
    PlannedFilePage? page,
    FilePlanFault? fault,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (fault != null) result.fault = fault;
    return result;
  }

  FilePlanPageReply._();

  factory FilePlanPageReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanPageReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, FilePlanPageReply_Outcome>
      _FilePlanPageReply_OutcomeByTag = {
    1: FilePlanPageReply_Outcome.page,
    2: FilePlanPageReply_Outcome.fault,
    0: FilePlanPageReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanPageReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<PlannedFilePage>(1, _omitFieldNames ? '' : 'page',
        subBuilder: PlannedFilePage.create)
    ..aOM<FilePlanFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: FilePlanFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanPageReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanPageReply copyWith(void Function(FilePlanPageReply) updates) =>
      super.copyWith((message) => updates(message as FilePlanPageReply))
          as FilePlanPageReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanPageReply create() => FilePlanPageReply._();
  @$core.override
  FilePlanPageReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanPageReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanPageReply>(create);
  static FilePlanPageReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  FilePlanPageReply_Outcome whichOutcome() =>
      _FilePlanPageReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  PlannedFilePage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(PlannedFilePage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  PlannedFilePage ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  FilePlanFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(FilePlanFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  FilePlanFault ensureFault() => $_ensure(1);
}

enum FilePlanInspectionReply_Outcome { inspection, fault, notSet }

class FilePlanInspectionReply extends $pb.GeneratedMessage {
  factory FilePlanInspectionReply({
    PlannedFileInspection? inspection,
    FilePlanFault? fault,
  }) {
    final result = create();
    if (inspection != null) result.inspection = inspection;
    if (fault != null) result.fault = fault;
    return result;
  }

  FilePlanInspectionReply._();

  factory FilePlanInspectionReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanInspectionReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, FilePlanInspectionReply_Outcome>
      _FilePlanInspectionReply_OutcomeByTag = {
    1: FilePlanInspectionReply_Outcome.inspection,
    2: FilePlanInspectionReply_Outcome.fault,
    0: FilePlanInspectionReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanInspectionReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<PlannedFileInspection>(1, _omitFieldNames ? '' : 'inspection',
        subBuilder: PlannedFileInspection.create)
    ..aOM<FilePlanFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: FilePlanFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanInspectionReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanInspectionReply copyWith(
          void Function(FilePlanInspectionReply) updates) =>
      super.copyWith((message) => updates(message as FilePlanInspectionReply))
          as FilePlanInspectionReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanInspectionReply create() => FilePlanInspectionReply._();
  @$core.override
  FilePlanInspectionReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanInspectionReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanInspectionReply>(create);
  static FilePlanInspectionReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  FilePlanInspectionReply_Outcome whichOutcome() =>
      _FilePlanInspectionReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  PlannedFileInspection get inspection => $_getN(0);
  @$pb.TagNumber(1)
  set inspection(PlannedFileInspection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInspection() => $_has(0);
  @$pb.TagNumber(1)
  void clearInspection() => $_clearField(1);
  @$pb.TagNumber(1)
  PlannedFileInspection ensureInspection() => $_ensure(0);

  @$pb.TagNumber(2)
  FilePlanFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(FilePlanFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  FilePlanFault ensureFault() => $_ensure(1);
}

enum FileVisibilityReply_Outcome { change, fault, notSet }

class FileVisibilityReply extends $pb.GeneratedMessage {
  factory FileVisibilityReply({
    FileVisibilityChange? change,
    FilePlanFault? fault,
  }) {
    final result = create();
    if (change != null) result.change = change;
    if (fault != null) result.fault = fault;
    return result;
  }

  FileVisibilityReply._();

  factory FileVisibilityReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileVisibilityReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, FileVisibilityReply_Outcome>
      _FileVisibilityReply_OutcomeByTag = {
    1: FileVisibilityReply_Outcome.change,
    2: FileVisibilityReply_Outcome.fault,
    0: FileVisibilityReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileVisibilityReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<FileVisibilityChange>(1, _omitFieldNames ? '' : 'change',
        subBuilder: FileVisibilityChange.create)
    ..aOM<FilePlanFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: FilePlanFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityReply copyWith(void Function(FileVisibilityReply) updates) =>
      super.copyWith((message) => updates(message as FileVisibilityReply))
          as FileVisibilityReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileVisibilityReply create() => FileVisibilityReply._();
  @$core.override
  FileVisibilityReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileVisibilityReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileVisibilityReply>(create);
  static FileVisibilityReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  FileVisibilityReply_Outcome whichOutcome() =>
      _FileVisibilityReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  FileVisibilityChange get change => $_getN(0);
  @$pb.TagNumber(1)
  set change(FileVisibilityChange value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasChange() => $_has(0);
  @$pb.TagNumber(1)
  void clearChange() => $_clearField(1);
  @$pb.TagNumber(1)
  FileVisibilityChange ensureChange() => $_ensure(0);

  @$pb.TagNumber(2)
  FilePlanFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(FilePlanFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  FilePlanFault ensureFault() => $_ensure(1);
}

enum FileVisibilityHistoryReply_Outcome { history, fault, notSet }

class FileVisibilityHistoryReply extends $pb.GeneratedMessage {
  factory FileVisibilityHistoryReply({
    FileVisibilityHistory? history,
    FilePlanFault? fault,
  }) {
    final result = create();
    if (history != null) result.history = history;
    if (fault != null) result.fault = fault;
    return result;
  }

  FileVisibilityHistoryReply._();

  factory FileVisibilityHistoryReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FileVisibilityHistoryReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, FileVisibilityHistoryReply_Outcome>
      _FileVisibilityHistoryReply_OutcomeByTag = {
    1: FileVisibilityHistoryReply_Outcome.history,
    2: FileVisibilityHistoryReply_Outcome.fault,
    0: FileVisibilityHistoryReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileVisibilityHistoryReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<FileVisibilityHistory>(1, _omitFieldNames ? '' : 'history',
        subBuilder: FileVisibilityHistory.create)
    ..aOM<FilePlanFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: FilePlanFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityHistoryReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FileVisibilityHistoryReply copyWith(
          void Function(FileVisibilityHistoryReply) updates) =>
      super.copyWith(
              (message) => updates(message as FileVisibilityHistoryReply))
          as FileVisibilityHistoryReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileVisibilityHistoryReply create() => FileVisibilityHistoryReply._();
  @$core.override
  FileVisibilityHistoryReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FileVisibilityHistoryReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FileVisibilityHistoryReply>(create);
  static FileVisibilityHistoryReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  FileVisibilityHistoryReply_Outcome whichOutcome() =>
      _FileVisibilityHistoryReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  FileVisibilityHistory get history => $_getN(0);
  @$pb.TagNumber(1)
  set history(FileVisibilityHistory value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHistory() => $_has(0);
  @$pb.TagNumber(1)
  void clearHistory() => $_clearField(1);
  @$pb.TagNumber(1)
  FileVisibilityHistory ensureHistory() => $_ensure(0);

  @$pb.TagNumber(2)
  FilePlanFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(FilePlanFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  FilePlanFault ensureFault() => $_ensure(1);
}

enum FilePlanProblemsReply_Outcome { problems, fault, notSet }

class FilePlanProblemsReply extends $pb.GeneratedMessage {
  factory FilePlanProblemsReply({
    FilePlanProblems? problems,
    FilePlanFault? fault,
  }) {
    final result = create();
    if (problems != null) result.problems = problems;
    if (fault != null) result.fault = fault;
    return result;
  }

  FilePlanProblemsReply._();

  factory FilePlanProblemsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanProblemsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, FilePlanProblemsReply_Outcome>
      _FilePlanProblemsReply_OutcomeByTag = {
    1: FilePlanProblemsReply_Outcome.problems,
    2: FilePlanProblemsReply_Outcome.fault,
    0: FilePlanProblemsReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanProblemsReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<FilePlanProblems>(1, _omitFieldNames ? '' : 'problems',
        subBuilder: FilePlanProblems.create)
    ..aOM<FilePlanFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: FilePlanFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanProblemsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanProblemsReply copyWith(
          void Function(FilePlanProblemsReply) updates) =>
      super.copyWith((message) => updates(message as FilePlanProblemsReply))
          as FilePlanProblemsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanProblemsReply create() => FilePlanProblemsReply._();
  @$core.override
  FilePlanProblemsReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanProblemsReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanProblemsReply>(create);
  static FilePlanProblemsReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  FilePlanProblemsReply_Outcome whichOutcome() =>
      _FilePlanProblemsReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  FilePlanProblems get problems => $_getN(0);
  @$pb.TagNumber(1)
  set problems(FilePlanProblems value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProblems() => $_has(0);
  @$pb.TagNumber(1)
  void clearProblems() => $_clearField(1);
  @$pb.TagNumber(1)
  FilePlanProblems ensureProblems() => $_ensure(0);

  @$pb.TagNumber(2)
  FilePlanFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(FilePlanFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  FilePlanFault ensureFault() => $_ensure(1);
}

class FilePlanLoadProgress extends $pb.GeneratedMessage {
  factory FilePlanLoadProgress({
    $core.int? files,
    $core.int? totalFiles,
    $fixnum.Int64? bytes,
    $fixnum.Int64? totalBytes,
  }) {
    final result = create();
    if (files != null) result.files = files;
    if (totalFiles != null) result.totalFiles = totalFiles;
    if (bytes != null) result.bytes = bytes;
    if (totalBytes != null) result.totalBytes = totalBytes;
    return result;
  }

  FilePlanLoadProgress._();

  factory FilePlanLoadProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanLoadProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanLoadProgress',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'files', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'totalFiles', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'totalBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanLoadProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanLoadProgress copyWith(void Function(FilePlanLoadProgress) updates) =>
      super.copyWith((message) => updates(message as FilePlanLoadProgress))
          as FilePlanLoadProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanLoadProgress create() => FilePlanLoadProgress._();
  @$core.override
  FilePlanLoadProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanLoadProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanLoadProgress>(create);
  static FilePlanLoadProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get files => $_getIZ(0);
  @$pb.TagNumber(1)
  set files($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFiles() => $_has(0);
  @$pb.TagNumber(1)
  void clearFiles() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get totalFiles => $_getIZ(1);
  @$pb.TagNumber(2)
  set totalFiles($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalFiles() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalFiles() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get bytes => $_getI64(2);
  @$pb.TagNumber(3)
  set bytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get totalBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set totalBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalBytes() => $_clearField(4);
}

enum FilePlanLoadEvent_Event { progress, finished, notSet }

class FilePlanLoadEvent extends $pb.GeneratedMessage {
  factory FilePlanLoadEvent({
    FilePlanLoadProgress? progress,
    FilePlanReply? finished,
  }) {
    final result = create();
    if (progress != null) result.progress = progress;
    if (finished != null) result.finished = finished;
    return result;
  }

  FilePlanLoadEvent._();

  factory FilePlanLoadEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilePlanLoadEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, FilePlanLoadEvent_Event>
      _FilePlanLoadEvent_EventByTag = {
    1: FilePlanLoadEvent_Event.progress,
    2: FilePlanLoadEvent_Event.finished,
    0: FilePlanLoadEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilePlanLoadEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<FilePlanLoadProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: FilePlanLoadProgress.create)
    ..aOM<FilePlanReply>(2, _omitFieldNames ? '' : 'finished',
        subBuilder: FilePlanReply.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanLoadEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilePlanLoadEvent copyWith(void Function(FilePlanLoadEvent) updates) =>
      super.copyWith((message) => updates(message as FilePlanLoadEvent))
          as FilePlanLoadEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilePlanLoadEvent create() => FilePlanLoadEvent._();
  @$core.override
  FilePlanLoadEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilePlanLoadEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilePlanLoadEvent>(create);
  static FilePlanLoadEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  FilePlanLoadEvent_Event whichEvent() =>
      _FilePlanLoadEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  FilePlanLoadProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(FilePlanLoadProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  FilePlanLoadProgress ensureProgress() => $_ensure(0);

  @$pb.TagNumber(2)
  FilePlanReply get finished => $_getN(1);
  @$pb.TagNumber(2)
  set finished(FilePlanReply value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFinished() => $_has(1);
  @$pb.TagNumber(2)
  void clearFinished() => $_clearField(2);
  @$pb.TagNumber(2)
  FilePlanReply ensureFinished() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
