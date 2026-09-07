// This is a generated file - do not edit.
//
// Generated from modconductor/v1/profile_mods.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'mod_library.pb.dart' as $1;
import 'profile_mods.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'profile_mods.pbenum.dart';

class ManagedProfileMod extends $pb.GeneratedMessage {
  factory ManagedProfileMod({
    $core.int? priority,
    $core.bool? enabled,
  }) {
    final result = create();
    if (priority != null) result.priority = priority;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  ManagedProfileMod._();

  factory ManagedProfileMod.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ManagedProfileMod.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ManagedProfileMod',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'priority', fieldType: $pb.PbFieldType.OU3)
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManagedProfileMod clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ManagedProfileMod copyWith(void Function(ManagedProfileMod) updates) =>
      super.copyWith((message) => updates(message as ManagedProfileMod))
          as ManagedProfileMod;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ManagedProfileMod create() => ManagedProfileMod._();
  @$core.override
  ManagedProfileMod createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ManagedProfileMod getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ManagedProfileMod>(create);
  static ManagedProfileMod? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get priority => $_getIZ(0);
  @$pb.TagNumber(1)
  set priority($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPriority() => $_has(0);
  @$pb.TagNumber(1)
  void clearPriority() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);
}

class OrderedProfileMod extends $pb.GeneratedMessage {
  factory OrderedProfileMod({
    $core.int? priority,
  }) {
    final result = create();
    if (priority != null) result.priority = priority;
    return result;
  }

  OrderedProfileMod._();

