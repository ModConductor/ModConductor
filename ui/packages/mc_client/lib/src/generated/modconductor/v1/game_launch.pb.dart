// This is a generated file - do not edit.
//
// Generated from modconductor/v1/game_launch.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'executables.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class GameLaunchStateRequest extends $pb.GeneratedMessage {
  factory GameLaunchStateRequest({
    $core.String? workspaceId,
    $core.String? profileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  GameLaunchStateRequest._();

  factory GameLaunchStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameLaunchStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameLaunchStateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameLaunchStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameLaunchStateRequest copyWith(
          void Function(GameLaunchStateRequest) updates) =>
      super.copyWith((message) => updates(message as GameLaunchStateRequest))
          as GameLaunchStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameLaunchStateRequest create() => GameLaunchStateRequest._();
  @$core.override
  GameLaunchStateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameLaunchStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameLaunchStateRequest>(create);
  static GameLaunchStateRequest? _defaultInstance;

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

class GameLaunchState extends $pb.GeneratedMessage {
  factory GameLaunchState({
    $core.String? workspaceId,
    $core.String? profileId,
    $fixnum.Int64? contextRevision,
    $core.String? sourceToken,
    $core.String? name,
    $core.String? runtime,
    $core.String? problem,
    $1.ExecutableRun? latest,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (contextRevision != null) result.contextRevision = contextRevision;
    if (sourceToken != null) result.sourceToken = sourceToken;
    if (name != null) result.name = name;
    if (runtime != null) result.runtime = runtime;
    if (problem != null) result.problem = problem;
    if (latest != null) result.latest = latest;
    return result;
  }

  GameLaunchState._();

  factory GameLaunchState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameLaunchState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameLaunchState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'contextRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'sourceToken')
    ..aOS(5, _omitFieldNames ? '' : 'name')
    ..aOS(6, _omitFieldNames ? '' : 'runtime')
    ..aOS(7, _omitFieldNames ? '' : 'problem')
    ..aOM<$1.ExecutableRun>(8, _omitFieldNames ? '' : 'latest',
        subBuilder: $1.ExecutableRun.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameLaunchState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameLaunchState copyWith(void Function(GameLaunchState) updates) =>
      super.copyWith((message) => updates(message as GameLaunchState))
          as GameLaunchState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameLaunchState create() => GameLaunchState._();
  @$core.override
  GameLaunchState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameLaunchState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameLaunchState>(create);
  static GameLaunchState? _defaultInstance;

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
  $fixnum.Int64 get contextRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set contextRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContextRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearContextRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sourceToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set sourceToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSourceToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearSourceToken() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get runtime => $_getSZ(5);
  @$pb.TagNumber(6)
  set runtime($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRuntime() => $_has(5);
  @$pb.TagNumber(6)
  void clearRuntime() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get problem => $_getSZ(6);
  @$pb.TagNumber(7)
  set problem($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProblem() => $_has(6);
  @$pb.TagNumber(7)
  void clearProblem() => $_clearField(7);

  @$pb.TagNumber(8)
  $1.ExecutableRun get latest => $_getN(7);
  @$pb.TagNumber(8)
  set latest($1.ExecutableRun value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasLatest() => $_has(7);
  @$pb.TagNumber(8)
  void clearLatest() => $_clearField(8);
  @$pb.TagNumber(8)
  $1.ExecutableRun ensureLatest() => $_ensure(7);
}

enum GameLaunchStateReply_Result { state, problem, notSet }

class GameLaunchStateReply extends $pb.GeneratedMessage {
  factory GameLaunchStateReply({
    GameLaunchState? state,
    $1.ExecutableProblem? problem,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (problem != null) result.problem = problem;
    return result;
  }

  GameLaunchStateReply._();

  factory GameLaunchStateReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GameLaunchStateReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, GameLaunchStateReply_Result>
      _GameLaunchStateReply_ResultByTag = {
    1: GameLaunchStateReply_Result.state,
    2: GameLaunchStateReply_Result.problem,
    0: GameLaunchStateReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GameLaunchStateReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<GameLaunchState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: GameLaunchState.create)
    ..aOM<$1.ExecutableProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: $1.ExecutableProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameLaunchStateReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GameLaunchStateReply copyWith(void Function(GameLaunchStateReply) updates) =>
      super.copyWith((message) => updates(message as GameLaunchStateReply))
          as GameLaunchStateReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GameLaunchStateReply create() => GameLaunchStateReply._();
  @$core.override
  GameLaunchStateReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GameLaunchStateReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GameLaunchStateReply>(create);
  static GameLaunchStateReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  GameLaunchStateReply_Result whichResult() =>
      _GameLaunchStateReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  GameLaunchState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(GameLaunchState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  GameLaunchState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ExecutableProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem($1.ExecutableProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ExecutableProblem ensureProblem() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
