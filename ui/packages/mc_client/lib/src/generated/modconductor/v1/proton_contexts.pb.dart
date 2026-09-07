// This is a generated file - do not edit.
//
// Generated from modconductor/v1/proton_contexts.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'steam_discovery.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SearchProtonContextsRequest extends $pb.GeneratedMessage {
  factory SearchProtonContextsRequest({
    $core.String? definitionId,
    $core.String? gamePath,
    $core.Iterable<$core.String>? additionalRoots,
  }) {
    final result = create();
    if (definitionId != null) result.definitionId = definitionId;
    if (gamePath != null) result.gamePath = gamePath;
    if (additionalRoots != null) result.additionalRoots.addAll(additionalRoots);
    return result;
  }

  SearchProtonContextsRequest._();

  factory SearchProtonContextsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchProtonContextsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchProtonContextsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'definitionId')
    ..aOS(2, _omitFieldNames ? '' : 'gamePath')
    ..pPS(3, _omitFieldNames ? '' : 'additionalRoots')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchProtonContextsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchProtonContextsRequest copyWith(
          void Function(SearchProtonContextsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SearchProtonContextsRequest))
          as SearchProtonContextsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchProtonContextsRequest create() =>
      SearchProtonContextsRequest._();
  @$core.override
  SearchProtonContextsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchProtonContextsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchProtonContextsRequest>(create);
  static SearchProtonContextsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get definitionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set definitionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDefinitionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDefinitionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get gamePath => $_getSZ(1);
  @$pb.TagNumber(2)
  set gamePath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGamePath() => $_has(1);
  @$pb.TagNumber(2)
  void clearGamePath() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get additionalRoots => $_getList(2);
}

class ProtonSteamAssociation extends $pb.GeneratedMessage {
  factory ProtonSteamAssociation({
    $core.String? steamRoot,
    $core.String? library,
  }) {
    final result = create();
    if (steamRoot != null) result.steamRoot = steamRoot;
    if (library != null) result.library = library;
    return result;
  }

  ProtonSteamAssociation._();

