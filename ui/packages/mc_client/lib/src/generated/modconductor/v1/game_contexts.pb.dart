// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_contexts.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'game_contexts.pbenum.dart';
import 'proton_contexts.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'game_contexts.pbenum.dart';

class ReadGameContextRequest extends $pb.GeneratedMessage {
  factory ReadGameContextRequest({
    $core.String? workspaceId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    return result;
  }

  ReadGameContextRequest._();

  factory ReadGameContextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadGameContextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadGameContextRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadGameContextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadGameContextRequest copyWith(
          void Function(ReadGameContextRequest) updates) =>
      super.copyWith((message) => updates(message as ReadGameContextRequest))
          as ReadGameContextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadGameContextRequest create() => ReadGameContextRequest._();
  @$core.override
  ReadGameContextRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadGameContextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadGameContextRequest>(create);
  static ReadGameContextRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);
}

class SaveGameContextRequest extends $pb.GeneratedMessage {
  factory SaveGameContextRequest({
    $core.String? workspaceId,
    $fixnum.Int64? expectedRevision,
    $core.String? path,
    $1.ProtonSelectionInfo? proton,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (path != null) result.path = path;
    if (proton != null) result.proton = proton;
    return result;
  }

  SaveGameContextRequest._();

  factory SaveGameContextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveGameContextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveGameContextRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'path')
    ..aOM<$1.ProtonSelectionInfo>(4, _omitFieldNames ? '' : 'proton',
        subBuilder: $1.ProtonSelectionInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveGameContextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveGameContextRequest copyWith(
          void Function(SaveGameContextRequest) updates) =>
      super.copyWith((message) => updates(message as SaveGameContextRequest))
          as SaveGameContextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveGameContextRequest create() => SaveGameContextRequest._();
  @$core.override
  SaveGameContextRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveGameContextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveGameContextRequest>(create);
  static SaveGameContextRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get path => $_getSZ(2);
  @$pb.TagNumber(3)
  set path($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearPath() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.ProtonSelectionInfo get proton => $_getN(3);
  @$pb.TagNumber(4)
  set proton($1.ProtonSelectionInfo value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasProton() => $_has(3);
  @$pb.TagNumber(4)
  void clearProton() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.ProtonSelectionInfo ensureProton() => $_ensure(3);
}

class RefreshGameContextRequest extends $pb.GeneratedMessage {
  factory RefreshGameContextRequest({
    $core.String? workspaceId,
    $fixnum.Int64? expectedRevision,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    return result;
  }

  RefreshGameContextRequest._();

  factory RefreshGameContextRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshGameContextRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshGameContextRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshGameContextRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshGameContextRequest copyWith(
          void Function(RefreshGameContextRequest) updates) =>
      super.copyWith((message) => updates(message as RefreshGameContextRequest))
          as RefreshGameContextRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshGameContextRequest create() => RefreshGameContextRequest._();
  @$core.override
  RefreshGameContextRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshGameContextRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshGameContextRequest>(create);
  static RefreshGameContextRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedRevision() => $_clearField(2);
}

class GameDefinitionInfo extends $pb.GeneratedMessage {
  factory GameDefinitionInfo({
    $core.String? definitionId,
    $core.int? revision,
    $core.String? name,
    $core.String? storefront,
    $core.int? declaredSteamAppId,
    $core.Iterable<UnavailableGameCapability>? unavailableCapabilities,
    $core.Iterable<GameCapabilityInfo>? capabilities,
  }) {
    final result = create();
    if (definitionId != null) result.definitionId = definitionId;
    if (revision != null) result.revision = revision;
    if (name != null) result.name = name;
    if (storefront != null) result.storefront = storefront;
    if (declaredSteamAppId != null)
      result.declaredSteamAppId = declaredSteamAppId;
    if (unavailableCapabilities != null)
      result.unavailableCapabilities.addAll(unavailableCapabilities);
    if (capabilities != null) result.capabilities.addAll(capabilities);
    return result;
  }

  GameDefinitionInfo._();

  factory GameDefinitionInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameDefinitionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameDefinitionInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'definitionId')
    ..aI(2, _omitFieldNames ? '' : 'revision', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'storefront')
    ..aI(5, _omitFieldNames ? '' : 'declaredSteamAppId',
        fieldType: $pb.PbFieldType.OU3)
    ..pPM<UnavailableGameCapability>(
        6, _omitFieldNames ? '' : 'unavailableCapabilities',
        subBuilder: UnavailableGameCapability.create)
    ..pPM<GameCapabilityInfo>(7, _omitFieldNames ? '' : 'capabilities',
        subBuilder: GameCapabilityInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameDefinitionInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameDefinitionInfo copyWith(void Function(GameDefinitionInfo) updates) =>
      super.copyWith((message) => updates(message as GameDefinitionInfo))
          as GameDefinitionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameDefinitionInfo create() => GameDefinitionInfo._();
  @$core.override
  GameDefinitionInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameDefinitionInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameDefinitionInfo>(create);
  static GameDefinitionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get definitionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set definitionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDefinitionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDefinitionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get revision => $_getIZ(1);
  @$pb.TagNumber(2)
  set revision($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get storefront => $_getSZ(3);
  @$pb.TagNumber(4)
  set storefront($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStorefront() => $_has(3);
  @$pb.TagNumber(4)
  void clearStorefront() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get declaredSteamAppId => $_getIZ(4);
  @$pb.TagNumber(5)
  set declaredSteamAppId($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeclaredSteamAppId() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeclaredSteamAppId() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<UnavailableGameCapability> get unavailableCapabilities =>
      $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<GameCapabilityInfo> get capabilities => $_getList(6);
}

class UnavailableGameCapability extends $pb.GeneratedMessage {
  factory UnavailableGameCapability({
    $core.String? name,
    $core.String? reason,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (reason != null) result.reason = reason;
    return result;
  }

  UnavailableGameCapability._();

  factory UnavailableGameCapability.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnavailableGameCapability.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnavailableGameCapability',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnavailableGameCapability clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnavailableGameCapability copyWith(
          void Function(UnavailableGameCapability) updates) =>
      super.copyWith((message) => updates(message as UnavailableGameCapability))
          as UnavailableGameCapability;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnavailableGameCapability create() => UnavailableGameCapability._();
  @$core.override
  UnavailableGameCapability createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnavailableGameCapability getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnavailableGameCapability>(create);
  static UnavailableGameCapability? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get reason => $_getSZ(1);
  @$pb.TagNumber(2)
  set reason($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);
}

class GameCapabilityContext extends $pb.GeneratedMessage {
  factory GameCapabilityContext({
    $core.String? definitionId,
    $core.Iterable<GameContextPlatform>? platforms,
  }) {
    final result = create();
    if (definitionId != null) result.definitionId = definitionId;
    if (platforms != null) result.platforms.addAll(platforms);
    return result;
  }

  GameCapabilityContext._();

  factory GameCapabilityContext.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameCapabilityContext.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameCapabilityContext',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'definitionId')
    ..pc<GameContextPlatform>(
        2, _omitFieldNames ? '' : 'platforms', $pb.PbFieldType.KE,
        valueOf: GameContextPlatform.valueOf,
        enumValues: GameContextPlatform.values,
        defaultEnumValue: GameContextPlatform.GAME_CONTEXT_PLATFORM_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameCapabilityContext clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameCapabilityContext copyWith(
          void Function(GameCapabilityContext) updates) =>
      super.copyWith((message) => updates(message as GameCapabilityContext))
          as GameCapabilityContext;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameCapabilityContext create() => GameCapabilityContext._();
  @$core.override
  GameCapabilityContext createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameCapabilityContext getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameCapabilityContext>(create);
  static GameCapabilityContext? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get definitionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set definitionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDefinitionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDefinitionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<GameContextPlatform> get platforms => $_getList(1);
}

class GameCapabilityInfo extends $pb.GeneratedMessage {
  factory GameCapabilityInfo({
    $core.String? capabilityId,
    $core.int? revision,
    $core.String? name,
    GameCapabilityKind? kind,
    $core.Iterable<GameCapabilityContext>? contexts,
    GameCapabilityDisposition? disposition,
    $core.String? reason,
  }) {
    final result = create();
    if (capabilityId != null) result.capabilityId = capabilityId;
    if (revision != null) result.revision = revision;
    if (name != null) result.name = name;
    if (kind != null) result.kind = kind;
    if (contexts != null) result.contexts.addAll(contexts);
    if (disposition != null) result.disposition = disposition;
    if (reason != null) result.reason = reason;
    return result;
  }

  GameCapabilityInfo._();

  factory GameCapabilityInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameCapabilityInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameCapabilityInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'capabilityId')
    ..aI(2, _omitFieldNames ? '' : 'revision', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aE<GameCapabilityKind>(4, _omitFieldNames ? '' : 'kind',
        enumValues: GameCapabilityKind.values)
    ..pPM<GameCapabilityContext>(5, _omitFieldNames ? '' : 'contexts',
        subBuilder: GameCapabilityContext.create)
    ..aE<GameCapabilityDisposition>(6, _omitFieldNames ? '' : 'disposition',
        enumValues: GameCapabilityDisposition.values)
    ..aOS(7, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameCapabilityInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameCapabilityInfo copyWith(void Function(GameCapabilityInfo) updates) =>
      super.copyWith((message) => updates(message as GameCapabilityInfo))
          as GameCapabilityInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameCapabilityInfo create() => GameCapabilityInfo._();
  @$core.override
  GameCapabilityInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameCapabilityInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameCapabilityInfo>(create);
  static GameCapabilityInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get capabilityId => $_getSZ(0);
  @$pb.TagNumber(1)
  set capabilityId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCapabilityId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCapabilityId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get revision => $_getIZ(1);
  @$pb.TagNumber(2)
  set revision($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  GameCapabilityKind get kind => $_getN(3);
  @$pb.TagNumber(4)
  set kind(GameCapabilityKind value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<GameCapabilityContext> get contexts => $_getList(4);

  @$pb.TagNumber(6)
  GameCapabilityDisposition get disposition => $_getN(5);
  @$pb.TagNumber(6)
  set disposition(GameCapabilityDisposition value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasDisposition() => $_has(5);
  @$pb.TagNumber(6)
  void clearDisposition() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get reason => $_getSZ(6);
  @$pb.TagNumber(7)
  set reason($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReason() => $_has(6);
  @$pb.TagNumber(7)
  void clearReason() => $_clearField(7);
}

enum GameLocation_Result { located, unavailableReason, notSet }

class GameLocation extends $pb.GeneratedMessage {
  factory GameLocation({
    LocatedGameFolder? located,
    $core.String? unavailableReason,
  }) {
    final result = create();
    if (located != null) result.located = located;
    if (unavailableReason != null) result.unavailableReason = unavailableReason;
    return result;
  }

  GameLocation._();

  factory GameLocation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameLocation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GameLocation_Result>
      _GameLocation_ResultByTag = {
    1: GameLocation_Result.located,
    2: GameLocation_Result.unavailableReason,
    0: GameLocation_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameLocation',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<LocatedGameFolder>(1, _omitFieldNames ? '' : 'located',
        subBuilder: LocatedGameFolder.create)
    ..aOS(2, _omitFieldNames ? '' : 'unavailableReason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameLocation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameLocation copyWith(void Function(GameLocation) updates) =>
      super.copyWith((message) => updates(message as GameLocation))
          as GameLocation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameLocation create() => GameLocation._();
  @$core.override
  GameLocation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameLocation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameLocation>(create);
  static GameLocation? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  GameLocation_Result whichResult() =>
      _GameLocation_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  LocatedGameFolder get located => $_getN(0);
  @$pb.TagNumber(1)
  set located(LocatedGameFolder value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLocated() => $_has(0);
  @$pb.TagNumber(1)
  void clearLocated() => $_clearField(1);
  @$pb.TagNumber(1)
  LocatedGameFolder ensureLocated() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get unavailableReason => $_getSZ(1);
  @$pb.TagNumber(2)
  set unavailableReason($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUnavailableReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnavailableReason() => $_clearField(2);
}

class LocatedGameFolder extends $pb.GeneratedMessage {
  factory LocatedGameFolder({
    $core.String? path,
    $core.bool? exists,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (exists != null) result.exists = exists;
    return result;
  }

  LocatedGameFolder._();

  factory LocatedGameFolder.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocatedGameFolder.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocatedGameFolder',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOB(2, _omitFieldNames ? '' : 'exists')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocatedGameFolder clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocatedGameFolder copyWith(void Function(LocatedGameFolder) updates) =>
      super.copyWith((message) => updates(message as LocatedGameFolder))
          as LocatedGameFolder;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocatedGameFolder create() => LocatedGameFolder._();
  @$core.override
  LocatedGameFolder createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LocatedGameFolder getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocatedGameFolder>(create);
  static LocatedGameFolder? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get exists => $_getBF(1);
  @$pb.TagNumber(2)
  set exists($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExists() => $_has(1);
  @$pb.TagNumber(2)
  void clearExists() => $_clearField(2);
}

class GameExecutableEvidence extends $pb.GeneratedMessage {
  factory GameExecutableEvidence({
    $core.String? path,
    $core.String? sha256,
    $fixnum.Int64? length,
    $core.String? fileVersion,
    $core.String? productVersion,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (sha256 != null) result.sha256 = sha256;
    if (length != null) result.length = length;
    if (fileVersion != null) result.fileVersion = fileVersion;
    if (productVersion != null) result.productVersion = productVersion;
    return result;
  }

  GameExecutableEvidence._();

  factory GameExecutableEvidence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameExecutableEvidence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameExecutableEvidence',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'sha256')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'fileVersion')
    ..aOS(5, _omitFieldNames ? '' : 'productVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameExecutableEvidence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameExecutableEvidence copyWith(
          void Function(GameExecutableEvidence) updates) =>
      super.copyWith((message) => updates(message as GameExecutableEvidence))
          as GameExecutableEvidence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameExecutableEvidence create() => GameExecutableEvidence._();
  @$core.override
  GameExecutableEvidence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameExecutableEvidence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameExecutableEvidence>(create);
  static GameExecutableEvidence? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sha256 => $_getSZ(1);
  @$pb.TagNumber(2)
  set sha256($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSha256() => $_has(1);
  @$pb.TagNumber(2)
  void clearSha256() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get length => $_getI64(2);
  @$pb.TagNumber(3)
  set length($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLength() => $_has(2);
  @$pb.TagNumber(3)
  void clearLength() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get fileVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set fileVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFileVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearFileVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get productVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set productVersion($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProductVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearProductVersion() => $_clearField(5);
}

class GameValidationProblem extends $pb.GeneratedMessage {
  factory GameValidationProblem({
    $core.String? path,
    $core.String? detail,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (detail != null) result.detail = detail;
    return result;
  }

  GameValidationProblem._();

  factory GameValidationProblem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameValidationProblem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameValidationProblem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameValidationProblem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameValidationProblem copyWith(
          void Function(GameValidationProblem) updates) =>
      super.copyWith((message) => updates(message as GameValidationProblem))
          as GameValidationProblem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameValidationProblem create() => GameValidationProblem._();
  @$core.override
  GameValidationProblem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameValidationProblem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameValidationProblem>(create);
  static GameValidationProblem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get detail => $_getSZ(1);
  @$pb.TagNumber(2)
  set detail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDetail() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetail() => $_clearField(2);
}

class GameInstallationEvidence extends $pb.GeneratedMessage {
  factory GameInstallationEvidence({
    GameContextPlatform? platform,
    $core.String? rootPath,
    $core.String? dataPath,
    GameExecutableEvidence? executable,
    $core.String? launcherPath,
    GameLocation? documents,
    GameLocation? saves,
    GameLocation? localAppData,
    $core.Iterable<GameValidationProblem>? problems,
    $fixnum.Int64? checkedAtUnixMs,
    $core.String? fingerprint,
    $core.String? definitionId,
    $core.int? definitionRevision,
    $1.ProtonContextEvidence? proton,
  }) {
    final result = create();
    if (platform != null) result.platform = platform;
    if (rootPath != null) result.rootPath = rootPath;
    if (dataPath != null) result.dataPath = dataPath;
    if (executable != null) result.executable = executable;
    if (launcherPath != null) result.launcherPath = launcherPath;
    if (documents != null) result.documents = documents;
    if (saves != null) result.saves = saves;
    if (localAppData != null) result.localAppData = localAppData;
    if (problems != null) result.problems.addAll(problems);
    if (checkedAtUnixMs != null) result.checkedAtUnixMs = checkedAtUnixMs;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (definitionId != null) result.definitionId = definitionId;
    if (definitionRevision != null)
      result.definitionRevision = definitionRevision;
    if (proton != null) result.proton = proton;
    return result;
  }

  GameInstallationEvidence._();

  factory GameInstallationEvidence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameInstallationEvidence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameInstallationEvidence',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<GameContextPlatform>(1, _omitFieldNames ? '' : 'platform',
        enumValues: GameContextPlatform.values)
    ..aOS(2, _omitFieldNames ? '' : 'rootPath')
    ..aOS(3, _omitFieldNames ? '' : 'dataPath')
    ..aOM<GameExecutableEvidence>(4, _omitFieldNames ? '' : 'executable',
        subBuilder: GameExecutableEvidence.create)
    ..aOS(5, _omitFieldNames ? '' : 'launcherPath')
    ..aOM<GameLocation>(6, _omitFieldNames ? '' : 'documents',
        subBuilder: GameLocation.create)
    ..aOM<GameLocation>(7, _omitFieldNames ? '' : 'saves',
        subBuilder: GameLocation.create)
    ..aOM<GameLocation>(8, _omitFieldNames ? '' : 'localAppData',
        subBuilder: GameLocation.create)
    ..pPM<GameValidationProblem>(9, _omitFieldNames ? '' : 'problems',
        subBuilder: GameValidationProblem.create)
    ..aInt64(10, _omitFieldNames ? '' : 'checkedAtUnixMs')
    ..aOS(11, _omitFieldNames ? '' : 'fingerprint')
    ..aOS(12, _omitFieldNames ? '' : 'definitionId')
    ..aI(13, _omitFieldNames ? '' : 'definitionRevision',
        fieldType: $pb.PbFieldType.OU3)
    ..aOM<$1.ProtonContextEvidence>(14, _omitFieldNames ? '' : 'proton',
        subBuilder: $1.ProtonContextEvidence.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameInstallationEvidence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameInstallationEvidence copyWith(
          void Function(GameInstallationEvidence) updates) =>
      super.copyWith((message) => updates(message as GameInstallationEvidence))
          as GameInstallationEvidence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameInstallationEvidence create() => GameInstallationEvidence._();
  @$core.override
  GameInstallationEvidence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameInstallationEvidence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameInstallationEvidence>(create);
  static GameInstallationEvidence? _defaultInstance;

  @$pb.TagNumber(1)
  GameContextPlatform get platform => $_getN(0);
  @$pb.TagNumber(1)
  set platform(GameContextPlatform value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPlatform() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlatform() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get rootPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set rootPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRootPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearRootPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get dataPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set dataPath($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDataPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearDataPath() => $_clearField(3);

  @$pb.TagNumber(4)
  GameExecutableEvidence get executable => $_getN(3);
  @$pb.TagNumber(4)
  set executable(GameExecutableEvidence value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasExecutable() => $_has(3);
  @$pb.TagNumber(4)
  void clearExecutable() => $_clearField(4);
  @$pb.TagNumber(4)
  GameExecutableEvidence ensureExecutable() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get launcherPath => $_getSZ(4);
  @$pb.TagNumber(5)
  set launcherPath($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLauncherPath() => $_has(4);
  @$pb.TagNumber(5)
  void clearLauncherPath() => $_clearField(5);

  @$pb.TagNumber(6)
  GameLocation get documents => $_getN(5);
  @$pb.TagNumber(6)
  set documents(GameLocation value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasDocuments() => $_has(5);
  @$pb.TagNumber(6)
  void clearDocuments() => $_clearField(6);
  @$pb.TagNumber(6)
  GameLocation ensureDocuments() => $_ensure(5);

  @$pb.TagNumber(7)
  GameLocation get saves => $_getN(6);
  @$pb.TagNumber(7)
  set saves(GameLocation value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSaves() => $_has(6);
  @$pb.TagNumber(7)
  void clearSaves() => $_clearField(7);
  @$pb.TagNumber(7)
  GameLocation ensureSaves() => $_ensure(6);

  @$pb.TagNumber(8)
  GameLocation get localAppData => $_getN(7);
  @$pb.TagNumber(8)
  set localAppData(GameLocation value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasLocalAppData() => $_has(7);
  @$pb.TagNumber(8)
  void clearLocalAppData() => $_clearField(8);
  @$pb.TagNumber(8)
  GameLocation ensureLocalAppData() => $_ensure(7);

  @$pb.TagNumber(9)
  $pb.PbList<GameValidationProblem> get problems => $_getList(8);

  @$pb.TagNumber(10)
  $fixnum.Int64 get checkedAtUnixMs => $_getI64(9);
  @$pb.TagNumber(10)
  set checkedAtUnixMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCheckedAtUnixMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearCheckedAtUnixMs() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get fingerprint => $_getSZ(10);
  @$pb.TagNumber(11)
  set fingerprint($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasFingerprint() => $_has(10);
  @$pb.TagNumber(11)
  void clearFingerprint() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get definitionId => $_getSZ(11);
  @$pb.TagNumber(12)
  set definitionId($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDefinitionId() => $_has(11);
  @$pb.TagNumber(12)
  void clearDefinitionId() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get definitionRevision => $_getIZ(12);
  @$pb.TagNumber(13)
  set definitionRevision($core.int value) => $_setUnsignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasDefinitionRevision() => $_has(12);
  @$pb.TagNumber(13)
  void clearDefinitionRevision() => $_clearField(13);

  @$pb.TagNumber(14)
  $1.ProtonContextEvidence get proton => $_getN(13);
  @$pb.TagNumber(14)
  set proton($1.ProtonContextEvidence value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasProton() => $_has(13);
  @$pb.TagNumber(14)
  void clearProton() => $_clearField(14);
  @$pb.TagNumber(14)
  $1.ProtonContextEvidence ensureProton() => $_ensure(13);
}

class GameBindingInfo extends $pb.GeneratedMessage {
  factory GameBindingInfo({
    $core.String? bindingId,
    $core.String? path,
    GameInstallationEvidence? evidence,
    $core.bool? needsCheck,
    $core.String? failure,
    $1.ProtonSelectionInfo? proton,
  }) {
    final result = create();
    if (bindingId != null) result.bindingId = bindingId;
    if (path != null) result.path = path;
    if (evidence != null) result.evidence = evidence;
    if (needsCheck != null) result.needsCheck = needsCheck;
    if (failure != null) result.failure = failure;
    if (proton != null) result.proton = proton;
    return result;
  }

  GameBindingInfo._();

  factory GameBindingInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameBindingInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameBindingInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'bindingId')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOM<GameInstallationEvidence>(3, _omitFieldNames ? '' : 'evidence',
        subBuilder: GameInstallationEvidence.create)
    ..aOB(4, _omitFieldNames ? '' : 'needsCheck')
    ..aOS(5, _omitFieldNames ? '' : 'failure')
    ..aOM<$1.ProtonSelectionInfo>(6, _omitFieldNames ? '' : 'proton',
        subBuilder: $1.ProtonSelectionInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameBindingInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameBindingInfo copyWith(void Function(GameBindingInfo) updates) =>
      super.copyWith((message) => updates(message as GameBindingInfo))
          as GameBindingInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameBindingInfo create() => GameBindingInfo._();
  @$core.override
  GameBindingInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameBindingInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameBindingInfo>(create);
  static GameBindingInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get bindingId => $_getSZ(0);
  @$pb.TagNumber(1)
  set bindingId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBindingId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBindingId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  GameInstallationEvidence get evidence => $_getN(2);
  @$pb.TagNumber(3)
  set evidence(GameInstallationEvidence value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEvidence() => $_has(2);
  @$pb.TagNumber(3)
  void clearEvidence() => $_clearField(3);
  @$pb.TagNumber(3)
  GameInstallationEvidence ensureEvidence() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get needsCheck => $_getBF(3);
  @$pb.TagNumber(4)
  set needsCheck($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNeedsCheck() => $_has(3);
  @$pb.TagNumber(4)
  void clearNeedsCheck() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get failure => $_getSZ(4);
  @$pb.TagNumber(5)
  set failure($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFailure() => $_has(4);
  @$pb.TagNumber(5)
  void clearFailure() => $_clearField(5);

  @$pb.TagNumber(6)
  $1.ProtonSelectionInfo get proton => $_getN(5);
  @$pb.TagNumber(6)
  set proton($1.ProtonSelectionInfo value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasProton() => $_has(5);
  @$pb.TagNumber(6)
  void clearProton() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.ProtonSelectionInfo ensureProton() => $_ensure(5);
}

class GameContextState extends $pb.GeneratedMessage {
  factory GameContextState({
    $core.String? workspaceId,
    $fixnum.Int64? revision,
    GameDefinitionInfo? definition,
    GameBindingInfo? binding,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (revision != null) result.revision = revision;
    if (definition != null) result.definition = definition;
    if (binding != null) result.binding = binding;
    return result;
  }

  GameContextState._();

  factory GameContextState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameContextState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameContextState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<GameDefinitionInfo>(3, _omitFieldNames ? '' : 'definition',
        subBuilder: GameDefinitionInfo.create)
    ..aOM<GameBindingInfo>(4, _omitFieldNames ? '' : 'binding',
        subBuilder: GameBindingInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameContextState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameContextState copyWith(void Function(GameContextState) updates) =>
      super.copyWith((message) => updates(message as GameContextState))
          as GameContextState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameContextState create() => GameContextState._();
  @$core.override
  GameContextState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameContextState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameContextState>(create);
  static GameContextState? _defaultInstance;

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
  GameDefinitionInfo get definition => $_getN(2);
  @$pb.TagNumber(3)
  set definition(GameDefinitionInfo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDefinition() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefinition() => $_clearField(3);
  @$pb.TagNumber(3)
  GameDefinitionInfo ensureDefinition() => $_ensure(2);

  @$pb.TagNumber(4)
  GameBindingInfo get binding => $_getN(3);
  @$pb.TagNumber(4)
  set binding(GameBindingInfo value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasBinding() => $_has(3);
  @$pb.TagNumber(4)
  void clearBinding() => $_clearField(4);
  @$pb.TagNumber(4)
  GameBindingInfo ensureBinding() => $_ensure(3);
}

class GameContextFault extends $pb.GeneratedMessage {
  factory GameContextFault({
    GameContextFaultCode? code,
    $core.String? detail,
    GameInstallationEvidence? candidate,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    if (candidate != null) result.candidate = candidate;
    return result;
  }

  GameContextFault._();

  factory GameContextFault.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameContextFault.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameContextFault',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<GameContextFaultCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: GameContextFaultCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..aOM<GameInstallationEvidence>(3, _omitFieldNames ? '' : 'candidate',
        subBuilder: GameInstallationEvidence.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameContextFault clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameContextFault copyWith(void Function(GameContextFault) updates) =>
      super.copyWith((message) => updates(message as GameContextFault))
          as GameContextFault;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameContextFault create() => GameContextFault._();
  @$core.override
  GameContextFault createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameContextFault getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameContextFault>(create);
  static GameContextFault? _defaultInstance;

  @$pb.TagNumber(1)
  GameContextFaultCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(GameContextFaultCode value) => $_setField(1, value);
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

  @$pb.TagNumber(3)
  GameInstallationEvidence get candidate => $_getN(2);
  @$pb.TagNumber(3)
  set candidate(GameInstallationEvidence value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCandidate() => $_has(2);
  @$pb.TagNumber(3)
  void clearCandidate() => $_clearField(3);
  @$pb.TagNumber(3)
  GameInstallationEvidence ensureCandidate() => $_ensure(2);
}

enum GameContextReply_Outcome { state, fault, notSet }

class GameContextReply extends $pb.GeneratedMessage {
  factory GameContextReply({
    GameContextState? state,
    GameContextFault? fault,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (fault != null) result.fault = fault;
    return result;
  }

  GameContextReply._();

  factory GameContextReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameContextReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GameContextReply_Outcome>
      _GameContextReply_OutcomeByTag = {
    1: GameContextReply_Outcome.state,
    2: GameContextReply_Outcome.fault,
    0: GameContextReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameContextReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<GameContextState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: GameContextState.create)
    ..aOM<GameContextFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: GameContextFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameContextReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameContextReply copyWith(void Function(GameContextReply) updates) =>
      super.copyWith((message) => updates(message as GameContextReply))
          as GameContextReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameContextReply create() => GameContextReply._();
  @$core.override
  GameContextReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameContextReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameContextReply>(create);
  static GameContextReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  GameContextReply_Outcome whichOutcome() =>
      _GameContextReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  GameContextState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(GameContextState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  GameContextState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  GameContextFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(GameContextFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  GameContextFault ensureFault() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
