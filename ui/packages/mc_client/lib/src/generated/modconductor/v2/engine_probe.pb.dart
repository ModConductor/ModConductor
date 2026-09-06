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

class ModLogicalPath extends $pb.GeneratedMessage {
  factory ModLogicalPath({
    $core.Iterable<$core.String>? components,
  }) {
    final result = create();
    if (components != null) result.components.addAll(components);
    return result;
  }

  ModLogicalPath._();

  factory ModLogicalPath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModLogicalPath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModLogicalPath',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'components')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModLogicalPath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModLogicalPath copyWith(void Function(ModLogicalPath) updates) =>
      super.copyWith((message) => updates(message as ModLogicalPath))
          as ModLogicalPath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModLogicalPath create() => ModLogicalPath._();
  @$core.override
  ModLogicalPath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModLogicalPath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModLogicalPath>(create);
  static ModLogicalPath? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get components => $_getList(0);
}

class InventoryModMetadata extends $pb.GeneratedMessage {
  factory InventoryModMetadata({
    $core.String? name,
    $core.String? notes,
    $core.String? comment,
    $core.String? version,
    $core.String? source,
    $core.String? category,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (notes != null) result.notes = notes;
    if (comment != null) result.comment = comment;
    if (version != null) result.version = version;
    if (source != null) result.source = source;
    if (category != null) result.category = category;
    return result;
  }

  InventoryModMetadata._();

  factory InventoryModMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryModMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryModMetadata',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'notes')
    ..aOS(3, _omitFieldNames ? '' : 'comment')
    ..aOS(4, _omitFieldNames ? '' : 'version')
    ..aOS(5, _omitFieldNames ? '' : 'source')
    ..aOS(6, _omitFieldNames ? '' : 'category')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryModMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryModMetadata copyWith(void Function(InventoryModMetadata) updates) =>
      super.copyWith((message) => updates(message as InventoryModMetadata))
          as InventoryModMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryModMetadata create() => InventoryModMetadata._();
  @$core.override
  InventoryModMetadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryModMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryModMetadata>(create);
  static InventoryModMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get notes => $_getSZ(1);
  @$pb.TagNumber(2)
  set notes($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNotes() => $_has(1);
  @$pb.TagNumber(2)
  void clearNotes() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get comment => $_getSZ(2);
  @$pb.TagNumber(3)
  set comment($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasComment() => $_has(2);
  @$pb.TagNumber(3)
  void clearComment() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get version => $_getSZ(3);
  @$pb.TagNumber(4)
  set version($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get source => $_getSZ(4);
  @$pb.TagNumber(5)
  set source($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSource() => $_has(4);
  @$pb.TagNumber(5)
  void clearSource() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get category => $_getSZ(5);
  @$pb.TagNumber(6)
  set category($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCategory() => $_has(5);
  @$pb.TagNumber(6)
  void clearCategory() => $_clearField(6);
}

class InventoryMod extends $pb.GeneratedMessage {
  factory InventoryMod({
    $core.String? modId,
    $core.String? workspaceId,
    InventoryModKind? kind,
    InventoryModMetadata? metadata,
    $fixnum.Int64? revision,
    ModLogicalPath? sourcePath,
    $core.String? currentVersionId,
    ModInventoryStatus? status,
    $core.Iterable<InventoryModAction>? actions,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (kind != null) result.kind = kind;
    if (metadata != null) result.metadata = metadata;
    if (revision != null) result.revision = revision;
    if (sourcePath != null) result.sourcePath = sourcePath;
    if (currentVersionId != null) result.currentVersionId = currentVersionId;
    if (status != null) result.status = status;
    if (actions != null) result.actions.addAll(actions);
    return result;
  }

  InventoryMod._();

  factory InventoryMod.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryMod.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryMod',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aE<InventoryModKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: InventoryModKind.values)
    ..aOM<InventoryModMetadata>(4, _omitFieldNames ? '' : 'metadata',
        subBuilder: InventoryModMetadata.create)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<ModLogicalPath>(6, _omitFieldNames ? '' : 'sourcePath',
        subBuilder: ModLogicalPath.create)
    ..aOS(7, _omitFieldNames ? '' : 'currentVersionId')
    ..aE<ModInventoryStatus>(8, _omitFieldNames ? '' : 'status',
        enumValues: ModInventoryStatus.values)
    ..pc<InventoryModAction>(
        9, _omitFieldNames ? '' : 'actions', $pb.PbFieldType.KE,
        valueOf: InventoryModAction.valueOf,
        enumValues: InventoryModAction.values,
        defaultEnumValue: InventoryModAction.INVENTORY_MOD_ACTION_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryMod clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryMod copyWith(void Function(InventoryMod) updates) =>
      super.copyWith((message) => updates(message as InventoryMod))
          as InventoryMod;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryMod create() => InventoryMod._();
  @$core.override
  InventoryMod createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryMod getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryMod>(create);
  static InventoryMod? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => $_clearField(2);

  @$pb.TagNumber(3)
  InventoryModKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(InventoryModKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  InventoryModMetadata get metadata => $_getN(3);
  @$pb.TagNumber(4)
  set metadata(InventoryModMetadata value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMetadata() => $_has(3);
  @$pb.TagNumber(4)
  void clearMetadata() => $_clearField(4);
  @$pb.TagNumber(4)
  InventoryModMetadata ensureMetadata() => $_ensure(3);

  /// Per-mod metadata/current-version revision, independent of workspace/runtime revisions.
  @$pb.TagNumber(5)
  $fixnum.Int64 get revision => $_getI64(4);
  @$pb.TagNumber(5)
  set revision($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRevision() => $_has(4);
  @$pb.TagNumber(5)
  void clearRevision() => $_clearField(5);

  @$pb.TagNumber(6)
  ModLogicalPath get sourcePath => $_getN(5);
  @$pb.TagNumber(6)
  set sourcePath(ModLogicalPath value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSourcePath() => $_has(5);
  @$pb.TagNumber(6)
  void clearSourcePath() => $_clearField(6);
  @$pb.TagNumber(6)
  ModLogicalPath ensureSourcePath() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.String get currentVersionId => $_getSZ(6);
  @$pb.TagNumber(7)
  set currentVersionId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCurrentVersionId() => $_has(6);
  @$pb.TagNumber(7)
  void clearCurrentVersionId() => $_clearField(7);

  @$pb.TagNumber(8)
  ModInventoryStatus get status => $_getN(7);
  @$pb.TagNumber(8)
  set status(ModInventoryStatus value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearStatus() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<InventoryModAction> get actions => $_getList(8);
}

class ModLibraryFault extends $pb.GeneratedMessage {
  factory ModLibraryFault({
    ModLibraryFaultCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  ModLibraryFault._();

  factory ModLibraryFault.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModLibraryFault.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModLibraryFault',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aE<ModLibraryFaultCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: ModLibraryFaultCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModLibraryFault clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModLibraryFault copyWith(void Function(ModLibraryFault) updates) =>
      super.copyWith((message) => updates(message as ModLibraryFault))
          as ModLibraryFault;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModLibraryFault create() => ModLibraryFault._();
  @$core.override
  ModLibraryFault createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModLibraryFault getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModLibraryFault>(create);
  static ModLibraryFault? _defaultInstance;

  @$pb.TagNumber(1)
  ModLibraryFaultCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ModLibraryFaultCode value) => $_setField(1, value);
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

enum ModReply_Outcome { mod, fault, notSet }

class ModReply extends $pb.GeneratedMessage {
  factory ModReply({
    InventoryMod? mod,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (mod != null) result.mod = mod;
    if (fault != null) result.fault = fault;
    return result;
  }

  ModReply._();

  factory ModReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModReply_Outcome> _ModReply_OutcomeByTag = {
    1: ModReply_Outcome.mod,
    2: ModReply_Outcome.fault,
    0: ModReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<InventoryMod>(1, _omitFieldNames ? '' : 'mod',
        subBuilder: InventoryMod.create)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModReply copyWith(void Function(ModReply) updates) =>
      super.copyWith((message) => updates(message as ModReply)) as ModReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModReply create() => ModReply._();
  @$core.override
  ModReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModReply>(create);
  static ModReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ModReply_Outcome whichOutcome() => _ModReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  InventoryMod get mod => $_getN(0);
  @$pb.TagNumber(1)
  set mod(InventoryMod value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMod() => $_has(0);
  @$pb.TagNumber(1)
  void clearMod() => $_clearField(1);
  @$pb.TagNumber(1)
  InventoryMod ensureMod() => $_ensure(0);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

class RegisterModRequest extends $pb.GeneratedMessage {
  factory RegisterModRequest({
    $core.String? workspaceId,
    $core.String? modId,
    InventoryModMetadata? metadata,
    InventoryModKind? kind,
    ModLogicalPath? sourcePath,
    $core.String? backupVersionId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (modId != null) result.modId = modId;
    if (metadata != null) result.metadata = metadata;
    if (kind != null) result.kind = kind;
    if (sourcePath != null) result.sourcePath = sourcePath;
    if (backupVersionId != null) result.backupVersionId = backupVersionId;
    return result;
  }

  RegisterModRequest._();

  factory RegisterModRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterModRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterModRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..aOM<InventoryModMetadata>(3, _omitFieldNames ? '' : 'metadata',
        subBuilder: InventoryModMetadata.create)
    ..aE<InventoryModKind>(4, _omitFieldNames ? '' : 'kind',
        enumValues: InventoryModKind.values)
    ..aOM<ModLogicalPath>(5, _omitFieldNames ? '' : 'sourcePath',
        subBuilder: ModLogicalPath.create)
    ..aOS(6, _omitFieldNames ? '' : 'backupVersionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterModRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterModRequest copyWith(void Function(RegisterModRequest) updates) =>
      super.copyWith((message) => updates(message as RegisterModRequest))
          as RegisterModRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterModRequest create() => RegisterModRequest._();
  @$core.override
  RegisterModRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterModRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterModRequest>(create);
  static RegisterModRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModId() => $_clearField(2);

  @$pb.TagNumber(3)
  InventoryModMetadata get metadata => $_getN(2);
  @$pb.TagNumber(3)
  set metadata(InventoryModMetadata value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMetadata() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetadata() => $_clearField(3);
  @$pb.TagNumber(3)
  InventoryModMetadata ensureMetadata() => $_ensure(2);

  @$pb.TagNumber(4)
  InventoryModKind get kind => $_getN(3);
  @$pb.TagNumber(4)
  set kind(InventoryModKind value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);

  @$pb.TagNumber(5)
  ModLogicalPath get sourcePath => $_getN(4);
  @$pb.TagNumber(5)
  set sourcePath(ModLogicalPath value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSourcePath() => $_has(4);
  @$pb.TagNumber(5)
  void clearSourcePath() => $_clearField(5);
  @$pb.TagNumber(5)
  ModLogicalPath ensureSourcePath() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get backupVersionId => $_getSZ(5);
  @$pb.TagNumber(6)
  set backupVersionId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBackupVersionId() => $_has(5);
  @$pb.TagNumber(6)
  void clearBackupVersionId() => $_clearField(6);
}

class EditModRequest extends $pb.GeneratedMessage {
  factory EditModRequest({
    $core.String? modId,
    $fixnum.Int64? expectedRevision,
    InventoryModMetadata? metadata,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  EditModRequest._();

  factory EditModRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EditModRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditModRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<InventoryModMetadata>(3, _omitFieldNames ? '' : 'metadata',
        subBuilder: InventoryModMetadata.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditModRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditModRequest copyWith(void Function(EditModRequest) updates) =>
      super.copyWith((message) => updates(message as EditModRequest))
          as EditModRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EditModRequest create() => EditModRequest._();
  @$core.override
  EditModRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EditModRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditModRequest>(create);
  static EditModRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  InventoryModMetadata get metadata => $_getN(2);
  @$pb.TagNumber(3)
  set metadata(InventoryModMetadata value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMetadata() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetadata() => $_clearField(3);
  @$pb.TagNumber(3)
  InventoryModMetadata ensureMetadata() => $_ensure(2);
}

class ReadInventoryRequest extends $pb.GeneratedMessage {
  factory ReadInventoryRequest({
    $core.String? profileId,
    $core.String? afterModId,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (afterModId != null) result.afterModId = afterModId;
    return result;
  }

  ReadInventoryRequest._();

  factory ReadInventoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadInventoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadInventoryRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOS(2, _omitFieldNames ? '' : 'afterModId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadInventoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadInventoryRequest copyWith(void Function(ReadInventoryRequest) updates) =>
      super.copyWith((message) => updates(message as ReadInventoryRequest))
          as ReadInventoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadInventoryRequest create() => ReadInventoryRequest._();
  @$core.override
  ReadInventoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadInventoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadInventoryRequest>(create);
  static ReadInventoryRequest? _defaultInstance;

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
}

class ModInventoryPage extends $pb.GeneratedMessage {
  factory ModInventoryPage({
    $core.Iterable<InventoryMod>? entries,
    $core.String? nextModId,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (nextModId != null) result.nextModId = nextModId;
    return result;
  }

  ModInventoryPage._();

  factory ModInventoryPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModInventoryPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModInventoryPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..pPM<InventoryMod>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: InventoryMod.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextModId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModInventoryPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModInventoryPage copyWith(void Function(ModInventoryPage) updates) =>
      super.copyWith((message) => updates(message as ModInventoryPage))
          as ModInventoryPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModInventoryPage create() => ModInventoryPage._();
  @$core.override
  ModInventoryPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModInventoryPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModInventoryPage>(create);
  static ModInventoryPage? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<InventoryMod> get entries => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextModId => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextModId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextModId() => $_clearField(2);
}

enum InventoryReply_Outcome { page, fault, notSet }

class InventoryReply extends $pb.GeneratedMessage {
  factory InventoryReply({
    ModInventoryPage? page,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (fault != null) result.fault = fault;
    return result;
  }

  InventoryReply._();

  factory InventoryReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, InventoryReply_Outcome>
      _InventoryReply_OutcomeByTag = {
    1: InventoryReply_Outcome.page,
    2: InventoryReply_Outcome.fault,
    0: InventoryReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ModInventoryPage>(1, _omitFieldNames ? '' : 'page',
        subBuilder: ModInventoryPage.create)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryReply copyWith(void Function(InventoryReply) updates) =>
      super.copyWith((message) => updates(message as InventoryReply))
          as InventoryReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryReply create() => InventoryReply._();
  @$core.override
  InventoryReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryReply>(create);
  static InventoryReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  InventoryReply_Outcome whichOutcome() =>
      _InventoryReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModInventoryPage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(ModInventoryPage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  ModInventoryPage ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

class ScanInventoryRequest extends $pb.GeneratedMessage {
  factory ScanInventoryRequest({
    $core.String? workspaceId,
    $core.int? candidateLimit,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (candidateLimit != null) result.candidateLimit = candidateLimit;
    return result;
  }

  ScanInventoryRequest._();

  factory ScanInventoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScanInventoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScanInventoryRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aI(2, _omitFieldNames ? '' : 'candidateLimit',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanInventoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScanInventoryRequest copyWith(void Function(ScanInventoryRequest) updates) =>
      super.copyWith((message) => updates(message as ScanInventoryRequest))
          as ScanInventoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScanInventoryRequest create() => ScanInventoryRequest._();
  @$core.override
  ScanInventoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ScanInventoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScanInventoryRequest>(create);
  static ScanInventoryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get candidateLimit => $_getIZ(1);
  @$pb.TagNumber(2)
  set candidateLimit($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCandidateLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearCandidateLimit() => $_clearField(2);
}

class UnmanagedModPath extends $pb.GeneratedMessage {
  factory UnmanagedModPath({
    ModLogicalPath? path,
    $core.bool? directory,
    $core.bool? unsupported,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (directory != null) result.directory = directory;
    if (unsupported != null) result.unsupported = unsupported;
    return result;
  }

  UnmanagedModPath._();

  factory UnmanagedModPath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UnmanagedModPath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnmanagedModPath',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOM<ModLogicalPath>(1, _omitFieldNames ? '' : 'path',
        subBuilder: ModLogicalPath.create)
    ..aOB(2, _omitFieldNames ? '' : 'directory')
    ..aOB(3, _omitFieldNames ? '' : 'unsupported')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnmanagedModPath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnmanagedModPath copyWith(void Function(UnmanagedModPath) updates) =>
      super.copyWith((message) => updates(message as UnmanagedModPath))
          as UnmanagedModPath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UnmanagedModPath create() => UnmanagedModPath._();
  @$core.override
  UnmanagedModPath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UnmanagedModPath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnmanagedModPath>(create);
  static UnmanagedModPath? _defaultInstance;

  @$pb.TagNumber(1)
  ModLogicalPath get path => $_getN(0);
  @$pb.TagNumber(1)
  set path(ModLogicalPath value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
  @$pb.TagNumber(1)
  ModLogicalPath ensurePath() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get directory => $_getBF(1);
  @$pb.TagNumber(2)
  set directory($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDirectory() => $_has(1);
  @$pb.TagNumber(2)
  void clearDirectory() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get unsupported => $_getBF(2);
  @$pb.TagNumber(3)
  set unsupported($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUnsupported() => $_has(2);
  @$pb.TagNumber(3)
  void clearUnsupported() => $_clearField(3);
}

class ModInventoryScan extends $pb.GeneratedMessage {
  factory ModInventoryScan({
    $core.Iterable<InventoryMod>? entries,
    $core.Iterable<UnmanagedModPath>? unmanaged,
    $core.bool? limited,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (unmanaged != null) result.unmanaged.addAll(unmanaged);
    if (limited != null) result.limited = limited;
    return result;
  }

  ModInventoryScan._();

  factory ModInventoryScan.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModInventoryScan.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModInventoryScan',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..pPM<InventoryMod>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: InventoryMod.create)
    ..pPM<UnmanagedModPath>(2, _omitFieldNames ? '' : 'unmanaged',
        subBuilder: UnmanagedModPath.create)
    ..aOB(3, _omitFieldNames ? '' : 'limited')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModInventoryScan clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModInventoryScan copyWith(void Function(ModInventoryScan) updates) =>
      super.copyWith((message) => updates(message as ModInventoryScan))
          as ModInventoryScan;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModInventoryScan create() => ModInventoryScan._();
  @$core.override
  ModInventoryScan createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModInventoryScan getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModInventoryScan>(create);
  static ModInventoryScan? _defaultInstance;

  /// Bounded summary (32 each), not a complete inventory. ReadInventory pages persisted entries.
  @$pb.TagNumber(1)
  $pb.PbList<InventoryMod> get entries => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<UnmanagedModPath> get unmanaged => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get limited => $_getBF(2);
  @$pb.TagNumber(3)
  set limited($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimited() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimited() => $_clearField(3);
}

enum InventoryScanReply_Outcome { scan, fault, notSet }

class InventoryScanReply extends $pb.GeneratedMessage {
  factory InventoryScanReply({
    ModInventoryScan? scan,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (scan != null) result.scan = scan;
    if (fault != null) result.fault = fault;
    return result;
  }

  InventoryScanReply._();

  factory InventoryScanReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryScanReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, InventoryScanReply_Outcome>
      _InventoryScanReply_OutcomeByTag = {
    1: InventoryScanReply_Outcome.scan,
    2: InventoryScanReply_Outcome.fault,
    0: InventoryScanReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryScanReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ModInventoryScan>(1, _omitFieldNames ? '' : 'scan',
        subBuilder: ModInventoryScan.create)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryScanReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryScanReply copyWith(void Function(InventoryScanReply) updates) =>
      super.copyWith((message) => updates(message as InventoryScanReply))
          as InventoryScanReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryScanReply create() => InventoryScanReply._();
  @$core.override
  InventoryScanReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryScanReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryScanReply>(create);
  static InventoryScanReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  InventoryScanReply_Outcome whichOutcome() =>
      _InventoryScanReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModInventoryScan get scan => $_getN(0);
  @$pb.TagNumber(1)
  set scan(ModInventoryScan value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasScan() => $_has(0);
  @$pb.TagNumber(1)
  void clearScan() => $_clearField(1);
  @$pb.TagNumber(1)
  ModInventoryScan ensureScan() => $_ensure(0);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

class PublishModRequest extends $pb.GeneratedMessage {
  factory PublishModRequest({
    $core.String? modId,
    $fixnum.Int64? expectedRevision,
    $core.String? versionId,
  }) {
    final result = create();
    if (modId != null) result.modId = modId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (versionId != null) result.versionId = versionId;
    return result;
  }

  PublishModRequest._();

  factory PublishModRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublishModRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublishModRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'versionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishModRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishModRequest copyWith(void Function(PublishModRequest) updates) =>
      super.copyWith((message) => updates(message as PublishModRequest))
          as PublishModRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublishModRequest create() => PublishModRequest._();
  @$core.override
  PublishModRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PublishModRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublishModRequest>(create);
  static PublishModRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get versionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set versionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersionId() => $_clearField(3);
}

class PublicationRequest extends $pb.GeneratedMessage {
  factory PublicationRequest({
    $core.String? versionId,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    return result;
  }

  PublicationRequest._();

  factory PublicationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublicationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublicationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'versionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicationRequest copyWith(void Function(PublicationRequest) updates) =>
      super.copyWith((message) => updates(message as PublicationRequest))
          as PublicationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublicationRequest create() => PublicationRequest._();
  @$core.override
  PublicationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PublicationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublicationRequest>(create);
  static PublicationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get versionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set versionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);
}

class ModPublicationReceipt extends $pb.GeneratedMessage {
  factory ModPublicationReceipt({
    $core.String? versionId,
    $core.String? modId,
    $fixnum.Int64? expectedRevision,
    ModPublicationPhase? phase,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    if (modId != null) result.modId = modId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (phase != null) result.phase = phase;
    return result;
  }

  ModPublicationReceipt._();

  factory ModPublicationReceipt.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModPublicationReceipt.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModPublicationReceipt',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'versionId')
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<ModPublicationPhase>(4, _omitFieldNames ? '' : 'phase',
        enumValues: ModPublicationPhase.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPublicationReceipt clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPublicationReceipt copyWith(
          void Function(ModPublicationReceipt) updates) =>
      super.copyWith((message) => updates(message as ModPublicationReceipt))
          as ModPublicationReceipt;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModPublicationReceipt create() => ModPublicationReceipt._();
  @$core.override
  ModPublicationReceipt createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModPublicationReceipt getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModPublicationReceipt>(create);
  static ModPublicationReceipt? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get versionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set versionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);

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

  @$pb.TagNumber(4)
  ModPublicationPhase get phase => $_getN(3);
  @$pb.TagNumber(4)
  set phase(ModPublicationPhase value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPhase() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhase() => $_clearField(4);
}

enum PublicationReply_Outcome { receipt, fault, notSet }

class PublicationReply extends $pb.GeneratedMessage {
  factory PublicationReply({
    ModPublicationReceipt? receipt,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (receipt != null) result.receipt = receipt;
    if (fault != null) result.fault = fault;
    return result;
  }

  PublicationReply._();

  factory PublicationReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublicationReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PublicationReply_Outcome>
      _PublicationReply_OutcomeByTag = {
    1: PublicationReply_Outcome.receipt,
    2: PublicationReply_Outcome.fault,
    0: PublicationReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublicationReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ModPublicationReceipt>(1, _omitFieldNames ? '' : 'receipt',
        subBuilder: ModPublicationReceipt.create)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicationReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicationReply copyWith(void Function(PublicationReply) updates) =>
      super.copyWith((message) => updates(message as PublicationReply))
          as PublicationReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublicationReply create() => PublicationReply._();
  @$core.override
  PublicationReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PublicationReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublicationReply>(create);
  static PublicationReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  PublicationReply_Outcome whichOutcome() =>
      _PublicationReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModPublicationReceipt get receipt => $_getN(0);
  @$pb.TagNumber(1)
  set receipt(ModPublicationReceipt value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReceipt() => $_has(0);
  @$pb.TagNumber(1)
  void clearReceipt() => $_clearField(1);
  @$pb.TagNumber(1)
  ModPublicationReceipt ensureReceipt() => $_ensure(0);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

class ReadModVersionRequest extends $pb.GeneratedMessage {
  factory ReadModVersionRequest({
    $core.String? versionId,
    $core.int? offset,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    if (offset != null) result.offset = offset;
    return result;
  }

  ReadModVersionRequest._();

  factory ReadModVersionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadModVersionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadModVersionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'versionId')
    ..aI(2, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadModVersionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadModVersionRequest copyWith(
          void Function(ReadModVersionRequest) updates) =>
      super.copyWith((message) => updates(message as ReadModVersionRequest))
          as ReadModVersionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadModVersionRequest create() => ReadModVersionRequest._();
  @$core.override
  ReadModVersionRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadModVersionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadModVersionRequest>(create);
  static ReadModVersionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get versionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set versionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get offset => $_getIZ(1);
  @$pb.TagNumber(2)
  set offset($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);
}

class ModPayload extends $pb.GeneratedMessage {
  factory ModPayload({
    $core.String? payloadId,
    $fixnum.Int64? length,
    $core.String? sha256,
  }) {
    final result = create();
    if (payloadId != null) result.payloadId = payloadId;
    if (length != null) result.length = length;
    if (sha256 != null) result.sha256 = sha256;
    return result;
  }

  ModPayload._();

  factory ModPayload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModPayload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModPayload',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'payloadId')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'length', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'sha256')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPayload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPayload copyWith(void Function(ModPayload) updates) =>
      super.copyWith((message) => updates(message as ModPayload)) as ModPayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModPayload create() => ModPayload._();
  @$core.override
  ModPayload createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModPayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModPayload>(create);
  static ModPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get payloadId => $_getSZ(0);
  @$pb.TagNumber(1)
  set payloadId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPayloadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPayloadId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get length => $_getI64(1);
  @$pb.TagNumber(2)
  set length($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLength() => $_has(1);
  @$pb.TagNumber(2)
  void clearLength() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sha256 => $_getSZ(2);
  @$pb.TagNumber(3)
  set sha256($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSha256() => $_has(2);
  @$pb.TagNumber(3)
  void clearSha256() => $_clearField(3);
}

class ModManifestEntry extends $pb.GeneratedMessage {
  factory ModManifestEntry({
    ModLogicalPath? path,
    ModPayload? payload,
  }) {
    final result = create();
    if (path != null) result.path = path;
    if (payload != null) result.payload = payload;
    return result;
  }

  ModManifestEntry._();

  factory ModManifestEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModManifestEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModManifestEntry',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOM<ModLogicalPath>(1, _omitFieldNames ? '' : 'path',
        subBuilder: ModLogicalPath.create)
    ..aOM<ModPayload>(2, _omitFieldNames ? '' : 'payload',
        subBuilder: ModPayload.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModManifestEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModManifestEntry copyWith(void Function(ModManifestEntry) updates) =>
      super.copyWith((message) => updates(message as ModManifestEntry))
          as ModManifestEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModManifestEntry create() => ModManifestEntry._();
  @$core.override
  ModManifestEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModManifestEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModManifestEntry>(create);
  static ModManifestEntry? _defaultInstance;

  @$pb.TagNumber(1)
  ModLogicalPath get path => $_getN(0);
  @$pb.TagNumber(1)
  set path(ModLogicalPath value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
  @$pb.TagNumber(1)
  ModLogicalPath ensurePath() => $_ensure(0);

  @$pb.TagNumber(2)
  ModPayload get payload => $_getN(1);
  @$pb.TagNumber(2)
  set payload(ModPayload value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField(2);
  @$pb.TagNumber(2)
  ModPayload ensurePayload() => $_ensure(1);
}

class ModVersionPage extends $pb.GeneratedMessage {
  factory ModVersionPage({
    $core.String? versionId,
    $core.String? modId,
    $core.Iterable<ModManifestEntry>? entries,
    $core.int? nextOffset,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    if (modId != null) result.modId = modId;
    if (entries != null) result.entries.addAll(entries);
    if (nextOffset != null) result.nextOffset = nextOffset;
    return result;
  }

  ModVersionPage._();

  factory ModVersionPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModVersionPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModVersionPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'versionId')
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..pPM<ModManifestEntry>(3, _omitFieldNames ? '' : 'entries',
        subBuilder: ModManifestEntry.create)
    ..aI(4, _omitFieldNames ? '' : 'nextOffset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModVersionPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModVersionPage copyWith(void Function(ModVersionPage) updates) =>
      super.copyWith((message) => updates(message as ModVersionPage))
          as ModVersionPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModVersionPage create() => ModVersionPage._();
  @$core.override
  ModVersionPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModVersionPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModVersionPage>(create);
  static ModVersionPage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get versionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set versionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get modId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<ModManifestEntry> get entries => $_getList(2);

  @$pb.TagNumber(4)
  $core.int get nextOffset => $_getIZ(3);
  @$pb.TagNumber(4)
  set nextOffset($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNextOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearNextOffset() => $_clearField(4);
}

enum ModVersionReply_Outcome { version, fault, notSet }

class ModVersionReply extends $pb.GeneratedMessage {
  factory ModVersionReply({
    ModVersionPage? version,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (fault != null) result.fault = fault;
    return result;
  }

  ModVersionReply._();

  factory ModVersionReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModVersionReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModVersionReply_Outcome>
      _ModVersionReply_OutcomeByTag = {
    1: ModVersionReply_Outcome.version,
    2: ModVersionReply_Outcome.fault,
    0: ModVersionReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModVersionReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ModVersionPage>(1, _omitFieldNames ? '' : 'version',
        subBuilder: ModVersionPage.create)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModVersionReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModVersionReply copyWith(void Function(ModVersionReply) updates) =>
      super.copyWith((message) => updates(message as ModVersionReply))
          as ModVersionReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModVersionReply create() => ModVersionReply._();
  @$core.override
  ModVersionReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModVersionReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModVersionReply>(create);
  static ModVersionReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ModVersionReply_Outcome whichOutcome() =>
      _ModVersionReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModVersionPage get version => $_getN(0);
  @$pb.TagNumber(1)
  set version(ModVersionPage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ModVersionPage ensureVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

class ReadModPayloadRequest extends $pb.GeneratedMessage {
  factory ReadModPayloadRequest({
    $core.String? versionId,
    $core.String? payloadId,
    $fixnum.Int64? offset,
    $core.int? count,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    if (payloadId != null) result.payloadId = payloadId;
    if (offset != null) result.offset = offset;
    if (count != null) result.count = count;
    return result;
  }

  ReadModPayloadRequest._();

  factory ReadModPayloadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadModPayloadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadModPayloadRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'versionId')
    ..aOS(2, _omitFieldNames ? '' : 'payloadId')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(4, _omitFieldNames ? '' : 'count', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadModPayloadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadModPayloadRequest copyWith(
          void Function(ReadModPayloadRequest) updates) =>
      super.copyWith((message) => updates(message as ReadModPayloadRequest))
          as ReadModPayloadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadModPayloadRequest create() => ReadModPayloadRequest._();
  @$core.override
  ReadModPayloadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadModPayloadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadModPayloadRequest>(create);
  static ReadModPayloadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get versionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set versionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get payloadId => $_getSZ(1);
  @$pb.TagNumber(2)
  set payloadId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPayloadId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayloadId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get offset => $_getI64(2);
  @$pb.TagNumber(3)
  set offset($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffset() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get count => $_getIZ(3);
  @$pb.TagNumber(4)
  set count($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearCount() => $_clearField(4);
}

enum ModPayloadReply_Outcome { data, fault, notSet }

class ModPayloadReply extends $pb.GeneratedMessage {
  factory ModPayloadReply({
    $core.List<$core.int>? data,
    ModLibraryFault? fault,
  }) {
    final result = create();
    if (data != null) result.data = data;
    if (fault != null) result.fault = fault;
    return result;
  }

  ModPayloadReply._();

  factory ModPayloadReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModPayloadReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModPayloadReply_Outcome>
      _ModPayloadReply_OutcomeByTag = {
    1: ModPayloadReply_Outcome.data,
    2: ModPayloadReply_Outcome.fault,
    0: ModPayloadReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModPayloadReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v2'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOM<ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPayloadReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModPayloadReply copyWith(void Function(ModPayloadReply) updates) =>
      super.copyWith((message) => updates(message as ModPayloadReply))
          as ModPayloadReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModPayloadReply create() => ModPayloadReply._();
  @$core.override
  ModPayloadReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModPayloadReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModPayloadReply>(create);
  static ModPayloadReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ModPayloadReply_Outcome whichOutcome() =>
      _ModPayloadReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  @$pb.TagNumber(2)
  ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  ModLibraryFault ensureFault() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
