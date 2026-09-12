// This is a generated file - do not edit.
//
// Generated from modconductor/v1/artifacts.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'artifacts.pbenum.dart';
import 'download_models.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'artifacts.pbenum.dart';

class ArtifactProvenance extends $pb.GeneratedMessage {
  factory ArtifactProvenance({
    $core.String? modId,
    $core.String? versionId,
    $core.String? modName,
    $core.String? versionLabel,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (versionId != null) result.versionId = versionId;
    if (modName != null) result.modName = modName;
    if (versionLabel != null) result.versionLabel = versionLabel;
    return result;
  }

  ArtifactProvenance._();

  factory ArtifactProvenance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactProvenance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactProvenance',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..aOS(2, _omitFieldNames ? '' : 'versionId')
    ..aOS(3, _omitFieldNames ? '' : 'modName')
    ..aOS(4, _omitFieldNames ? '' : 'versionLabel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactProvenance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactProvenance copyWith(void Function(ArtifactProvenance) updates) =>
      super.copyWith((message) => updates(message as ArtifactProvenance))
          as ArtifactProvenance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactProvenance create() => ArtifactProvenance._();
  @$core.override
  ArtifactProvenance createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactProvenance getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactProvenance>(create);
  static ArtifactProvenance? _defaultInstance;

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
  $core.String get modName => $_getSZ(2);
  @$pb.TagNumber(3)
  set modName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModName() => $_has(2);
  @$pb.TagNumber(3)
  void clearModName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get versionLabel => $_getSZ(3);
  @$pb.TagNumber(4)
  set versionLabel($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVersionLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersionLabel() => $_clearField(4);
}

class ArchiveArtifact extends $pb.GeneratedMessage {
  factory ArchiveArtifact({
    $core.String? id,
    $core.String? workspaceId,
    $fixnum.Int64? revision,
    $core.String? originalName,
    $core.String? originalPath,
    $core.String? path,
    ArchiveStorage? storage,
    ArchiveState? state,
    $fixnum.Int64? length,
    $core.String? sha256,
    $core.String? problem,
    $core.Iterable<ArtifactProvenance>? links,
    $core.bool? canRetry,
    $core.bool? canLocate,
    $core.bool? canDeleteCopy,
    $core.bool? canRemove,
    $1.ArchiveDownload? download,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (revision != null) result.revision = revision;
    if (originalName != null) result.originalName = originalName;
    if (originalPath != null) result.originalPath = originalPath;
    if (path != null) result.path = path;
    if (storage != null) result.storage = storage;
    if (state != null) result.state = state;
    if (length != null) result.length = length;
    if (sha256 != null) result.sha256 = sha256;
    if (problem != null) result.problem = problem;
    if (links != null) result.links.addAll(links);
    if (canRetry != null) result.canRetry = canRetry;
    if (canLocate != null) result.canLocate = canLocate;
    if (canDeleteCopy != null) result.canDeleteCopy = canDeleteCopy;
    if (canRemove != null) result.canRemove = canRemove;
    if (download != null) result.download = download;
    return result;
  }

  ArchiveArtifact._();

  factory ArchiveArtifact.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArchiveArtifact.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArchiveArtifact',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'originalName')
    ..aOS(5, _omitFieldNames ? '' : 'originalPath')
    ..aOS(6, _omitFieldNames ? '' : 'path')
    ..aE<ArchiveStorage>(7, _omitFieldNames ? '' : 'storage',
        enumValues: ArchiveStorage.values)
    ..aE<ArchiveState>(8, _omitFieldNames ? '' : 'state',
        enumValues: ArchiveState.values)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(10, _omitFieldNames ? '' : 'sha256')
    ..aOS(11, _omitFieldNames ? '' : 'problem')
    ..pPM<ArtifactProvenance>(12, _omitFieldNames ? '' : 'links',
        subBuilder: ArtifactProvenance.create)
    ..aOB(13, _omitFieldNames ? '' : 'canRetry')
    ..aOB(14, _omitFieldNames ? '' : 'canLocate')
    ..aOB(15, _omitFieldNames ? '' : 'canDeleteCopy')
    ..aOB(16, _omitFieldNames ? '' : 'canRemove')
    ..aOM<$1.ArchiveDownload>(17, _omitFieldNames ? '' : 'download',
        subBuilder: $1.ArchiveDownload.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveArtifact clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveArtifact copyWith(void Function(ArchiveArtifact) updates) =>
      super.copyWith((message) => updates(message as ArchiveArtifact))
          as ArchiveArtifact;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArchiveArtifact create() => ArchiveArtifact._();
  @$core.override
  ArchiveArtifact createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArchiveArtifact getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArchiveArtifact>(create);
  static ArchiveArtifact? _defaultInstance;

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
  $fixnum.Int64 get revision => $_getI64(2);
  @$pb.TagNumber(3)
  set revision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get originalName => $_getSZ(3);
  @$pb.TagNumber(4)
  set originalName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOriginalName() => $_has(3);
  @$pb.TagNumber(4)
  void clearOriginalName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get originalPath => $_getSZ(4);
  @$pb.TagNumber(5)
  set originalPath($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOriginalPath() => $_has(4);
  @$pb.TagNumber(5)
  void clearOriginalPath() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get path => $_getSZ(5);
  @$pb.TagNumber(6)
  set path($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPath() => $_has(5);
  @$pb.TagNumber(6)
  void clearPath() => $_clearField(6);

  @$pb.TagNumber(7)
  ArchiveStorage get storage => $_getN(6);
  @$pb.TagNumber(7)
  set storage(ArchiveStorage value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasStorage() => $_has(6);
  @$pb.TagNumber(7)
  void clearStorage() => $_clearField(7);

  @$pb.TagNumber(8)
  ArchiveState get state => $_getN(7);
  @$pb.TagNumber(8)
  set state(ArchiveState value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasState() => $_has(7);
  @$pb.TagNumber(8)
  void clearState() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get length => $_getI64(8);
  @$pb.TagNumber(9)
  set length($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLength() => $_has(8);
  @$pb.TagNumber(9)
  void clearLength() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get sha256 => $_getSZ(9);
  @$pb.TagNumber(10)
  set sha256($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSha256() => $_has(9);
  @$pb.TagNumber(10)
  void clearSha256() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get problem => $_getSZ(10);
  @$pb.TagNumber(11)
  set problem($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasProblem() => $_has(10);
  @$pb.TagNumber(11)
  void clearProblem() => $_clearField(11);

  @$pb.TagNumber(12)
  $pb.PbList<ArtifactProvenance> get links => $_getList(11);

  @$pb.TagNumber(13)
  $core.bool get canRetry => $_getBF(12);
  @$pb.TagNumber(13)
  set canRetry($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCanRetry() => $_has(12);
  @$pb.TagNumber(13)
  void clearCanRetry() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get canLocate => $_getBF(13);
  @$pb.TagNumber(14)
  set canLocate($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCanLocate() => $_has(13);
  @$pb.TagNumber(14)
  void clearCanLocate() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.bool get canDeleteCopy => $_getBF(14);
  @$pb.TagNumber(15)
  set canDeleteCopy($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCanDeleteCopy() => $_has(14);
  @$pb.TagNumber(15)
  void clearCanDeleteCopy() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get canRemove => $_getBF(15);
  @$pb.TagNumber(16)
  set canRemove($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCanRemove() => $_has(15);
  @$pb.TagNumber(16)
  void clearCanRemove() => $_clearField(16);

  @$pb.TagNumber(17)
  $1.ArchiveDownload get download => $_getN(16);
  @$pb.TagNumber(17)
  set download($1.ArchiveDownload value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasDownload() => $_has(16);
  @$pb.TagNumber(17)
  void clearDownload() => $_clearField(17);
  @$pb.TagNumber(17)
  $1.ArchiveDownload ensureDownload() => $_ensure(16);
}

class ArtifactLinkPage extends $pb.GeneratedMessage {
  factory ArtifactLinkPage({
    $core.Iterable<ArtifactProvenance>? entries,
    $core.String? next,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (next != null) result.next = next;
    return result;
  }

  ArtifactLinkPage._();

  factory ArtifactLinkPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactLinkPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactLinkPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<ArtifactProvenance>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: ArtifactProvenance.create)
    ..aOS(2, _omitFieldNames ? '' : 'next')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactLinkPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactLinkPage copyWith(void Function(ArtifactLinkPage) updates) =>
      super.copyWith((message) => updates(message as ArtifactLinkPage))
          as ArtifactLinkPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactLinkPage create() => ArtifactLinkPage._();
  @$core.override
  ArtifactLinkPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactLinkPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactLinkPage>(create);
  static ArtifactLinkPage? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ArtifactProvenance> get entries => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get next => $_getSZ(1);
  @$pb.TagNumber(2)
  set next($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNext() => $_has(1);
  @$pb.TagNumber(2)
  void clearNext() => $_clearField(2);
}

class ArtifactPage extends $pb.GeneratedMessage {
  factory ArtifactPage({
    $core.Iterable<ArchiveArtifact>? entries,
    $core.String? next,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (next != null) result.next = next;
    return result;
  }

  ArtifactPage._();

  factory ArtifactPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<ArchiveArtifact>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: ArchiveArtifact.create)
    ..aOS(2, _omitFieldNames ? '' : 'next')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactPage copyWith(void Function(ArtifactPage) updates) =>
      super.copyWith((message) => updates(message as ArtifactPage))
          as ArtifactPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactPage create() => ArtifactPage._();
  @$core.override
  ArtifactPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactPage>(create);
  static ArtifactPage? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ArchiveArtifact> get entries => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get next => $_getSZ(1);
  @$pb.TagNumber(2)
  set next($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNext() => $_has(1);
  @$pb.TagNumber(2)
  void clearNext() => $_clearField(2);
}

class ArtifactListRequest extends $pb.GeneratedMessage {
  factory ArtifactListRequest({
    $core.String? workspaceId,
    $core.String? after,
    $core.bool? refresh,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (after != null) result.after = after;
    if (refresh != null) result.refresh = refresh;
    return result;
  }

  ArtifactListRequest._();

  factory ArtifactListRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactListRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactListRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'after')
    ..aOB(3, _omitFieldNames ? '' : 'refresh')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactListRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactListRequest copyWith(void Function(ArtifactListRequest) updates) =>
      super.copyWith((message) => updates(message as ArtifactListRequest))
          as ArtifactListRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactListRequest create() => ArtifactListRequest._();
  @$core.override
  ArtifactListRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactListRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactListRequest>(create);
  static ArtifactListRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get after => $_getSZ(1);
  @$pb.TagNumber(2)
  set after($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAfter() => $_has(1);
  @$pb.TagNumber(2)
  void clearAfter() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get refresh => $_getBF(2);
  @$pb.TagNumber(3)
  set refresh($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRefresh() => $_has(2);
  @$pb.TagNumber(3)
  void clearRefresh() => $_clearField(3);
}

class ArtifactReadRequest extends $pb.GeneratedMessage {
  factory ArtifactReadRequest({
    $core.String? workspaceId,
    $core.String? id,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    return result;
  }

  ArtifactReadRequest._();

  factory ArtifactReadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactReadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactReadRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactReadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactReadRequest copyWith(void Function(ArtifactReadRequest) updates) =>
      super.copyWith((message) => updates(message as ArtifactReadRequest))
          as ArtifactReadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactReadRequest create() => ArtifactReadRequest._();
  @$core.override
  ArtifactReadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactReadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactReadRequest>(create);
  static ArtifactReadRequest? _defaultInstance;

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

class ArtifactAddRequest extends $pb.GeneratedMessage {
  factory ArtifactAddRequest({
    $core.String? workspaceId,
    $core.String? id,
    $core.String? path,
    ArchiveStorage? storage,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    if (path != null) result.path = path;
    if (storage != null) result.storage = storage;
    return result;
  }

  ArtifactAddRequest._();

  factory ArtifactAddRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactAddRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactAddRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'path')
    ..aE<ArchiveStorage>(4, _omitFieldNames ? '' : 'storage',
        enumValues: ArchiveStorage.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactAddRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactAddRequest copyWith(void Function(ArtifactAddRequest) updates) =>
      super.copyWith((message) => updates(message as ArtifactAddRequest))
          as ArtifactAddRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactAddRequest create() => ArtifactAddRequest._();
  @$core.override
  ArtifactAddRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactAddRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactAddRequest>(create);
  static ArtifactAddRequest? _defaultInstance;

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
  $core.String get path => $_getSZ(2);
  @$pb.TagNumber(3)
  set path($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearPath() => $_clearField(3);

  @$pb.TagNumber(4)
  ArchiveStorage get storage => $_getN(3);
  @$pb.TagNumber(4)
  set storage(ArchiveStorage value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStorage() => $_has(3);
  @$pb.TagNumber(4)
  void clearStorage() => $_clearField(4);
}

class ArtifactReference extends $pb.GeneratedMessage {
  factory ArtifactReference({
    $core.String? workspaceId,
    $core.String? id,
    $fixnum.Int64? revision,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    if (revision != null) result.revision = revision;
    return result;
  }

  ArtifactReference._();

  factory ArtifactReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactReference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactReference copyWith(void Function(ArtifactReference) updates) =>
      super.copyWith((message) => updates(message as ArtifactReference))
          as ArtifactReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactReference create() => ArtifactReference._();
  @$core.override
  ArtifactReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactReference>(create);
  static ArtifactReference? _defaultInstance;

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
  $fixnum.Int64 get revision => $_getI64(2);
  @$pb.TagNumber(3)
  set revision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevision() => $_clearField(3);
}

class ArtifactLocateRequest extends $pb.GeneratedMessage {
  factory ArtifactLocateRequest({
    ArtifactReference? expected,
    $core.String? path,
  }) {
    final result = create();
    if (expected != null) result.expected = expected;
    if (path != null) result.path = path;
    return result;
  }

  ArtifactLocateRequest._();

  factory ArtifactLocateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactLocateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactLocateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ArtifactReference>(1, _omitFieldNames ? '' : 'expected',
        subBuilder: ArtifactReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactLocateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactLocateRequest copyWith(
          void Function(ArtifactLocateRequest) updates) =>
      super.copyWith((message) => updates(message as ArtifactLocateRequest))
          as ArtifactLocateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactLocateRequest create() => ArtifactLocateRequest._();
  @$core.override
  ArtifactLocateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactLocateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactLocateRequest>(create);
  static ArtifactLocateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ArtifactReference get expected => $_getN(0);
  @$pb.TagNumber(1)
  set expected(ArtifactReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasExpected() => $_has(0);
  @$pb.TagNumber(1)
  void clearExpected() => $_clearField(1);
  @$pb.TagNumber(1)
  ArtifactReference ensureExpected() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
}

class ArtifactLinkRequest extends $pb.GeneratedMessage {
  factory ArtifactLinkRequest({
    ArtifactReference? expected,
    $core.String? modId,
    $core.String? versionId,
    $core.bool? remove,
  }) {
    final result = create();
    if (expected != null) result.expected = expected;
    if (modId != null) result.modId = modId;
    if (versionId != null) result.versionId = versionId;
    if (remove != null) result.remove = remove;
    return result;
  }

  ArtifactLinkRequest._();

  factory ArtifactLinkRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactLinkRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactLinkRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ArtifactReference>(1, _omitFieldNames ? '' : 'expected',
        subBuilder: ArtifactReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..aOS(3, _omitFieldNames ? '' : 'versionId')
    ..aOB(4, _omitFieldNames ? '' : 'remove')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactLinkRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactLinkRequest copyWith(void Function(ArtifactLinkRequest) updates) =>
      super.copyWith((message) => updates(message as ArtifactLinkRequest))
          as ArtifactLinkRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactLinkRequest create() => ArtifactLinkRequest._();
  @$core.override
  ArtifactLinkRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactLinkRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactLinkRequest>(create);
  static ArtifactLinkRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ArtifactReference get expected => $_getN(0);
  @$pb.TagNumber(1)
  set expected(ArtifactReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasExpected() => $_has(0);
  @$pb.TagNumber(1)
  void clearExpected() => $_clearField(1);
  @$pb.TagNumber(1)
  ArtifactReference ensureExpected() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get modId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get versionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set versionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get remove => $_getBF(3);
  @$pb.TagNumber(4)
  set remove($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRemove() => $_has(3);
  @$pb.TagNumber(4)
  void clearRemove() => $_clearField(4);
}

class ArtifactRemoved extends $pb.GeneratedMessage {
  factory ArtifactRemoved() => create();

  ArtifactRemoved._();

  factory ArtifactRemoved.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArtifactRemoved.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArtifactRemoved',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactRemoved clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArtifactRemoved copyWith(void Function(ArtifactRemoved) updates) =>
      super.copyWith((message) => updates(message as ArtifactRemoved))
          as ArtifactRemoved;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactRemoved create() => ArtifactRemoved._();
  @$core.override
  ArtifactRemoved createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArtifactRemoved getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArtifactRemoved>(create);
  static ArtifactRemoved? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
