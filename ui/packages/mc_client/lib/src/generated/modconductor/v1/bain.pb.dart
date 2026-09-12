// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bain.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'archive_installation.pb.dart' as $0;
import 'installation_review.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ArchiveInstallerChange extends $pb.GeneratedMessage {
  factory ArchiveInstallerChange({
    $0.InstallationDraftReference? reference,
    $0.ArchiveInstaller? installer,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (installer != null) result.installer = installer;
    return result;
  }

  ArchiveInstallerChange._();

  factory ArchiveInstallerChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArchiveInstallerChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArchiveInstallerChange',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$0.InstallationDraftReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: $0.InstallationDraftReference.create)
    ..aE<$0.ArchiveInstaller>(2, _omitFieldNames ? '' : 'installer',
        enumValues: $0.ArchiveInstaller.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveInstallerChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchiveInstallerChange copyWith(
          void Function(ArchiveInstallerChange) updates) =>
      super.copyWith((message) => updates(message as ArchiveInstallerChange))
          as ArchiveInstallerChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArchiveInstallerChange create() => ArchiveInstallerChange._();
  @$core.override
  ArchiveInstallerChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArchiveInstallerChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArchiveInstallerChange>(create);
  static ArchiveInstallerChange? _defaultInstance;

  @$pb.TagNumber(1)
  $0.InstallationDraftReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($0.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.InstallationDraftReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.ArchiveInstaller get installer => $_getN(1);
  @$pb.TagNumber(2)
  set installer($0.ArchiveInstaller value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasInstaller() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstaller() => $_clearField(2);
}

class BainFolderSelection extends $pb.GeneratedMessage {
  factory BainFolderSelection({
    $0.InstallationDraftReference? reference,
    $core.int? index,
    $core.bool? selected,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (index != null) result.index = index;
    if (selected != null) result.selected = selected;
    return result;
  }

  BainFolderSelection._();

  factory BainFolderSelection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BainFolderSelection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BainFolderSelection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$0.InstallationDraftReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: $0.InstallationDraftReference.create)
    ..aI(2, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'selected')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainFolderSelection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainFolderSelection copyWith(void Function(BainFolderSelection) updates) =>
      super.copyWith((message) => updates(message as BainFolderSelection))
          as BainFolderSelection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BainFolderSelection create() => BainFolderSelection._();
  @$core.override
  BainFolderSelection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BainFolderSelection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BainFolderSelection>(create);
  static BainFolderSelection? _defaultInstance;

  @$pb.TagNumber(1)
  $0.InstallationDraftReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($0.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.InstallationDraftReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get selected => $_getBF(2);
  @$pb.TagNumber(3)
  set selected($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSelected() => $_has(2);
  @$pb.TagNumber(3)
  void clearSelected() => $_clearField(3);
}

class BainAllFoldersSelection extends $pb.GeneratedMessage {
  factory BainAllFoldersSelection({
    $0.InstallationDraftReference? reference,
    $core.bool? selected,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (selected != null) result.selected = selected;
    return result;
  }

  BainAllFoldersSelection._();

  factory BainAllFoldersSelection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BainAllFoldersSelection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BainAllFoldersSelection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$0.InstallationDraftReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: $0.InstallationDraftReference.create)
    ..aOB(2, _omitFieldNames ? '' : 'selected')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainAllFoldersSelection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainAllFoldersSelection copyWith(
          void Function(BainAllFoldersSelection) updates) =>
      super.copyWith((message) => updates(message as BainAllFoldersSelection))
          as BainAllFoldersSelection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BainAllFoldersSelection create() => BainAllFoldersSelection._();
  @$core.override
  BainAllFoldersSelection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BainAllFoldersSelection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BainAllFoldersSelection>(create);
  static BainAllFoldersSelection? _defaultInstance;

  @$pb.TagNumber(1)
  $0.InstallationDraftReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($0.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.InstallationDraftReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get selected => $_getBF(1);
  @$pb.TagNumber(2)
  set selected($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSelected() => $_has(1);
  @$pb.TagNumber(2)
  void clearSelected() => $_clearField(2);
}

class BainFileSelection extends $pb.GeneratedMessage {
  factory BainFileSelection({
    $0.InstallationDraftReference? reference,
    $core.Iterable<$core.String>? path,
    $core.bool? included,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (path != null) result.path.addAll(path);
    if (included != null) result.included = included;
    return result;
  }

  BainFileSelection._();

  factory BainFileSelection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BainFileSelection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BainFileSelection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$0.InstallationDraftReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: $0.InstallationDraftReference.create)
    ..pPS(2, _omitFieldNames ? '' : 'path')
    ..aOB(3, _omitFieldNames ? '' : 'included')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainFileSelection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainFileSelection copyWith(void Function(BainFileSelection) updates) =>
      super.copyWith((message) => updates(message as BainFileSelection))
          as BainFileSelection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BainFileSelection create() => BainFileSelection._();
  @$core.override
  BainFileSelection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BainFileSelection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BainFileSelection>(create);
  static BainFileSelection? _defaultInstance;

  @$pb.TagNumber(1)
  $0.InstallationDraftReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($0.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.InstallationDraftReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get path => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get included => $_getBF(2);
  @$pb.TagNumber(3)
  set included($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIncluded() => $_has(2);
  @$pb.TagNumber(3)
  void clearIncluded() => $_clearField(3);
}

class BainFolderReference extends $pb.GeneratedMessage {
  factory BainFolderReference({
    $0.InstallationDraftReference? reference,
    $core.int? index,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (index != null) result.index = index;
    return result;
  }

  BainFolderReference._();

  factory BainFolderReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BainFolderReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BainFolderReference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$0.InstallationDraftReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: $0.InstallationDraftReference.create)
    ..aI(2, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainFolderReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainFolderReference copyWith(void Function(BainFolderReference) updates) =>
      super.copyWith((message) => updates(message as BainFolderReference))
          as BainFolderReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BainFolderReference create() => BainFolderReference._();
  @$core.override
  BainFolderReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BainFolderReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BainFolderReference>(create);
  static BainFolderReference? _defaultInstance;

  @$pb.TagNumber(1)
  $0.InstallationDraftReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($0.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.InstallationDraftReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => $_clearField(2);
}

class BainPackageNotes extends $pb.GeneratedMessage {
  factory BainPackageNotes({
    $core.String? text,
  }) {
    final result = create();
    if (text != null) result.text = text;
    return result;
  }

  BainPackageNotes._();

  factory BainPackageNotes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BainPackageNotes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BainPackageNotes',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainPackageNotes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainPackageNotes copyWith(void Function(BainPackageNotes) updates) =>
      super.copyWith((message) => updates(message as BainPackageNotes))
          as BainPackageNotes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BainPackageNotes create() => BainPackageNotes._();
  @$core.override
  BainPackageNotes createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BainPackageNotes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BainPackageNotes>(create);
  static BainPackageNotes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);
}

class BainFolderFiles extends $pb.GeneratedMessage {
  factory BainFolderFiles({
    $core.Iterable<$2.InstallationReviewedFile>? files,
  }) {
    final result = create();
    if (files != null) result.files.addAll(files);
    return result;
  }

  BainFolderFiles._();

  factory BainFolderFiles.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BainFolderFiles.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BainFolderFiles',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<$2.InstallationReviewedFile>(1, _omitFieldNames ? '' : 'files',
        subBuilder: $2.InstallationReviewedFile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainFolderFiles clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainFolderFiles copyWith(void Function(BainFolderFiles) updates) =>
      super.copyWith((message) => updates(message as BainFolderFiles))
          as BainFolderFiles;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BainFolderFiles create() => BainFolderFiles._();
  @$core.override
  BainFolderFiles createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BainFolderFiles getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BainFolderFiles>(create);
  static BainFolderFiles? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$2.InstallationReviewedFile> get files => $_getList(0);
}

class BainPackage extends $pb.GeneratedMessage {
  factory BainPackage({
    $core.int? index,
    $core.String? name,
    $core.int? files,
    $fixnum.Int64? bytes,
    $core.bool? selected,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (name != null) result.name = name;
    if (files != null) result.files = files;
    if (bytes != null) result.bytes = bytes;
    if (selected != null) result.selected = selected;
    return result;
  }

  BainPackage._();

  factory BainPackage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BainPackage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BainPackage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aI(3, _omitFieldNames ? '' : 'files', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(5, _omitFieldNames ? '' : 'selected')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainPackage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainPackage copyWith(void Function(BainPackage) updates) =>
      super.copyWith((message) => updates(message as BainPackage))
          as BainPackage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BainPackage create() => BainPackage._();
  @$core.override
  BainPackage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BainPackage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BainPackage>(create);
  static BainPackage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get files => $_getIZ(2);
  @$pb.TagNumber(3)
  set files($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFiles() => $_has(2);
  @$pb.TagNumber(3)
  void clearFiles() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get bytes => $_getI64(3);
  @$pb.TagNumber(4)
  set bytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get selected => $_getBF(4);
  @$pb.TagNumber(5)
  set selected($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSelected() => $_has(4);
  @$pb.TagNumber(5)
  void clearSelected() => $_clearField(5);
}

class BainReviewedFile extends $pb.GeneratedMessage {
  factory BainReviewedFile({
    $2.InstallationReviewedFile? file,
    $core.bool? included,
  }) {
    final result = create();
    if (file != null) result.file = file;
    if (included != null) result.included = included;
    return result;
  }

  BainReviewedFile._();

  factory BainReviewedFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BainReviewedFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BainReviewedFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$2.InstallationReviewedFile>(1, _omitFieldNames ? '' : 'file',
        subBuilder: $2.InstallationReviewedFile.create)
    ..aOB(2, _omitFieldNames ? '' : 'included')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainReviewedFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainReviewedFile copyWith(void Function(BainReviewedFile) updates) =>
      super.copyWith((message) => updates(message as BainReviewedFile))
          as BainReviewedFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BainReviewedFile create() => BainReviewedFile._();
  @$core.override
  BainReviewedFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BainReviewedFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BainReviewedFile>(create);
  static BainReviewedFile? _defaultInstance;

  @$pb.TagNumber(1)
  $2.InstallationReviewedFile get file => $_getN(0);
  @$pb.TagNumber(1)
  set file($2.InstallationReviewedFile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.InstallationReviewedFile ensureFile() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get included => $_getBF(1);
  @$pb.TagNumber(2)
  set included($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIncluded() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncluded() => $_clearField(2);
}

class BainChoices extends $pb.GeneratedMessage {
  factory BainChoices({
    $0.InstallationDraftReference? reference,
    $core.Iterable<BainPackage>? packages,
    $core.Iterable<BainReviewedFile>? files,
    $core.bool? reviewing,
    $core.bool? hasNotes,
    $core.String? problem,
    $0.ArchiveInstallationDraft? reviewedDraft,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (packages != null) result.packages.addAll(packages);
    if (files != null) result.files.addAll(files);
    if (reviewing != null) result.reviewing = reviewing;
    if (hasNotes != null) result.hasNotes = hasNotes;
    if (problem != null) result.problem = problem;
    if (reviewedDraft != null) result.reviewedDraft = reviewedDraft;
    return result;
  }

  BainChoices._();

  factory BainChoices.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BainChoices.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BainChoices',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$0.InstallationDraftReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: $0.InstallationDraftReference.create)
    ..pPM<BainPackage>(2, _omitFieldNames ? '' : 'packages',
        subBuilder: BainPackage.create)
    ..pPM<BainReviewedFile>(3, _omitFieldNames ? '' : 'files',
        subBuilder: BainReviewedFile.create)
    ..aOB(4, _omitFieldNames ? '' : 'reviewing')
    ..aOB(5, _omitFieldNames ? '' : 'hasNotes')
    ..aOS(6, _omitFieldNames ? '' : 'problem')
    ..aOM<$0.ArchiveInstallationDraft>(
        7, _omitFieldNames ? '' : 'reviewedDraft',
        subBuilder: $0.ArchiveInstallationDraft.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainChoices clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BainChoices copyWith(void Function(BainChoices) updates) =>
      super.copyWith((message) => updates(message as BainChoices))
          as BainChoices;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BainChoices create() => BainChoices._();
  @$core.override
  BainChoices createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BainChoices getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BainChoices>(create);
  static BainChoices? _defaultInstance;

  @$pb.TagNumber(1)
  $0.InstallationDraftReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($0.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.InstallationDraftReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<BainPackage> get packages => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<BainReviewedFile> get files => $_getList(2);

  @$pb.TagNumber(4)
  $core.bool get reviewing => $_getBF(3);
  @$pb.TagNumber(4)
  set reviewing($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReviewing() => $_has(3);
  @$pb.TagNumber(4)
  void clearReviewing() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get hasNotes => $_getBF(4);
  @$pb.TagNumber(5)
  set hasNotes($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHasNotes() => $_has(4);
  @$pb.TagNumber(5)
  void clearHasNotes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get problem => $_getSZ(5);
  @$pb.TagNumber(6)
  set problem($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProblem() => $_has(5);
  @$pb.TagNumber(6)
  void clearProblem() => $_clearField(6);

  @$pb.TagNumber(7)
  $0.ArchiveInstallationDraft get reviewedDraft => $_getN(6);
  @$pb.TagNumber(7)
  set reviewedDraft($0.ArchiveInstallationDraft value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasReviewedDraft() => $_has(6);
  @$pb.TagNumber(7)
  void clearReviewedDraft() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.ArchiveInstallationDraft ensureReviewedDraft() => $_ensure(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
