// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_transport.proto.

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

class InspectProfileTransportRequest extends $pb.GeneratedMessage {
  factory InspectProfileTransportRequest({
    $core.String? path,
  }) {
    final result = create();
    if (path != null) result.path = path;
    return result;
  }

  InspectProfileTransportRequest._();

  factory InspectProfileTransportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InspectProfileTransportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InspectProfileTransportRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectProfileTransportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectProfileTransportRequest copyWith(
          void Function(InspectProfileTransportRequest) updates) =>
      super.copyWith(
              (message) => updates(message as InspectProfileTransportRequest))
          as InspectProfileTransportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InspectProfileTransportRequest create() =>
      InspectProfileTransportRequest._();
  @$core.override
  InspectProfileTransportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InspectProfileTransportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InspectProfileTransportRequest>(create);
  static InspectProfileTransportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
}

class PreviewExportProfileTransportRequest extends $pb.GeneratedMessage {
  factory PreviewExportProfileTransportRequest({
    $core.String? workspaceId,
    $core.String? profileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  PreviewExportProfileTransportRequest._();

  factory PreviewExportProfileTransportRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreviewExportProfileTransportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewExportProfileTransportRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewExportProfileTransportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewExportProfileTransportRequest copyWith(
          void Function(PreviewExportProfileTransportRequest) updates) =>
      super.copyWith((message) =>
              updates(message as PreviewExportProfileTransportRequest))
          as PreviewExportProfileTransportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreviewExportProfileTransportRequest create() =>
      PreviewExportProfileTransportRequest._();
  @$core.override
  PreviewExportProfileTransportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreviewExportProfileTransportRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          PreviewExportProfileTransportRequest>(create);
  static PreviewExportProfileTransportRequest? _defaultInstance;

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
}

class ProfileSourceRequirement extends $pb.GeneratedMessage {
  factory ProfileSourceRequirement({
    $core.int? modIndex,
    $core.String? modName,
    $core.String? archiveName,
    $core.String? sha256,
    $fixnum.Int64? length,
    $core.String? providerGame,
    $fixnum.Int64? providerMod,
    $fixnum.Int64? providerFile,
    $core.String? providerVersion,
  }) {
    final result = create();
    if (modIndex != null) result.modIndex = modIndex;
    if (modName != null) result.modName = modName;
    if (archiveName != null) result.archiveName = archiveName;
    if (sha256 != null) result.sha256 = sha256;
    if (length != null) result.length = length;
    if (providerGame != null) result.providerGame = providerGame;
    if (providerMod != null) result.providerMod = providerMod;
    if (providerFile != null) result.providerFile = providerFile;
    if (providerVersion != null) result.providerVersion = providerVersion;
    return result;
  }

  ProfileSourceRequirement._();

  factory ProfileSourceRequirement.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSourceRequirement.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSourceRequirement',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'modIndex', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'modName')
    ..aOS(3, _omitFieldNames ? '' : 'archiveName')
    ..aOS(4, _omitFieldNames ? '' : 'sha256')
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(6, _omitFieldNames ? '' : 'providerGame')
    ..aInt64(7, _omitFieldNames ? '' : 'providerMod')
    ..aInt64(8, _omitFieldNames ? '' : 'providerFile')
    ..aOS(9, _omitFieldNames ? '' : 'providerVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSourceRequirement clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSourceRequirement copyWith(
          void Function(ProfileSourceRequirement) updates) =>
      super.copyWith((message) => updates(message as ProfileSourceRequirement))
          as ProfileSourceRequirement;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSourceRequirement create() => ProfileSourceRequirement._();
  @$core.override
  ProfileSourceRequirement createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSourceRequirement getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSourceRequirement>(create);
  static ProfileSourceRequirement? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get modIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set modIndex($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearModIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modName => $_getSZ(1);
  @$pb.TagNumber(2)
  set modName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModName() => $_has(1);
  @$pb.TagNumber(2)
  void clearModName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get archiveName => $_getSZ(2);
  @$pb.TagNumber(3)
  set archiveName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasArchiveName() => $_has(2);
  @$pb.TagNumber(3)
  void clearArchiveName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sha256 => $_getSZ(3);
  @$pb.TagNumber(4)
  set sha256($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSha256() => $_has(3);
  @$pb.TagNumber(4)
  void clearSha256() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get length => $_getI64(4);
  @$pb.TagNumber(5)
  set length($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLength() => $_has(4);
  @$pb.TagNumber(5)
  void clearLength() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get providerGame => $_getSZ(5);
  @$pb.TagNumber(6)
  set providerGame($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProviderGame() => $_has(5);
  @$pb.TagNumber(6)
  void clearProviderGame() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get providerMod => $_getI64(6);
  @$pb.TagNumber(7)
  set providerMod($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProviderMod() => $_has(6);
  @$pb.TagNumber(7)
  void clearProviderMod() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get providerFile => $_getI64(7);
  @$pb.TagNumber(8)
  set providerFile($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasProviderFile() => $_has(7);
  @$pb.TagNumber(8)
  void clearProviderFile() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get providerVersion => $_getSZ(8);
  @$pb.TagNumber(9)
  set providerVersion($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasProviderVersion() => $_has(8);
  @$pb.TagNumber(9)
  void clearProviderVersion() => $_clearField(9);
}

class ProfileTransportPreview extends $pb.GeneratedMessage {
  factory ProfileTransportPreview({
    $core.String? name,
    $core.String? game,
    $core.int? modCount,
    $core.int? saveFileCount,
    $fixnum.Int64? saveBytes,
    $core.Iterable<ProfileSourceRequirement>? sources,
    $core.int? modFileCount,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (game != null) result.game = game;
    if (modCount != null) result.modCount = modCount;
    if (saveFileCount != null) result.saveFileCount = saveFileCount;
    if (saveBytes != null) result.saveBytes = saveBytes;
    if (sources != null) result.sources.addAll(sources);
    if (modFileCount != null) result.modFileCount = modFileCount;
    return result;
  }

  ProfileTransportPreview._();

  factory ProfileTransportPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileTransportPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileTransportPreview',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'game')
    ..aI(3, _omitFieldNames ? '' : 'modCount', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'saveFileCount',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'saveBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<ProfileSourceRequirement>(6, _omitFieldNames ? '' : 'sources',
        subBuilder: ProfileSourceRequirement.create)
    ..aI(7, _omitFieldNames ? '' : 'modFileCount',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileTransportPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileTransportPreview copyWith(
          void Function(ProfileTransportPreview) updates) =>
      super.copyWith((message) => updates(message as ProfileTransportPreview))
          as ProfileTransportPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileTransportPreview create() => ProfileTransportPreview._();
  @$core.override
  ProfileTransportPreview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileTransportPreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileTransportPreview>(create);
  static ProfileTransportPreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get game => $_getSZ(1);
  @$pb.TagNumber(2)
  set game($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGame() => $_has(1);
  @$pb.TagNumber(2)
  void clearGame() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get modCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set modCount($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearModCount() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get saveFileCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set saveFileCount($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSaveFileCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearSaveFileCount() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get saveBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set saveBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSaveBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearSaveBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<ProfileSourceRequirement> get sources => $_getList(5);

  @$pb.TagNumber(7)
  $core.int get modFileCount => $_getIZ(6);
  @$pb.TagNumber(7)
  set modFileCount($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasModFileCount() => $_has(6);
  @$pb.TagNumber(7)
  void clearModFileCount() => $_clearField(7);
}

class ExportProfileTransportRequest extends $pb.GeneratedMessage {
  factory ExportProfileTransportRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? destination,
    $core.bool? includeSaves,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (destination != null) result.destination = destination;
    if (includeSaves != null) result.includeSaves = includeSaves;
    return result;
  }

  ExportProfileTransportRequest._();

  factory ExportProfileTransportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExportProfileTransportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExportProfileTransportRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'destination')
    ..aOB(4, _omitFieldNames ? '' : 'includeSaves')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportProfileTransportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportProfileTransportRequest copyWith(
          void Function(ExportProfileTransportRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ExportProfileTransportRequest))
          as ExportProfileTransportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportProfileTransportRequest create() =>
      ExportProfileTransportRequest._();
  @$core.override
  ExportProfileTransportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExportProfileTransportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportProfileTransportRequest>(create);
  static ExportProfileTransportRequest? _defaultInstance;

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
  $core.String get destination => $_getSZ(2);
  @$pb.TagNumber(3)
  set destination($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDestination() => $_has(2);
  @$pb.TagNumber(3)
  void clearDestination() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get includeSaves => $_getBF(3);
  @$pb.TagNumber(4)
  set includeSaves($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIncludeSaves() => $_has(3);
  @$pb.TagNumber(4)
  void clearIncludeSaves() => $_clearField(4);
}

class ManualProfileSource extends $pb.GeneratedMessage {
  factory ManualProfileSource({
    $core.int? modIndex,
    $core.String? path,
  }) {
    final result = create();
    if (modIndex != null) result.modIndex = modIndex;
    if (path != null) result.path = path;
    return result;
  }

  ManualProfileSource._();

  factory ManualProfileSource.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ManualProfileSource.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ManualProfileSource',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'modIndex', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManualProfileSource clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManualProfileSource copyWith(void Function(ManualProfileSource) updates) =>
      super.copyWith((message) => updates(message as ManualProfileSource))
          as ManualProfileSource;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ManualProfileSource create() => ManualProfileSource._();
  @$core.override
  ManualProfileSource createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ManualProfileSource getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ManualProfileSource>(create);
  static ManualProfileSource? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get modIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set modIndex($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearModIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
}

class ImportProfileTransportRequest extends $pb.GeneratedMessage {
  factory ImportProfileTransportRequest({
    $core.String? path,
    $core.String? workspaceId,
    $core.String? gameProfileId,
    $core.String? profileName,
    $core.Iterable<ManualProfileSource>? manualSources,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (gameProfileId != null) result.gameProfileId = gameProfileId;
    if (profileName != null) result.profileName = profileName;
    if (manualSources != null) result.manualSources.addAll(manualSources);
    return result;
  }

  ImportProfileTransportRequest._();

  factory ImportProfileTransportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ImportProfileTransportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ImportProfileTransportRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'gameProfileId')
    ..aOS(4, _omitFieldNames ? '' : 'profileName')
    ..pPM<ManualProfileSource>(5, _omitFieldNames ? '' : 'manualSources',
        subBuilder: ManualProfileSource.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportProfileTransportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ImportProfileTransportRequest copyWith(
          void Function(ImportProfileTransportRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ImportProfileTransportRequest))
          as ImportProfileTransportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImportProfileTransportRequest create() =>
      ImportProfileTransportRequest._();
  @$core.override
  ImportProfileTransportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ImportProfileTransportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ImportProfileTransportRequest>(create);
  static ImportProfileTransportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get gameProfileId => $_getSZ(2);
  @$pb.TagNumber(3)
  set gameProfileId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGameProfileId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGameProfileId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get profileName => $_getSZ(3);
  @$pb.TagNumber(4)
  set profileName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProfileName() => $_has(3);
  @$pb.TagNumber(4)
  void clearProfileName() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<ManualProfileSource> get manualSources => $_getList(4);
}

class ProfileTransportResult extends $pb.GeneratedMessage {
  factory ProfileTransportResult({
    $core.String? profileId,
    $core.String? problem,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (problem != null) result.problem = problem;
    return result;
  }

  ProfileTransportResult._();

  factory ProfileTransportResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileTransportResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileTransportResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOS(2, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileTransportResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileTransportResult copyWith(
          void Function(ProfileTransportResult) updates) =>
      super.copyWith((message) => updates(message as ProfileTransportResult))
          as ProfileTransportResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileTransportResult create() => ProfileTransportResult._();
  @$core.override
  ProfileTransportResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileTransportResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileTransportResult>(create);
  static ProfileTransportResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get problem => $_getSZ(1);
  @$pb.TagNumber(2)
  set problem($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
