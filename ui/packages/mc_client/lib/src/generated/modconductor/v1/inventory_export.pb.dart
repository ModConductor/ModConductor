// This is a generated file - do not edit.
//
// Generated from modconductor/v1/inventory_export.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'inventory_export.pbenum.dart';
import 'mod_organization.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'inventory_export.pbenum.dart';

class InventoryExportFault extends $pb.GeneratedMessage {
  factory InventoryExportFault({
    InventoryExportFaultCode? code,
    $core.String? detail,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (detail != null) result.detail = detail;
    return result;
  }

  InventoryExportFault._();

  factory InventoryExportFault.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryExportFault.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryExportFault',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aE<InventoryExportFaultCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: InventoryExportFaultCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryExportFault clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryExportFault copyWith(void Function(InventoryExportFault) updates) =>
      super.copyWith((message) => updates(message as InventoryExportFault))
          as InventoryExportFault;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryExportFault create() => InventoryExportFault._();
  @$core.override
  InventoryExportFault createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryExportFault getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryExportFault>(create);
  static InventoryExportFault? _defaultInstance;

  @$pb.TagNumber(1)
  InventoryExportFaultCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(InventoryExportFaultCode value) => $_setField(1, value);
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

class PrepareInventoryExportRequest extends $pb.GeneratedMessage {
  factory PrepareInventoryExportRequest({
    $core.String? workspaceId,
    $fixnum.Int64? workspaceRevision,
    $core.String? profileId,
    InventoryExportScope? scope,
    $core.Iterable<$core.String>? selectedModIds,
    $1.ModQueryDefinition? query,
    $core.String? queryIdentity,
    $fixnum.Int64? catalogueRevision,
    $fixnum.Int64? selectionRevision,
    $core.Iterable<InventoryExportField>? fields,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (workspaceRevision != null) result.workspaceRevision = workspaceRevision;
    if (profileId != null) result.profileId = profileId;
    if (scope != null) result.scope = scope;
    if (selectedModIds != null) result.selectedModIds.addAll(selectedModIds);
    if (query != null) result.query = query;
    if (queryIdentity != null) result.queryIdentity = queryIdentity;
    if (catalogueRevision != null) result.catalogueRevision = catalogueRevision;
    if (selectionRevision != null) result.selectionRevision = selectionRevision;
    if (fields != null) result.fields.addAll(fields);
    return result;
  }

  PrepareInventoryExportRequest._();

  factory PrepareInventoryExportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrepareInventoryExportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrepareInventoryExportRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'workspaceRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'profileId')
    ..aE<InventoryExportScope>(4, _omitFieldNames ? '' : 'scope',
        enumValues: InventoryExportScope.values)
    ..pPS(5, _omitFieldNames ? '' : 'selectedModIds')
    ..aOM<$1.ModQueryDefinition>(6, _omitFieldNames ? '' : 'query',
        subBuilder: $1.ModQueryDefinition.create)
    ..aOS(7, _omitFieldNames ? '' : 'queryIdentity')
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'catalogueRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'selectionRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pc<InventoryExportField>(
        10, _omitFieldNames ? '' : 'fields', $pb.PbFieldType.KE,
        valueOf: InventoryExportField.valueOf,
        enumValues: InventoryExportField.values,
        defaultEnumValue:
            InventoryExportField.INVENTORY_EXPORT_FIELD_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareInventoryExportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareInventoryExportRequest copyWith(
          void Function(PrepareInventoryExportRequest) updates) =>
      super.copyWith(
              (message) => updates(message as PrepareInventoryExportRequest))
          as PrepareInventoryExportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrepareInventoryExportRequest create() =>
      PrepareInventoryExportRequest._();
  @$core.override
  PrepareInventoryExportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PrepareInventoryExportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrepareInventoryExportRequest>(create);
  static PrepareInventoryExportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get workspaceRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set workspaceRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get profileId => $_getSZ(2);
  @$pb.TagNumber(3)
  set profileId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProfileId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfileId() => $_clearField(3);

  @$pb.TagNumber(4)
  InventoryExportScope get scope => $_getN(3);
  @$pb.TagNumber(4)
  set scope(InventoryExportScope value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasScope() => $_has(3);
  @$pb.TagNumber(4)
  void clearScope() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get selectedModIds => $_getList(4);

  @$pb.TagNumber(6)
  $1.ModQueryDefinition get query => $_getN(5);
  @$pb.TagNumber(6)
  set query($1.ModQueryDefinition value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasQuery() => $_has(5);
  @$pb.TagNumber(6)
  void clearQuery() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.ModQueryDefinition ensureQuery() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.String get queryIdentity => $_getSZ(6);
  @$pb.TagNumber(7)
  set queryIdentity($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasQueryIdentity() => $_has(6);
  @$pb.TagNumber(7)
  void clearQueryIdentity() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get catalogueRevision => $_getI64(7);
  @$pb.TagNumber(8)
  set catalogueRevision($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCatalogueRevision() => $_has(7);
  @$pb.TagNumber(8)
  void clearCatalogueRevision() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get selectionRevision => $_getI64(8);
  @$pb.TagNumber(9)
  set selectionRevision($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSelectionRevision() => $_has(8);
  @$pb.TagNumber(9)
  void clearSelectionRevision() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<InventoryExportField> get fields => $_getList(9);
}

class PreparedInventoryExport extends $pb.GeneratedMessage {
  factory PreparedInventoryExport({
    $core.String? exportId,
    $core.int? rowCount,
    $core.Iterable<InventoryExportField>? fields,
  }) {
    final result = create();
    if (exportId != null) result.exportId = exportId;
    if (rowCount != null) result.rowCount = rowCount;
    if (fields != null) result.fields.addAll(fields);
    return result;
  }

  PreparedInventoryExport._();

  factory PreparedInventoryExport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreparedInventoryExport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreparedInventoryExport',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'exportId')
    ..aI(2, _omitFieldNames ? '' : 'rowCount', fieldType: $pb.PbFieldType.OU3)
    ..pc<InventoryExportField>(
        3, _omitFieldNames ? '' : 'fields', $pb.PbFieldType.KE,
        valueOf: InventoryExportField.valueOf,
        enumValues: InventoryExportField.values,
        defaultEnumValue:
            InventoryExportField.INVENTORY_EXPORT_FIELD_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparedInventoryExport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparedInventoryExport copyWith(
          void Function(PreparedInventoryExport) updates) =>
      super.copyWith((message) => updates(message as PreparedInventoryExport))
          as PreparedInventoryExport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreparedInventoryExport create() => PreparedInventoryExport._();
  @$core.override
  PreparedInventoryExport createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PreparedInventoryExport getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreparedInventoryExport>(create);
  static PreparedInventoryExport? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get exportId => $_getSZ(0);
  @$pb.TagNumber(1)
  set exportId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExportId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExportId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get rowCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set rowCount($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRowCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowCount() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<InventoryExportField> get fields => $_getList(2);
}

enum PrepareInventoryExportReply_Outcome { prepared, fault, notSet }

class PrepareInventoryExportReply extends $pb.GeneratedMessage {
  factory PrepareInventoryExportReply({
    PreparedInventoryExport? prepared,
    InventoryExportFault? fault,
  }) {
    final result = create();
    if (prepared != null) result.prepared = prepared;
    if (fault != null) result.fault = fault;
    return result;
  }

  PrepareInventoryExportReply._();

  factory PrepareInventoryExportReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PrepareInventoryExportReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PrepareInventoryExportReply_Outcome>
      _PrepareInventoryExportReply_OutcomeByTag = {
    1: PrepareInventoryExportReply_Outcome.prepared,
    2: PrepareInventoryExportReply_Outcome.fault,
    0: PrepareInventoryExportReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrepareInventoryExportReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<PreparedInventoryExport>(1, _omitFieldNames ? '' : 'prepared',
        subBuilder: PreparedInventoryExport.create)
    ..aOM<InventoryExportFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: InventoryExportFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareInventoryExportReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareInventoryExportReply copyWith(
          void Function(PrepareInventoryExportReply) updates) =>
      super.copyWith(
              (message) => updates(message as PrepareInventoryExportReply))
          as PrepareInventoryExportReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PrepareInventoryExportReply create() =>
      PrepareInventoryExportReply._();
  @$core.override
  PrepareInventoryExportReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PrepareInventoryExportReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrepareInventoryExportReply>(create);
  static PrepareInventoryExportReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  PrepareInventoryExportReply_Outcome whichOutcome() =>
      _PrepareInventoryExportReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  PreparedInventoryExport get prepared => $_getN(0);
  @$pb.TagNumber(1)
  set prepared(PreparedInventoryExport value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPrepared() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrepared() => $_clearField(1);
  @$pb.TagNumber(1)
  PreparedInventoryExport ensurePrepared() => $_ensure(0);

  @$pb.TagNumber(2)
  InventoryExportFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(InventoryExportFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  InventoryExportFault ensureFault() => $_ensure(1);
}

class InspectInventoryExportDestinationRequest extends $pb.GeneratedMessage {
  factory InspectInventoryExportDestinationRequest({
    $core.String? exportId,
    $core.String? destinationPath,
  }) {
    final result = create();
    if (exportId != null) result.exportId = exportId;
    if (destinationPath != null) result.destinationPath = destinationPath;
    return result;
  }

  InspectInventoryExportDestinationRequest._();

  factory InspectInventoryExportDestinationRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InspectInventoryExportDestinationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InspectInventoryExportDestinationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'exportId')
    ..aOS(2, _omitFieldNames ? '' : 'destinationPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectInventoryExportDestinationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectInventoryExportDestinationRequest copyWith(
          void Function(InspectInventoryExportDestinationRequest) updates) =>
      super.copyWith((message) =>
              updates(message as InspectInventoryExportDestinationRequest))
          as InspectInventoryExportDestinationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InspectInventoryExportDestinationRequest create() =>
      InspectInventoryExportDestinationRequest._();
  @$core.override
  InspectInventoryExportDestinationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InspectInventoryExportDestinationRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          InspectInventoryExportDestinationRequest>(create);
  static InspectInventoryExportDestinationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get exportId => $_getSZ(0);
  @$pb.TagNumber(1)
  set exportId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExportId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExportId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get destinationPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set destinationPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDestinationPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearDestinationPath() => $_clearField(2);
}

class InventoryExportDestination extends $pb.GeneratedMessage {
  factory InventoryExportDestination({
    $core.String? destinationId,
    $core.String? fileName,
    $core.bool? exists,
  }) {
    final result = create();
    if (destinationId != null) result.destinationId = destinationId;
    if (fileName != null) result.fileName = fileName;
    if (exists != null) result.exists = exists;
    return result;
  }

  InventoryExportDestination._();

  factory InventoryExportDestination.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryExportDestination.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryExportDestination',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'destinationId')
    ..aOS(2, _omitFieldNames ? '' : 'fileName')
    ..aOB(3, _omitFieldNames ? '' : 'exists')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryExportDestination clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryExportDestination copyWith(
          void Function(InventoryExportDestination) updates) =>
      super.copyWith(
              (message) => updates(message as InventoryExportDestination))
          as InventoryExportDestination;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryExportDestination create() => InventoryExportDestination._();
  @$core.override
  InventoryExportDestination createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryExportDestination getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryExportDestination>(create);
  static InventoryExportDestination? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get destinationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set destinationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDestinationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDestinationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get fileName => $_getSZ(1);
  @$pb.TagNumber(2)
  set fileName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileName() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get exists => $_getBF(2);
  @$pb.TagNumber(3)
  set exists($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExists() => $_has(2);
  @$pb.TagNumber(3)
  void clearExists() => $_clearField(3);
}

enum InspectInventoryExportDestinationReply_Outcome {
  destination,
  fault,
  notSet
}

class InspectInventoryExportDestinationReply extends $pb.GeneratedMessage {
  factory InspectInventoryExportDestinationReply({
    InventoryExportDestination? destination,
    InventoryExportFault? fault,
  }) {
    final result = create();
    if (destination != null) result.destination = destination;
    if (fault != null) result.fault = fault;
    return result;
  }

  InspectInventoryExportDestinationReply._();

  factory InspectInventoryExportDestinationReply.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InspectInventoryExportDestinationReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core
      .Map<$core.int, InspectInventoryExportDestinationReply_Outcome>
      _InspectInventoryExportDestinationReply_OutcomeByTag = {
    1: InspectInventoryExportDestinationReply_Outcome.destination,
    2: InspectInventoryExportDestinationReply_Outcome.fault,
    0: InspectInventoryExportDestinationReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InspectInventoryExportDestinationReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<InventoryExportDestination>(1, _omitFieldNames ? '' : 'destination',
        subBuilder: InventoryExportDestination.create)
    ..aOM<InventoryExportFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: InventoryExportFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectInventoryExportDestinationReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectInventoryExportDestinationReply copyWith(
          void Function(InspectInventoryExportDestinationReply) updates) =>
      super.copyWith((message) =>
              updates(message as InspectInventoryExportDestinationReply))
          as InspectInventoryExportDestinationReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InspectInventoryExportDestinationReply create() =>
      InspectInventoryExportDestinationReply._();
  @$core.override
  InspectInventoryExportDestinationReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InspectInventoryExportDestinationReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          InspectInventoryExportDestinationReply>(create);
  static InspectInventoryExportDestinationReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  InspectInventoryExportDestinationReply_Outcome whichOutcome() =>
      _InspectInventoryExportDestinationReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  InventoryExportDestination get destination => $_getN(0);
  @$pb.TagNumber(1)
  set destination(InventoryExportDestination value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDestination() => $_has(0);
  @$pb.TagNumber(1)
  void clearDestination() => $_clearField(1);
  @$pb.TagNumber(1)
  InventoryExportDestination ensureDestination() => $_ensure(0);

  @$pb.TagNumber(2)
  InventoryExportFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(InventoryExportFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  InventoryExportFault ensureFault() => $_ensure(1);
}

class WriteInventoryExportRequest extends $pb.GeneratedMessage {
  factory WriteInventoryExportRequest({
    $core.String? exportId,
    $core.String? destinationId,
    $core.bool? replaceExisting,
  }) {
    final result = create();
    if (exportId != null) result.exportId = exportId;
    if (destinationId != null) result.destinationId = destinationId;
    if (replaceExisting != null) result.replaceExisting = replaceExisting;
    return result;
  }

  WriteInventoryExportRequest._();

  factory WriteInventoryExportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WriteInventoryExportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WriteInventoryExportRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'exportId')
    ..aOS(2, _omitFieldNames ? '' : 'destinationId')
    ..aOB(3, _omitFieldNames ? '' : 'replaceExisting')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteInventoryExportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WriteInventoryExportRequest copyWith(
          void Function(WriteInventoryExportRequest) updates) =>
      super.copyWith(
              (message) => updates(message as WriteInventoryExportRequest))
          as WriteInventoryExportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WriteInventoryExportRequest create() =>
      WriteInventoryExportRequest._();
  @$core.override
  WriteInventoryExportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WriteInventoryExportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WriteInventoryExportRequest>(create);
  static WriteInventoryExportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get exportId => $_getSZ(0);
  @$pb.TagNumber(1)
  set exportId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExportId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExportId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get destinationId => $_getSZ(1);
  @$pb.TagNumber(2)
  set destinationId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDestinationId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDestinationId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get replaceExisting => $_getBF(2);
  @$pb.TagNumber(3)
  set replaceExisting($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReplaceExisting() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplaceExisting() => $_clearField(3);
}

class InventoryExportWriteProgress extends $pb.GeneratedMessage {
  factory InventoryExportWriteProgress({
    $core.int? writtenRows,
    $core.int? totalRows,
  }) {
    final result = create();
    if (writtenRows != null) result.writtenRows = writtenRows;
    if (totalRows != null) result.totalRows = totalRows;
    return result;
  }

  InventoryExportWriteProgress._();

  factory InventoryExportWriteProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryExportWriteProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryExportWriteProgress',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'writtenRows',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'totalRows', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryExportWriteProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryExportWriteProgress copyWith(
          void Function(InventoryExportWriteProgress) updates) =>
      super.copyWith(
              (message) => updates(message as InventoryExportWriteProgress))
          as InventoryExportWriteProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryExportWriteProgress create() =>
      InventoryExportWriteProgress._();
  @$core.override
  InventoryExportWriteProgress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryExportWriteProgress getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryExportWriteProgress>(create);
  static InventoryExportWriteProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get writtenRows => $_getIZ(0);
  @$pb.TagNumber(1)
  set writtenRows($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWrittenRows() => $_has(0);
  @$pb.TagNumber(1)
  void clearWrittenRows() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get totalRows => $_getIZ(1);
  @$pb.TagNumber(2)
  set totalRows($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalRows() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalRows() => $_clearField(2);
}

class CompletedInventoryExport extends $pb.GeneratedMessage {
  factory CompletedInventoryExport({
    $core.String? fileName,
    $core.int? rowCount,
    $fixnum.Int64? byteCount,
  }) {
    final result = create();
    if (fileName != null) result.fileName = fileName;
    if (rowCount != null) result.rowCount = rowCount;
    if (byteCount != null) result.byteCount = byteCount;
    return result;
  }

  CompletedInventoryExport._();

  factory CompletedInventoryExport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CompletedInventoryExport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompletedInventoryExport',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fileName')
    ..aI(2, _omitFieldNames ? '' : 'rowCount', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'byteCount', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompletedInventoryExport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompletedInventoryExport copyWith(
          void Function(CompletedInventoryExport) updates) =>
      super.copyWith((message) => updates(message as CompletedInventoryExport))
          as CompletedInventoryExport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CompletedInventoryExport create() => CompletedInventoryExport._();
  @$core.override
  CompletedInventoryExport createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CompletedInventoryExport getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompletedInventoryExport>(create);
  static CompletedInventoryExport? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fileName => $_getSZ(0);
  @$pb.TagNumber(1)
  set fileName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFileName() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get rowCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set rowCount($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRowCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearRowCount() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get byteCount => $_getI64(2);
  @$pb.TagNumber(3)
  set byteCount($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasByteCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearByteCount() => $_clearField(3);
}

enum InventoryExportEvent_Outcome { progress, completed, fault, notSet }

class InventoryExportEvent extends $pb.GeneratedMessage {
  factory InventoryExportEvent({
    InventoryExportWriteProgress? progress,
    CompletedInventoryExport? completed,
    InventoryExportFault? fault,
  }) {
    final result = create();
    if (progress != null) result.progress = progress;
    if (completed != null) result.completed = completed;
    if (fault != null) result.fault = fault;
    return result;
  }

  InventoryExportEvent._();

  factory InventoryExportEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InventoryExportEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, InventoryExportEvent_Outcome>
      _InventoryExportEvent_OutcomeByTag = {
    1: InventoryExportEvent_Outcome.progress,
    2: InventoryExportEvent_Outcome.completed,
    3: InventoryExportEvent_Outcome.fault,
    0: InventoryExportEvent_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InventoryExportEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<InventoryExportWriteProgress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: InventoryExportWriteProgress.create)
    ..aOM<CompletedInventoryExport>(2, _omitFieldNames ? '' : 'completed',
        subBuilder: CompletedInventoryExport.create)
    ..aOM<InventoryExportFault>(3, _omitFieldNames ? '' : 'fault',
        subBuilder: InventoryExportFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryExportEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InventoryExportEvent copyWith(void Function(InventoryExportEvent) updates) =>
      super.copyWith((message) => updates(message as InventoryExportEvent))
          as InventoryExportEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InventoryExportEvent create() => InventoryExportEvent._();
  @$core.override
  InventoryExportEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InventoryExportEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InventoryExportEvent>(create);
  static InventoryExportEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  InventoryExportEvent_Outcome whichOutcome() =>
      _InventoryExportEvent_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  InventoryExportWriteProgress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(InventoryExportWriteProgress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  InventoryExportWriteProgress ensureProgress() => $_ensure(0);

  @$pb.TagNumber(2)
  CompletedInventoryExport get completed => $_getN(1);
  @$pb.TagNumber(2)
  set completed(CompletedInventoryExport value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCompleted() => $_has(1);
  @$pb.TagNumber(2)
  void clearCompleted() => $_clearField(2);
  @$pb.TagNumber(2)
  CompletedInventoryExport ensureCompleted() => $_ensure(1);

  @$pb.TagNumber(3)
  InventoryExportFault get fault => $_getN(2);
  @$pb.TagNumber(3)
  set fault(InventoryExportFault value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFault() => $_has(2);
  @$pb.TagNumber(3)
  void clearFault() => $_clearField(3);
  @$pb.TagNumber(3)
  InventoryExportFault ensureFault() => $_ensure(2);
}

class CancelInventoryExportRequest extends $pb.GeneratedMessage {
  factory CancelInventoryExportRequest({
    $core.String? exportId,
  }) {
    final result = create();
    if (exportId != null) result.exportId = exportId;
    return result;
  }

  CancelInventoryExportRequest._();

  factory CancelInventoryExportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelInventoryExportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelInventoryExportRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'exportId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelInventoryExportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelInventoryExportRequest copyWith(
          void Function(CancelInventoryExportRequest) updates) =>
      super.copyWith(
              (message) => updates(message as CancelInventoryExportRequest))
          as CancelInventoryExportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelInventoryExportRequest create() =>
      CancelInventoryExportRequest._();
  @$core.override
  CancelInventoryExportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelInventoryExportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelInventoryExportRequest>(create);
  static CancelInventoryExportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get exportId => $_getSZ(0);
  @$pb.TagNumber(1)
  set exportId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExportId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExportId() => $_clearField(1);
}

class CancelInventoryExportReply extends $pb.GeneratedMessage {
  factory CancelInventoryExportReply({
    $core.bool? requested,
  }) {
    final result = create();
    if (requested != null) result.requested = requested;
    return result;
  }

  CancelInventoryExportReply._();

  factory CancelInventoryExportReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CancelInventoryExportReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelInventoryExportReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'requested')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelInventoryExportReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelInventoryExportReply copyWith(
          void Function(CancelInventoryExportReply) updates) =>
      super.copyWith(
              (message) => updates(message as CancelInventoryExportReply))
          as CancelInventoryExportReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelInventoryExportReply create() => CancelInventoryExportReply._();
  @$core.override
  CancelInventoryExportReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CancelInventoryExportReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelInventoryExportReply>(create);
  static CancelInventoryExportReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get requested => $_getBF(0);
  @$pb.TagNumber(1)
  set requested($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequested() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequested() => $_clearField(1);
}

class DiscardInventoryExportRequest extends $pb.GeneratedMessage {
  factory DiscardInventoryExportRequest({
    $core.String? exportId,
  }) {
    final result = create();
    if (exportId != null) result.exportId = exportId;
    return result;
  }

  DiscardInventoryExportRequest._();

  factory DiscardInventoryExportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiscardInventoryExportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiscardInventoryExportRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'exportId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscardInventoryExportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscardInventoryExportRequest copyWith(
          void Function(DiscardInventoryExportRequest) updates) =>
      super.copyWith(
              (message) => updates(message as DiscardInventoryExportRequest))
          as DiscardInventoryExportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiscardInventoryExportRequest create() =>
      DiscardInventoryExportRequest._();
  @$core.override
  DiscardInventoryExportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiscardInventoryExportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiscardInventoryExportRequest>(create);
  static DiscardInventoryExportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get exportId => $_getSZ(0);
  @$pb.TagNumber(1)
  set exportId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExportId() => $_has(0);
  @$pb.TagNumber(1)
  void clearExportId() => $_clearField(1);
}

class DiscardInventoryExportReply extends $pb.GeneratedMessage {
  factory DiscardInventoryExportReply({
    $core.bool? discarded,
  }) {
    final result = create();
    if (discarded != null) result.discarded = discarded;
    return result;
  }

  DiscardInventoryExportReply._();

  factory DiscardInventoryExportReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiscardInventoryExportReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiscardInventoryExportReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'discarded')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscardInventoryExportReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscardInventoryExportReply copyWith(
          void Function(DiscardInventoryExportReply) updates) =>
      super.copyWith(
              (message) => updates(message as DiscardInventoryExportReply))
          as DiscardInventoryExportReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiscardInventoryExportReply create() =>
      DiscardInventoryExportReply._();
  @$core.override
  DiscardInventoryExportReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiscardInventoryExportReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiscardInventoryExportReply>(create);
  static DiscardInventoryExportReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get discarded => $_getBF(0);
  @$pb.TagNumber(1)
  set discarded($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDiscarded() => $_has(0);
  @$pb.TagNumber(1)
  void clearDiscarded() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
