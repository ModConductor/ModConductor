// This is a generated file - do not edit.
//
// Generated from modconductor/v1/desktop.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'desktop.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'desktop.pbenum.dart';

class ResolveDesktopRequestMessage extends $pb.GeneratedMessage {
  factory ResolveDesktopRequestMessage({
    $core.Iterable<$core.String>? arguments,
  }) {
    final result = create();
    if (arguments != null) result.arguments.addAll(arguments);
    return result;
  }

  ResolveDesktopRequestMessage._();

  factory ResolveDesktopRequestMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResolveDesktopRequestMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResolveDesktopRequestMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'arguments')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolveDesktopRequestMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolveDesktopRequestMessage copyWith(
          void Function(ResolveDesktopRequestMessage) updates) =>
      super.copyWith(
              (message) => updates(message as ResolveDesktopRequestMessage))
          as ResolveDesktopRequestMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolveDesktopRequestMessage create() =>
      ResolveDesktopRequestMessage._();
  @$core.override
  ResolveDesktopRequestMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResolveDesktopRequestMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResolveDesktopRequestMessage>(create);
  static ResolveDesktopRequestMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get arguments => $_getList(0);
}

class DesktopIntent extends $pb.GeneratedMessage {
  factory DesktopIntent({
    DesktopIntentKind? kind,
    $core.String? path,
    $core.String? workspaceId,
    $fixnum.Int64? length,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (path != null) result.path = path;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (length != null) result.length = length;
    return result;
  }

  DesktopIntent._();

  factory DesktopIntent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DesktopIntent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DesktopIntent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<DesktopIntentKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: DesktopIntentKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOS(3, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DesktopIntent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DesktopIntent copyWith(void Function(DesktopIntent) updates) =>
      super.copyWith((message) => updates(message as DesktopIntent))
          as DesktopIntent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DesktopIntent create() => DesktopIntent._();
  @$core.override
  DesktopIntent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DesktopIntent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DesktopIntent>(create);
  static DesktopIntent? _defaultInstance;

  @$pb.TagNumber(1)
  DesktopIntentKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(DesktopIntentKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get workspaceId => $_getSZ(2);
  @$pb.TagNumber(3)
  set workspaceId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWorkspaceId() => $_has(2);
  @$pb.TagNumber(3)
  void clearWorkspaceId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get length => $_getI64(3);
  @$pb.TagNumber(4)
  set length($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLength() => $_has(3);
  @$pb.TagNumber(4)
  void clearLength() => $_clearField(4);
}

enum DesktopRequestReply_Outcome { intent, problem, notSet }

class DesktopRequestReply extends $pb.GeneratedMessage {
  factory DesktopRequestReply({
    DesktopIntent? intent,
    $core.String? problem,
  }) {
    final result = create();
    if (intent != null) result.intent = intent;
    if (problem != null) result.problem = problem;
    return result;
  }

  DesktopRequestReply._();

  factory DesktopRequestReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DesktopRequestReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DesktopRequestReply_Outcome>
      _DesktopRequestReply_OutcomeByTag = {
    1: DesktopRequestReply_Outcome.intent,
    2: DesktopRequestReply_Outcome.problem,
    0: DesktopRequestReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DesktopRequestReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DesktopIntent>(1, _omitFieldNames ? '' : 'intent',
        subBuilder: DesktopIntent.create)
    ..aOS(2, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DesktopRequestReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DesktopRequestReply copyWith(void Function(DesktopRequestReply) updates) =>
      super.copyWith((message) => updates(message as DesktopRequestReply))
          as DesktopRequestReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DesktopRequestReply create() => DesktopRequestReply._();
  @$core.override
  DesktopRequestReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DesktopRequestReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DesktopRequestReply>(create);
  static DesktopRequestReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DesktopRequestReply_Outcome whichOutcome() =>
      _DesktopRequestReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DesktopIntent get intent => $_getN(0);
  @$pb.TagNumber(1)
  set intent(DesktopIntent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasIntent() => $_has(0);
  @$pb.TagNumber(1)
  void clearIntent() => $_clearField(1);
  @$pb.TagNumber(1)
  DesktopIntent ensureIntent() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get problem => $_getSZ(1);
  @$pb.TagNumber(2)
  set problem($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
