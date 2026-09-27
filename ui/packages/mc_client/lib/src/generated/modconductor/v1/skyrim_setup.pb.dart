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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'skyrim_setup.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'skyrim_setup.pbenum.dart';

class SkyrimSetupPageRequest extends $pb.GeneratedMessage {
  factory SkyrimSetupPageRequest({
    $core.String? componentId,
  }) {
    final result = create();
    if (componentId != null) result.componentId = componentId;
    return result;
  }

  SkyrimSetupPageRequest._();

  factory SkyrimSetupPageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkyrimSetupPageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkyrimSetupPageRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'componentId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupPageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupPageRequest copyWith(
          void Function(SkyrimSetupPageRequest) updates) =>
      super.copyWith((message) => updates(message as SkyrimSetupPageRequest))
          as SkyrimSetupPageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkyrimSetupPageRequest create() => SkyrimSetupPageRequest._();
  @$core.override
  SkyrimSetupPageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkyrimSetupPageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkyrimSetupPageRequest>(create);
  static SkyrimSetupPageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get componentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set componentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasComponentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearComponentId() => $_clearField(1);
}

class SkyrimSetupPageReply extends $pb.GeneratedMessage {
  factory SkyrimSetupPageReply({
    $core.bool? opened,
  }) {
    final result = create();
    if (opened != null) result.opened = opened;
    return result;
  }

  SkyrimSetupPageReply._();

  factory SkyrimSetupPageReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkyrimSetupPageReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkyrimSetupPageReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'opened')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupPageReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupPageReply copyWith(void Function(SkyrimSetupPageReply) updates) =>
      super.copyWith((message) => updates(message as SkyrimSetupPageReply))
          as SkyrimSetupPageReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkyrimSetupPageReply create() => SkyrimSetupPageReply._();
  @$core.override
  SkyrimSetupPageReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkyrimSetupPageReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkyrimSetupPageReply>(create);
  static SkyrimSetupPageReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get opened => $_getBF(0);
  @$pb.TagNumber(1)
  set opened($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOpened() => $_has(0);
  @$pb.TagNumber(1)
  void clearOpened() => $_clearField(1);
}

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
    SkyrimSetupSelection? selection,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (selection != null) result.selection = selection;
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
    ..aOM<SkyrimSetupSelection>(3, _omitFieldNames ? '' : 'selection',
        subBuilder: SkyrimSetupSelection.create)
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
  SkyrimSetupSelection get selection => $_getN(2);
  @$pb.TagNumber(3)
  set selection(SkyrimSetupSelection value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSelection() => $_has(2);
  @$pb.TagNumber(3)
  void clearSelection() => $_clearField(3);
  @$pb.TagNumber(3)
  SkyrimSetupSelection ensureSelection() => $_ensure(2);
}

