// This is a generated file - do not edit.
//
// Generated from modconductor/v1/diagnostics.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'diagnostics.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'diagnostics.pbenum.dart';

class DiagnosticRequest extends $pb.GeneratedMessage {
  factory DiagnosticRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? fileSnapshotId,
    $core.String? deploymentId,
    $fixnum.Int64? deploymentRevision,
    $core.String? pluginSnapshotId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (fileSnapshotId != null) result.fileSnapshotId = fileSnapshotId;
    if (deploymentId != null) result.deploymentId = deploymentId;
    if (deploymentRevision != null)
      result.deploymentRevision = deploymentRevision;
    if (pluginSnapshotId != null) result.pluginSnapshotId = pluginSnapshotId;
    return result;
  }

  DiagnosticRequest._();

  factory DiagnosticRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'fileSnapshotId')
    ..aOS(4, _omitFieldNames ? '' : 'deploymentId')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'deploymentRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(6, _omitFieldNames ? '' : 'pluginSnapshotId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticRequest copyWith(void Function(DiagnosticRequest) updates) =>
      super.copyWith((message) => updates(message as DiagnosticRequest))
          as DiagnosticRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticRequest create() => DiagnosticRequest._();
  @$core.override
  DiagnosticRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticRequest>(create);
  static DiagnosticRequest? _defaultInstance;

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
  $core.String get fileSnapshotId => $_getSZ(2);
  @$pb.TagNumber(3)
  set fileSnapshotId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFileSnapshotId() => $_has(2);
  @$pb.TagNumber(3)
  void clearFileSnapshotId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get deploymentId => $_getSZ(3);
  @$pb.TagNumber(4)
  set deploymentId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDeploymentId() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeploymentId() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get deploymentRevision => $_getI64(4);
  @$pb.TagNumber(5)
  set deploymentRevision($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeploymentRevision() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeploymentRevision() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get pluginSnapshotId => $_getSZ(5);
  @$pb.TagNumber(6)
  set pluginSnapshotId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPluginSnapshotId() => $_has(5);
  @$pb.TagNumber(6)
  void clearPluginSnapshotId() => $_clearField(6);
}

class DiagnosticSnapshotReference extends $pb.GeneratedMessage {
  factory DiagnosticSnapshotReference({
    $core.String? snapshotId,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    return result;
  }

  DiagnosticSnapshotReference._();

  factory DiagnosticSnapshotReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticSnapshotReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticSnapshotReference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticSnapshotReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticSnapshotReference copyWith(
          void Function(DiagnosticSnapshotReference) updates) =>
      super.copyWith(
              (message) => updates(message as DiagnosticSnapshotReference))
          as DiagnosticSnapshotReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticSnapshotReference create() =>
      DiagnosticSnapshotReference._();
  @$core.override
  DiagnosticSnapshotReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticSnapshotReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticSnapshotReference>(create);
  static DiagnosticSnapshotReference? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);
}

class DiagnosticPreviewRequest extends $pb.GeneratedMessage {
  factory DiagnosticPreviewRequest({
    $core.String? snapshotId,
    $core.String? problemId,
  }) {
    final result = create();
    if (snapshotId != null) result.snapshotId = snapshotId;
    if (problemId != null) result.problemId = problemId;
    return result;
  }

  DiagnosticPreviewRequest._();

  factory DiagnosticPreviewRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticPreviewRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticPreviewRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshotId')
    ..aOS(2, _omitFieldNames ? '' : 'problemId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticPreviewRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticPreviewRequest copyWith(
          void Function(DiagnosticPreviewRequest) updates) =>
      super.copyWith((message) => updates(message as DiagnosticPreviewRequest))
          as DiagnosticPreviewRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticPreviewRequest create() => DiagnosticPreviewRequest._();
  @$core.override
  DiagnosticPreviewRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticPreviewRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticPreviewRequest>(create);
  static DiagnosticPreviewRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get snapshotId => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshotId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshotId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshotId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get problemId => $_getSZ(1);
  @$pb.TagNumber(2)
  set problemId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProblemId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblemId() => $_clearField(2);
}

