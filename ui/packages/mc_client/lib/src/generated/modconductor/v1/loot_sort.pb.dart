// This is a generated file - do not edit.
//
// Generated from modconductor/v1/loot_sort.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'loot_sort.pbenum.dart';
import 'profile_data.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'loot_sort.pbenum.dart';

class ReadLootStateRequest extends $pb.GeneratedMessage {
  factory ReadLootStateRequest() => create();

  ReadLootStateRequest._();

  factory ReadLootStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadLootStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadLootStateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadLootStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadLootStateRequest copyWith(void Function(ReadLootStateRequest) updates) =>
      super.copyWith((message) => updates(message as ReadLootStateRequest))
          as ReadLootStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadLootStateRequest create() => ReadLootStateRequest._();
  @$core.override
  ReadLootStateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadLootStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadLootStateRequest>(create);
  static ReadLootStateRequest? _defaultInstance;
}

class PreviewLootSortRequest extends $pb.GeneratedMessage {
  factory PreviewLootSortRequest({
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

  PreviewLootSortRequest._();

  factory PreviewLootSortRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreviewLootSortRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewLootSortRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'headersId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewLootSortRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewLootSortRequest copyWith(
          void Function(PreviewLootSortRequest) updates) =>
      super.copyWith((message) => updates(message as PreviewLootSortRequest))
          as PreviewLootSortRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreviewLootSortRequest create() => PreviewLootSortRequest._();
  @$core.override
  PreviewLootSortRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreviewLootSortRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewLootSortRequest>(create);
  static PreviewLootSortRequest? _defaultInstance;

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

class ApplyLootSortRequest extends $pb.GeneratedMessage {
  factory ApplyLootSortRequest({
    $core.String? proposalId,
    $2.ProfileDataRef? expected,
    $core.String? headersId,
  }) {
    final result = create();
    if (proposalId != null) result.proposalId = proposalId;
    if (expected != null) result.expected = expected;
    if (headersId != null) result.headersId = headersId;
    return result;
  }

  ApplyLootSortRequest._();

  factory ApplyLootSortRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyLootSortRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyLootSortRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'proposalId')
    ..aOM<$2.ProfileDataRef>(2, _omitFieldNames ? '' : 'expected',
        subBuilder: $2.ProfileDataRef.create)
    ..aOS(3, _omitFieldNames ? '' : 'headersId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyLootSortRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyLootSortRequest copyWith(void Function(ApplyLootSortRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyLootSortRequest))
          as ApplyLootSortRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyLootSortRequest create() => ApplyLootSortRequest._();
  @$core.override
  ApplyLootSortRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyLootSortRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyLootSortRequest>(create);
  static ApplyLootSortRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get proposalId => $_getSZ(0);
  @$pb.TagNumber(1)
  set proposalId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProposalId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProposalId() => $_clearField(1);

  @$pb.TagNumber(2)
  $2.ProfileDataRef get expected => $_getN(1);
  @$pb.TagNumber(2)
  set expected($2.ProfileDataRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpected() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpected() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.ProfileDataRef ensureExpected() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get headersId => $_getSZ(2);
  @$pb.TagNumber(3)
  set headersId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeadersId() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeadersId() => $_clearField(3);
}

class DismissLootSortRequest extends $pb.GeneratedMessage {
  factory DismissLootSortRequest({
    $core.String? proposalId,
  }) {
    final result = create();
    if (proposalId != null) result.proposalId = proposalId;
    return result;
  }

  DismissLootSortRequest._();

  factory DismissLootSortRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DismissLootSortRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DismissLootSortRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'proposalId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DismissLootSortRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DismissLootSortRequest copyWith(
          void Function(DismissLootSortRequest) updates) =>
      super.copyWith((message) => updates(message as DismissLootSortRequest))
          as DismissLootSortRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DismissLootSortRequest create() => DismissLootSortRequest._();
  @$core.override
  DismissLootSortRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DismissLootSortRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DismissLootSortRequest>(create);
  static DismissLootSortRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get proposalId => $_getSZ(0);
  @$pb.TagNumber(1)
  set proposalId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProposalId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProposalId() => $_clearField(1);
}

class RefreshLootMetadataRequest extends $pb.GeneratedMessage {
  factory RefreshLootMetadataRequest() => create();

  RefreshLootMetadataRequest._();

  factory RefreshLootMetadataRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshLootMetadataRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshLootMetadataRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshLootMetadataRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshLootMetadataRequest copyWith(
          void Function(RefreshLootMetadataRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RefreshLootMetadataRequest))
          as RefreshLootMetadataRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshLootMetadataRequest create() => RefreshLootMetadataRequest._();
  @$core.override
  RefreshLootMetadataRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshLootMetadataRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshLootMetadataRequest>(create);
  static RefreshLootMetadataRequest? _defaultInstance;
}

class LootMetadataState extends $pb.GeneratedMessage {
  factory LootMetadataState({
    $core.String? revision,
    $core.String? masterlistCommit,
    $core.String? preludeCommit,
    $core.String? masterlistSha256,
    $core.String? preludeSha256,
    $fixnum.Int64? fetchedUnixMs,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (masterlistCommit != null) result.masterlistCommit = masterlistCommit;
    if (preludeCommit != null) result.preludeCommit = preludeCommit;
    if (masterlistSha256 != null) result.masterlistSha256 = masterlistSha256;
    if (preludeSha256 != null) result.preludeSha256 = preludeSha256;
    if (fetchedUnixMs != null) result.fetchedUnixMs = fetchedUnixMs;
    return result;
  }

  LootMetadataState._();

  factory LootMetadataState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LootMetadataState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LootMetadataState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'revision')
    ..aOS(2, _omitFieldNames ? '' : 'masterlistCommit')
    ..aOS(3, _omitFieldNames ? '' : 'preludeCommit')
    ..aOS(4, _omitFieldNames ? '' : 'masterlistSha256')
    ..aOS(5, _omitFieldNames ? '' : 'preludeSha256')
    ..aInt64(6, _omitFieldNames ? '' : 'fetchedUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootMetadataState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootMetadataState copyWith(void Function(LootMetadataState) updates) =>
      super.copyWith((message) => updates(message as LootMetadataState))
          as LootMetadataState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LootMetadataState create() => LootMetadataState._();
  @$core.override
  LootMetadataState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LootMetadataState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LootMetadataState>(create);
  static LootMetadataState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get revision => $_getSZ(0);
  @$pb.TagNumber(1)
  set revision($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get masterlistCommit => $_getSZ(1);
  @$pb.TagNumber(2)
  set masterlistCommit($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMasterlistCommit() => $_has(1);
  @$pb.TagNumber(2)
  void clearMasterlistCommit() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get preludeCommit => $_getSZ(2);
  @$pb.TagNumber(3)
  set preludeCommit($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPreludeCommit() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreludeCommit() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get masterlistSha256 => $_getSZ(3);
  @$pb.TagNumber(4)
  set masterlistSha256($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMasterlistSha256() => $_has(3);
  @$pb.TagNumber(4)
  void clearMasterlistSha256() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get preludeSha256 => $_getSZ(4);
  @$pb.TagNumber(5)
  set preludeSha256($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPreludeSha256() => $_has(4);
  @$pb.TagNumber(5)
  void clearPreludeSha256() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get fetchedUnixMs => $_getI64(5);
  @$pb.TagNumber(6)
  set fetchedUnixMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFetchedUnixMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearFetchedUnixMs() => $_clearField(6);
}

class LootSortMove extends $pb.GeneratedMessage {
  factory LootSortMove({
    $core.String? plugin,
    $core.int? current,
    $core.int? proposed,
    $core.String? reason,
  }) {
    final result = create();
    if (plugin != null) result.plugin = plugin;
    if (current != null) result.current = current;
    if (proposed != null) result.proposed = proposed;
    if (reason != null) result.reason = reason;
    return result;
  }

  LootSortMove._();

  factory LootSortMove.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LootSortMove.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LootSortMove',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'plugin')
    ..aI(2, _omitFieldNames ? '' : 'current')
    ..aI(3, _omitFieldNames ? '' : 'proposed')
    ..aOS(4, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootSortMove clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootSortMove copyWith(void Function(LootSortMove) updates) =>
      super.copyWith((message) => updates(message as LootSortMove))
          as LootSortMove;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LootSortMove create() => LootSortMove._();
  @$core.override
  LootSortMove createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LootSortMove getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LootSortMove>(create);
  static LootSortMove? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get plugin => $_getSZ(0);
  @$pb.TagNumber(1)
  set plugin($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlugin() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlugin() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get current => $_getIZ(1);
  @$pb.TagNumber(2)
  set current($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrent() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrent() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get proposed => $_getIZ(2);
  @$pb.TagNumber(3)
  set proposed($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProposed() => $_has(2);
  @$pb.TagNumber(3)
  void clearProposed() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get reason => $_getSZ(3);
  @$pb.TagNumber(4)
  set reason($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearReason() => $_clearField(4);
}

class LootSortMessage extends $pb.GeneratedMessage {
  factory LootSortMessage({
    $core.String? plugin,
    $core.String? level,
    $core.String? text,
  }) {
    final result = create();
    if (plugin != null) result.plugin = plugin;
    if (level != null) result.level = level;
    if (text != null) result.text = text;
    return result;
  }

  LootSortMessage._();

  factory LootSortMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LootSortMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LootSortMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'plugin')
    ..aOS(2, _omitFieldNames ? '' : 'level')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootSortMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootSortMessage copyWith(void Function(LootSortMessage) updates) =>
      super.copyWith((message) => updates(message as LootSortMessage))
          as LootSortMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LootSortMessage create() => LootSortMessage._();
  @$core.override
  LootSortMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LootSortMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LootSortMessage>(create);
  static LootSortMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get plugin => $_getSZ(0);
  @$pb.TagNumber(1)
  set plugin($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlugin() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlugin() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get level => $_getSZ(1);
  @$pb.TagNumber(2)
  set level($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLevel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);
}

class LootSortProposal extends $pb.GeneratedMessage {
  factory LootSortProposal({
    $core.String? id,
    $2.ProfileDataRef? expected,
    $core.String? headersId,
    $fixnum.Int64? createdUnixMs,
    $core.Iterable<$core.String>? current,
    $core.Iterable<$core.String>? sorted,
    $core.Iterable<LootSortMove>? moves,
    $core.Iterable<LootSortMessage>? messages,
    LootMetadataState? metadata,
    $core.String? helperVersion,
    $core.String? liblootVersion,
    $core.String? liblootRevision,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (expected != null) result.expected = expected;
    if (headersId != null) result.headersId = headersId;
    if (createdUnixMs != null) result.createdUnixMs = createdUnixMs;
    if (current != null) result.current.addAll(current);
    if (sorted != null) result.sorted.addAll(sorted);
    if (moves != null) result.moves.addAll(moves);
    if (messages != null) result.messages.addAll(messages);
    if (metadata != null) result.metadata = metadata;
    if (helperVersion != null) result.helperVersion = helperVersion;
    if (liblootVersion != null) result.liblootVersion = liblootVersion;
    if (liblootRevision != null) result.liblootRevision = liblootRevision;
    return result;
  }

  LootSortProposal._();

  factory LootSortProposal.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LootSortProposal.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LootSortProposal',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<$2.ProfileDataRef>(2, _omitFieldNames ? '' : 'expected',
        subBuilder: $2.ProfileDataRef.create)
    ..aOS(3, _omitFieldNames ? '' : 'headersId')
    ..aInt64(4, _omitFieldNames ? '' : 'createdUnixMs')
    ..pPS(5, _omitFieldNames ? '' : 'current')
    ..pPS(6, _omitFieldNames ? '' : 'sorted')
    ..pPM<LootSortMove>(7, _omitFieldNames ? '' : 'moves',
        subBuilder: LootSortMove.create)
    ..pPM<LootSortMessage>(8, _omitFieldNames ? '' : 'messages',
        subBuilder: LootSortMessage.create)
    ..aOM<LootMetadataState>(9, _omitFieldNames ? '' : 'metadata',
        subBuilder: LootMetadataState.create)
    ..aOS(10, _omitFieldNames ? '' : 'helperVersion')
    ..aOS(11, _omitFieldNames ? '' : 'liblootVersion')
    ..aOS(12, _omitFieldNames ? '' : 'liblootRevision')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootSortProposal clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootSortProposal copyWith(void Function(LootSortProposal) updates) =>
      super.copyWith((message) => updates(message as LootSortProposal))
          as LootSortProposal;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LootSortProposal create() => LootSortProposal._();
  @$core.override
  LootSortProposal createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LootSortProposal getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LootSortProposal>(create);
  static LootSortProposal? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $2.ProfileDataRef get expected => $_getN(1);
  @$pb.TagNumber(2)
  set expected($2.ProfileDataRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpected() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpected() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.ProfileDataRef ensureExpected() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get headersId => $_getSZ(2);
  @$pb.TagNumber(3)
  set headersId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeadersId() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeadersId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get createdUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set createdUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedUnixMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get current => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get sorted => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<LootSortMove> get moves => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<LootSortMessage> get messages => $_getList(7);

  @$pb.TagNumber(9)
  LootMetadataState get metadata => $_getN(8);
  @$pb.TagNumber(9)
  set metadata(LootMetadataState value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasMetadata() => $_has(8);
  @$pb.TagNumber(9)
  void clearMetadata() => $_clearField(9);
  @$pb.TagNumber(9)
  LootMetadataState ensureMetadata() => $_ensure(8);

  @$pb.TagNumber(10)
  $core.String get helperVersion => $_getSZ(9);
  @$pb.TagNumber(10)
  set helperVersion($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasHelperVersion() => $_has(9);
  @$pb.TagNumber(10)
  void clearHelperVersion() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get liblootVersion => $_getSZ(10);
  @$pb.TagNumber(11)
  set liblootVersion($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLiblootVersion() => $_has(10);
  @$pb.TagNumber(11)
  void clearLiblootVersion() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get liblootRevision => $_getSZ(11);
  @$pb.TagNumber(12)
  set liblootRevision($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasLiblootRevision() => $_has(11);
  @$pb.TagNumber(12)
  void clearLiblootRevision() => $_clearField(12);
}

class LootState extends $pb.GeneratedMessage {
  factory LootState({
    $core.String? capabilityId,
    $core.bool? available,
    $core.String? reason,
    LootMetadataState? metadata,
    LootSortProposal? proposal,
  }) {
    final result = create();
    if (capabilityId != null) result.capabilityId = capabilityId;
    if (available != null) result.available = available;
    if (reason != null) result.reason = reason;
    if (metadata != null) result.metadata = metadata;
    if (proposal != null) result.proposal = proposal;
    return result;
  }

  LootState._();

  factory LootState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LootState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LootState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'capabilityId')
    ..aOB(2, _omitFieldNames ? '' : 'available')
    ..aOS(3, _omitFieldNames ? '' : 'reason')
    ..aOM<LootMetadataState>(4, _omitFieldNames ? '' : 'metadata',
        subBuilder: LootMetadataState.create)
    ..aOM<LootSortProposal>(5, _omitFieldNames ? '' : 'proposal',
        subBuilder: LootSortProposal.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootState copyWith(void Function(LootState) updates) =>
      super.copyWith((message) => updates(message as LootState)) as LootState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LootState create() => LootState._();
  @$core.override
  LootState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LootState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LootState>(create);
  static LootState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get capabilityId => $_getSZ(0);
  @$pb.TagNumber(1)
  set capabilityId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCapabilityId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCapabilityId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get available => $_getBF(1);
  @$pb.TagNumber(2)
  set available($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAvailable() => $_has(1);
  @$pb.TagNumber(2)
  void clearAvailable() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get reason => $_getSZ(2);
  @$pb.TagNumber(3)
  set reason($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => $_clearField(3);

  @$pb.TagNumber(4)
  LootMetadataState get metadata => $_getN(3);
  @$pb.TagNumber(4)
  set metadata(LootMetadataState value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMetadata() => $_has(3);
  @$pb.TagNumber(4)
  void clearMetadata() => $_clearField(4);
  @$pb.TagNumber(4)
  LootMetadataState ensureMetadata() => $_ensure(3);

  @$pb.TagNumber(5)
  LootSortProposal get proposal => $_getN(4);
  @$pb.TagNumber(5)
  set proposal(LootSortProposal value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasProposal() => $_has(4);
  @$pb.TagNumber(5)
  void clearProposal() => $_clearField(5);
  @$pb.TagNumber(5)
  LootSortProposal ensureProposal() => $_ensure(4);
}

class LootProblem extends $pb.GeneratedMessage {
  factory LootProblem({
    LootProblemKind? kind,
    $core.String? detail,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (detail != null) result.detail = detail;
    return result;
  }

  LootProblem._();

  factory LootProblem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LootProblem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LootProblem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<LootProblemKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: LootProblemKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootProblem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootProblem copyWith(void Function(LootProblem) updates) =>
      super.copyWith((message) => updates(message as LootProblem))
          as LootProblem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LootProblem create() => LootProblem._();
  @$core.override
  LootProblem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LootProblem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LootProblem>(create);
  static LootProblem? _defaultInstance;

  @$pb.TagNumber(1)
  LootProblemKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(LootProblemKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get detail => $_getSZ(1);
  @$pb.TagNumber(2)
  set detail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDetail() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetail() => $_clearField(2);
}

enum LootStateReply_Outcome { state, problem, notSet }

class LootStateReply extends $pb.GeneratedMessage {
  factory LootStateReply({
    LootState? state,
    LootProblem? problem,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (problem != null) result.problem = problem;
    return result;
  }

  LootStateReply._();

  factory LootStateReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LootStateReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, LootStateReply_Outcome>
      _LootStateReply_OutcomeByTag = {
    1: LootStateReply_Outcome.state,
    2: LootStateReply_Outcome.problem,
    0: LootStateReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LootStateReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<LootState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: LootState.create)
    ..aOM<LootProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: LootProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootStateReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LootStateReply copyWith(void Function(LootStateReply) updates) =>
      super.copyWith((message) => updates(message as LootStateReply))
          as LootStateReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LootStateReply create() => LootStateReply._();
  @$core.override
  LootStateReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LootStateReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LootStateReply>(create);
  static LootStateReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  LootStateReply_Outcome whichOutcome() =>
      _LootStateReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  LootState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(LootState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  LootState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  LootProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem(LootProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  LootProblem ensureProblem() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
