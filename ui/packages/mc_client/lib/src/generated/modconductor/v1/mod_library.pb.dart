// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_library.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'mod_library.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'mod_library.pbenum.dart';

class ModLogicalPath extends $pb.GeneratedMessage {
  factory ModLogicalPath({
    $core.Iterable<$core.String>? components,
  }) {
    final result = create();
    if (components != null) result.components.addAll(components);
    return result;
  }

  ModLogicalPath._();

  factory ModLogicalPath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModLogicalPath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModLogicalPath',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'components')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModLogicalPath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModLogicalPath copyWith(void Function(ModLogicalPath) updates) =>
      super.copyWith((message) => updates(message as ModLogicalPath))
          as ModLogicalPath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModLogicalPath create() => ModLogicalPath._();
  @$core.override
  ModLogicalPath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModLogicalPath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModLogicalPath>(create);
  static ModLogicalPath? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get components => $_getList(0);
}

class ModCategoryReference extends $pb.GeneratedMessage {
  factory ModCategoryReference({
    $core.String? categoryId,
    $core.String? label,
    $core.bool? missing,
  }) {
    final result = create();
    if (categoryId != null) result.categoryId = categoryId;
    if (label != null) result.label = label;
    if (missing != null) result.missing = missing;
    return result;
  }

  ModCategoryReference._();

  factory ModCategoryReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModCategoryReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModCategoryReference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'categoryId')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOB(3, _omitFieldNames ? '' : 'missing')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModCategoryReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModCategoryReference copyWith(void Function(ModCategoryReference) updates) =>
      super.copyWith((message) => updates(message as ModCategoryReference))
          as ModCategoryReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModCategoryReference create() => ModCategoryReference._();
  @$core.override
  ModCategoryReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModCategoryReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModCategoryReference>(create);
  static ModCategoryReference? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get categoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set categoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCategoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategoryId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get missing => $_getBF(2);
  @$pb.TagNumber(3)
  set missing($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMissing() => $_has(2);
  @$pb.TagNumber(3)
  void clearMissing() => $_clearField(3);
}

