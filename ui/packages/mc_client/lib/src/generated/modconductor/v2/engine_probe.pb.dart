// This is a generated file - do not edit.
//
// Generated from modconductor/v2/engine_probe.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'engine_probe.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'engine_probe.pbenum.dart';

class StateRequest extends $pb.GeneratedMessage {
  factory StateRequest({
    $core.int? protocolMajor,
  }) {
    final result = create();
    if (protocolMajor != null) result.protocolMajor = protocolMajor;
    return result;
  }

  StateRequest._();

  factory StateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'protocolMajor',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateRequest copyWith(void Function(StateRequest) updates) =>
      super.copyWith((message) => updates(message as StateRequest))
          as StateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StateRequest create() => StateRequest._();
  @$core.override
  StateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StateRequest>(create);
  static StateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get protocolMajor => $_getIZ(0);
  @$pb.TagNumber(1)
  set protocolMajor($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolMajor() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolMajor() => $_clearField(1);
}

class RuntimeCheckRequest extends $pb.GeneratedMessage {
  factory RuntimeCheckRequest({
    $core.String? operationId,
    $fixnum.Int64? expectedRevision,
    $core.int? heartbeatCount,
  }) {
    final result = create();
    if (operationId != null) result.operationId = operationId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (heartbeatCount != null) result.heartbeatCount = heartbeatCount;
    return result;
  }

  RuntimeCheckRequest._();