  factory OrderedProfileMod.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OrderedProfileMod.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OrderedProfileMod',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'priority', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrderedProfileMod clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrderedProfileMod copyWith(void Function(OrderedProfileMod) updates) =>
      super.copyWith((message) => updates(message as OrderedProfileMod))
          as OrderedProfileMod;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OrderedProfileMod create() => OrderedProfileMod._();
  @$core.override
  OrderedProfileMod createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OrderedProfileMod getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OrderedProfileMod>(create);
  static OrderedProfileMod? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get priority => $_getIZ(0);
  @$pb.TagNumber(1)
  set priority($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPriority() => $_has(0);
  @$pb.TagNumber(1)
  void clearPriority() => $_clearField(1);
}

enum ProfileModSelection_State { managed, separator, locked, notSet }

class ProfileModSelection extends $pb.GeneratedMessage {
  factory ProfileModSelection({
    $core.String? modId,
    ManagedProfileMod? managed,
    OrderedProfileMod? separator,
    ProfileModRestriction? locked,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (managed != null) result.managed = managed;
    if (separator != null) result.separator = separator;
    if (locked != null) result.locked = locked;
    return result;
  }

  ProfileModSelection._();

  factory ProfileModSelection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileModSelection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileModSelection_State>
      _ProfileModSelection_StateByTag = {
    2: ProfileModSelection_State.managed,
    3: ProfileModSelection_State.separator,
    4: ProfileModSelection_State.locked,
    0: ProfileModSelection_State.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileModSelection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..aOM<ManagedProfileMod>(2, _omitFieldNames ? '' : 'managed',
        subBuilder: ManagedProfileMod.create)
    ..aOM<OrderedProfileMod>(3, _omitFieldNames ? '' : 'separator',
        subBuilder: OrderedProfileMod.create)
    ..aE<ProfileModRestriction>(4, _omitFieldNames ? '' : 'locked',
        enumValues: ProfileModRestriction.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModSelection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModSelection copyWith(void Function(ProfileModSelection) updates) =>
      super.copyWith((message) => updates(message as ProfileModSelection))
          as ProfileModSelection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileModSelection create() => ProfileModSelection._();
  @$core.override
  ProfileModSelection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileModSelection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileModSelection>(create);
  static ProfileModSelection? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  ProfileModSelection_State whichState() =>
      _ProfileModSelection_StateByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearState() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get modId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModId() => $_clearField(1);

  @$pb.TagNumber(2)
  ManagedProfileMod get managed => $_getN(1);
  @$pb.TagNumber(2)
  set managed(ManagedProfileMod value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasManaged() => $_has(1);
  @$pb.TagNumber(2)
  void clearManaged() => $_clearField(2);
  @$pb.TagNumber(2)
  ManagedProfileMod ensureManaged() => $_ensure(1);

  @$pb.TagNumber(3)
  OrderedProfileMod get separator => $_getN(2);
  @$pb.TagNumber(3)
  set separator(OrderedProfileMod value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSeparator() => $_has(2);
  @$pb.TagNumber(3)
  void clearSeparator() => $_clearField(3);
  @$pb.TagNumber(3)
  OrderedProfileMod ensureSeparator() => $_ensure(2);

  @$pb.TagNumber(4)
  ProfileModRestriction get locked => $_getN(3);
  @$pb.TagNumber(4)
  set locked(ProfileModRestriction value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLocked() => $_has(3);
  @$pb.TagNumber(4)
  void clearLocked() => $_clearField(4);
}

class ProfileModView extends $pb.GeneratedMessage {
  factory ProfileModView({
    $1.InventoryMod? mod,
    ProfileModSelection? selection,
  }) {
    final result = create();
    if (mod != null) result.mod = mod;
    if (selection != null) result.selection = selection;
    return result;
  }

  ProfileModView._();

  factory ProfileModView.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileModView.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileModView',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.InventoryMod>(1, _omitFieldNames ? '' : 'mod',
        subBuilder: $1.InventoryMod.create)
    ..aOM<ProfileModSelection>(2, _omitFieldNames ? '' : 'selection',
        subBuilder: ProfileModSelection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModView clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModView copyWith(void Function(ProfileModView) updates) =>
      super.copyWith((message) => updates(message as ProfileModView))
          as ProfileModView;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileModView create() => ProfileModView._();
  @$core.override
  ProfileModView createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileModView getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileModView>(create);
  static ProfileModView? _defaultInstance;

  @$pb.TagNumber(1)
  $1.InventoryMod get mod => $_getN(0);
  @$pb.TagNumber(1)
  set mod($1.InventoryMod value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMod() => $_has(0);
  @$pb.TagNumber(1)
  void clearMod() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.InventoryMod ensureMod() => $_ensure(0);

  @$pb.TagNumber(2)
  ProfileModSelection get selection => $_getN(1);
  @$pb.TagNumber(2)
  set selection(ProfileModSelection value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSelection() => $_has(1);
  @$pb.TagNumber(2)
  void clearSelection() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileModSelection ensureSelection() => $_ensure(1);
}

class ReadProfileModsRequest extends $pb.GeneratedMessage {
  factory ReadProfileModsRequest({
    $core.String? profileId,
    $core.String? afterModId,
    $fixnum.Int64? expectedRevision,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (afterModId != null) result.afterModId = afterModId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    return result;
  }

  ReadProfileModsRequest._();

  factory ReadProfileModsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadProfileModsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadProfileModsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOS(2, _omitFieldNames ? '' : 'afterModId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadProfileModsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadProfileModsRequest copyWith(
          void Function(ReadProfileModsRequest) updates) =>
      super.copyWith((message) => updates(message as ReadProfileModsRequest))
          as ReadProfileModsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadProfileModsRequest create() => ReadProfileModsRequest._();
  @$core.override
  ReadProfileModsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadProfileModsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadProfileModsRequest>(create);
  static ReadProfileModsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get afterModId => $_getSZ(1);
  @$pb.TagNumber(2)
  set afterModId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAfterModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAfterModId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get expectedRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpectedRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpectedRevision() => $_clearField(3);
}

class ProfileModsPage extends $pb.GeneratedMessage {
  factory ProfileModsPage({
    $fixnum.Int64? revision,
    $core.Iterable<ProfileModView>? entries,
    $core.String? nextModId,
    $core.int? total,
    $core.int? enabledCount,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (entries != null) result.entries.addAll(entries);
    if (nextModId != null) result.nextModId = nextModId;
    if (total != null) result.total = total;
    if (enabledCount != null) result.enabledCount = enabledCount;
    return result;
  }

  ProfileModsPage._();

  factory ProfileModsPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileModsPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileModsPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<ProfileModView>(2, _omitFieldNames ? '' : 'entries',
        subBuilder: ProfileModView.create)
    ..aOS(3, _omitFieldNames ? '' : 'nextModId')
    ..aI(4, _omitFieldNames ? '' : 'total', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'enabledCount',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModsPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModsPage copyWith(void Function(ProfileModsPage) updates) =>
      super.copyWith((message) => updates(message as ProfileModsPage))
          as ProfileModsPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileModsPage create() => ProfileModsPage._();
  @$core.override
  ProfileModsPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileModsPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileModsPage>(create);
  static ProfileModsPage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get revision => $_getI64(0);
  @$pb.TagNumber(1)
  set revision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ProfileModView> get entries => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get nextModId => $_getSZ(2);
  @$pb.TagNumber(3)
  set nextModId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNextModId() => $_has(2);
  @$pb.TagNumber(3)
  void clearNextModId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get total => $_getIZ(3);
  @$pb.TagNumber(4)
  set total($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotal() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotal() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get enabledCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set enabledCount($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnabledCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnabledCount() => $_clearField(5);
}

enum ProfileModsReply_Outcome { page, fault, notSet }

class ProfileModsReply extends $pb.GeneratedMessage {
  factory ProfileModsReply({
    ProfileModsPage? page,
    $1.ModLibraryFault? fault,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (fault != null) result.fault = fault;
    return result;
  }

  ProfileModsReply._();

  factory ProfileModsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileModsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileModsReply_Outcome>
      _ProfileModsReply_OutcomeByTag = {
    1: ProfileModsReply_Outcome.page,
    2: ProfileModsReply_Outcome.fault,
    0: ProfileModsReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileModsReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProfileModsPage>(1, _omitFieldNames ? '' : 'page',
        subBuilder: ProfileModsPage.create)
    ..aOM<$1.ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: $1.ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModsReply copyWith(void Function(ProfileModsReply) updates) =>
      super.copyWith((message) => updates(message as ProfileModsReply))
          as ProfileModsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileModsReply create() => ProfileModsReply._();
  @$core.override
  ProfileModsReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileModsReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileModsReply>(create);
  static ProfileModsReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProfileModsReply_Outcome whichOutcome() =>
      _ProfileModsReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfileModsPage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(ProfileModsPage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileModsPage ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault($1.ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLibraryFault ensureFault() => $_ensure(1);
}

enum ChangeProfileModsRequest_Edit { enabled, move, notSet }

class ChangeProfileModsRequest extends $pb.GeneratedMessage {
  factory ChangeProfileModsRequest({
    $core.String? profileId,
    $fixnum.Int64? expectedRevision,
    $core.Iterable<$core.String>? modIds,
    $core.bool? enabled,
    ProfileModMove? move,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (modIds != null) result.modIds.addAll(modIds);
    if (enabled != null) result.enabled = enabled;
    if (move != null) result.move = move;
    return result;
  }

  ChangeProfileModsRequest._();

  factory ChangeProfileModsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangeProfileModsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ChangeProfileModsRequest_Edit>
      _ChangeProfileModsRequest_EditByTag = {
    4: ChangeProfileModsRequest_Edit.enabled,
    5: ChangeProfileModsRequest_Edit.move,
    0: ChangeProfileModsRequest_Edit.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeProfileModsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [4, 5])
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPS(3, _omitFieldNames ? '' : 'modIds')
    ..aOB(4, _omitFieldNames ? '' : 'enabled')
    ..aE<ProfileModMove>(5, _omitFieldNames ? '' : 'move',
        enumValues: ProfileModMove.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeProfileModsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeProfileModsRequest copyWith(
          void Function(ChangeProfileModsRequest) updates) =>
      super.copyWith((message) => updates(message as ChangeProfileModsRequest))
          as ChangeProfileModsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeProfileModsRequest create() => ChangeProfileModsRequest._();
  @$core.override
  ChangeProfileModsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChangeProfileModsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeProfileModsRequest>(create);
  static ChangeProfileModsRequest? _defaultInstance;

  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  ChangeProfileModsRequest_Edit whichEdit() =>
      _ChangeProfileModsRequest_EditByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearEdit() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get modIds => $_getList(2);

  @$pb.TagNumber(4)
  $core.bool get enabled => $_getBF(3);
  @$pb.TagNumber(4)
  set enabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnabled() => $_clearField(4);

  @$pb.TagNumber(5)
  ProfileModMove get move => $_getN(4);
  @$pb.TagNumber(5)
  set move(ProfileModMove value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasMove() => $_has(4);
  @$pb.TagNumber(5)
  void clearMove() => $_clearField(5);
}

class ProfileModsDelta extends $pb.GeneratedMessage {
  factory ProfileModsDelta({
    $fixnum.Int64? revision,
    $core.Iterable<ProfileModSelection>? changed,
    $core.int? enabledCount,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (changed != null) result.changed.addAll(changed);
    if (enabledCount != null) result.enabledCount = enabledCount;
    return result;
  }

  ProfileModsDelta._();

  factory ProfileModsDelta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileModsDelta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileModsDelta',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<ProfileModSelection>(2, _omitFieldNames ? '' : 'changed',
        subBuilder: ProfileModSelection.create)
    ..aI(3, _omitFieldNames ? '' : 'enabledCount',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModsDelta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModsDelta copyWith(void Function(ProfileModsDelta) updates) =>
      super.copyWith((message) => updates(message as ProfileModsDelta))
          as ProfileModsDelta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileModsDelta create() => ProfileModsDelta._();
  @$core.override
  ProfileModsDelta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileModsDelta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileModsDelta>(create);
  static ProfileModsDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get revision => $_getI64(0);
  @$pb.TagNumber(1)
  set revision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ProfileModSelection> get changed => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get enabledCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set enabledCount($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEnabledCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnabledCount() => $_clearField(3);
}

enum ProfileModsChangeReply_Outcome { delta, fault, notSet }

class ProfileModsChangeReply extends $pb.GeneratedMessage {
  factory ProfileModsChangeReply({
    ProfileModsDelta? delta,
    $1.ModLibraryFault? fault,
  }) {
    final result = create();
    if (delta != null) result.delta = delta;
    if (fault != null) result.fault = fault;
    return result;
  }

  ProfileModsChangeReply._();

  factory ProfileModsChangeReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileModsChangeReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileModsChangeReply_Outcome>
      _ProfileModsChangeReply_OutcomeByTag = {
    1: ProfileModsChangeReply_Outcome.delta,
    2: ProfileModsChangeReply_Outcome.fault,
    0: ProfileModsChangeReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileModsChangeReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProfileModsDelta>(1, _omitFieldNames ? '' : 'delta',
        subBuilder: ProfileModsDelta.create)
    ..aOM<$1.ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: $1.ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModsChangeReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModsChangeReply copyWith(
          void Function(ProfileModsChangeReply) updates) =>
      super.copyWith((message) => updates(message as ProfileModsChangeReply))
          as ProfileModsChangeReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileModsChangeReply create() => ProfileModsChangeReply._();
  @$core.override
  ProfileModsChangeReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileModsChangeReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileModsChangeReply>(create);
  static ProfileModsChangeReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProfileModsChangeReply_Outcome whichOutcome() =>
      _ProfileModsChangeReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfileModsDelta get delta => $_getN(0);
  @$pb.TagNumber(1)
  set delta(ProfileModsDelta value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDelta() => $_has(0);
  @$pb.TagNumber(1)
  void clearDelta() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileModsDelta ensureDelta() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault($1.ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLibraryFault ensureFault() => $_ensure(1);
}

class ReadProfileModRequest extends $pb.GeneratedMessage {
  factory ReadProfileModRequest({
    $core.String? profileId,
    $core.String? modId,
    $fixnum.Int64? expectedRevision,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (modId != null) result.modId = modId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    return result;
  }

  ReadProfileModRequest._();

  factory ReadProfileModRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadProfileModRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadProfileModRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadProfileModRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadProfileModRequest copyWith(
          void Function(ReadProfileModRequest) updates) =>
      super.copyWith((message) => updates(message as ReadProfileModRequest))
          as ReadProfileModRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadProfileModRequest create() => ReadProfileModRequest._();
  @$core.override
  ReadProfileModRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadProfileModRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadProfileModRequest>(create);
  static ReadProfileModRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get expectedRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpectedRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpectedRevision() => $_clearField(3);
}

class ProfileModDetail extends $pb.GeneratedMessage {
  factory ProfileModDetail({
    $fixnum.Int64? revision,
    ProfileModView? entry,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (entry != null) result.entry = entry;
    return result;
  }

  ProfileModDetail._();

  factory ProfileModDetail.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileModDetail.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileModDetail',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<ProfileModView>(2, _omitFieldNames ? '' : 'entry',
        subBuilder: ProfileModView.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModDetail clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModDetail copyWith(void Function(ProfileModDetail) updates) =>
      super.copyWith((message) => updates(message as ProfileModDetail))
          as ProfileModDetail;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileModDetail create() => ProfileModDetail._();
  @$core.override
  ProfileModDetail createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileModDetail getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileModDetail>(create);
  static ProfileModDetail? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get revision => $_getI64(0);
  @$pb.TagNumber(1)
  set revision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  ProfileModView get entry => $_getN(1);
  @$pb.TagNumber(2)
  set entry(ProfileModView value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEntry() => $_has(1);
  @$pb.TagNumber(2)
  void clearEntry() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileModView ensureEntry() => $_ensure(1);
}

enum ProfileModReply_Outcome { detail, fault, notSet }

class ProfileModReply extends $pb.GeneratedMessage {
  factory ProfileModReply({
    ProfileModDetail? detail,
    $1.ModLibraryFault? fault,
  }) {
    final result = create();
    if (detail != null) result.detail = detail;
    if (fault != null) result.fault = fault;
    return result;
  }

  ProfileModReply._();

  factory ProfileModReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileModReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileModReply_Outcome>
      _ProfileModReply_OutcomeByTag = {
    1: ProfileModReply_Outcome.detail,
    2: ProfileModReply_Outcome.fault,
    0: ProfileModReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileModReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProfileModDetail>(1, _omitFieldNames ? '' : 'detail',
        subBuilder: ProfileModDetail.create)
    ..aOM<$1.ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: $1.ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileModReply copyWith(void Function(ProfileModReply) updates) =>
      super.copyWith((message) => updates(message as ProfileModReply))
          as ProfileModReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileModReply create() => ProfileModReply._();
  @$core.override
  ProfileModReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileModReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileModReply>(create);
  static ProfileModReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProfileModReply_Outcome whichOutcome() =>
      _ProfileModReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfileModDetail get detail => $_getN(0);
  @$pb.TagNumber(1)
  set detail(ProfileModDetail value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDetail() => $_has(0);
  @$pb.TagNumber(1)
  void clearDetail() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileModDetail ensureDetail() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault($1.ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLibraryFault ensureFault() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
