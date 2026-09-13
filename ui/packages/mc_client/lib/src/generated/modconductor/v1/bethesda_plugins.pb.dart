// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bethesda_plugins.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'file_plans.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ScanPluginsRequest extends $pb.GeneratedMessage {
  factory ScanPluginsRequest({
    $core.String? profileId,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  ScanPluginsRequest._();

  factory ScanPluginsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScanPluginsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScanPluginsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanPluginsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanPluginsRequest copyWith(void Function(ScanPluginsRequest) updates) =>
      super.copyWith((message) => updates(message as ScanPluginsRequest))
          as ScanPluginsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScanPluginsRequest create() => ScanPluginsRequest._();
  @$core.override
  ScanPluginsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScanPluginsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScanPluginsRequest>(create);
  static ScanPluginsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);
}

class ReadPluginsRequest extends $pb.GeneratedMessage {
  factory ReadPluginsRequest({
    $core.String? snapshotId,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    return result;
  }

  ReadPluginsRequest._();

  factory ReadPluginsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadPluginsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadPluginsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadPluginsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadPluginsRequest copyWith(void Function(ReadPluginsRequest) updates) =>
      super.copyWith((message) => updates(message as ReadPluginsRequest))
          as ReadPluginsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadPluginsRequest create() => ReadPluginsRequest._();
  @$core.override
  ReadPluginsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadPluginsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadPluginsRequest>(create);
  static ReadPluginsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);
}

