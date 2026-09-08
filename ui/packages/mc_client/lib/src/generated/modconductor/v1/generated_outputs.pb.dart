// This is a generated file - do not edit.
//
// Generated from modconductor/v1/generated_outputs.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'generated_outputs.pbenum.dart';
import 'mod_library.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'generated_outputs.pbenum.dart';

class OutputScopeRef extends $pb.GeneratedMessage {
  factory OutputScopeRef({
    $core.String? workspaceId,
    $core.String? contextId,
    $fixnum.Int64? revision,
    $fixnum.Int64? contextRevision,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (contextId != null) result.contextId = contextId;
    if (revision != null) result.revision = revision;
    if (contextRevision != null) result.contextRevision = contextRevision;
    return result;
  }

  OutputScopeRef._();

  factory OutputScopeRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputScopeRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputScopeRef',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'contextId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'contextRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputScopeRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputScopeRef copyWith(void Function(OutputScopeRef) updates) =>
      super.copyWith((message) => updates(message as OutputScopeRef))
          as OutputScopeRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputScopeRef create() => OutputScopeRef._();
  @$core.override
  OutputScopeRef createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputScopeRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputScopeRef>(create);
  static OutputScopeRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get contextId => $_getSZ(1);
  @$pb.TagNumber(2)
  set contextId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContextId() => $_has(1);
  @$pb.TagNumber(2)
  void clearContextId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get revision => $_getI64(2);
  @$pb.TagNumber(3)
  set revision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get contextRevision => $_getI64(3);
  @$pb.TagNumber(4)
  set contextRevision($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContextRevision() => $_has(3);
  @$pb.TagNumber(4)
  void clearContextRevision() => $_clearField(4);
}

class ReadOutputsRequest extends $pb.GeneratedMessage {
  factory ReadOutputsRequest({
    $core.String? workspaceId,
    $core.String? contextId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (contextId != null) result.contextId = contextId;
    return result;
  }

  ReadOutputsRequest._();

  factory ReadOutputsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadOutputsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadOutputsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'contextId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadOutputsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadOutputsRequest copyWith(void Function(ReadOutputsRequest) updates) =>
      super.copyWith((message) => updates(message as ReadOutputsRequest))
          as ReadOutputsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadOutputsRequest create() => ReadOutputsRequest._();
  @$core.override
  ReadOutputsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadOutputsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadOutputsRequest>(create);
  static ReadOutputsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get contextId => $_getSZ(1);
  @$pb.TagNumber(2)
  set contextId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContextId() => $_has(1);
  @$pb.TagNumber(2)
  void clearContextId() => $_clearField(2);
}

class OutputLocation extends $pb.GeneratedMessage {
  factory OutputLocation({
    $core.String? id,
    $core.String? workspaceId,
    $core.String? contextId,
    $core.String? name,
    OutputLocationKind? kind,
    $1.ModLogicalPath? target,
    $fixnum.Int64? revision,
    OutputLocationStatus? status,
    $core.String? physicalPath,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (contextId != null) result.contextId = contextId;
    if (name != null) result.name = name;
    if (kind != null) result.kind = kind;
    if (target != null) result.target = target;
    if (revision != null) result.revision = revision;
    if (status != null) result.status = status;
    if (physicalPath != null) result.physicalPath = physicalPath;
    return result;
  }

  OutputLocation._();

  factory OutputLocation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputLocation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputLocation',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'contextId')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aE<OutputLocationKind>(5, _omitFieldNames ? '' : 'kind',
        enumValues: OutputLocationKind.values)
    ..aOM<$1.ModLogicalPath>(6, _omitFieldNames ? '' : 'target',
        subBuilder: $1.ModLogicalPath.create)
    ..a<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<OutputLocationStatus>(8, _omitFieldNames ? '' : 'status',
        enumValues: OutputLocationStatus.values)
    ..aOS(9, _omitFieldNames ? '' : 'physicalPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputLocation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputLocation copyWith(void Function(OutputLocation) updates) =>
      super.copyWith((message) => updates(message as OutputLocation))
          as OutputLocation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputLocation create() => OutputLocation._();
  @$core.override
  OutputLocation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputLocation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputLocation>(create);
  static OutputLocation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get contextId => $_getSZ(2);
  @$pb.TagNumber(3)
  set contextId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContextId() => $_has(2);
  @$pb.TagNumber(3)
  void clearContextId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  OutputLocationKind get kind => $_getN(4);
  @$pb.TagNumber(5)
  set kind(OutputLocationKind value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasKind() => $_has(4);
  @$pb.TagNumber(5)
  void clearKind() => $_clearField(5);

  @$pb.TagNumber(6)
  $1.ModLogicalPath get target => $_getN(5);
  @$pb.TagNumber(6)
  set target($1.ModLogicalPath value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasTarget() => $_has(5);
  @$pb.TagNumber(6)
  void clearTarget() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.ModLogicalPath ensureTarget() => $_ensure(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get revision => $_getI64(6);
  @$pb.TagNumber(7)
  set revision($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRevision() => $_has(6);
  @$pb.TagNumber(7)
  void clearRevision() => $_clearField(7);

  @$pb.TagNumber(8)
  OutputLocationStatus get status => $_getN(7);
  @$pb.TagNumber(8)
  set status(OutputLocationStatus value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearStatus() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get physicalPath => $_getSZ(8);
  @$pb.TagNumber(9)
  set physicalPath($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPhysicalPath() => $_has(8);
  @$pb.TagNumber(9)
  void clearPhysicalPath() => $_clearField(9);
}

class OutputContext extends $pb.GeneratedMessage {
  factory OutputContext({
    $core.String? id,
    $core.String? installation,
    $core.bool? current,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (installation != null) result.installation = installation;
    if (current != null) result.current = current;
    return result;
  }

  OutputContext._();

  factory OutputContext.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputContext.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputContext',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'installation')
    ..aOB(3, _omitFieldNames ? '' : 'current')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputContext clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputContext copyWith(void Function(OutputContext) updates) =>
      super.copyWith((message) => updates(message as OutputContext))
          as OutputContext;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputContext create() => OutputContext._();
  @$core.override
  OutputContext createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputContext getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputContext>(create);
  static OutputContext? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get installation => $_getSZ(1);
  @$pb.TagNumber(2)
  set installation($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInstallation() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstallation() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get current => $_getBF(2);
  @$pb.TagNumber(3)
  set current($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrent() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrent() => $_clearField(3);
}

class OutputScope extends $pb.GeneratedMessage {
  factory OutputScope({
    OutputScopeRef? reference,
    $core.String? installation,
    $core.Iterable<OutputLocation>? locations,
    $core.Iterable<OutputContext>? contexts,
    $core.Iterable<$core.String>? pendingActions,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (installation != null) result.installation = installation;
    if (locations != null) result.locations.addAll(locations);
    if (contexts != null) result.contexts.addAll(contexts);
    if (pendingActions != null) result.pendingActions.addAll(pendingActions);
    return result;
  }

  OutputScope._();

  factory OutputScope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputScope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputScope',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<OutputScopeRef>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: OutputScopeRef.create)
    ..aOS(2, _omitFieldNames ? '' : 'installation')
    ..pPM<OutputLocation>(3, _omitFieldNames ? '' : 'locations',
        subBuilder: OutputLocation.create)
    ..pPM<OutputContext>(4, _omitFieldNames ? '' : 'contexts',
        subBuilder: OutputContext.create)
    ..pPS(5, _omitFieldNames ? '' : 'pendingActions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputScope clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputScope copyWith(void Function(OutputScope) updates) =>
      super.copyWith((message) => updates(message as OutputScope))
          as OutputScope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputScope create() => OutputScope._();
  @$core.override
  OutputScope createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputScope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputScope>(create);
  static OutputScope? _defaultInstance;

  @$pb.TagNumber(1)
  OutputScopeRef get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(OutputScopeRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputScopeRef ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get installation => $_getSZ(1);
  @$pb.TagNumber(2)
  set installation($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInstallation() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstallation() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<OutputLocation> get locations => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<OutputContext> get contexts => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get pendingActions => $_getList(4);
}

class AddOutputLocationRequest extends $pb.GeneratedMessage {
  factory AddOutputLocationRequest({
    $core.String? id,
    OutputScopeRef? expected,
    $core.String? name,
    OutputLocationKind? kind,
    $1.ModLogicalPath? target,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (expected != null) result.expected = expected;
    if (name != null) result.name = name;
    if (kind != null) result.kind = kind;
    if (target != null) result.target = target;
    return result;
  }

  AddOutputLocationRequest._();

  factory AddOutputLocationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddOutputLocationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddOutputLocationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<OutputScopeRef>(2, _omitFieldNames ? '' : 'expected',
        subBuilder: OutputScopeRef.create)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aE<OutputLocationKind>(4, _omitFieldNames ? '' : 'kind',
        enumValues: OutputLocationKind.values)
    ..aOM<$1.ModLogicalPath>(5, _omitFieldNames ? '' : 'target',
        subBuilder: $1.ModLogicalPath.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddOutputLocationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddOutputLocationRequest copyWith(
          void Function(AddOutputLocationRequest) updates) =>
      super.copyWith((message) => updates(message as AddOutputLocationRequest))
          as AddOutputLocationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddOutputLocationRequest create() => AddOutputLocationRequest._();
  @$core.override
  AddOutputLocationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddOutputLocationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddOutputLocationRequest>(create);
  static AddOutputLocationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  OutputScopeRef get expected => $_getN(1);
  @$pb.TagNumber(2)
  set expected(OutputScopeRef value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpected() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpected() => $_clearField(2);
  @$pb.TagNumber(2)
  OutputScopeRef ensureExpected() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  OutputLocationKind get kind => $_getN(3);
  @$pb.TagNumber(4)
  set kind(OutputLocationKind value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);

  @$pb.TagNumber(5)
  $1.ModLogicalPath get target => $_getN(4);
  @$pb.TagNumber(5)
  set target($1.ModLogicalPath value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTarget() => $_has(4);
  @$pb.TagNumber(5)
  void clearTarget() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.ModLogicalPath ensureTarget() => $_ensure(4);
}

class StopOutputLocationRequest extends $pb.GeneratedMessage {
  factory StopOutputLocationRequest({
    $core.String? id,
    $fixnum.Int64? revision,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (revision != null) result.revision = revision;
    return result;
  }

  StopOutputLocationRequest._();

  factory StopOutputLocationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StopOutputLocationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopOutputLocationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopOutputLocationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopOutputLocationRequest copyWith(
          void Function(StopOutputLocationRequest) updates) =>
      super.copyWith((message) => updates(message as StopOutputLocationRequest))
          as StopOutputLocationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StopOutputLocationRequest create() => StopOutputLocationRequest._();
  @$core.override
  StopOutputLocationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StopOutputLocationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopOutputLocationRequest>(create);
  static StopOutputLocationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revision => $_getI64(1);
  @$pb.TagNumber(2)
  set revision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);
}

class ObserveOutputsRequest extends $pb.GeneratedMessage {
  factory ObserveOutputsRequest({
    OutputScopeRef? expected,
  }) {
    final result = create();
    if (expected != null) result.expected = expected;
    return result;
  }

  ObserveOutputsRequest._();

  factory ObserveOutputsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ObserveOutputsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ObserveOutputsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<OutputScopeRef>(1, _omitFieldNames ? '' : 'expected',
        subBuilder: OutputScopeRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObserveOutputsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObserveOutputsRequest copyWith(
          void Function(ObserveOutputsRequest) updates) =>
      super.copyWith((message) => updates(message as ObserveOutputsRequest))
          as ObserveOutputsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ObserveOutputsRequest create() => ObserveOutputsRequest._();
  @$core.override
  ObserveOutputsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ObserveOutputsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ObserveOutputsRequest>(create);
  static ObserveOutputsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  OutputScopeRef get expected => $_getN(0);
  @$pb.TagNumber(1)
  set expected(OutputScopeRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasExpected() => $_has(0);
  @$pb.TagNumber(1)
  void clearExpected() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputScopeRef ensureExpected() => $_ensure(0);
}

class OutputFile extends $pb.GeneratedMessage {
  factory OutputFile({
    $core.String? locationId,
    $1.ModLogicalPath? path,
    OutputFileStatus? status,
    $fixnum.Int64? length,
    $core.String? sha256,
    $fixnum.Int64? observedAtUnixMs,
    $core.String? deploymentId,
  }) {
    final result = create();
    if (locationId != null) result.locationId = locationId;
    if (path != null) result.path = path;
    if (status != null) result.status = status;
    if (length != null) result.length = length;
    if (sha256 != null) result.sha256 = sha256;
    if (observedAtUnixMs != null) result.observedAtUnixMs = observedAtUnixMs;
    if (deploymentId != null) result.deploymentId = deploymentId;
    return result;
  }

  OutputFile._();

  factory OutputFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'locationId')
    ..aOM<$1.ModLogicalPath>(2, _omitFieldNames ? '' : 'path',
        subBuilder: $1.ModLogicalPath.create)
    ..aE<OutputFileStatus>(3, _omitFieldNames ? '' : 'status',
        enumValues: OutputFileStatus.values)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(5, _omitFieldNames ? '' : 'sha256')
    ..aInt64(6, _omitFieldNames ? '' : 'observedAtUnixMs')
    ..aOS(7, _omitFieldNames ? '' : 'deploymentId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputFile copyWith(void Function(OutputFile) updates) =>
      super.copyWith((message) => updates(message as OutputFile)) as OutputFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputFile create() => OutputFile._();
  @$core.override
  OutputFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputFile>(create);
  static OutputFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get locationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set locationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLocationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLocationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.ModLogicalPath get path => $_getN(1);
  @$pb.TagNumber(2)
  set path($1.ModLogicalPath value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLogicalPath ensurePath() => $_ensure(1);

  @$pb.TagNumber(3)
  OutputFileStatus get status => $_getN(2);
  @$pb.TagNumber(3)
  set status(OutputFileStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get length => $_getI64(3);
  @$pb.TagNumber(4)
  set length($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLength() => $_has(3);
  @$pb.TagNumber(4)
  void clearLength() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get sha256 => $_getSZ(4);
  @$pb.TagNumber(5)
  set sha256($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSha256() => $_has(4);
  @$pb.TagNumber(5)
  void clearSha256() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get observedAtUnixMs => $_getI64(5);
  @$pb.TagNumber(6)
  set observedAtUnixMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasObservedAtUnixMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearObservedAtUnixMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get deploymentId => $_getSZ(6);
  @$pb.TagNumber(7)
  set deploymentId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDeploymentId() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeploymentId() => $_clearField(7);
}

class OutputSnapshot extends $pb.GeneratedMessage {
  factory OutputSnapshot({
    $core.String? id,
    OutputScope? scope,
    $fixnum.Int64? observedAtUnixMs,
    $core.int? files,
    $core.int? entries,
    $core.int? unreviewed,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (scope != null) result.scope = scope;
    if (observedAtUnixMs != null) result.observedAtUnixMs = observedAtUnixMs;
    if (files != null) result.files = files;
    if (entries != null) result.entries = entries;
    if (unreviewed != null) result.unreviewed = unreviewed;
    return result;
  }

  OutputSnapshot._();

  factory OutputSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<OutputScope>(2, _omitFieldNames ? '' : 'scope',
        subBuilder: OutputScope.create)
    ..aInt64(3, _omitFieldNames ? '' : 'observedAtUnixMs')
    ..aI(4, _omitFieldNames ? '' : 'files', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'entries', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'unreviewed', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputSnapshot copyWith(void Function(OutputSnapshot) updates) =>
      super.copyWith((message) => updates(message as OutputSnapshot))
          as OutputSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputSnapshot create() => OutputSnapshot._();
  @$core.override
  OutputSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputSnapshot>(create);
  static OutputSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  OutputScope get scope => $_getN(1);
  @$pb.TagNumber(2)
  set scope(OutputScope value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasScope() => $_has(1);
  @$pb.TagNumber(2)
  void clearScope() => $_clearField(2);
  @$pb.TagNumber(2)
  OutputScope ensureScope() => $_ensure(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get observedAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set observedAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasObservedAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearObservedAtUnixMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get files => $_getIZ(3);
  @$pb.TagNumber(4)
  set files($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFiles() => $_has(3);
  @$pb.TagNumber(4)
  void clearFiles() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get entries => $_getIZ(4);
  @$pb.TagNumber(5)
  set entries($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEntries() => $_has(4);
  @$pb.TagNumber(5)
  void clearEntries() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get unreviewed => $_getIZ(5);
  @$pb.TagNumber(6)
  set unreviewed($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUnreviewed() => $_has(5);
  @$pb.TagNumber(6)
  void clearUnreviewed() => $_clearField(6);
}

class OutputPageRequest extends $pb.GeneratedMessage {
  factory OutputPageRequest({
    $core.String? snapshotId,
    $core.String? cursor,
    $core.String? filter,
    OutputLocationKind? kind,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (cursor != null) result.cursor = cursor;
    if (filter != null) result.filter = filter;
    if (kind != null) result.kind = kind;
    return result;
  }

  OutputPageRequest._();

  factory OutputPageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputPageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputPageRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..aOS(2, _omitFieldNames ? '' : 'cursor')
    ..aOS(3, _omitFieldNames ? '' : 'filter')
    ..aE<OutputLocationKind>(4, _omitFieldNames ? '' : 'kind',
        enumValues: OutputLocationKind.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPageRequest copyWith(void Function(OutputPageRequest) updates) =>
      super.copyWith((message) => updates(message as OutputPageRequest))
          as OutputPageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputPageRequest create() => OutputPageRequest._();
  @$core.override
  OutputPageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputPageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputPageRequest>(create);
  static OutputPageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get cursor => $_getSZ(1);
  @$pb.TagNumber(2)
  set cursor($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCursor() => $_has(1);
  @$pb.TagNumber(2)
  void clearCursor() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get filter => $_getSZ(2);
  @$pb.TagNumber(3)
  set filter($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilter() => $_clearField(3);

  @$pb.TagNumber(4)
  OutputLocationKind get kind => $_getN(3);
  @$pb.TagNumber(4)
  set kind(OutputLocationKind value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);
}

class OutputPage extends $pb.GeneratedMessage {
  factory OutputPage({
    OutputSnapshot? snapshot,
    $core.Iterable<OutputFile>? entries,
    $core.int? matching,
    $core.String? nextCursor,
    $core.int? files,
    $core.int? unreviewed,
  }) {
    final result = create();
    if (snapshot != null) result.snapshot = snapshot;
    if (entries != null) result.entries.addAll(entries);
    if (matching != null) result.matching = matching;
    if (nextCursor != null) result.nextCursor = nextCursor;
    if (files != null) result.files = files;
    if (unreviewed != null) result.unreviewed = unreviewed;
    return result;
  }

  OutputPage._();

  factory OutputPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<OutputSnapshot>(1, _omitFieldNames ? '' : 'snapshot',
        subBuilder: OutputSnapshot.create)
    ..pPM<OutputFile>(2, _omitFieldNames ? '' : 'entries',
        subBuilder: OutputFile.create)
    ..aI(3, _omitFieldNames ? '' : 'matching', fieldType: $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'nextCursor')
    ..aI(5, _omitFieldNames ? '' : 'files', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'unreviewed', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPage copyWith(void Function(OutputPage) updates) =>
      super.copyWith((message) => updates(message as OutputPage)) as OutputPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputPage create() => OutputPage._();
  @$core.override
  OutputPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputPage>(create);
  static OutputPage? _defaultInstance;

  @$pb.TagNumber(1)
  OutputSnapshot get snapshot => $_getN(0);
  @$pb.TagNumber(1)
  set snapshot(OutputSnapshot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshot() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputSnapshot ensureSnapshot() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<OutputFile> get entries => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get matching => $_getIZ(2);
  @$pb.TagNumber(3)
  set matching($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMatching() => $_has(2);
  @$pb.TagNumber(3)
  void clearMatching() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get nextCursor => $_getSZ(3);
  @$pb.TagNumber(4)
  set nextCursor($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNextCursor() => $_has(3);
  @$pb.TagNumber(4)
  void clearNextCursor() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get files => $_getIZ(4);
  @$pb.TagNumber(5)
  set files($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFiles() => $_has(4);
  @$pb.TagNumber(5)
  void clearFiles() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get unreviewed => $_getIZ(5);
  @$pb.TagNumber(6)
  set unreviewed($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUnreviewed() => $_has(5);
  @$pb.TagNumber(6)
  void clearUnreviewed() => $_clearField(6);
}

class OutputSelection extends $pb.GeneratedMessage {
  factory OutputSelection({
    $core.String? locationId,
    $1.ModLogicalPath? path,
  }) {
    final result = create();
    if (locationId != null) result.locationId = locationId;
    if (path != null) result.path = path;
    return result;
  }

  OutputSelection._();

  factory OutputSelection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputSelection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputSelection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'locationId')
    ..aOM<$1.ModLogicalPath>(2, _omitFieldNames ? '' : 'path',
        subBuilder: $1.ModLogicalPath.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputSelection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputSelection copyWith(void Function(OutputSelection) updates) =>
      super.copyWith((message) => updates(message as OutputSelection))
          as OutputSelection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputSelection create() => OutputSelection._();
  @$core.override
  OutputSelection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputSelection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputSelection>(create);
  static OutputSelection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get locationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set locationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLocationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLocationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.ModLogicalPath get path => $_getN(1);
  @$pb.TagNumber(2)
  set path($1.ModLogicalPath value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLogicalPath ensurePath() => $_ensure(1);
}

class ExistingOutputMod extends $pb.GeneratedMessage {
  factory ExistingOutputMod({
    $core.String? modId,
    $fixnum.Int64? revision,
    $core.String? versionLabel,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (revision != null) result.revision = revision;
    if (versionLabel != null) result.versionLabel = versionLabel;
    return result;
  }

  ExistingOutputMod._();

  factory ExistingOutputMod.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExistingOutputMod.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExistingOutputMod',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'versionLabel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExistingOutputMod clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExistingOutputMod copyWith(void Function(ExistingOutputMod) updates) =>
      super.copyWith((message) => updates(message as ExistingOutputMod))
          as ExistingOutputMod;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExistingOutputMod create() => ExistingOutputMod._();
  @$core.override
  ExistingOutputMod createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExistingOutputMod getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExistingOutputMod>(create);
  static ExistingOutputMod? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revision => $_getI64(1);
  @$pb.TagNumber(2)
  set revision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get versionLabel => $_getSZ(2);
  @$pb.TagNumber(3)
  set versionLabel($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersionLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersionLabel() => $_clearField(3);
}

class NewOutputMod extends $pb.GeneratedMessage {
  factory NewOutputMod({
    $core.String? modId,
    $core.String? name,
    $core.String? versionLabel,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (name != null) result.name = name;
    if (versionLabel != null) result.versionLabel = versionLabel;
    return result;
  }

  NewOutputMod._();

  factory NewOutputMod.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NewOutputMod.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NewOutputMod',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'versionLabel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewOutputMod clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewOutputMod copyWith(void Function(NewOutputMod) updates) =>
      super.copyWith((message) => updates(message as NewOutputMod))
          as NewOutputMod;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NewOutputMod create() => NewOutputMod._();
  @$core.override
  NewOutputMod createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NewOutputMod getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NewOutputMod>(create);
  static NewOutputMod? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get versionLabel => $_getSZ(2);
  @$pb.TagNumber(3)
  set versionLabel($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersionLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersionLabel() => $_clearField(3);
}

enum OutputDestination_Destination { existingMod, newMod, notSet }

class OutputDestination extends $pb.GeneratedMessage {
  factory OutputDestination({
    ExistingOutputMod? existingMod,
    NewOutputMod? newMod,
  }) {
    final result = create();
    if (existingMod != null) result.existingMod = existingMod;
    if (newMod != null) result.newMod = newMod;
    return result;
  }

  OutputDestination._();

  factory OutputDestination.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputDestination.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OutputDestination_Destination>
      _OutputDestination_DestinationByTag = {
    1: OutputDestination_Destination.existingMod,
    2: OutputDestination_Destination.newMod,
    0: OutputDestination_Destination.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputDestination',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ExistingOutputMod>(1, _omitFieldNames ? '' : 'existingMod',
        subBuilder: ExistingOutputMod.create)
    ..aOM<NewOutputMod>(2, _omitFieldNames ? '' : 'newMod',
        subBuilder: NewOutputMod.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputDestination clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputDestination copyWith(void Function(OutputDestination) updates) =>
      super.copyWith((message) => updates(message as OutputDestination))
          as OutputDestination;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputDestination create() => OutputDestination._();
  @$core.override
  OutputDestination createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputDestination getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputDestination>(create);
  static OutputDestination? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  OutputDestination_Destination whichDestination() =>
      _OutputDestination_DestinationByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearDestination() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ExistingOutputMod get existingMod => $_getN(0);
  @$pb.TagNumber(1)
  set existingMod(ExistingOutputMod value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasExistingMod() => $_has(0);
  @$pb.TagNumber(1)
  void clearExistingMod() => $_clearField(1);
  @$pb.TagNumber(1)
  ExistingOutputMod ensureExistingMod() => $_ensure(0);

  @$pb.TagNumber(2)
  NewOutputMod get newMod => $_getN(1);
  @$pb.TagNumber(2)
  set newMod(NewOutputMod value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNewMod() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewMod() => $_clearField(2);
  @$pb.TagNumber(2)
  NewOutputMod ensureNewMod() => $_ensure(1);
}

class OutputActionSpec extends $pb.GeneratedMessage {
  factory OutputActionSpec({
    OutputActionKind? kind,
    OutputDestination? destination,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (destination != null) result.destination = destination;
    return result;
  }

  OutputActionSpec._();

  factory OutputActionSpec.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputActionSpec.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputActionSpec',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<OutputActionKind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: OutputActionKind.values)
    ..aOM<OutputDestination>(2, _omitFieldNames ? '' : 'destination',
        subBuilder: OutputDestination.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputActionSpec clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputActionSpec copyWith(void Function(OutputActionSpec) updates) =>
      super.copyWith((message) => updates(message as OutputActionSpec))
          as OutputActionSpec;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputActionSpec create() => OutputActionSpec._();
  @$core.override
  OutputActionSpec createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputActionSpec getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputActionSpec>(create);
  static OutputActionSpec? _defaultInstance;

  @$pb.TagNumber(1)
  OutputActionKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(OutputActionKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  OutputDestination get destination => $_getN(1);
  @$pb.TagNumber(2)
  set destination(OutputDestination value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDestination() => $_has(1);
  @$pb.TagNumber(2)
  void clearDestination() => $_clearField(2);
  @$pb.TagNumber(2)
  OutputDestination ensureDestination() => $_ensure(1);
}

class OutputPromotionRequest extends $pb.GeneratedMessage {
  factory OutputPromotionRequest({
    $core.String? snapshotId,
    $core.Iterable<OutputSelection>? files,
    OutputActionSpec? action,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (files != null) result.files.addAll(files);
    if (action != null) result.action = action;
    return result;
  }

  OutputPromotionRequest._();

  factory OutputPromotionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputPromotionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputPromotionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..pPM<OutputSelection>(2, _omitFieldNames ? '' : 'files',
        subBuilder: OutputSelection.create)
    ..aOM<OutputActionSpec>(3, _omitFieldNames ? '' : 'action',
        subBuilder: OutputActionSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPromotionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPromotionRequest copyWith(
          void Function(OutputPromotionRequest) updates) =>
      super.copyWith((message) => updates(message as OutputPromotionRequest))
          as OutputPromotionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputPromotionRequest create() => OutputPromotionRequest._();
  @$core.override
  OutputPromotionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputPromotionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputPromotionRequest>(create);
  static OutputPromotionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<OutputSelection> get files => $_getList(1);

  @$pb.TagNumber(3)
  OutputActionSpec get action => $_getN(2);
  @$pb.TagNumber(3)
  set action(OutputActionSpec value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAction() => $_has(2);
  @$pb.TagNumber(3)
  void clearAction() => $_clearField(3);
  @$pb.TagNumber(3)
  OutputActionSpec ensureAction() => $_ensure(2);
}

class OutputPromotionPreview extends $pb.GeneratedMessage {
  factory OutputPromotionPreview({
    $core.int? selected,
    $core.Iterable<$1.ModLogicalPath>? replaced,
    $core.String? previousVersion,
    $core.bool? registeredSource,
  }) {
    final result = create();
    if (selected != null) result.selected = selected;
    if (replaced != null) result.replaced.addAll(replaced);
    if (previousVersion != null) result.previousVersion = previousVersion;
    if (registeredSource != null) result.registeredSource = registeredSource;
    return result;
  }

  OutputPromotionPreview._();

  factory OutputPromotionPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputPromotionPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputPromotionPreview',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'selected', fieldType: $pb.PbFieldType.OU3)
    ..pPM<$1.ModLogicalPath>(2, _omitFieldNames ? '' : 'replaced',
        subBuilder: $1.ModLogicalPath.create)
    ..aOS(3, _omitFieldNames ? '' : 'previousVersion')
    ..aOB(4, _omitFieldNames ? '' : 'registeredSource')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPromotionPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPromotionPreview copyWith(
          void Function(OutputPromotionPreview) updates) =>
      super.copyWith((message) => updates(message as OutputPromotionPreview))
          as OutputPromotionPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputPromotionPreview create() => OutputPromotionPreview._();
  @$core.override
  OutputPromotionPreview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputPromotionPreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputPromotionPreview>(create);
  static OutputPromotionPreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get selected => $_getIZ(0);
  @$pb.TagNumber(1)
  set selected($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSelected() => $_has(0);
  @$pb.TagNumber(1)
  void clearSelected() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$1.ModLogicalPath> get replaced => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get previousVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set previousVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPreviousVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreviousVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get registeredSource => $_getBF(3);
  @$pb.TagNumber(4)
  set registeredSource($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRegisteredSource() => $_has(3);
  @$pb.TagNumber(4)
  void clearRegisteredSource() => $_clearField(4);
}

class ApplyOutputActionRequest extends $pb.GeneratedMessage {
  factory ApplyOutputActionRequest({
    $core.String? id,
    $core.String? snapshotId,
    $core.Iterable<OutputSelection>? files,
    OutputActionSpec? action,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (files != null) result.files.addAll(files);
    if (action != null) result.action = action;
    return result;
  }

  ApplyOutputActionRequest._();

  factory ApplyOutputActionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyOutputActionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyOutputActionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'snapshotId')
    ..pPM<OutputSelection>(3, _omitFieldNames ? '' : 'files',
        subBuilder: OutputSelection.create)
    ..aOM<OutputActionSpec>(4, _omitFieldNames ? '' : 'action',
        subBuilder: OutputActionSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyOutputActionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyOutputActionRequest copyWith(
          void Function(ApplyOutputActionRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyOutputActionRequest))
          as ApplyOutputActionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyOutputActionRequest create() => ApplyOutputActionRequest._();
  @$core.override
  ApplyOutputActionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyOutputActionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyOutputActionRequest>(create);
  static ApplyOutputActionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get snapshotId => $_getSZ(1);
  @$pb.TagNumber(2)
  set snapshotId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSnapshotId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSnapshotId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<OutputSelection> get files => $_getList(2);

  @$pb.TagNumber(4)
  OutputActionSpec get action => $_getN(3);
  @$pb.TagNumber(4)
  set action(OutputActionSpec value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAction() => $_has(3);
  @$pb.TagNumber(4)
  void clearAction() => $_clearField(4);
  @$pb.TagNumber(4)
  OutputActionSpec ensureAction() => $_ensure(3);
}

class OutputActionRequest extends $pb.GeneratedMessage {
  factory OutputActionRequest({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  OutputActionRequest._();

  factory OutputActionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputActionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputActionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputActionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputActionRequest copyWith(void Function(OutputActionRequest) updates) =>
      super.copyWith((message) => updates(message as OutputActionRequest))
          as OutputActionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputActionRequest create() => OutputActionRequest._();
  @$core.override
  OutputActionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputActionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputActionRequest>(create);
  static OutputActionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class OutputActionEntry extends $pb.GeneratedMessage {
  factory OutputActionEntry({
    OutputSelection? file,
    OutputDisposition? disposition,
  }) {
    final result = create();
    if (file != null) result.file = file;
    if (disposition != null) result.disposition = disposition;
    return result;
  }

  OutputActionEntry._();

  factory OutputActionEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputActionEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputActionEntry',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<OutputSelection>(1, _omitFieldNames ? '' : 'file',
        subBuilder: OutputSelection.create)
    ..aE<OutputDisposition>(2, _omitFieldNames ? '' : 'disposition',
        enumValues: OutputDisposition.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputActionEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputActionEntry copyWith(void Function(OutputActionEntry) updates) =>
      super.copyWith((message) => updates(message as OutputActionEntry))
          as OutputActionEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputActionEntry create() => OutputActionEntry._();
  @$core.override
  OutputActionEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputActionEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputActionEntry>(create);
  static OutputActionEntry? _defaultInstance;

  @$pb.TagNumber(1)
  OutputSelection get file => $_getN(0);
  @$pb.TagNumber(1)
  set file(OutputSelection value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearFile() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputSelection ensureFile() => $_ensure(0);

  @$pb.TagNumber(2)
  OutputDisposition get disposition => $_getN(1);
  @$pb.TagNumber(2)
  set disposition(OutputDisposition value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDisposition() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisposition() => $_clearField(2);
}

class OutputActionResult extends $pb.GeneratedMessage {
  factory OutputActionResult({
    $core.String? id,
    $core.String? versionId,
    $core.bool? published,
    $core.Iterable<OutputActionEntry>? entries,
    $core.bool? complete,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (versionId != null) result.versionId = versionId;
    if (published != null) result.published = published;
    if (entries != null) result.entries.addAll(entries);
    if (complete != null) result.complete = complete;
    return result;
  }

  OutputActionResult._();

  factory OutputActionResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputActionResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputActionResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'versionId')
    ..aOB(3, _omitFieldNames ? '' : 'published')
    ..pPM<OutputActionEntry>(4, _omitFieldNames ? '' : 'entries',
        subBuilder: OutputActionEntry.create)
    ..aOB(5, _omitFieldNames ? '' : 'complete')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputActionResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputActionResult copyWith(void Function(OutputActionResult) updates) =>
      super.copyWith((message) => updates(message as OutputActionResult))
          as OutputActionResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputActionResult create() => OutputActionResult._();
  @$core.override
  OutputActionResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputActionResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputActionResult>(create);
  static OutputActionResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get versionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set versionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get published => $_getBF(2);
  @$pb.TagNumber(3)
  set published($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPublished() => $_has(2);
  @$pb.TagNumber(3)
  void clearPublished() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<OutputActionEntry> get entries => $_getList(3);

  @$pb.TagNumber(5)
  $core.bool get complete => $_getBF(4);
  @$pb.TagNumber(5)
  set complete($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasComplete() => $_has(4);
  @$pb.TagNumber(5)
  void clearComplete() => $_clearField(5);
}

class OutputFault extends $pb.GeneratedMessage {
  factory OutputFault({
    OutputFaultCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  OutputFault._();

  factory OutputFault.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputFault.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputFault',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<OutputFaultCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: OutputFaultCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputFault clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputFault copyWith(void Function(OutputFault) updates) =>
      super.copyWith((message) => updates(message as OutputFault))
          as OutputFault;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputFault create() => OutputFault._();
  @$core.override
  OutputFault createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputFault getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputFault>(create);
  static OutputFault? _defaultInstance;

  @$pb.TagNumber(1)
  OutputFaultCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(OutputFaultCode value) => $_setField(1, value);
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
}

enum OutputScopeReply_Outcome { scope, fault, notSet }

class OutputScopeReply extends $pb.GeneratedMessage {
  factory OutputScopeReply({
    OutputScope? scope,
    OutputFault? fault,
  }) {
    final result = create();
    if (scope != null) result.scope = scope;
    if (fault != null) result.fault = fault;
    return result;
  }

  OutputScopeReply._();

  factory OutputScopeReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputScopeReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OutputScopeReply_Outcome>
      _OutputScopeReply_OutcomeByTag = {
    1: OutputScopeReply_Outcome.scope,
    2: OutputScopeReply_Outcome.fault,
    0: OutputScopeReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputScopeReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<OutputScope>(1, _omitFieldNames ? '' : 'scope',
        subBuilder: OutputScope.create)
    ..aOM<OutputFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: OutputFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputScopeReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputScopeReply copyWith(void Function(OutputScopeReply) updates) =>
      super.copyWith((message) => updates(message as OutputScopeReply))
          as OutputScopeReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputScopeReply create() => OutputScopeReply._();
  @$core.override
  OutputScopeReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputScopeReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputScopeReply>(create);
  static OutputScopeReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  OutputScopeReply_Outcome whichOutcome() =>
      _OutputScopeReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OutputScope get scope => $_getN(0);
  @$pb.TagNumber(1)
  set scope(OutputScope value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasScope() => $_has(0);
  @$pb.TagNumber(1)
  void clearScope() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputScope ensureScope() => $_ensure(0);

  @$pb.TagNumber(2)
  OutputFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(OutputFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  OutputFault ensureFault() => $_ensure(1);
}

enum OutputLocationReply_Outcome { location, fault, notSet }

class OutputLocationReply extends $pb.GeneratedMessage {
  factory OutputLocationReply({
    OutputLocation? location,
    OutputFault? fault,
  }) {
    final result = create();
    if (location != null) result.location = location;
    if (fault != null) result.fault = fault;
    return result;
  }

  OutputLocationReply._();

  factory OutputLocationReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputLocationReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OutputLocationReply_Outcome>
      _OutputLocationReply_OutcomeByTag = {
    1: OutputLocationReply_Outcome.location,
    2: OutputLocationReply_Outcome.fault,
    0: OutputLocationReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputLocationReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<OutputLocation>(1, _omitFieldNames ? '' : 'location',
        subBuilder: OutputLocation.create)
    ..aOM<OutputFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: OutputFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputLocationReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputLocationReply copyWith(void Function(OutputLocationReply) updates) =>
      super.copyWith((message) => updates(message as OutputLocationReply))
          as OutputLocationReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputLocationReply create() => OutputLocationReply._();
  @$core.override
  OutputLocationReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputLocationReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputLocationReply>(create);
  static OutputLocationReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  OutputLocationReply_Outcome whichOutcome() =>
      _OutputLocationReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OutputLocation get location => $_getN(0);
  @$pb.TagNumber(1)
  set location(OutputLocation value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLocation() => $_has(0);
  @$pb.TagNumber(1)
  void clearLocation() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputLocation ensureLocation() => $_ensure(0);

  @$pb.TagNumber(2)
  OutputFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(OutputFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  OutputFault ensureFault() => $_ensure(1);
}

enum OutputSnapshotReply_Outcome { snapshot, fault, notSet }

class OutputSnapshotReply extends $pb.GeneratedMessage {
  factory OutputSnapshotReply({
    OutputSnapshot? snapshot,
    OutputFault? fault,
  }) {
    final result = create();
    if (snapshot != null) result.snapshot = snapshot;
    if (fault != null) result.fault = fault;
    return result;
  }

  OutputSnapshotReply._();

  factory OutputSnapshotReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputSnapshotReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OutputSnapshotReply_Outcome>
      _OutputSnapshotReply_OutcomeByTag = {
    1: OutputSnapshotReply_Outcome.snapshot,
    2: OutputSnapshotReply_Outcome.fault,
    0: OutputSnapshotReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputSnapshotReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<OutputSnapshot>(1, _omitFieldNames ? '' : 'snapshot',
        subBuilder: OutputSnapshot.create)
    ..aOM<OutputFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: OutputFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputSnapshotReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputSnapshotReply copyWith(void Function(OutputSnapshotReply) updates) =>
      super.copyWith((message) => updates(message as OutputSnapshotReply))
          as OutputSnapshotReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputSnapshotReply create() => OutputSnapshotReply._();
  @$core.override
  OutputSnapshotReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputSnapshotReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputSnapshotReply>(create);
  static OutputSnapshotReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  OutputSnapshotReply_Outcome whichOutcome() =>
      _OutputSnapshotReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OutputSnapshot get snapshot => $_getN(0);
  @$pb.TagNumber(1)
  set snapshot(OutputSnapshot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshot() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputSnapshot ensureSnapshot() => $_ensure(0);

  @$pb.TagNumber(2)
  OutputFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(OutputFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  OutputFault ensureFault() => $_ensure(1);
}

enum OutputPageReply_Outcome { page, fault, notSet }

class OutputPageReply extends $pb.GeneratedMessage {
  factory OutputPageReply({
    OutputPage? page,
    OutputFault? fault,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (fault != null) result.fault = fault;
    return result;
  }

  OutputPageReply._();

  factory OutputPageReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputPageReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OutputPageReply_Outcome>
      _OutputPageReply_OutcomeByTag = {
    1: OutputPageReply_Outcome.page,
    2: OutputPageReply_Outcome.fault,
    0: OutputPageReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputPageReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<OutputPage>(1, _omitFieldNames ? '' : 'page',
        subBuilder: OutputPage.create)
    ..aOM<OutputFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: OutputFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPageReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPageReply copyWith(void Function(OutputPageReply) updates) =>
      super.copyWith((message) => updates(message as OutputPageReply))
          as OutputPageReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputPageReply create() => OutputPageReply._();
  @$core.override
  OutputPageReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputPageReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputPageReply>(create);
  static OutputPageReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  OutputPageReply_Outcome whichOutcome() =>
      _OutputPageReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OutputPage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(OutputPage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputPage ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  OutputFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(OutputFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  OutputFault ensureFault() => $_ensure(1);
}

enum OutputPromotionReply_Outcome { preview, fault, notSet }

class OutputPromotionReply extends $pb.GeneratedMessage {
  factory OutputPromotionReply({
    OutputPromotionPreview? preview,
    OutputFault? fault,
  }) {
    final result = create();
    if (preview != null) result.preview = preview;
    if (fault != null) result.fault = fault;
    return result;
  }

  OutputPromotionReply._();

  factory OutputPromotionReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputPromotionReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OutputPromotionReply_Outcome>
      _OutputPromotionReply_OutcomeByTag = {
    1: OutputPromotionReply_Outcome.preview,
    2: OutputPromotionReply_Outcome.fault,
    0: OutputPromotionReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputPromotionReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<OutputPromotionPreview>(1, _omitFieldNames ? '' : 'preview',
        subBuilder: OutputPromotionPreview.create)
    ..aOM<OutputFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: OutputFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPromotionReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputPromotionReply copyWith(void Function(OutputPromotionReply) updates) =>
      super.copyWith((message) => updates(message as OutputPromotionReply))
          as OutputPromotionReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputPromotionReply create() => OutputPromotionReply._();
  @$core.override
  OutputPromotionReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputPromotionReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputPromotionReply>(create);
  static OutputPromotionReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  OutputPromotionReply_Outcome whichOutcome() =>
      _OutputPromotionReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OutputPromotionPreview get preview => $_getN(0);
  @$pb.TagNumber(1)
  set preview(OutputPromotionPreview value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreview() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreview() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputPromotionPreview ensurePreview() => $_ensure(0);

  @$pb.TagNumber(2)
  OutputFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(OutputFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  OutputFault ensureFault() => $_ensure(1);
}

enum OutputActionReply_Outcome { result, fault, notSet }

class OutputActionReply extends $pb.GeneratedMessage {
  factory OutputActionReply({
    OutputActionResult? result,
    OutputFault? fault,
  }) {
    final result$ = create();
    if (result != null) result$.result = result;
    if (fault != null) result$.fault = fault;
    return result$;
  }

  OutputActionReply._();

  factory OutputActionReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputActionReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OutputActionReply_Outcome>
      _OutputActionReply_OutcomeByTag = {
    1: OutputActionReply_Outcome.result,
    2: OutputActionReply_Outcome.fault,
    0: OutputActionReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputActionReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<OutputActionResult>(1, _omitFieldNames ? '' : 'result',
        subBuilder: OutputActionResult.create)
    ..aOM<OutputFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: OutputFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputActionReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputActionReply copyWith(void Function(OutputActionReply) updates) =>
      super.copyWith((message) => updates(message as OutputActionReply))
          as OutputActionReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputActionReply create() => OutputActionReply._();
  @$core.override
  OutputActionReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputActionReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputActionReply>(create);
  static OutputActionReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  OutputActionReply_Outcome whichOutcome() =>
      _OutputActionReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OutputActionResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(OutputActionResult value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputActionResult ensureResult() => $_ensure(0);

  @$pb.TagNumber(2)
  OutputFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(OutputFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  OutputFault ensureFault() => $_ensure(1);
}

class OutputProgress extends $pb.GeneratedMessage {
  factory OutputProgress({
    $core.int? files,
    $fixnum.Int64? bytes,
  }) {
    final result = create();
    if (files != null) result.files = files;
    if (bytes != null) result.bytes = bytes;
    return result;
  }

  OutputProgress._();

  factory OutputProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputProgress',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'files', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputProgress copyWith(void Function(OutputProgress) updates) =>
      super.copyWith((message) => updates(message as OutputProgress))
          as OutputProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputProgress create() => OutputProgress._();
  @$core.override
  OutputProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputProgress>(create);
  static OutputProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get files => $_getIZ(0);
  @$pb.TagNumber(1)
  set files($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFiles() => $_has(0);
  @$pb.TagNumber(1)
  void clearFiles() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytes => $_getI64(1);
  @$pb.TagNumber(2)
  set bytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytes() => $_clearField(2);
}

enum OutputLoadEvent_Event { progress, finished, notSet }

class OutputLoadEvent extends $pb.GeneratedMessage {
  factory OutputLoadEvent({
    OutputProgress? progress,
    OutputSnapshotReply? finished,
  }) {
    final result = create();
    if (progress != null) result.progress = progress;
    if (finished != null) result.finished = finished;
    return result;
  }

  OutputLoadEvent._();

  factory OutputLoadEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OutputLoadEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OutputLoadEvent_Event>
      _OutputLoadEvent_EventByTag = {
    1: OutputLoadEvent_Event.progress,
    2: OutputLoadEvent_Event.finished,
    0: OutputLoadEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OutputLoadEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<OutputProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: OutputProgress.create)
    ..aOM<OutputSnapshotReply>(2, _omitFieldNames ? '' : 'finished',
        subBuilder: OutputSnapshotReply.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputLoadEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutputLoadEvent copyWith(void Function(OutputLoadEvent) updates) =>
      super.copyWith((message) => updates(message as OutputLoadEvent))
          as OutputLoadEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutputLoadEvent create() => OutputLoadEvent._();
  @$core.override
  OutputLoadEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OutputLoadEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OutputLoadEvent>(create);
  static OutputLoadEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  OutputLoadEvent_Event whichEvent() =>
      _OutputLoadEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OutputProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(OutputProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  OutputProgress ensureProgress() => $_ensure(0);

  @$pb.TagNumber(2)
  OutputSnapshotReply get finished => $_getN(1);
  @$pb.TagNumber(2)
  set finished(OutputSnapshotReply value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFinished() => $_has(1);
  @$pb.TagNumber(2)
  void clearFinished() => $_clearField(2);
  @$pb.TagNumber(2)
  OutputSnapshotReply ensureFinished() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
