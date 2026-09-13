// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nexus_interactions.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'nexus.pb.dart' as $2;
import 'nexus_metadata.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ModNexusInteractionState extends $pb.GeneratedMessage {
  factory ModNexusInteractionState({
    $fixnum.Int64? revision,
    $core.bool? tracking,
    $core.String? endorsement,
    $core.bool? busy,
    $2.NexusFailure? failure,
    $core.String? accountName,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (tracking != null) result.tracking = tracking;
    if (endorsement != null) result.endorsement = endorsement;
    if (busy != null) result.busy = busy;
    if (failure != null) result.failure = failure;
    if (accountName != null) result.accountName = accountName;
    return result;
  }

  ModNexusInteractionState._();

  factory ModNexusInteractionState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModNexusInteractionState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModNexusInteractionState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'revision')
    ..aOB(2, _omitFieldNames ? '' : 'tracking')
    ..aOS(3, _omitFieldNames ? '' : 'endorsement')
    ..aOB(4, _omitFieldNames ? '' : 'busy')
    ..aOM<$2.NexusFailure>(5, _omitFieldNames ? '' : 'failure',
        subBuilder: $2.NexusFailure.create)
    ..aOS(6, _omitFieldNames ? '' : 'accountName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusInteractionState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusInteractionState copyWith(
          void Function(ModNexusInteractionState) updates) =>
      super.copyWith((message) => updates(message as ModNexusInteractionState))
          as ModNexusInteractionState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModNexusInteractionState create() => ModNexusInteractionState._();
  @$core.override
  ModNexusInteractionState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModNexusInteractionState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModNexusInteractionState>(create);
  static ModNexusInteractionState? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get revision => $_getI64(0);
  @$pb.TagNumber(1)
  set revision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get tracking => $_getBF(1);
  @$pb.TagNumber(2)
  set tracking($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTracking() => $_has(1);
  @$pb.TagNumber(2)
  void clearTracking() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get endorsement => $_getSZ(2);
  @$pb.TagNumber(3)
  set endorsement($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEndorsement() => $_has(2);
  @$pb.TagNumber(3)
  void clearEndorsement() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get busy => $_getBF(3);
  @$pb.TagNumber(4)
  set busy($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBusy() => $_has(3);
  @$pb.TagNumber(4)
  void clearBusy() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.NexusFailure get failure => $_getN(4);
  @$pb.TagNumber(5)
  set failure($2.NexusFailure value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasFailure() => $_has(4);
  @$pb.TagNumber(5)
  void clearFailure() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.NexusFailure ensureFailure() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get accountName => $_getSZ(5);
  @$pb.TagNumber(6)
  set accountName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAccountName() => $_has(5);
  @$pb.TagNumber(6)
  void clearAccountName() => $_clearField(6);
}

enum ModNexusInteractionsReply_Result { state, failure, notSet }

class ModNexusInteractionsReply extends $pb.GeneratedMessage {
  factory ModNexusInteractionsReply({
    ModNexusInteractionState? state,
    $2.NexusFailure? failure,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (failure != null) result.failure = failure;
    return result;
  }

  ModNexusInteractionsReply._();

  factory ModNexusInteractionsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModNexusInteractionsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModNexusInteractionsReply_Result>
      _ModNexusInteractionsReply_ResultByTag = {
    1: ModNexusInteractionsReply_Result.state,
    2: ModNexusInteractionsReply_Result.failure,
    0: ModNexusInteractionsReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModNexusInteractionsReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ModNexusInteractionState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: ModNexusInteractionState.create)
    ..aOM<$2.NexusFailure>(2, _omitFieldNames ? '' : 'failure',
        subBuilder: $2.NexusFailure.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusInteractionsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModNexusInteractionsReply copyWith(
          void Function(ModNexusInteractionsReply) updates) =>
      super.copyWith((message) => updates(message as ModNexusInteractionsReply))
          as ModNexusInteractionsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModNexusInteractionsReply create() => ModNexusInteractionsReply._();
  @$core.override
  ModNexusInteractionsReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModNexusInteractionsReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModNexusInteractionsReply>(create);
  static ModNexusInteractionsReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ModNexusInteractionsReply_Result whichResult() =>
      _ModNexusInteractionsReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModNexusInteractionState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(ModNexusInteractionState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  ModNexusInteractionState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.NexusFailure get failure => $_getN(1);
  @$pb.TagNumber(2)
  set failure($2.NexusFailure value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFailure() => $_has(1);
  @$pb.TagNumber(2)
  void clearFailure() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.NexusFailure ensureFailure() => $_ensure(1);
}

class ChangeModNexusInteractionRequest extends $pb.GeneratedMessage {
  factory ChangeModNexusInteractionRequest({
    $0.ModNexusReference? reference,
    $fixnum.Int64? revision,
    $core.String? action,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (revision != null) result.revision = revision;
    if (action != null) result.action = action;
    return result;
  }

  ChangeModNexusInteractionRequest._();

  factory ChangeModNexusInteractionRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangeModNexusInteractionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeModNexusInteractionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$0.ModNexusReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: $0.ModNexusReference.create)
    ..aInt64(2, _omitFieldNames ? '' : 'revision')
    ..aOS(3, _omitFieldNames ? '' : 'action')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeModNexusInteractionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeModNexusInteractionRequest copyWith(
          void Function(ChangeModNexusInteractionRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ChangeModNexusInteractionRequest))
          as ChangeModNexusInteractionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeModNexusInteractionRequest create() =>
      ChangeModNexusInteractionRequest._();
  @$core.override
  ChangeModNexusInteractionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChangeModNexusInteractionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeModNexusInteractionRequest>(
          create);
  static ChangeModNexusInteractionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.ModNexusReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($0.ModNexusReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ModNexusReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revision => $_getI64(1);
  @$pb.TagNumber(2)
  set revision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get action => $_getSZ(2);
  @$pb.TagNumber(3)
  set action($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAction() => $_has(2);
  @$pb.TagNumber(3)
  void clearAction() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
