// This is a generated file - do not edit.
//
// Generated from modconductor/v1/nexus.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'artifacts.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class NexusStatusRequest extends $pb.GeneratedMessage {
  factory NexusStatusRequest() => create();

  NexusStatusRequest._();

  factory NexusStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusStatusRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusStatusRequest copyWith(void Function(NexusStatusRequest) updates) =>
      super.copyWith((message) => updates(message as NexusStatusRequest))
          as NexusStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusStatusRequest create() => NexusStatusRequest._();
  @$core.override
  NexusStatusRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusStatusRequest>(create);
  static NexusStatusRequest? _defaultInstance;
}

class NexusPersonalApiKeyRequest extends $pb.GeneratedMessage {
  factory NexusPersonalApiKeyRequest({
    $core.String? apiKey,
  }) {
    final result = create();
    if (apiKey != null) result.apiKey = apiKey;
    return result;
  }

  NexusPersonalApiKeyRequest._();

  factory NexusPersonalApiKeyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusPersonalApiKeyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusPersonalApiKeyRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'apiKey')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusPersonalApiKeyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusPersonalApiKeyRequest copyWith(
          void Function(NexusPersonalApiKeyRequest) updates) =>
      super.copyWith(
              (message) => updates(message as NexusPersonalApiKeyRequest))
          as NexusPersonalApiKeyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusPersonalApiKeyRequest create() => NexusPersonalApiKeyRequest._();
  @$core.override
  NexusPersonalApiKeyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusPersonalApiKeyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusPersonalApiKeyRequest>(create);
  static NexusPersonalApiKeyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get apiKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set apiKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasApiKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiKey() => $_clearField(1);
}

class NexusFailure extends $pb.GeneratedMessage {
  factory NexusFailure({
    $core.String? code,
    $core.String? message,
    $fixnum.Int64? retryAtUnixMs,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    if (retryAtUnixMs != null) result.retryAtUnixMs = retryAtUnixMs;
    return result;
  }

  NexusFailure._();

  factory NexusFailure.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusFailure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusFailure',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aInt64(3, _omitFieldNames ? '' : 'retryAtUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusFailure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusFailure copyWith(void Function(NexusFailure) updates) =>
      super.copyWith((message) => updates(message as NexusFailure))
          as NexusFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusFailure create() => NexusFailure._();
  @$core.override
  NexusFailure createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusFailure getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusFailure>(create);
  static NexusFailure? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get retryAtUnixMs => $_getI64(2);
  @$pb.TagNumber(3)
  set retryAtUnixMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRetryAtUnixMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearRetryAtUnixMs() => $_clearField(3);
}

class NexusAccountStatus extends $pb.GeneratedMessage {
  factory NexusAccountStatus({
    $core.bool? configured,
    $core.bool? waiting,
    $core.String? accountName,
    $core.bool? premium,
    NexusFailure? failure,
    $core.String? profileImageUrl,
  }) {
    final result = create();
    if (configured != null) result.configured = configured;
    if (waiting != null) result.waiting = waiting;
    if (accountName != null) result.accountName = accountName;
    if (premium != null) result.premium = premium;
    if (failure != null) result.failure = failure;
    if (profileImageUrl != null) result.profileImageUrl = profileImageUrl;
    return result;
  }

  NexusAccountStatus._();