  factory ProtonSteamAssociation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonSteamAssociation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonSteamAssociation',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'steamRoot')
    ..aOS(2, _omitFieldNames ? '' : 'library')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonSteamAssociation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonSteamAssociation copyWith(
          void Function(ProtonSteamAssociation) updates) =>
      super.copyWith((message) => updates(message as ProtonSteamAssociation))
          as ProtonSteamAssociation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonSteamAssociation create() => ProtonSteamAssociation._();
  @$core.override
  ProtonSteamAssociation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonSteamAssociation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonSteamAssociation>(create);
  static ProtonSteamAssociation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get steamRoot => $_getSZ(0);
  @$pb.TagNumber(1)
  set steamRoot($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSteamRoot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSteamRoot() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get library => $_getSZ(1);
  @$pb.TagNumber(2)
  set library($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLibrary() => $_has(1);
  @$pb.TagNumber(2)
  void clearLibrary() => $_clearField(2);
}

enum ProtonSelectionInfo_Association { manual, steam, notSet }

class ProtonSelectionInfo extends $pb.GeneratedMessage {
  factory ProtonSelectionInfo({
    $core.int? appId,
    $core.bool? manual,
    ProtonSteamAssociation? steam,
    $core.String? compatData,
    $core.String? runtimeDirectory,
    $core.String? toolId,
  }) {
    final result = create();
    if (appId != null) result.appId = appId;
    if (manual != null) result.manual = manual;
    if (steam != null) result.steam = steam;
    if (compatData != null) result.compatData = compatData;
    if (runtimeDirectory != null) result.runtimeDirectory = runtimeDirectory;
    if (toolId != null) result.toolId = toolId;
    return result;
  }

  ProtonSelectionInfo._();

  factory ProtonSelectionInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonSelectionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProtonSelectionInfo_Association>
      _ProtonSelectionInfo_AssociationByTag = {
    2: ProtonSelectionInfo_Association.manual,
    3: ProtonSelectionInfo_Association.steam,
    0: ProtonSelectionInfo_Association.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonSelectionInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..aI(1, _omitFieldNames ? '' : 'appId', fieldType: $pb.PbFieldType.OU3)
    ..aOB(2, _omitFieldNames ? '' : 'manual')
    ..aOM<ProtonSteamAssociation>(3, _omitFieldNames ? '' : 'steam',
        subBuilder: ProtonSteamAssociation.create)
    ..aOS(4, _omitFieldNames ? '' : 'compatData')
    ..aOS(5, _omitFieldNames ? '' : 'runtimeDirectory')
    ..aOS(6, _omitFieldNames ? '' : 'toolId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonSelectionInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonSelectionInfo copyWith(void Function(ProtonSelectionInfo) updates) =>
      super.copyWith((message) => updates(message as ProtonSelectionInfo))
          as ProtonSelectionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonSelectionInfo create() => ProtonSelectionInfo._();
  @$core.override
  ProtonSelectionInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonSelectionInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonSelectionInfo>(create);
  static ProtonSelectionInfo? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  ProtonSelectionInfo_Association whichAssociation() =>
      _ProtonSelectionInfo_AssociationByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearAssociation() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.int get appId => $_getIZ(0);
  @$pb.TagNumber(1)
  set appId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAppId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get manual => $_getBF(1);
  @$pb.TagNumber(2)
  set manual($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasManual() => $_has(1);
  @$pb.TagNumber(2)
  void clearManual() => $_clearField(2);

  @$pb.TagNumber(3)
  ProtonSteamAssociation get steam => $_getN(2);
  @$pb.TagNumber(3)
  set steam(ProtonSteamAssociation value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSteam() => $_has(2);
  @$pb.TagNumber(3)
  void clearSteam() => $_clearField(3);
  @$pb.TagNumber(3)
  ProtonSteamAssociation ensureSteam() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get compatData => $_getSZ(3);
  @$pb.TagNumber(4)
  set compatData($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCompatData() => $_has(3);
  @$pb.TagNumber(4)
  void clearCompatData() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get runtimeDirectory => $_getSZ(4);
  @$pb.TagNumber(5)
  set runtimeDirectory($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRuntimeDirectory() => $_has(4);
  @$pb.TagNumber(5)
  void clearRuntimeDirectory() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get toolId => $_getSZ(5);
  @$pb.TagNumber(6)
  set toolId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasToolId() => $_has(5);
  @$pb.TagNumber(6)
  void clearToolId() => $_clearField(6);
}

class ProtonContextFile extends $pb.GeneratedMessage {
  factory ProtonContextFile({
    $core.String? path,
    $core.String? nativeIdentity,
    $core.String? sha256,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (nativeIdentity != null) result.nativeIdentity = nativeIdentity;
    if (sha256 != null) result.sha256 = sha256;
    return result;
  }

  ProtonContextFile._();

  factory ProtonContextFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonContextFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonContextFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'nativeIdentity')
    ..aOS(3, _omitFieldNames ? '' : 'sha256')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonContextFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonContextFile copyWith(void Function(ProtonContextFile) updates) =>
      super.copyWith((message) => updates(message as ProtonContextFile))
          as ProtonContextFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonContextFile create() => ProtonContextFile._();
  @$core.override
  ProtonContextFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonContextFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonContextFile>(create);
  static ProtonContextFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get nativeIdentity => $_getSZ(1);
  @$pb.TagNumber(2)
  set nativeIdentity($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNativeIdentity() => $_has(1);
  @$pb.TagNumber(2)
  void clearNativeIdentity() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sha256 => $_getSZ(2);
  @$pb.TagNumber(3)
  set sha256($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSha256() => $_has(2);
  @$pb.TagNumber(3)
  void clearSha256() => $_clearField(3);
}

class ProtonLocatedPath extends $pb.GeneratedMessage {
  factory ProtonLocatedPath({
    $core.String? path,
    $core.bool? exists,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (exists != null) result.exists = exists;
    return result;
  }

  ProtonLocatedPath._();

  factory ProtonLocatedPath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonLocatedPath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonLocatedPath',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOB(2, _omitFieldNames ? '' : 'exists')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonLocatedPath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonLocatedPath copyWith(void Function(ProtonLocatedPath) updates) =>
      super.copyWith((message) => updates(message as ProtonLocatedPath))
          as ProtonLocatedPath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonLocatedPath create() => ProtonLocatedPath._();
  @$core.override
  ProtonLocatedPath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonLocatedPath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonLocatedPath>(create);
  static ProtonLocatedPath? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get exists => $_getBF(1);
  @$pb.TagNumber(2)
  set exists($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExists() => $_has(1);
  @$pb.TagNumber(2)
  void clearExists() => $_clearField(2);
}

enum ProtonUserPath_Result { located, unavailableReason, notSet }

class ProtonUserPath extends $pb.GeneratedMessage {
  factory ProtonUserPath({
    $core.String? name,
    $core.String? windowsPath,
    ProtonLocatedPath? located,
    $core.String? unavailableReason,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (windowsPath != null) result.windowsPath = windowsPath;
    if (located != null) result.located = located;
    if (unavailableReason != null) result.unavailableReason = unavailableReason;
    return result;
  }

  ProtonUserPath._();

  factory ProtonUserPath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonUserPath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProtonUserPath_Result>
      _ProtonUserPath_ResultByTag = {
    3: ProtonUserPath_Result.located,
    4: ProtonUserPath_Result.unavailableReason,
    0: ProtonUserPath_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonUserPath',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'windowsPath')
    ..aOM<ProtonLocatedPath>(3, _omitFieldNames ? '' : 'located',
        subBuilder: ProtonLocatedPath.create)
    ..aOS(4, _omitFieldNames ? '' : 'unavailableReason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonUserPath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonUserPath copyWith(void Function(ProtonUserPath) updates) =>
      super.copyWith((message) => updates(message as ProtonUserPath))
          as ProtonUserPath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonUserPath create() => ProtonUserPath._();
  @$core.override
  ProtonUserPath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonUserPath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonUserPath>(create);
  static ProtonUserPath? _defaultInstance;

  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  ProtonUserPath_Result whichResult() =>
      _ProtonUserPath_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get windowsPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set windowsPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWindowsPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearWindowsPath() => $_clearField(2);

  @$pb.TagNumber(3)
  ProtonLocatedPath get located => $_getN(2);
  @$pb.TagNumber(3)
  set located(ProtonLocatedPath value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLocated() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocated() => $_clearField(3);
  @$pb.TagNumber(3)
  ProtonLocatedPath ensureLocated() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get unavailableReason => $_getSZ(3);
  @$pb.TagNumber(4)
  set unavailableReason($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUnavailableReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearUnavailableReason() => $_clearField(4);
}

class ProtonContextEvidence extends $pb.GeneratedMessage {
  factory ProtonContextEvidence({
    ProtonSelectionInfo? selection,
    $core.String? prefixPath,
    $core.String? prefixIdentity,
    $core.String? compatDataIdentity,
    $core.String? runtimeIdentity,
    $core.String? runtimeName,
    $core.String? runtimeVersion,
    $core.String? prefixVersion,
    ProtonContextFile? launcher,
    $core.Iterable<ProtonContextFile>? metadata,
    $core.String? perGameTool,
    $core.String? globalTool,
    $core.Iterable<ProtonUserPath>? paths,
    $core.String? mappingProblem,
  }) {
    final result = create();
    if (selection != null) result.selection = selection;
    if (prefixPath != null) result.prefixPath = prefixPath;
    if (prefixIdentity != null) result.prefixIdentity = prefixIdentity;
    if (compatDataIdentity != null)
      result.compatDataIdentity = compatDataIdentity;
    if (runtimeIdentity != null) result.runtimeIdentity = runtimeIdentity;
    if (runtimeName != null) result.runtimeName = runtimeName;
    if (runtimeVersion != null) result.runtimeVersion = runtimeVersion;
    if (prefixVersion != null) result.prefixVersion = prefixVersion;
    if (launcher != null) result.launcher = launcher;
    if (metadata != null) result.metadata.addAll(metadata);
    if (perGameTool != null) result.perGameTool = perGameTool;
    if (globalTool != null) result.globalTool = globalTool;
    if (paths != null) result.paths.addAll(paths);
    if (mappingProblem != null) result.mappingProblem = mappingProblem;
    return result;
  }

  ProtonContextEvidence._();

  factory ProtonContextEvidence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonContextEvidence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonContextEvidence',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ProtonSelectionInfo>(1, _omitFieldNames ? '' : 'selection',
        subBuilder: ProtonSelectionInfo.create)
    ..aOS(2, _omitFieldNames ? '' : 'prefixPath')
    ..aOS(3, _omitFieldNames ? '' : 'prefixIdentity')
    ..aOS(4, _omitFieldNames ? '' : 'compatDataIdentity')
    ..aOS(5, _omitFieldNames ? '' : 'runtimeIdentity')
    ..aOS(6, _omitFieldNames ? '' : 'runtimeName')
    ..aOS(7, _omitFieldNames ? '' : 'runtimeVersion')
    ..aOS(8, _omitFieldNames ? '' : 'prefixVersion')
    ..aOM<ProtonContextFile>(9, _omitFieldNames ? '' : 'launcher',
        subBuilder: ProtonContextFile.create)
    ..pPM<ProtonContextFile>(10, _omitFieldNames ? '' : 'metadata',
        subBuilder: ProtonContextFile.create)
    ..aOS(11, _omitFieldNames ? '' : 'perGameTool')
    ..aOS(12, _omitFieldNames ? '' : 'globalTool')
    ..pPM<ProtonUserPath>(13, _omitFieldNames ? '' : 'paths',
        subBuilder: ProtonUserPath.create)
    ..aOS(14, _omitFieldNames ? '' : 'mappingProblem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonContextEvidence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonContextEvidence copyWith(
          void Function(ProtonContextEvidence) updates) =>
      super.copyWith((message) => updates(message as ProtonContextEvidence))
          as ProtonContextEvidence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonContextEvidence create() => ProtonContextEvidence._();
  @$core.override
  ProtonContextEvidence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonContextEvidence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonContextEvidence>(create);
  static ProtonContextEvidence? _defaultInstance;

  @$pb.TagNumber(1)
  ProtonSelectionInfo get selection => $_getN(0);
  @$pb.TagNumber(1)
  set selection(ProtonSelectionInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSelection() => $_has(0);
  @$pb.TagNumber(1)
  void clearSelection() => $_clearField(1);
  @$pb.TagNumber(1)
  ProtonSelectionInfo ensureSelection() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get prefixPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set prefixPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPrefixPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrefixPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get prefixIdentity => $_getSZ(2);
  @$pb.TagNumber(3)
  set prefixIdentity($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPrefixIdentity() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrefixIdentity() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get compatDataIdentity => $_getSZ(3);
  @$pb.TagNumber(4)
  set compatDataIdentity($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCompatDataIdentity() => $_has(3);
  @$pb.TagNumber(4)
  void clearCompatDataIdentity() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get runtimeIdentity => $_getSZ(4);
  @$pb.TagNumber(5)
  set runtimeIdentity($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRuntimeIdentity() => $_has(4);
  @$pb.TagNumber(5)
  void clearRuntimeIdentity() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get runtimeName => $_getSZ(5);
  @$pb.TagNumber(6)
  set runtimeName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRuntimeName() => $_has(5);
  @$pb.TagNumber(6)
  void clearRuntimeName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get runtimeVersion => $_getSZ(6);
  @$pb.TagNumber(7)
  set runtimeVersion($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRuntimeVersion() => $_has(6);
  @$pb.TagNumber(7)
  void clearRuntimeVersion() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get prefixVersion => $_getSZ(7);
  @$pb.TagNumber(8)
  set prefixVersion($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPrefixVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearPrefixVersion() => $_clearField(8);

  @$pb.TagNumber(9)
  ProtonContextFile get launcher => $_getN(8);
  @$pb.TagNumber(9)
  set launcher(ProtonContextFile value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasLauncher() => $_has(8);
  @$pb.TagNumber(9)
  void clearLauncher() => $_clearField(9);
  @$pb.TagNumber(9)
  ProtonContextFile ensureLauncher() => $_ensure(8);

  @$pb.TagNumber(10)
  $pb.PbList<ProtonContextFile> get metadata => $_getList(9);

  @$pb.TagNumber(11)
  $core.String get perGameTool => $_getSZ(10);
  @$pb.TagNumber(11)
  set perGameTool($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPerGameTool() => $_has(10);
  @$pb.TagNumber(11)
  void clearPerGameTool() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get globalTool => $_getSZ(11);
  @$pb.TagNumber(12)
  set globalTool($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasGlobalTool() => $_has(11);
  @$pb.TagNumber(12)
  void clearGlobalTool() => $_clearField(12);

  @$pb.TagNumber(13)
  $pb.PbList<ProtonUserPath> get paths => $_getList(12);

  @$pb.TagNumber(14)
  $core.String get mappingProblem => $_getSZ(13);
  @$pb.TagNumber(14)
  set mappingProblem($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasMappingProblem() => $_has(13);
  @$pb.TagNumber(14)
  void clearMappingProblem() => $_clearField(14);
}

class ProtonPrefixCandidate extends $pb.GeneratedMessage {
  factory ProtonPrefixCandidate({
    $core.String? candidateId,
    $core.String? compatData,
    $core.String? prefixPath,
    $core.Iterable<$1.SteamInstallationOrigin>? origins,
  }) {
    final result = create();
    if (candidateId != null) result.candidateId = candidateId;
    if (compatData != null) result.compatData = compatData;
    if (prefixPath != null) result.prefixPath = prefixPath;
    if (origins != null) result.origins.addAll(origins);
    return result;
  }

  ProtonPrefixCandidate._();

  factory ProtonPrefixCandidate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonPrefixCandidate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonPrefixCandidate',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'candidateId')
    ..aOS(2, _omitFieldNames ? '' : 'compatData')
    ..aOS(3, _omitFieldNames ? '' : 'prefixPath')
    ..pPM<$1.SteamInstallationOrigin>(4, _omitFieldNames ? '' : 'origins',
        subBuilder: $1.SteamInstallationOrigin.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonPrefixCandidate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonPrefixCandidate copyWith(
          void Function(ProtonPrefixCandidate) updates) =>
      super.copyWith((message) => updates(message as ProtonPrefixCandidate))
          as ProtonPrefixCandidate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonPrefixCandidate create() => ProtonPrefixCandidate._();
  @$core.override
  ProtonPrefixCandidate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonPrefixCandidate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonPrefixCandidate>(create);
  static ProtonPrefixCandidate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get candidateId => $_getSZ(0);
  @$pb.TagNumber(1)
  set candidateId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCandidateId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCandidateId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get compatData => $_getSZ(1);
  @$pb.TagNumber(2)
  set compatData($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCompatData() => $_has(1);
  @$pb.TagNumber(2)
  void clearCompatData() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get prefixPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set prefixPath($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPrefixPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrefixPath() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$1.SteamInstallationOrigin> get origins => $_getList(3);
}

class ProtonInstalledTool extends $pb.GeneratedMessage {
  factory ProtonInstalledTool({
    $core.String? toolId,
    $core.String? name,
    $core.String? directory,
    ProtonContextFile? source,
  }) {
    final result = create();
    if (toolId != null) result.toolId = toolId;
    if (name != null) result.name = name;
    if (directory != null) result.directory = directory;
    if (source != null) result.source = source;
    return result;
  }

  ProtonInstalledTool._();

  factory ProtonInstalledTool.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonInstalledTool.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonInstalledTool',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'toolId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'directory')
    ..aOM<ProtonContextFile>(4, _omitFieldNames ? '' : 'source',
        subBuilder: ProtonContextFile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonInstalledTool clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonInstalledTool copyWith(void Function(ProtonInstalledTool) updates) =>
      super.copyWith((message) => updates(message as ProtonInstalledTool))
          as ProtonInstalledTool;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonInstalledTool create() => ProtonInstalledTool._();
  @$core.override
  ProtonInstalledTool createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonInstalledTool getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonInstalledTool>(create);
  static ProtonInstalledTool? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get toolId => $_getSZ(0);
  @$pb.TagNumber(1)
  set toolId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToolId() => $_has(0);
  @$pb.TagNumber(1)
  void clearToolId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get directory => $_getSZ(2);
  @$pb.TagNumber(3)
  set directory($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDirectory() => $_has(2);
  @$pb.TagNumber(3)
  void clearDirectory() => $_clearField(3);

  @$pb.TagNumber(4)
  ProtonContextFile get source => $_getN(3);
  @$pb.TagNumber(4)
  set source(ProtonContextFile value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSource() => $_has(3);
  @$pb.TagNumber(4)
  void clearSource() => $_clearField(4);
  @$pb.TagNumber(4)
  ProtonContextFile ensureSource() => $_ensure(3);
}

class ProtonToolMapping extends $pb.GeneratedMessage {
  factory ProtonToolMapping({
    $core.String? perGame,
    $core.String? globalDefault,
    ProtonContextFile? source,
  }) {
    final result = create();
    if (perGame != null) result.perGame = perGame;
    if (globalDefault != null) result.globalDefault = globalDefault;
    if (source != null) result.source = source;
    return result;
  }

  ProtonToolMapping._();

  factory ProtonToolMapping.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonToolMapping.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonToolMapping',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'perGame')
    ..aOS(2, _omitFieldNames ? '' : 'globalDefault')
    ..aOM<ProtonContextFile>(3, _omitFieldNames ? '' : 'source',
        subBuilder: ProtonContextFile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonToolMapping clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonToolMapping copyWith(void Function(ProtonToolMapping) updates) =>
      super.copyWith((message) => updates(message as ProtonToolMapping))
          as ProtonToolMapping;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonToolMapping create() => ProtonToolMapping._();
  @$core.override
  ProtonToolMapping createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonToolMapping getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonToolMapping>(create);
  static ProtonToolMapping? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get perGame => $_getSZ(0);
  @$pb.TagNumber(1)
  set perGame($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPerGame() => $_has(0);
  @$pb.TagNumber(1)
  void clearPerGame() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get globalDefault => $_getSZ(1);
  @$pb.TagNumber(2)
  set globalDefault($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGlobalDefault() => $_has(1);
  @$pb.TagNumber(2)
  void clearGlobalDefault() => $_clearField(2);

  @$pb.TagNumber(3)
  ProtonContextFile get source => $_getN(2);
  @$pb.TagNumber(3)
  set source(ProtonContextFile value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);
  @$pb.TagNumber(3)
  ProtonContextFile ensureSource() => $_ensure(2);
}

class ProtonSearchProblem extends $pb.GeneratedMessage {
  factory ProtonSearchProblem({
    $core.String? path,
    $core.String? detail,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (detail != null) result.detail = detail;
    return result;
  }

  ProtonSearchProblem._();

  factory ProtonSearchProblem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonSearchProblem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonSearchProblem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonSearchProblem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonSearchProblem copyWith(void Function(ProtonSearchProblem) updates) =>
      super.copyWith((message) => updates(message as ProtonSearchProblem))
          as ProtonSearchProblem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonSearchProblem create() => ProtonSearchProblem._();
  @$core.override
  ProtonSearchProblem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonSearchProblem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonSearchProblem>(create);
  static ProtonSearchProblem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get detail => $_getSZ(1);
  @$pb.TagNumber(2)
  set detail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDetail() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetail() => $_clearField(2);
}

class ProtonSearchResult extends $pb.GeneratedMessage {
  factory ProtonSearchResult({
    $core.Iterable<ProtonPrefixCandidate>? prefixes,
    $core.Iterable<ProtonInstalledTool>? tools,
    $core.Iterable<ProtonToolMapping>? mappings,
    $core.Iterable<ProtonSearchProblem>? problems,
    $core.bool? limited,
  }) {
    final result = create();
    if (prefixes != null) result.prefixes.addAll(prefixes);
    if (tools != null) result.tools.addAll(tools);
    if (mappings != null) result.mappings.addAll(mappings);
    if (problems != null) result.problems.addAll(problems);
    if (limited != null) result.limited = limited;
    return result;
  }

  ProtonSearchResult._();

  factory ProtonSearchResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProtonSearchResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProtonSearchResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<ProtonPrefixCandidate>(1, _omitFieldNames ? '' : 'prefixes',
        subBuilder: ProtonPrefixCandidate.create)
    ..pPM<ProtonInstalledTool>(2, _omitFieldNames ? '' : 'tools',
        subBuilder: ProtonInstalledTool.create)
    ..pPM<ProtonToolMapping>(3, _omitFieldNames ? '' : 'mappings',
        subBuilder: ProtonToolMapping.create)
    ..pPM<ProtonSearchProblem>(4, _omitFieldNames ? '' : 'problems',
        subBuilder: ProtonSearchProblem.create)
    ..aOB(5, _omitFieldNames ? '' : 'limited')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonSearchResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProtonSearchResult copyWith(void Function(ProtonSearchResult) updates) =>
      super.copyWith((message) => updates(message as ProtonSearchResult))
          as ProtonSearchResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProtonSearchResult create() => ProtonSearchResult._();
  @$core.override
  ProtonSearchResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProtonSearchResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProtonSearchResult>(create);
  static ProtonSearchResult? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ProtonPrefixCandidate> get prefixes => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<ProtonInstalledTool> get tools => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<ProtonToolMapping> get mappings => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<ProtonSearchProblem> get problems => $_getList(3);

  @$pb.TagNumber(5)
  $core.bool get limited => $_getBF(4);
  @$pb.TagNumber(5)
  set limited($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLimited() => $_has(4);
  @$pb.TagNumber(5)
  void clearLimited() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
