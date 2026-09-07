// This is a generated file - do not edit.
//
// Generated from modconductor/v1/steam_discovery.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'steam_discovery.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'steam_discovery.pbenum.dart';

class SteamSearchRequest extends $pb.GeneratedMessage {
  factory SteamSearchRequest({
    $core.String? definitionId,
    $core.Iterable<$core.String>? additionalRoots,
  }) {
    final result = create();
    if (definitionId != null) result.definitionId = definitionId;
    if (additionalRoots != null) result.additionalRoots.addAll(additionalRoots);
    return result;
  }

  SteamSearchRequest._();

  factory SteamSearchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SteamSearchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SteamSearchRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'definitionId')
    ..pPS(2, _omitFieldNames ? '' : 'additionalRoots')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamSearchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamSearchRequest copyWith(void Function(SteamSearchRequest) updates) =>
      super.copyWith((message) => updates(message as SteamSearchRequest))
          as SteamSearchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SteamSearchRequest create() => SteamSearchRequest._();
  @$core.override
  SteamSearchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SteamSearchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SteamSearchRequest>(create);
  static SteamSearchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get definitionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set definitionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDefinitionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDefinitionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get additionalRoots => $_getList(1);
}

class SteamSearchRoot extends $pb.GeneratedMessage {
  factory SteamSearchRoot({
    $core.String? path,
    $core.String? origin,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (origin != null) result.origin = origin;
    return result;
  }

  SteamSearchRoot._();

  factory SteamSearchRoot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SteamSearchRoot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SteamSearchRoot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'origin')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamSearchRoot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamSearchRoot copyWith(void Function(SteamSearchRoot) updates) =>
      super.copyWith((message) => updates(message as SteamSearchRoot))
          as SteamSearchRoot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SteamSearchRoot create() => SteamSearchRoot._();
  @$core.override
  SteamSearchRoot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SteamSearchRoot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SteamSearchRoot>(create);
  static SteamSearchRoot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get origin => $_getSZ(1);
  @$pb.TagNumber(2)
  set origin($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOrigin() => $_has(1);
  @$pb.TagNumber(2)
  void clearOrigin() => $_clearField(2);
}

class SteamDirectory extends $pb.GeneratedMessage {
  factory SteamDirectory({
    $core.String? declaredPath,
    $core.String? canonicalPath,
    $core.String? nativeIdentity,
  }) {
    final result = create();
    if (declaredPath != null) result.declaredPath = declaredPath;
    if (canonicalPath != null) result.canonicalPath = canonicalPath;
    if (nativeIdentity != null) result.nativeIdentity = nativeIdentity;
    return result;
  }

  SteamDirectory._();

