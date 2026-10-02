// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_registration.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'game_contexts.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ListInstalledGamesRequest extends $pb.GeneratedMessage {
  factory ListInstalledGamesRequest({
    $core.Iterable<$core.String>? additionalRoots,
  }) {
    final result = create();
    if (additionalRoots != null) result.additionalRoots.addAll(additionalRoots);
    return result;
  }

  ListInstalledGamesRequest._();

  factory ListInstalledGamesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListInstalledGamesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListInstalledGamesRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'additionalRoots')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInstalledGamesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInstalledGamesRequest copyWith(
          void Function(ListInstalledGamesRequest) updates) =>
      super.copyWith((message) => updates(message as ListInstalledGamesRequest))
          as ListInstalledGamesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListInstalledGamesRequest create() => ListInstalledGamesRequest._();
  @$core.override
  ListInstalledGamesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListInstalledGamesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListInstalledGamesRequest>(create);
  static ListInstalledGamesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get additionalRoots => $_getList(0);
}

class SearchThunderstoreGamesRequest extends $pb.GeneratedMessage {
  factory SearchThunderstoreGamesRequest({
    $core.String? query,
  }) {
    final result = create();
    if (query != null) result.query = query;
    return result;
  }

  SearchThunderstoreGamesRequest._();

  factory SearchThunderstoreGamesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchThunderstoreGamesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchThunderstoreGamesRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchThunderstoreGamesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchThunderstoreGamesRequest copyWith(
          void Function(SearchThunderstoreGamesRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SearchThunderstoreGamesRequest))
          as SearchThunderstoreGamesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchThunderstoreGamesRequest create() =>
      SearchThunderstoreGamesRequest._();
  @$core.override
  SearchThunderstoreGamesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SearchThunderstoreGamesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchThunderstoreGamesRequest>(create);
  static SearchThunderstoreGamesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);
}

