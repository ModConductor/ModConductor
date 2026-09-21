// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nxm.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'artifacts.pb.dart' as $2;
import 'nexus.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class NexusIngressRequest extends $pb.GeneratedMessage {
  factory NexusIngressRequest({
    $core.int? processId,
  }) {
    final result = create();
    if (processId != null) result.processId = processId;
    return result;
  }

  NexusIngressRequest._();

  factory NexusIngressRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusIngressRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusIngressRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'processId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusIngressRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusIngressRequest copyWith(void Function(NexusIngressRequest) updates) =>
      super.copyWith((message) => updates(message as NexusIngressRequest))
          as NexusIngressRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusIngressRequest create() => NexusIngressRequest._();
  @$core.override
  NexusIngressRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusIngressRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusIngressRequest>(create);
  static NexusIngressRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get processId => $_getIZ(0);
  @$pb.TagNumber(1)
  set processId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProcessId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProcessId() => $_clearField(1);
}

class NexusIngressReply extends $pb.GeneratedMessage {
  factory NexusIngressReply({
    $core.String? endpoint,
    $core.List<$core.int>? capability,
    $core.int? processId,
  }) {
    final result = create();
    if (endpoint != null) result.endpoint = endpoint;
    if (capability != null) result.capability = capability;
    if (processId != null) result.processId = processId;
    return result;
  }

  NexusIngressReply._();

  factory NexusIngressReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusIngressReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusIngressReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'endpoint')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'capability', $pb.PbFieldType.OY)
    ..aI(3, _omitFieldNames ? '' : 'processId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusIngressReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusIngressReply copyWith(void Function(NexusIngressReply) updates) =>
      super.copyWith((message) => updates(message as NexusIngressReply))
          as NexusIngressReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusIngressReply create() => NexusIngressReply._();
  @$core.override
  NexusIngressReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusIngressReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusIngressReply>(create);
  static NexusIngressReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get endpoint => $_getSZ(0);
  @$pb.TagNumber(1)
  set endpoint($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEndpoint() => $_has(0);
  @$pb.TagNumber(1)
  void clearEndpoint() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get capability => $_getN(1);
  @$pb.TagNumber(2)
  set capability($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCapability() => $_has(1);
  @$pb.TagNumber(2)
  void clearCapability() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get processId => $_getIZ(2);
  @$pb.TagNumber(3)
  set processId($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProcessId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProcessId() => $_clearField(3);
}

class NexusLinkRequest extends $pb.GeneratedMessage {
  factory NexusLinkRequest({
    $core.String? reference,
    $core.String? workspaceId,
    $core.String? profileId,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  NexusLinkRequest._();

  factory NexusLinkRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusLinkRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusLinkRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'reference')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusLinkRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusLinkRequest copyWith(void Function(NexusLinkRequest) updates) =>
      super.copyWith((message) => updates(message as NexusLinkRequest))
          as NexusLinkRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusLinkRequest create() => NexusLinkRequest._();
  @$core.override
  NexusLinkRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusLinkRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusLinkRequest>(create);
  static NexusLinkRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get reference => $_getSZ(0);
  @$pb.TagNumber(1)
  set reference($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);

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
}

class NexusLinkReply extends $pb.GeneratedMessage {
  factory NexusLinkReply({
    $core.String? game,
    $1.NexusFileInfo? file,
    $core.String? problem,
    $core.bool? signInRequired,
    $2.ArchiveArtifact? artifact,
    $core.String? problemDetail,
  }) {
    final result = create();
    if (game != null) result.game = game;
    if (file != null) result.file = file;
    if (problem != null) result.problem = problem;
    if (signInRequired != null) result.signInRequired = signInRequired;
    if (artifact != null) result.artifact = artifact;
    if (problemDetail != null) result.problemDetail = problemDetail;
    return result;
  }

  NexusLinkReply._();

  factory NexusLinkReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusLinkReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusLinkReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'game')
    ..aOM<$1.NexusFileInfo>(2, _omitFieldNames ? '' : 'file',
        subBuilder: $1.NexusFileInfo.create)
    ..aOS(3, _omitFieldNames ? '' : 'problem')
    ..aOB(4, _omitFieldNames ? '' : 'signInRequired')
    ..aOM<$2.ArchiveArtifact>(5, _omitFieldNames ? '' : 'artifact',
        subBuilder: $2.ArchiveArtifact.create)
    ..aOS(6, _omitFieldNames ? '' : 'problemDetail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusLinkReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusLinkReply copyWith(void Function(NexusLinkReply) updates) =>
      super.copyWith((message) => updates(message as NexusLinkReply))
          as NexusLinkReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusLinkReply create() => NexusLinkReply._();
  @$core.override
  NexusLinkReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusLinkReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusLinkReply>(create);
  static NexusLinkReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get game => $_getSZ(0);
  @$pb.TagNumber(1)
  set game($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGame() => $_has(0);
  @$pb.TagNumber(1)
  void clearGame() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.NexusFileInfo get file => $_getN(1);
  @$pb.TagNumber(2)
  set file($1.NexusFileInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFile() => $_has(1);
  @$pb.TagNumber(2)
  void clearFile() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.NexusFileInfo ensureFile() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get problem => $_getSZ(2);
  @$pb.TagNumber(3)
  set problem($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProblem() => $_has(2);
  @$pb.TagNumber(3)
  void clearProblem() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get signInRequired => $_getBF(3);
  @$pb.TagNumber(4)
  set signInRequired($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSignInRequired() => $_has(3);
  @$pb.TagNumber(4)
  void clearSignInRequired() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.ArchiveArtifact get artifact => $_getN(4);
  @$pb.TagNumber(5)
  set artifact($2.ArchiveArtifact value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasArtifact() => $_has(4);
  @$pb.TagNumber(5)
  void clearArtifact() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.ArchiveArtifact ensureArtifact() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get problemDetail => $_getSZ(5);
  @$pb.TagNumber(6)
  set problemDetail($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProblemDetail() => $_has(5);
  @$pb.TagNumber(6)
  void clearProblemDetail() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
