// This is a generated file - do not edit.
//
// Generated from modconductor/v1/plugin_order.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'bethesda_plugins.pb.dart' as $2;
import 'plugin_order.pbenum.dart';
import 'profile_data.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'plugin_order.pbenum.dart';

class ReadPluginOrderRequest extends $pb.GeneratedMessage {
  factory ReadPluginOrderRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? headersId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (headersId != null) result.headersId = headersId;
    return result;
  }

  ReadPluginOrderRequest._();

  factory ReadPluginOrderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadPluginOrderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadPluginOrderRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'headersId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadPluginOrderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadPluginOrderRequest copyWith(
          void Function(ReadPluginOrderRequest) updates) =>
      super.copyWith((message) => updates(message as ReadPluginOrderRequest))
          as ReadPluginOrderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadPluginOrderRequest create() => ReadPluginOrderRequest._();
  @$core.override
  ReadPluginOrderRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadPluginOrderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadPluginOrderRequest>(create);
  static ReadPluginOrderRequest? _defaultInstance;

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
  $core.String get headersId => $_getSZ(2);
  @$pb.TagNumber(3)
  set headersId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeadersId() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeadersId() => $_clearField(3);
}

class PluginOrderSetting extends $pb.GeneratedMessage {
  factory PluginOrderSetting({
    $core.String? name,
    $core.bool? enabled,
    $core.int? lockedIndex,
    $core.bool? required,
    PluginRequiredReason? requiredReason,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (enabled != null) result.enabled = enabled;
    if (lockedIndex != null) result.lockedIndex = lockedIndex;
    if (required != null) result.required = required;
    if (requiredReason != null) result.requiredReason = requiredReason;
    return result;
  }

  PluginOrderSetting._();

  factory PluginOrderSetting.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PluginOrderSetting.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PluginOrderSetting',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..aI(3, _omitFieldNames ? '' : 'lockedIndex')
    ..aOB(4, _omitFieldNames ? '' : 'required')
    ..aE<PluginRequiredReason>(5, _omitFieldNames ? '' : 'requiredReason',
        enumValues: PluginRequiredReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PluginOrderSetting clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PluginOrderSetting copyWith(void Function(PluginOrderSetting) updates) =>
      super.copyWith((message) => updates(message as PluginOrderSetting))
          as PluginOrderSetting;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PluginOrderSetting create() => PluginOrderSetting._();
  @$core.override
  PluginOrderSetting createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PluginOrderSetting getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PluginOrderSetting>(create);
  static PluginOrderSetting? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get lockedIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set lockedIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLockedIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearLockedIndex() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get required => $_getBF(3);
  @$pb.TagNumber(4)
  set required($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRequired() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequired() => $_clearField(4);

  @$pb.TagNumber(5)
  PluginRequiredReason get requiredReason => $_getN(4);
  @$pb.TagNumber(5)
  set requiredReason(PluginRequiredReason value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRequiredReason() => $_has(4);
  @$pb.TagNumber(5)
  void clearRequiredReason() => $_clearField(5);
}

class PluginOrderIssue extends $pb.GeneratedMessage {
  factory PluginOrderIssue({
    $core.String? name,
    $core.String? detail,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (detail != null) result.detail = detail;
    return result;
  }

  PluginOrderIssue._();

  factory PluginOrderIssue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PluginOrderIssue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PluginOrderIssue',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PluginOrderIssue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PluginOrderIssue copyWith(void Function(PluginOrderIssue) updates) =>
      super.copyWith((message) => updates(message as PluginOrderIssue))
          as PluginOrderIssue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PluginOrderIssue create() => PluginOrderIssue._();
  @$core.override
  PluginOrderIssue createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PluginOrderIssue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PluginOrderIssue>(create);
  static PluginOrderIssue? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get detail => $_getSZ(1);
  @$pb.TagNumber(2)
  set detail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDetail() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetail() => $_clearField(2);
}

class ProfilePluginOrder extends $pb.GeneratedMessage {
  factory ProfilePluginOrder({
    $1.ProfileDataRef? reference,
    $2.BethesdaPluginSnapshot? headers,
    $core.Iterable<PluginOrderSetting>? entries,
    $core.Iterable<PluginOrderIssue>? issues,
    $core.int? full,
    $core.int? light,
    $core.int? fullLimit,
    $core.bool? saved,
    $core.bool? applied,
    $core.bool? externalChanged,
    $core.bool? pending,
    $core.Iterable<PluginOrderSetting>? unknown,
    $core.String? pendingProblem,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (headers != null) result.headers = headers;
    if (entries != null) result.entries.addAll(entries);
    if (issues != null) result.issues.addAll(issues);
    if (full != null) result.full = full;
    if (light != null) result.light = light;
    if (fullLimit != null) result.fullLimit = fullLimit;
    if (saved != null) result.saved = saved;
    if (applied != null) result.applied = applied;
    if (externalChanged != null) result.externalChanged = externalChanged;
    if (pending != null) result.pending = pending;
    if (unknown != null) result.unknown.addAll(unknown);
    if (pendingProblem != null) result.pendingProblem = pendingProblem;
    return result;
  }

  ProfilePluginOrder._();

  factory ProfilePluginOrder.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfilePluginOrder.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfilePluginOrder',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.ProfileDataRef>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: $1.ProfileDataRef.create)
    ..aOM<$2.BethesdaPluginSnapshot>(2, _omitFieldNames ? '' : 'headers',
        subBuilder: $2.BethesdaPluginSnapshot.create)
    ..pPM<PluginOrderSetting>(3, _omitFieldNames ? '' : 'entries',
        subBuilder: PluginOrderSetting.create)
    ..pPM<PluginOrderIssue>(4, _omitFieldNames ? '' : 'issues',
        subBuilder: PluginOrderIssue.create)
    ..aI(5, _omitFieldNames ? '' : 'full')
    ..aI(6, _omitFieldNames ? '' : 'light')
    ..aI(7, _omitFieldNames ? '' : 'fullLimit')
    ..aOB(8, _omitFieldNames ? '' : 'saved')
    ..aOB(9, _omitFieldNames ? '' : 'applied')
    ..aOB(10, _omitFieldNames ? '' : 'externalChanged')
    ..aOB(11, _omitFieldNames ? '' : 'pending')
    ..pPM<PluginOrderSetting>(12, _omitFieldNames ? '' : 'unknown',
        subBuilder: PluginOrderSetting.create)
    ..aOS(13, _omitFieldNames ? '' : 'pendingProblem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfilePluginOrder clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfilePluginOrder copyWith(void Function(ProfilePluginOrder) updates) =>
      super.copyWith((message) => updates(message as ProfilePluginOrder))
          as ProfilePluginOrder;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfilePluginOrder create() => ProfilePluginOrder._();
  @$core.override
  ProfilePluginOrder createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfilePluginOrder getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfilePluginOrder>(create);
  static ProfilePluginOrder? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ProfileDataRef get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($1.ProfileDataRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ProfileDataRef ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.BethesdaPluginSnapshot get headers => $_getN(1);
  @$pb.TagNumber(2)
  set headers($2.BethesdaPluginSnapshot value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasHeaders() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeaders() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.BethesdaPluginSnapshot ensureHeaders() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<PluginOrderSetting> get entries => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<PluginOrderIssue> get issues => $_getList(3);

  @$pb.TagNumber(5)
  $core.int get full => $_getIZ(4);
  @$pb.TagNumber(5)
  set full($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFull() => $_has(4);
  @$pb.TagNumber(5)
  void clearFull() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get light => $_getIZ(5);
  @$pb.TagNumber(6)
  set light($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLight() => $_has(5);
  @$pb.TagNumber(6)
  void clearLight() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get fullLimit => $_getIZ(6);
  @$pb.TagNumber(7)
  set fullLimit($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFullLimit() => $_has(6);
  @$pb.TagNumber(7)
  void clearFullLimit() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get saved => $_getBF(7);
  @$pb.TagNumber(8)
  set saved($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSaved() => $_has(7);
  @$pb.TagNumber(8)
  void clearSaved() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get applied => $_getBF(8);
  @$pb.TagNumber(9)
  set applied($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasApplied() => $_has(8);
  @$pb.TagNumber(9)
  void clearApplied() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get externalChanged => $_getBF(9);
  @$pb.TagNumber(10)
  set externalChanged($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasExternalChanged() => $_has(9);
  @$pb.TagNumber(10)
  void clearExternalChanged() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get pending => $_getBF(10);
  @$pb.TagNumber(11)
  set pending($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPending() => $_has(10);
  @$pb.TagNumber(11)
  void clearPending() => $_clearField(11);

  @$pb.TagNumber(12)
  $pb.PbList<PluginOrderSetting> get unknown => $_getList(11);

  @$pb.TagNumber(13)
  $core.String get pendingProblem => $_getSZ(12);
  @$pb.TagNumber(13)
  set pendingProblem($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasPendingProblem() => $_has(12);
  @$pb.TagNumber(13)
  void clearPendingProblem() => $_clearField(13);
}

enum ChangePluginOrderRequest_Change { enabled, moveUp, locked, notSet }

class ChangePluginOrderRequest extends $pb.GeneratedMessage {
  factory ChangePluginOrderRequest({
    $1.ProfileDataRef? expected,
    $core.String? headersId,
    $core.Iterable<$core.String>? names,
    $core.bool? enabled,
    $core.bool? moveUp,
    $core.bool? locked,
  }) {
    final result = create();
    if (expected != null) result.expected = expected;
    if (headersId != null) result.headersId = headersId;
    if (names != null) result.names.addAll(names);
    if (enabled != null) result.enabled = enabled;
    if (moveUp != null) result.moveUp = moveUp;
    if (locked != null) result.locked = locked;
    return result;
  }

  ChangePluginOrderRequest._();

  factory ChangePluginOrderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangePluginOrderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ChangePluginOrderRequest_Change>
      _ChangePluginOrderRequest_ChangeByTag = {
    4: ChangePluginOrderRequest_Change.enabled,
    5: ChangePluginOrderRequest_Change.moveUp,
    6: ChangePluginOrderRequest_Change.locked,
    0: ChangePluginOrderRequest_Change.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePluginOrderRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [4, 5, 6])
    ..aOM<$1.ProfileDataRef>(1, _omitFieldNames ? '' : 'expected',
        subBuilder: $1.ProfileDataRef.create)
    ..aOS(2, _omitFieldNames ? '' : 'headersId')
    ..pPS(3, _omitFieldNames ? '' : 'names')
    ..aOB(4, _omitFieldNames ? '' : 'enabled')
    ..aOB(5, _omitFieldNames ? '' : 'moveUp')
    ..aOB(6, _omitFieldNames ? '' : 'locked')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePluginOrderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePluginOrderRequest copyWith(
          void Function(ChangePluginOrderRequest) updates) =>
      super.copyWith((message) => updates(message as ChangePluginOrderRequest))
          as ChangePluginOrderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangePluginOrderRequest create() => ChangePluginOrderRequest._();
  @$core.override
  ChangePluginOrderRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChangePluginOrderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePluginOrderRequest>(create);
  static ChangePluginOrderRequest? _defaultInstance;

  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  ChangePluginOrderRequest_Change whichChange() =>
      _ChangePluginOrderRequest_ChangeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  void clearChange() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.ProfileDataRef get expected => $_getN(0);
  @$pb.TagNumber(1)
  set expected($1.ProfileDataRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasExpected() => $_has(0);
  @$pb.TagNumber(1)
  void clearExpected() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ProfileDataRef ensureExpected() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get headersId => $_getSZ(1);
  @$pb.TagNumber(2)
  set headersId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeadersId() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeadersId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get names => $_getList(2);

  @$pb.TagNumber(4)
  $core.bool get enabled => $_getBF(3);
  @$pb.TagNumber(4)
  set enabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnabled() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get moveUp => $_getBF(4);
  @$pb.TagNumber(5)
  set moveUp($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMoveUp() => $_has(4);
  @$pb.TagNumber(5)
  void clearMoveUp() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get locked => $_getBF(5);
  @$pb.TagNumber(6)
  set locked($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLocked() => $_has(5);
  @$pb.TagNumber(6)
  void clearLocked() => $_clearField(6);
}

class UseGamePluginOrderRequest extends $pb.GeneratedMessage {
  factory UseGamePluginOrderRequest({
    $1.ProfileDataRef? expected,
    $core.String? headersId,
  }) {
    final result = create();
    if (expected != null) result.expected = expected;
    if (headersId != null) result.headersId = headersId;
    return result;
  }

  UseGamePluginOrderRequest._();

  factory UseGamePluginOrderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UseGamePluginOrderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UseGamePluginOrderRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.ProfileDataRef>(1, _omitFieldNames ? '' : 'expected',
        subBuilder: $1.ProfileDataRef.create)
    ..aOS(2, _omitFieldNames ? '' : 'headersId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UseGamePluginOrderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UseGamePluginOrderRequest copyWith(
          void Function(UseGamePluginOrderRequest) updates) =>
      super.copyWith((message) => updates(message as UseGamePluginOrderRequest))
          as UseGamePluginOrderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UseGamePluginOrderRequest create() => UseGamePluginOrderRequest._();
  @$core.override
  UseGamePluginOrderRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UseGamePluginOrderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UseGamePluginOrderRequest>(create);
  static UseGamePluginOrderRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ProfileDataRef get expected => $_getN(0);
  @$pb.TagNumber(1)
  set expected($1.ProfileDataRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasExpected() => $_has(0);
  @$pb.TagNumber(1)
  void clearExpected() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ProfileDataRef ensureExpected() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get headersId => $_getSZ(1);
  @$pb.TagNumber(2)
  set headersId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeadersId() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeadersId() => $_clearField(2);
}

enum PluginOrderReply_Outcome { order, problem, notSet }

class PluginOrderReply extends $pb.GeneratedMessage {
  factory PluginOrderReply({
    ProfilePluginOrder? order,
    $1.ProfileDataProblem? problem,
  }) {
    final result = create();
    if (order != null) result.order = order;
    if (problem != null) result.problem = problem;
    return result;
  }

  PluginOrderReply._();

  factory PluginOrderReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PluginOrderReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PluginOrderReply_Outcome>
      _PluginOrderReply_OutcomeByTag = {
    1: PluginOrderReply_Outcome.order,
    2: PluginOrderReply_Outcome.problem,
    0: PluginOrderReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PluginOrderReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProfilePluginOrder>(1, _omitFieldNames ? '' : 'order',
        subBuilder: ProfilePluginOrder.create)
    ..aOM<$1.ProfileDataProblem>(2, _omitFieldNames ? '' : 'problem',
        subBuilder: $1.ProfileDataProblem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PluginOrderReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PluginOrderReply copyWith(void Function(PluginOrderReply) updates) =>
      super.copyWith((message) => updates(message as PluginOrderReply))
          as PluginOrderReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PluginOrderReply create() => PluginOrderReply._();
  @$core.override
  PluginOrderReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PluginOrderReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PluginOrderReply>(create);
  static PluginOrderReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  PluginOrderReply_Outcome whichOutcome() =>
      _PluginOrderReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfilePluginOrder get order => $_getN(0);
  @$pb.TagNumber(1)
  set order(ProfilePluginOrder value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOrder() => $_has(0);
  @$pb.TagNumber(1)
  void clearOrder() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfilePluginOrder ensureOrder() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ProfileDataProblem get problem => $_getN(1);
  @$pb.TagNumber(2)
  set problem($1.ProfileDataProblem value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ProfileDataProblem ensureProblem() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
