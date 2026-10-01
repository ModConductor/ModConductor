// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_catalogue.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'game_contexts.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ReadGameCatalogueRequest extends $pb.GeneratedMessage {
  factory ReadGameCatalogueRequest() => create();

  ReadGameCatalogueRequest._();

  factory ReadGameCatalogueRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadGameCatalogueRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadGameCatalogueRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadGameCatalogueRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadGameCatalogueRequest copyWith(
          void Function(ReadGameCatalogueRequest) updates) =>
      super.copyWith((message) => updates(message as ReadGameCatalogueRequest))
          as ReadGameCatalogueRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadGameCatalogueRequest create() => ReadGameCatalogueRequest._();
  @$core.override
  ReadGameCatalogueRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadGameCatalogueRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadGameCatalogueRequest>(create);
  static ReadGameCatalogueRequest? _defaultInstance;
}

class GameCatalogueReply extends $pb.GeneratedMessage {
  factory GameCatalogueReply({
    $core.Iterable<$1.GameDefinitionInfo>? games,
  }) {
    final result = create();
    if (games != null) result.games.addAll(games);
    return result;
  }

  GameCatalogueReply._();

  factory GameCatalogueReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameCatalogueReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameCatalogueReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<$1.GameDefinitionInfo>(1, _omitFieldNames ? '' : 'games',
        subBuilder: $1.GameDefinitionInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameCatalogueReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameCatalogueReply copyWith(void Function(GameCatalogueReply) updates) =>
      super.copyWith((message) => updates(message as GameCatalogueReply))
          as GameCatalogueReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameCatalogueReply create() => GameCatalogueReply._();
  @$core.override
  GameCatalogueReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameCatalogueReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameCatalogueReply>(create);
  static GameCatalogueReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$1.GameDefinitionInfo> get games => $_getList(0);
}

class OpenScriptExtenderPageRequest extends $pb.GeneratedMessage {
  factory OpenScriptExtenderPageRequest({
    $core.String? gameId,
  }) {
    final result = create();
    if (gameId != null) result.gameId = gameId;
    return result;
  }

  OpenScriptExtenderPageRequest._();

  factory OpenScriptExtenderPageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenScriptExtenderPageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenScriptExtenderPageRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'gameId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenScriptExtenderPageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenScriptExtenderPageRequest copyWith(
          void Function(OpenScriptExtenderPageRequest) updates) =>
      super.copyWith(
              (message) => updates(message as OpenScriptExtenderPageRequest))
          as OpenScriptExtenderPageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenScriptExtenderPageRequest create() =>
      OpenScriptExtenderPageRequest._();
  @$core.override
  OpenScriptExtenderPageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenScriptExtenderPageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenScriptExtenderPageRequest>(create);
  static OpenScriptExtenderPageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get gameId => $_getSZ(0);
  @$pb.TagNumber(1)
  set gameId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGameId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGameId() => $_clearField(1);
}

class OpenScriptExtenderPageReply extends $pb.GeneratedMessage {
  factory OpenScriptExtenderPageReply({
    $core.String? problem,
  }) {
    final result = create();
    if (problem != null) result.problem = problem;
    return result;
  }

  OpenScriptExtenderPageReply._();

  factory OpenScriptExtenderPageReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenScriptExtenderPageReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenScriptExtenderPageReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenScriptExtenderPageReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenScriptExtenderPageReply copyWith(
          void Function(OpenScriptExtenderPageReply) updates) =>
      super.copyWith(
              (message) => updates(message as OpenScriptExtenderPageReply))
          as OpenScriptExtenderPageReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenScriptExtenderPageReply create() =>
      OpenScriptExtenderPageReply._();
  @$core.override
  OpenScriptExtenderPageReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenScriptExtenderPageReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenScriptExtenderPageReply>(create);
  static OpenScriptExtenderPageReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get problem => $_getSZ(0);
  @$pb.TagNumber(1)
  set problem($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProblem() => $_has(0);
  @$pb.TagNumber(1)
  void clearProblem() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