  factory NexusAccountStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusAccountStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusAccountStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'configured')
    ..aOB(2, _omitFieldNames ? '' : 'waiting')
    ..aOS(3, _omitFieldNames ? '' : 'accountName')
    ..aOB(4, _omitFieldNames ? '' : 'premium')
    ..aOM<NexusFailure>(5, _omitFieldNames ? '' : 'failure',
        subBuilder: NexusFailure.create)
    ..aOS(6, _omitFieldNames ? '' : 'profileImageUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusAccountStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusAccountStatus copyWith(void Function(NexusAccountStatus) updates) =>
      super.copyWith((message) => updates(message as NexusAccountStatus))
          as NexusAccountStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusAccountStatus create() => NexusAccountStatus._();
  @$core.override
  NexusAccountStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusAccountStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusAccountStatus>(create);
  static NexusAccountStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get configured => $_getBF(0);
  @$pb.TagNumber(1)
  set configured($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfigured() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfigured() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get waiting => $_getBF(1);
  @$pb.TagNumber(2)
  set waiting($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWaiting() => $_has(1);
  @$pb.TagNumber(2)
  void clearWaiting() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get accountName => $_getSZ(2);
  @$pb.TagNumber(3)
  set accountName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAccountName() => $_has(2);
  @$pb.TagNumber(3)
  void clearAccountName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get premium => $_getBF(3);
  @$pb.TagNumber(4)
  set premium($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPremium() => $_has(3);
  @$pb.TagNumber(4)
  void clearPremium() => $_clearField(4);

  @$pb.TagNumber(5)
  NexusFailure get failure => $_getN(4);
  @$pb.TagNumber(5)
  set failure(NexusFailure value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasFailure() => $_has(4);
  @$pb.TagNumber(5)
  void clearFailure() => $_clearField(5);
  @$pb.TagNumber(5)
  NexusFailure ensureFailure() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get profileImageUrl => $_getSZ(5);
  @$pb.TagNumber(6)
  set profileImageUrl($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProfileImageUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearProfileImageUrl() => $_clearField(6);
}

class NexusModRequest extends $pb.GeneratedMessage {
  factory NexusModRequest({
    $core.String? workspaceId,
    $fixnum.Int64? modId,
    $core.String? profileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (modId != null) result.modId = modId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  NexusModRequest._();

  factory NexusModRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusModRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusModRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aInt64(2, _omitFieldNames ? '' : 'modId')
    ..aOS(3, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusModRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusModRequest copyWith(void Function(NexusModRequest) updates) =>
      super.copyWith((message) => updates(message as NexusModRequest))
          as NexusModRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusModRequest create() => NexusModRequest._();
  @$core.override
  NexusModRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusModRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusModRequest>(create);
  static NexusModRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get modId => $_getI64(1);
  @$pb.TagNumber(2)
  set modId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get profileId => $_getSZ(2);
  @$pb.TagNumber(3)
  set profileId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProfileId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfileId() => $_clearField(3);
}

class NexusFileInfo extends $pb.GeneratedMessage {
  factory NexusFileInfo({
    $fixnum.Int64? id,
    $core.String? name,
    $core.String? version,
    $core.String? category,
    $core.String? description,
    $fixnum.Int64? bytes,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    if (category != null) result.category = category;
    if (description != null) result.description = description;
    if (bytes != null) result.bytes = bytes;
    return result;
  }

  NexusFileInfo._();

  factory NexusFileInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusFileInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusFileInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..aOS(4, _omitFieldNames ? '' : 'category')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..aInt64(6, _omitFieldNames ? '' : 'bytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusFileInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusFileInfo copyWith(void Function(NexusFileInfo) updates) =>
      super.copyWith((message) => updates(message as NexusFileInfo))
          as NexusFileInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusFileInfo create() => NexusFileInfo._();
  @$core.override
  NexusFileInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusFileInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusFileInfo>(create);
  static NexusFileInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get category => $_getSZ(3);
  @$pb.TagNumber(4)
  set category($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCategory() => $_has(3);
  @$pb.TagNumber(4)
  void clearCategory() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get bytes => $_getI64(5);
  @$pb.TagNumber(6)
  set bytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearBytes() => $_clearField(6);
}

class NexusModInfo extends $pb.GeneratedMessage {
  factory NexusModInfo({
    $fixnum.Int64? id,
    $core.String? name,
    $core.String? summary,
    $core.Iterable<NexusFileInfo>? files,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (summary != null) result.summary = summary;
    if (files != null) result.files.addAll(files);
    return result;
  }

  NexusModInfo._();

  factory NexusModInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusModInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusModInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'summary')
    ..pPM<NexusFileInfo>(4, _omitFieldNames ? '' : 'files',
        subBuilder: NexusFileInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusModInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusModInfo copyWith(void Function(NexusModInfo) updates) =>
      super.copyWith((message) => updates(message as NexusModInfo))
          as NexusModInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusModInfo create() => NexusModInfo._();
  @$core.override
  NexusModInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusModInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusModInfo>(create);
  static NexusModInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get summary => $_getSZ(2);
  @$pb.TagNumber(3)
  set summary($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSummary() => $_has(2);
  @$pb.TagNumber(3)
  void clearSummary() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<NexusFileInfo> get files => $_getList(3);
}

enum NexusModReply_Result { mod, failure, notSet }

class NexusModReply extends $pb.GeneratedMessage {
  factory NexusModReply({
    NexusModInfo? mod,
    NexusFailure? failure,
  }) {
    final result = create();
    if (mod != null) result.mod = mod;
    if (failure != null) result.failure = failure;
    return result;
  }

  NexusModReply._();

  factory NexusModReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusModReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, NexusModReply_Result>
      _NexusModReply_ResultByTag = {
    1: NexusModReply_Result.mod,
    2: NexusModReply_Result.failure,
    0: NexusModReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusModReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<NexusModInfo>(1, _omitFieldNames ? '' : 'mod',
        subBuilder: NexusModInfo.create)
    ..aOM<NexusFailure>(2, _omitFieldNames ? '' : 'failure',
        subBuilder: NexusFailure.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusModReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusModReply copyWith(void Function(NexusModReply) updates) =>
      super.copyWith((message) => updates(message as NexusModReply))
          as NexusModReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusModReply create() => NexusModReply._();
  @$core.override
  NexusModReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusModReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusModReply>(create);
  static NexusModReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  NexusModReply_Result whichResult() =>
      _NexusModReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  NexusModInfo get mod => $_getN(0);
  @$pb.TagNumber(1)
  set mod(NexusModInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMod() => $_has(0);
  @$pb.TagNumber(1)
  void clearMod() => $_clearField(1);
  @$pb.TagNumber(1)
  NexusModInfo ensureMod() => $_ensure(0);

  @$pb.TagNumber(2)
  NexusFailure get failure => $_getN(1);
  @$pb.TagNumber(2)
  set failure(NexusFailure value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFailure() => $_has(1);
  @$pb.TagNumber(2)
  void clearFailure() => $_clearField(2);
  @$pb.TagNumber(2)
  NexusFailure ensureFailure() => $_ensure(1);
}

class NexusDownloadRequest extends $pb.GeneratedMessage {
  factory NexusDownloadRequest({
    $core.String? workspaceId,
    $core.String? artifactId,
    $fixnum.Int64? modId,
    $fixnum.Int64? fileId,
    $core.String? profileId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (artifactId != null) result.artifactId = artifactId;
    if (modId != null) result.modId = modId;
    if (fileId != null) result.fileId = fileId;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  NexusDownloadRequest._();

  factory NexusDownloadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusDownloadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusDownloadRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'artifactId')
    ..aInt64(3, _omitFieldNames ? '' : 'modId')
    ..aInt64(4, _omitFieldNames ? '' : 'fileId')
    ..aOS(5, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusDownloadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusDownloadRequest copyWith(void Function(NexusDownloadRequest) updates) =>
      super.copyWith((message) => updates(message as NexusDownloadRequest))
          as NexusDownloadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusDownloadRequest create() => NexusDownloadRequest._();
  @$core.override
  NexusDownloadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusDownloadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusDownloadRequest>(create);
  static NexusDownloadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get artifactId => $_getSZ(1);
  @$pb.TagNumber(2)
  set artifactId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasArtifactId() => $_has(1);
  @$pb.TagNumber(2)
  void clearArtifactId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get modId => $_getI64(2);
  @$pb.TagNumber(3)
  set modId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModId() => $_has(2);
  @$pb.TagNumber(3)
  void clearModId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get fileId => $_getI64(3);
  @$pb.TagNumber(4)
  set fileId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFileId() => $_has(3);
  @$pb.TagNumber(4)
  void clearFileId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get profileId => $_getSZ(4);
  @$pb.TagNumber(5)
  set profileId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProfileId() => $_has(4);
  @$pb.TagNumber(5)
  void clearProfileId() => $_clearField(5);
}

enum NexusDownloadReply_Result { artifact, failure, notSet }

class NexusDownloadReply extends $pb.GeneratedMessage {
  factory NexusDownloadReply({
    $1.ArchiveArtifact? artifact,
    NexusFailure? failure,
  }) {
    final result = create();
    if (artifact != null) result.artifact = artifact;
    if (failure != null) result.failure = failure;
    return result;
  }

  NexusDownloadReply._();

  factory NexusDownloadReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NexusDownloadReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, NexusDownloadReply_Result>
      _NexusDownloadReply_ResultByTag = {
    1: NexusDownloadReply_Result.artifact,
    2: NexusDownloadReply_Result.failure,
    0: NexusDownloadReply_Result.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NexusDownloadReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$1.ArchiveArtifact>(1, _omitFieldNames ? '' : 'artifact',
        subBuilder: $1.ArchiveArtifact.create)
    ..aOM<NexusFailure>(2, _omitFieldNames ? '' : 'failure',
        subBuilder: NexusFailure.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusDownloadReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NexusDownloadReply copyWith(void Function(NexusDownloadReply) updates) =>
      super.copyWith((message) => updates(message as NexusDownloadReply))
          as NexusDownloadReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NexusDownloadReply create() => NexusDownloadReply._();
  @$core.override
  NexusDownloadReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NexusDownloadReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NexusDownloadReply>(create);
  static NexusDownloadReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  NexusDownloadReply_Result whichResult() =>
      _NexusDownloadReply_ResultByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResult() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.ArchiveArtifact get artifact => $_getN(0);
  @$pb.TagNumber(1)
  set artifact($1.ArchiveArtifact value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasArtifact() => $_has(0);
  @$pb.TagNumber(1)
  void clearArtifact() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ArchiveArtifact ensureArtifact() => $_ensure(0);

  @$pb.TagNumber(2)
  NexusFailure get failure => $_getN(1);
  @$pb.TagNumber(2)
  set failure(NexusFailure value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFailure() => $_has(1);
  @$pb.TagNumber(2)
  void clearFailure() => $_clearField(2);
  @$pb.TagNumber(2)
  NexusFailure ensureFailure() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