class ThunderstoreGameInfo extends $pb.GeneratedMessage {
  factory ThunderstoreGameInfo({
    $core.String? id,
    $core.String? name,
    $core.String? community,
    $core.bool? suppliesSetup,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (community != null) result.community = community;
    if (suppliesSetup != null) result.suppliesSetup = suppliesSetup;
    return result;
  }

  ThunderstoreGameInfo._();

  factory ThunderstoreGameInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreGameInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreGameInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'community')
    ..aOB(4, _omitFieldNames ? '' : 'suppliesSetup')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreGameInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreGameInfo copyWith(void Function(ThunderstoreGameInfo) updates) =>
      super.copyWith((message) => updates(message as ThunderstoreGameInfo))
          as ThunderstoreGameInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreGameInfo create() => ThunderstoreGameInfo._();
  @$core.override
  ThunderstoreGameInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreGameInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreGameInfo>(create);
  static ThunderstoreGameInfo? _defaultInstance;

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
  $core.String get community => $_getSZ(2);
  @$pb.TagNumber(3)
  set community($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommunity() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommunity() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get suppliesSetup => $_getBF(3);
  @$pb.TagNumber(4)
  set suppliesSetup($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSuppliesSetup() => $_has(3);
  @$pb.TagNumber(4)
  void clearSuppliesSetup() => $_clearField(4);
}

class ThunderstoreGamesReply extends $pb.GeneratedMessage {
  factory ThunderstoreGamesReply({
    $core.Iterable<ThunderstoreGameInfo>? games,
    $core.String? problem,
  }) {
    final result = create();
    if (games != null) result.games.addAll(games);
    if (problem != null) result.problem = problem;
    return result;
  }

  ThunderstoreGamesReply._();

  factory ThunderstoreGamesReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreGamesReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreGamesReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<ThunderstoreGameInfo>(1, _omitFieldNames ? '' : 'games',
        subBuilder: ThunderstoreGameInfo.create)
    ..aOS(2, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreGamesReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreGamesReply copyWith(
          void Function(ThunderstoreGamesReply) updates) =>
      super.copyWith((message) => updates(message as ThunderstoreGamesReply))
          as ThunderstoreGamesReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreGamesReply create() => ThunderstoreGamesReply._();
  @$core.override
  ThunderstoreGamesReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreGamesReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreGamesReply>(create);
  static ThunderstoreGamesReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ThunderstoreGameInfo> get games => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get problem => $_getSZ(1);
  @$pb.TagNumber(2)
  set problem($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
}

class DetectGameRequest extends $pb.GeneratedMessage {
  factory DetectGameRequest({
    $core.String? path,
    $core.String? name,
    $core.int? steamAppId,
    $core.String? thunderstoreId,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (name != null) result.name = name;
    if (steamAppId != null) result.steamAppId = steamAppId;
    if (thunderstoreId != null) result.thunderstoreId = thunderstoreId;
    return result;
  }

  DetectGameRequest._();

  factory DetectGameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetectGameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetectGameRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aI(3, _omitFieldNames ? '' : 'steamAppId', fieldType: $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'thunderstoreId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetectGameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetectGameRequest copyWith(void Function(DetectGameRequest) updates) =>
      super.copyWith((message) => updates(message as DetectGameRequest))
          as DetectGameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetectGameRequest create() => DetectGameRequest._();
  @$core.override
  DetectGameRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DetectGameRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetectGameRequest>(create);
  static DetectGameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get steamAppId => $_getIZ(2);
  @$pb.TagNumber(3)
  set steamAppId($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSteamAppId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSteamAppId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get thunderstoreId => $_getSZ(3);
  @$pb.TagNumber(4)
  set thunderstoreId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasThunderstoreId() => $_has(3);
  @$pb.TagNumber(4)
  void clearThunderstoreId() => $_clearField(4);
}

class DetectGameReply extends $pb.GeneratedMessage {
  factory DetectGameReply({
    CustomGameDraft? draft,
    $core.Iterable<$core.String>? executableChoices,
    $core.String? problem,
    $core.String? detectedEngine,
  }) {
    final result = create();
    if (draft != null) result.draft = draft;
    if (executableChoices != null)
      result.executableChoices.addAll(executableChoices);
    if (problem != null) result.problem = problem;
    if (detectedEngine != null) result.detectedEngine = detectedEngine;
    return result;
  }

  DetectGameReply._();

  factory DetectGameReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetectGameReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetectGameReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<CustomGameDraft>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: CustomGameDraft.create)
    ..pPS(2, _omitFieldNames ? '' : 'executableChoices')
    ..aOS(3, _omitFieldNames ? '' : 'problem')
    ..aOS(4, _omitFieldNames ? '' : 'detectedEngine')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetectGameReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetectGameReply copyWith(void Function(DetectGameReply) updates) =>
      super.copyWith((message) => updates(message as DetectGameReply))
          as DetectGameReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetectGameReply create() => DetectGameReply._();
  @$core.override
  DetectGameReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DetectGameReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetectGameReply>(create);
  static DetectGameReply? _defaultInstance;

  @$pb.TagNumber(1)
  CustomGameDraft get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft(CustomGameDraft value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  CustomGameDraft ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get executableChoices => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get problem => $_getSZ(2);
  @$pb.TagNumber(3)
  set problem($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProblem() => $_has(2);
  @$pb.TagNumber(3)
  void clearProblem() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get detectedEngine => $_getSZ(3);
  @$pb.TagNumber(4)
  set detectedEngine($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDetectedEngine() => $_has(3);
  @$pb.TagNumber(4)
  void clearDetectedEngine() => $_clearField(4);
}

class ReadCustomGameRequest extends $pb.GeneratedMessage {
  factory ReadCustomGameRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  ReadCustomGameRequest._();

  factory ReadCustomGameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadCustomGameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadCustomGameRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadCustomGameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadCustomGameRequest copyWith(
          void Function(ReadCustomGameRequest) updates) =>
      super.copyWith((message) => updates(message as ReadCustomGameRequest))
          as ReadCustomGameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadCustomGameRequest create() => ReadCustomGameRequest._();
  @$core.override
  ReadCustomGameRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadCustomGameRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadCustomGameRequest>(create);
  static ReadCustomGameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class SaveCustomGameRequest extends $pb.GeneratedMessage {
  factory SaveCustomGameRequest({
    CustomGameDraft? draft,
  }) {
    final result = create();
    if (draft != null) result.draft = draft;
    return result;
  }

  SaveCustomGameRequest._();

  factory SaveCustomGameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveCustomGameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveCustomGameRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<CustomGameDraft>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: CustomGameDraft.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveCustomGameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveCustomGameRequest copyWith(
          void Function(SaveCustomGameRequest) updates) =>
      super.copyWith((message) => updates(message as SaveCustomGameRequest))
          as SaveCustomGameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveCustomGameRequest create() => SaveCustomGameRequest._();
  @$core.override
  SaveCustomGameRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveCustomGameRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveCustomGameRequest>(create);
  static SaveCustomGameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  CustomGameDraft get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft(CustomGameDraft value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  CustomGameDraft ensureDraft() => $_ensure(0);
}

class CustomGameReply extends $pb.GeneratedMessage {
  factory CustomGameReply({
    CustomGameDraft? draft,
    $2.GameDefinitionInfo? game,
    $core.String? problem,
  }) {
    final result = create();
    if (draft != null) result.draft = draft;
    if (game != null) result.game = game;
    if (problem != null) result.problem = problem;
    return result;
  }

  CustomGameReply._();

  factory CustomGameReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CustomGameReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CustomGameReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<CustomGameDraft>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: CustomGameDraft.create)
    ..aOM<$2.GameDefinitionInfo>(2, _omitFieldNames ? '' : 'game',
        subBuilder: $2.GameDefinitionInfo.create)
    ..aOS(3, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomGameReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomGameReply copyWith(void Function(CustomGameReply) updates) =>
      super.copyWith((message) => updates(message as CustomGameReply))
          as CustomGameReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CustomGameReply create() => CustomGameReply._();
  @$core.override
  CustomGameReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CustomGameReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CustomGameReply>(create);
  static CustomGameReply? _defaultInstance;

  @$pb.TagNumber(1)
  CustomGameDraft get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft(CustomGameDraft value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  CustomGameDraft ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.GameDefinitionInfo get game => $_getN(1);
  @$pb.TagNumber(2)
  set game($2.GameDefinitionInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasGame() => $_has(1);
  @$pb.TagNumber(2)
  void clearGame() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.GameDefinitionInfo ensureGame() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get problem => $_getSZ(2);
  @$pb.TagNumber(3)
  set problem($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProblem() => $_has(2);
  @$pb.TagNumber(3)
  void clearProblem() => $_clearField(3);
}

class CustomGameDraft extends $pb.GeneratedMessage {
  factory CustomGameDraft({
    $core.String? id,
    $core.int? revision,
    $core.String? name,
    $core.int? steamAppId,
    $core.String? mechanism,
    $core.String? executable,
    $core.String? linuxExecutable,
    $core.String? content,
    $core.String? windowsRuntime,
    $core.String? linuxRuntime,
    $core.String? metadata,
    $core.String? unityMetadata,
    $core.String? linuxWrapper,
    $core.String? community,
    $core.String? loaderNamespace,
    $core.String? loaderPackage,
    $core.String? loaderVersion,
    $core.String? archiveRoot,
    $core.String? loaderPage,
    $core.String? loaderDownload,
    $core.String? loaderLicense,
    $core.String? proxy,
    $core.String? core,
    $core.String? mods,
    $core.String? settingsFile,
    $core.String? log,
    $core.String? gameFeatures,
    $core.String? configs,
    $core.String? gameFeatureField,
    $core.Iterable<$core.String>? arguments,
    $core.Iterable<$core.String>? excluded,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (revision != null) result.revision = revision;
    if (name != null) result.name = name;
    if (steamAppId != null) result.steamAppId = steamAppId;
    if (mechanism != null) result.mechanism = mechanism;
    if (executable != null) result.executable = executable;
    if (linuxExecutable != null) result.linuxExecutable = linuxExecutable;
    if (content != null) result.content = content;
    if (windowsRuntime != null) result.windowsRuntime = windowsRuntime;
    if (linuxRuntime != null) result.linuxRuntime = linuxRuntime;
    if (metadata != null) result.metadata = metadata;
    if (unityMetadata != null) result.unityMetadata = unityMetadata;
    if (linuxWrapper != null) result.linuxWrapper = linuxWrapper;
    if (community != null) result.community = community;
    if (loaderNamespace != null) result.loaderNamespace = loaderNamespace;
    if (loaderPackage != null) result.loaderPackage = loaderPackage;
    if (loaderVersion != null) result.loaderVersion = loaderVersion;
    if (archiveRoot != null) result.archiveRoot = archiveRoot;
    if (loaderPage != null) result.loaderPage = loaderPage;
    if (loaderDownload != null) result.loaderDownload = loaderDownload;
    if (loaderLicense != null) result.loaderLicense = loaderLicense;
    if (proxy != null) result.proxy = proxy;
    if (core != null) result.core = core;
    if (mods != null) result.mods = mods;
    if (settingsFile != null) result.settingsFile = settingsFile;
    if (log != null) result.log = log;
    if (gameFeatures != null) result.gameFeatures = gameFeatures;
    if (configs != null) result.configs = configs;
    if (gameFeatureField != null) result.gameFeatureField = gameFeatureField;
    if (arguments != null) result.arguments.addAll(arguments);
    if (excluded != null) result.excluded.addAll(excluded);
    return result;
  }

  CustomGameDraft._();

  factory CustomGameDraft.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CustomGameDraft.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CustomGameDraft',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aI(2, _omitFieldNames ? '' : 'revision')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aI(4, _omitFieldNames ? '' : 'steamAppId', fieldType: $pb.PbFieldType.OU3)
    ..aOS(5, _omitFieldNames ? '' : 'mechanism')
    ..aOS(6, _omitFieldNames ? '' : 'executable')
    ..aOS(7, _omitFieldNames ? '' : 'linuxExecutable')
    ..aOS(8, _omitFieldNames ? '' : 'content')
    ..aOS(9, _omitFieldNames ? '' : 'windowsRuntime')
    ..aOS(10, _omitFieldNames ? '' : 'linuxRuntime')
    ..aOS(11, _omitFieldNames ? '' : 'metadata')
    ..aOS(12, _omitFieldNames ? '' : 'unityMetadata')
    ..aOS(13, _omitFieldNames ? '' : 'linuxWrapper')
    ..aOS(14, _omitFieldNames ? '' : 'community')
    ..aOS(15, _omitFieldNames ? '' : 'loaderNamespace')
    ..aOS(16, _omitFieldNames ? '' : 'loaderPackage')
    ..aOS(17, _omitFieldNames ? '' : 'loaderVersion')
    ..aOS(18, _omitFieldNames ? '' : 'archiveRoot')
    ..aOS(19, _omitFieldNames ? '' : 'loaderPage')
    ..aOS(20, _omitFieldNames ? '' : 'loaderDownload')
    ..aOS(21, _omitFieldNames ? '' : 'loaderLicense')
    ..aOS(22, _omitFieldNames ? '' : 'proxy')
    ..aOS(23, _omitFieldNames ? '' : 'core')
    ..aOS(24, _omitFieldNames ? '' : 'mods')
    ..aOS(25, _omitFieldNames ? '' : 'settingsFile')
    ..aOS(26, _omitFieldNames ? '' : 'log')
    ..aOS(27, _omitFieldNames ? '' : 'gameFeatures')
    ..aOS(28, _omitFieldNames ? '' : 'configs')
    ..aOS(29, _omitFieldNames ? '' : 'gameFeatureField')
    ..pPS(30, _omitFieldNames ? '' : 'arguments')
    ..pPS(31, _omitFieldNames ? '' : 'excluded')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomGameDraft clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomGameDraft copyWith(void Function(CustomGameDraft) updates) =>
      super.copyWith((message) => updates(message as CustomGameDraft))
          as CustomGameDraft;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CustomGameDraft create() => CustomGameDraft._();
  @$core.override
  CustomGameDraft createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CustomGameDraft getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CustomGameDraft>(create);
  static CustomGameDraft? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get revision => $_getIZ(1);
  @$pb.TagNumber(2)
  set revision($core.int value) => $_setSignedInt32(1, value);
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
  $core.int get steamAppId => $_getIZ(3);
  @$pb.TagNumber(4)
  set steamAppId($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSteamAppId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSteamAppId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get mechanism => $_getSZ(4);
  @$pb.TagNumber(5)
  set mechanism($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMechanism() => $_has(4);
  @$pb.TagNumber(5)
  void clearMechanism() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get executable => $_getSZ(5);
  @$pb.TagNumber(6)
  set executable($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasExecutable() => $_has(5);
  @$pb.TagNumber(6)
  void clearExecutable() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get linuxExecutable => $_getSZ(6);
  @$pb.TagNumber(7)
  set linuxExecutable($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLinuxExecutable() => $_has(6);
  @$pb.TagNumber(7)
  void clearLinuxExecutable() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get content => $_getSZ(7);
  @$pb.TagNumber(8)
  set content($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasContent() => $_has(7);
  @$pb.TagNumber(8)
  void clearContent() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get windowsRuntime => $_getSZ(8);
  @$pb.TagNumber(9)
  set windowsRuntime($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasWindowsRuntime() => $_has(8);
  @$pb.TagNumber(9)
  void clearWindowsRuntime() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get linuxRuntime => $_getSZ(9);
  @$pb.TagNumber(10)
  set linuxRuntime($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLinuxRuntime() => $_has(9);
  @$pb.TagNumber(10)
  void clearLinuxRuntime() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get metadata => $_getSZ(10);
  @$pb.TagNumber(11)
  set metadata($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasMetadata() => $_has(10);
  @$pb.TagNumber(11)
  void clearMetadata() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get unityMetadata => $_getSZ(11);
  @$pb.TagNumber(12)
  set unityMetadata($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasUnityMetadata() => $_has(11);
  @$pb.TagNumber(12)
  void clearUnityMetadata() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get linuxWrapper => $_getSZ(12);
  @$pb.TagNumber(13)
  set linuxWrapper($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasLinuxWrapper() => $_has(12);
  @$pb.TagNumber(13)
  void clearLinuxWrapper() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get community => $_getSZ(13);
  @$pb.TagNumber(14)
  set community($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCommunity() => $_has(13);
  @$pb.TagNumber(14)
  void clearCommunity() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get loaderNamespace => $_getSZ(14);
  @$pb.TagNumber(15)
  set loaderNamespace($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasLoaderNamespace() => $_has(14);
  @$pb.TagNumber(15)
  void clearLoaderNamespace() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get loaderPackage => $_getSZ(15);
  @$pb.TagNumber(16)
  set loaderPackage($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasLoaderPackage() => $_has(15);
  @$pb.TagNumber(16)
  void clearLoaderPackage() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get loaderVersion => $_getSZ(16);
  @$pb.TagNumber(17)
  set loaderVersion($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasLoaderVersion() => $_has(16);
  @$pb.TagNumber(17)
  void clearLoaderVersion() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get archiveRoot => $_getSZ(17);
  @$pb.TagNumber(18)
  set archiveRoot($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasArchiveRoot() => $_has(17);
  @$pb.TagNumber(18)
  void clearArchiveRoot() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get loaderPage => $_getSZ(18);
  @$pb.TagNumber(19)
  set loaderPage($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasLoaderPage() => $_has(18);
  @$pb.TagNumber(19)
  void clearLoaderPage() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get loaderDownload => $_getSZ(19);
  @$pb.TagNumber(20)
  set loaderDownload($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasLoaderDownload() => $_has(19);
  @$pb.TagNumber(20)
  void clearLoaderDownload() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get loaderLicense => $_getSZ(20);
  @$pb.TagNumber(21)
  set loaderLicense($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasLoaderLicense() => $_has(20);
  @$pb.TagNumber(21)
  void clearLoaderLicense() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.String get proxy => $_getSZ(21);
  @$pb.TagNumber(22)
  set proxy($core.String value) => $_setString(21, value);
  @$pb.TagNumber(22)
  $core.bool hasProxy() => $_has(21);
  @$pb.TagNumber(22)
  void clearProxy() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.String get core => $_getSZ(22);
  @$pb.TagNumber(23)
  set core($core.String value) => $_setString(22, value);
  @$pb.TagNumber(23)
  $core.bool hasCore() => $_has(22);
  @$pb.TagNumber(23)
  void clearCore() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.String get mods => $_getSZ(23);
  @$pb.TagNumber(24)
  set mods($core.String value) => $_setString(23, value);
  @$pb.TagNumber(24)
  $core.bool hasMods() => $_has(23);
  @$pb.TagNumber(24)
  void clearMods() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.String get settingsFile => $_getSZ(24);
  @$pb.TagNumber(25)
  set settingsFile($core.String value) => $_setString(24, value);
  @$pb.TagNumber(25)
  $core.bool hasSettingsFile() => $_has(24);
  @$pb.TagNumber(25)
  void clearSettingsFile() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.String get log => $_getSZ(25);
  @$pb.TagNumber(26)
  set log($core.String value) => $_setString(25, value);
  @$pb.TagNumber(26)
  $core.bool hasLog() => $_has(25);
  @$pb.TagNumber(26)
  void clearLog() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.String get gameFeatures => $_getSZ(26);
  @$pb.TagNumber(27)
  set gameFeatures($core.String value) => $_setString(26, value);
  @$pb.TagNumber(27)
  $core.bool hasGameFeatures() => $_has(26);
  @$pb.TagNumber(27)
  void clearGameFeatures() => $_clearField(27);

  @$pb.TagNumber(28)
  $core.String get configs => $_getSZ(27);
  @$pb.TagNumber(28)
  set configs($core.String value) => $_setString(27, value);
  @$pb.TagNumber(28)
  $core.bool hasConfigs() => $_has(27);
  @$pb.TagNumber(28)
  void clearConfigs() => $_clearField(28);

  @$pb.TagNumber(29)
  $core.String get gameFeatureField => $_getSZ(28);
  @$pb.TagNumber(29)
  set gameFeatureField($core.String value) => $_setString(28, value);
  @$pb.TagNumber(29)
  $core.bool hasGameFeatureField() => $_has(28);
  @$pb.TagNumber(29)
  void clearGameFeatureField() => $_clearField(29);

  @$pb.TagNumber(30)
  $pb.PbList<$core.String> get arguments => $_getList(29);

  @$pb.TagNumber(31)
  $pb.PbList<$core.String> get excluded => $_getList(30);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