  factory RuntimeCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RuntimeCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RuntimeCheckRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operationId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(3, _omitFieldNames ? '' : 'heartbeatCount',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RuntimeCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RuntimeCheckRequest copyWith(void Function(RuntimeCheckRequest) updates) =>
      super.copyWith((message) => updates(message as RuntimeCheckRequest))
          as RuntimeCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RuntimeCheckRequest create() => RuntimeCheckRequest._();
  @$core.override
  RuntimeCheckRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RuntimeCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RuntimeCheckRequest>(create);
  static RuntimeCheckRequest? _defaultInstance;

  /// Canonical UUID without separators. It fixes the complete request across restarts.
  @$pb.TagNumber(1)
  $core.String get operationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set operationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperationId() => $_clearField(1);

  /// Version of committed runtime results, not the progress cursor. Initial version is zero.
  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedRevision() => $_clearField(2);

  /// Required 1..16. This preserves the existing bounded heartbeat connection check.
  @$pb.TagNumber(3)
  $core.int get heartbeatCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set heartbeatCount($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeartbeatCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeartbeatCount() => $_clearField(3);
}

class OperationIdentity extends $pb.GeneratedMessage {
  factory OperationIdentity({
    $core.String? operationId,
  }) {
    final result = create();
    if (operationId != null) result.operationId = operationId;
    return result;
  }

  OperationIdentity._();

  factory OperationIdentity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperationIdentity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperationIdentity',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationIdentity clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationIdentity copyWith(void Function(OperationIdentity) updates) =>
      super.copyWith((message) => updates(message as OperationIdentity))
          as OperationIdentity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperationIdentity create() => OperationIdentity._();
  @$core.override
  OperationIdentity createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperationIdentity getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OperationIdentity>(create);
  static OperationIdentity? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get operationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set operationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperationId() => $_clearField(1);
}

class WatchRequest extends $pb.GeneratedMessage {
  factory WatchRequest({
    $fixnum.Int64? afterCursor,
  }) {
    final result = create();
    if (afterCursor != null) result.afterCursor = afterCursor;
    return result;
  }

  WatchRequest._();

  factory WatchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'afterCursor', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchRequest copyWith(void Function(WatchRequest) updates) =>
      super.copyWith((message) => updates(message as WatchRequest))
          as WatchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchRequest create() => WatchRequest._();
  @$core.override
  WatchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchRequest>(create);
  static WatchRequest? _defaultInstance;

  /// Omission asks for a current snapshot. An old/future cursor explicitly requests resync.
  @$pb.TagNumber(1)
  $fixnum.Int64 get afterCursor => $_getI64(0);
  @$pb.TagNumber(1)
  set afterCursor($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAfterCursor() => $_has(0);
  @$pb.TagNumber(1)
  void clearAfterCursor() => $_clearField(1);
}

class RuntimeInfo extends $pb.GeneratedMessage {
  factory RuntimeInfo({
    $core.String? architecture,
    $core.bool? nativeAot,
    $core.String? sqliteVersion,
  }) {
    final result = create();
    if (architecture != null) result.architecture = architecture;
    if (nativeAot != null) result.nativeAot = nativeAot;
    if (sqliteVersion != null) result.sqliteVersion = sqliteVersion;
    return result;
  }

  RuntimeInfo._();

  factory RuntimeInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RuntimeInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RuntimeInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'architecture')
    ..aOB(2, _omitFieldNames ? '' : 'nativeAot')
    ..aOS(3, _omitFieldNames ? '' : 'sqliteVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RuntimeInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RuntimeInfo copyWith(void Function(RuntimeInfo) updates) =>
      super.copyWith((message) => updates(message as RuntimeInfo))
          as RuntimeInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RuntimeInfo create() => RuntimeInfo._();
  @$core.override
  RuntimeInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RuntimeInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RuntimeInfo>(create);
  static RuntimeInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get architecture => $_getSZ(0);
  @$pb.TagNumber(1)
  set architecture($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasArchitecture() => $_has(0);
  @$pb.TagNumber(1)
  void clearArchitecture() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get nativeAot => $_getBF(1);
  @$pb.TagNumber(2)
  set nativeAot($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNativeAot() => $_has(1);
  @$pb.TagNumber(2)
  void clearNativeAot() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sqliteVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set sqliteVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSqliteVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearSqliteVersion() => $_clearField(3);
}

class OperationSnapshot extends $pb.GeneratedMessage {
  factory OperationSnapshot({
    $core.String? operationId,
    $fixnum.Int64? expectedRevision,
    $core.int? heartbeatCount,
    OperationPhase? phase,
    $core.int? progress,
    RuntimeInfo? result,
    $fixnum.Int64? resultRevision,
  }) {
    final result$ = create();
    if (operationId != null) result$.operationId = operationId;
    if (expectedRevision != null) result$.expectedRevision = expectedRevision;
    if (heartbeatCount != null) result$.heartbeatCount = heartbeatCount;
    if (phase != null) result$.phase = phase;
    if (progress != null) result$.progress = progress;
    if (result != null) result$.result = result;
    if (resultRevision != null) result$.resultRevision = resultRevision;
    return result$;
  }

  OperationSnapshot._();

  factory OperationSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperationSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperationSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operationId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(3, _omitFieldNames ? '' : 'heartbeatCount',
        fieldType: $pb.PbFieldType.OU3)
    ..aE<OperationPhase>(4, _omitFieldNames ? '' : 'phase',
        enumValues: OperationPhase.values)
    ..aI(5, _omitFieldNames ? '' : 'progress', fieldType: $pb.PbFieldType.OU3)
    ..aOM<RuntimeInfo>(6, _omitFieldNames ? '' : 'result',
        subBuilder: RuntimeInfo.create)
    ..a<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'resultRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationSnapshot copyWith(void Function(OperationSnapshot) updates) =>
      super.copyWith((message) => updates(message as OperationSnapshot))
          as OperationSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperationSnapshot create() => OperationSnapshot._();
  @$core.override
  OperationSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperationSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OperationSnapshot>(create);
  static OperationSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get operationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set operationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get heartbeatCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set heartbeatCount($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeartbeatCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeartbeatCount() => $_clearField(3);

  @$pb.TagNumber(4)
  OperationPhase get phase => $_getN(3);
  @$pb.TagNumber(4)
  set phase(OperationPhase value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPhase() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhase() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get progress => $_getIZ(4);
  @$pb.TagNumber(5)
  set progress($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProgress() => $_has(4);
  @$pb.TagNumber(5)
  void clearProgress() => $_clearField(5);

  @$pb.TagNumber(6)
  RuntimeInfo get result => $_getN(5);
  @$pb.TagNumber(6)
  set result(RuntimeInfo value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasResult() => $_has(5);
  @$pb.TagNumber(6)
  void clearResult() => $_clearField(6);
  @$pb.TagNumber(6)
  RuntimeInfo ensureResult() => $_ensure(5);

  /// Nonzero only for a completed result. Replay and cancellation do not advance it.
  @$pb.TagNumber(7)
  $fixnum.Int64 get resultRevision => $_getI64(6);
  @$pb.TagNumber(7)
  set resultRevision($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasResultRevision() => $_has(6);
  @$pb.TagNumber(7)
  void clearResultRevision() => $_clearField(7);
}

class OperationChange extends $pb.GeneratedMessage {
  factory OperationChange({
    $fixnum.Int64? cursor,
    OperationSnapshot? operation,
  }) {
    final result = create();
    if (cursor != null) result.cursor = cursor;
    if (operation != null) result.operation = operation;
    return result;
  }

  OperationChange._();

  factory OperationChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperationChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperationChange',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'cursor', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<OperationSnapshot>(2, _omitFieldNames ? '' : 'operation',
        subBuilder: OperationSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationChange copyWith(void Function(OperationChange) updates) =>
      super.copyWith((message) => updates(message as OperationChange))
          as OperationChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperationChange create() => OperationChange._();
  @$core.override
  OperationChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperationChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OperationChange>(create);
  static OperationChange? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get cursor => $_getI64(0);
  @$pb.TagNumber(1)
  set cursor($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCursor() => $_has(0);
  @$pb.TagNumber(1)
  void clearCursor() => $_clearField(1);

  @$pb.TagNumber(2)
  OperationSnapshot get operation => $_getN(1);
  @$pb.TagNumber(2)
  set operation(OperationSnapshot value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperation() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperation() => $_clearField(2);
  @$pb.TagNumber(2)
  OperationSnapshot ensureOperation() => $_ensure(1);
}

class OperationBatch extends $pb.GeneratedMessage {
  factory OperationBatch({
    $fixnum.Int64? cursor,
    $fixnum.Int64? revision,
    $core.bool? resyncRequired,
    $core.bool? hasSnapshot,
    $core.Iterable<OperationSnapshot>? snapshot,
    $core.Iterable<OperationChange>? changes,
  }) {
    final result = create();
    if (cursor != null) result.cursor = cursor;
    if (revision != null) result.revision = revision;
    if (resyncRequired != null) result.resyncRequired = resyncRequired;
    if (hasSnapshot != null) result.hasSnapshot = hasSnapshot;
    if (snapshot != null) result.snapshot.addAll(snapshot);
    if (changes != null) result.changes.addAll(changes);
    return result;
  }

  OperationBatch._();

  factory OperationBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperationBatch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperationBatch',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'cursor', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(3, _omitFieldNames ? '' : 'resyncRequired')
    ..aOB(4, _omitFieldNames ? '' : 'hasSnapshot')
    ..pPM<OperationSnapshot>(5, _omitFieldNames ? '' : 'snapshot',
        subBuilder: OperationSnapshot.create)
    ..pPM<OperationChange>(6, _omitFieldNames ? '' : 'changes',
        subBuilder: OperationChange.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationBatch copyWith(void Function(OperationBatch) updates) =>
      super.copyWith((message) => updates(message as OperationBatch))
          as OperationBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperationBatch create() => OperationBatch._();
  @$core.override
  OperationBatch createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperationBatch getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OperationBatch>(create);
  static OperationBatch? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get cursor => $_getI64(0);
  @$pb.TagNumber(1)
  set cursor($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCursor() => $_has(0);
  @$pb.TagNumber(1)
  void clearCursor() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get revision => $_getI64(1);
  @$pb.TagNumber(2)
  set revision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get resyncRequired => $_getBF(2);
  @$pb.TagNumber(3)
  set resyncRequired($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasResyncRequired() => $_has(2);
  @$pb.TagNumber(3)
  void clearResyncRequired() => $_clearField(3);

  /// Initial/reconnect or gap response. Latest 16 operations; older IDs remain queryable.
  @$pb.TagNumber(4)
  $core.bool get hasSnapshot => $_getBF(3);
  @$pb.TagNumber(4)
  set hasSnapshot($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHasSnapshot() => $_has(3);
  @$pb.TagNumber(4)
  void clearHasSnapshot() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<OperationSnapshot> get snapshot => $_getList(4);

  /// At most 16 ordered changes. The durable window retains the latest 128 changes.
  @$pb.TagNumber(6)
  $pb.PbList<OperationChange> get changes => $_getList(5);
}

/// Public descriptor on the owned stdout pipe, not a network RPC.
class EngineReady extends $pb.GeneratedMessage {
  factory EngineReady({
    $core.int? protocolMajor,
    $core.int? port,
    $core.List<$core.int>? certificatePem,
  }) {
    final result = create();
    if (protocolMajor != null) result.protocolMajor = protocolMajor;
    if (port != null) result.port = port;
    if (certificatePem != null) result.certificatePem = certificatePem;
    return result;
  }

  EngineReady._();

  factory EngineReady.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EngineReady.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EngineReady',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'protocolMajor',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'certificatePem', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineReady clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineReady copyWith(void Function(EngineReady) updates) =>
      super.copyWith((message) => updates(message as EngineReady))
          as EngineReady;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineReady create() => EngineReady._();
  @$core.override
  EngineReady createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EngineReady getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineReady>(create);
  static EngineReady? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get protocolMajor => $_getIZ(0);
  @$pb.TagNumber(1)
  set protocolMajor($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolMajor() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolMajor() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get port => $_getIZ(1);
  @$pb.TagNumber(2)
  set port($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearPort() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get certificatePem => $_getN(2);
  @$pb.TagNumber(3)
  set certificatePem($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCertificatePem() => $_has(2);
  @$pb.TagNumber(3)
  void clearCertificatePem() => $_clearField(3);
}

class ProfileInfo extends $pb.GeneratedMessage {
  factory ProfileInfo({
    $core.String? profileId,
    $core.String? name,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (name != null) result.name = name;
    return result;
  }

  ProfileInfo._();

  factory ProfileInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileInfo copyWith(void Function(ProfileInfo) updates) =>
      super.copyWith((message) => updates(message as ProfileInfo))
          as ProfileInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileInfo create() => ProfileInfo._();
  @$core.override
  ProfileInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileInfo>(create);
  static ProfileInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class PendingWorkspaceRoot extends $pb.GeneratedMessage {
  factory PendingWorkspaceRoot({
    $fixnum.Int64? receiptRevision,
    WorkspaceRootIssueReason? reason,
  }) {
    final result = create();
    if (receiptRevision != null) result.receiptRevision = receiptRevision;
    if (reason != null) result.reason = reason;
    return result;
  }

  PendingWorkspaceRoot._();

  factory PendingWorkspaceRoot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PendingWorkspaceRoot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PendingWorkspaceRoot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'receiptRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<WorkspaceRootIssueReason>(2, _omitFieldNames ? '' : 'reason',
        enumValues: WorkspaceRootIssueReason.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PendingWorkspaceRoot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PendingWorkspaceRoot copyWith(void Function(PendingWorkspaceRoot) updates) =>
      super.copyWith((message) => updates(message as PendingWorkspaceRoot))
          as PendingWorkspaceRoot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PendingWorkspaceRoot create() => PendingWorkspaceRoot._();
  @$core.override
  PendingWorkspaceRoot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PendingWorkspaceRoot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PendingWorkspaceRoot>(create);
  static PendingWorkspaceRoot? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get receiptRevision => $_getI64(0);
  @$pb.TagNumber(1)
  set receiptRevision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReceiptRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceiptRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  WorkspaceRootIssueReason get reason => $_getN(1);
  @$pb.TagNumber(2)
  set reason(WorkspaceRootIssueReason value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);
}

class WorkspaceInfo extends $pb.GeneratedMessage {
  factory WorkspaceInfo({
    $core.String? workspaceId,
    $core.String? name,
    $core.String? path,
    $fixnum.Int64? revision,
    ProfileInfo? selectedProfile,
    PendingWorkspaceRoot? pendingRoot,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (name != null) result.name = name;
    if (path != null) result.path = path;
    if (revision != null) result.revision = revision;
    if (selectedProfile != null) result.selectedProfile = selectedProfile;
    if (pendingRoot != null) result.pendingRoot = pendingRoot;
    return result;
  }

  WorkspaceInfo._();

  factory WorkspaceInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WorkspaceInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WorkspaceInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'path')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<ProfileInfo>(5, _omitFieldNames ? '' : 'selectedProfile',
        subBuilder: ProfileInfo.create)
    ..aOM<PendingWorkspaceRoot>(6, _omitFieldNames ? '' : 'pendingRoot',
        subBuilder: PendingWorkspaceRoot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspaceInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspaceInfo copyWith(void Function(WorkspaceInfo) updates) =>
      super.copyWith((message) => updates(message as WorkspaceInfo))
          as WorkspaceInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WorkspaceInfo create() => WorkspaceInfo._();
  @$core.override
  WorkspaceInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WorkspaceInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WorkspaceInfo>(create);
  static WorkspaceInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get path => $_getSZ(2);
  @$pb.TagNumber(3)
  set path($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearPath() => $_clearField(3);

  /// Workspace metadata revision; independent of runtime-result and root-receipt revisions.
  @$pb.TagNumber(4)
  $fixnum.Int64 get revision => $_getI64(3);
  @$pb.TagNumber(4)
  set revision($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRevision() => $_has(3);
  @$pb.TagNumber(4)
  void clearRevision() => $_clearField(4);

  @$pb.TagNumber(5)
  ProfileInfo get selectedProfile => $_getN(4);
  @$pb.TagNumber(5)
  set selectedProfile(ProfileInfo value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSelectedProfile() => $_has(4);
  @$pb.TagNumber(5)
  void clearSelectedProfile() => $_clearField(5);
  @$pb.TagNumber(5)
  ProfileInfo ensureSelectedProfile() => $_ensure(4);

  @$pb.TagNumber(6)
  PendingWorkspaceRoot get pendingRoot => $_getN(5);
  @$pb.TagNumber(6)
  set pendingRoot(PendingWorkspaceRoot value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPendingRoot() => $_has(5);
  @$pb.TagNumber(6)
  void clearPendingRoot() => $_clearField(6);
  @$pb.TagNumber(6)
  PendingWorkspaceRoot ensurePendingRoot() => $_ensure(5);
}

class WorkspacePage extends $pb.GeneratedMessage {
  factory WorkspacePage({
    WorkspaceInfo? workspace,
    $core.Iterable<ProfileInfo>? profiles,
    $core.String? nextProfileId,
  }) {
    final result = create();
    if (workspace != null) result.workspace = workspace;
    if (profiles != null) result.profiles.addAll(profiles);
    if (nextProfileId != null) result.nextProfileId = nextProfileId;
    return result;
  }

  WorkspacePage._();

  factory WorkspacePage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WorkspacePage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WorkspacePage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOM<WorkspaceInfo>(1, _omitFieldNames ? '' : 'workspace',
        subBuilder: WorkspaceInfo.create)
    ..pPM<ProfileInfo>(2, _omitFieldNames ? '' : 'profiles',
        subBuilder: ProfileInfo.create)
    ..aOS(3, _omitFieldNames ? '' : 'nextProfileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspacePage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspacePage copyWith(void Function(WorkspacePage) updates) =>
      super.copyWith((message) => updates(message as WorkspacePage))
          as WorkspacePage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WorkspacePage create() => WorkspacePage._();
  @$core.override
  WorkspacePage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WorkspacePage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WorkspacePage>(create);
  static WorkspacePage? _defaultInstance;

  @$pb.TagNumber(1)
  WorkspaceInfo get workspace => $_getN(0);
  @$pb.TagNumber(1)
  set workspace(WorkspaceInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspace() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspace() => $_clearField(1);
  @$pb.TagNumber(1)
  WorkspaceInfo ensureWorkspace() => $_ensure(0);

  /// At most 32 profiles, in stable ID order. A cursor permits the next page.
  @$pb.TagNumber(2)
  $pb.PbList<ProfileInfo> get profiles => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get nextProfileId => $_getSZ(2);
  @$pb.TagNumber(3)
  set nextProfileId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNextProfileId() => $_has(2);
  @$pb.TagNumber(3)
  void clearNextProfileId() => $_clearField(3);
}

class WorkspaceFault extends $pb.GeneratedMessage {
  factory WorkspaceFault({
    WorkspaceFaultCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  WorkspaceFault._();

  factory WorkspaceFault.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WorkspaceFault.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WorkspaceFault',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aE<WorkspaceFaultCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: WorkspaceFaultCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspaceFault clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspaceFault copyWith(void Function(WorkspaceFault) updates) =>
      super.copyWith((message) => updates(message as WorkspaceFault))
          as WorkspaceFault;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WorkspaceFault create() => WorkspaceFault._();
  @$core.override
  WorkspaceFault createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WorkspaceFault getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WorkspaceFault>(create);
  static WorkspaceFault? _defaultInstance;

  @$pb.TagNumber(1)
  WorkspaceFaultCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(WorkspaceFaultCode value) => $_setField(1, value);
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

enum WorkspaceReply_Outcome { page, fault, notSet }

class WorkspaceReply extends $pb.GeneratedMessage {
  factory WorkspaceReply({
    WorkspacePage? page,
    WorkspaceFault? fault,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (fault != null) result.fault = fault;
    return result;
  }

  WorkspaceReply._();

  factory WorkspaceReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WorkspaceReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, WorkspaceReply_Outcome>
      _WorkspaceReply_OutcomeByTag = {
    1: WorkspaceReply_Outcome.page,
    2: WorkspaceReply_Outcome.fault,
    0: WorkspaceReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WorkspaceReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<WorkspacePage>(1, _omitFieldNames ? '' : 'page',
        subBuilder: WorkspacePage.create)
    ..aOM<WorkspaceFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: WorkspaceFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspaceReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkspaceReply copyWith(void Function(WorkspaceReply) updates) =>
      super.copyWith((message) => updates(message as WorkspaceReply))
          as WorkspaceReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WorkspaceReply create() => WorkspaceReply._();
  @$core.override
  WorkspaceReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WorkspaceReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WorkspaceReply>(create);
  static WorkspaceReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  WorkspaceReply_Outcome whichOutcome() =>
      _WorkspaceReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  WorkspacePage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(WorkspacePage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  WorkspacePage ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  WorkspaceFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(WorkspaceFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  WorkspaceFault ensureFault() => $_ensure(1);
}

class CreateWorkspaceRequest extends $pb.GeneratedMessage {
  factory CreateWorkspaceRequest({
    $core.String? workspaceId,
    $core.String? name,
    $core.String? path,
    $fixnum.Int64? expectedRevision,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (name != null) result.name = name;
    if (path != null) result.path = path;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    return result;
  }

  CreateWorkspaceRequest._();

  factory CreateWorkspaceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateWorkspaceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateWorkspaceRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'path')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateWorkspaceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateWorkspaceRequest copyWith(
          void Function(CreateWorkspaceRequest) updates) =>
      super.copyWith((message) => updates(message as CreateWorkspaceRequest))
          as CreateWorkspaceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateWorkspaceRequest create() => CreateWorkspaceRequest._();
  @$core.override
  CreateWorkspaceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateWorkspaceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateWorkspaceRequest>(create);
  static CreateWorkspaceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get path => $_getSZ(2);
  @$pb.TagNumber(3)
  set path($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearPath() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get expectedRevision => $_getI64(3);
  @$pb.TagNumber(4)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExpectedRevision() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpectedRevision() => $_clearField(4);
}

class OpenWorkspaceRequest extends $pb.GeneratedMessage {
  factory OpenWorkspaceRequest({
    $core.String? path,
  }) {
    final result = create();
    if (path != null) result.path = path;
    return result;
  }

  OpenWorkspaceRequest._();

  factory OpenWorkspaceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenWorkspaceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenWorkspaceRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenWorkspaceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenWorkspaceRequest copyWith(void Function(OpenWorkspaceRequest) updates) =>
      super.copyWith((message) => updates(message as OpenWorkspaceRequest))
          as OpenWorkspaceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenWorkspaceRequest create() => OpenWorkspaceRequest._();
  @$core.override
  OpenWorkspaceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenWorkspaceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenWorkspaceRequest>(create);
  static OpenWorkspaceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
}

class ReadWorkspaceRequest extends $pb.GeneratedMessage {
  factory ReadWorkspaceRequest({
    $core.String? workspaceId,
    $core.String? afterProfileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (afterProfileId != null) result.afterProfileId = afterProfileId;
    return result;
  }

  ReadWorkspaceRequest._();

  factory ReadWorkspaceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadWorkspaceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadWorkspaceRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'afterProfileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadWorkspaceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadWorkspaceRequest copyWith(void Function(ReadWorkspaceRequest) updates) =>
      super.copyWith((message) => updates(message as ReadWorkspaceRequest))
          as ReadWorkspaceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadWorkspaceRequest create() => ReadWorkspaceRequest._();
  @$core.override
  ReadWorkspaceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadWorkspaceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadWorkspaceRequest>(create);
  static ReadWorkspaceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get afterProfileId => $_getSZ(1);
  @$pb.TagNumber(2)
  set afterProfileId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAfterProfileId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAfterProfileId() => $_clearField(2);
}

class CloneProfile extends $pb.GeneratedMessage {
  factory CloneProfile({
    $core.String? sourceProfileId,
    ProfileInfo? copy,
  }) {
    final result = create();
    if (sourceProfileId != null) result.sourceProfileId = sourceProfileId;
    if (copy != null) result.copy = copy;
    return result;
  }

  CloneProfile._();

  factory CloneProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloneProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloneProfile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sourceProfileId')
    ..aOM<ProfileInfo>(2, _omitFieldNames ? '' : 'copy',
        subBuilder: ProfileInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloneProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloneProfile copyWith(void Function(CloneProfile) updates) =>
      super.copyWith((message) => updates(message as CloneProfile))
          as CloneProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloneProfile create() => CloneProfile._();
  @$core.override
  CloneProfile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CloneProfile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloneProfile>(create);
  static CloneProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sourceProfileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sourceProfileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  ProfileInfo get copy => $_getN(1);
  @$pb.TagNumber(2)
  set copy(ProfileInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCopy() => $_has(1);
  @$pb.TagNumber(2)
  void clearCopy() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileInfo ensureCopy() => $_ensure(1);
}

enum EditProfileRequest_Edit {
  createProfile,
  cloneProfile,
  renameProfile,
  selectProfileId,
  deleteProfileId,
  notSet
}

class EditProfileRequest extends $pb.GeneratedMessage {
  factory EditProfileRequest({
    $core.String? workspaceId,
    $fixnum.Int64? expectedRevision,
    ProfileInfo? createProfile,
    CloneProfile? cloneProfile,
    ProfileInfo? renameProfile,
    $core.String? selectProfileId,
    $core.String? deleteProfileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (createProfile != null) result.createProfile = createProfile;
    if (cloneProfile != null) result.cloneProfile = cloneProfile;
    if (renameProfile != null) result.renameProfile = renameProfile;
    if (selectProfileId != null) result.selectProfileId = selectProfileId;
    if (deleteProfileId != null) result.deleteProfileId = deleteProfileId;
    return result;
  }

  EditProfileRequest._();

  factory EditProfileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EditProfileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, EditProfileRequest_Edit>
      _EditProfileRequest_EditByTag = {
    3: EditProfileRequest_Edit.createProfile,
    4: EditProfileRequest_Edit.cloneProfile,
    5: EditProfileRequest_Edit.renameProfile,
    6: EditProfileRequest_Edit.selectProfileId,
    7: EditProfileRequest_Edit.deleteProfileId,
    0: EditProfileRequest_Edit.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditProfileRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..oo(0, [3, 4, 5, 6, 7])
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<ProfileInfo>(3, _omitFieldNames ? '' : 'createProfile',
        subBuilder: ProfileInfo.create)
    ..aOM<CloneProfile>(4, _omitFieldNames ? '' : 'cloneProfile',
        subBuilder: CloneProfile.create)
    ..aOM<ProfileInfo>(5, _omitFieldNames ? '' : 'renameProfile',
        subBuilder: ProfileInfo.create)
    ..aOS(6, _omitFieldNames ? '' : 'selectProfileId')
    ..aOS(7, _omitFieldNames ? '' : 'deleteProfileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditProfileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditProfileRequest copyWith(void Function(EditProfileRequest) updates) =>
      super.copyWith((message) => updates(message as EditProfileRequest))
          as EditProfileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EditProfileRequest create() => EditProfileRequest._();
  @$core.override
  EditProfileRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EditProfileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditProfileRequest>(create);
  static EditProfileRequest? _defaultInstance;

  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  EditProfileRequest_Edit whichEdit() =>
      _EditProfileRequest_EditByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  void clearEdit() => $_clearField($_whichOneof(0));

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
  ProfileInfo get createProfile => $_getN(2);
  @$pb.TagNumber(3)
  set createProfile(ProfileInfo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCreateProfile() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreateProfile() => $_clearField(3);
  @$pb.TagNumber(3)
  ProfileInfo ensureCreateProfile() => $_ensure(2);

  @$pb.TagNumber(4)
  CloneProfile get cloneProfile => $_getN(3);
  @$pb.TagNumber(4)
  set cloneProfile(CloneProfile value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCloneProfile() => $_has(3);
  @$pb.TagNumber(4)
  void clearCloneProfile() => $_clearField(4);
  @$pb.TagNumber(4)
  CloneProfile ensureCloneProfile() => $_ensure(3);

  @$pb.TagNumber(5)
  ProfileInfo get renameProfile => $_getN(4);
  @$pb.TagNumber(5)
  set renameProfile(ProfileInfo value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRenameProfile() => $_has(4);
  @$pb.TagNumber(5)
  void clearRenameProfile() => $_clearField(5);
  @$pb.TagNumber(5)
  ProfileInfo ensureRenameProfile() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get selectProfileId => $_getSZ(5);
  @$pb.TagNumber(6)
  set selectProfileId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSelectProfileId() => $_has(5);
  @$pb.TagNumber(6)
  void clearSelectProfileId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get deleteProfileId => $_getSZ(6);
  @$pb.TagNumber(7)
  set deleteProfileId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDeleteProfileId() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeleteProfileId() => $_clearField(7);
}

class ProfileChange extends $pb.GeneratedMessage {
  factory ProfileChange({
    WorkspaceInfo? workspace,
    ProfileInfo? changed,
    $core.String? deletedProfileId,
  }) {
    final result = create();
    if (workspace != null) result.workspace = workspace;
    if (changed != null) result.changed = changed;
    if (deletedProfileId != null) result.deletedProfileId = deletedProfileId;
    return result;
  }

  ProfileChange._();

  factory ProfileChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileChange',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOM<WorkspaceInfo>(1, _omitFieldNames ? '' : 'workspace',
        subBuilder: WorkspaceInfo.create)
    ..aOM<ProfileInfo>(2, _omitFieldNames ? '' : 'changed',
        subBuilder: ProfileInfo.create)
    ..aOS(3, _omitFieldNames ? '' : 'deletedProfileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileChange copyWith(void Function(ProfileChange) updates) =>
      super.copyWith((message) => updates(message as ProfileChange))
          as ProfileChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileChange create() => ProfileChange._();
  @$core.override
  ProfileChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileChange>(create);
  static ProfileChange? _defaultInstance;

  @$pb.TagNumber(1)
  WorkspaceInfo get workspace => $_getN(0);
  @$pb.TagNumber(1)
  set workspace(WorkspaceInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspace() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspace() => $_clearField(1);
  @$pb.TagNumber(1)
  WorkspaceInfo ensureWorkspace() => $_ensure(0);

  @$pb.TagNumber(2)
  ProfileInfo get changed => $_getN(1);
  @$pb.TagNumber(2)
  set changed(ProfileInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasChanged() => $_has(1);
  @$pb.TagNumber(2)
  void clearChanged() => $_clearField(2);
  @$pb.TagNumber(2)
  ProfileInfo ensureChanged() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get deletedProfileId => $_getSZ(2);
  @$pb.TagNumber(3)
  set deletedProfileId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeletedProfileId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeletedProfileId() => $_clearField(3);
}

enum ProfileReply_Outcome { change, fault, notSet }

class ProfileReply extends $pb.GeneratedMessage {
  factory ProfileReply({
    ProfileChange? change,
    WorkspaceFault? fault,
  }) {
    final result = create();
    if (change != null) result.change = change;
    if (fault != null) result.fault = fault;
    return result;
  }

  ProfileReply._();

  factory ProfileReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ProfileReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ProfileReply_Outcome>
      _ProfileReply_OutcomeByTag = {
    1: ProfileReply_Outcome.change,
    2: ProfileReply_Outcome.fault,
    0: ProfileReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ProfileReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ProfileChange>(1, _omitFieldNames ? '' : 'change',
        subBuilder: ProfileChange.create)
    ..aOM<WorkspaceFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: WorkspaceFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProfileReply copyWith(void Function(ProfileReply) updates) =>
      super.copyWith((message) => updates(message as ProfileReply))
          as ProfileReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProfileReply create() => ProfileReply._();
  @$core.override
  ProfileReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ProfileReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ProfileReply>(create);
  static ProfileReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ProfileReply_Outcome whichOutcome() =>
      _ProfileReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ProfileChange get change => $_getN(0);
  @$pb.TagNumber(1)
  set change(ProfileChange value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasChange() => $_has(0);
  @$pb.TagNumber(1)
  void clearChange() => $_clearField(1);
  @$pb.TagNumber(1)
  ProfileChange ensureChange() => $_ensure(0);

  @$pb.TagNumber(2)
  WorkspaceFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(WorkspaceFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  WorkspaceFault ensureFault() => $_ensure(1);
}

class CheckWorkspaceRequest extends $pb.GeneratedMessage {
  factory CheckWorkspaceRequest({
    $core.String? workspaceId,
    $fixnum.Int64? expectedReceiptRevision,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (expectedReceiptRevision != null)
      result.expectedReceiptRevision = expectedReceiptRevision;
    return result;
  }

  CheckWorkspaceRequest._();

  factory CheckWorkspaceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CheckWorkspaceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckWorkspaceRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'expectedReceiptRevision',
        $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckWorkspaceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckWorkspaceRequest copyWith(
          void Function(CheckWorkspaceRequest) updates) =>
      super.copyWith((message) => updates(message as CheckWorkspaceRequest))
          as CheckWorkspaceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckWorkspaceRequest create() => CheckWorkspaceRequest._();
  @$core.override
  CheckWorkspaceRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CheckWorkspaceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckWorkspaceRequest>(create);
  static CheckWorkspaceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedReceiptRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedReceiptRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedReceiptRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedReceiptRevision() => $_clearField(2);
}

class RecentWorkspacesRequest extends $pb.GeneratedMessage {
  factory RecentWorkspacesRequest({
    $core.String? afterWorkspaceId,
  }) {
    final result = create();
    if (afterWorkspaceId != null) result.afterWorkspaceId = afterWorkspaceId;
    return result;
  }

  RecentWorkspacesRequest._();

  factory RecentWorkspacesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RecentWorkspacesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecentWorkspacesRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'afterWorkspaceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentWorkspacesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentWorkspacesRequest copyWith(
          void Function(RecentWorkspacesRequest) updates) =>
      super.copyWith((message) => updates(message as RecentWorkspacesRequest))
          as RecentWorkspacesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecentWorkspacesRequest create() => RecentWorkspacesRequest._();
  @$core.override
  RecentWorkspacesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RecentWorkspacesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecentWorkspacesRequest>(create);
  static RecentWorkspacesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get afterWorkspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set afterWorkspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAfterWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAfterWorkspaceId() => $_clearField(1);
}

class RecentWorkspacesReply extends $pb.GeneratedMessage {
  factory RecentWorkspacesReply({
    $core.Iterable<WorkspaceInfo>? workspaces,
    $core.String? nextWorkspaceId,
  }) {
    final result = create();
    if (workspaces != null) result.workspaces.addAll(workspaces);
    if (nextWorkspaceId != null) result.nextWorkspaceId = nextWorkspaceId;
    return result;
  }

  RecentWorkspacesReply._();

  factory RecentWorkspacesReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RecentWorkspacesReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecentWorkspacesReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..pPM<WorkspaceInfo>(1, _omitFieldNames ? '' : 'workspaces',
        subBuilder: WorkspaceInfo.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextWorkspaceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentWorkspacesReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecentWorkspacesReply copyWith(
          void Function(RecentWorkspacesReply) updates) =>
      super.copyWith((message) => updates(message as RecentWorkspacesReply))
          as RecentWorkspacesReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecentWorkspacesReply create() => RecentWorkspacesReply._();
  @$core.override
  RecentWorkspacesReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RecentWorkspacesReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecentWorkspacesReply>(create);
  static RecentWorkspacesReply? _defaultInstance;

  /// At most 8 registered roots. Presence is not a fresh filesystem validation.
  @$pb.TagNumber(1)
  $pb.PbList<WorkspaceInfo> get workspaces => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextWorkspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextWorkspaceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextWorkspaceId() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
