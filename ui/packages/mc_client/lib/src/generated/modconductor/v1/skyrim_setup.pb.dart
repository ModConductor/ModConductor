// This is a generated file - do not edit.
//
// Generated from modconductor/v1/skyrim_setup.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'skyrim_setup.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'skyrim_setup.pbenum.dart';

class SkyrimSetupRequest extends $pb.GeneratedMessage {
  factory SkyrimSetupRequest({
    $core.String? workspaceId,
    $core.String? profileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  SkyrimSetupRequest._();

  factory SkyrimSetupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkyrimSetupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkyrimSetupRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupRequest copyWith(void Function(SkyrimSetupRequest) updates) =>
      super.copyWith((message) => updates(message as SkyrimSetupRequest))
          as SkyrimSetupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkyrimSetupRequest create() => SkyrimSetupRequest._();
  @$core.override
  SkyrimSetupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkyrimSetupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkyrimSetupRequest>(create);
  static SkyrimSetupRequest? _defaultInstance;

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

class ReadSkyrimSetupRequest extends $pb.GeneratedMessage {
  factory ReadSkyrimSetupRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.bool? includeFnis,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (includeFnis != null) result.includeFnis = includeFnis;
    return result;
  }

  ReadSkyrimSetupRequest._();

  factory ReadSkyrimSetupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadSkyrimSetupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadSkyrimSetupRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOB(3, _omitFieldNames ? '' : 'includeFnis')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadSkyrimSetupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadSkyrimSetupRequest copyWith(
          void Function(ReadSkyrimSetupRequest) updates) =>
      super.copyWith((message) => updates(message as ReadSkyrimSetupRequest))
          as ReadSkyrimSetupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadSkyrimSetupRequest create() => ReadSkyrimSetupRequest._();
  @$core.override
  ReadSkyrimSetupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadSkyrimSetupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadSkyrimSetupRequest>(create);
  static ReadSkyrimSetupRequest? _defaultInstance;

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
  $core.bool get includeFnis => $_getBF(2);
  @$pb.TagNumber(3)
  set includeFnis($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIncludeFnis() => $_has(2);
  @$pb.TagNumber(3)
  void clearIncludeFnis() => $_clearField(3);
}

class StartSkyrimSetupRequest extends $pb.GeneratedMessage {
  factory StartSkyrimSetupRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.bool? includeFnis,
    $core.String? planToken,
    $core.bool? changePlanConfirmed,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (includeFnis != null) result.includeFnis = includeFnis;
    if (planToken != null) result.planToken = planToken;
    if (changePlanConfirmed != null)
      result.changePlanConfirmed = changePlanConfirmed;
    return result;
  }

  StartSkyrimSetupRequest._();

  factory StartSkyrimSetupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartSkyrimSetupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartSkyrimSetupRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOB(3, _omitFieldNames ? '' : 'includeFnis')
    ..aOS(4, _omitFieldNames ? '' : 'planToken')
    ..aOB(5, _omitFieldNames ? '' : 'changePlanConfirmed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartSkyrimSetupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartSkyrimSetupRequest copyWith(
          void Function(StartSkyrimSetupRequest) updates) =>
      super.copyWith((message) => updates(message as StartSkyrimSetupRequest))
          as StartSkyrimSetupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartSkyrimSetupRequest create() => StartSkyrimSetupRequest._();
  @$core.override
  StartSkyrimSetupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartSkyrimSetupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartSkyrimSetupRequest>(create);
  static StartSkyrimSetupRequest? _defaultInstance;

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
  $core.bool get includeFnis => $_getBF(2);
  @$pb.TagNumber(3)
  set includeFnis($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIncludeFnis() => $_has(2);
  @$pb.TagNumber(3)
  void clearIncludeFnis() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get planToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set planToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPlanToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlanToken() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get changePlanConfirmed => $_getBF(4);
  @$pb.TagNumber(5)
  set changePlanConfirmed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasChangePlanConfirmed() => $_has(4);
  @$pb.TagNumber(5)
  void clearChangePlanConfirmed() => $_clearField(5);
}

class SkyrimSetupArchiveRequest extends $pb.GeneratedMessage {
  factory SkyrimSetupArchiveRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? operationId,
    $core.String? path,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (operationId != null) result.operationId = operationId;
    if (path != null) result.path = path;
    return result;
  }

  SkyrimSetupArchiveRequest._();

  factory SkyrimSetupArchiveRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkyrimSetupArchiveRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkyrimSetupArchiveRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'operationId')
    ..aOS(4, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupArchiveRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupArchiveRequest copyWith(
          void Function(SkyrimSetupArchiveRequest) updates) =>
      super.copyWith((message) => updates(message as SkyrimSetupArchiveRequest))
          as SkyrimSetupArchiveRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkyrimSetupArchiveRequest create() => SkyrimSetupArchiveRequest._();
  @$core.override
  SkyrimSetupArchiveRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkyrimSetupArchiveRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkyrimSetupArchiveRequest>(create);
  static SkyrimSetupArchiveRequest? _defaultInstance;

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
  $core.String get operationId => $_getSZ(2);
  @$pb.TagNumber(3)
  set operationId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOperationId() => $_has(2);
  @$pb.TagNumber(3)
  void clearOperationId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get path => $_getSZ(3);
  @$pb.TagNumber(4)
  set path($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearPath() => $_clearField(4);
}

class SkyrimSetupChange extends $pb.GeneratedMessage {
  factory SkyrimSetupChange({
    $core.String? title,
    $core.String? detail,
  }) {
    final result = create();
    if (title != null) result.title = title;
    if (detail != null) result.detail = detail;
    return result;
  }

  SkyrimSetupChange._();

  factory SkyrimSetupChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkyrimSetupChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkyrimSetupChange',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupChange copyWith(void Function(SkyrimSetupChange) updates) =>
      super.copyWith((message) => updates(message as SkyrimSetupChange))
          as SkyrimSetupChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkyrimSetupChange create() => SkyrimSetupChange._();
  @$core.override
  SkyrimSetupChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkyrimSetupChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkyrimSetupChange>(create);
  static SkyrimSetupChange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get detail => $_getSZ(1);
  @$pb.TagNumber(2)
  set detail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDetail() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetail() => $_clearField(2);
}

class SkyrimSetupComponent extends $pb.GeneratedMessage {
  factory SkyrimSetupComponent({
    $core.String? name,
    $core.String? status,
    $core.String? detail,
    $core.bool? ready,
    $core.bool? active,
    $core.bool? blocked,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (status != null) result.status = status;
    if (detail != null) result.detail = detail;
    if (ready != null) result.ready = ready;
    if (active != null) result.active = active;
    if (blocked != null) result.blocked = blocked;
    return result;
  }

  SkyrimSetupComponent._();

  factory SkyrimSetupComponent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkyrimSetupComponent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkyrimSetupComponent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'detail')
    ..aOB(4, _omitFieldNames ? '' : 'ready')
    ..aOB(5, _omitFieldNames ? '' : 'active')
    ..aOB(6, _omitFieldNames ? '' : 'blocked')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupComponent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupComponent copyWith(void Function(SkyrimSetupComponent) updates) =>
      super.copyWith((message) => updates(message as SkyrimSetupComponent))
          as SkyrimSetupComponent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkyrimSetupComponent create() => SkyrimSetupComponent._();
  @$core.override
  SkyrimSetupComponent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkyrimSetupComponent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkyrimSetupComponent>(create);
  static SkyrimSetupComponent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get detail => $_getSZ(2);
  @$pb.TagNumber(3)
  set detail($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDetail() => $_has(2);
  @$pb.TagNumber(3)
  void clearDetail() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get ready => $_getBF(3);
  @$pb.TagNumber(4)
  set ready($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReady() => $_has(3);
  @$pb.TagNumber(4)
  void clearReady() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get active => $_getBF(4);
  @$pb.TagNumber(5)
  set active($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasActive() => $_has(4);
  @$pb.TagNumber(5)
  void clearActive() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get blocked => $_getBF(5);
  @$pb.TagNumber(6)
  set blocked($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBlocked() => $_has(5);
  @$pb.TagNumber(6)
  void clearBlocked() => $_clearField(6);
}

class SkyrimSetupState extends $pb.GeneratedMessage {
  factory SkyrimSetupState({
    SkyrimSetupPhase? phase,
    $core.String? status,
    $core.String? detail,
    $core.String? planToken,
    $core.Iterable<SkyrimSetupChange>? changes,
    $core.Iterable<SkyrimSetupComponent>? components,
    $core.bool? includeFnis,
    $core.bool? consentRecorded,
    $core.bool? canStart,
    $core.bool? canContinue,
    $core.bool? canSelectEnbArchive,
    $core.bool? active,
    $core.bool? ready,
    $core.bool? canCancel,
  }) {
    final result = create();
    if (phase != null) result.phase = phase;
    if (status != null) result.status = status;
    if (detail != null) result.detail = detail;
    if (planToken != null) result.planToken = planToken;
    if (changes != null) result.changes.addAll(changes);
    if (components != null) result.components.addAll(components);
    if (includeFnis != null) result.includeFnis = includeFnis;
    if (consentRecorded != null) result.consentRecorded = consentRecorded;
    if (canStart != null) result.canStart = canStart;
    if (canContinue != null) result.canContinue = canContinue;
    if (canSelectEnbArchive != null)
      result.canSelectEnbArchive = canSelectEnbArchive;
    if (active != null) result.active = active;
    if (ready != null) result.ready = ready;
    if (canCancel != null) result.canCancel = canCancel;
    return result;
  }

  SkyrimSetupState._();

  factory SkyrimSetupState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkyrimSetupState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkyrimSetupState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<SkyrimSetupPhase>(1, _omitFieldNames ? '' : 'phase',
        enumValues: SkyrimSetupPhase.values)
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'detail')
    ..aOS(4, _omitFieldNames ? '' : 'planToken')
    ..pPM<SkyrimSetupChange>(5, _omitFieldNames ? '' : 'changes',
        subBuilder: SkyrimSetupChange.create)
    ..pPM<SkyrimSetupComponent>(6, _omitFieldNames ? '' : 'components',
        subBuilder: SkyrimSetupComponent.create)
    ..aOB(7, _omitFieldNames ? '' : 'includeFnis')
    ..aOB(8, _omitFieldNames ? '' : 'consentRecorded')
    ..aOB(9, _omitFieldNames ? '' : 'canStart')
    ..aOB(10, _omitFieldNames ? '' : 'canContinue')
    ..aOB(11, _omitFieldNames ? '' : 'canSelectEnbArchive')
    ..aOB(12, _omitFieldNames ? '' : 'active')
    ..aOB(13, _omitFieldNames ? '' : 'ready')
    ..aOB(14, _omitFieldNames ? '' : 'canCancel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupState copyWith(void Function(SkyrimSetupState) updates) =>
      super.copyWith((message) => updates(message as SkyrimSetupState))
          as SkyrimSetupState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkyrimSetupState create() => SkyrimSetupState._();
  @$core.override
  SkyrimSetupState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkyrimSetupState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkyrimSetupState>(create);
  static SkyrimSetupState? _defaultInstance;

  @$pb.TagNumber(1)
  SkyrimSetupPhase get phase => $_getN(0);
  @$pb.TagNumber(1)
  set phase(SkyrimSetupPhase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPhase() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhase() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get detail => $_getSZ(2);
  @$pb.TagNumber(3)
  set detail($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDetail() => $_has(2);
  @$pb.TagNumber(3)
  void clearDetail() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get planToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set planToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPlanToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlanToken() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<SkyrimSetupChange> get changes => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<SkyrimSetupComponent> get components => $_getList(5);

  @$pb.TagNumber(7)
  $core.bool get includeFnis => $_getBF(6);
  @$pb.TagNumber(7)
  set includeFnis($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIncludeFnis() => $_has(6);
  @$pb.TagNumber(7)
  void clearIncludeFnis() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get consentRecorded => $_getBF(7);
  @$pb.TagNumber(8)
  set consentRecorded($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasConsentRecorded() => $_has(7);
  @$pb.TagNumber(8)
  void clearConsentRecorded() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get canStart => $_getBF(8);
  @$pb.TagNumber(9)
  set canStart($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCanStart() => $_has(8);
  @$pb.TagNumber(9)
  void clearCanStart() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get canContinue => $_getBF(9);
  @$pb.TagNumber(10)
  set canContinue($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCanContinue() => $_has(9);
  @$pb.TagNumber(10)
  void clearCanContinue() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get canSelectEnbArchive => $_getBF(10);
  @$pb.TagNumber(11)
  set canSelectEnbArchive($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCanSelectEnbArchive() => $_has(10);
  @$pb.TagNumber(11)
  void clearCanSelectEnbArchive() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get active => $_getBF(11);
  @$pb.TagNumber(12)
  set active($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasActive() => $_has(11);
  @$pb.TagNumber(12)
  void clearActive() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get ready => $_getBF(12);
  @$pb.TagNumber(13)
  set ready($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasReady() => $_has(12);
  @$pb.TagNumber(13)
  void clearReady() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get canCancel => $_getBF(13);
  @$pb.TagNumber(14)
  set canCancel($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCanCancel() => $_has(13);
  @$pb.TagNumber(14)
  void clearCanCancel() => $_clearField(14);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
