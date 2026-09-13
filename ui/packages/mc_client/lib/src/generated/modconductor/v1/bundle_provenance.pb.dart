// This is a generated file - do not edit.
//
// Generated from modconductor/v1/bundle_provenance.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class BundleArchiveSource extends $pb.GeneratedMessage {
  factory BundleArchiveSource({
    $core.Iterable<$core.String>? path,
    $core.String? sha256,
  }) {
    final result = create();
    if (path != null) result.path.addAll(path);
    if (sha256 != null) result.sha256 = sha256;
    return result;
  }

  BundleArchiveSource._();

  factory BundleArchiveSource.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleArchiveSource.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleArchiveSource',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'sha256')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleArchiveSource clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleArchiveSource copyWith(void Function(BundleArchiveSource) updates) =>
      super.copyWith((message) => updates(message as BundleArchiveSource))
          as BundleArchiveSource;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleArchiveSource create() => BundleArchiveSource._();
  @$core.override
  BundleArchiveSource createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleArchiveSource getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleArchiveSource>(create);
  static BundleArchiveSource? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get path => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get sha256 => $_getSZ(1);
  @$pb.TagNumber(2)
  set sha256($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSha256() => $_has(1);
  @$pb.TagNumber(2)
  void clearSha256() => $_clearField(2);
}

class BundleProvenance extends $pb.GeneratedMessage {
  factory BundleProvenance({
    $core.String? parentSha256,
    $core.Iterable<BundleArchiveSource>? archives,
  }) {
    final result = create();
    if (parentSha256 != null) result.parentSha256 = parentSha256;
    if (archives != null) result.archives.addAll(archives);
    return result;
  }

  BundleProvenance._();

  factory BundleProvenance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BundleProvenance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BundleProvenance',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'parentSha256')
    ..pPM<BundleArchiveSource>(2, _omitFieldNames ? '' : 'archives',
        subBuilder: BundleArchiveSource.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleProvenance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BundleProvenance copyWith(void Function(BundleProvenance) updates) =>
      super.copyWith((message) => updates(message as BundleProvenance))
          as BundleProvenance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BundleProvenance create() => BundleProvenance._();
  @$core.override
  BundleProvenance createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BundleProvenance getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BundleProvenance>(create);
  static BundleProvenance? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get parentSha256 => $_getSZ(0);
  @$pb.TagNumber(1)
  set parentSha256($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParentSha256() => $_has(0);
  @$pb.TagNumber(1)
  void clearParentSha256() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<BundleArchiveSource> get archives => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
