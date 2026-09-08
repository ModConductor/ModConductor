// This is a generated file - do not edit.
//
// Generated from modconductor/v1/deployments.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'deployments.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'deployments.pbenum.dart';

class ReadDeploymentRequest extends $pb.GeneratedMessage {
  factory ReadDeploymentRequest({
    $core.String? profileId,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  ReadDeploymentRequest._();

  factory ReadDeploymentRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadDeploymentRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadDeploymentRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadDeploymentRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadDeploymentRequest copyWith(
          void Function(ReadDeploymentRequest) updates) =>
      super.copyWith((message) => updates(message as ReadDeploymentRequest))
          as ReadDeploymentRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadDeploymentRequest create() => ReadDeploymentRequest._();
  @$core.override
  ReadDeploymentRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadDeploymentRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadDeploymentRequest>(create);
  static ReadDeploymentRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);
}

class DeploymentProfile extends $pb.GeneratedMessage {
  factory DeploymentProfile({
    $core.String? id,
    $core.String? name,
    $fixnum.Int64? revision,
    $core.int? enabledMods,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (revision != null) result.revision = revision;
    if (enabledMods != null) result.enabledMods = enabledMods;
    return result;
  }

  DeploymentProfile._();

  factory DeploymentProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeploymentProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeploymentProfile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(4, _omitFieldNames ? '' : 'enabledMods',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentProfile copyWith(void Function(DeploymentProfile) updates) =>
      super.copyWith((message) => updates(message as DeploymentProfile))
          as DeploymentProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeploymentProfile create() => DeploymentProfile._();
  @$core.override
  DeploymentProfile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeploymentProfile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeploymentProfile>(create);
  static DeploymentProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get revision => $_getI64(2);
  @$pb.TagNumber(3)
  set revision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get enabledMods => $_getIZ(3);
  @$pb.TagNumber(4)
  set enabledMods($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnabledMods() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnabledMods() => $_clearField(4);
}

class SavedDeployment extends $pb.GeneratedMessage {
  factory SavedDeployment({
    $core.String? id,
    $fixnum.Int64? preparedAtUnixMs,
    DeploymentProfile? profile,
    $core.bool? known,
    $core.bool? active,
    $core.String? fingerprint,
    $core.bool? canRestore,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (preparedAtUnixMs != null) result.preparedAtUnixMs = preparedAtUnixMs;
    if (profile != null) result.profile = profile;
    if (known != null) result.known = known;
    if (active != null) result.active = active;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (canRestore != null) result.canRestore = canRestore;
    return result;
  }

  SavedDeployment._();

  factory SavedDeployment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SavedDeployment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SavedDeployment',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'preparedAtUnixMs')
    ..aOM<DeploymentProfile>(3, _omitFieldNames ? '' : 'profile',
        subBuilder: DeploymentProfile.create)
    ..aOB(4, _omitFieldNames ? '' : 'known')
    ..aOB(5, _omitFieldNames ? '' : 'active')
    ..aOS(6, _omitFieldNames ? '' : 'fingerprint')
    ..aOB(7, _omitFieldNames ? '' : 'canRestore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavedDeployment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavedDeployment copyWith(void Function(SavedDeployment) updates) =>
      super.copyWith((message) => updates(message as SavedDeployment))
          as SavedDeployment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SavedDeployment create() => SavedDeployment._();
  @$core.override
  SavedDeployment createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SavedDeployment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SavedDeployment>(create);
  static SavedDeployment? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get preparedAtUnixMs => $_getI64(1);
  @$pb.TagNumber(2)
  set preparedAtUnixMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPreparedAtUnixMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreparedAtUnixMs() => $_clearField(2);

  @$pb.TagNumber(3)
  DeploymentProfile get profile => $_getN(2);
  @$pb.TagNumber(3)
  set profile(DeploymentProfile value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProfile() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfile() => $_clearField(3);
  @$pb.TagNumber(3)
  DeploymentProfile ensureProfile() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get known => $_getBF(3);
  @$pb.TagNumber(4)
  set known($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasKnown() => $_has(3);
  @$pb.TagNumber(4)
  void clearKnown() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get active => $_getBF(4);
  @$pb.TagNumber(5)
  set active($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasActive() => $_has(4);
  @$pb.TagNumber(5)
  void clearActive() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get fingerprint => $_getSZ(5);
  @$pb.TagNumber(6)
  set fingerprint($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFingerprint() => $_has(5);
  @$pb.TagNumber(6)
  void clearFingerprint() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get canRestore => $_getBF(6);
  @$pb.TagNumber(7)
  set canRestore($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCanRestore() => $_has(6);
  @$pb.TagNumber(7)
  void clearCanRestore() => $_clearField(7);
}

class DeploymentState extends $pb.GeneratedMessage {
  factory DeploymentState({
    $core.String? workspaceId,
    $fixnum.Int64? revision,
    SavedDeployment? active,
    $core.String? pendingReceipt,
    $core.String? sourceToken,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (revision != null) result.revision = revision;
    if (active != null) result.active = active;
    if (pendingReceipt != null) result.pendingReceipt = pendingReceipt;
    if (sourceToken != null) result.sourceToken = sourceToken;
    return result;
  }

  DeploymentState._();

  factory DeploymentState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeploymentState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeploymentState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<SavedDeployment>(3, _omitFieldNames ? '' : 'active',
        subBuilder: SavedDeployment.create)
    ..aOS(4, _omitFieldNames ? '' : 'pendingReceipt')
    ..aOS(5, _omitFieldNames ? '' : 'sourceToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentState copyWith(void Function(DeploymentState) updates) =>
      super.copyWith((message) => updates(message as DeploymentState))
          as DeploymentState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeploymentState create() => DeploymentState._();
  @$core.override
  DeploymentState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeploymentState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeploymentState>(create);
  static DeploymentState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revision => $_getI64(1);
  @$pb.TagNumber(2)
  set revision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  SavedDeployment get active => $_getN(2);
  @$pb.TagNumber(3)
  set active(SavedDeployment value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasActive() => $_has(2);
  @$pb.TagNumber(3)
  void clearActive() => $_clearField(3);
  @$pb.TagNumber(3)
  SavedDeployment ensureActive() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get pendingReceipt => $_getSZ(3);
  @$pb.TagNumber(4)
  set pendingReceipt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPendingReceipt() => $_has(3);
  @$pb.TagNumber(4)
  void clearPendingReceipt() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get sourceToken => $_getSZ(4);
  @$pb.TagNumber(5)
  set sourceToken($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSourceToken() => $_has(4);
  @$pb.TagNumber(5)
  void clearSourceToken() => $_clearField(5);
}

class SavedDeploymentsRequest extends $pb.GeneratedMessage {
  factory SavedDeploymentsRequest({
    $core.String? profileId,
    $fixnum.Int64? before,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (before != null) result.before = before;
    return result;
  }

  SavedDeploymentsRequest._();

  factory SavedDeploymentsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SavedDeploymentsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SavedDeploymentsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'before', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavedDeploymentsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavedDeploymentsRequest copyWith(
          void Function(SavedDeploymentsRequest) updates) =>
      super.copyWith((message) => updates(message as SavedDeploymentsRequest))
          as SavedDeploymentsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SavedDeploymentsRequest create() => SavedDeploymentsRequest._();
  @$core.override
  SavedDeploymentsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SavedDeploymentsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SavedDeploymentsRequest>(create);
  static SavedDeploymentsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get before => $_getI64(1);
  @$pb.TagNumber(2)
  set before($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBefore() => $_has(1);
  @$pb.TagNumber(2)
  void clearBefore() => $_clearField(2);
}

class SavedDeploymentsPage extends $pb.GeneratedMessage {
  factory SavedDeploymentsPage({
    $core.Iterable<SavedDeployment>? entries,
    $fixnum.Int64? nextBefore,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (nextBefore != null) result.nextBefore = nextBefore;
    return result;
  }

  SavedDeploymentsPage._();

  factory SavedDeploymentsPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SavedDeploymentsPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SavedDeploymentsPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<SavedDeployment>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: SavedDeployment.create)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'nextBefore', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavedDeploymentsPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavedDeploymentsPage copyWith(void Function(SavedDeploymentsPage) updates) =>
      super.copyWith((message) => updates(message as SavedDeploymentsPage))
          as SavedDeploymentsPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SavedDeploymentsPage create() => SavedDeploymentsPage._();
  @$core.override
  SavedDeploymentsPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SavedDeploymentsPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SavedDeploymentsPage>(create);
  static SavedDeploymentsPage? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SavedDeployment> get entries => $_getList(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get nextBefore => $_getI64(1);
  @$pb.TagNumber(2)
  set nextBefore($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextBefore() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextBefore() => $_clearField(2);
}

class PrepareDeploymentRequest extends $pb.GeneratedMessage {
  factory PrepareDeploymentRequest({
    $core.String? id,
    $core.String? profileId,
    $core.String? sourceToken,
    $core.bool? retained,
    $core.String? generationId,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (profileId != null) result.profileId = profileId;
    if (sourceToken != null) result.sourceToken = sourceToken;
    if (retained != null) result.retained = retained;
    if (generationId != null) result.generationId = generationId;
    return result;
  }

  PrepareDeploymentRequest._();

  factory PrepareDeploymentRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrepareDeploymentRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrepareDeploymentRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'sourceToken')
    ..aOB(4, _omitFieldNames ? '' : 'retained')
    ..aOS(5, _omitFieldNames ? '' : 'generationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareDeploymentRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareDeploymentRequest copyWith(
          void Function(PrepareDeploymentRequest) updates) =>
      super.copyWith((message) => updates(message as PrepareDeploymentRequest))
          as PrepareDeploymentRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrepareDeploymentRequest create() => PrepareDeploymentRequest._();
  @$core.override
  PrepareDeploymentRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PrepareDeploymentRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrepareDeploymentRequest>(create);
  static PrepareDeploymentRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get profileId => $_getSZ(1);
  @$pb.TagNumber(2)
  set profileId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProfileId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProfileId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sourceToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set sourceToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSourceToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearSourceToken() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get retained => $_getBF(3);
  @$pb.TagNumber(4)
  set retained($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRetained() => $_has(3);
  @$pb.TagNumber(4)
  void clearRetained() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get generationId => $_getSZ(4);
  @$pb.TagNumber(5)
  set generationId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGenerationId() => $_has(4);
  @$pb.TagNumber(5)
  void clearGenerationId() => $_clearField(5);
}

class PreparedDeployment extends $pb.GeneratedMessage {
  factory PreparedDeployment({
    $core.String? id,
    $core.String? workspaceId,
    $core.String? fingerprint,
    $core.String? sourceToken,
    DeploymentProfile? profile,
    $core.int? writableFiles,
    $core.int? changedPaths,
    $core.int? preservedOriginals,
    $core.int? managedLinks,
    $fixnum.Int64? copiedBytes,
    $fixnum.Int64? requiredBytes,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (sourceToken != null) result.sourceToken = sourceToken;
    if (profile != null) result.profile = profile;
    if (writableFiles != null) result.writableFiles = writableFiles;
    if (changedPaths != null) result.changedPaths = changedPaths;
    if (preservedOriginals != null)
      result.preservedOriginals = preservedOriginals;
    if (managedLinks != null) result.managedLinks = managedLinks;
    if (copiedBytes != null) result.copiedBytes = copiedBytes;
    if (requiredBytes != null) result.requiredBytes = requiredBytes;
    return result;
  }

  PreparedDeployment._();

  factory PreparedDeployment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreparedDeployment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreparedDeployment',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'fingerprint')
    ..aOS(4, _omitFieldNames ? '' : 'sourceToken')
    ..aOM<DeploymentProfile>(5, _omitFieldNames ? '' : 'profile',
        subBuilder: DeploymentProfile.create)
    ..aI(6, _omitFieldNames ? '' : 'writableFiles',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'changedPaths',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'preservedOriginals',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(9, _omitFieldNames ? '' : 'managedLinks',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        10, _omitFieldNames ? '' : 'copiedBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'requiredBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparedDeployment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparedDeployment copyWith(void Function(PreparedDeployment) updates) =>
      super.copyWith((message) => updates(message as PreparedDeployment))
          as PreparedDeployment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreparedDeployment create() => PreparedDeployment._();
  @$core.override
  PreparedDeployment createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreparedDeployment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreparedDeployment>(create);
  static PreparedDeployment? _defaultInstance;

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
  $core.String get fingerprint => $_getSZ(2);
  @$pb.TagNumber(3)
  set fingerprint($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFingerprint() => $_has(2);
  @$pb.TagNumber(3)
  void clearFingerprint() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sourceToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set sourceToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSourceToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearSourceToken() => $_clearField(4);

  @$pb.TagNumber(5)
  DeploymentProfile get profile => $_getN(4);
  @$pb.TagNumber(5)
  set profile(DeploymentProfile value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasProfile() => $_has(4);
  @$pb.TagNumber(5)
  void clearProfile() => $_clearField(5);
  @$pb.TagNumber(5)
  DeploymentProfile ensureProfile() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.int get writableFiles => $_getIZ(5);
  @$pb.TagNumber(6)
  set writableFiles($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWritableFiles() => $_has(5);
  @$pb.TagNumber(6)
  void clearWritableFiles() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get changedPaths => $_getIZ(6);
  @$pb.TagNumber(7)
  set changedPaths($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasChangedPaths() => $_has(6);
  @$pb.TagNumber(7)
  void clearChangedPaths() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get preservedOriginals => $_getIZ(7);
  @$pb.TagNumber(8)
  set preservedOriginals($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPreservedOriginals() => $_has(7);
  @$pb.TagNumber(8)
  void clearPreservedOriginals() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get managedLinks => $_getIZ(8);
  @$pb.TagNumber(9)
  set managedLinks($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasManagedLinks() => $_has(8);
  @$pb.TagNumber(9)
  void clearManagedLinks() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get copiedBytes => $_getI64(9);
  @$pb.TagNumber(10)
  set copiedBytes($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCopiedBytes() => $_has(9);
  @$pb.TagNumber(10)
  void clearCopiedBytes() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get requiredBytes => $_getI64(10);
  @$pb.TagNumber(11)
  set requiredBytes($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasRequiredBytes() => $_has(10);
  @$pb.TagNumber(11)
  void clearRequiredBytes() => $_clearField(11);
}

class ActivateDeploymentRequest extends $pb.GeneratedMessage {
  factory ActivateDeploymentRequest({
    $core.String? preparedId,
    $core.String? profileId,
    $core.String? sourceToken,
  }) {
    final result = create();
    if (preparedId != null) result.preparedId = preparedId;
    if (profileId != null) result.profileId = profileId;
    if (sourceToken != null) result.sourceToken = sourceToken;
    return result;
  }

  ActivateDeploymentRequest._();

  factory ActivateDeploymentRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ActivateDeploymentRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActivateDeploymentRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'preparedId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'sourceToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivateDeploymentRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivateDeploymentRequest copyWith(
          void Function(ActivateDeploymentRequest) updates) =>
      super.copyWith((message) => updates(message as ActivateDeploymentRequest))
          as ActivateDeploymentRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActivateDeploymentRequest create() => ActivateDeploymentRequest._();
  @$core.override
  ActivateDeploymentRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ActivateDeploymentRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActivateDeploymentRequest>(create);
  static ActivateDeploymentRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get preparedId => $_getSZ(0);
  @$pb.TagNumber(1)
  set preparedId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPreparedId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreparedId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get profileId => $_getSZ(1);
  @$pb.TagNumber(2)
  set profileId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProfileId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProfileId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sourceToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set sourceToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSourceToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearSourceToken() => $_clearField(3);
}

class RecoverDeploymentRequest extends $pb.GeneratedMessage {
  factory RecoverDeploymentRequest({
    $core.String? receiptId,
    $fixnum.Int64? revision,
    $core.bool? restore,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    if (revision != null) result.revision = revision;
    if (restore != null) result.restore = restore;
    return result;
  }

  RecoverDeploymentRequest._();

  factory RecoverDeploymentRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RecoverDeploymentRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecoverDeploymentRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'receiptId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(3, _omitFieldNames ? '' : 'restore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecoverDeploymentRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecoverDeploymentRequest copyWith(
          void Function(RecoverDeploymentRequest) updates) =>
      super.copyWith((message) => updates(message as RecoverDeploymentRequest))
          as RecoverDeploymentRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecoverDeploymentRequest create() => RecoverDeploymentRequest._();
  @$core.override
  RecoverDeploymentRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RecoverDeploymentRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecoverDeploymentRequest>(create);
  static RecoverDeploymentRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get receiptId => $_getSZ(0);
  @$pb.TagNumber(1)
  set receiptId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revision => $_getI64(1);
  @$pb.TagNumber(2)
  set revision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get restore => $_getBF(2);
  @$pb.TagNumber(3)
  set restore($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRestore() => $_has(2);
  @$pb.TagNumber(3)
  void clearRestore() => $_clearField(3);
}

class DeploymentReceiptRequest extends $pb.GeneratedMessage {
  factory DeploymentReceiptRequest({
    $core.String? receiptId,
  }) {
    final result = create();
    if (receiptId != null) result.receiptId = receiptId;
    return result;
  }

  DeploymentReceiptRequest._();

  factory DeploymentReceiptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeploymentReceiptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeploymentReceiptRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'receiptId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentReceiptRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentReceiptRequest copyWith(
          void Function(DeploymentReceiptRequest) updates) =>
      super.copyWith((message) => updates(message as DeploymentReceiptRequest))
          as DeploymentReceiptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeploymentReceiptRequest create() => DeploymentReceiptRequest._();
  @$core.override
  DeploymentReceiptRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeploymentReceiptRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeploymentReceiptRequest>(create);
  static DeploymentReceiptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get receiptId => $_getSZ(0);
  @$pb.TagNumber(1)
  set receiptId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptId() => $_clearField(1);
}

class DeploymentReceipt extends $pb.GeneratedMessage {
  factory DeploymentReceipt({
    $core.String? id,
    $core.String? workspaceId,
    $fixnum.Int64? revision,
    DeploymentPhase? phase,
    $core.String? previous,
    $core.String? proposed,
    $core.int? completed,
    $core.int? total,
    $core.String? detail,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (revision != null) result.revision = revision;
    if (phase != null) result.phase = phase;
    if (previous != null) result.previous = previous;
    if (proposed != null) result.proposed = proposed;
    if (completed != null) result.completed = completed;
    if (total != null) result.total = total;
    if (detail != null) result.detail = detail;
    return result;
  }

  DeploymentReceipt._();

  factory DeploymentReceipt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeploymentReceipt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeploymentReceipt',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<DeploymentPhase>(4, _omitFieldNames ? '' : 'phase',
        enumValues: DeploymentPhase.values)
    ..aOS(5, _omitFieldNames ? '' : 'previous')
    ..aOS(6, _omitFieldNames ? '' : 'proposed')
    ..aI(7, _omitFieldNames ? '' : 'completed', fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'total', fieldType: $pb.PbFieldType.OU3)
    ..aOS(9, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentReceipt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentReceipt copyWith(void Function(DeploymentReceipt) updates) =>
      super.copyWith((message) => updates(message as DeploymentReceipt))
          as DeploymentReceipt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeploymentReceipt create() => DeploymentReceipt._();
  @$core.override
  DeploymentReceipt createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeploymentReceipt getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeploymentReceipt>(create);
  static DeploymentReceipt? _defaultInstance;

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
  $fixnum.Int64 get revision => $_getI64(2);
  @$pb.TagNumber(3)
  set revision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  DeploymentPhase get phase => $_getN(3);
  @$pb.TagNumber(4)
  set phase(DeploymentPhase value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPhase() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhase() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get previous => $_getSZ(4);
  @$pb.TagNumber(5)
  set previous($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPrevious() => $_has(4);
  @$pb.TagNumber(5)
  void clearPrevious() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get proposed => $_getSZ(5);
  @$pb.TagNumber(6)
  set proposed($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProposed() => $_has(5);
  @$pb.TagNumber(6)
  void clearProposed() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get completed => $_getIZ(6);
  @$pb.TagNumber(7)
  set completed($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCompleted() => $_has(6);
  @$pb.TagNumber(7)
  void clearCompleted() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get total => $_getIZ(7);
  @$pb.TagNumber(8)
  set total($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTotal() => $_has(7);
  @$pb.TagNumber(8)
  void clearTotal() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get detail => $_getSZ(8);
  @$pb.TagNumber(9)
  set detail($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDetail() => $_has(8);
  @$pb.TagNumber(9)
  void clearDetail() => $_clearField(9);
}

class DeploymentProgress extends $pb.GeneratedMessage {
  factory DeploymentProgress({
    DeploymentPhase? phase,
    $core.int? completed,
    $core.int? total,
    $fixnum.Int64? bytes,
  }) {
    final result = create();
    if (phase != null) result.phase = phase;
    if (completed != null) result.completed = completed;
    if (total != null) result.total = total;
    if (bytes != null) result.bytes = bytes;
    return result;
  }

  DeploymentProgress._();

  factory DeploymentProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeploymentProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeploymentProgress',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<DeploymentPhase>(1, _omitFieldNames ? '' : 'phase',
        enumValues: DeploymentPhase.values)
    ..aI(2, _omitFieldNames ? '' : 'completed', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'total', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentProgress copyWith(void Function(DeploymentProgress) updates) =>
      super.copyWith((message) => updates(message as DeploymentProgress))
          as DeploymentProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeploymentProgress create() => DeploymentProgress._();
  @$core.override
  DeploymentProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeploymentProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeploymentProgress>(create);
  static DeploymentProgress? _defaultInstance;

  @$pb.TagNumber(1)
  DeploymentPhase get phase => $_getN(0);
  @$pb.TagNumber(1)
  set phase(DeploymentPhase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPhase() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhase() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get completed => $_getIZ(1);
  @$pb.TagNumber(2)
  set completed($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCompleted() => $_has(1);
  @$pb.TagNumber(2)
  void clearCompleted() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get total => $_getIZ(2);
  @$pb.TagNumber(3)
  set total($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get bytes => $_getI64(3);
  @$pb.TagNumber(4)
  set bytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearBytes() => $_clearField(4);
}

class DeploymentFault extends $pb.GeneratedMessage {
  factory DeploymentFault({
    DeploymentFaultCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  DeploymentFault._();

  factory DeploymentFault.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeploymentFault.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeploymentFault',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<DeploymentFaultCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: DeploymentFaultCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentFault clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentFault copyWith(void Function(DeploymentFault) updates) =>
      super.copyWith((message) => updates(message as DeploymentFault))
          as DeploymentFault;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeploymentFault create() => DeploymentFault._();
  @$core.override
  DeploymentFault createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeploymentFault getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeploymentFault>(create);
  static DeploymentFault? _defaultInstance;

  @$pb.TagNumber(1)
  DeploymentFaultCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(DeploymentFaultCode value) => $_setField(1, value);
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

enum DeploymentStateReply_Outcome { state, fault, notSet }

class DeploymentStateReply extends $pb.GeneratedMessage {
  factory DeploymentStateReply({
    DeploymentState? state,
    DeploymentFault? fault,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (fault != null) result.fault = fault;
    return result;
  }

  DeploymentStateReply._();

  factory DeploymentStateReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeploymentStateReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DeploymentStateReply_Outcome>
      _DeploymentStateReply_OutcomeByTag = {
    1: DeploymentStateReply_Outcome.state,
    2: DeploymentStateReply_Outcome.fault,
    0: DeploymentStateReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeploymentStateReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DeploymentState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: DeploymentState.create)
    ..aOM<DeploymentFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: DeploymentFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentStateReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentStateReply copyWith(void Function(DeploymentStateReply) updates) =>
      super.copyWith((message) => updates(message as DeploymentStateReply))
          as DeploymentStateReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeploymentStateReply create() => DeploymentStateReply._();
  @$core.override
  DeploymentStateReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeploymentStateReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeploymentStateReply>(create);
  static DeploymentStateReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DeploymentStateReply_Outcome whichOutcome() =>
      _DeploymentStateReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DeploymentState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(DeploymentState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  DeploymentState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  DeploymentFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(DeploymentFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  DeploymentFault ensureFault() => $_ensure(1);
}

enum SavedDeploymentsReply_Outcome { page, fault, notSet }

class SavedDeploymentsReply extends $pb.GeneratedMessage {
  factory SavedDeploymentsReply({
    SavedDeploymentsPage? page,
    DeploymentFault? fault,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (fault != null) result.fault = fault;
    return result;
  }

  SavedDeploymentsReply._();

  factory SavedDeploymentsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SavedDeploymentsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SavedDeploymentsReply_Outcome>
      _SavedDeploymentsReply_OutcomeByTag = {
    1: SavedDeploymentsReply_Outcome.page,
    2: SavedDeploymentsReply_Outcome.fault,
    0: SavedDeploymentsReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SavedDeploymentsReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<SavedDeploymentsPage>(1, _omitFieldNames ? '' : 'page',
        subBuilder: SavedDeploymentsPage.create)
    ..aOM<DeploymentFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: DeploymentFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavedDeploymentsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavedDeploymentsReply copyWith(
          void Function(SavedDeploymentsReply) updates) =>
      super.copyWith((message) => updates(message as SavedDeploymentsReply))
          as SavedDeploymentsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SavedDeploymentsReply create() => SavedDeploymentsReply._();
  @$core.override
  SavedDeploymentsReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SavedDeploymentsReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SavedDeploymentsReply>(create);
  static SavedDeploymentsReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  SavedDeploymentsReply_Outcome whichOutcome() =>
      _SavedDeploymentsReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SavedDeploymentsPage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(SavedDeploymentsPage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  SavedDeploymentsPage ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  DeploymentFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(DeploymentFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  DeploymentFault ensureFault() => $_ensure(1);
}

enum PreparedDeploymentReply_Outcome { prepared, fault, notSet }

class PreparedDeploymentReply extends $pb.GeneratedMessage {
  factory PreparedDeploymentReply({
    PreparedDeployment? prepared,
    DeploymentFault? fault,
  }) {
    final result = create();
    if (prepared != null) result.prepared = prepared;
    if (fault != null) result.fault = fault;
    return result;
  }

  PreparedDeploymentReply._();

  factory PreparedDeploymentReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreparedDeploymentReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PreparedDeploymentReply_Outcome>
      _PreparedDeploymentReply_OutcomeByTag = {
    1: PreparedDeploymentReply_Outcome.prepared,
    2: PreparedDeploymentReply_Outcome.fault,
    0: PreparedDeploymentReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreparedDeploymentReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<PreparedDeployment>(1, _omitFieldNames ? '' : 'prepared',
        subBuilder: PreparedDeployment.create)
    ..aOM<DeploymentFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: DeploymentFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparedDeploymentReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparedDeploymentReply copyWith(
          void Function(PreparedDeploymentReply) updates) =>
      super.copyWith((message) => updates(message as PreparedDeploymentReply))
          as PreparedDeploymentReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreparedDeploymentReply create() => PreparedDeploymentReply._();
  @$core.override
  PreparedDeploymentReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreparedDeploymentReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreparedDeploymentReply>(create);
  static PreparedDeploymentReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  PreparedDeploymentReply_Outcome whichOutcome() =>
      _PreparedDeploymentReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  PreparedDeployment get prepared => $_getN(0);
  @$pb.TagNumber(1)
  set prepared(PreparedDeployment value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPrepared() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrepared() => $_clearField(1);
  @$pb.TagNumber(1)
  PreparedDeployment ensurePrepared() => $_ensure(0);

  @$pb.TagNumber(2)
  DeploymentFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(DeploymentFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  DeploymentFault ensureFault() => $_ensure(1);
}

enum DeploymentReceiptReply_Outcome { receipt, fault, notSet }

class DeploymentReceiptReply extends $pb.GeneratedMessage {
  factory DeploymentReceiptReply({
    DeploymentReceipt? receipt,
    DeploymentFault? fault,
  }) {
    final result = create();
    if (receipt != null) result.receipt = receipt;
    if (fault != null) result.fault = fault;
    return result;
  }

  DeploymentReceiptReply._();

  factory DeploymentReceiptReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeploymentReceiptReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DeploymentReceiptReply_Outcome>
      _DeploymentReceiptReply_OutcomeByTag = {
    1: DeploymentReceiptReply_Outcome.receipt,
    2: DeploymentReceiptReply_Outcome.fault,
    0: DeploymentReceiptReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeploymentReceiptReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DeploymentReceipt>(1, _omitFieldNames ? '' : 'receipt',
        subBuilder: DeploymentReceipt.create)
    ..aOM<DeploymentFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: DeploymentFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentReceiptReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentReceiptReply copyWith(
          void Function(DeploymentReceiptReply) updates) =>
      super.copyWith((message) => updates(message as DeploymentReceiptReply))
          as DeploymentReceiptReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeploymentReceiptReply create() => DeploymentReceiptReply._();
  @$core.override
  DeploymentReceiptReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeploymentReceiptReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeploymentReceiptReply>(create);
  static DeploymentReceiptReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DeploymentReceiptReply_Outcome whichOutcome() =>
      _DeploymentReceiptReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DeploymentReceipt get receipt => $_getN(0);
  @$pb.TagNumber(1)
  set receipt(DeploymentReceipt value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReceipt() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceipt() => $_clearField(1);
  @$pb.TagNumber(1)
  DeploymentReceipt ensureReceipt() => $_ensure(0);

  @$pb.TagNumber(2)
  DeploymentFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(DeploymentFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  DeploymentFault ensureFault() => $_ensure(1);
}

enum DeploymentPrepareEvent_Event { progress, finished, notSet }

class DeploymentPrepareEvent extends $pb.GeneratedMessage {
  factory DeploymentPrepareEvent({
    DeploymentProgress? progress,
    PreparedDeploymentReply? finished,
  }) {
    final result = create();
    if (progress != null) result.progress = progress;
    if (finished != null) result.finished = finished;
    return result;
  }

  DeploymentPrepareEvent._();

  factory DeploymentPrepareEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeploymentPrepareEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DeploymentPrepareEvent_Event>
      _DeploymentPrepareEvent_EventByTag = {
    1: DeploymentPrepareEvent_Event.progress,
    2: DeploymentPrepareEvent_Event.finished,
    0: DeploymentPrepareEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeploymentPrepareEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DeploymentProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: DeploymentProgress.create)
    ..aOM<PreparedDeploymentReply>(2, _omitFieldNames ? '' : 'finished',
        subBuilder: PreparedDeploymentReply.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentPrepareEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentPrepareEvent copyWith(
          void Function(DeploymentPrepareEvent) updates) =>
      super.copyWith((message) => updates(message as DeploymentPrepareEvent))
          as DeploymentPrepareEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeploymentPrepareEvent create() => DeploymentPrepareEvent._();
  @$core.override
  DeploymentPrepareEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeploymentPrepareEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeploymentPrepareEvent>(create);
  static DeploymentPrepareEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DeploymentPrepareEvent_Event whichEvent() =>
      _DeploymentPrepareEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DeploymentProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(DeploymentProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  DeploymentProgress ensureProgress() => $_ensure(0);

  @$pb.TagNumber(2)
  PreparedDeploymentReply get finished => $_getN(1);
  @$pb.TagNumber(2)
  set finished(PreparedDeploymentReply value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFinished() => $_has(1);
  @$pb.TagNumber(2)
  void clearFinished() => $_clearField(2);
  @$pb.TagNumber(2)
  PreparedDeploymentReply ensureFinished() => $_ensure(1);
}

enum DeploymentRunEvent_Event { progress, finished, notSet }

class DeploymentRunEvent extends $pb.GeneratedMessage {
  factory DeploymentRunEvent({
    DeploymentProgress? progress,
    DeploymentReceiptReply? finished,
  }) {
    final result = create();
    if (progress != null) result.progress = progress;
    if (finished != null) result.finished = finished;
    return result;
  }

  DeploymentRunEvent._();

  factory DeploymentRunEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeploymentRunEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DeploymentRunEvent_Event>
      _DeploymentRunEvent_EventByTag = {
    1: DeploymentRunEvent_Event.progress,
    2: DeploymentRunEvent_Event.finished,
    0: DeploymentRunEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeploymentRunEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DeploymentProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: DeploymentProgress.create)
    ..aOM<DeploymentReceiptReply>(2, _omitFieldNames ? '' : 'finished',
        subBuilder: DeploymentReceiptReply.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentRunEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeploymentRunEvent copyWith(void Function(DeploymentRunEvent) updates) =>
      super.copyWith((message) => updates(message as DeploymentRunEvent))
          as DeploymentRunEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeploymentRunEvent create() => DeploymentRunEvent._();
  @$core.override
  DeploymentRunEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeploymentRunEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeploymentRunEvent>(create);
  static DeploymentRunEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DeploymentRunEvent_Event whichEvent() =>
      _DeploymentRunEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DeploymentProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(DeploymentProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  DeploymentProgress ensureProgress() => $_ensure(0);

  @$pb.TagNumber(2)
  DeploymentReceiptReply get finished => $_getN(1);
  @$pb.TagNumber(2)
  set finished(DeploymentReceiptReply value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFinished() => $_has(1);
  @$pb.TagNumber(2)
  void clearFinished() => $_clearField(2);
  @$pb.TagNumber(2)
  DeploymentReceiptReply ensureFinished() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
