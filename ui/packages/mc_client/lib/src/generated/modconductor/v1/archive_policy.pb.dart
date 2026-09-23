// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_policy.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'archive_policy.pbenum.dart';
import 'bethesda_plugins.pb.dart' as $2;
import 'profile_data.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'archive_policy.pbenum.dart';

class ScanArchivePolicyRequest extends $pb.GeneratedMessage {
  factory ScanArchivePolicyRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? headersId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (headersId != null) result.headersId = headersId;
    return result;
  }

  ScanArchivePolicyRequest._();

  factory ScanArchivePolicyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScanArchivePolicyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScanArchivePolicyRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'headersId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanArchivePolicyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanArchivePolicyRequest copyWith(
          void Function(ScanArchivePolicyRequest) updates) =>
      super.copyWith((message) => updates(message as ScanArchivePolicyRequest))
          as ScanArchivePolicyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScanArchivePolicyRequest create() => ScanArchivePolicyRequest._();
  @$core.override
  ScanArchivePolicyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScanArchivePolicyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScanArchivePolicyRequest>(create);
  static ScanArchivePolicyRequest? _defaultInstance;

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
  $core.String get headersId => $_getSZ(2);
  @$pb.TagNumber(3)
  set headersId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeadersId() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeadersId() => $_clearField(3);
}

class ReadArchivePolicyRequest extends $pb.GeneratedMessage {
  factory ReadArchivePolicyRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? snapshotId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (snapshotId != null) result.snapshotId = snapshotId;
    return result;
  }

  ReadArchivePolicyRequest._();

  factory ReadArchivePolicyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadArchivePolicyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadArchivePolicyRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'snapshotId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadArchivePolicyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadArchivePolicyRequest copyWith(
          void Function(ReadArchivePolicyRequest) updates) =>
      super.copyWith((message) => updates(message as ReadArchivePolicyRequest))
          as ReadArchivePolicyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadArchivePolicyRequest create() => ReadArchivePolicyRequest._();
  @$core.override
  ReadArchivePolicyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadArchivePolicyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadArchivePolicyRequest>(create);
  static ReadArchivePolicyRequest? _defaultInstance;

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
  $core.String get snapshotId => $_getSZ(2);
  @$pb.TagNumber(3)
  set snapshotId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSnapshotId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSnapshotId() => $_clearField(3);
}