  factory SteamDirectory.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SteamDirectory.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SteamDirectory',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'declaredPath')
    ..aOS(2, _omitFieldNames ? '' : 'canonicalPath')
    ..aOS(3, _omitFieldNames ? '' : 'nativeIdentity')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamDirectory clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamDirectory copyWith(void Function(SteamDirectory) updates) =>
      super.copyWith((message) => updates(message as SteamDirectory))
          as SteamDirectory;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SteamDirectory create() => SteamDirectory._();
  @$core.override
  SteamDirectory createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SteamDirectory getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SteamDirectory>(create);
  static SteamDirectory? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get declaredPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set declaredPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeclaredPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeclaredPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get canonicalPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set canonicalPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCanonicalPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearCanonicalPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get nativeIdentity => $_getSZ(2);
  @$pb.TagNumber(3)
  set nativeIdentity($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNativeIdentity() => $_has(2);
  @$pb.TagNumber(3)
  void clearNativeIdentity() => $_clearField(3);
}

class SteamManifestEvidence extends $pb.GeneratedMessage {
  factory SteamManifestEvidence({
    $core.String? path,
    $core.String? nativeIdentity,
    $core.String? sha256,
    $core.int? appId,
    $core.String? installDirectory,
    $core.String? name,
    $core.String? buildId,
    $fixnum.Int64? stateFlags,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (nativeIdentity != null) result.nativeIdentity = nativeIdentity;
    if (sha256 != null) result.sha256 = sha256;
    if (appId != null) result.appId = appId;
    if (installDirectory != null) result.installDirectory = installDirectory;
    if (name != null) result.name = name;
    if (buildId != null) result.buildId = buildId;
    if (stateFlags != null) result.stateFlags = stateFlags;
    return result;
  }

  SteamManifestEvidence._();

  factory SteamManifestEvidence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SteamManifestEvidence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SteamManifestEvidence',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'nativeIdentity')
    ..aOS(3, _omitFieldNames ? '' : 'sha256')
    ..aI(4, _omitFieldNames ? '' : 'appId', fieldType: $pb.PbFieldType.OU3)
    ..aOS(5, _omitFieldNames ? '' : 'installDirectory')
    ..aOS(6, _omitFieldNames ? '' : 'name')
    ..aOS(7, _omitFieldNames ? '' : 'buildId')
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'stateFlags', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamManifestEvidence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamManifestEvidence copyWith(
          void Function(SteamManifestEvidence) updates) =>
      super.copyWith((message) => updates(message as SteamManifestEvidence))
          as SteamManifestEvidence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SteamManifestEvidence create() => SteamManifestEvidence._();
  @$core.override
  SteamManifestEvidence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SteamManifestEvidence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SteamManifestEvidence>(create);
  static SteamManifestEvidence? _defaultInstance;

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

  @$pb.TagNumber(4)
  $core.int get appId => $_getIZ(3);
  @$pb.TagNumber(4)
  set appId($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAppId() => $_has(3);
  @$pb.TagNumber(4)
  void clearAppId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get installDirectory => $_getSZ(4);
  @$pb.TagNumber(5)
  set installDirectory($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInstallDirectory() => $_has(4);
  @$pb.TagNumber(5)
  void clearInstallDirectory() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get name => $_getSZ(5);
  @$pb.TagNumber(6)
  set name($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasName() => $_has(5);
  @$pb.TagNumber(6)
  void clearName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get buildId => $_getSZ(6);
  @$pb.TagNumber(7)
  set buildId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBuildId() => $_has(6);
  @$pb.TagNumber(7)
  void clearBuildId() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get stateFlags => $_getI64(7);
  @$pb.TagNumber(8)
  set stateFlags($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasStateFlags() => $_has(7);
  @$pb.TagNumber(8)
  void clearStateFlags() => $_clearField(8);
}

class SteamInstallationOrigin extends $pb.GeneratedMessage {
  factory SteamInstallationOrigin({
    SteamSearchRoot? root,
    SteamDirectory? steamRoot,
    SteamDirectory? library,
    $core.String? libraryEntry,
    SteamManifestEvidence? manifest,
  }) {
    final result = create();
    if (root != null) result.root = root;
    if (steamRoot != null) result.steamRoot = steamRoot;
    if (library != null) result.library = library;
    if (libraryEntry != null) result.libraryEntry = libraryEntry;
    if (manifest != null) result.manifest = manifest;
    return result;
  }

  SteamInstallationOrigin._();

  factory SteamInstallationOrigin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SteamInstallationOrigin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SteamInstallationOrigin',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<SteamSearchRoot>(1, _omitFieldNames ? '' : 'root',
        subBuilder: SteamSearchRoot.create)
    ..aOM<SteamDirectory>(2, _omitFieldNames ? '' : 'steamRoot',
        subBuilder: SteamDirectory.create)
    ..aOM<SteamDirectory>(3, _omitFieldNames ? '' : 'library',
        subBuilder: SteamDirectory.create)
    ..aOS(4, _omitFieldNames ? '' : 'libraryEntry')
    ..aOM<SteamManifestEvidence>(5, _omitFieldNames ? '' : 'manifest',
        subBuilder: SteamManifestEvidence.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamInstallationOrigin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamInstallationOrigin copyWith(
          void Function(SteamInstallationOrigin) updates) =>
      super.copyWith((message) => updates(message as SteamInstallationOrigin))
          as SteamInstallationOrigin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SteamInstallationOrigin create() => SteamInstallationOrigin._();
  @$core.override
  SteamInstallationOrigin createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SteamInstallationOrigin getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SteamInstallationOrigin>(create);
  static SteamInstallationOrigin? _defaultInstance;

  @$pb.TagNumber(1)
  SteamSearchRoot get root => $_getN(0);
  @$pb.TagNumber(1)
  set root(SteamSearchRoot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRoot() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoot() => $_clearField(1);
  @$pb.TagNumber(1)
  SteamSearchRoot ensureRoot() => $_ensure(0);

  @$pb.TagNumber(2)
  SteamDirectory get steamRoot => $_getN(1);
  @$pb.TagNumber(2)
  set steamRoot(SteamDirectory value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSteamRoot() => $_has(1);
  @$pb.TagNumber(2)
  void clearSteamRoot() => $_clearField(2);
  @$pb.TagNumber(2)
  SteamDirectory ensureSteamRoot() => $_ensure(1);

  @$pb.TagNumber(3)
  SteamDirectory get library => $_getN(2);
  @$pb.TagNumber(3)
  set library(SteamDirectory value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLibrary() => $_has(2);
  @$pb.TagNumber(3)
  void clearLibrary() => $_clearField(3);
  @$pb.TagNumber(3)
  SteamDirectory ensureLibrary() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get libraryEntry => $_getSZ(3);
  @$pb.TagNumber(4)
  set libraryEntry($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLibraryEntry() => $_has(3);
  @$pb.TagNumber(4)
  void clearLibraryEntry() => $_clearField(4);

  @$pb.TagNumber(5)
  SteamManifestEvidence get manifest => $_getN(4);
  @$pb.TagNumber(5)
  set manifest(SteamManifestEvidence value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasManifest() => $_has(4);
  @$pb.TagNumber(5)
  void clearManifest() => $_clearField(5);
  @$pb.TagNumber(5)
  SteamManifestEvidence ensureManifest() => $_ensure(4);
}

class SteamInstallationCandidate extends $pb.GeneratedMessage {
  factory SteamInstallationCandidate({
    $core.String? candidateId,
    SteamDirectory? directory,
    $core.Iterable<SteamInstallationOrigin>? origins,
  }) {
    final result = create();
    if (candidateId != null) result.candidateId = candidateId;
    if (directory != null) result.directory = directory;
    if (origins != null) result.origins.addAll(origins);
    return result;
  }

  SteamInstallationCandidate._();

  factory SteamInstallationCandidate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SteamInstallationCandidate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SteamInstallationCandidate',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'candidateId')
    ..aOM<SteamDirectory>(2, _omitFieldNames ? '' : 'directory',
        subBuilder: SteamDirectory.create)
    ..pPM<SteamInstallationOrigin>(3, _omitFieldNames ? '' : 'origins',
        subBuilder: SteamInstallationOrigin.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamInstallationCandidate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamInstallationCandidate copyWith(
          void Function(SteamInstallationCandidate) updates) =>
      super.copyWith(
              (message) => updates(message as SteamInstallationCandidate))
          as SteamInstallationCandidate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SteamInstallationCandidate create() => SteamInstallationCandidate._();
  @$core.override
  SteamInstallationCandidate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SteamInstallationCandidate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SteamInstallationCandidate>(create);
  static SteamInstallationCandidate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get candidateId => $_getSZ(0);
  @$pb.TagNumber(1)
  set candidateId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCandidateId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCandidateId() => $_clearField(1);

  @$pb.TagNumber(2)
  SteamDirectory get directory => $_getN(1);
  @$pb.TagNumber(2)
  set directory(SteamDirectory value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDirectory() => $_has(1);
  @$pb.TagNumber(2)
  void clearDirectory() => $_clearField(2);
  @$pb.TagNumber(2)
  SteamDirectory ensureDirectory() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<SteamInstallationOrigin> get origins => $_getList(2);
}

class SteamSearchDiagnostic extends $pb.GeneratedMessage {
  factory SteamSearchDiagnostic({
    $core.String? rootPath,
    $core.String? path,
    SteamDiscoveryProblem? kind,
    $core.String? detail,
  }) {
    final result = create();
    if (rootPath != null) result.rootPath = rootPath;
    if (path != null) result.path = path;
    if (kind != null) result.kind = kind;
    if (detail != null) result.detail = detail;
    return result;
  }

  SteamSearchDiagnostic._();

  factory SteamSearchDiagnostic.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SteamSearchDiagnostic.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SteamSearchDiagnostic',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rootPath')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aE<SteamDiscoveryProblem>(3, _omitFieldNames ? '' : 'kind',
        enumValues: SteamDiscoveryProblem.values)
    ..aOS(4, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamSearchDiagnostic clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamSearchDiagnostic copyWith(
          void Function(SteamSearchDiagnostic) updates) =>
      super.copyWith((message) => updates(message as SteamSearchDiagnostic))
          as SteamSearchDiagnostic;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SteamSearchDiagnostic create() => SteamSearchDiagnostic._();
  @$core.override
  SteamSearchDiagnostic createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SteamSearchDiagnostic getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SteamSearchDiagnostic>(create);
  static SteamSearchDiagnostic? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get rootPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set rootPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRootPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  SteamDiscoveryProblem get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(SteamDiscoveryProblem value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get detail => $_getSZ(3);
  @$pb.TagNumber(4)
  set detail($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDetail() => $_has(3);
  @$pb.TagNumber(4)
  void clearDetail() => $_clearField(4);
}

class SteamSearchResult extends $pb.GeneratedMessage {
  factory SteamSearchResult({
    $core.int? appId,
    $core.Iterable<SteamSearchRoot>? roots,
    $core.Iterable<SteamInstallationCandidate>? candidates,
    $core.Iterable<SteamSearchDiagnostic>? diagnostics,
    $core.bool? limited,
  }) {
    final result = create();
    if (appId != null) result.appId = appId;
    if (roots != null) result.roots.addAll(roots);
    if (candidates != null) result.candidates.addAll(candidates);
    if (diagnostics != null) result.diagnostics.addAll(diagnostics);
    if (limited != null) result.limited = limited;
    return result;
  }

  SteamSearchResult._();

  factory SteamSearchResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SteamSearchResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SteamSearchResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'appId', fieldType: $pb.PbFieldType.OU3)
    ..pPM<SteamSearchRoot>(2, _omitFieldNames ? '' : 'roots',
        subBuilder: SteamSearchRoot.create)
    ..pPM<SteamInstallationCandidate>(3, _omitFieldNames ? '' : 'candidates',
        subBuilder: SteamInstallationCandidate.create)
    ..pPM<SteamSearchDiagnostic>(4, _omitFieldNames ? '' : 'diagnostics',
        subBuilder: SteamSearchDiagnostic.create)
    ..aOB(5, _omitFieldNames ? '' : 'limited')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamSearchResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SteamSearchResult copyWith(void Function(SteamSearchResult) updates) =>
      super.copyWith((message) => updates(message as SteamSearchResult))
          as SteamSearchResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SteamSearchResult create() => SteamSearchResult._();
  @$core.override
  SteamSearchResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SteamSearchResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SteamSearchResult>(create);
  static SteamSearchResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get appId => $_getIZ(0);
  @$pb.TagNumber(1)
  set appId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAppId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SteamSearchRoot> get roots => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<SteamInstallationCandidate> get candidates => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<SteamSearchDiagnostic> get diagnostics => $_getList(3);

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
