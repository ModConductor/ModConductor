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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