class StartSkyrimSetupRequest extends $pb.GeneratedMessage {
  factory StartSkyrimSetupRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    SkyrimSetupSelection? selection,
    SkseReleaseChoice? skseChoice,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (selection != null) result.selection = selection;
    if (skseChoice != null) result.skseChoice = skseChoice;
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
    ..aOM<SkyrimSetupSelection>(3, _omitFieldNames ? '' : 'selection',
        subBuilder: SkyrimSetupSelection.create)
    ..aOM<SkseReleaseChoice>(4, _omitFieldNames ? '' : 'skseChoice',
        subBuilder: SkseReleaseChoice.create)
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
  SkyrimSetupSelection get selection => $_getN(2);
  @$pb.TagNumber(3)
  set selection(SkyrimSetupSelection value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSelection() => $_has(2);
  @$pb.TagNumber(3)
  void clearSelection() => $_clearField(3);
  @$pb.TagNumber(3)
  SkyrimSetupSelection ensureSelection() => $_ensure(2);

  @$pb.TagNumber(4)
  SkseReleaseChoice get skseChoice => $_getN(3);
  @$pb.TagNumber(4)
  set skseChoice(SkseReleaseChoice value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSkseChoice() => $_has(3);
  @$pb.TagNumber(4)
  void clearSkseChoice() => $_clearField(4);
  @$pb.TagNumber(4)
  SkseReleaseChoice ensureSkseChoice() => $_ensure(3);
}

class SkseReleaseChoice extends $pb.GeneratedMessage {
  factory SkseReleaseChoice({
    $fixnum.Int64? fileId,
    $core.String? componentVersion,
    $core.String? gameVersion,
    $core.String? gameSha256,
    $core.bool? allowIncompatible,
  }) {
    final result = create();
    if (fileId != null) result.fileId = fileId;
    if (componentVersion != null) result.componentVersion = componentVersion;
    if (gameVersion != null) result.gameVersion = gameVersion;
    if (gameSha256 != null) result.gameSha256 = gameSha256;
    if (allowIncompatible != null) result.allowIncompatible = allowIncompatible;
    return result;
  }

  SkseReleaseChoice._();

  factory SkseReleaseChoice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkseReleaseChoice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkseReleaseChoice',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'fileId')
    ..aOS(2, _omitFieldNames ? '' : 'componentVersion')
    ..aOS(3, _omitFieldNames ? '' : 'gameVersion')
    ..aOS(4, _omitFieldNames ? '' : 'gameSha256')
    ..aOB(5, _omitFieldNames ? '' : 'allowIncompatible')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkseReleaseChoice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkseReleaseChoice copyWith(void Function(SkseReleaseChoice) updates) =>
      super.copyWith((message) => updates(message as SkseReleaseChoice))
          as SkseReleaseChoice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkseReleaseChoice create() => SkseReleaseChoice._();
  @$core.override
  SkseReleaseChoice createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkseReleaseChoice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkseReleaseChoice>(create);
  static SkseReleaseChoice? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get fileId => $_getI64(0);
  @$pb.TagNumber(1)
  set fileId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get componentVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set componentVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasComponentVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearComponentVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get gameVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set gameVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGameVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearGameVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get gameSha256 => $_getSZ(3);
  @$pb.TagNumber(4)
  set gameSha256($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGameSha256() => $_has(3);
  @$pb.TagNumber(4)
  void clearGameSha256() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get allowIncompatible => $_getBF(4);
  @$pb.TagNumber(5)
  set allowIncompatible($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAllowIncompatible() => $_has(4);
  @$pb.TagNumber(5)
  void clearAllowIncompatible() => $_clearField(5);
}

class SkseReleaseReview extends $pb.GeneratedMessage {
  factory SkseReleaseReview({
    $core.bool? compatible,
    $core.String? gameVersion,
    $core.String? gameSha256,
    $fixnum.Int64? fileId,
    $core.String? componentVersion,
    $core.String? supportedRuntime,
    $core.String? problem,
  }) {
    final result = create();
    if (compatible != null) result.compatible = compatible;
    if (gameVersion != null) result.gameVersion = gameVersion;
    if (gameSha256 != null) result.gameSha256 = gameSha256;
    if (fileId != null) result.fileId = fileId;
    if (componentVersion != null) result.componentVersion = componentVersion;
    if (supportedRuntime != null) result.supportedRuntime = supportedRuntime;
    if (problem != null) result.problem = problem;
    return result;
  }

  SkseReleaseReview._();

  factory SkseReleaseReview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkseReleaseReview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkseReleaseReview',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'compatible')
    ..aOS(2, _omitFieldNames ? '' : 'gameVersion')
    ..aOS(3, _omitFieldNames ? '' : 'gameSha256')
    ..aInt64(4, _omitFieldNames ? '' : 'fileId')
    ..aOS(5, _omitFieldNames ? '' : 'componentVersion')
    ..aOS(6, _omitFieldNames ? '' : 'supportedRuntime')
    ..aOS(7, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkseReleaseReview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkseReleaseReview copyWith(void Function(SkseReleaseReview) updates) =>
      super.copyWith((message) => updates(message as SkseReleaseReview))
          as SkseReleaseReview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkseReleaseReview create() => SkseReleaseReview._();
  @$core.override
  SkseReleaseReview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkseReleaseReview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkseReleaseReview>(create);
  static SkseReleaseReview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get compatible => $_getBF(0);
  @$pb.TagNumber(1)
  set compatible($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCompatible() => $_has(0);
  @$pb.TagNumber(1)
  void clearCompatible() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get gameVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set gameVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGameVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearGameVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get gameSha256 => $_getSZ(2);
  @$pb.TagNumber(3)
  set gameSha256($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGameSha256() => $_has(2);
  @$pb.TagNumber(3)
  void clearGameSha256() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get fileId => $_getI64(3);
  @$pb.TagNumber(4)
  set fileId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFileId() => $_has(3);
  @$pb.TagNumber(4)
  void clearFileId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get componentVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set componentVersion($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasComponentVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearComponentVersion() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get supportedRuntime => $_getSZ(5);
  @$pb.TagNumber(6)
  set supportedRuntime($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSupportedRuntime() => $_has(5);
  @$pb.TagNumber(6)
  void clearSupportedRuntime() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get problem => $_getSZ(6);
  @$pb.TagNumber(7)
  set problem($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProblem() => $_has(6);
  @$pb.TagNumber(7)
  void clearProblem() => $_clearField(7);
}

class SkyrimSetupSelection extends $pb.GeneratedMessage {
  factory SkyrimSetupSelection({
    SkyrimSetupAction? skse,
    SkyrimSetupAction? enb,
    SkyrimSetupAction? fnis,
    $core.String? enbArchivePath,
  }) {
    final result = create();
    if (skse != null) result.skse = skse;
    if (enb != null) result.enb = enb;
    if (fnis != null) result.fnis = fnis;
    if (enbArchivePath != null) result.enbArchivePath = enbArchivePath;
    return result;
  }

  SkyrimSetupSelection._();

  factory SkyrimSetupSelection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SkyrimSetupSelection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SkyrimSetupSelection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<SkyrimSetupAction>(1, _omitFieldNames ? '' : 'skse',
        enumValues: SkyrimSetupAction.values)
    ..aE<SkyrimSetupAction>(2, _omitFieldNames ? '' : 'enb',
        enumValues: SkyrimSetupAction.values)
    ..aE<SkyrimSetupAction>(3, _omitFieldNames ? '' : 'fnis',
        enumValues: SkyrimSetupAction.values)
    ..aOS(4, _omitFieldNames ? '' : 'enbArchivePath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupSelection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SkyrimSetupSelection copyWith(void Function(SkyrimSetupSelection) updates) =>
      super.copyWith((message) => updates(message as SkyrimSetupSelection))
          as SkyrimSetupSelection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SkyrimSetupSelection create() => SkyrimSetupSelection._();
  @$core.override
  SkyrimSetupSelection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SkyrimSetupSelection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SkyrimSetupSelection>(create);
  static SkyrimSetupSelection? _defaultInstance;

  @$pb.TagNumber(1)
  SkyrimSetupAction get skse => $_getN(0);
  @$pb.TagNumber(1)
  set skse(SkyrimSetupAction value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSkse() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkse() => $_clearField(1);

  @$pb.TagNumber(2)
  SkyrimSetupAction get enb => $_getN(1);
  @$pb.TagNumber(2)
  set enb(SkyrimSetupAction value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEnb() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnb() => $_clearField(2);

  @$pb.TagNumber(3)
  SkyrimSetupAction get fnis => $_getN(2);
  @$pb.TagNumber(3)
  set fnis(SkyrimSetupAction value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFnis() => $_has(2);
  @$pb.TagNumber(3)
  void clearFnis() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get enbArchivePath => $_getSZ(3);
  @$pb.TagNumber(4)
  set enbArchivePath($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnbArchivePath() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnbArchivePath() => $_clearField(4);
}

class SkyrimSetupComponent extends $pb.GeneratedMessage {
  factory SkyrimSetupComponent({
    $core.String? name,
    $core.String? status,
    $core.String? detail,
    $core.bool? ready,
    $core.bool? active,
    $core.bool? blocked,
    $core.String? id,
    $core.bool? installed,
    $core.String? updateVersion,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (status != null) result.status = status;
    if (detail != null) result.detail = detail;
    if (ready != null) result.ready = ready;
    if (active != null) result.active = active;
    if (blocked != null) result.blocked = blocked;
    if (id != null) result.id = id;
    if (installed != null) result.installed = installed;
    if (updateVersion != null) result.updateVersion = updateVersion;
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
    ..aOS(7, _omitFieldNames ? '' : 'id')
    ..aOB(8, _omitFieldNames ? '' : 'installed')
    ..aOS(9, _omitFieldNames ? '' : 'updateVersion')
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

  @$pb.TagNumber(7)
  $core.String get id => $_getSZ(6);
  @$pb.TagNumber(7)
  set id($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasId() => $_has(6);
  @$pb.TagNumber(7)
  void clearId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get installed => $_getBF(7);
  @$pb.TagNumber(8)
  set installed($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasInstalled() => $_has(7);
  @$pb.TagNumber(8)
  void clearInstalled() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get updateVersion => $_getSZ(8);
  @$pb.TagNumber(9)
  set updateVersion($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUpdateVersion() => $_has(8);
  @$pb.TagNumber(9)
  void clearUpdateVersion() => $_clearField(9);
}

class SkyrimSetupState extends $pb.GeneratedMessage {
  factory SkyrimSetupState({
    SkyrimSetupPhase? phase,
    $core.String? status,
    $core.String? detail,
    $core.Iterable<SkyrimSetupComponent>? components,
    SkyrimSetupSelection? selection,
    $core.bool? canStart,
    $core.bool? canContinue,
    $core.bool? active,
    $core.bool? ready,
    $core.bool? canCancel,
  }) {
    final result = create();
    if (phase != null) result.phase = phase;
    if (status != null) result.status = status;
    if (detail != null) result.detail = detail;
    if (components != null) result.components.addAll(components);
    if (selection != null) result.selection = selection;
    if (canStart != null) result.canStart = canStart;
    if (canContinue != null) result.canContinue = canContinue;
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
    ..pPM<SkyrimSetupComponent>(6, _omitFieldNames ? '' : 'components',
        subBuilder: SkyrimSetupComponent.create)
    ..aOM<SkyrimSetupSelection>(7, _omitFieldNames ? '' : 'selection',
        subBuilder: SkyrimSetupSelection.create)
    ..aOB(9, _omitFieldNames ? '' : 'canStart')
    ..aOB(10, _omitFieldNames ? '' : 'canContinue')
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

  @$pb.TagNumber(6)
  $pb.PbList<SkyrimSetupComponent> get components => $_getList(3);

  @$pb.TagNumber(7)
  SkyrimSetupSelection get selection => $_getN(4);
  @$pb.TagNumber(7)
  set selection(SkyrimSetupSelection value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSelection() => $_has(4);
  @$pb.TagNumber(7)
  void clearSelection() => $_clearField(7);
  @$pb.TagNumber(7)
  SkyrimSetupSelection ensureSelection() => $_ensure(4);

  @$pb.TagNumber(9)
  $core.bool get canStart => $_getBF(5);
  @$pb.TagNumber(9)
  set canStart($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(9)
  $core.bool hasCanStart() => $_has(5);
  @$pb.TagNumber(9)
  void clearCanStart() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get canContinue => $_getBF(6);
  @$pb.TagNumber(10)
  set canContinue($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(10)
  $core.bool hasCanContinue() => $_has(6);
  @$pb.TagNumber(10)
  void clearCanContinue() => $_clearField(10);

  @$pb.TagNumber(12)
  $core.bool get active => $_getBF(7);
  @$pb.TagNumber(12)
  set active($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(12)
  $core.bool hasActive() => $_has(7);
  @$pb.TagNumber(12)
  void clearActive() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get ready => $_getBF(8);
  @$pb.TagNumber(13)
  set ready($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(13)
  $core.bool hasReady() => $_has(8);
  @$pb.TagNumber(13)
  void clearReady() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get canCancel => $_getBF(9);
  @$pb.TagNumber(14)
  set canCancel($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(14)
  $core.bool hasCanCancel() => $_has(9);
  @$pb.TagNumber(14)
  void clearCanCancel() => $_clearField(14);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