class BethesdaPluginSource extends $pb.GeneratedMessage {
  factory BethesdaPluginSource({
    $core.String? name,
    $core.String? version,
    $core.String? path,
    $core.String? modId,
    $core.String? versionId,
    $core.bool? gameFile,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    if (path != null) result.path = path;
    if (modId != null) result.modId = modId;
    if (versionId != null) result.versionId = versionId;
    if (gameFile != null) result.gameFile = gameFile;
    return result;
  }

  BethesdaPluginSource._();

  factory BethesdaPluginSource.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BethesdaPluginSource.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BethesdaPluginSource',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'path')
    ..aOS(4, _omitFieldNames ? '' : 'modId')
    ..aOS(5, _omitFieldNames ? '' : 'versionId')
    ..aOB(6, _omitFieldNames ? '' : 'gameFile')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaPluginSource clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaPluginSource copyWith(void Function(BethesdaPluginSource) updates) =>
      super.copyWith((message) => updates(message as BethesdaPluginSource))
          as BethesdaPluginSource;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BethesdaPluginSource create() => BethesdaPluginSource._();
  @$core.override
  BethesdaPluginSource createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BethesdaPluginSource getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BethesdaPluginSource>(create);
  static BethesdaPluginSource? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get path => $_getSZ(2);
  @$pb.TagNumber(3)
  set path($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearPath() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get modId => $_getSZ(3);
  @$pb.TagNumber(4)
  set modId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModId() => $_has(3);
  @$pb.TagNumber(4)
  void clearModId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get versionId => $_getSZ(4);
  @$pb.TagNumber(5)
  set versionId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasVersionId() => $_has(4);
  @$pb.TagNumber(5)
  void clearVersionId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get gameFile => $_getBF(5);
  @$pb.TagNumber(6)
  set gameFile($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGameFile() => $_has(5);
  @$pb.TagNumber(6)
  void clearGameFile() => $_clearField(6);
}

class BethesdaMaster extends $pb.GeneratedMessage {
  factory BethesdaMaster({
    $core.String? name,
    $core.String? status,
    BethesdaPluginSource? source,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (status != null) result.status = status;
    if (source != null) result.source = source;
    return result;
  }

  BethesdaMaster._();

  factory BethesdaMaster.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BethesdaMaster.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BethesdaMaster',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOM<BethesdaPluginSource>(3, _omitFieldNames ? '' : 'source',
        subBuilder: BethesdaPluginSource.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaMaster clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaMaster copyWith(void Function(BethesdaMaster) updates) =>
      super.copyWith((message) => updates(message as BethesdaMaster))
          as BethesdaMaster;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BethesdaMaster create() => BethesdaMaster._();
  @$core.override
  BethesdaMaster createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BethesdaMaster getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BethesdaMaster>(create);
  static BethesdaMaster? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  BethesdaPluginSource get source => $_getN(2);
  @$pb.TagNumber(3)
  set source(BethesdaPluginSource value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);
  @$pb.TagNumber(3)
  BethesdaPluginSource ensureSource() => $_ensure(2);
}

class BethesdaPluginHeader extends $pb.GeneratedMessage {
  factory BethesdaPluginHeader({
    $core.String? extension_1,
    $core.int? flags,
    $core.int? formVersion,
    $core.double? headerVersion,
    $core.int? declaredRecords,
    $core.bool? localized,
    $core.String? author,
    $core.String? description,
    $core.String? flagLabels,
  }) {
    final result = create();
    if (extension_1 != null) result.extension_1 = extension_1;
    if (flags != null) result.flags = flags;
    if (formVersion != null) result.formVersion = formVersion;
    if (headerVersion != null) result.headerVersion = headerVersion;
    if (declaredRecords != null) result.declaredRecords = declaredRecords;
    if (localized != null) result.localized = localized;
    if (author != null) result.author = author;
    if (description != null) result.description = description;
    if (flagLabels != null) result.flagLabels = flagLabels;
    return result;
  }

  BethesdaPluginHeader._();

  factory BethesdaPluginHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BethesdaPluginHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BethesdaPluginHeader',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'extension')
    ..aI(2, _omitFieldNames ? '' : 'flags', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'formVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..aD(4, _omitFieldNames ? '' : 'headerVersion',
        fieldType: $pb.PbFieldType.OF)
    ..aI(5, _omitFieldNames ? '' : 'declaredRecords',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(6, _omitFieldNames ? '' : 'localized')
    ..aOS(7, _omitFieldNames ? '' : 'author')
    ..aOS(8, _omitFieldNames ? '' : 'description')
    ..aOS(9, _omitFieldNames ? '' : 'flagLabels')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaPluginHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaPluginHeader copyWith(void Function(BethesdaPluginHeader) updates) =>
      super.copyWith((message) => updates(message as BethesdaPluginHeader))
          as BethesdaPluginHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BethesdaPluginHeader create() => BethesdaPluginHeader._();
  @$core.override
  BethesdaPluginHeader createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BethesdaPluginHeader getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BethesdaPluginHeader>(create);
  static BethesdaPluginHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get extension_1 => $_getSZ(0);
  @$pb.TagNumber(1)
  set extension_1($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtension_1() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtension_1() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get flags => $_getIZ(1);
  @$pb.TagNumber(2)
  set flags($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFlags() => $_has(1);
  @$pb.TagNumber(2)
  void clearFlags() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get formVersion => $_getIZ(2);
  @$pb.TagNumber(3)
  set formVersion($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFormVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearFormVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get headerVersion => $_getN(3);
  @$pb.TagNumber(4)
  set headerVersion($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHeaderVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearHeaderVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get declaredRecords => $_getIZ(4);
  @$pb.TagNumber(5)
  set declaredRecords($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeclaredRecords() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeclaredRecords() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get localized => $_getBF(5);
  @$pb.TagNumber(6)
  set localized($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLocalized() => $_has(5);
  @$pb.TagNumber(6)
  void clearLocalized() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get author => $_getSZ(6);
  @$pb.TagNumber(7)
  set author($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAuthor() => $_has(6);
  @$pb.TagNumber(7)
  void clearAuthor() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get description => $_getSZ(7);
  @$pb.TagNumber(8)
  set description($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDescription() => $_has(7);
  @$pb.TagNumber(8)
  void clearDescription() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get flagLabels => $_getSZ(8);
  @$pb.TagNumber(9)
  set flagLabels($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFlagLabels() => $_has(8);
  @$pb.TagNumber(9)
  void clearFlagLabels() => $_clearField(9);
}

class BethesdaPlugin extends $pb.GeneratedMessage {
  factory BethesdaPlugin({
    $core.String? name,
    $core.String? kind,
    $core.String? status,
    $core.String? problem,
    $core.bool? hasIssues,
    BethesdaPluginSource? winner,
    $core.Iterable<BethesdaPluginSource>? alternatives,
    BethesdaPluginHeader? header,
    $core.Iterable<BethesdaMaster>? masters,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (kind != null) result.kind = kind;
    if (status != null) result.status = status;
    if (problem != null) result.problem = problem;
    if (hasIssues != null) result.hasIssues = hasIssues;
    if (winner != null) result.winner = winner;
    if (alternatives != null) result.alternatives.addAll(alternatives);
    if (header != null) result.header = header;
    if (masters != null) result.masters.addAll(masters);
    return result;
  }

  BethesdaPlugin._();

  factory BethesdaPlugin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BethesdaPlugin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BethesdaPlugin',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..aOS(3, _omitFieldNames ? '' : 'status')
    ..aOS(4, _omitFieldNames ? '' : 'problem')
    ..aOB(5, _omitFieldNames ? '' : 'hasIssues')
    ..aOM<BethesdaPluginSource>(6, _omitFieldNames ? '' : 'winner',
        subBuilder: BethesdaPluginSource.create)
    ..pPM<BethesdaPluginSource>(7, _omitFieldNames ? '' : 'alternatives',
        subBuilder: BethesdaPluginSource.create)
    ..aOM<BethesdaPluginHeader>(8, _omitFieldNames ? '' : 'header',
        subBuilder: BethesdaPluginHeader.create)
    ..pPM<BethesdaMaster>(9, _omitFieldNames ? '' : 'masters',
        subBuilder: BethesdaMaster.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaPlugin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaPlugin copyWith(void Function(BethesdaPlugin) updates) =>
      super.copyWith((message) => updates(message as BethesdaPlugin))
          as BethesdaPlugin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BethesdaPlugin create() => BethesdaPlugin._();
  @$core.override
  BethesdaPlugin createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BethesdaPlugin getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BethesdaPlugin>(create);
  static BethesdaPlugin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get status => $_getSZ(2);
  @$pb.TagNumber(3)
  set status($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get problem => $_getSZ(3);
  @$pb.TagNumber(4)
  set problem($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProblem() => $_has(3);
  @$pb.TagNumber(4)
  void clearProblem() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get hasIssues => $_getBF(4);
  @$pb.TagNumber(5)
  set hasIssues($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHasIssues() => $_has(4);
  @$pb.TagNumber(5)
  void clearHasIssues() => $_clearField(5);

  @$pb.TagNumber(6)
  BethesdaPluginSource get winner => $_getN(5);
  @$pb.TagNumber(6)
  set winner(BethesdaPluginSource value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasWinner() => $_has(5);
  @$pb.TagNumber(6)
  void clearWinner() => $_clearField(6);
  @$pb.TagNumber(6)
  BethesdaPluginSource ensureWinner() => $_ensure(5);

  @$pb.TagNumber(7)
  $pb.PbList<BethesdaPluginSource> get alternatives => $_getList(6);

  @$pb.TagNumber(8)
  BethesdaPluginHeader get header => $_getN(7);
  @$pb.TagNumber(8)
  set header(BethesdaPluginHeader value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasHeader() => $_has(7);
  @$pb.TagNumber(8)
  void clearHeader() => $_clearField(8);
  @$pb.TagNumber(8)
  BethesdaPluginHeader ensureHeader() => $_ensure(7);

  @$pb.TagNumber(9)
  $pb.PbList<BethesdaMaster> get masters => $_getList(8);
}

class BethesdaPluginSnapshot extends $pb.GeneratedMessage {
  factory BethesdaPluginSnapshot({
    $core.String? snapshotId,
    $core.String? workspaceId,
    $core.String? profileId,
    $fixnum.Int64? observedAtUnixMs,
    $core.bool? stale,
    $core.Iterable<BethesdaPlugin>? plugins,
    $core.Iterable<$core.String>? problems,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (observedAtUnixMs != null) result.observedAtUnixMs = observedAtUnixMs;
    if (stale != null) result.stale = stale;
    if (plugins != null) result.plugins.addAll(plugins);
    if (problems != null) result.problems.addAll(problems);
    return result;
  }

  BethesdaPluginSnapshot._();

  factory BethesdaPluginSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BethesdaPluginSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BethesdaPluginSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'profileId')
    ..aInt64(4, _omitFieldNames ? '' : 'observedAtUnixMs')
    ..aOB(5, _omitFieldNames ? '' : 'stale')
    ..pPM<BethesdaPlugin>(6, _omitFieldNames ? '' : 'plugins',
        subBuilder: BethesdaPlugin.create)
    ..pPS(7, _omitFieldNames ? '' : 'problems')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaPluginSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaPluginSnapshot copyWith(
          void Function(BethesdaPluginSnapshot) updates) =>
      super.copyWith((message) => updates(message as BethesdaPluginSnapshot))
          as BethesdaPluginSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BethesdaPluginSnapshot create() => BethesdaPluginSnapshot._();
  @$core.override
  BethesdaPluginSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BethesdaPluginSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BethesdaPluginSnapshot>(create);
  static BethesdaPluginSnapshot? _defaultInstance;

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
  $fixnum.Int64 get observedAtUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set observedAtUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasObservedAtUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearObservedAtUnixMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get stale => $_getBF(4);
  @$pb.TagNumber(5)
  set stale($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStale() => $_has(4);
  @$pb.TagNumber(5)
  void clearStale() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<BethesdaPlugin> get plugins => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get problems => $_getList(6);
}

enum BethesdaPluginsReply_Outcome { snapshot, fault, notSet }

class BethesdaPluginsReply extends $pb.GeneratedMessage {
  factory BethesdaPluginsReply({
    BethesdaPluginSnapshot? snapshot,
    $1.FilePlanFault? fault,
  }) {
    final result = create();
    if (snapshot != null) result.snapshot = snapshot;
    if (fault != null) result.fault = fault;
    return result;
  }

  BethesdaPluginsReply._();

  factory BethesdaPluginsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BethesdaPluginsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, BethesdaPluginsReply_Outcome>
      _BethesdaPluginsReply_OutcomeByTag = {
    1: BethesdaPluginsReply_Outcome.snapshot,
    2: BethesdaPluginsReply_Outcome.fault,
    0: BethesdaPluginsReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BethesdaPluginsReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<BethesdaPluginSnapshot>(1, _omitFieldNames ? '' : 'snapshot',
        subBuilder: BethesdaPluginSnapshot.create)
    ..aOM<$1.FilePlanFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: $1.FilePlanFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaPluginsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BethesdaPluginsReply copyWith(void Function(BethesdaPluginsReply) updates) =>
      super.copyWith((message) => updates(message as BethesdaPluginsReply))
          as BethesdaPluginsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BethesdaPluginsReply create() => BethesdaPluginsReply._();
  @$core.override
  BethesdaPluginsReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BethesdaPluginsReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BethesdaPluginsReply>(create);
  static BethesdaPluginsReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  BethesdaPluginsReply_Outcome whichOutcome() =>
      _BethesdaPluginsReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  BethesdaPluginSnapshot get snapshot => $_getN(0);
  @$pb.TagNumber(1)
  set snapshot(BethesdaPluginSnapshot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshot() => $_clearField(1);
  @$pb.TagNumber(1)
  BethesdaPluginSnapshot ensureSnapshot() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.FilePlanFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault($1.FilePlanFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.FilePlanFault ensureFault() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
