// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bundles.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'archive_installation.pb.dart' as $2;
import 'artifacts.pb.dart' as $0;
import 'bundles.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'bundles.pbenum.dart';

class BundleReference extends $pb.GeneratedMessage {
  factory BundleReference({
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

  BundleReference._();

  factory BundleReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleReference',
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
  BundleReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleReference copyWith(void Function(BundleReference) updates) =>
      super.copyWith((message) => updates(message as BundleReference))
          as BundleReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleReference create() => BundleReference._();
  @$core.override
  BundleReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleReference>(create);
  static BundleReference? _defaultInstance;

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

class BundleFound extends $pb.GeneratedMessage {
  factory BundleFound({
    ModBundle? bundle,
  }) {
    final result = create();
    if (bundle != null) result.bundle = bundle;
    return result;
  }

  BundleFound._();

  factory BundleFound.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleFound.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleFound',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ModBundle>(1, _omitFieldNames ? '' : 'bundle',
        subBuilder: ModBundle.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleFound clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleFound copyWith(void Function(BundleFound) updates) =>
      super.copyWith((message) => updates(message as BundleFound))
          as BundleFound;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleFound create() => BundleFound._();
  @$core.override
  BundleFound createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleFound getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleFound>(create);
  static BundleFound? _defaultInstance;

  @$pb.TagNumber(1)
  ModBundle get bundle => $_getN(0);
  @$pb.TagNumber(1)
  set bundle(ModBundle value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBundle() => $_has(0);
  @$pb.TagNumber(1)
  void clearBundle() => $_clearField(1);
  @$pb.TagNumber(1)
  ModBundle ensureBundle() => $_ensure(0);
}

class BundleArchive extends $pb.GeneratedMessage {
  factory BundleArchive({
    $core.int? index,
    $core.Iterable<$core.String>? path,
    $fixnum.Int64? bytes,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (path != null) result.path.addAll(path);
    if (bytes != null) result.bytes = bytes;
    return result;
  }

  BundleArchive._();

  factory BundleArchive.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleArchive.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleArchive',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..pPS(2, _omitFieldNames ? '' : 'path')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleArchive clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleArchive copyWith(void Function(BundleArchive) updates) =>
      super.copyWith((message) => updates(message as BundleArchive))
          as BundleArchive;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleArchive create() => BundleArchive._();
  @$core.override
  BundleArchive createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleArchive getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleArchive>(create);
  static BundleArchive? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get path => $_getList(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get bytes => $_getI64(2);
  @$pb.TagNumber(3)
  set bytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearBytes() => $_clearField(3);
}

class BundleDiscovery extends $pb.GeneratedMessage {
  factory BundleDiscovery({
    $2.ArchiveInstallationDraft? draft,
    $core.Iterable<BundleArchive>? archives,
  }) {
    final result = create();
    if (draft != null) result.draft = draft;
    if (archives != null) result.archives.addAll(archives);
    return result;
  }

  BundleDiscovery._();

  factory BundleDiscovery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleDiscovery.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleDiscovery',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$2.ArchiveInstallationDraft>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: $2.ArchiveInstallationDraft.create)
    ..pPM<BundleArchive>(2, _omitFieldNames ? '' : 'archives',
        subBuilder: BundleArchive.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleDiscovery clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleDiscovery copyWith(void Function(BundleDiscovery) updates) =>
      super.copyWith((message) => updates(message as BundleDiscovery))
          as BundleDiscovery;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleDiscovery create() => BundleDiscovery._();
  @$core.override
  BundleDiscovery createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleDiscovery getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleDiscovery>(create);
  static BundleDiscovery? _defaultInstance;

  @$pb.TagNumber(1)
  $2.ArchiveInstallationDraft get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft($2.ArchiveInstallationDraft value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.ArchiveInstallationDraft ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<BundleArchive> get archives => $_getList(1);
}

class BundleSelection extends $pb.GeneratedMessage {
  factory BundleSelection({
    $2.InstallationDraftReference? draft,
    $core.Iterable<$core.int>? entries,
  }) {
    final result = create();
    if (draft != null) result.draft = draft;
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  BundleSelection._();

  factory BundleSelection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleSelection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleSelection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$2.InstallationDraftReference>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: $2.InstallationDraftReference.create)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'entries', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleSelection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleSelection copyWith(void Function(BundleSelection) updates) =>
      super.copyWith((message) => updates(message as BundleSelection))
          as BundleSelection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleSelection create() => BundleSelection._();
  @$core.override
  BundleSelection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleSelection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleSelection>(create);
  static BundleSelection? _defaultInstance;

  @$pb.TagNumber(1)
  $2.InstallationDraftReference get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft($2.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.InstallationDraftReference ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.int> get entries => $_getList(1);
}

class BundleModRequest extends $pb.GeneratedMessage {
  factory BundleModRequest({
    BundleReference? reference,
    $core.String? mod,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (mod != null) result.mod = mod;
    return result;
  }

  BundleModRequest._();

  factory BundleModRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleModRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleModRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<BundleReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: BundleReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'mod')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleModRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleModRequest copyWith(void Function(BundleModRequest) updates) =>
      super.copyWith((message) => updates(message as BundleModRequest))
          as BundleModRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleModRequest create() => BundleModRequest._();
  @$core.override
  BundleModRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleModRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleModRequest>(create);
  static BundleModRequest? _defaultInstance;

  @$pb.TagNumber(1)
  BundleReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(BundleReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  BundleReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get mod => $_getSZ(1);
  @$pb.TagNumber(2)
  set mod($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMod() => $_has(1);
  @$pb.TagNumber(2)
  void clearMod() => $_clearField(2);
}

class NestedBundleSelection extends $pb.GeneratedMessage {
  factory NestedBundleSelection({
    BundleModRequest? target,
    $2.InstallationDraftReference? draft,
    $core.Iterable<$core.int>? entries,
  }) {
    final result = create();
    if (target != null) result.target = target;
    if (draft != null) result.draft = draft;
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  NestedBundleSelection._();

  factory NestedBundleSelection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NestedBundleSelection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NestedBundleSelection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<BundleModRequest>(1, _omitFieldNames ? '' : 'target',
        subBuilder: BundleModRequest.create)
    ..aOM<$2.InstallationDraftReference>(2, _omitFieldNames ? '' : 'draft',
        subBuilder: $2.InstallationDraftReference.create)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'entries', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NestedBundleSelection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NestedBundleSelection copyWith(
          void Function(NestedBundleSelection) updates) =>
      super.copyWith((message) => updates(message as NestedBundleSelection))
          as NestedBundleSelection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NestedBundleSelection create() => NestedBundleSelection._();
  @$core.override
  NestedBundleSelection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NestedBundleSelection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NestedBundleSelection>(create);
  static NestedBundleSelection? _defaultInstance;

  @$pb.TagNumber(1)
  BundleModRequest get target => $_getN(0);
  @$pb.TagNumber(1)
  set target(BundleModRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);
  @$pb.TagNumber(1)
  BundleModRequest ensureTarget() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.InstallationDraftReference get draft => $_getN(1);
  @$pb.TagNumber(2)
  set draft($2.InstallationDraftReference value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDraft() => $_has(1);
  @$pb.TagNumber(2)
  void clearDraft() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.InstallationDraftReference ensureDraft() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.int> get entries => $_getList(2);
}

class BundleModRename extends $pb.GeneratedMessage {
  factory BundleModRename({
    BundleModRequest? target,
    $core.String? name,
  }) {
    final result = create();
    if (target != null) result.target = target;
    if (name != null) result.name = name;
    return result;
  }

  BundleModRename._();

  factory BundleModRename.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleModRename.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleModRename',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<BundleModRequest>(1, _omitFieldNames ? '' : 'target',
        subBuilder: BundleModRequest.create)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleModRename clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleModRename copyWith(void Function(BundleModRename) updates) =>
      super.copyWith((message) => updates(message as BundleModRename))
          as BundleModRename;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleModRename create() => BundleModRename._();
  @$core.override
  BundleModRename createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleModRename getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleModRename>(create);
  static BundleModRename? _defaultInstance;

  @$pb.TagNumber(1)
  BundleModRequest get target => $_getN(0);
  @$pb.TagNumber(1)
  set target(BundleModRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);
  @$pb.TagNumber(1)
  BundleModRequest ensureTarget() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class BundleModMove extends $pb.GeneratedMessage {
  factory BundleModMove({
    BundleModRequest? target,
    $core.bool? earlier,
  }) {
    final result = create();
    if (target != null) result.target = target;
    if (earlier != null) result.earlier = earlier;
    return result;
  }

  BundleModMove._();

  factory BundleModMove.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleModMove.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleModMove',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<BundleModRequest>(1, _omitFieldNames ? '' : 'target',
        subBuilder: BundleModRequest.create)
    ..aOB(2, _omitFieldNames ? '' : 'earlier')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleModMove clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleModMove copyWith(void Function(BundleModMove) updates) =>
      super.copyWith((message) => updates(message as BundleModMove))
          as BundleModMove;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleModMove create() => BundleModMove._();
  @$core.override
  BundleModMove createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleModMove getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleModMove>(create);
  static BundleModMove? _defaultInstance;

  @$pb.TagNumber(1)
  BundleModRequest get target => $_getN(0);
  @$pb.TagNumber(1)
  set target(BundleModRequest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);
  @$pb.TagNumber(1)
  BundleModRequest ensureTarget() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get earlier => $_getBF(1);
  @$pb.TagNumber(2)
  set earlier($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEarlier() => $_has(1);
  @$pb.TagNumber(2)
  void clearEarlier() => $_clearField(2);
}

class BundleConfiguration extends $pb.GeneratedMessage {
  factory BundleConfiguration({
    ModBundle? bundle,
    BundleDiscovery? prepared,
  }) {
    final result = create();
    if (bundle != null) result.bundle = bundle;
    if (prepared != null) result.prepared = prepared;
    return result;
  }

  BundleConfiguration._();

  factory BundleConfiguration.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleConfiguration.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleConfiguration',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ModBundle>(1, _omitFieldNames ? '' : 'bundle',
        subBuilder: ModBundle.create)
    ..aOM<BundleDiscovery>(2, _omitFieldNames ? '' : 'prepared',
        subBuilder: BundleDiscovery.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleConfiguration clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleConfiguration copyWith(void Function(BundleConfiguration) updates) =>
      super.copyWith((message) => updates(message as BundleConfiguration))
          as BundleConfiguration;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleConfiguration create() => BundleConfiguration._();
  @$core.override
  BundleConfiguration createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleConfiguration getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleConfiguration>(create);
  static BundleConfiguration? _defaultInstance;

  @$pb.TagNumber(1)
  ModBundle get bundle => $_getN(0);
  @$pb.TagNumber(1)
  set bundle(ModBundle value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBundle() => $_has(0);
  @$pb.TagNumber(1)
  void clearBundle() => $_clearField(1);
  @$pb.TagNumber(1)
  ModBundle ensureBundle() => $_ensure(0);

  @$pb.TagNumber(2)
  BundleDiscovery get prepared => $_getN(1);
  @$pb.TagNumber(2)
  set prepared(BundleDiscovery value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPrepared() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrepared() => $_clearField(2);
  @$pb.TagNumber(2)
  BundleDiscovery ensurePrepared() => $_ensure(1);
}

class BundleArchivePath extends $pb.GeneratedMessage {
  factory BundleArchivePath({
    $core.Iterable<$core.String>? components,
  }) {
    final result = create();
    if (components != null) result.components.addAll(components);
    return result;
  }

  BundleArchivePath._();

  factory BundleArchivePath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleArchivePath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleArchivePath',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'components')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleArchivePath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleArchivePath copyWith(void Function(BundleArchivePath) updates) =>
      super.copyWith((message) => updates(message as BundleArchivePath))
          as BundleArchivePath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleArchivePath create() => BundleArchivePath._();
  @$core.override
  BundleArchivePath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleArchivePath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleArchivePath>(create);
  static BundleArchivePath? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get components => $_getList(0);
}

class BundleMod extends $pb.GeneratedMessage {
  factory BundleMod({
    $core.String? id,
    $core.String? sourceId,
    $core.String? modId,
    $core.String? name,
    $core.int? order,
    $core.Iterable<BundleArchivePath>? archives,
    $fixnum.Int64? bytes,
    BundleModState? state,
    $core.String? attemptId,
    $core.String? problem,
    $core.bool? incompleteArchive,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (sourceId != null) result.sourceId = sourceId;
    if (modId != null) result.modId = modId;
    if (name != null) result.name = name;
    if (order != null) result.order = order;
    if (archives != null) result.archives.addAll(archives);
    if (bytes != null) result.bytes = bytes;
    if (state != null) result.state = state;
    if (attemptId != null) result.attemptId = attemptId;
    if (problem != null) result.problem = problem;
    if (incompleteArchive != null) result.incompleteArchive = incompleteArchive;
    return result;
  }

  BundleMod._();

  factory BundleMod.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleMod.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleMod',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'sourceId')
    ..aOS(3, _omitFieldNames ? '' : 'modId')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aI(5, _omitFieldNames ? '' : 'order', fieldType: $pb.PbFieldType.OU3)
    ..pPM<BundleArchivePath>(6, _omitFieldNames ? '' : 'archives',
        subBuilder: BundleArchivePath.create)
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<BundleModState>(8, _omitFieldNames ? '' : 'state',
        enumValues: BundleModState.values)
    ..aOS(9, _omitFieldNames ? '' : 'attemptId')
    ..aOS(10, _omitFieldNames ? '' : 'problem')
    ..aOB(11, _omitFieldNames ? '' : 'incompleteArchive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleMod clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleMod copyWith(void Function(BundleMod) updates) =>
      super.copyWith((message) => updates(message as BundleMod)) as BundleMod;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleMod create() => BundleMod._();
  @$core.override
  BundleMod createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleMod getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BundleMod>(create);
  static BundleMod? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sourceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sourceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSourceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSourceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get modId => $_getSZ(2);
  @$pb.TagNumber(3)
  set modId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModId() => $_has(2);
  @$pb.TagNumber(3)
  void clearModId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get order => $_getIZ(4);
  @$pb.TagNumber(5)
  set order($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOrder() => $_has(4);
  @$pb.TagNumber(5)
  void clearOrder() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<BundleArchivePath> get archives => $_getList(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get bytes => $_getI64(6);
  @$pb.TagNumber(7)
  set bytes($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearBytes() => $_clearField(7);

  @$pb.TagNumber(8)
  BundleModState get state => $_getN(7);
  @$pb.TagNumber(8)
  set state(BundleModState value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasState() => $_has(7);
  @$pb.TagNumber(8)
  void clearState() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get attemptId => $_getSZ(8);
  @$pb.TagNumber(9)
  set attemptId($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAttemptId() => $_has(8);
  @$pb.TagNumber(9)
  void clearAttemptId() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get problem => $_getSZ(9);
  @$pb.TagNumber(10)
  set problem($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasProblem() => $_has(9);
  @$pb.TagNumber(10)
  void clearProblem() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get incompleteArchive => $_getBF(10);
  @$pb.TagNumber(11)
  set incompleteArchive($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasIncompleteArchive() => $_has(10);
  @$pb.TagNumber(11)
  void clearIncompleteArchive() => $_clearField(11);
}

class ModBundle extends $pb.GeneratedMessage {
  factory ModBundle({
    BundleReference? reference,
    $0.ArtifactReference? artifact,
    $core.String? archiveName,
    $core.Iterable<BundleMod>? mods,
    $fixnum.Int64? temporaryBytes,
    $core.String? problem,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (artifact != null) result.artifact = artifact;
    if (archiveName != null) result.archiveName = archiveName;
    if (mods != null) result.mods.addAll(mods);
    if (temporaryBytes != null) result.temporaryBytes = temporaryBytes;
    if (problem != null) result.problem = problem;
    return result;
  }

  ModBundle._();

  factory ModBundle.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModBundle.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModBundle',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<BundleReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: BundleReference.create)
    ..aOM<$0.ArtifactReference>(2, _omitFieldNames ? '' : 'artifact',
        subBuilder: $0.ArtifactReference.create)
    ..aOS(3, _omitFieldNames ? '' : 'archiveName')
    ..pPM<BundleMod>(4, _omitFieldNames ? '' : 'mods',
        subBuilder: BundleMod.create)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'temporaryBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(6, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModBundle clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModBundle copyWith(void Function(ModBundle) updates) =>
      super.copyWith((message) => updates(message as ModBundle)) as ModBundle;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModBundle create() => ModBundle._();
  @$core.override
  ModBundle createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModBundle getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModBundle>(create);
  static ModBundle? _defaultInstance;

  @$pb.TagNumber(1)
  BundleReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(BundleReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  BundleReference ensureReference() => $_ensure(0);

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
  $pb.PbList<BundleMod> get mods => $_getList(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get temporaryBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set temporaryBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTemporaryBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearTemporaryBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get problem => $_getSZ(5);
  @$pb.TagNumber(6)
  set problem($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProblem() => $_has(5);
  @$pb.TagNumber(6)
  void clearProblem() => $_clearField(6);
}

class BundleClosed extends $pb.GeneratedMessage {
  factory BundleClosed() => create();

  BundleClosed._();

  factory BundleClosed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleClosed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleClosed',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleClosed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleClosed copyWith(void Function(BundleClosed) updates) =>
      super.copyWith((message) => updates(message as BundleClosed))
          as BundleClosed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleClosed create() => BundleClosed._();
  @$core.override
  BundleClosed createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleClosed getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleClosed>(create);
  static BundleClosed? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
