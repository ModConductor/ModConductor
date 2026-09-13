// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nexus_metadata.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'nexus.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ModNexusRequest extends $pb.GeneratedMessage {
  factory ModNexusRequest({
    $core.String? workspaceId,
    $core.String? modId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (modId != null) result.modId = modId;
    return result;
  }

  ModNexusRequest._();

  factory ModNexusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModNexusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModNexusRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusRequest copyWith(void Function(ModNexusRequest) updates) =>
      super.copyWith((message) => updates(message as ModNexusRequest))
          as ModNexusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModNexusRequest create() => ModNexusRequest._();
  @$core.override
  ModNexusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModNexusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModNexusRequest>(create);
  static ModNexusRequest? _defaultInstance;

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
}

class ModNexusReference extends $pb.GeneratedMessage {
  factory ModNexusReference({
    $core.String? workspaceId,
    $core.String? modId,
    $fixnum.Int64? linkRevision,
    $core.String? versionId,
    $fixnum.Int64? providerMod,
    $fixnum.Int64? modRevision,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (modId != null) result.modId = modId;
    if (linkRevision != null) result.linkRevision = linkRevision;
    if (versionId != null) result.versionId = versionId;
    if (providerMod != null) result.providerMod = providerMod;
    if (modRevision != null) result.modRevision = modRevision;
    return result;
  }

  ModNexusReference._();

  factory ModNexusReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModNexusReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModNexusReference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..aInt64(3, _omitFieldNames ? '' : 'linkRevision')
    ..aOS(4, _omitFieldNames ? '' : 'versionId')
    ..aInt64(5, _omitFieldNames ? '' : 'providerMod')
    ..aInt64(6, _omitFieldNames ? '' : 'modRevision')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusReference copyWith(void Function(ModNexusReference) updates) =>
      super.copyWith((message) => updates(message as ModNexusReference))
          as ModNexusReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModNexusReference create() => ModNexusReference._();
  @$core.override
  ModNexusReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModNexusReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModNexusReference>(create);
  static ModNexusReference? _defaultInstance;

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
  $fixnum.Int64 get linkRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set linkRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLinkRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearLinkRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get versionId => $_getSZ(3);
  @$pb.TagNumber(4)
  set versionId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVersionId() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersionId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get providerMod => $_getI64(4);
  @$pb.TagNumber(5)
  set providerMod($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProviderMod() => $_has(4);
  @$pb.TagNumber(5)
  void clearProviderMod() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get modRevision => $_getI64(5);
  @$pb.TagNumber(6)
  set modRevision($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasModRevision() => $_has(5);
  @$pb.TagNumber(6)
  void clearModRevision() => $_clearField(6);
}

class NexusMetadataFile extends $pb.GeneratedMessage {
  factory NexusMetadataFile({
    $1.NexusFileInfo? file,
    $core.int? categoryId,
    $fixnum.Int64? uploadedUnixMs,
    $core.bool? updateCandidate,
  }) {
    final result = create();
    if (file != null) result.file = file;
    if (categoryId != null) result.categoryId = categoryId;
    if (uploadedUnixMs != null) result.uploadedUnixMs = uploadedUnixMs;
    if (updateCandidate != null) result.updateCandidate = updateCandidate;
    return result;
  }

  NexusMetadataFile._();

  factory NexusMetadataFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusMetadataFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusMetadataFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.NexusFileInfo>(1, _omitFieldNames ? '' : 'file',
        subBuilder: $1.NexusFileInfo.create)
    ..aI(2, _omitFieldNames ? '' : 'categoryId')
    ..aInt64(3, _omitFieldNames ? '' : 'uploadedUnixMs')
    ..aOB(4, _omitFieldNames ? '' : 'updateCandidate')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusMetadataFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusMetadataFile copyWith(void Function(NexusMetadataFile) updates) =>
      super.copyWith((message) => updates(message as NexusMetadataFile))
          as NexusMetadataFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusMetadataFile create() => NexusMetadataFile._();
  @$core.override
  NexusMetadataFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusMetadataFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusMetadataFile>(create);
  static NexusMetadataFile? _defaultInstance;

  @$pb.TagNumber(1)
  $1.NexusFileInfo get file => $_getN(0);
  @$pb.TagNumber(1)
  set file($1.NexusFileInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.NexusFileInfo ensureFile() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get categoryId => $_getIZ(1);
  @$pb.TagNumber(2)
  set categoryId($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCategoryId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCategoryId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get uploadedUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set uploadedUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUploadedUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearUploadedUnixMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get updateCandidate => $_getBF(3);
  @$pb.TagNumber(4)
  set updateCandidate($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUpdateCandidate() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdateCandidate() => $_clearField(4);
}

class NexusPublicMetadata extends $pb.GeneratedMessage {
  factory NexusPublicMetadata({
    $core.String? name,
    $core.String? summary,
    $core.String? version,
    $core.String? author,
    $core.String? uploader,
    $fixnum.Int64? categoryId,
    $core.String? category,
    $fixnum.Int64? modifiedUnixMs,
    $core.bool? available,
    $core.bool? allowsRating,
    $core.Iterable<NexusMetadataFile>? files,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (summary != null) result.summary = summary;
    if (version != null) result.version = version;
    if (author != null) result.author = author;
    if (uploader != null) result.uploader = uploader;
    if (categoryId != null) result.categoryId = categoryId;
    if (category != null) result.category = category;
    if (modifiedUnixMs != null) result.modifiedUnixMs = modifiedUnixMs;
    if (available != null) result.available = available;
    if (allowsRating != null) result.allowsRating = allowsRating;
    if (files != null) result.files.addAll(files);
    return result;
  }

  NexusPublicMetadata._();

  factory NexusPublicMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusPublicMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusPublicMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'summary')
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..aOS(4, _omitFieldNames ? '' : 'author')
    ..aOS(5, _omitFieldNames ? '' : 'uploader')
    ..aInt64(6, _omitFieldNames ? '' : 'categoryId')
    ..aOS(7, _omitFieldNames ? '' : 'category')
    ..aInt64(8, _omitFieldNames ? '' : 'modifiedUnixMs')
    ..aOB(9, _omitFieldNames ? '' : 'available')
    ..aOB(10, _omitFieldNames ? '' : 'allowsRating')
    ..pPM<NexusMetadataFile>(11, _omitFieldNames ? '' : 'files',
        subBuilder: NexusMetadataFile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusPublicMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusPublicMetadata copyWith(void Function(NexusPublicMetadata) updates) =>
      super.copyWith((message) => updates(message as NexusPublicMetadata))
          as NexusPublicMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusPublicMetadata create() => NexusPublicMetadata._();
  @$core.override
  NexusPublicMetadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusPublicMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusPublicMetadata>(create);
  static NexusPublicMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get summary => $_getSZ(1);
  @$pb.TagNumber(2)
  set summary($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSummary() => $_has(1);
  @$pb.TagNumber(2)
  void clearSummary() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get author => $_getSZ(3);
  @$pb.TagNumber(4)
  set author($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAuthor() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthor() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get uploader => $_getSZ(4);
  @$pb.TagNumber(5)
  set uploader($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUploader() => $_has(4);
  @$pb.TagNumber(5)
  void clearUploader() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get categoryId => $_getI64(5);
  @$pb.TagNumber(6)
  set categoryId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCategoryId() => $_has(5);
  @$pb.TagNumber(6)
  void clearCategoryId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get category => $_getSZ(6);
  @$pb.TagNumber(7)
  set category($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCategory() => $_has(6);
  @$pb.TagNumber(7)
  void clearCategory() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get modifiedUnixMs => $_getI64(7);
  @$pb.TagNumber(8)
  set modifiedUnixMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasModifiedUnixMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearModifiedUnixMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get available => $_getBF(8);
  @$pb.TagNumber(9)
  set available($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAvailable() => $_has(8);
  @$pb.TagNumber(9)
  void clearAvailable() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get allowsRating => $_getBF(9);
  @$pb.TagNumber(10)
  set allowsRating($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAllowsRating() => $_has(9);
  @$pb.TagNumber(10)
  void clearAllowsRating() => $_clearField(10);

  @$pb.TagNumber(11)
  $pb.PbList<NexusMetadataFile> get files => $_getList(10);
}

class ModNexusDetails extends $pb.GeneratedMessage {
  factory ModNexusDetails({
    ModNexusReference? reference,
    $core.String? localName,
    $fixnum.Int64? installedFile,
    $core.String? installedVersion,
    $core.bool? linkedManually,
    NexusPublicMetadata? metadata,
    $core.String? freshness,
    $fixnum.Int64? checkedUnixMs,
    $core.String? problem,
    $core.String? categoryId,
    $core.String? category,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (localName != null) result.localName = localName;
    if (installedFile != null) result.installedFile = installedFile;
    if (installedVersion != null) result.installedVersion = installedVersion;
    if (linkedManually != null) result.linkedManually = linkedManually;
    if (metadata != null) result.metadata = metadata;
    if (freshness != null) result.freshness = freshness;
    if (checkedUnixMs != null) result.checkedUnixMs = checkedUnixMs;
    if (problem != null) result.problem = problem;
    if (categoryId != null) result.categoryId = categoryId;
    if (category != null) result.category = category;
    return result;
  }

  ModNexusDetails._();

  factory ModNexusDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModNexusDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModNexusDetails',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ModNexusReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: ModNexusReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'localName')
    ..aInt64(3, _omitFieldNames ? '' : 'installedFile')
    ..aOS(4, _omitFieldNames ? '' : 'installedVersion')
    ..aOB(5, _omitFieldNames ? '' : 'linkedManually')
    ..aOM<NexusPublicMetadata>(6, _omitFieldNames ? '' : 'metadata',
        subBuilder: NexusPublicMetadata.create)
    ..aOS(7, _omitFieldNames ? '' : 'freshness')
    ..aInt64(8, _omitFieldNames ? '' : 'checkedUnixMs')
    ..aOS(9, _omitFieldNames ? '' : 'problem')
    ..aOS(10, _omitFieldNames ? '' : 'categoryId')
    ..aOS(11, _omitFieldNames ? '' : 'category')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusDetails copyWith(void Function(ModNexusDetails) updates) =>
      super.copyWith((message) => updates(message as ModNexusDetails))
          as ModNexusDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModNexusDetails create() => ModNexusDetails._();
  @$core.override
  ModNexusDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModNexusDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModNexusDetails>(create);
  static ModNexusDetails? _defaultInstance;

  @$pb.TagNumber(1)
  ModNexusReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(ModNexusReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  ModNexusReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get localName => $_getSZ(1);
  @$pb.TagNumber(2)
  set localName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocalName() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocalName() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get installedFile => $_getI64(2);
  @$pb.TagNumber(3)
  set installedFile($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInstalledFile() => $_has(2);
  @$pb.TagNumber(3)
  void clearInstalledFile() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get installedVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set installedVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInstalledVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearInstalledVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get linkedManually => $_getBF(4);
  @$pb.TagNumber(5)
  set linkedManually($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLinkedManually() => $_has(4);
  @$pb.TagNumber(5)
  void clearLinkedManually() => $_clearField(5);

  @$pb.TagNumber(6)
  NexusPublicMetadata get metadata => $_getN(5);
  @$pb.TagNumber(6)
  set metadata(NexusPublicMetadata value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMetadata() => $_has(5);
  @$pb.TagNumber(6)
  void clearMetadata() => $_clearField(6);
  @$pb.TagNumber(6)
  NexusPublicMetadata ensureMetadata() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.String get freshness => $_getSZ(6);
  @$pb.TagNumber(7)
  set freshness($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFreshness() => $_has(6);
  @$pb.TagNumber(7)
  void clearFreshness() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get checkedUnixMs => $_getI64(7);
  @$pb.TagNumber(8)
  set checkedUnixMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCheckedUnixMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearCheckedUnixMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get problem => $_getSZ(8);
  @$pb.TagNumber(9)
  set problem($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasProblem() => $_has(8);
  @$pb.TagNumber(9)
  void clearProblem() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get categoryId => $_getSZ(9);
  @$pb.TagNumber(10)
  set categoryId($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCategoryId() => $_has(9);
  @$pb.TagNumber(10)
  void clearCategoryId() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get category => $_getSZ(10);
  @$pb.TagNumber(11)
  set category($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCategory() => $_has(10);
  @$pb.TagNumber(11)
  void clearCategory() => $_clearField(11);
}

enum ModNexusReply_Result { details, failure, notSet }

class ModNexusReply extends $pb.GeneratedMessage {
  factory ModNexusReply({
    ModNexusDetails? details,
    $1.NexusFailure? failure,
  }) {
    final result = create();
    if (details != null) result.details = details;
    if (failure != null) result.failure = failure;
    return result;
  }

  ModNexusReply._();

  factory ModNexusReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModNexusReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModNexusReply_Result>
      _ModNexusReply_ResultByTag = {
    1: ModNexusReply_Result.details,
    2: ModNexusReply_Result.failure,
    0: ModNexusReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModNexusReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ModNexusDetails>(1, _omitFieldNames ? '' : 'details',
        subBuilder: ModNexusDetails.create)
    ..aOM<$1.NexusFailure>(2, _omitFieldNames ? '' : 'failure',
        subBuilder: $1.NexusFailure.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusReply copyWith(void Function(ModNexusReply) updates) =>
      super.copyWith((message) => updates(message as ModNexusReply))
          as ModNexusReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModNexusReply create() => ModNexusReply._();
  @$core.override
  ModNexusReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModNexusReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModNexusReply>(create);
  static ModNexusReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ModNexusReply_Result whichResult() =>
      _ModNexusReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModNexusDetails get details => $_getN(0);
  @$pb.TagNumber(1)
  set details(ModNexusDetails value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDetails() => $_has(0);
  @$pb.TagNumber(1)
  void clearDetails() => $_clearField(1);
  @$pb.TagNumber(1)
  ModNexusDetails ensureDetails() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.NexusFailure get failure => $_getN(1);
  @$pb.TagNumber(2)
  set failure($1.NexusFailure value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFailure() => $_has(1);
  @$pb.TagNumber(2)
  void clearFailure() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.NexusFailure ensureFailure() => $_ensure(1);
}

class LinkModNexusRequest extends $pb.GeneratedMessage {
  factory LinkModNexusRequest({
    ModNexusReference? reference,
    $fixnum.Int64? providerMod,
    $fixnum.Int64? fileId,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (providerMod != null) result.providerMod = providerMod;
    if (fileId != null) result.fileId = fileId;
    return result;
  }

  LinkModNexusRequest._();

  factory LinkModNexusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LinkModNexusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LinkModNexusRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ModNexusReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: ModNexusReference.create)
    ..aInt64(2, _omitFieldNames ? '' : 'providerMod')
    ..aInt64(3, _omitFieldNames ? '' : 'fileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkModNexusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkModNexusRequest copyWith(void Function(LinkModNexusRequest) updates) =>
      super.copyWith((message) => updates(message as LinkModNexusRequest))
          as LinkModNexusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LinkModNexusRequest create() => LinkModNexusRequest._();
  @$core.override
  LinkModNexusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LinkModNexusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LinkModNexusRequest>(create);
  static LinkModNexusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ModNexusReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(ModNexusReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  ModNexusReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get providerMod => $_getI64(1);
  @$pb.TagNumber(2)
  set providerMod($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProviderMod() => $_has(1);
  @$pb.TagNumber(2)
  void clearProviderMod() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get fileId => $_getI64(2);
  @$pb.TagNumber(3)
  set fileId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFileId() => $_has(2);
  @$pb.TagNumber(3)
  void clearFileId() => $_clearField(3);
}

class MapModNexusCategoryRequest extends $pb.GeneratedMessage {
  factory MapModNexusCategoryRequest({
    ModNexusReference? reference,
    $core.String? categoryId,
    $fixnum.Int64? providerCategoryId,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (categoryId != null) result.categoryId = categoryId;
    if (providerCategoryId != null)
      result.providerCategoryId = providerCategoryId;
    return result;
  }

  MapModNexusCategoryRequest._();

  factory MapModNexusCategoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MapModNexusCategoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MapModNexusCategoryRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ModNexusReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: ModNexusReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'categoryId')
    ..aInt64(3, _omitFieldNames ? '' : 'providerCategoryId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MapModNexusCategoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MapModNexusCategoryRequest copyWith(
          void Function(MapModNexusCategoryRequest) updates) =>
      super.copyWith(
              (message) => updates(message as MapModNexusCategoryRequest))
          as MapModNexusCategoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MapModNexusCategoryRequest create() => MapModNexusCategoryRequest._();
  @$core.override
  MapModNexusCategoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MapModNexusCategoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MapModNexusCategoryRequest>(create);
  static MapModNexusCategoryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ModNexusReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(ModNexusReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  ModNexusReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get categoryId => $_getSZ(1);
  @$pb.TagNumber(2)
  set categoryId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCategoryId() => $_has(1);
  @$pb.TagNumber(2)
  void clearCategoryId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get providerCategoryId => $_getI64(2);
  @$pb.TagNumber(3)
  set providerCategoryId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProviderCategoryId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProviderCategoryId() => $_clearField(3);
}

class DownloadModNexusFileRequest extends $pb.GeneratedMessage {
  factory DownloadModNexusFileRequest({
    ModNexusReference? reference,
    $fixnum.Int64? fileId,
    $core.bool? updateOnly,
    $core.String? artifactId,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (fileId != null) result.fileId = fileId;
    if (updateOnly != null) result.updateOnly = updateOnly;
    if (artifactId != null) result.artifactId = artifactId;
    return result;
  }

  DownloadModNexusFileRequest._();

  factory DownloadModNexusFileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DownloadModNexusFileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadModNexusFileRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ModNexusReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: ModNexusReference.create)
    ..aInt64(2, _omitFieldNames ? '' : 'fileId')
    ..aOB(3, _omitFieldNames ? '' : 'updateOnly')
    ..aOS(4, _omitFieldNames ? '' : 'artifactId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadModNexusFileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadModNexusFileRequest copyWith(
          void Function(DownloadModNexusFileRequest) updates) =>
      super.copyWith(
              (message) => updates(message as DownloadModNexusFileRequest))
          as DownloadModNexusFileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadModNexusFileRequest create() =>
      DownloadModNexusFileRequest._();
  @$core.override
  DownloadModNexusFileRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DownloadModNexusFileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadModNexusFileRequest>(create);
  static DownloadModNexusFileRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ModNexusReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(ModNexusReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  ModNexusReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fileId => $_getI64(1);
  @$pb.TagNumber(2)
  set fileId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get updateOnly => $_getBF(2);
  @$pb.TagNumber(3)
  set updateOnly($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUpdateOnly() => $_has(2);
  @$pb.TagNumber(3)
  void clearUpdateOnly() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get artifactId => $_getSZ(3);
  @$pb.TagNumber(4)
  set artifactId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasArtifactId() => $_has(3);
  @$pb.TagNumber(4)
  void clearArtifactId() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