class DiagnosticApplyRequest extends $pb.GeneratedMessage {
  factory DiagnosticApplyRequest({
    $core.String? previewId,
  }) {
    final result = create();
    if (previewId != null) result.previewId = previewId;
    return result;
  }

  DiagnosticApplyRequest._();

  factory DiagnosticApplyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticApplyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticApplyRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'previewId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticApplyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticApplyRequest copyWith(
          void Function(DiagnosticApplyRequest) updates) =>
      super.copyWith((message) => updates(message as DiagnosticApplyRequest))
          as DiagnosticApplyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticApplyRequest create() => DiagnosticApplyRequest._();
  @$core.override
  DiagnosticApplyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticApplyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticApplyRequest>(create);
  static DiagnosticApplyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get previewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set previewId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPreviewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreviewId() => $_clearField(1);
}

class DiagnosticEvidence extends $pb.GeneratedMessage {
  factory DiagnosticEvidence({
    $core.String? label,
    $core.String? value,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (value != null) result.value = value;
    return result;
  }

  DiagnosticEvidence._();

  factory DiagnosticEvidence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticEvidence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticEvidence',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticEvidence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticEvidence copyWith(void Function(DiagnosticEvidence) updates) =>
      super.copyWith((message) => updates(message as DiagnosticEvidence))
          as DiagnosticEvidence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticEvidence create() => DiagnosticEvidence._();
  @$core.override
  DiagnosticEvidence createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticEvidence getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticEvidence>(create);
  static DiagnosticEvidence? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

class DiagnosticCorrelation extends $pb.GeneratedMessage {
  factory DiagnosticCorrelation({
    $core.String? kind,
    $core.String? id,
    $fixnum.Int64? revision,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (id != null) result.id = id;
    if (revision != null) result.revision = revision;
    return result;
  }

  DiagnosticCorrelation._();

  factory DiagnosticCorrelation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticCorrelation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticCorrelation',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticCorrelation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticCorrelation copyWith(
          void Function(DiagnosticCorrelation) updates) =>
      super.copyWith((message) => updates(message as DiagnosticCorrelation))
          as DiagnosticCorrelation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticCorrelation create() => DiagnosticCorrelation._();
  @$core.override
  DiagnosticCorrelation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticCorrelation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticCorrelation>(create);
  static DiagnosticCorrelation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get revision => $_getI64(2);
  @$pb.TagNumber(3)
  set revision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearRevision() => $_clearField(3);
}

class DiagnosticFinding extends $pb.GeneratedMessage {
  factory DiagnosticFinding({
    $core.String? id,
    $core.String? code,
    DiagnosticSeverity? severity,
    $core.String? workspaceName,
    $core.String? profileName,
    $core.String? gameName,
    $core.String? title,
    $core.String? summary,
    $core.String? area,
    $core.Iterable<DiagnosticEvidence>? evidence,
    $core.String? nextAction,
    DiagnosticFixability? fixability,
    $core.String? fixDetail,
    $core.Iterable<DiagnosticCorrelation>? correlations,
    $core.String? detail,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (code != null) result.code = code;
    if (severity != null) result.severity = severity;
    if (workspaceName != null) result.workspaceName = workspaceName;
    if (profileName != null) result.profileName = profileName;
    if (gameName != null) result.gameName = gameName;
    if (title != null) result.title = title;
    if (summary != null) result.summary = summary;
    if (area != null) result.area = area;
    if (evidence != null) result.evidence.addAll(evidence);
    if (nextAction != null) result.nextAction = nextAction;
    if (fixability != null) result.fixability = fixability;
    if (fixDetail != null) result.fixDetail = fixDetail;
    if (correlations != null) result.correlations.addAll(correlations);
    if (detail != null) result.detail = detail;
    return result;
  }

  DiagnosticFinding._();

  factory DiagnosticFinding.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticFinding.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticFinding',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..aE<DiagnosticSeverity>(3, _omitFieldNames ? '' : 'severity',
        enumValues: DiagnosticSeverity.values)
    ..aOS(4, _omitFieldNames ? '' : 'workspaceName')
    ..aOS(5, _omitFieldNames ? '' : 'profileName')
    ..aOS(6, _omitFieldNames ? '' : 'gameName')
    ..aOS(7, _omitFieldNames ? '' : 'title')
    ..aOS(8, _omitFieldNames ? '' : 'summary')
    ..aOS(9, _omitFieldNames ? '' : 'area')
    ..pPM<DiagnosticEvidence>(10, _omitFieldNames ? '' : 'evidence',
        subBuilder: DiagnosticEvidence.create)
    ..aOS(11, _omitFieldNames ? '' : 'nextAction')
    ..aE<DiagnosticFixability>(12, _omitFieldNames ? '' : 'fixability',
        enumValues: DiagnosticFixability.values)
    ..aOS(13, _omitFieldNames ? '' : 'fixDetail')
    ..pPM<DiagnosticCorrelation>(14, _omitFieldNames ? '' : 'correlations',
        subBuilder: DiagnosticCorrelation.create)
    ..aOS(15, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticFinding clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticFinding copyWith(void Function(DiagnosticFinding) updates) =>
      super.copyWith((message) => updates(message as DiagnosticFinding))
          as DiagnosticFinding;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticFinding create() => DiagnosticFinding._();
  @$core.override
  DiagnosticFinding createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticFinding getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticFinding>(create);
  static DiagnosticFinding? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  @$pb.TagNumber(3)
  DiagnosticSeverity get severity => $_getN(2);
  @$pb.TagNumber(3)
  set severity(DiagnosticSeverity value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSeverity() => $_has(2);
  @$pb.TagNumber(3)
  void clearSeverity() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get workspaceName => $_getSZ(3);
  @$pb.TagNumber(4)
  set workspaceName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasWorkspaceName() => $_has(3);
  @$pb.TagNumber(4)
  void clearWorkspaceName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get profileName => $_getSZ(4);
  @$pb.TagNumber(5)
  set profileName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProfileName() => $_has(4);
  @$pb.TagNumber(5)
  void clearProfileName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get gameName => $_getSZ(5);
  @$pb.TagNumber(6)
  set gameName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGameName() => $_has(5);
  @$pb.TagNumber(6)
  void clearGameName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get title => $_getSZ(6);
  @$pb.TagNumber(7)
  set title($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTitle() => $_has(6);
  @$pb.TagNumber(7)
  void clearTitle() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get summary => $_getSZ(7);
  @$pb.TagNumber(8)
  set summary($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSummary() => $_has(7);
  @$pb.TagNumber(8)
  void clearSummary() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get area => $_getSZ(8);
  @$pb.TagNumber(9)
  set area($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasArea() => $_has(8);
  @$pb.TagNumber(9)
  void clearArea() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<DiagnosticEvidence> get evidence => $_getList(9);

  @$pb.TagNumber(11)
  $core.String get nextAction => $_getSZ(10);
  @$pb.TagNumber(11)
  set nextAction($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasNextAction() => $_has(10);
  @$pb.TagNumber(11)
  void clearNextAction() => $_clearField(11);

  @$pb.TagNumber(12)
  DiagnosticFixability get fixability => $_getN(11);
  @$pb.TagNumber(12)
  set fixability(DiagnosticFixability value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasFixability() => $_has(11);
  @$pb.TagNumber(12)
  void clearFixability() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get fixDetail => $_getSZ(12);
  @$pb.TagNumber(13)
  set fixDetail($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasFixDetail() => $_has(12);
  @$pb.TagNumber(13)
  void clearFixDetail() => $_clearField(13);

  @$pb.TagNumber(14)
  $pb.PbList<DiagnosticCorrelation> get correlations => $_getList(13);

  @$pb.TagNumber(15)
  $core.String get detail => $_getSZ(14);
  @$pb.TagNumber(15)
  set detail($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasDetail() => $_has(14);
  @$pb.TagNumber(15)
  void clearDetail() => $_clearField(15);
}

class DiagnosticSnapshot extends $pb.GeneratedMessage {
  factory DiagnosticSnapshot({
    $core.String? id,
    $core.String? workspaceId,
    $core.String? profileId,
    $core.String? capturedAt,
    $core.Iterable<DiagnosticFinding>? findings,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (capturedAt != null) result.capturedAt = capturedAt;
    if (findings != null) result.findings.addAll(findings);
    return result;
  }

  DiagnosticSnapshot._();

  factory DiagnosticSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'profileId')
    ..aOS(4, _omitFieldNames ? '' : 'capturedAt')
    ..pPM<DiagnosticFinding>(5, _omitFieldNames ? '' : 'findings',
        subBuilder: DiagnosticFinding.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticSnapshot copyWith(void Function(DiagnosticSnapshot) updates) =>
      super.copyWith((message) => updates(message as DiagnosticSnapshot))
          as DiagnosticSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticSnapshot create() => DiagnosticSnapshot._();
  @$core.override
  DiagnosticSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticSnapshot>(create);
  static DiagnosticSnapshot? _defaultInstance;

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
  $core.String get profileId => $_getSZ(2);
  @$pb.TagNumber(3)
  set profileId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProfileId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfileId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get capturedAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set capturedAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCapturedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCapturedAt() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<DiagnosticFinding> get findings => $_getList(4);
}

enum DiagnosticSnapshotReply_Outcome { snapshot, fault, notSet }

class DiagnosticSnapshotReply extends $pb.GeneratedMessage {
  factory DiagnosticSnapshotReply({
    DiagnosticSnapshot? snapshot,
    DiagnosticFault? fault,
  }) {
    final result = create();
    if (snapshot != null) result.snapshot = snapshot;
    if (fault != null) result.fault = fault;
    return result;
  }

  DiagnosticSnapshotReply._();

  factory DiagnosticSnapshotReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticSnapshotReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DiagnosticSnapshotReply_Outcome>
      _DiagnosticSnapshotReply_OutcomeByTag = {
    1: DiagnosticSnapshotReply_Outcome.snapshot,
    2: DiagnosticSnapshotReply_Outcome.fault,
    0: DiagnosticSnapshotReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticSnapshotReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DiagnosticSnapshot>(1, _omitFieldNames ? '' : 'snapshot',
        subBuilder: DiagnosticSnapshot.create)
    ..aE<DiagnosticFault>(2, _omitFieldNames ? '' : 'fault',
        enumValues: DiagnosticFault.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticSnapshotReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticSnapshotReply copyWith(
          void Function(DiagnosticSnapshotReply) updates) =>
      super.copyWith((message) => updates(message as DiagnosticSnapshotReply))
          as DiagnosticSnapshotReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticSnapshotReply create() => DiagnosticSnapshotReply._();
  @$core.override
  DiagnosticSnapshotReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticSnapshotReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticSnapshotReply>(create);
  static DiagnosticSnapshotReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DiagnosticSnapshotReply_Outcome whichOutcome() =>
      _DiagnosticSnapshotReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DiagnosticSnapshot get snapshot => $_getN(0);
  @$pb.TagNumber(1)
  set snapshot(DiagnosticSnapshot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshot() => $_clearField(1);
  @$pb.TagNumber(1)
  DiagnosticSnapshot ensureSnapshot() => $_ensure(0);

  @$pb.TagNumber(2)
  DiagnosticFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(DiagnosticFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
}

class DiagnosticRemediationItem extends $pb.GeneratedMessage {
  factory DiagnosticRemediationItem({
    $core.String? label,
    $core.String? value,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (value != null) result.value = value;
    return result;
  }

  DiagnosticRemediationItem._();

  factory DiagnosticRemediationItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticRemediationItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticRemediationItem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticRemediationItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticRemediationItem copyWith(
          void Function(DiagnosticRemediationItem) updates) =>
      super.copyWith((message) => updates(message as DiagnosticRemediationItem))
          as DiagnosticRemediationItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticRemediationItem create() => DiagnosticRemediationItem._();
  @$core.override
  DiagnosticRemediationItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticRemediationItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticRemediationItem>(create);
  static DiagnosticRemediationItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

class DiagnosticRemediationIdentifier extends $pb.GeneratedMessage {
  factory DiagnosticRemediationIdentifier({
    $core.String? label,
    $core.String? value,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (value != null) result.value = value;
    return result;
  }

  DiagnosticRemediationIdentifier._();

  factory DiagnosticRemediationIdentifier.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticRemediationIdentifier.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticRemediationIdentifier',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticRemediationIdentifier clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticRemediationIdentifier copyWith(
          void Function(DiagnosticRemediationIdentifier) updates) =>
      super.copyWith(
              (message) => updates(message as DiagnosticRemediationIdentifier))
          as DiagnosticRemediationIdentifier;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticRemediationIdentifier create() =>
      DiagnosticRemediationIdentifier._();
  @$core.override
  DiagnosticRemediationIdentifier createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticRemediationIdentifier getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticRemediationIdentifier>(
          create);
  static DiagnosticRemediationIdentifier? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

class DiagnosticPreview extends $pb.GeneratedMessage {
  factory DiagnosticPreview({
    $core.String? id,
    $core.String? snapshotId,
    $core.String? problemId,
    $core.String? expiresAt,
    $core.String? result,
    $core.Iterable<DiagnosticRemediationItem>? items,
    $core.Iterable<DiagnosticRemediationIdentifier>? identifiers,
  }) {
    final result$ = create();
    if (id != null) result$.id = id;
    if (snapshotId != null) result$.snapshotId = snapshotId;
    if (problemId != null) result$.problemId = problemId;
    if (expiresAt != null) result$.expiresAt = expiresAt;
    if (result != null) result$.result = result;
    if (items != null) result$.items.addAll(items);
    if (identifiers != null) result$.identifiers.addAll(identifiers);
    return result$;
  }

  DiagnosticPreview._();

  factory DiagnosticPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticPreview',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'snapshotId')
    ..aOS(3, _omitFieldNames ? '' : 'problemId')
    ..aOS(4, _omitFieldNames ? '' : 'expiresAt')
    ..aOS(5, _omitFieldNames ? '' : 'result')
    ..pPM<DiagnosticRemediationItem>(6, _omitFieldNames ? '' : 'items',
        subBuilder: DiagnosticRemediationItem.create)
    ..pPM<DiagnosticRemediationIdentifier>(
        7, _omitFieldNames ? '' : 'identifiers',
        subBuilder: DiagnosticRemediationIdentifier.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticPreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticPreview copyWith(void Function(DiagnosticPreview) updates) =>
      super.copyWith((message) => updates(message as DiagnosticPreview))
          as DiagnosticPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticPreview create() => DiagnosticPreview._();
  @$core.override
  DiagnosticPreview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticPreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticPreview>(create);
  static DiagnosticPreview? _defaultInstance;

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
  $core.String get problemId => $_getSZ(2);
  @$pb.TagNumber(3)
  set problemId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProblemId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProblemId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get expiresAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set expiresAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExpiresAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpiresAt() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get result => $_getSZ(4);
  @$pb.TagNumber(5)
  set result($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasResult() => $_has(4);
  @$pb.TagNumber(5)
  void clearResult() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<DiagnosticRemediationItem> get items => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<DiagnosticRemediationIdentifier> get identifiers => $_getList(6);
}

enum DiagnosticPreviewReply_Outcome { preview, fault, notSet }

class DiagnosticPreviewReply extends $pb.GeneratedMessage {
  factory DiagnosticPreviewReply({
    DiagnosticPreview? preview,
    DiagnosticFault? fault,
  }) {
    final result = create();
    if (preview != null) result.preview = preview;
    if (fault != null) result.fault = fault;
    return result;
  }

  DiagnosticPreviewReply._();

  factory DiagnosticPreviewReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticPreviewReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DiagnosticPreviewReply_Outcome>
      _DiagnosticPreviewReply_OutcomeByTag = {
    1: DiagnosticPreviewReply_Outcome.preview,
    2: DiagnosticPreviewReply_Outcome.fault,
    0: DiagnosticPreviewReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticPreviewReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DiagnosticPreview>(1, _omitFieldNames ? '' : 'preview',
        subBuilder: DiagnosticPreview.create)
    ..aE<DiagnosticFault>(2, _omitFieldNames ? '' : 'fault',
        enumValues: DiagnosticFault.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticPreviewReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticPreviewReply copyWith(
          void Function(DiagnosticPreviewReply) updates) =>
      super.copyWith((message) => updates(message as DiagnosticPreviewReply))
          as DiagnosticPreviewReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticPreviewReply create() => DiagnosticPreviewReply._();
  @$core.override
  DiagnosticPreviewReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticPreviewReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticPreviewReply>(create);
  static DiagnosticPreviewReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DiagnosticPreviewReply_Outcome whichOutcome() =>
      _DiagnosticPreviewReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DiagnosticPreview get preview => $_getN(0);
  @$pb.TagNumber(1)
  set preview(DiagnosticPreview value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreview() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreview() => $_clearField(1);
  @$pb.TagNumber(1)
  DiagnosticPreview ensurePreview() => $_ensure(0);

  @$pb.TagNumber(2)
  DiagnosticFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(DiagnosticFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
}

class DiagnosticApplyResult extends $pb.GeneratedMessage {
  factory DiagnosticApplyResult({
    $core.String? previewId,
    $core.bool? complete,
    $core.String? result,
    $core.String? detail,
  }) {
    final result$ = create();
    if (previewId != null) result$.previewId = previewId;
    if (complete != null) result$.complete = complete;
    if (result != null) result$.result = result;
    if (detail != null) result$.detail = detail;
    return result$;
  }

  DiagnosticApplyResult._();

  factory DiagnosticApplyResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticApplyResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticApplyResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'previewId')
    ..aOB(2, _omitFieldNames ? '' : 'complete')
    ..aOS(3, _omitFieldNames ? '' : 'result')
    ..aOS(4, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticApplyResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticApplyResult copyWith(
          void Function(DiagnosticApplyResult) updates) =>
      super.copyWith((message) => updates(message as DiagnosticApplyResult))
          as DiagnosticApplyResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticApplyResult create() => DiagnosticApplyResult._();
  @$core.override
  DiagnosticApplyResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticApplyResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticApplyResult>(create);
  static DiagnosticApplyResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get previewId => $_getSZ(0);
  @$pb.TagNumber(1)
  set previewId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPreviewId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreviewId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get complete => $_getBF(1);
  @$pb.TagNumber(2)
  set complete($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasComplete() => $_has(1);
  @$pb.TagNumber(2)
  void clearComplete() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get result => $_getSZ(2);
  @$pb.TagNumber(3)
  set result($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasResult() => $_has(2);
  @$pb.TagNumber(3)
  void clearResult() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get detail => $_getSZ(3);
  @$pb.TagNumber(4)
  set detail($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDetail() => $_has(3);
  @$pb.TagNumber(4)
  void clearDetail() => $_clearField(4);
}

enum DiagnosticApplyReply_Outcome { result, fault, notSet }

class DiagnosticApplyReply extends $pb.GeneratedMessage {
  factory DiagnosticApplyReply({
    DiagnosticApplyResult? result,
    DiagnosticFault? fault,
  }) {
    final result$ = create();
    if (result != null) result$.result = result;
    if (fault != null) result$.fault = fault;
    return result$;
  }

  DiagnosticApplyReply._();

  factory DiagnosticApplyReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticApplyReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DiagnosticApplyReply_Outcome>
      _DiagnosticApplyReply_OutcomeByTag = {
    1: DiagnosticApplyReply_Outcome.result,
    2: DiagnosticApplyReply_Outcome.fault,
    0: DiagnosticApplyReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticApplyReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DiagnosticApplyResult>(1, _omitFieldNames ? '' : 'result',
        subBuilder: DiagnosticApplyResult.create)
    ..aE<DiagnosticFault>(2, _omitFieldNames ? '' : 'fault',
        enumValues: DiagnosticFault.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticApplyReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticApplyReply copyWith(void Function(DiagnosticApplyReply) updates) =>
      super.copyWith((message) => updates(message as DiagnosticApplyReply))
          as DiagnosticApplyReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticApplyReply create() => DiagnosticApplyReply._();
  @$core.override
  DiagnosticApplyReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticApplyReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticApplyReply>(create);
  static DiagnosticApplyReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DiagnosticApplyReply_Outcome whichOutcome() =>
      _DiagnosticApplyReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DiagnosticApplyResult get result => $_getN(0);
  @$pb.TagNumber(1)
  set result(DiagnosticApplyResult value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => $_clearField(1);
  @$pb.TagNumber(1)
  DiagnosticApplyResult ensureResult() => $_ensure(0);

  @$pb.TagNumber(2)
  DiagnosticFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(DiagnosticFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
}

class DiagnosticSupportReport extends $pb.GeneratedMessage {
  factory DiagnosticSupportReport({
    $core.String? fileName,
    $core.List<$core.int>? content,
  }) {
    final result = create();
    if (fileName != null) result.fileName = fileName;
    if (content != null) result.content = content;
    return result;
  }

  DiagnosticSupportReport._();

  factory DiagnosticSupportReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticSupportReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticSupportReport',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fileName')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'content', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticSupportReport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticSupportReport copyWith(
          void Function(DiagnosticSupportReport) updates) =>
      super.copyWith((message) => updates(message as DiagnosticSupportReport))
          as DiagnosticSupportReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticSupportReport create() => DiagnosticSupportReport._();
  @$core.override
  DiagnosticSupportReport createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticSupportReport getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticSupportReport>(create);
  static DiagnosticSupportReport? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fileName => $_getSZ(0);
  @$pb.TagNumber(1)
  set fileName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFileName() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get content => $_getN(1);
  @$pb.TagNumber(2)
  set content($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => $_clearField(2);
}

enum DiagnosticSupportReply_Outcome { report, fault, notSet }

class DiagnosticSupportReply extends $pb.GeneratedMessage {
  factory DiagnosticSupportReply({
    DiagnosticSupportReport? report,
    DiagnosticFault? fault,
  }) {
    final result = create();
    if (report != null) result.report = report;
    if (fault != null) result.fault = fault;
    return result;
  }

  DiagnosticSupportReply._();

  factory DiagnosticSupportReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DiagnosticSupportReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DiagnosticSupportReply_Outcome>
      _DiagnosticSupportReply_OutcomeByTag = {
    1: DiagnosticSupportReply_Outcome.report,
    2: DiagnosticSupportReply_Outcome.fault,
    0: DiagnosticSupportReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiagnosticSupportReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DiagnosticSupportReport>(1, _omitFieldNames ? '' : 'report',
        subBuilder: DiagnosticSupportReport.create)
    ..aE<DiagnosticFault>(2, _omitFieldNames ? '' : 'fault',
        enumValues: DiagnosticFault.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticSupportReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticSupportReply copyWith(
          void Function(DiagnosticSupportReply) updates) =>
      super.copyWith((message) => updates(message as DiagnosticSupportReply))
          as DiagnosticSupportReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticSupportReply create() => DiagnosticSupportReply._();
  @$core.override
  DiagnosticSupportReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DiagnosticSupportReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DiagnosticSupportReply>(create);
  static DiagnosticSupportReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DiagnosticSupportReply_Outcome whichOutcome() =>
      _DiagnosticSupportReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DiagnosticSupportReport get report => $_getN(0);
  @$pb.TagNumber(1)
  set report(DiagnosticSupportReport value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReport() => $_has(0);
  @$pb.TagNumber(1)
  void clearReport() => $_clearField(1);
  @$pb.TagNumber(1)
  DiagnosticSupportReport ensureReport() => $_ensure(0);

  @$pb.TagNumber(2)
  DiagnosticFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault(DiagnosticFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
