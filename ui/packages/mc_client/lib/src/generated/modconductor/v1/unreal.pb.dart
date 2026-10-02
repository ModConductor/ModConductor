// This is a generated file - do not edit.
//
// Generated from modconductor/v1/unreal.proto.

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

class UnrealLoaderInfo extends $pb.GeneratedMessage {
  factory UnrealLoaderInfo({
    $core.String? workspaceId,
    $core.String? profileId,
    $fixnum.Int64? contextRevision,
    $fixnum.Int64? selectionRevision,
    $core.String? loaderId,
    $core.String? name,
    $core.String? subtitle,
    $core.String? version,
    $core.String? iconUrl,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? iconHeaders,
    $core.String? modId,
    $core.bool? enabled,
    $core.bool? archiveRequired,
    $core.Iterable<$core.String>? settingsFiles,
    $core.bool? logAvailable,
    $core.String? declaredVersion,
    $core.String? declaredVersionLabel,
    $core.String? declaredSource,
    $core.String? upstreamLicense,
    $core.String? upstreamCommit,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (contextRevision != null) result.contextRevision = contextRevision;
    if (selectionRevision != null) result.selectionRevision = selectionRevision;
    if (loaderId != null) result.loaderId = loaderId;
    if (name != null) result.name = name;
    if (subtitle != null) result.subtitle = subtitle;
    if (version != null) result.version = version;
    if (iconUrl != null) result.iconUrl = iconUrl;
    if (iconHeaders != null) result.iconHeaders.addEntries(iconHeaders);
    if (modId != null) result.modId = modId;
    if (enabled != null) result.enabled = enabled;
    if (archiveRequired != null) result.archiveRequired = archiveRequired;
    if (settingsFiles != null) result.settingsFiles.addAll(settingsFiles);
    if (logAvailable != null) result.logAvailable = logAvailable;
    if (declaredVersion != null) result.declaredVersion = declaredVersion;
    if (declaredVersionLabel != null)
      result.declaredVersionLabel = declaredVersionLabel;
    if (declaredSource != null) result.declaredSource = declaredSource;
    if (upstreamLicense != null) result.upstreamLicense = upstreamLicense;
    if (upstreamCommit != null) result.upstreamCommit = upstreamCommit;
    return result;
  }

  UnrealLoaderInfo._();

  factory UnrealLoaderInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnrealLoaderInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnrealLoaderInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'contextRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'selectionRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(5, _omitFieldNames ? '' : 'loaderId')
    ..aOS(6, _omitFieldNames ? '' : 'name')
    ..aOS(7, _omitFieldNames ? '' : 'subtitle')
    ..aOS(8, _omitFieldNames ? '' : 'version')
    ..aOS(9, _omitFieldNames ? '' : 'iconUrl')
    ..m<$core.String, $core.String>(10, _omitFieldNames ? '' : 'iconHeaders',
        entryClassName: 'UnrealLoaderInfo.IconHeadersEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('modconductor.v1'))
    ..aOS(11, _omitFieldNames ? '' : 'modId')
    ..aOB(12, _omitFieldNames ? '' : 'enabled')
    ..aOB(13, _omitFieldNames ? '' : 'archiveRequired')
    ..pPS(14, _omitFieldNames ? '' : 'settingsFiles')
    ..aOB(15, _omitFieldNames ? '' : 'logAvailable')
    ..aOS(16, _omitFieldNames ? '' : 'declaredVersion')
    ..aOS(17, _omitFieldNames ? '' : 'declaredVersionLabel')
    ..aOS(18, _omitFieldNames ? '' : 'declaredSource')
    ..aOS(19, _omitFieldNames ? '' : 'upstreamLicense')
    ..aOS(20, _omitFieldNames ? '' : 'upstreamCommit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnrealLoaderInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnrealLoaderInfo copyWith(void Function(UnrealLoaderInfo) updates) =>
      super.copyWith((message) => updates(message as UnrealLoaderInfo))
          as UnrealLoaderInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnrealLoaderInfo create() => UnrealLoaderInfo._();
  @$core.override
  UnrealLoaderInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnrealLoaderInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnrealLoaderInfo>(create);
  static UnrealLoaderInfo? _defaultInstance;

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

  @$pb.TagNumber(3)
  $fixnum.Int64 get contextRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set contextRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContextRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearContextRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get selectionRevision => $_getI64(3);
  @$pb.TagNumber(4)
  set selectionRevision($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSelectionRevision() => $_has(3);
  @$pb.TagNumber(4)
  void clearSelectionRevision() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get loaderId => $_getSZ(4);
  @$pb.TagNumber(5)
  set loaderId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLoaderId() => $_has(4);
  @$pb.TagNumber(5)
  void clearLoaderId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get name => $_getSZ(5);
  @$pb.TagNumber(6)
  set name($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasName() => $_has(5);
  @$pb.TagNumber(6)
  void clearName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get subtitle => $_getSZ(6);
  @$pb.TagNumber(7)
  set subtitle($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSubtitle() => $_has(6);
  @$pb.TagNumber(7)
  void clearSubtitle() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get version => $_getSZ(7);
  @$pb.TagNumber(8)
  set version($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearVersion() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get iconUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set iconUrl($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIconUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearIconUrl() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbMap<$core.String, $core.String> get iconHeaders => $_getMap(9);

  @$pb.TagNumber(11)
  $core.String get modId => $_getSZ(10);
  @$pb.TagNumber(11)
  set modId($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasModId() => $_has(10);
  @$pb.TagNumber(11)
  void clearModId() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get enabled => $_getBF(11);
  @$pb.TagNumber(12)
  set enabled($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasEnabled() => $_has(11);
  @$pb.TagNumber(12)
  void clearEnabled() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get archiveRequired => $_getBF(12);
  @$pb.TagNumber(13)
  set archiveRequired($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasArchiveRequired() => $_has(12);
  @$pb.TagNumber(13)
  void clearArchiveRequired() => $_clearField(13);

  @$pb.TagNumber(14)
  $pb.PbList<$core.String> get settingsFiles => $_getList(13);

  @$pb.TagNumber(15)
  $core.bool get logAvailable => $_getBF(14);
  @$pb.TagNumber(15)
  set logAvailable($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasLogAvailable() => $_has(14);
  @$pb.TagNumber(15)
  void clearLogAvailable() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get declaredVersion => $_getSZ(15);
  @$pb.TagNumber(16)
  set declaredVersion($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasDeclaredVersion() => $_has(15);
  @$pb.TagNumber(16)
  void clearDeclaredVersion() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get declaredVersionLabel => $_getSZ(16);
  @$pb.TagNumber(17)
  set declaredVersionLabel($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasDeclaredVersionLabel() => $_has(16);
  @$pb.TagNumber(17)
  void clearDeclaredVersionLabel() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get declaredSource => $_getSZ(17);
  @$pb.TagNumber(18)
  set declaredSource($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasDeclaredSource() => $_has(17);
  @$pb.TagNumber(18)
  void clearDeclaredSource() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get upstreamLicense => $_getSZ(18);
  @$pb.TagNumber(19)
  set upstreamLicense($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasUpstreamLicense() => $_has(18);
  @$pb.TagNumber(19)
  void clearUpstreamLicense() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get upstreamCommit => $_getSZ(19);
  @$pb.TagNumber(20)
  set upstreamCommit($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasUpstreamCommit() => $_has(19);
  @$pb.TagNumber(20)
  void clearUpstreamCommit() => $_clearField(20);
}

enum UnrealLoaderReply_Result { loader, problem, notSet }

class UnrealLoaderReply extends $pb.GeneratedMessage {
  factory UnrealLoaderReply({
    UnrealLoaderInfo? loader,
    $core.String? problem,
  }) {
    final result = create();
    if (loader != null) result.loader = loader;
    if (problem != null) result.problem = problem;
    return result;
  }

  UnrealLoaderReply._();

  factory UnrealLoaderReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnrealLoaderReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UnrealLoaderReply_Result>
      _UnrealLoaderReply_ResultByTag = {
    1: UnrealLoaderReply_Result.loader,
    2: UnrealLoaderReply_Result.problem,
    0: UnrealLoaderReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnrealLoaderReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<UnrealLoaderInfo>(1, _omitFieldNames ? '' : 'loader',
        subBuilder: UnrealLoaderInfo.create)
    ..aOS(2, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnrealLoaderReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnrealLoaderReply copyWith(void Function(UnrealLoaderReply) updates) =>
      super.copyWith((message) => updates(message as UnrealLoaderReply))
          as UnrealLoaderReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnrealLoaderReply create() => UnrealLoaderReply._();
  @$core.override
  UnrealLoaderReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnrealLoaderReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnrealLoaderReply>(create);
  static UnrealLoaderReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UnrealLoaderReply_Result whichResult() =>
      _UnrealLoaderReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  UnrealLoaderInfo get loader => $_getN(0);
  @$pb.TagNumber(1)
  set loader(UnrealLoaderInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLoader() => $_has(0);
  @$pb.TagNumber(1)
  void clearLoader() => $_clearField(1);
  @$pb.TagNumber(1)
  UnrealLoaderInfo ensureLoader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get problem => $_getSZ(1);
  @$pb.TagNumber(2)
  set problem($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
}

class AcquireUnrealLoaderRequest extends $pb.GeneratedMessage {
  factory AcquireUnrealLoaderRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $fixnum.Int64? contextRevision,
    $core.String? archivePath,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (contextRevision != null) result.contextRevision = contextRevision;
    if (archivePath != null) result.archivePath = archivePath;
    return result;
  }

  AcquireUnrealLoaderRequest._();

  factory AcquireUnrealLoaderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireUnrealLoaderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcquireUnrealLoaderRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'contextRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'archivePath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireUnrealLoaderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireUnrealLoaderRequest copyWith(
          void Function(AcquireUnrealLoaderRequest) updates) =>
      super.copyWith(
              (message) => updates(message as AcquireUnrealLoaderRequest))
          as AcquireUnrealLoaderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireUnrealLoaderRequest create() => AcquireUnrealLoaderRequest._();
  @$core.override
  AcquireUnrealLoaderRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireUnrealLoaderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcquireUnrealLoaderRequest>(create);
  static AcquireUnrealLoaderRequest? _defaultInstance;

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

  @$pb.TagNumber(3)
  $fixnum.Int64 get contextRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set contextRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContextRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearContextRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get archivePath => $_getSZ(3);
  @$pb.TagNumber(4)
  set archivePath($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasArchivePath() => $_has(3);
  @$pb.TagNumber(4)
  void clearArchivePath() => $_clearField(4);
}

class UnrealAcquisitionProgress extends $pb.GeneratedMessage {
  factory UnrealAcquisitionProgress({
    $core.String? stage,
    $fixnum.Int64? bytes,
    $fixnum.Int64? total,
    $core.String? modId,
    $core.String? problem,
    UnrealLoaderInfo? loader,
  }) {
    final result = create();
    if (stage != null) result.stage = stage;
    if (bytes != null) result.bytes = bytes;
    if (total != null) result.total = total;
    if (modId != null) result.modId = modId;
    if (problem != null) result.problem = problem;
    if (loader != null) result.loader = loader;
    return result;
  }

  UnrealAcquisitionProgress._();

  factory UnrealAcquisitionProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnrealAcquisitionProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnrealAcquisitionProgress',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'stage')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'total', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'modId')
    ..aOS(5, _omitFieldNames ? '' : 'problem')
    ..aOM<UnrealLoaderInfo>(6, _omitFieldNames ? '' : 'loader',
        subBuilder: UnrealLoaderInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnrealAcquisitionProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnrealAcquisitionProgress copyWith(
          void Function(UnrealAcquisitionProgress) updates) =>
      super.copyWith((message) => updates(message as UnrealAcquisitionProgress))
          as UnrealAcquisitionProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnrealAcquisitionProgress create() => UnrealAcquisitionProgress._();
  @$core.override
  UnrealAcquisitionProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnrealAcquisitionProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnrealAcquisitionProgress>(create);
  static UnrealAcquisitionProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get stage => $_getSZ(0);
  @$pb.TagNumber(1)
  set stage($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStage() => $_has(0);
  @$pb.TagNumber(1)
  void clearStage() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytes => $_getI64(1);
  @$pb.TagNumber(2)
  set bytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get total => $_getI64(2);
  @$pb.TagNumber(3)
  set total($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get modId => $_getSZ(3);
  @$pb.TagNumber(4)
  set modId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModId() => $_has(3);
  @$pb.TagNumber(4)
  void clearModId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get problem => $_getSZ(4);
  @$pb.TagNumber(5)
  set problem($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProblem() => $_has(4);
  @$pb.TagNumber(5)
  void clearProblem() => $_clearField(5);

  @$pb.TagNumber(6)
  UnrealLoaderInfo get loader => $_getN(5);
  @$pb.TagNumber(6)
  set loader(UnrealLoaderInfo value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLoader() => $_has(5);
  @$pb.TagNumber(6)
  void clearLoader() => $_clearField(6);
  @$pb.TagNumber(6)
  UnrealLoaderInfo ensureLoader() => $_ensure(5);
}

class UnrealTextRequest extends $pb.GeneratedMessage {
  factory UnrealTextRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? name,
    $core.bool? log,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (name != null) result.name = name;
    if (log != null) result.log = log;
    return result;
  }

  UnrealTextRequest._();

  factory UnrealTextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnrealTextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnrealTextRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOB(4, _omitFieldNames ? '' : 'log')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnrealTextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnrealTextRequest copyWith(void Function(UnrealTextRequest) updates) =>
      super.copyWith((message) => updates(message as UnrealTextRequest))
          as UnrealTextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnrealTextRequest create() => UnrealTextRequest._();
  @$core.override
  UnrealTextRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnrealTextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnrealTextRequest>(create);
  static UnrealTextRequest? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get log => $_getBF(3);
  @$pb.TagNumber(4)
  set log($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLog() => $_has(3);
  @$pb.TagNumber(4)
  void clearLog() => $_clearField(4);
}

class SaveUnrealTextRequest extends $pb.GeneratedMessage {
  factory SaveUnrealTextRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? name,
    $core.List<$core.int>? original,
    $core.String? content,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (name != null) result.name = name;
    if (original != null) result.original = original;
    if (content != null) result.content = content;
    return result;
  }

  SaveUnrealTextRequest._();

  factory SaveUnrealTextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveUnrealTextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveUnrealTextRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'original', $pb.PbFieldType.OY)
    ..aOS(5, _omitFieldNames ? '' : 'content')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveUnrealTextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveUnrealTextRequest copyWith(
          void Function(SaveUnrealTextRequest) updates) =>
      super.copyWith((message) => updates(message as SaveUnrealTextRequest))
          as SaveUnrealTextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveUnrealTextRequest create() => SaveUnrealTextRequest._();
  @$core.override
  SaveUnrealTextRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveUnrealTextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveUnrealTextRequest>(create);
  static SaveUnrealTextRequest? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get original => $_getN(3);
  @$pb.TagNumber(4)
  set original($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOriginal() => $_has(3);
  @$pb.TagNumber(4)
  void clearOriginal() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get content => $_getSZ(4);
  @$pb.TagNumber(5)
  set content($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContent() => $_has(4);
  @$pb.TagNumber(5)
  void clearContent() => $_clearField(5);
}

class UnrealPageReply extends $pb.GeneratedMessage {
  factory UnrealPageReply({
    $core.String? problem,
  }) {
    final result = create();
    if (problem != null) result.problem = problem;
    return result;
  }

  UnrealPageReply._();

  factory UnrealPageReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnrealPageReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnrealPageReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnrealPageReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnrealPageReply copyWith(void Function(UnrealPageReply) updates) =>
      super.copyWith((message) => updates(message as UnrealPageReply))
          as UnrealPageReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnrealPageReply create() => UnrealPageReply._();
  @$core.override
  UnrealPageReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnrealPageReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnrealPageReply>(create);
  static UnrealPageReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get problem => $_getSZ(0);
  @$pb.TagNumber(1)
  set problem($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProblem() => $_has(0);
  @$pb.TagNumber(1)
  void clearProblem() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
