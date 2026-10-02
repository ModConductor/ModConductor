// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bepinex.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'file_plans.pb.dart' as $2;
import 'thunderstore.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class LoaderRequest extends $pb.GeneratedMessage {
  factory LoaderRequest({
    $core.String? workspaceId,
    $core.String? profileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  LoaderRequest._();

  factory LoaderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoaderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoaderRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoaderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoaderRequest copyWith(void Function(LoaderRequest) updates) =>
      super.copyWith((message) => updates(message as LoaderRequest))
          as LoaderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoaderRequest create() => LoaderRequest._();
  @$core.override
  LoaderRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoaderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoaderRequest>(create);
  static LoaderRequest? _defaultInstance;

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
}

class ChangeLoaderRequest extends $pb.GeneratedMessage {
  factory ChangeLoaderRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $fixnum.Int64? contextRevision,
    $fixnum.Int64? selectionRevision,
    $core.bool? enabled,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (contextRevision != null) result.contextRevision = contextRevision;
    if (selectionRevision != null) result.selectionRevision = selectionRevision;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  ChangeLoaderRequest._();

  factory ChangeLoaderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangeLoaderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeLoaderRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'contextRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'selectionRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(5, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeLoaderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeLoaderRequest copyWith(void Function(ChangeLoaderRequest) updates) =>
      super.copyWith((message) => updates(message as ChangeLoaderRequest))
          as ChangeLoaderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeLoaderRequest create() => ChangeLoaderRequest._();
  @$core.override
  ChangeLoaderRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChangeLoaderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeLoaderRequest>(create);
  static ChangeLoaderRequest? _defaultInstance;

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
  $fixnum.Int64 get contextRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set contextRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContextRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearContextRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get selectionRevision => $_getI64(3);
  @$pb.TagNumber(4)
  set selectionRevision($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSelectionRevision() => $_has(3);
  @$pb.TagNumber(4)
  void clearSelectionRevision() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get enabled => $_getBF(4);
  @$pb.TagNumber(5)
  set enabled($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnabled() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnabled() => $_clearField(5);
}

class LoaderInfo extends $pb.GeneratedMessage {
  factory LoaderInfo({
    $core.String? workspaceId,
    $core.String? profileId,
    $fixnum.Int64? contextRevision,
    $fixnum.Int64? selectionRevision,
    $1.ThunderstoreVersionReference? package,
    $core.String? modId,
    $core.bool? enabled,
    $core.bool? settingsAvailable,
    $core.bool? logAvailable,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (contextRevision != null) result.contextRevision = contextRevision;
    if (selectionRevision != null) result.selectionRevision = selectionRevision;
    if (package != null) result.package = package;
    if (modId != null) result.modId = modId;
    if (enabled != null) result.enabled = enabled;
    if (settingsAvailable != null) result.settingsAvailable = settingsAvailable;
    if (logAvailable != null) result.logAvailable = logAvailable;
    return result;
  }

  LoaderInfo._();

  factory LoaderInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoaderInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoaderInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'contextRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'selectionRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$1.ThunderstoreVersionReference>(5, _omitFieldNames ? '' : 'package',
        subBuilder: $1.ThunderstoreVersionReference.create)
    ..aOS(6, _omitFieldNames ? '' : 'modId')
    ..aOB(7, _omitFieldNames ? '' : 'enabled')
    ..aOB(8, _omitFieldNames ? '' : 'settingsAvailable')
    ..aOB(9, _omitFieldNames ? '' : 'logAvailable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoaderInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoaderInfo copyWith(void Function(LoaderInfo) updates) =>
      super.copyWith((message) => updates(message as LoaderInfo)) as LoaderInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoaderInfo create() => LoaderInfo._();
  @$core.override
  LoaderInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoaderInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoaderInfo>(create);
  static LoaderInfo? _defaultInstance;

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
  $fixnum.Int64 get contextRevision => $_getI64(2);
  @$pb.TagNumber(3)
  set contextRevision($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContextRevision() => $_has(2);
  @$pb.TagNumber(3)
  void clearContextRevision() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get selectionRevision => $_getI64(3);
  @$pb.TagNumber(4)
  set selectionRevision($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSelectionRevision() => $_has(3);
  @$pb.TagNumber(4)
  void clearSelectionRevision() => $_clearField(4);

  @$pb.TagNumber(5)
  $1.ThunderstoreVersionReference get package => $_getN(4);
  @$pb.TagNumber(5)
  set package($1.ThunderstoreVersionReference value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPackage() => $_has(4);
  @$pb.TagNumber(5)
  void clearPackage() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.ThunderstoreVersionReference ensurePackage() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get modId => $_getSZ(5);
  @$pb.TagNumber(6)
  set modId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasModId() => $_has(5);
  @$pb.TagNumber(6)
  void clearModId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get enabled => $_getBF(6);
  @$pb.TagNumber(7)
  set enabled($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEnabled() => $_has(6);
  @$pb.TagNumber(7)
  void clearEnabled() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get settingsAvailable => $_getBF(7);
  @$pb.TagNumber(8)
  set settingsAvailable($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSettingsAvailable() => $_has(7);
  @$pb.TagNumber(8)
  void clearSettingsAvailable() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get logAvailable => $_getBF(8);
  @$pb.TagNumber(9)
  set logAvailable($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLogAvailable() => $_has(8);
  @$pb.TagNumber(9)
  void clearLogAvailable() => $_clearField(9);
}

enum LoaderReply_Result { loader, problem, notSet }

class LoaderReply extends $pb.GeneratedMessage {
  factory LoaderReply({
    LoaderInfo? loader,
    $core.String? problem,
  }) {
    final result = create();
    if (loader != null) result.loader = loader;
    if (problem != null) result.problem = problem;
    return result;
  }

  LoaderReply._();

  factory LoaderReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoaderReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, LoaderReply_Result>
      _LoaderReply_ResultByTag = {
    1: LoaderReply_Result.loader,
    2: LoaderReply_Result.problem,
    0: LoaderReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoaderReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<LoaderInfo>(1, _omitFieldNames ? '' : 'loader',
        subBuilder: LoaderInfo.create)
    ..aOS(2, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoaderReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoaderReply copyWith(void Function(LoaderReply) updates) =>
      super.copyWith((message) => updates(message as LoaderReply))
          as LoaderReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoaderReply create() => LoaderReply._();
  @$core.override
  LoaderReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoaderReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoaderReply>(create);
  static LoaderReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  LoaderReply_Result whichResult() =>
      _LoaderReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  LoaderInfo get loader => $_getN(0);
  @$pb.TagNumber(1)
  set loader(LoaderInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLoader() => $_has(0);
  @$pb.TagNumber(1)
  void clearLoader() => $_clearField(1);
  @$pb.TagNumber(1)
  LoaderInfo ensureLoader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get problem => $_getSZ(1);
  @$pb.TagNumber(2)
  set problem($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
}

class LoaderText extends $pb.GeneratedMessage {
  factory LoaderText({
    $2.TextDocument? document,
    $core.List<$core.int>? original,
  }) {
    final result = create();
    if (document != null) result.document = document;
    if (original != null) result.original = original;
    return result;
  }

  LoaderText._();

  factory LoaderText.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoaderText.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoaderText',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$2.TextDocument>(1, _omitFieldNames ? '' : 'document',
        subBuilder: $2.TextDocument.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'original', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoaderText clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoaderText copyWith(void Function(LoaderText) updates) =>
      super.copyWith((message) => updates(message as LoaderText)) as LoaderText;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoaderText create() => LoaderText._();
  @$core.override
  LoaderText createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoaderText getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoaderText>(create);
  static LoaderText? _defaultInstance;

  @$pb.TagNumber(1)
  $2.TextDocument get document => $_getN(0);
  @$pb.TagNumber(1)
  set document($2.TextDocument value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDocument() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocument() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.TextDocument ensureDocument() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get original => $_getN(1);
  @$pb.TagNumber(2)
  set original($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOriginal() => $_has(1);
  @$pb.TagNumber(2)
  void clearOriginal() => $_clearField(2);
}

enum LoaderTextReply_Result { text, problem, notSet }

class LoaderTextReply extends $pb.GeneratedMessage {
  factory LoaderTextReply({
    LoaderText? text,
    $core.String? problem,
  }) {
    final result = create();
    if (text != null) result.text = text;
    if (problem != null) result.problem = problem;
    return result;
  }

  LoaderTextReply._();

  factory LoaderTextReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoaderTextReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, LoaderTextReply_Result>
      _LoaderTextReply_ResultByTag = {
    1: LoaderTextReply_Result.text,
    2: LoaderTextReply_Result.problem,
    0: LoaderTextReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoaderTextReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<LoaderText>(1, _omitFieldNames ? '' : 'text',
        subBuilder: LoaderText.create)
    ..aOS(2, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoaderTextReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoaderTextReply copyWith(void Function(LoaderTextReply) updates) =>
      super.copyWith((message) => updates(message as LoaderTextReply))
          as LoaderTextReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoaderTextReply create() => LoaderTextReply._();
  @$core.override
  LoaderTextReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoaderTextReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoaderTextReply>(create);
  static LoaderTextReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  LoaderTextReply_Result whichResult() =>
      _LoaderTextReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  LoaderText get text => $_getN(0);
  @$pb.TagNumber(1)
  set text(LoaderText value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);
  @$pb.TagNumber(1)
  LoaderText ensureText() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get problem => $_getSZ(1);
  @$pb.TagNumber(2)
  set problem($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProblem() => $_has(1);
  @$pb.TagNumber(2)
  void clearProblem() => $_clearField(2);
}

class SaveLoaderSettingsRequest extends $pb.GeneratedMessage {
  factory SaveLoaderSettingsRequest({
    $core.String? workspaceId,
    $core.String? profileId,
    $core.List<$core.int>? original,
    $core.String? content,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (profileId != null) result.profileId = profileId;
    if (original != null) result.original = original;
    if (content != null) result.content = content;
    return result;
  }

  SaveLoaderSettingsRequest._();

  factory SaveLoaderSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SaveLoaderSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SaveLoaderSettingsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'original', $pb.PbFieldType.OY)
    ..aOS(4, _omitFieldNames ? '' : 'content')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveLoaderSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveLoaderSettingsRequest copyWith(
          void Function(SaveLoaderSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as SaveLoaderSettingsRequest))
          as SaveLoaderSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveLoaderSettingsRequest create() => SaveLoaderSettingsRequest._();
  @$core.override
  SaveLoaderSettingsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SaveLoaderSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveLoaderSettingsRequest>(create);
  static SaveLoaderSettingsRequest? _defaultInstance;

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
  $core.List<$core.int> get original => $_getN(2);
  @$pb.TagNumber(3)
  set original($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOriginal() => $_has(2);
  @$pb.TagNumber(3)
  void clearOriginal() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get content => $_getSZ(3);
  @$pb.TagNumber(4)
  set content($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContent() => $_has(3);
  @$pb.TagNumber(4)
  void clearContent() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
