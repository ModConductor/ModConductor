// This is a generated file - do not edit.
//
// Generated from modconductor/v1/installation_review.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class InstallationSourcePath extends $pb.GeneratedMessage {
  factory InstallationSourcePath({
    $core.Iterable<$core.String>? path,
  }) {
    final result = create();
    if (path != null) result.path.addAll(path);
    return result;
  }

  InstallationSourcePath._();

  factory InstallationSourcePath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationSourcePath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationSourcePath',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationSourcePath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationSourcePath copyWith(
          void Function(InstallationSourcePath) updates) =>
      super.copyWith((message) => updates(message as InstallationSourcePath))
          as InstallationSourcePath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationSourcePath create() => InstallationSourcePath._();
  @$core.override
  InstallationSourcePath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationSourcePath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationSourcePath>(create);
  static InstallationSourcePath? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get path => $_getList(0);
}

class InstallationReviewedFile extends $pb.GeneratedMessage {
  factory InstallationReviewedFile({
    $core.int? index,
    $core.Iterable<$core.String>? destination,
    $core.Iterable<$core.String>? source,
    $core.String? choice,
    $fixnum.Int64? bytes,
    $core.Iterable<InstallationSourcePath>? replaces,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (destination != null) result.destination.addAll(destination);
    if (source != null) result.source.addAll(source);
    if (choice != null) result.choice = choice;
    if (bytes != null) result.bytes = bytes;
    if (replaces != null) result.replaces.addAll(replaces);
    return result;
  }

  InstallationReviewedFile._();

  factory InstallationReviewedFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InstallationReviewedFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InstallationReviewedFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..pPS(2, _omitFieldNames ? '' : 'destination')
    ..pPS(3, _omitFieldNames ? '' : 'source')
    ..aOS(4, _omitFieldNames ? '' : 'choice')
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<InstallationSourcePath>(6, _omitFieldNames ? '' : 'replaces',
        subBuilder: InstallationSourcePath.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationReviewedFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InstallationReviewedFile copyWith(
          void Function(InstallationReviewedFile) updates) =>
      super.copyWith((message) => updates(message as InstallationReviewedFile))
          as InstallationReviewedFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InstallationReviewedFile create() => InstallationReviewedFile._();
  @$core.override
  InstallationReviewedFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InstallationReviewedFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InstallationReviewedFile>(create);
  static InstallationReviewedFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get destination => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get source => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get choice => $_getSZ(3);
  @$pb.TagNumber(4)
  set choice($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChoice() => $_has(3);
  @$pb.TagNumber(4)
  void clearChoice() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get bytes => $_getI64(4);
  @$pb.TagNumber(5)
  set bytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<InstallationSourcePath> get replaces => $_getList(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