class InventoryModMetadata extends $pb.GeneratedMessage {
  factory InventoryModMetadata({
    $core.String? name,
    $core.String? notes,
    $core.String? comment,
    $core.String? version,
    $core.String? source,
    $core.Iterable<ModCategoryReference>? categories,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (notes != null) result.notes = notes;
    if (comment != null) result.comment = comment;
    if (version != null) result.version = version;
    if (source != null) result.source = source;
    if (categories != null) result.categories.addAll(categories);
    return result;
  }

  InventoryModMetadata._();

  factory InventoryModMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryModMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryModMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'notes')
    ..aOS(3, _omitFieldNames ? '' : 'comment')
    ..aOS(4, _omitFieldNames ? '' : 'version')
    ..aOS(5, _omitFieldNames ? '' : 'source')
    ..pPM<ModCategoryReference>(7, _omitFieldNames ? '' : 'categories',
        subBuilder: ModCategoryReference.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryModMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryModMetadata copyWith(void Function(InventoryModMetadata) updates) =>
      super.copyWith((message) => updates(message as InventoryModMetadata))
          as InventoryModMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryModMetadata create() => InventoryModMetadata._();
  @$core.override
  InventoryModMetadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryModMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryModMetadata>(create);
  static InventoryModMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get notes => $_getSZ(1);
  @$pb.TagNumber(2)
  set notes($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNotes() => $_has(1);
  @$pb.TagNumber(2)
  void clearNotes() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get comment => $_getSZ(2);
  @$pb.TagNumber(3)
  set comment($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasComment() => $_has(2);
  @$pb.TagNumber(3)
  void clearComment() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get version => $_getSZ(3);
  @$pb.TagNumber(4)
  set version($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get source => $_getSZ(4);
  @$pb.TagNumber(5)
  set source($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSource() => $_has(4);
  @$pb.TagNumber(5)
  void clearSource() => $_clearField(5);

  @$pb.TagNumber(7)
  $pb.PbList<ModCategoryReference> get categories => $_getList(5);
}

class InventoryMod extends $pb.GeneratedMessage {
  factory InventoryMod({
    $core.String? modId,
    $core.String? workspaceId,
    InventoryModKind? kind,
    InventoryModMetadata? metadata,
    $fixnum.Int64? revision,
    ModLogicalPath? sourcePath,
    $core.String? currentVersionId,
    ModInventoryStatus? status,
    $core.Iterable<InventoryModAction>? actions,
    ModVersionOrigin? versionOrigin,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (kind != null) result.kind = kind;
    if (metadata != null) result.metadata = metadata;
    if (revision != null) result.revision = revision;
    if (sourcePath != null) result.sourcePath = sourcePath;
    if (currentVersionId != null) result.currentVersionId = currentVersionId;
    if (status != null) result.status = status;
    if (actions != null) result.actions.addAll(actions);
    if (versionOrigin != null) result.versionOrigin = versionOrigin;
    return result;
  }

  InventoryMod._();

  factory InventoryMod.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryMod.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryMod',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aE<InventoryModKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: InventoryModKind.values)
    ..aOM<InventoryModMetadata>(4, _omitFieldNames ? '' : 'metadata',
        subBuilder: InventoryModMetadata.create)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<ModLogicalPath>(6, _omitFieldNames ? '' : 'sourcePath',
        subBuilder: ModLogicalPath.create)
    ..aOS(7, _omitFieldNames ? '' : 'currentVersionId')
    ..aE<ModInventoryStatus>(8, _omitFieldNames ? '' : 'status',
        enumValues: ModInventoryStatus.values)
    ..pc<InventoryModAction>(
        9, _omitFieldNames ? '' : 'actions', $pb.PbFieldType.KE,
        valueOf: InventoryModAction.valueOf,
        enumValues: InventoryModAction.values,
        defaultEnumValue: InventoryModAction.INVENTORY_MOD_ACTION_UNSPECIFIED)
    ..aOM<ModVersionOrigin>(10, _omitFieldNames ? '' : 'versionOrigin',
        subBuilder: ModVersionOrigin.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryMod clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryMod copyWith(void Function(InventoryMod) updates) =>
      super.copyWith((message) => updates(message as InventoryMod))
          as InventoryMod;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryMod create() => InventoryMod._();
  @$core.override
  InventoryMod createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryMod getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryMod>(create);
  static InventoryMod? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => $_clearField(2);

  @$pb.TagNumber(3)
  InventoryModKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(InventoryModKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  InventoryModMetadata get metadata => $_getN(3);
  @$pb.TagNumber(4)
  set metadata(InventoryModMetadata value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMetadata() => $_has(3);
  @$pb.TagNumber(4)
  void clearMetadata() => $_clearField(4);
  @$pb.TagNumber(4)
  InventoryModMetadata ensureMetadata() => $_ensure(3);

  /// Per-mod metadata/current-version revision, independent of workspace/runtime revisions.
  @$pb.TagNumber(5)
  $fixnum.Int64 get revision => $_getI64(4);
  @$pb.TagNumber(5)
  set revision($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRevision() => $_has(4);
  @$pb.TagNumber(5)
  void clearRevision() => $_clearField(5);

  @$pb.TagNumber(6)
  ModLogicalPath get sourcePath => $_getN(5);
  @$pb.TagNumber(6)
  set sourcePath(ModLogicalPath value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSourcePath() => $_has(5);
  @$pb.TagNumber(6)
  void clearSourcePath() => $_clearField(6);
  @$pb.TagNumber(6)
  ModLogicalPath ensureSourcePath() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.String get currentVersionId => $_getSZ(6);
  @$pb.TagNumber(7)
  set currentVersionId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCurrentVersionId() => $_has(6);
  @$pb.TagNumber(7)
  void clearCurrentVersionId() => $_clearField(7);

  @$pb.TagNumber(8)
  ModInventoryStatus get status => $_getN(7);
  @$pb.TagNumber(8)
  set status(ModInventoryStatus value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearStatus() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<InventoryModAction> get actions => $_getList(8);

  @$pb.TagNumber(10)
  ModVersionOrigin get versionOrigin => $_getN(9);
  @$pb.TagNumber(10)
  set versionOrigin(ModVersionOrigin value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasVersionOrigin() => $_has(9);
  @$pb.TagNumber(10)
  void clearVersionOrigin() => $_clearField(10);
  @$pb.TagNumber(10)
  ModVersionOrigin ensureVersionOrigin() => $_ensure(9);
}

class ModLibraryFault extends $pb.GeneratedMessage {
  factory ModLibraryFault({
    ModLibraryFaultCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  ModLibraryFault._();

  factory ModLibraryFault.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModLibraryFault.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModLibraryFault',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<ModLibraryFaultCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: ModLibraryFaultCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModLibraryFault clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModLibraryFault copyWith(void Function(ModLibraryFault) updates) =>
      super.copyWith((message) => updates(message as ModLibraryFault))
          as ModLibraryFault;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModLibraryFault create() => ModLibraryFault._();
  @$core.override
  ModLibraryFault createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModLibraryFault getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModLibraryFault>(create);
  static ModLibraryFault? _defaultInstance;

  @$pb.TagNumber(1)
  ModLibraryFaultCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ModLibraryFaultCode value) => $_setField(1, value);
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

enum ModReply_Outcome { mod, fault, notSet }

class ModReply extends $pb.GeneratedMessage {
  factory ModReply({
    InventoryMod? mod,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (mod != null) result.mod = mod;
    if (fault != null) result.fault = fault;
    return result;
  }

  ModReply._();

  factory ModReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModReply_Outcome> _ModReply_OutcomeByTag = {
    1: ModReply_Outcome.mod,
    2: ModReply_Outcome.fault,
    0: ModReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<InventoryMod>(1, _omitFieldNames ? '' : 'mod',
        subBuilder: InventoryMod.create)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModReply copyWith(void Function(ModReply) updates) =>
      super.copyWith((message) => updates(message as ModReply)) as ModReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModReply create() => ModReply._();
  @$core.override
  ModReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModReply>(create);
  static ModReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ModReply_Outcome whichOutcome() => _ModReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  InventoryMod get mod => $_getN(0);
  @$pb.TagNumber(1)
  set mod(InventoryMod value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMod() => $_has(0);
  @$pb.TagNumber(1)
  void clearMod() => $_clearField(1);
  @$pb.TagNumber(1)
  InventoryMod ensureMod() => $_ensure(0);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

class RegisterModRequest extends $pb.GeneratedMessage {
  factory RegisterModRequest({
    $core.String? workspaceId,
    $core.String? modId,
    InventoryModMetadata? metadata,
    InventoryModKind? kind,
    ModLogicalPath? sourcePath,
    $core.String? backupVersionId,
    $core.String? nativeSourcePath,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (modId != null) result.modId = modId;
    if (metadata != null) result.metadata = metadata;
    if (kind != null) result.kind = kind;
    if (sourcePath != null) result.sourcePath = sourcePath;
    if (backupVersionId != null) result.backupVersionId = backupVersionId;
    if (nativeSourcePath != null) result.nativeSourcePath = nativeSourcePath;
    return result;
  }

  RegisterModRequest._();

  factory RegisterModRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterModRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterModRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..aOM<InventoryModMetadata>(3, _omitFieldNames ? '' : 'metadata',
        subBuilder: InventoryModMetadata.create)
    ..aE<InventoryModKind>(4, _omitFieldNames ? '' : 'kind',
        enumValues: InventoryModKind.values)
    ..aOM<ModLogicalPath>(5, _omitFieldNames ? '' : 'sourcePath',
        subBuilder: ModLogicalPath.create)
    ..aOS(6, _omitFieldNames ? '' : 'backupVersionId')
    ..aOS(7, _omitFieldNames ? '' : 'nativeSourcePath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterModRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterModRequest copyWith(void Function(RegisterModRequest) updates) =>
      super.copyWith((message) => updates(message as RegisterModRequest))
          as RegisterModRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterModRequest create() => RegisterModRequest._();
  @$core.override
  RegisterModRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterModRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterModRequest>(create);
  static RegisterModRequest? _defaultInstance;

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
  InventoryModMetadata get metadata => $_getN(2);
  @$pb.TagNumber(3)
  set metadata(InventoryModMetadata value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMetadata() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetadata() => $_clearField(3);
  @$pb.TagNumber(3)
  InventoryModMetadata ensureMetadata() => $_ensure(2);

  @$pb.TagNumber(4)
  InventoryModKind get kind => $_getN(3);
  @$pb.TagNumber(4)
  set kind(InventoryModKind value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);

  @$pb.TagNumber(5)
  ModLogicalPath get sourcePath => $_getN(4);
  @$pb.TagNumber(5)
  set sourcePath(ModLogicalPath value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSourcePath() => $_has(4);
  @$pb.TagNumber(5)
  void clearSourcePath() => $_clearField(5);
  @$pb.TagNumber(5)
  ModLogicalPath ensureSourcePath() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get backupVersionId => $_getSZ(5);
  @$pb.TagNumber(6)
  set backupVersionId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBackupVersionId() => $_has(5);
  @$pb.TagNumber(6)
  void clearBackupVersionId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get nativeSourcePath => $_getSZ(6);
  @$pb.TagNumber(7)
  set nativeSourcePath($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNativeSourcePath() => $_has(6);
  @$pb.TagNumber(7)
  void clearNativeSourcePath() => $_clearField(7);
}

class EditModRequest extends $pb.GeneratedMessage {
  factory EditModRequest({
    $core.String? modId,
    $fixnum.Int64? expectedRevision,
    InventoryModMetadata? metadata,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  EditModRequest._();

  factory EditModRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EditModRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditModRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<InventoryModMetadata>(3, _omitFieldNames ? '' : 'metadata',
        subBuilder: InventoryModMetadata.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditModRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditModRequest copyWith(void Function(EditModRequest) updates) =>
      super.copyWith((message) => updates(message as EditModRequest))
          as EditModRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EditModRequest create() => EditModRequest._();
  @$core.override
  EditModRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EditModRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditModRequest>(create);
  static EditModRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  InventoryModMetadata get metadata => $_getN(2);
  @$pb.TagNumber(3)
  set metadata(InventoryModMetadata value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMetadata() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetadata() => $_clearField(3);
  @$pb.TagNumber(3)
  InventoryModMetadata ensureMetadata() => $_ensure(2);
}

class ScanInventoryRequest extends $pb.GeneratedMessage {
  factory ScanInventoryRequest({
    $core.String? workspaceId,
    $core.int? candidateLimit,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (candidateLimit != null) result.candidateLimit = candidateLimit;
    return result;
  }

  ScanInventoryRequest._();

  factory ScanInventoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScanInventoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScanInventoryRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aI(2, _omitFieldNames ? '' : 'candidateLimit',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanInventoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanInventoryRequest copyWith(void Function(ScanInventoryRequest) updates) =>
      super.copyWith((message) => updates(message as ScanInventoryRequest))
          as ScanInventoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScanInventoryRequest create() => ScanInventoryRequest._();
  @$core.override
  ScanInventoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScanInventoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScanInventoryRequest>(create);
  static ScanInventoryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get candidateLimit => $_getIZ(1);
  @$pb.TagNumber(2)
  set candidateLimit($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCandidateLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearCandidateLimit() => $_clearField(2);
}

class UnmanagedModPath extends $pb.GeneratedMessage {
  factory UnmanagedModPath({
    ModLogicalPath? path,
    $core.bool? directory,
    $core.bool? unsupported,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (directory != null) result.directory = directory;
    if (unsupported != null) result.unsupported = unsupported;
    return result;
  }

  UnmanagedModPath._();

  factory UnmanagedModPath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnmanagedModPath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnmanagedModPath',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ModLogicalPath>(1, _omitFieldNames ? '' : 'path',
        subBuilder: ModLogicalPath.create)
    ..aOB(2, _omitFieldNames ? '' : 'directory')
    ..aOB(3, _omitFieldNames ? '' : 'unsupported')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnmanagedModPath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnmanagedModPath copyWith(void Function(UnmanagedModPath) updates) =>
      super.copyWith((message) => updates(message as UnmanagedModPath))
          as UnmanagedModPath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnmanagedModPath create() => UnmanagedModPath._();
  @$core.override
  UnmanagedModPath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnmanagedModPath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnmanagedModPath>(create);
  static UnmanagedModPath? _defaultInstance;

  @$pb.TagNumber(1)
  ModLogicalPath get path => $_getN(0);
  @$pb.TagNumber(1)
  set path(ModLogicalPath value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
  @$pb.TagNumber(1)
  ModLogicalPath ensurePath() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get directory => $_getBF(1);
  @$pb.TagNumber(2)
  set directory($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDirectory() => $_has(1);
  @$pb.TagNumber(2)
  void clearDirectory() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get unsupported => $_getBF(2);
  @$pb.TagNumber(3)
  set unsupported($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUnsupported() => $_has(2);
  @$pb.TagNumber(3)
  void clearUnsupported() => $_clearField(3);
}

class ModInventoryScan extends $pb.GeneratedMessage {
  factory ModInventoryScan({
    $core.Iterable<InventoryMod>? entries,
    $core.Iterable<UnmanagedModPath>? unmanaged,
    $core.bool? limited,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (unmanaged != null) result.unmanaged.addAll(unmanaged);
    if (limited != null) result.limited = limited;
    return result;
  }

  ModInventoryScan._();

  factory ModInventoryScan.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModInventoryScan.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModInventoryScan',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<InventoryMod>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: InventoryMod.create)
    ..pPM<UnmanagedModPath>(2, _omitFieldNames ? '' : 'unmanaged',
        subBuilder: UnmanagedModPath.create)
    ..aOB(3, _omitFieldNames ? '' : 'limited')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModInventoryScan clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModInventoryScan copyWith(void Function(ModInventoryScan) updates) =>
      super.copyWith((message) => updates(message as ModInventoryScan))
          as ModInventoryScan;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModInventoryScan create() => ModInventoryScan._();
  @$core.override
  ModInventoryScan createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModInventoryScan getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModInventoryScan>(create);
  static ModInventoryScan? _defaultInstance;

  /// Bounded summary (32 each), not a complete inventory. QueryMods pages persisted entries.
  @$pb.TagNumber(1)
  $pb.PbList<InventoryMod> get entries => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<UnmanagedModPath> get unmanaged => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get limited => $_getBF(2);
  @$pb.TagNumber(3)
  set limited($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimited() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimited() => $_clearField(3);
}

enum InventoryScanReply_Outcome { scan, fault, notSet }

class InventoryScanReply extends $pb.GeneratedMessage {
  factory InventoryScanReply({
    ModInventoryScan? scan,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (scan != null) result.scan = scan;
    if (fault != null) result.fault = fault;
    return result;
  }

  InventoryScanReply._();

  factory InventoryScanReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryScanReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, InventoryScanReply_Outcome>
      _InventoryScanReply_OutcomeByTag = {
    1: InventoryScanReply_Outcome.scan,
    2: InventoryScanReply_Outcome.fault,
    0: InventoryScanReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryScanReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ModInventoryScan>(1, _omitFieldNames ? '' : 'scan',
        subBuilder: ModInventoryScan.create)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryScanReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryScanReply copyWith(void Function(InventoryScanReply) updates) =>
      super.copyWith((message) => updates(message as InventoryScanReply))
          as InventoryScanReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryScanReply create() => InventoryScanReply._();
  @$core.override
  InventoryScanReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryScanReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryScanReply>(create);
  static InventoryScanReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  InventoryScanReply_Outcome whichOutcome() =>
      _InventoryScanReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModInventoryScan get scan => $_getN(0);
  @$pb.TagNumber(1)
  set scan(ModInventoryScan value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasScan() => $_has(0);
  @$pb.TagNumber(1)
  void clearScan() => $_clearField(1);
  @$pb.TagNumber(1)
  ModInventoryScan ensureScan() => $_ensure(0);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

class PublishModRequest extends $pb.GeneratedMessage {
  factory PublishModRequest({
    $core.String? modId,
    $fixnum.Int64? expectedRevision,
    $core.String? versionId,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (versionId != null) result.versionId = versionId;
    return result;
  }

  PublishModRequest._();

  factory PublishModRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublishModRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublishModRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'versionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishModRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishModRequest copyWith(void Function(PublishModRequest) updates) =>
      super.copyWith((message) => updates(message as PublishModRequest))
          as PublishModRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublishModRequest create() => PublishModRequest._();
  @$core.override
  PublishModRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PublishModRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublishModRequest>(create);
  static PublishModRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get versionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set versionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersionId() => $_clearField(3);
}

class PublicationRequest extends $pb.GeneratedMessage {
  factory PublicationRequest({
    $core.String? versionId,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    return result;
  }

  PublicationRequest._();

  factory PublicationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublicationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublicationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'versionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicationRequest copyWith(void Function(PublicationRequest) updates) =>
      super.copyWith((message) => updates(message as PublicationRequest))
          as PublicationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublicationRequest create() => PublicationRequest._();
  @$core.override
  PublicationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PublicationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublicationRequest>(create);
  static PublicationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get versionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set versionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);
}

class ModPublicationReceipt extends $pb.GeneratedMessage {
  factory ModPublicationReceipt({
    $core.String? versionId,
    $core.String? modId,
    $fixnum.Int64? expectedRevision,
    ModPublicationPhase? phase,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    if (modId != null) result.modId = modId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (phase != null) result.phase = phase;
    return result;
  }

  ModPublicationReceipt._();

  factory ModPublicationReceipt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModPublicationReceipt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModPublicationReceipt',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'versionId')
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<ModPublicationPhase>(4, _omitFieldNames ? '' : 'phase',
        enumValues: ModPublicationPhase.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPublicationReceipt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPublicationReceipt copyWith(
          void Function(ModPublicationReceipt) updates) =>
      super.copyWith((message) => updates(message as ModPublicationReceipt))
          as ModPublicationReceipt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModPublicationReceipt create() => ModPublicationReceipt._();
  @$core.override
  ModPublicationReceipt createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModPublicationReceipt getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModPublicationReceipt>(create);
  static ModPublicationReceipt? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get versionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set versionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get expectedRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpectedRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpectedRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  ModPublicationPhase get phase => $_getN(3);
  @$pb.TagNumber(4)
  set phase(ModPublicationPhase value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPhase() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhase() => $_clearField(4);
}

enum PublicationReply_Outcome { receipt, fault, notSet }

class PublicationReply extends $pb.GeneratedMessage {
  factory PublicationReply({
    ModPublicationReceipt? receipt,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (receipt != null) result.receipt = receipt;
    if (fault != null) result.fault = fault;
    return result;
  }

  PublicationReply._();

  factory PublicationReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublicationReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PublicationReply_Outcome>
      _PublicationReply_OutcomeByTag = {
    1: PublicationReply_Outcome.receipt,
    2: PublicationReply_Outcome.fault,
    0: PublicationReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublicationReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ModPublicationReceipt>(1, _omitFieldNames ? '' : 'receipt',
        subBuilder: ModPublicationReceipt.create)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicationReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicationReply copyWith(void Function(PublicationReply) updates) =>
      super.copyWith((message) => updates(message as PublicationReply))
          as PublicationReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublicationReply create() => PublicationReply._();
  @$core.override
  PublicationReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PublicationReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublicationReply>(create);
  static PublicationReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  PublicationReply_Outcome whichOutcome() =>
      _PublicationReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModPublicationReceipt get receipt => $_getN(0);
  @$pb.TagNumber(1)
  set receipt(ModPublicationReceipt value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReceipt() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceipt() => $_clearField(1);
  @$pb.TagNumber(1)
  ModPublicationReceipt ensureReceipt() => $_ensure(0);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

class ReadModVersionRequest extends $pb.GeneratedMessage {
  factory ReadModVersionRequest({
    $core.String? versionId,
    $core.int? offset,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    if (offset != null) result.offset = offset;
    return result;
  }

  ReadModVersionRequest._();

  factory ReadModVersionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadModVersionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadModVersionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'versionId')
    ..aI(2, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadModVersionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadModVersionRequest copyWith(
          void Function(ReadModVersionRequest) updates) =>
      super.copyWith((message) => updates(message as ReadModVersionRequest))
          as ReadModVersionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadModVersionRequest create() => ReadModVersionRequest._();
  @$core.override
  ReadModVersionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadModVersionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadModVersionRequest>(create);
  static ReadModVersionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get versionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set versionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get offset => $_getIZ(1);
  @$pb.TagNumber(2)
  set offset($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);
}

class ModPayload extends $pb.GeneratedMessage {
  factory ModPayload({
    $core.String? payloadId,
    $fixnum.Int64? length,
    $core.String? sha256,
  }) {
    final result = create();
    if (payloadId != null) result.payloadId = payloadId;
    if (length != null) result.length = length;
    if (sha256 != null) result.sha256 = sha256;
    return result;
  }

  ModPayload._();

  factory ModPayload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModPayload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModPayload',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'payloadId')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'sha256')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPayload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPayload copyWith(void Function(ModPayload) updates) =>
      super.copyWith((message) => updates(message as ModPayload)) as ModPayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModPayload create() => ModPayload._();
  @$core.override
  ModPayload createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModPayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModPayload>(create);
  static ModPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get payloadId => $_getSZ(0);
  @$pb.TagNumber(1)
  set payloadId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPayloadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPayloadId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get length => $_getI64(1);
  @$pb.TagNumber(2)
  set length($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLength() => $_has(1);
  @$pb.TagNumber(2)
  void clearLength() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sha256 => $_getSZ(2);
  @$pb.TagNumber(3)
  set sha256($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSha256() => $_has(2);
  @$pb.TagNumber(3)
  void clearSha256() => $_clearField(3);
}

class ModManifestEntry extends $pb.GeneratedMessage {
  factory ModManifestEntry({
    ModLogicalPath? path,
    ModPayload? payload,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (payload != null) result.payload = payload;
    return result;
  }

  ModManifestEntry._();

  factory ModManifestEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModManifestEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModManifestEntry',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ModLogicalPath>(1, _omitFieldNames ? '' : 'path',
        subBuilder: ModLogicalPath.create)
    ..aOM<ModPayload>(2, _omitFieldNames ? '' : 'payload',
        subBuilder: ModPayload.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModManifestEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModManifestEntry copyWith(void Function(ModManifestEntry) updates) =>
      super.copyWith((message) => updates(message as ModManifestEntry))
          as ModManifestEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModManifestEntry create() => ModManifestEntry._();
  @$core.override
  ModManifestEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModManifestEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModManifestEntry>(create);
  static ModManifestEntry? _defaultInstance;

  @$pb.TagNumber(1)
  ModLogicalPath get path => $_getN(0);
  @$pb.TagNumber(1)
  set path(ModLogicalPath value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
  @$pb.TagNumber(1)
  ModLogicalPath ensurePath() => $_ensure(0);

  @$pb.TagNumber(2)
  ModPayload get payload => $_getN(1);
  @$pb.TagNumber(2)
  set payload(ModPayload value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField(2);
  @$pb.TagNumber(2)
  ModPayload ensurePayload() => $_ensure(1);
}

class ModVersionOrigin extends $pb.GeneratedMessage {
  factory ModVersionOrigin({
    $core.String? outputActionId,
    $core.String? archiveArtifactId,
  }) {
    final result = create();
    if (outputActionId != null) result.outputActionId = outputActionId;
    if (archiveArtifactId != null) result.archiveArtifactId = archiveArtifactId;
    return result;
  }

  ModVersionOrigin._();

  factory ModVersionOrigin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModVersionOrigin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModVersionOrigin',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'outputActionId')
    ..aOS(2, _omitFieldNames ? '' : 'archiveArtifactId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModVersionOrigin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModVersionOrigin copyWith(void Function(ModVersionOrigin) updates) =>
      super.copyWith((message) => updates(message as ModVersionOrigin))
          as ModVersionOrigin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModVersionOrigin create() => ModVersionOrigin._();
  @$core.override
  ModVersionOrigin createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModVersionOrigin getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModVersionOrigin>(create);
  static ModVersionOrigin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get outputActionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set outputActionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOutputActionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOutputActionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get archiveArtifactId => $_getSZ(1);
  @$pb.TagNumber(2)
  set archiveArtifactId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasArchiveArtifactId() => $_has(1);
  @$pb.TagNumber(2)
  void clearArchiveArtifactId() => $_clearField(2);
}

class ModVersionPage extends $pb.GeneratedMessage {
  factory ModVersionPage({
    $core.String? versionId,
    $core.String? modId,
    $core.Iterable<ModManifestEntry>? entries,
    $core.int? nextOffset,
    ModVersionOrigin? origin,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    if (modId != null) result.modId = modId;
    if (entries != null) result.entries.addAll(entries);
    if (nextOffset != null) result.nextOffset = nextOffset;
    if (origin != null) result.origin = origin;
    return result;
  }

  ModVersionPage._();

  factory ModVersionPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModVersionPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModVersionPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'versionId')
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..pPM<ModManifestEntry>(3, _omitFieldNames ? '' : 'entries',
        subBuilder: ModManifestEntry.create)
    ..aI(4, _omitFieldNames ? '' : 'nextOffset', fieldType: $pb.PbFieldType.OU3)
    ..aOM<ModVersionOrigin>(5, _omitFieldNames ? '' : 'origin',
        subBuilder: ModVersionOrigin.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModVersionPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModVersionPage copyWith(void Function(ModVersionPage) updates) =>
      super.copyWith((message) => updates(message as ModVersionPage))
          as ModVersionPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModVersionPage create() => ModVersionPage._();
  @$core.override
  ModVersionPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModVersionPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModVersionPage>(create);
  static ModVersionPage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get versionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set versionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<ModManifestEntry> get entries => $_getList(2);

  @$pb.TagNumber(4)
  $core.int get nextOffset => $_getIZ(3);
  @$pb.TagNumber(4)
  set nextOffset($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNextOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearNextOffset() => $_clearField(4);

  @$pb.TagNumber(5)
  ModVersionOrigin get origin => $_getN(4);
  @$pb.TagNumber(5)
  set origin(ModVersionOrigin value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasOrigin() => $_has(4);
  @$pb.TagNumber(5)
  void clearOrigin() => $_clearField(5);
  @$pb.TagNumber(5)
  ModVersionOrigin ensureOrigin() => $_ensure(4);
}

enum ModVersionReply_Outcome { version, fault, notSet }

class ModVersionReply extends $pb.GeneratedMessage {
  factory ModVersionReply({
    ModVersionPage? version,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (fault != null) result.fault = fault;
    return result;
  }

  ModVersionReply._();

  factory ModVersionReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModVersionReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModVersionReply_Outcome>
      _ModVersionReply_OutcomeByTag = {
    1: ModVersionReply_Outcome.version,
    2: ModVersionReply_Outcome.fault,
    0: ModVersionReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModVersionReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ModVersionPage>(1, _omitFieldNames ? '' : 'version',
        subBuilder: ModVersionPage.create)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModVersionReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModVersionReply copyWith(void Function(ModVersionReply) updates) =>
      super.copyWith((message) => updates(message as ModVersionReply))
          as ModVersionReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModVersionReply create() => ModVersionReply._();
  @$core.override
  ModVersionReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModVersionReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModVersionReply>(create);
  static ModVersionReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ModVersionReply_Outcome whichOutcome() =>
      _ModVersionReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModVersionPage get version => $_getN(0);
  @$pb.TagNumber(1)
  set version(ModVersionPage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ModVersionPage ensureVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

class ReadModPayloadRequest extends $pb.GeneratedMessage {
  factory ReadModPayloadRequest({
    $core.String? versionId,
    $core.String? payloadId,
    $fixnum.Int64? offset,
    $core.int? count,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    if (payloadId != null) result.payloadId = payloadId;
    if (offset != null) result.offset = offset;
    if (count != null) result.count = count;
    return result;
  }

  ReadModPayloadRequest._();

  factory ReadModPayloadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadModPayloadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadModPayloadRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'versionId')
    ..aOS(2, _omitFieldNames ? '' : 'payloadId')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(4, _omitFieldNames ? '' : 'count', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadModPayloadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadModPayloadRequest copyWith(
          void Function(ReadModPayloadRequest) updates) =>
      super.copyWith((message) => updates(message as ReadModPayloadRequest))
          as ReadModPayloadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadModPayloadRequest create() => ReadModPayloadRequest._();
  @$core.override
  ReadModPayloadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadModPayloadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadModPayloadRequest>(create);
  static ReadModPayloadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get versionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set versionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get payloadId => $_getSZ(1);
  @$pb.TagNumber(2)
  set payloadId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPayloadId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayloadId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get offset => $_getI64(2);
  @$pb.TagNumber(3)
  set offset($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffset() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get count => $_getIZ(3);
  @$pb.TagNumber(4)
  set count($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearCount() => $_clearField(4);
}

enum ModPayloadReply_Outcome { data, fault, notSet }

class ModPayloadReply extends $pb.GeneratedMessage {
  factory ModPayloadReply({
    $core.List<$core.int>? data,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (data != null) result.data = data;
    if (fault != null) result.fault = fault;
    return result;
  }

  ModPayloadReply._();

  factory ModPayloadReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModPayloadReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModPayloadReply_Outcome>
      _ModPayloadReply_OutcomeByTag = {
    1: ModPayloadReply_Outcome.data,
    2: ModPayloadReply_Outcome.fault,
    0: ModPayloadReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModPayloadReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPayloadReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPayloadReply copyWith(void Function(ModPayloadReply) updates) =>
      super.copyWith((message) => updates(message as ModPayloadReply))
          as ModPayloadReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModPayloadReply create() => ModPayloadReply._();
  @$core.override
  ModPayloadReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModPayloadReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModPayloadReply>(create);
  static ModPayloadReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ModPayloadReply_Outcome whichOutcome() =>
      _ModPayloadReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