class ApplyArchivePolicyRequest extends $pb.GeneratedMessage {
  factory ApplyArchivePolicyRequest({
    $core.String? id,
    $1.ProfileDataRef? expected,
    $core.String? snapshotId,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (expected != null) result.expected = expected;
    if (snapshotId != null) result.snapshotId = snapshotId;
    return result;
  }

  ApplyArchivePolicyRequest._();

  factory ApplyArchivePolicyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyArchivePolicyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyArchivePolicyRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<$1.ProfileDataRef>(2, _omitFieldNames ? '' : 'expected',
        subBuilder: $1.ProfileDataRef.create)
    ..aOS(3, _omitFieldNames ? '' : 'snapshotId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyArchivePolicyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyArchivePolicyRequest copyWith(
          void Function(ApplyArchivePolicyRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyArchivePolicyRequest))
          as ApplyArchivePolicyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyArchivePolicyRequest create() => ApplyArchivePolicyRequest._();
  @$core.override
  ApplyArchivePolicyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyArchivePolicyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyArchivePolicyRequest>(create);
  static ApplyArchivePolicyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.ProfileDataRef get expected => $_getN(1);
  @$pb.TagNumber(2)
  set expected($1.ProfileDataRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpected() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpected() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ProfileDataRef ensureExpected() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get snapshotId => $_getSZ(2);
  @$pb.TagNumber(3)
  set snapshotId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSnapshotId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSnapshotId() => $_clearField(3);
}

class RestoreArchivePolicyRequest extends $pb.GeneratedMessage {
  factory RestoreArchivePolicyRequest({
    $core.String? id,
    $1.ProfileDataRef? expected,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (expected != null) result.expected = expected;
    return result;
  }

  RestoreArchivePolicyRequest._();

  factory RestoreArchivePolicyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RestoreArchivePolicyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RestoreArchivePolicyRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<$1.ProfileDataRef>(2, _omitFieldNames ? '' : 'expected',
        subBuilder: $1.ProfileDataRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestoreArchivePolicyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestoreArchivePolicyRequest copyWith(
          void Function(RestoreArchivePolicyRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RestoreArchivePolicyRequest))
          as RestoreArchivePolicyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RestoreArchivePolicyRequest create() =>
      RestoreArchivePolicyRequest._();
  @$core.override
  RestoreArchivePolicyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RestoreArchivePolicyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RestoreArchivePolicyRequest>(create);
  static RestoreArchivePolicyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.ProfileDataRef get expected => $_getN(1);
  @$pb.TagNumber(2)
  set expected($1.ProfileDataRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpected() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpected() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ProfileDataRef ensureExpected() => $_ensure(1);
}

class ArchivePolicyEntry extends $pb.GeneratedMessage {
  factory ArchivePolicyEntry({
    $core.String? name,
    $core.int? position,
    ArchivePolicyState? state,
    $core.bool? required,
    $core.bool? explicit,
    $core.String? iniKey,
    $core.int? iniPosition,
    $core.String? associatedPlugin,
    $core.Iterable<$core.String>? reasons,
    $2.BethesdaPluginSource? source,
    $core.String? format,
    $core.String? problem,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (position != null) result.position = position;
    if (state != null) result.state = state;
    if (required != null) result.required = required;
    if (explicit != null) result.explicit = explicit;
    if (iniKey != null) result.iniKey = iniKey;
    if (iniPosition != null) result.iniPosition = iniPosition;
    if (associatedPlugin != null) result.associatedPlugin = associatedPlugin;
    if (reasons != null) result.reasons.addAll(reasons);
    if (source != null) result.source = source;
    if (format != null) result.format = format;
    if (problem != null) result.problem = problem;
    return result;
  }

  ArchivePolicyEntry._();

  factory ArchivePolicyEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArchivePolicyEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArchivePolicyEntry',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aI(2, _omitFieldNames ? '' : 'position', fieldType: $pb.PbFieldType.OU3)
    ..aE<ArchivePolicyState>(3, _omitFieldNames ? '' : 'state',
        enumValues: ArchivePolicyState.values)
    ..aOB(4, _omitFieldNames ? '' : 'required')
    ..aOB(5, _omitFieldNames ? '' : 'explicit')
    ..aOS(6, _omitFieldNames ? '' : 'iniKey')
    ..aI(7, _omitFieldNames ? '' : 'iniPosition',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(8, _omitFieldNames ? '' : 'associatedPlugin')
    ..pPS(9, _omitFieldNames ? '' : 'reasons')
    ..aOM<$2.BethesdaPluginSource>(10, _omitFieldNames ? '' : 'source',
        subBuilder: $2.BethesdaPluginSource.create)
    ..aOS(11, _omitFieldNames ? '' : 'format')
    ..aOS(12, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchivePolicyEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchivePolicyEntry copyWith(void Function(ArchivePolicyEntry) updates) =>
      super.copyWith((message) => updates(message as ArchivePolicyEntry))
          as ArchivePolicyEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArchivePolicyEntry create() => ArchivePolicyEntry._();
  @$core.override
  ArchivePolicyEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArchivePolicyEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArchivePolicyEntry>(create);
  static ArchivePolicyEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get position => $_getIZ(1);
  @$pb.TagNumber(2)
  set position($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPosition() => $_has(1);
  @$pb.TagNumber(2)
  void clearPosition() => $_clearField(2);

  @$pb.TagNumber(3)
  ArchivePolicyState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(ArchivePolicyState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get required => $_getBF(3);
  @$pb.TagNumber(4)
  set required($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRequired() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequired() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get explicit => $_getBF(4);
  @$pb.TagNumber(5)
  set explicit($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExplicit() => $_has(4);
  @$pb.TagNumber(5)
  void clearExplicit() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get iniKey => $_getSZ(5);
  @$pb.TagNumber(6)
  set iniKey($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIniKey() => $_has(5);
  @$pb.TagNumber(6)
  void clearIniKey() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get iniPosition => $_getIZ(6);
  @$pb.TagNumber(7)
  set iniPosition($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIniPosition() => $_has(6);
  @$pb.TagNumber(7)
  void clearIniPosition() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get associatedPlugin => $_getSZ(7);
  @$pb.TagNumber(8)
  set associatedPlugin($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAssociatedPlugin() => $_has(7);
  @$pb.TagNumber(8)
  void clearAssociatedPlugin() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get reasons => $_getList(8);

  @$pb.TagNumber(10)
  $2.BethesdaPluginSource get source => $_getN(9);
  @$pb.TagNumber(10)
  set source($2.BethesdaPluginSource value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSource() => $_has(9);
  @$pb.TagNumber(10)
  void clearSource() => $_clearField(10);
  @$pb.TagNumber(10)
  $2.BethesdaPluginSource ensureSource() => $_ensure(9);

  @$pb.TagNumber(11)
  $core.String get format => $_getSZ(10);
  @$pb.TagNumber(11)
  set format($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasFormat() => $_has(10);
  @$pb.TagNumber(11)
  void clearFormat() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get problem => $_getSZ(11);
  @$pb.TagNumber(12)
  set problem($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasProblem() => $_has(11);
  @$pb.TagNumber(12)
  void clearProblem() => $_clearField(12);
}

class ArchivePolicyView extends $pb.GeneratedMessage {
  factory ArchivePolicyView({
    $1.ProfileDataRef? reference,
    $core.String? snapshotId,
    $fixnum.Int64? observedAtUnixMs,
    $core.bool? stale,
    $core.Iterable<ArchivePolicyEntry>? entries,
    $core.Iterable<$core.String>? problems,
    $core.Iterable<$core.String>? blockingProblems,
    $core.bool? saved,
    $core.bool? applied,
    $core.bool? pending,
    $core.String? pendingProblem,
    $core.String? invalidation,
    $core.Iterable<$core.String>? changes,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (observedAtUnixMs != null) result.observedAtUnixMs = observedAtUnixMs;
    if (stale != null) result.stale = stale;
    if (entries != null) result.entries.addAll(entries);
    if (problems != null) result.problems.addAll(problems);
    if (blockingProblems != null)
      result.blockingProblems.addAll(blockingProblems);
    if (saved != null) result.saved = saved;
    if (applied != null) result.applied = applied;
    if (pending != null) result.pending = pending;
    if (pendingProblem != null) result.pendingProblem = pendingProblem;
    if (invalidation != null) result.invalidation = invalidation;
    if (changes != null) result.changes.addAll(changes);
    return result;
  }

  ArchivePolicyView._();

  factory ArchivePolicyView.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArchivePolicyView.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArchivePolicyView',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.ProfileDataRef>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: $1.ProfileDataRef.create)
    ..aOS(2, _omitFieldNames ? '' : 'snapshotId')
    ..aInt64(3, _omitFieldNames ? '' : 'observedAtUnixMs')
    ..aOB(4, _omitFieldNames ? '' : 'stale')
    ..pPM<ArchivePolicyEntry>(5, _omitFieldNames ? '' : 'entries',
        subBuilder: ArchivePolicyEntry.create)
    ..pPS(6, _omitFieldNames ? '' : 'problems')
    ..pPS(7, _omitFieldNames ? '' : 'blockingProblems')
    ..aOB(8, _omitFieldNames ? '' : 'saved')
    ..aOB(9, _omitFieldNames ? '' : 'applied')
    ..aOB(10, _omitFieldNames ? '' : 'pending')
    ..aOS(11, _omitFieldNames ? '' : 'pendingProblem')
    ..aOS(12, _omitFieldNames ? '' : 'invalidation')
    ..pPS(13, _omitFieldNames ? '' : 'changes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchivePolicyView clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchivePolicyView copyWith(void Function(ArchivePolicyView) updates) =>
      super.copyWith((message) => updates(message as ArchivePolicyView))
          as ArchivePolicyView;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArchivePolicyView create() => ArchivePolicyView._();
  @$core.override
  ArchivePolicyView createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArchivePolicyView getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArchivePolicyView>(create);
  static ArchivePolicyView? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ProfileDataRef get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($1.ProfileDataRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ProfileDataRef ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get snapshotId => $_getSZ(1);
  @$pb.TagNumber(2)
  set snapshotId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSnapshotId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSnapshotId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get observedAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set observedAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasObservedAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearObservedAtUnixMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get stale => $_getBF(3);
  @$pb.TagNumber(4)
  set stale($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStale() => $_has(3);
  @$pb.TagNumber(4)
  void clearStale() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<ArchivePolicyEntry> get entries => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get problems => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get blockingProblems => $_getList(6);

  @$pb.TagNumber(8)
  $core.bool get saved => $_getBF(7);
  @$pb.TagNumber(8)
  set saved($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSaved() => $_has(7);
  @$pb.TagNumber(8)
  void clearSaved() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get applied => $_getBF(8);
  @$pb.TagNumber(9)
  set applied($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasApplied() => $_has(8);
  @$pb.TagNumber(9)
  void clearApplied() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get pending => $_getBF(9);
  @$pb.TagNumber(10)
  set pending($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPending() => $_has(9);
  @$pb.TagNumber(10)
  void clearPending() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get pendingProblem => $_getSZ(10);
  @$pb.TagNumber(11)
  set pendingProblem($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPendingProblem() => $_has(10);
  @$pb.TagNumber(11)
  void clearPendingProblem() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get invalidation => $_getSZ(11);
  @$pb.TagNumber(12)
  set invalidation($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasInvalidation() => $_has(11);
  @$pb.TagNumber(12)
  void clearInvalidation() => $_clearField(12);

  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get changes => $_getList(12);
}

enum ArchivePolicyReply_Outcome { policy, problem, notSet }

class ArchivePolicyReply extends $pb.GeneratedMessage {
  factory ArchivePolicyReply({
    ArchivePolicyView? policy,
    $1.ProfileDataProblem? problem,
  }) {
    final result = create();
    if (policy != null) result.policy = policy;
    if (problem != null) result.problem = problem;
    return result;
  }

  ArchivePolicyReply._();

  factory ArchivePolicyReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ArchivePolicyReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ArchivePolicyReply_Outcome>
      _ArchivePolicyReply_OutcomeByTag = {
    1: ArchivePolicyReply_Outcome.policy,
    2: ArchivePolicyReply_Outcome.problem,
    0: ArchivePolicyReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ArchivePolicyReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ArchivePolicyView>(1, _omitFieldNames ? '' : 'policy',
        subBuilder: ArchivePolicyView.create)
    ..aOM<$1.ProfileDataProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: $1.ProfileDataProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchivePolicyReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArchivePolicyReply copyWith(void Function(ArchivePolicyReply) updates) =>
      super.copyWith((message) => updates(message as ArchivePolicyReply))
          as ArchivePolicyReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArchivePolicyReply create() => ArchivePolicyReply._();
  @$core.override
  ArchivePolicyReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ArchivePolicyReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ArchivePolicyReply>(create);
  static ArchivePolicyReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ArchivePolicyReply_Outcome whichOutcome() =>
      _ArchivePolicyReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ArchivePolicyView get policy => $_getN(0);
  @$pb.TagNumber(1)
  set policy(ArchivePolicyView value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPolicy() => $_has(0);
  @$pb.TagNumber(1)
  void clearPolicy() => $_clearField(1);
  @$pb.TagNumber(1)
  ArchivePolicyView ensurePolicy() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ProfileDataProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem($1.ProfileDataProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ProfileDataProblem ensureProblem() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
