// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'profile_data.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'profile_data.pbenum.dart';

class ProfileDataReadRequest extends $pb.GeneratedMessage {
  factory ProfileDataReadRequest({
    $core.String? workspaceId,
    $core.String? profileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  ProfileDataReadRequest._();

  factory ProfileDataReadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataReadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataReadRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataReadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataReadRequest copyWith(
          void Function(ProfileDataReadRequest) updates) =>
      super.copyWith((message) => updates(message as ProfileDataReadRequest))
          as ProfileDataReadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataReadRequest create() => ProfileDataReadRequest._();
  @$core.override
  ProfileDataReadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataReadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataReadRequest>(create);
  static ProfileDataReadRequest? _defaultInstance;

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

class ProfileDataRef extends $pb.GeneratedMessage {
  factory ProfileDataRef({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? contextId,
    $fixnum.Int64? revision,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (contextId != null) result.contextId = contextId;
    if (revision != null) result.revision = revision;
    return result;
  }

  ProfileDataRef._();

  factory ProfileDataRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataRef',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'contextId')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataRef copyWith(void Function(ProfileDataRef) updates) =>
      super.copyWith((message) => updates(message as ProfileDataRef))
          as ProfileDataRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataRef create() => ProfileDataRef._();
  @$core.override
  ProfileDataRef createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataRef>(create);
  static ProfileDataRef? _defaultInstance;

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
  $core.String get contextId => $_getSZ(2);
  @$pb.TagNumber(3)
  set contextId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContextId() => $_has(2);
  @$pb.TagNumber(3)
  void clearContextId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get revision => $_getI64(3);
  @$pb.TagNumber(4)
  set revision($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRevision() => $_has(3);
  @$pb.TagNumber(4)
  void clearRevision() => $_clearField(4);
}

class ProfileDataOptions extends $pb.GeneratedMessage {
  factory ProfileDataOptions({
    $core.bool? settings,
    $core.bool? saves,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    if (saves != null) result.saves = saves;
    return result;
  }

  ProfileDataOptions._();

  factory ProfileDataOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataOptions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataOptions',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'settings')
    ..aOB(2, _omitFieldNames ? '' : 'saves')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataOptions copyWith(void Function(ProfileDataOptions) updates) =>
      super.copyWith((message) => updates(message as ProfileDataOptions))
          as ProfileDataOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataOptions create() => ProfileDataOptions._();
  @$core.override
  ProfileDataOptions createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataOptions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataOptions>(create);
  static ProfileDataOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get settings => $_getBF(0);
  @$pb.TagNumber(1)
  set settings($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get saves => $_getBF(1);
  @$pb.TagNumber(2)
  set saves($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSaves() => $_has(1);
  @$pb.TagNumber(2)
  void clearSaves() => $_clearField(2);
}

class ProfileDataState extends $pb.GeneratedMessage {
  factory ProfileDataState({
    ProfileDataRef? reference,
    ProfileDataOptions? options,
    $core.String? inUseProfileId,
    $core.String? settingsPath,
    $core.String? savesPath,
    $core.int? settingsFiles,
    $core.int? saveFiles,
    $core.String? pendingActionId,
    $core.String? problem,
    $core.bool? pendingProfileChange,
    $core.bool? settingsInitialized,
    $core.bool? savesInitialized,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (options != null) result.options = options;
    if (inUseProfileId != null) result.inUseProfileId = inUseProfileId;
    if (settingsPath != null) result.settingsPath = settingsPath;
    if (savesPath != null) result.savesPath = savesPath;
    if (settingsFiles != null) result.settingsFiles = settingsFiles;
    if (saveFiles != null) result.saveFiles = saveFiles;
    if (pendingActionId != null) result.pendingActionId = pendingActionId;
    if (problem != null) result.problem = problem;
    if (pendingProfileChange != null)
      result.pendingProfileChange = pendingProfileChange;
    if (settingsInitialized != null)
      result.settingsInitialized = settingsInitialized;
    if (savesInitialized != null) result.savesInitialized = savesInitialized;
    return result;
  }

  ProfileDataState._();

  factory ProfileDataState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ProfileDataRef>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: ProfileDataRef.create)
    ..aOM<ProfileDataOptions>(2, _omitFieldNames ? '' : 'options',
        subBuilder: ProfileDataOptions.create)
    ..aOS(3, _omitFieldNames ? '' : 'inUseProfileId')
    ..aOS(4, _omitFieldNames ? '' : 'settingsPath')
    ..aOS(5, _omitFieldNames ? '' : 'savesPath')
    ..aI(6, _omitFieldNames ? '' : 'settingsFiles',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'saveFiles', fieldType: $pb.PbFieldType.OU3)
    ..aOS(8, _omitFieldNames ? '' : 'pendingActionId')
    ..aOS(9, _omitFieldNames ? '' : 'problem')
    ..aOB(10, _omitFieldNames ? '' : 'pendingProfileChange')
    ..aOB(11, _omitFieldNames ? '' : 'settingsInitialized')
    ..aOB(12, _omitFieldNames ? '' : 'savesInitialized')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataState copyWith(void Function(ProfileDataState) updates) =>
      super.copyWith((message) => updates(message as ProfileDataState))
          as ProfileDataState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataState create() => ProfileDataState._();
  @$core.override
  ProfileDataState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataState>(create);
  static ProfileDataState? _defaultInstance;

  @$pb.TagNumber(1)
  ProfileDataRef get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(ProfileDataRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileDataRef ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  ProfileDataOptions get options => $_getN(1);
  @$pb.TagNumber(2)
  set options(ProfileDataOptions value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOptions() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptions() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataOptions ensureOptions() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get inUseProfileId => $_getSZ(2);
  @$pb.TagNumber(3)
  set inUseProfileId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInUseProfileId() => $_has(2);
  @$pb.TagNumber(3)
  void clearInUseProfileId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get settingsPath => $_getSZ(3);
  @$pb.TagNumber(4)
  set settingsPath($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSettingsPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearSettingsPath() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get savesPath => $_getSZ(4);
  @$pb.TagNumber(5)
  set savesPath($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSavesPath() => $_has(4);
  @$pb.TagNumber(5)
  void clearSavesPath() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get settingsFiles => $_getIZ(5);
  @$pb.TagNumber(6)
  set settingsFiles($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSettingsFiles() => $_has(5);
  @$pb.TagNumber(6)
  void clearSettingsFiles() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get saveFiles => $_getIZ(6);
  @$pb.TagNumber(7)
  set saveFiles($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSaveFiles() => $_has(6);
  @$pb.TagNumber(7)
  void clearSaveFiles() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get pendingActionId => $_getSZ(7);
  @$pb.TagNumber(8)
  set pendingActionId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPendingActionId() => $_has(7);
  @$pb.TagNumber(8)
  void clearPendingActionId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get problem => $_getSZ(8);
  @$pb.TagNumber(9)
  set problem($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasProblem() => $_has(8);
  @$pb.TagNumber(9)
  void clearProblem() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get pendingProfileChange => $_getBF(9);
  @$pb.TagNumber(10)
  set pendingProfileChange($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPendingProfileChange() => $_has(9);
  @$pb.TagNumber(10)
  void clearPendingProfileChange() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get settingsInitialized => $_getBF(10);
  @$pb.TagNumber(11)
  set settingsInitialized($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSettingsInitialized() => $_has(10);
  @$pb.TagNumber(11)
  void clearSettingsInitialized() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get savesInitialized => $_getBF(11);
  @$pb.TagNumber(12)
  set savesInitialized($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasSavesInitialized() => $_has(11);
  @$pb.TagNumber(12)
  void clearSavesInitialized() => $_clearField(12);
}

class ProfileDataEditRequest extends $pb.GeneratedMessage {
  factory ProfileDataEditRequest({
    $core.String? id,
    ProfileDataRef? expected,
    ProfileDataOptions? options,
    InitialProfileSaves? initialSaves,
    DisabledProfileFiles? disabledFiles,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (expected != null) result.expected = expected;
    if (options != null) result.options = options;
    if (initialSaves != null) result.initialSaves = initialSaves;
    if (disabledFiles != null) result.disabledFiles = disabledFiles;
    return result;
  }

  ProfileDataEditRequest._();

  factory ProfileDataEditRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataEditRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataEditRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<ProfileDataRef>(2, _omitFieldNames ? '' : 'expected',
        subBuilder: ProfileDataRef.create)
    ..aOM<ProfileDataOptions>(3, _omitFieldNames ? '' : 'options',
        subBuilder: ProfileDataOptions.create)
    ..aE<InitialProfileSaves>(4, _omitFieldNames ? '' : 'initialSaves',
        enumValues: InitialProfileSaves.values)
    ..aE<DisabledProfileFiles>(5, _omitFieldNames ? '' : 'disabledFiles',
        enumValues: DisabledProfileFiles.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataEditRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataEditRequest copyWith(
          void Function(ProfileDataEditRequest) updates) =>
      super.copyWith((message) => updates(message as ProfileDataEditRequest))
          as ProfileDataEditRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataEditRequest create() => ProfileDataEditRequest._();
  @$core.override
  ProfileDataEditRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataEditRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataEditRequest>(create);
  static ProfileDataEditRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ProfileDataRef get expected => $_getN(1);
  @$pb.TagNumber(2)
  set expected(ProfileDataRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpected() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpected() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataRef ensureExpected() => $_ensure(1);

  @$pb.TagNumber(3)
  ProfileDataOptions get options => $_getN(2);
  @$pb.TagNumber(3)
  set options(ProfileDataOptions value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearOptions() => $_clearField(3);
  @$pb.TagNumber(3)
  ProfileDataOptions ensureOptions() => $_ensure(2);

  @$pb.TagNumber(4)
  InitialProfileSaves get initialSaves => $_getN(3);
  @$pb.TagNumber(4)
  set initialSaves(InitialProfileSaves value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasInitialSaves() => $_has(3);
  @$pb.TagNumber(4)
  void clearInitialSaves() => $_clearField(4);

  @$pb.TagNumber(5)
  DisabledProfileFiles get disabledFiles => $_getN(4);
  @$pb.TagNumber(5)
  set disabledFiles(DisabledProfileFiles value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDisabledFiles() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisabledFiles() => $_clearField(5);
}

class ProfileDataRestoreRequest extends $pb.GeneratedMessage {
  factory ProfileDataRestoreRequest({
    $core.String? id,
    ProfileDataRef? expected,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (expected != null) result.expected = expected;
    return result;
  }

  ProfileDataRestoreRequest._();

  factory ProfileDataRestoreRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataRestoreRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataRestoreRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<ProfileDataRef>(2, _omitFieldNames ? '' : 'expected',
        subBuilder: ProfileDataRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataRestoreRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataRestoreRequest copyWith(
          void Function(ProfileDataRestoreRequest) updates) =>
      super.copyWith((message) => updates(message as ProfileDataRestoreRequest))
          as ProfileDataRestoreRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataRestoreRequest create() => ProfileDataRestoreRequest._();
  @$core.override
  ProfileDataRestoreRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataRestoreRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataRestoreRequest>(create);
  static ProfileDataRestoreRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ProfileDataRef get expected => $_getN(1);
  @$pb.TagNumber(2)
  set expected(ProfileDataRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpected() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpected() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataRef ensureExpected() => $_ensure(1);
}

class ProfileDataActionRequest extends $pb.GeneratedMessage {
  factory ProfileDataActionRequest({
    $core.String? workspaceId,
    $core.String? id,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (id != null) result.id = id;
    return result;
  }

  ProfileDataActionRequest._();

  factory ProfileDataActionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataActionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataActionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataActionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataActionRequest copyWith(
          void Function(ProfileDataActionRequest) updates) =>
      super.copyWith((message) => updates(message as ProfileDataActionRequest))
          as ProfileDataActionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataActionRequest create() => ProfileDataActionRequest._();
  @$core.override
  ProfileDataActionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataActionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataActionRequest>(create);
  static ProfileDataActionRequest? _defaultInstance;

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

class ProfileDataActionResult extends $pb.GeneratedMessage {
  factory ProfileDataActionResult({
    $core.String? id,
    ProfileDataState? state,
    $core.bool? complete,
    $core.int? completedFiles,
    $core.String? problem,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (state != null) result.state = state;
    if (complete != null) result.complete = complete;
    if (completedFiles != null) result.completedFiles = completedFiles;
    if (problem != null) result.problem = problem;
    return result;
  }

  ProfileDataActionResult._();

  factory ProfileDataActionResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataActionResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataActionResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<ProfileDataState>(2, _omitFieldNames ? '' : 'state',
        subBuilder: ProfileDataState.create)
    ..aOB(3, _omitFieldNames ? '' : 'complete')
    ..aI(4, _omitFieldNames ? '' : 'completedFiles',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(5, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataActionResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataActionResult copyWith(
          void Function(ProfileDataActionResult) updates) =>
      super.copyWith((message) => updates(message as ProfileDataActionResult))
          as ProfileDataActionResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataActionResult create() => ProfileDataActionResult._();
  @$core.override
  ProfileDataActionResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataActionResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataActionResult>(create);
  static ProfileDataActionResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ProfileDataState get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(ProfileDataState value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataState ensureState() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get complete => $_getBF(2);
  @$pb.TagNumber(3)
  set complete($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasComplete() => $_has(2);
  @$pb.TagNumber(3)
  void clearComplete() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get completedFiles => $_getIZ(3);
  @$pb.TagNumber(4)
  set completedFiles($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCompletedFiles() => $_has(3);
  @$pb.TagNumber(4)
  void clearCompletedFiles() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get problem => $_getSZ(4);
  @$pb.TagNumber(5)
  set problem($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProblem() => $_has(4);
  @$pb.TagNumber(5)
  void clearProblem() => $_clearField(5);
}

class ProfileDataProblem extends $pb.GeneratedMessage {
  factory ProfileDataProblem({
    ProfileDataProblemKind? kind,
    $core.String? detail,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (detail != null) result.detail = detail;
    return result;
  }

  ProfileDataProblem._();

  factory ProfileDataProblem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataProblem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataProblem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<ProfileDataProblemKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: ProfileDataProblemKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataProblem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataProblem copyWith(void Function(ProfileDataProblem) updates) =>
      super.copyWith((message) => updates(message as ProfileDataProblem))
          as ProfileDataProblem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataProblem create() => ProfileDataProblem._();
  @$core.override
  ProfileDataProblem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataProblem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataProblem>(create);
  static ProfileDataProblem? _defaultInstance;

  @$pb.TagNumber(1)
  ProfileDataProblemKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(ProfileDataProblemKind value) => $_setField(1, value);
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

enum ProfileDataReply_Result { state, problem, notSet }

class ProfileDataReply extends $pb.GeneratedMessage {
  factory ProfileDataReply({
    ProfileDataState? state,
    ProfileDataProblem? problem,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (problem != null) result.problem = problem;
    return result;
  }

  ProfileDataReply._();

  factory ProfileDataReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileDataReply_Result>
      _ProfileDataReply_ResultByTag = {
    1: ProfileDataReply_Result.state,
    2: ProfileDataReply_Result.problem,
    0: ProfileDataReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProfileDataState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: ProfileDataState.create)
    ..aOM<ProfileDataProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: ProfileDataProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataReply copyWith(void Function(ProfileDataReply) updates) =>
      super.copyWith((message) => updates(message as ProfileDataReply))
          as ProfileDataReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataReply create() => ProfileDataReply._();
  @$core.override
  ProfileDataReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataReply>(create);
  static ProfileDataReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProfileDataReply_Result whichResult() =>
      _ProfileDataReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfileDataState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(ProfileDataState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileDataState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  ProfileDataProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem(ProfileDataProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataProblem ensureProblem() => $_ensure(1);
}

class ProfileDataProgress extends $pb.GeneratedMessage {
  factory ProfileDataProgress({
    $core.int? files,
    $fixnum.Int64? bytes,
  }) {
    final result = create();
    if (files != null) result.files = files;
    if (bytes != null) result.bytes = bytes;
    return result;
  }

  ProfileDataProgress._();

  factory ProfileDataProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataProgress',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'files', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataProgress copyWith(void Function(ProfileDataProgress) updates) =>
      super.copyWith((message) => updates(message as ProfileDataProgress))
          as ProfileDataProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataProgress create() => ProfileDataProgress._();
  @$core.override
  ProfileDataProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataProgress>(create);
  static ProfileDataProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get files => $_getIZ(0);
  @$pb.TagNumber(1)
  set files($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFiles() => $_has(0);
  @$pb.TagNumber(1)
  void clearFiles() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytes => $_getI64(1);
  @$pb.TagNumber(2)
  set bytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytes() => $_clearField(2);
}

enum ProfileDataEvent_Event { progress, result, problem, notSet }

class ProfileDataEvent extends $pb.GeneratedMessage {
  factory ProfileDataEvent({
    ProfileDataProgress? progress,
    ProfileDataActionResult? result,
    ProfileDataProblem? problem,
  }) {
    final result$ = create();
    if (progress != null) result$.progress = progress;
    if (result != null) result$.result = result;
    if (problem != null) result$.problem = problem;
    return result$;
  }

  ProfileDataEvent._();

  factory ProfileDataEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileDataEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileDataEvent_Event>
      _ProfileDataEvent_EventByTag = {
    1: ProfileDataEvent_Event.progress,
    2: ProfileDataEvent_Event.result,
    3: ProfileDataEvent_Event.problem,
    0: ProfileDataEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileDataEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<ProfileDataProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: ProfileDataProgress.create)
    ..aOM<ProfileDataActionResult>(2, _omitFieldNames ? '' : 'result',
        subBuilder: ProfileDataActionResult.create)
    ..aOM<ProfileDataProblem>(3, _omitFieldNames ? '' : 'problem',
        subBuilder: ProfileDataProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileDataEvent copyWith(void Function(ProfileDataEvent) updates) =>
      super.copyWith((message) => updates(message as ProfileDataEvent))
          as ProfileDataEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileDataEvent create() => ProfileDataEvent._();
  @$core.override
  ProfileDataEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileDataEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileDataEvent>(create);
  static ProfileDataEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  ProfileDataEvent_Event whichEvent() =>
      _ProfileDataEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfileDataProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(ProfileDataProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileDataProgress ensureProgress() => $_ensure(0);

  @$pb.TagNumber(2)
  ProfileDataActionResult get result => $_getN(1);
  @$pb.TagNumber(2)
  set result(ProfileDataActionResult value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResult() => $_has(1);
  @$pb.TagNumber(2)
  void clearResult() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataActionResult ensureResult() => $_ensure(1);

  @$pb.TagNumber(3)
  ProfileDataProblem get problem => $_getN(2);
  @$pb.TagNumber(3)
  set problem(ProfileDataProblem value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProblem() => $_has(2);
  @$pb.TagNumber(3)
  void clearProblem() => $_clearField(3);
  @$pb.TagNumber(3)
  ProfileDataProblem ensureProblem() => $_ensure(2);
}

class ProfileSaveRequest extends $pb.GeneratedMessage {
  factory ProfileSaveRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.Iterable<$core.String>? path,
    $core.String? after,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (path != null) result.path.addAll(path);
    if (after != null) result.after = after;
    return result;
  }

  ProfileSaveRequest._();

  factory ProfileSaveRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..pPS(3, _omitFieldNames ? '' : 'path')
    ..aOS(4, _omitFieldNames ? '' : 'after')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveRequest copyWith(void Function(ProfileSaveRequest) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveRequest))
          as ProfileSaveRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveRequest create() => ProfileSaveRequest._();
  @$core.override
  ProfileSaveRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveRequest>(create);
  static ProfileSaveRequest? _defaultInstance;

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
  $pb.PbList<$core.String> get path => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get after => $_getSZ(3);
  @$pb.TagNumber(4)
  set after($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAfter() => $_has(3);
  @$pb.TagNumber(4)
  void clearAfter() => $_clearField(4);
}

class ProfileSaveEntry extends $pb.GeneratedMessage {
  factory ProfileSaveEntry({
    $core.String? name,
    $core.bool? directory,
    $fixnum.Int64? bytes,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (directory != null) result.directory = directory;
    if (bytes != null) result.bytes = bytes;
    return result;
  }

  ProfileSaveEntry._();

  factory ProfileSaveEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveEntry',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'directory')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveEntry copyWith(void Function(ProfileSaveEntry) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveEntry))
          as ProfileSaveEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveEntry create() => ProfileSaveEntry._();
  @$core.override
  ProfileSaveEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveEntry>(create);
  static ProfileSaveEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get directory => $_getBF(1);
  @$pb.TagNumber(2)
  set directory($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDirectory() => $_has(1);
  @$pb.TagNumber(2)
  void clearDirectory() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get bytes => $_getI64(2);
  @$pb.TagNumber(3)
  set bytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearBytes() => $_clearField(3);
}

class ProfileSavePage extends $pb.GeneratedMessage {
  factory ProfileSavePage({
    $core.Iterable<ProfileSaveEntry>? entries,
    $core.String? next,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (next != null) result.next = next;
    return result;
  }

  ProfileSavePage._();

  factory ProfileSavePage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSavePage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSavePage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<ProfileSaveEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: ProfileSaveEntry.create)
    ..aOS(2, _omitFieldNames ? '' : 'next')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSavePage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSavePage copyWith(void Function(ProfileSavePage) updates) =>
      super.copyWith((message) => updates(message as ProfileSavePage))
          as ProfileSavePage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSavePage create() => ProfileSavePage._();
  @$core.override
  ProfileSavePage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSavePage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSavePage>(create);
  static ProfileSavePage? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ProfileSaveEntry> get entries => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get next => $_getSZ(1);
  @$pb.TagNumber(2)
  set next($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNext() => $_has(1);
  @$pb.TagNumber(2)
  void clearNext() => $_clearField(2);
}

enum ProfileSaveReply_Result { page, problem, notSet }

class ProfileSaveReply extends $pb.GeneratedMessage {
  factory ProfileSaveReply({
    ProfileSavePage? page,
    ProfileDataProblem? problem,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (problem != null) result.problem = problem;
    return result;
  }

  ProfileSaveReply._();

  factory ProfileSaveReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileSaveReply_Result>
      _ProfileSaveReply_ResultByTag = {
    1: ProfileSaveReply_Result.page,
    2: ProfileSaveReply_Result.problem,
    0: ProfileSaveReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProfileSavePage>(1, _omitFieldNames ? '' : 'page',
        subBuilder: ProfileSavePage.create)
    ..aOM<ProfileDataProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: ProfileDataProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveReply copyWith(void Function(ProfileSaveReply) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveReply))
          as ProfileSaveReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveReply create() => ProfileSaveReply._();
  @$core.override
  ProfileSaveReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveReply>(create);
  static ProfileSaveReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProfileSaveReply_Result whichResult() =>
      _ProfileSaveReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfileSavePage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(ProfileSavePage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileSavePage ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  ProfileDataProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem(ProfileDataProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataProblem ensureProblem() => $_ensure(1);
}

class ProfileSavePath extends $pb.GeneratedMessage {
  factory ProfileSavePath({
    $core.String? hostPath,
    $core.String? windowsPath,
  }) {
    final result = create();
    if (hostPath != null) result.hostPath = hostPath;
    if (windowsPath != null) result.windowsPath = windowsPath;
    return result;
  }

  ProfileSavePath._();

  factory ProfileSavePath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSavePath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSavePath',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hostPath')
    ..aOS(2, _omitFieldNames ? '' : 'windowsPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSavePath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSavePath copyWith(void Function(ProfileSavePath) updates) =>
      super.copyWith((message) => updates(message as ProfileSavePath))
          as ProfileSavePath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSavePath create() => ProfileSavePath._();
  @$core.override
  ProfileSavePath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSavePath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSavePath>(create);
  static ProfileSavePath? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHostPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get windowsPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set windowsPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWindowsPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearWindowsPath() => $_clearField(2);
}

class ProfileSaveGroupRequest extends $pb.GeneratedMessage {
  factory ProfileSaveGroupRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    ProfileSaveSource? source,
    $core.String? after,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (source != null) result.source = source;
    if (after != null) result.after = after;
    return result;
  }

  ProfileSaveGroupRequest._();

  factory ProfileSaveGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveGroupRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aE<ProfileSaveSource>(3, _omitFieldNames ? '' : 'source',
        enumValues: ProfileSaveSource.values)
    ..aOS(4, _omitFieldNames ? '' : 'after')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveGroupRequest copyWith(
          void Function(ProfileSaveGroupRequest) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveGroupRequest))
          as ProfileSaveGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveGroupRequest create() => ProfileSaveGroupRequest._();
  @$core.override
  ProfileSaveGroupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveGroupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveGroupRequest>(create);
  static ProfileSaveGroupRequest? _defaultInstance;

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
  ProfileSaveSource get source => $_getN(2);
  @$pb.TagNumber(3)
  set source(ProfileSaveSource value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get after => $_getSZ(3);
  @$pb.TagNumber(4)
  set after($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAfter() => $_has(3);
  @$pb.TagNumber(4)
  void clearAfter() => $_clearField(4);
}

class ProfileSaveGroupEntry extends $pb.GeneratedMessage {
  factory ProfileSaveGroupEntry({
    $core.String? id,
    $core.String? name,
    ProfileSaveEntryKind? kind,
    $fixnum.Int64? bytes,
    $core.String? companion,
    $fixnum.Int64? companionBytes,
    $core.bool? actionable,
    $core.String? problem,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (kind != null) result.kind = kind;
    if (bytes != null) result.bytes = bytes;
    if (companion != null) result.companion = companion;
    if (companionBytes != null) result.companionBytes = companionBytes;
    if (actionable != null) result.actionable = actionable;
    if (problem != null) result.problem = problem;
    return result;
  }

  ProfileSaveGroupEntry._();

  factory ProfileSaveGroupEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveGroupEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveGroupEntry',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<ProfileSaveEntryKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: ProfileSaveEntryKind.values)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(5, _omitFieldNames ? '' : 'companion')
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'companionBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(7, _omitFieldNames ? '' : 'actionable')
    ..aOS(8, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveGroupEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveGroupEntry copyWith(
          void Function(ProfileSaveGroupEntry) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveGroupEntry))
          as ProfileSaveGroupEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveGroupEntry create() => ProfileSaveGroupEntry._();
  @$core.override
  ProfileSaveGroupEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveGroupEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveGroupEntry>(create);
  static ProfileSaveGroupEntry? _defaultInstance;

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
  ProfileSaveEntryKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(ProfileSaveEntryKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get bytes => $_getI64(3);
  @$pb.TagNumber(4)
  set bytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get companion => $_getSZ(4);
  @$pb.TagNumber(5)
  set companion($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCompanion() => $_has(4);
  @$pb.TagNumber(5)
  void clearCompanion() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get companionBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set companionBytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCompanionBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearCompanionBytes() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get actionable => $_getBF(6);
  @$pb.TagNumber(7)
  set actionable($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasActionable() => $_has(6);
  @$pb.TagNumber(7)
  void clearActionable() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get problem => $_getSZ(7);
  @$pb.TagNumber(8)
  set problem($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasProblem() => $_has(7);
  @$pb.TagNumber(8)
  void clearProblem() => $_clearField(8);
}

class ProfileSaveGroupPage extends $pb.GeneratedMessage {
  factory ProfileSaveGroupPage({
    ProfileSaveSource? source,
    ProfileSavePath? path,
    $core.Iterable<ProfileSaveGroupEntry>? entries,
    $core.String? next,
  }) {
    final result = create();
    if (source != null) result.source = source;
    if (path != null) result.path = path;
    if (entries != null) result.entries.addAll(entries);
    if (next != null) result.next = next;
    return result;
  }

  ProfileSaveGroupPage._();

  factory ProfileSaveGroupPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveGroupPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveGroupPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<ProfileSaveSource>(1, _omitFieldNames ? '' : 'source',
        enumValues: ProfileSaveSource.values)
    ..aOM<ProfileSavePath>(2, _omitFieldNames ? '' : 'path',
        subBuilder: ProfileSavePath.create)
    ..pPM<ProfileSaveGroupEntry>(3, _omitFieldNames ? '' : 'entries',
        subBuilder: ProfileSaveGroupEntry.create)
    ..aOS(4, _omitFieldNames ? '' : 'next')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveGroupPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveGroupPage copyWith(void Function(ProfileSaveGroupPage) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveGroupPage))
          as ProfileSaveGroupPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveGroupPage create() => ProfileSaveGroupPage._();
  @$core.override
  ProfileSaveGroupPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveGroupPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveGroupPage>(create);
  static ProfileSaveGroupPage? _defaultInstance;

  @$pb.TagNumber(1)
  ProfileSaveSource get source => $_getN(0);
  @$pb.TagNumber(1)
  set source(ProfileSaveSource value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSource() => $_has(0);
  @$pb.TagNumber(1)
  void clearSource() => $_clearField(1);

  @$pb.TagNumber(2)
  ProfileSavePath get path => $_getN(1);
  @$pb.TagNumber(2)
  set path(ProfileSavePath value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileSavePath ensurePath() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<ProfileSaveGroupEntry> get entries => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get next => $_getSZ(3);
  @$pb.TagNumber(4)
  set next($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNext() => $_has(3);
  @$pb.TagNumber(4)
  void clearNext() => $_clearField(4);
}

enum ProfileSaveGroupReply_Result { page, problem, notSet }

class ProfileSaveGroupReply extends $pb.GeneratedMessage {
  factory ProfileSaveGroupReply({
    ProfileSaveGroupPage? page,
    ProfileDataProblem? problem,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (problem != null) result.problem = problem;
    return result;
  }

  ProfileSaveGroupReply._();

  factory ProfileSaveGroupReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveGroupReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileSaveGroupReply_Result>
      _ProfileSaveGroupReply_ResultByTag = {
    1: ProfileSaveGroupReply_Result.page,
    2: ProfileSaveGroupReply_Result.problem,
    0: ProfileSaveGroupReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveGroupReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProfileSaveGroupPage>(1, _omitFieldNames ? '' : 'page',
        subBuilder: ProfileSaveGroupPage.create)
    ..aOM<ProfileDataProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: ProfileDataProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveGroupReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveGroupReply copyWith(
          void Function(ProfileSaveGroupReply) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveGroupReply))
          as ProfileSaveGroupReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveGroupReply create() => ProfileSaveGroupReply._();
  @$core.override
  ProfileSaveGroupReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveGroupReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveGroupReply>(create);
  static ProfileSaveGroupReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProfileSaveGroupReply_Result whichResult() =>
      _ProfileSaveGroupReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfileSaveGroupPage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(ProfileSaveGroupPage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileSaveGroupPage ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  ProfileDataProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem(ProfileDataProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataProblem ensureProblem() => $_ensure(1);
}

class SkyrimSaveMetadata extends $pb.GeneratedMessage {
  factory SkyrimSaveMetadata({
    $core.int? headerVersion,
    $core.int? formVersion,
    SkyrimSaveCompression? compression,
    $core.int? saveNumber,
    $core.String? character,
    $core.int? level,
    $core.String? location,
    $core.String? gameTime,
    $core.Iterable<$core.String>? fullPlugins,
    $core.Iterable<$core.String>? lightPlugins,
  }) {
    final result = create();
    if (headerVersion != null) result.headerVersion = headerVersion;
    if (formVersion != null) result.formVersion = formVersion;
    if (compression != null) result.compression = compression;
    if (saveNumber != null) result.saveNumber = saveNumber;
    if (character != null) result.character = character;
    if (level != null) result.level = level;
    if (location != null) result.location = location;
    if (gameTime != null) result.gameTime = gameTime;
    if (fullPlugins != null) result.fullPlugins.addAll(fullPlugins);
    if (lightPlugins != null) result.lightPlugins.addAll(lightPlugins);
    return result;
  }

  SkyrimSaveMetadata._();

  factory SkyrimSaveMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkyrimSaveMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkyrimSaveMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'headerVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'formVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..aE<SkyrimSaveCompression>(3, _omitFieldNames ? '' : 'compression',
        enumValues: SkyrimSaveCompression.values)
    ..aI(4, _omitFieldNames ? '' : 'saveNumber', fieldType: $pb.PbFieldType.OU3)
    ..aOS(5, _omitFieldNames ? '' : 'character')
    ..aI(6, _omitFieldNames ? '' : 'level', fieldType: $pb.PbFieldType.OU3)
    ..aOS(7, _omitFieldNames ? '' : 'location')
    ..aOS(8, _omitFieldNames ? '' : 'gameTime')
    ..pPS(9, _omitFieldNames ? '' : 'fullPlugins')
    ..pPS(10, _omitFieldNames ? '' : 'lightPlugins')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSaveMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSaveMetadata copyWith(void Function(SkyrimSaveMetadata) updates) =>
      super.copyWith((message) => updates(message as SkyrimSaveMetadata))
          as SkyrimSaveMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkyrimSaveMetadata create() => SkyrimSaveMetadata._();
  @$core.override
  SkyrimSaveMetadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkyrimSaveMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkyrimSaveMetadata>(create);
  static SkyrimSaveMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get headerVersion => $_getIZ(0);
  @$pb.TagNumber(1)
  set headerVersion($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHeaderVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeaderVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get formVersion => $_getIZ(1);
  @$pb.TagNumber(2)
  set formVersion($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFormVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  SkyrimSaveCompression get compression => $_getN(2);
  @$pb.TagNumber(3)
  set compression(SkyrimSaveCompression value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCompression() => $_has(2);
  @$pb.TagNumber(3)
  void clearCompression() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get saveNumber => $_getIZ(3);
  @$pb.TagNumber(4)
  set saveNumber($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSaveNumber() => $_has(3);
  @$pb.TagNumber(4)
  void clearSaveNumber() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get character => $_getSZ(4);
  @$pb.TagNumber(5)
  set character($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCharacter() => $_has(4);
  @$pb.TagNumber(5)
  void clearCharacter() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get level => $_getIZ(5);
  @$pb.TagNumber(6)
  set level($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLevel() => $_has(5);
  @$pb.TagNumber(6)
  void clearLevel() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get location => $_getSZ(6);
  @$pb.TagNumber(7)
  set location($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLocation() => $_has(6);
  @$pb.TagNumber(7)
  void clearLocation() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get gameTime => $_getSZ(7);
  @$pb.TagNumber(8)
  set gameTime($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasGameTime() => $_has(7);
  @$pb.TagNumber(8)
  void clearGameTime() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get fullPlugins => $_getList(8);

  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get lightPlugins => $_getList(9);
}

class SavePluginIssue extends $pb.GeneratedMessage {
  factory SavePluginIssue({
    $core.String? name,
    SavePluginState? state,
    $core.String? source,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (state != null) result.state = state;
    if (source != null) result.source = source;
    return result;
  }

  SavePluginIssue._();

  factory SavePluginIssue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SavePluginIssue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SavePluginIssue',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aE<SavePluginState>(2, _omitFieldNames ? '' : 'state',
        enumValues: SavePluginState.values)
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavePluginIssue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SavePluginIssue copyWith(void Function(SavePluginIssue) updates) =>
      super.copyWith((message) => updates(message as SavePluginIssue))
          as SavePluginIssue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SavePluginIssue create() => SavePluginIssue._();
  @$core.override
  SavePluginIssue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SavePluginIssue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SavePluginIssue>(create);
  static SavePluginIssue? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  SavePluginState get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(SavePluginState value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);
}

class ProfileSaveInspectRequest extends $pb.GeneratedMessage {
  factory ProfileSaveInspectRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    ProfileSaveSource? source,
    $core.String? name,
    $core.String? headersId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (source != null) result.source = source;
    if (name != null) result.name = name;
    if (headersId != null) result.headersId = headersId;
    return result;
  }

  ProfileSaveInspectRequest._();

  factory ProfileSaveInspectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveInspectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveInspectRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aE<ProfileSaveSource>(3, _omitFieldNames ? '' : 'source',
        enumValues: ProfileSaveSource.values)
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'headersId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveInspectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveInspectRequest copyWith(
          void Function(ProfileSaveInspectRequest) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveInspectRequest))
          as ProfileSaveInspectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveInspectRequest create() => ProfileSaveInspectRequest._();
  @$core.override
  ProfileSaveInspectRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveInspectRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveInspectRequest>(create);
  static ProfileSaveInspectRequest? _defaultInstance;

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
  ProfileSaveSource get source => $_getN(2);
  @$pb.TagNumber(3)
  set source(ProfileSaveSource value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get headersId => $_getSZ(4);
  @$pb.TagNumber(5)
  set headersId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHeadersId() => $_has(4);
  @$pb.TagNumber(5)
  void clearHeadersId() => $_clearField(5);
}

class ProfileSaveInspection extends $pb.GeneratedMessage {
  factory ProfileSaveInspection({
    ProfileSaveSource? source,
    ProfileSavePath? path,
    ProfileSaveGroupEntry? entry,
    SkyrimSaveMetadata? metadata,
    $core.String? metadataProblem,
    $core.Iterable<SavePluginIssue>? pluginIssues,
    $core.String? pluginCheckProblem,
  }) {
    final result = create();
    if (source != null) result.source = source;
    if (path != null) result.path = path;
    if (entry != null) result.entry = entry;
    if (metadata != null) result.metadata = metadata;
    if (metadataProblem != null) result.metadataProblem = metadataProblem;
    if (pluginIssues != null) result.pluginIssues.addAll(pluginIssues);
    if (pluginCheckProblem != null)
      result.pluginCheckProblem = pluginCheckProblem;
    return result;
  }

  ProfileSaveInspection._();

  factory ProfileSaveInspection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveInspection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveInspection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<ProfileSaveSource>(1, _omitFieldNames ? '' : 'source',
        enumValues: ProfileSaveSource.values)
    ..aOM<ProfileSavePath>(2, _omitFieldNames ? '' : 'path',
        subBuilder: ProfileSavePath.create)
    ..aOM<ProfileSaveGroupEntry>(3, _omitFieldNames ? '' : 'entry',
        subBuilder: ProfileSaveGroupEntry.create)
    ..aOM<SkyrimSaveMetadata>(4, _omitFieldNames ? '' : 'metadata',
        subBuilder: SkyrimSaveMetadata.create)
    ..aOS(5, _omitFieldNames ? '' : 'metadataProblem')
    ..pPM<SavePluginIssue>(6, _omitFieldNames ? '' : 'pluginIssues',
        subBuilder: SavePluginIssue.create)
    ..aOS(7, _omitFieldNames ? '' : 'pluginCheckProblem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveInspection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveInspection copyWith(
          void Function(ProfileSaveInspection) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveInspection))
          as ProfileSaveInspection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveInspection create() => ProfileSaveInspection._();
  @$core.override
  ProfileSaveInspection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveInspection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveInspection>(create);
  static ProfileSaveInspection? _defaultInstance;

  @$pb.TagNumber(1)
  ProfileSaveSource get source => $_getN(0);
  @$pb.TagNumber(1)
  set source(ProfileSaveSource value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSource() => $_has(0);
  @$pb.TagNumber(1)
  void clearSource() => $_clearField(1);

  @$pb.TagNumber(2)
  ProfileSavePath get path => $_getN(1);
  @$pb.TagNumber(2)
  set path(ProfileSavePath value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileSavePath ensurePath() => $_ensure(1);

  @$pb.TagNumber(3)
  ProfileSaveGroupEntry get entry => $_getN(2);
  @$pb.TagNumber(3)
  set entry(ProfileSaveGroupEntry value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEntry() => $_has(2);
  @$pb.TagNumber(3)
  void clearEntry() => $_clearField(3);
  @$pb.TagNumber(3)
  ProfileSaveGroupEntry ensureEntry() => $_ensure(2);

  @$pb.TagNumber(4)
  SkyrimSaveMetadata get metadata => $_getN(3);
  @$pb.TagNumber(4)
  set metadata(SkyrimSaveMetadata value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMetadata() => $_has(3);
  @$pb.TagNumber(4)
  void clearMetadata() => $_clearField(4);
  @$pb.TagNumber(4)
  SkyrimSaveMetadata ensureMetadata() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get metadataProblem => $_getSZ(4);
  @$pb.TagNumber(5)
  set metadataProblem($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMetadataProblem() => $_has(4);
  @$pb.TagNumber(5)
  void clearMetadataProblem() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<SavePluginIssue> get pluginIssues => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get pluginCheckProblem => $_getSZ(6);
  @$pb.TagNumber(7)
  set pluginCheckProblem($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPluginCheckProblem() => $_has(6);
  @$pb.TagNumber(7)
  void clearPluginCheckProblem() => $_clearField(7);
}

enum ProfileSaveInspectReply_Result { inspection, problem, notSet }

class ProfileSaveInspectReply extends $pb.GeneratedMessage {
  factory ProfileSaveInspectReply({
    ProfileSaveInspection? inspection,
    ProfileDataProblem? problem,
  }) {
    final result = create();
    if (inspection != null) result.inspection = inspection;
    if (problem != null) result.problem = problem;
    return result;
  }

  ProfileSaveInspectReply._();

  factory ProfileSaveInspectReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveInspectReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileSaveInspectReply_Result>
      _ProfileSaveInspectReply_ResultByTag = {
    1: ProfileSaveInspectReply_Result.inspection,
    2: ProfileSaveInspectReply_Result.problem,
    0: ProfileSaveInspectReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveInspectReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProfileSaveInspection>(1, _omitFieldNames ? '' : 'inspection',
        subBuilder: ProfileSaveInspection.create)
    ..aOM<ProfileDataProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: ProfileDataProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveInspectReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveInspectReply copyWith(
          void Function(ProfileSaveInspectReply) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveInspectReply))
          as ProfileSaveInspectReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveInspectReply create() => ProfileSaveInspectReply._();
  @$core.override
  ProfileSaveInspectReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveInspectReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveInspectReply>(create);
  static ProfileSaveInspectReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProfileSaveInspectReply_Result whichResult() =>
      _ProfileSaveInspectReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfileSaveInspection get inspection => $_getN(0);
  @$pb.TagNumber(1)
  set inspection(ProfileSaveInspection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasInspection() => $_has(0);
  @$pb.TagNumber(1)
  void clearInspection() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileSaveInspection ensureInspection() => $_ensure(0);

  @$pb.TagNumber(2)
  ProfileDataProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem(ProfileDataProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataProblem ensureProblem() => $_ensure(1);
}

class ProfileSaveActionFile extends $pb.GeneratedMessage {
  factory ProfileSaveActionFile({
    $core.String? name,
    $fixnum.Int64? bytes,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (bytes != null) result.bytes = bytes;
    return result;
  }

  ProfileSaveActionFile._();

  factory ProfileSaveActionFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveActionFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveActionFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveActionFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveActionFile copyWith(
          void Function(ProfileSaveActionFile) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveActionFile))
          as ProfileSaveActionFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveActionFile create() => ProfileSaveActionFile._();
  @$core.override
  ProfileSaveActionFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveActionFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveActionFile>(create);
  static ProfileSaveActionFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytes => $_getI64(1);
  @$pb.TagNumber(2)
  set bytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytes() => $_clearField(2);
}

class ProfileSaveActionPreviewRequest extends $pb.GeneratedMessage {
  factory ProfileSaveActionPreviewRequest({
    ProfileDataRef? expected,
    ProfileSaveAction? action,
    $core.Iterable<$core.String>? names,
  }) {
    final result = create();
    if (expected != null) result.expected = expected;
    if (action != null) result.action = action;
    if (names != null) result.names.addAll(names);
    return result;
  }

  ProfileSaveActionPreviewRequest._();

  factory ProfileSaveActionPreviewRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveActionPreviewRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveActionPreviewRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ProfileDataRef>(1, _omitFieldNames ? '' : 'expected',
        subBuilder: ProfileDataRef.create)
    ..aE<ProfileSaveAction>(2, _omitFieldNames ? '' : 'action',
        enumValues: ProfileSaveAction.values)
    ..pPS(3, _omitFieldNames ? '' : 'names')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveActionPreviewRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveActionPreviewRequest copyWith(
          void Function(ProfileSaveActionPreviewRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ProfileSaveActionPreviewRequest))
          as ProfileSaveActionPreviewRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveActionPreviewRequest create() =>
      ProfileSaveActionPreviewRequest._();
  @$core.override
  ProfileSaveActionPreviewRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveActionPreviewRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveActionPreviewRequest>(
          create);
  static ProfileSaveActionPreviewRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ProfileDataRef get expected => $_getN(0);
  @$pb.TagNumber(1)
  set expected(ProfileDataRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasExpected() => $_has(0);
  @$pb.TagNumber(1)
  void clearExpected() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileDataRef ensureExpected() => $_ensure(0);

  @$pb.TagNumber(2)
  ProfileSaveAction get action => $_getN(1);
  @$pb.TagNumber(2)
  set action(ProfileSaveAction value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAction() => $_has(1);
  @$pb.TagNumber(2)
  void clearAction() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get names => $_getList(2);
}

class ProfileSaveActionPreview extends $pb.GeneratedMessage {
  factory ProfileSaveActionPreview({
    $core.String? id,
    ProfileDataRef? expected,
    ProfileSaveAction? action,
    ProfileSavePath? source,
    ProfileSavePath? destination,
    $core.Iterable<ProfileSaveActionFile>? files,
    $fixnum.Int64? bytes,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (expected != null) result.expected = expected;
    if (action != null) result.action = action;
    if (source != null) result.source = source;
    if (destination != null) result.destination = destination;
    if (files != null) result.files.addAll(files);
    if (bytes != null) result.bytes = bytes;
    return result;
  }

  ProfileSaveActionPreview._();

  factory ProfileSaveActionPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveActionPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveActionPreview',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<ProfileDataRef>(2, _omitFieldNames ? '' : 'expected',
        subBuilder: ProfileDataRef.create)
    ..aE<ProfileSaveAction>(3, _omitFieldNames ? '' : 'action',
        enumValues: ProfileSaveAction.values)
    ..aOM<ProfileSavePath>(4, _omitFieldNames ? '' : 'source',
        subBuilder: ProfileSavePath.create)
    ..aOM<ProfileSavePath>(5, _omitFieldNames ? '' : 'destination',
        subBuilder: ProfileSavePath.create)
    ..pPM<ProfileSaveActionFile>(6, _omitFieldNames ? '' : 'files',
        subBuilder: ProfileSaveActionFile.create)
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveActionPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveActionPreview copyWith(
          void Function(ProfileSaveActionPreview) updates) =>
      super.copyWith((message) => updates(message as ProfileSaveActionPreview))
          as ProfileSaveActionPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveActionPreview create() => ProfileSaveActionPreview._();
  @$core.override
  ProfileSaveActionPreview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveActionPreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveActionPreview>(create);
  static ProfileSaveActionPreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  ProfileDataRef get expected => $_getN(1);
  @$pb.TagNumber(2)
  set expected(ProfileDataRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpected() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpected() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataRef ensureExpected() => $_ensure(1);

  @$pb.TagNumber(3)
  ProfileSaveAction get action => $_getN(2);
  @$pb.TagNumber(3)
  set action(ProfileSaveAction value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAction() => $_has(2);
  @$pb.TagNumber(3)
  void clearAction() => $_clearField(3);

  @$pb.TagNumber(4)
  ProfileSavePath get source => $_getN(3);
  @$pb.TagNumber(4)
  set source(ProfileSavePath value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSource() => $_has(3);
  @$pb.TagNumber(4)
  void clearSource() => $_clearField(4);
  @$pb.TagNumber(4)
  ProfileSavePath ensureSource() => $_ensure(3);

  @$pb.TagNumber(5)
  ProfileSavePath get destination => $_getN(4);
  @$pb.TagNumber(5)
  set destination(ProfileSavePath value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDestination() => $_has(4);
  @$pb.TagNumber(5)
  void clearDestination() => $_clearField(5);
  @$pb.TagNumber(5)
  ProfileSavePath ensureDestination() => $_ensure(4);

  @$pb.TagNumber(6)
  $pb.PbList<ProfileSaveActionFile> get files => $_getList(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get bytes => $_getI64(6);
  @$pb.TagNumber(7)
  set bytes($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearBytes() => $_clearField(7);
}

enum ProfileSaveActionPreviewReply_Result { preview, problem, notSet }

class ProfileSaveActionPreviewReply extends $pb.GeneratedMessage {
  factory ProfileSaveActionPreviewReply({
    ProfileSaveActionPreview? preview,
    ProfileDataProblem? problem,
  }) {
    final result = create();
    if (preview != null) result.preview = preview;
    if (problem != null) result.problem = problem;
    return result;
  }

  ProfileSaveActionPreviewReply._();

  factory ProfileSaveActionPreviewReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveActionPreviewReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileSaveActionPreviewReply_Result>
      _ProfileSaveActionPreviewReply_ResultByTag = {
    1: ProfileSaveActionPreviewReply_Result.preview,
    2: ProfileSaveActionPreviewReply_Result.problem,
    0: ProfileSaveActionPreviewReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveActionPreviewReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProfileSaveActionPreview>(1, _omitFieldNames ? '' : 'preview',
        subBuilder: ProfileSaveActionPreview.create)
    ..aOM<ProfileDataProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: ProfileDataProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveActionPreviewReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveActionPreviewReply copyWith(
          void Function(ProfileSaveActionPreviewReply) updates) =>
      super.copyWith(
              (message) => updates(message as ProfileSaveActionPreviewReply))
          as ProfileSaveActionPreviewReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveActionPreviewReply create() =>
      ProfileSaveActionPreviewReply._();
  @$core.override
  ProfileSaveActionPreviewReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveActionPreviewReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveActionPreviewReply>(create);
  static ProfileSaveActionPreviewReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProfileSaveActionPreviewReply_Result whichResult() =>
      _ProfileSaveActionPreviewReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfileSaveActionPreview get preview => $_getN(0);
  @$pb.TagNumber(1)
  set preview(ProfileSaveActionPreview value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreview() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreview() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileSaveActionPreview ensurePreview() => $_ensure(0);

  @$pb.TagNumber(2)
  ProfileDataProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem(ProfileDataProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileDataProblem ensureProblem() => $_ensure(1);
}

class ProfileSaveActionApplyRequest extends $pb.GeneratedMessage {
  factory ProfileSaveActionApplyRequest({
    $core.String? id,
    $core.String? previewId,
    ProfileDataRef? expected,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (previewId != null) result.previewId = previewId;
    if (expected != null) result.expected = expected;
    return result;
  }

  ProfileSaveActionApplyRequest._();

  factory ProfileSaveActionApplyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileSaveActionApplyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileSaveActionApplyRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'previewId')
    ..aOM<ProfileDataRef>(3, _omitFieldNames ? '' : 'expected',
        subBuilder: ProfileDataRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveActionApplyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileSaveActionApplyRequest copyWith(
          void Function(ProfileSaveActionApplyRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ProfileSaveActionApplyRequest))
          as ProfileSaveActionApplyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileSaveActionApplyRequest create() =>
      ProfileSaveActionApplyRequest._();
  @$core.override
  ProfileSaveActionApplyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileSaveActionApplyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileSaveActionApplyRequest>(create);
  static ProfileSaveActionApplyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get previewId => $_getSZ(1);
  @$pb.TagNumber(2)
  set previewId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPreviewId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreviewId() => $_clearField(2);

  @$pb.TagNumber(3)
  ProfileDataRef get expected => $_getN(2);
  @$pb.TagNumber(3)
  set expected(ProfileDataRef value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExpected() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpected() => $_clearField(3);
  @$pb.TagNumber(3)
  ProfileDataRef ensureExpected() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
