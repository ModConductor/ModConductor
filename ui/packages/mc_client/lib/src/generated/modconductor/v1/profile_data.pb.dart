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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
