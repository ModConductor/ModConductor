// This is a generated file - do not edit.
//
// Generated from modconductor/v1/link_setup.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'link_setup.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'link_setup.pbenum.dart';

class LinkSetupRequest extends $pb.GeneratedMessage {
  factory LinkSetupRequest() => create();

  LinkSetupRequest._();

  factory LinkSetupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LinkSetupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LinkSetupRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkSetupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkSetupRequest copyWith(void Function(LinkSetupRequest) updates) =>
      super.copyWith((message) => updates(message as LinkSetupRequest))
          as LinkSetupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LinkSetupRequest create() => LinkSetupRequest._();
  @$core.override
  LinkSetupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LinkSetupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LinkSetupRequest>(create);
  static LinkSetupRequest? _defaultInstance;
}

class AddLinkSetupRequest extends $pb.GeneratedMessage {
  factory AddLinkSetupRequest({
    $core.String? executable,
  }) {
    final result = create();
    if (executable != null) result.executable = executable;
    return result;
  }

  AddLinkSetupRequest._();

  factory AddLinkSetupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddLinkSetupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddLinkSetupRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'executable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddLinkSetupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddLinkSetupRequest copyWith(void Function(AddLinkSetupRequest) updates) =>
      super.copyWith((message) => updates(message as AddLinkSetupRequest))
          as AddLinkSetupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddLinkSetupRequest create() => AddLinkSetupRequest._();
  @$core.override
  AddLinkSetupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddLinkSetupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddLinkSetupRequest>(create);
  static AddLinkSetupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get executable => $_getSZ(0);
  @$pb.TagNumber(1)
  set executable($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExecutable() => $_has(0);
  @$pb.TagNumber(1)
  void clearExecutable() => $_clearField(1);
}

class LinkSetupReply extends $pb.GeneratedMessage {
  factory LinkSetupReply({
    $core.bool? windows,
    $core.bool? available,
    LinkDefault? defaultApp,
    $core.bool? changed,
    $core.String? problem,
    $core.bool? canRemove,
  }) {
    final result = create();
    if (windows != null) result.windows = windows;
    if (available != null) result.available = available;
    if (defaultApp != null) result.defaultApp = defaultApp;
    if (changed != null) result.changed = changed;
    if (problem != null) result.problem = problem;
    if (canRemove != null) result.canRemove = canRemove;
    return result;
  }

  LinkSetupReply._();

  factory LinkSetupReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LinkSetupReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LinkSetupReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'windows')
    ..aOB(2, _omitFieldNames ? '' : 'available')
    ..aE<LinkDefault>(3, _omitFieldNames ? '' : 'defaultApp',
        enumValues: LinkDefault.values)
    ..aOB(4, _omitFieldNames ? '' : 'changed')
    ..aOS(5, _omitFieldNames ? '' : 'problem')
    ..aOB(6, _omitFieldNames ? '' : 'canRemove')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkSetupReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkSetupReply copyWith(void Function(LinkSetupReply) updates) =>
      super.copyWith((message) => updates(message as LinkSetupReply))
          as LinkSetupReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LinkSetupReply create() => LinkSetupReply._();
  @$core.override
  LinkSetupReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LinkSetupReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LinkSetupReply>(create);
  static LinkSetupReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get windows => $_getBF(0);
  @$pb.TagNumber(1)
  set windows($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWindows() => $_has(0);
  @$pb.TagNumber(1)
  void clearWindows() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get available => $_getBF(1);
  @$pb.TagNumber(2)
  set available($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAvailable() => $_has(1);
  @$pb.TagNumber(2)
  void clearAvailable() => $_clearField(2);

  @$pb.TagNumber(3)
  LinkDefault get defaultApp => $_getN(2);
  @$pb.TagNumber(3)
  set defaultApp(LinkDefault value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDefaultApp() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefaultApp() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get changed => $_getBF(3);
  @$pb.TagNumber(4)
  set changed($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChanged() => $_has(3);
  @$pb.TagNumber(4)
  void clearChanged() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get problem => $_getSZ(4);
  @$pb.TagNumber(5)
  set problem($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProblem() => $_has(4);
  @$pb.TagNumber(5)
  void clearProblem() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get canRemove => $_getBF(5);
  @$pb.TagNumber(6)
  set canRemove($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCanRemove() => $_has(5);
  @$pb.TagNumber(6)
  void clearCanRemove() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
