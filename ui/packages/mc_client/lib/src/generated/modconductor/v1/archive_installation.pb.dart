// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_installation.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'archive_inspection.pb.dart' as $2;
import 'archive_installation.pbenum.dart';
import 'artifacts.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'archive_installation.pbenum.dart';

class InstallationDraftReference extends $pb.GeneratedMessage {
  factory InstallationDraftReference({
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

  InstallationDraftReference._();

  factory InstallationDraftReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationDraftReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationDraftReference',
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
  InstallationDraftReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationDraftReference copyWith(
          void Function(InstallationDraftReference) updates) =>
      super.copyWith(
              (message) => updates(message as InstallationDraftReference))
          as InstallationDraftReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationDraftReference create() => InstallationDraftReference._();
  @$core.override
  InstallationDraftReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationDraftReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationDraftReference>(create);
  static InstallationDraftReference? _defaultInstance;

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

class InstallationDraftClosed extends $pb.GeneratedMessage {
  factory InstallationDraftClosed() => create();

  InstallationDraftClosed._();

  factory InstallationDraftClosed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationDraftClosed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationDraftClosed',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationDraftClosed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationDraftClosed copyWith(
          void Function(InstallationDraftClosed) updates) =>
      super.copyWith((message) => updates(message as InstallationDraftClosed))
          as InstallationDraftClosed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationDraftClosed create() => InstallationDraftClosed._();
  @$core.override
  InstallationDraftClosed createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationDraftClosed getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationDraftClosed>(create);
  static InstallationDraftClosed? _defaultInstance;
}

class InstallationWorkspace extends $pb.GeneratedMessage {
  factory InstallationWorkspace({
    $core.String? workspaceId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    return result;
  }

  InstallationWorkspace._();

  factory InstallationWorkspace.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationWorkspace.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationWorkspace',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationWorkspace clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationWorkspace copyWith(
          void Function(InstallationWorkspace) updates) =>
      super.copyWith((message) => updates(message as InstallationWorkspace))
          as InstallationWorkspace;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationWorkspace create() => InstallationWorkspace._();
  @$core.override
  InstallationWorkspace createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationWorkspace getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationWorkspace>(create);
  static InstallationWorkspace? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);
}

class InstallationReference extends $pb.GeneratedMessage {
  factory InstallationReference({
    $core.String? workspaceId,
    $core.String? id,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    return result;
  }

  InstallationReference._();

  factory InstallationReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationReference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationReference copyWith(
          void Function(InstallationReference) updates) =>
      super.copyWith((message) => updates(message as InstallationReference))
          as InstallationReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationReference create() => InstallationReference._();
  @$core.override
  InstallationReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationReference>(create);
  static InstallationReference? _defaultInstance;

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

class InstallationFile extends $pb.GeneratedMessage {
  factory InstallationFile({
    $core.int? index,
    $core.Iterable<$core.String>? destination,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (destination != null) result.destination.addAll(destination);
    return result;
  }

  InstallationFile._();

  factory InstallationFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..pPS(2, _omitFieldNames ? '' : 'destination')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationFile copyWith(void Function(InstallationFile) updates) =>
      super.copyWith((message) => updates(message as InstallationFile))
          as InstallationFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationFile create() => InstallationFile._();
  @$core.override
  InstallationFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationFile>(create);
  static InstallationFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get destination => $_getList(1);
}

class ArchiveInstallationDraft extends $pb.GeneratedMessage {
  factory ArchiveInstallationDraft({
    InstallationDraftReference? reference,
    $0.ArtifactReference? artifact,
    $core.String? archiveName,
    $2.InspectedArchive? manifest,
    $core.Iterable<$core.String>? root,
    $core.Iterable<InstallationFile>? files,
    $core.String? name,
    $core.String? version,
    $fixnum.Int64? bytes,
    $core.bool? canInstall,
    ArchiveInstaller? installer,
    $core.Iterable<ArchiveInstaller>? availableInstallers,
    $core.Iterable<$core.String>? wizardScripts,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (artifact != null) result.artifact = artifact;
    if (archiveName != null) result.archiveName = archiveName;
    if (manifest != null) result.manifest = manifest;
    if (root != null) result.root.addAll(root);
    if (files != null) result.files.addAll(files);
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    if (bytes != null) result.bytes = bytes;
    if (canInstall != null) result.canInstall = canInstall;
    if (installer != null) result.installer = installer;
    if (availableInstallers != null)
      result.availableInstallers.addAll(availableInstallers);
    if (wizardScripts != null) result.wizardScripts.addAll(wizardScripts);
    return result;
  }

  ArchiveInstallationDraft._();

  factory ArchiveInstallationDraft.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArchiveInstallationDraft.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArchiveInstallationDraft',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<InstallationDraftReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: InstallationDraftReference.create)
    ..aOM<$0.ArtifactReference>(2, _omitFieldNames ? '' : 'artifact',
        subBuilder: $0.ArtifactReference.create)
    ..aOS(3, _omitFieldNames ? '' : 'archiveName')
    ..aOM<$2.InspectedArchive>(4, _omitFieldNames ? '' : 'manifest',
        subBuilder: $2.InspectedArchive.create)
    ..pPS(5, _omitFieldNames ? '' : 'root')
    ..pPM<InstallationFile>(6, _omitFieldNames ? '' : 'files',
        subBuilder: InstallationFile.create)
    ..aOS(7, _omitFieldNames ? '' : 'name')
    ..aOS(8, _omitFieldNames ? '' : 'version')
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(10, _omitFieldNames ? '' : 'canInstall')
    ..aE<ArchiveInstaller>(11, _omitFieldNames ? '' : 'installer',
        enumValues: ArchiveInstaller.values)
    ..pc<ArchiveInstaller>(
        12, _omitFieldNames ? '' : 'availableInstallers', $pb.PbFieldType.KE,
        valueOf: ArchiveInstaller.valueOf,
        enumValues: ArchiveInstaller.values,
        defaultEnumValue: ArchiveInstaller.ARCHIVE_INSTALLER_MANUAL)
    ..pPS(13, _omitFieldNames ? '' : 'wizardScripts')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveInstallationDraft clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveInstallationDraft copyWith(
          void Function(ArchiveInstallationDraft) updates) =>
      super.copyWith((message) => updates(message as ArchiveInstallationDraft))
          as ArchiveInstallationDraft;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArchiveInstallationDraft create() => ArchiveInstallationDraft._();
  @$core.override
  ArchiveInstallationDraft createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArchiveInstallationDraft getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArchiveInstallationDraft>(create);
  static ArchiveInstallationDraft? _defaultInstance;

  @$pb.TagNumber(1)
  InstallationDraftReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  InstallationDraftReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.ArtifactReference get artifact => $_getN(1);
  @$pb.TagNumber(2)
  set artifact($0.ArtifactReference value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasArtifact() => $_has(1);
  @$pb.TagNumber(2)
  void clearArtifact() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.ArtifactReference ensureArtifact() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get archiveName => $_getSZ(2);
  @$pb.TagNumber(3)
  set archiveName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasArchiveName() => $_has(2);
  @$pb.TagNumber(3)
  void clearArchiveName() => $_clearField(3);

  @$pb.TagNumber(4)
  $2.InspectedArchive get manifest => $_getN(3);
  @$pb.TagNumber(4)
  set manifest($2.InspectedArchive value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasManifest() => $_has(3);
  @$pb.TagNumber(4)
  void clearManifest() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.InspectedArchive ensureManifest() => $_ensure(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get root => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<InstallationFile> get files => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get name => $_getSZ(6);
  @$pb.TagNumber(7)
  set name($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasName() => $_has(6);
  @$pb.TagNumber(7)
  void clearName() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get version => $_getSZ(7);
  @$pb.TagNumber(8)
  set version($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearVersion() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get bytes => $_getI64(8);
  @$pb.TagNumber(9)
  set bytes($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasBytes() => $_has(8);
  @$pb.TagNumber(9)
  void clearBytes() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get canInstall => $_getBF(9);
  @$pb.TagNumber(10)
  set canInstall($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCanInstall() => $_has(9);
  @$pb.TagNumber(10)
  void clearCanInstall() => $_clearField(10);

  @$pb.TagNumber(11)
  ArchiveInstaller get installer => $_getN(10);
  @$pb.TagNumber(11)
  set installer(ArchiveInstaller value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasInstaller() => $_has(10);
  @$pb.TagNumber(11)
  void clearInstaller() => $_clearField(11);

  @$pb.TagNumber(12)
  $pb.PbList<ArchiveInstaller> get availableInstallers => $_getList(11);

  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get wizardScripts => $_getList(12);
}

class InstallationRoot extends $pb.GeneratedMessage {
  factory InstallationRoot({
    $core.Iterable<$core.String>? components,
  }) {
    final result = create();
    if (components != null) result.components.addAll(components);
    return result;
  }

  InstallationRoot._();

  factory InstallationRoot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationRoot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationRoot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'components')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationRoot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationRoot copyWith(void Function(InstallationRoot) updates) =>
      super.copyWith((message) => updates(message as InstallationRoot))
          as InstallationRoot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationRoot create() => InstallationRoot._();
  @$core.override
  InstallationRoot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationRoot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationRoot>(create);
  static InstallationRoot? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get components => $_getList(0);
}

class InstallationInclusion extends $pb.GeneratedMessage {
  factory InstallationInclusion({
    $core.Iterable<$core.String>? source,
    $core.bool? included,
  }) {
    final result = create();
    if (source != null) result.source.addAll(source);
    if (included != null) result.included = included;
    return result;
  }

  InstallationInclusion._();

  factory InstallationInclusion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationInclusion.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationInclusion',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'source')
    ..aOB(2, _omitFieldNames ? '' : 'included')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationInclusion clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationInclusion copyWith(
          void Function(InstallationInclusion) updates) =>
      super.copyWith((message) => updates(message as InstallationInclusion))
          as InstallationInclusion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationInclusion create() => InstallationInclusion._();
  @$core.override
  InstallationInclusion createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationInclusion getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationInclusion>(create);
  static InstallationInclusion? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get source => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get included => $_getBF(1);
  @$pb.TagNumber(2)
  set included($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIncluded() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncluded() => $_clearField(2);
}

class InstallationDestination extends $pb.GeneratedMessage {
  factory InstallationDestination({
    $core.Iterable<$core.String>? source,
    $core.Iterable<$core.String>? destination,
  }) {
    final result = create();
    if (source != null) result.source.addAll(source);
    if (destination != null) result.destination.addAll(destination);
    return result;
  }

  InstallationDestination._();

  factory InstallationDestination.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationDestination.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationDestination',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'source')
    ..pPS(2, _omitFieldNames ? '' : 'destination')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationDestination clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationDestination copyWith(
          void Function(InstallationDestination) updates) =>
      super.copyWith((message) => updates(message as InstallationDestination))
          as InstallationDestination;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationDestination create() => InstallationDestination._();
  @$core.override
  InstallationDestination createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationDestination getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationDestination>(create);
  static InstallationDestination? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get source => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get destination => $_getList(1);
}

class InstallationMetadata extends $pb.GeneratedMessage {
  factory InstallationMetadata({
    $core.String? name,
    $core.String? version,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    return result;
  }

  InstallationMetadata._();

  factory InstallationMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationMetadata copyWith(void Function(InstallationMetadata) updates) =>
      super.copyWith((message) => updates(message as InstallationMetadata))
          as InstallationMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationMetadata create() => InstallationMetadata._();
  @$core.override
  InstallationMetadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationMetadata>(create);
  static InstallationMetadata? _defaultInstance;

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
}

enum InstallationLayoutChange_Change {
  root,
  inclusion,
  destination,
  metadata,
  notSet
}

class InstallationLayoutChange extends $pb.GeneratedMessage {
  factory InstallationLayoutChange({
    InstallationDraftReference? reference,
    InstallationRoot? root,
    InstallationInclusion? inclusion,
    InstallationDestination? destination,
    InstallationMetadata? metadata,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (root != null) result.root = root;
    if (inclusion != null) result.inclusion = inclusion;
    if (destination != null) result.destination = destination;
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  InstallationLayoutChange._();

  factory InstallationLayoutChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationLayoutChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, InstallationLayoutChange_Change>
      _InstallationLayoutChange_ChangeByTag = {
    2: InstallationLayoutChange_Change.root,
    3: InstallationLayoutChange_Change.inclusion,
    4: InstallationLayoutChange_Change.destination,
    5: InstallationLayoutChange_Change.metadata,
    0: InstallationLayoutChange_Change.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationLayoutChange',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4, 5])
    ..aOM<InstallationDraftReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: InstallationDraftReference.create)
    ..aOM<InstallationRoot>(2, _omitFieldNames ? '' : 'root',
        subBuilder: InstallationRoot.create)
    ..aOM<InstallationInclusion>(3, _omitFieldNames ? '' : 'inclusion',
        subBuilder: InstallationInclusion.create)
    ..aOM<InstallationDestination>(4, _omitFieldNames ? '' : 'destination',
        subBuilder: InstallationDestination.create)
    ..aOM<InstallationMetadata>(5, _omitFieldNames ? '' : 'metadata',
        subBuilder: InstallationMetadata.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationLayoutChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationLayoutChange copyWith(
          void Function(InstallationLayoutChange) updates) =>
      super.copyWith((message) => updates(message as InstallationLayoutChange))
          as InstallationLayoutChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationLayoutChange create() => InstallationLayoutChange._();
  @$core.override
  InstallationLayoutChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationLayoutChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationLayoutChange>(create);
  static InstallationLayoutChange? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  InstallationLayoutChange_Change whichChange() =>
      _InstallationLayoutChange_ChangeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearChange() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  InstallationDraftReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  InstallationDraftReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  InstallationRoot get root => $_getN(1);
  @$pb.TagNumber(2)
  set root(InstallationRoot value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRoot() => $_has(1);
  @$pb.TagNumber(2)
  void clearRoot() => $_clearField(2);
  @$pb.TagNumber(2)
  InstallationRoot ensureRoot() => $_ensure(1);

  @$pb.TagNumber(3)
  InstallationInclusion get inclusion => $_getN(2);
  @$pb.TagNumber(3)
  set inclusion(InstallationInclusion value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasInclusion() => $_has(2);
  @$pb.TagNumber(3)
  void clearInclusion() => $_clearField(3);
  @$pb.TagNumber(3)
  InstallationInclusion ensureInclusion() => $_ensure(2);

  @$pb.TagNumber(4)
  InstallationDestination get destination => $_getN(3);
  @$pb.TagNumber(4)
  set destination(InstallationDestination value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDestination() => $_has(3);
  @$pb.TagNumber(4)
  void clearDestination() => $_clearField(4);
  @$pb.TagNumber(4)
  InstallationDestination ensureDestination() => $_ensure(3);

  @$pb.TagNumber(5)
  InstallationMetadata get metadata => $_getN(4);
  @$pb.TagNumber(5)
  set metadata(InstallationMetadata value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasMetadata() => $_has(4);
  @$pb.TagNumber(5)
  void clearMetadata() => $_clearField(5);
  @$pb.TagNumber(5)
  InstallationMetadata ensureMetadata() => $_ensure(4);
}

class StartArchiveInstallation extends $pb.GeneratedMessage {
  factory StartArchiveInstallation({
    InstallationDraftReference? draft,
    $core.String? id,
  }) {
    final result = create();
    if (draft != null) result.draft = draft;
    if (id != null) result.id = id;
    return result;
  }

  StartArchiveInstallation._();

  factory StartArchiveInstallation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartArchiveInstallation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartArchiveInstallation',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<InstallationDraftReference>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: InstallationDraftReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartArchiveInstallation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartArchiveInstallation copyWith(
          void Function(StartArchiveInstallation) updates) =>
      super.copyWith((message) => updates(message as StartArchiveInstallation))
          as StartArchiveInstallation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartArchiveInstallation create() => StartArchiveInstallation._();
  @$core.override
  StartArchiveInstallation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartArchiveInstallation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartArchiveInstallation>(create);
  static StartArchiveInstallation? _defaultInstance;

  @$pb.TagNumber(1)
  InstallationDraftReference get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft(InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  InstallationDraftReference ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);
}

class ArchiveInstallationStatus extends $pb.GeneratedMessage {
  factory ArchiveInstallationStatus({
    $core.String? id,
    $core.String? workspaceId,
    $core.String? artifactId,
    $core.String? archiveName,
    $core.String? name,
    $core.String? version,
    InstallationPhase? phase,
    $core.int? files,
    $core.int? totalFiles,
    $fixnum.Int64? bytes,
    $fixnum.Int64? totalBytes,
    $core.String? problem,
    $core.String? modId,
    $core.String? versionId,
    $fixnum.Int64? temporaryBytes,
    $core.bool? isUpdate,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (artifactId != null) result.artifactId = artifactId;
    if (archiveName != null) result.archiveName = archiveName;
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    if (phase != null) result.phase = phase;
    if (files != null) result.files = files;
    if (totalFiles != null) result.totalFiles = totalFiles;
    if (bytes != null) result.bytes = bytes;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (problem != null) result.problem = problem;
    if (modId != null) result.modId = modId;
    if (versionId != null) result.versionId = versionId;
    if (temporaryBytes != null) result.temporaryBytes = temporaryBytes;
    if (isUpdate != null) result.isUpdate = isUpdate;
    return result;
  }

  ArchiveInstallationStatus._();

  factory ArchiveInstallationStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArchiveInstallationStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArchiveInstallationStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'artifactId')
    ..aOS(4, _omitFieldNames ? '' : 'archiveName')
    ..aOS(5, _omitFieldNames ? '' : 'name')
    ..aOS(6, _omitFieldNames ? '' : 'version')
    ..aE<InstallationPhase>(7, _omitFieldNames ? '' : 'phase',
        enumValues: InstallationPhase.values)
    ..aI(8, _omitFieldNames ? '' : 'files', fieldType: $pb.PbFieldType.OU3)
    ..aI(9, _omitFieldNames ? '' : 'totalFiles', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(10, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'totalBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(12, _omitFieldNames ? '' : 'problem')
    ..aOS(13, _omitFieldNames ? '' : 'modId')
    ..aOS(14, _omitFieldNames ? '' : 'versionId')
    ..a<$fixnum.Int64>(
        15, _omitFieldNames ? '' : 'temporaryBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(16, _omitFieldNames ? '' : 'isUpdate')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveInstallationStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveInstallationStatus copyWith(
          void Function(ArchiveInstallationStatus) updates) =>
      super.copyWith((message) => updates(message as ArchiveInstallationStatus))
          as ArchiveInstallationStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArchiveInstallationStatus create() => ArchiveInstallationStatus._();
  @$core.override
  ArchiveInstallationStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArchiveInstallationStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArchiveInstallationStatus>(create);
  static ArchiveInstallationStatus? _defaultInstance;

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
  $core.String get artifactId => $_getSZ(2);
  @$pb.TagNumber(3)
  set artifactId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasArtifactId() => $_has(2);
  @$pb.TagNumber(3)
  void clearArtifactId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get archiveName => $_getSZ(3);
  @$pb.TagNumber(4)
  set archiveName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasArchiveName() => $_has(3);
  @$pb.TagNumber(4)
  void clearArchiveName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get version => $_getSZ(5);
  @$pb.TagNumber(6)
  set version($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearVersion() => $_clearField(6);

  @$pb.TagNumber(7)
  InstallationPhase get phase => $_getN(6);
  @$pb.TagNumber(7)
  set phase(InstallationPhase value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPhase() => $_has(6);
  @$pb.TagNumber(7)
  void clearPhase() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get files => $_getIZ(7);
  @$pb.TagNumber(8)
  set files($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFiles() => $_has(7);
  @$pb.TagNumber(8)
  void clearFiles() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get totalFiles => $_getIZ(8);
  @$pb.TagNumber(9)
  set totalFiles($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTotalFiles() => $_has(8);
  @$pb.TagNumber(9)
  void clearTotalFiles() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get bytes => $_getI64(9);
  @$pb.TagNumber(10)
  set bytes($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasBytes() => $_has(9);
  @$pb.TagNumber(10)
  void clearBytes() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get totalBytes => $_getI64(10);
  @$pb.TagNumber(11)
  set totalBytes($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasTotalBytes() => $_has(10);
  @$pb.TagNumber(11)
  void clearTotalBytes() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get problem => $_getSZ(11);
  @$pb.TagNumber(12)
  set problem($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasProblem() => $_has(11);
  @$pb.TagNumber(12)
  void clearProblem() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get modId => $_getSZ(12);
  @$pb.TagNumber(13)
  set modId($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasModId() => $_has(12);
  @$pb.TagNumber(13)
  void clearModId() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get versionId => $_getSZ(13);
  @$pb.TagNumber(14)
  set versionId($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasVersionId() => $_has(13);
  @$pb.TagNumber(14)
  void clearVersionId() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get temporaryBytes => $_getI64(14);
  @$pb.TagNumber(15)
  set temporaryBytes($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasTemporaryBytes() => $_has(14);
  @$pb.TagNumber(15)
  void clearTemporaryBytes() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get isUpdate => $_getBF(15);
  @$pb.TagNumber(16)
  set isUpdate($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasIsUpdate() => $_has(15);
  @$pb.TagNumber(16)
  void clearIsUpdate() => $_clearField(16);
}

class ArchiveInstallationList extends $pb.GeneratedMessage {
  factory ArchiveInstallationList({
    $core.Iterable<ArchiveInstallationStatus>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  ArchiveInstallationList._();

  factory ArchiveInstallationList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArchiveInstallationList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArchiveInstallationList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<ArchiveInstallationStatus>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: ArchiveInstallationStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveInstallationList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveInstallationList copyWith(
          void Function(ArchiveInstallationList) updates) =>
      super.copyWith((message) => updates(message as ArchiveInstallationList))
          as ArchiveInstallationList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArchiveInstallationList create() => ArchiveInstallationList._();
  @$core.override
  ArchiveInstallationList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArchiveInstallationList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArchiveInstallationList>(create);
  static ArchiveInstallationList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ArchiveInstallationStatus> get entries => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
