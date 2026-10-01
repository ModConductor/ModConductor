// This is a generated file - do not edit.
//
// Generated from modconductor/v1/thunderstore.proto.

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

class ThunderstorePackageReference extends $pb.GeneratedMessage {
  factory ThunderstorePackageReference({
    $core.String? community,
    $core.String? namespace,
    $core.String? name,
  }) {
    final result = create();
    if (community != null) result.community = community;
    if (namespace != null) result.namespace = namespace;
    if (name != null) result.name = name;
    return result;
  }

  ThunderstorePackageReference._();

  factory ThunderstorePackageReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstorePackageReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstorePackageReference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'community')
    ..aOS(2, _omitFieldNames ? '' : 'namespace')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackageReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackageReference copyWith(
          void Function(ThunderstorePackageReference) updates) =>
      super.copyWith(
              (message) => updates(message as ThunderstorePackageReference))
          as ThunderstorePackageReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstorePackageReference create() =>
      ThunderstorePackageReference._();
  @$core.override
  ThunderstorePackageReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstorePackageReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstorePackageReference>(create);
  static ThunderstorePackageReference? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get community => $_getSZ(0);
  @$pb.TagNumber(1)
  set community($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCommunity() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommunity() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get namespace => $_getSZ(1);
  @$pb.TagNumber(2)
  set namespace($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNamespace() => $_has(1);
  @$pb.TagNumber(2)
  void clearNamespace() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);
}

class ThunderstoreVersionReference extends $pb.GeneratedMessage {
  factory ThunderstoreVersionReference({
    ThunderstorePackageReference? package,
    $core.String? version,
  }) {
    final result = create();
    if (package != null) result.package = package;
    if (version != null) result.version = version;
    return result;
  }

  ThunderstoreVersionReference._();

  factory ThunderstoreVersionReference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreVersionReference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreVersionReference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ThunderstorePackageReference>(1, _omitFieldNames ? '' : 'package',
        subBuilder: ThunderstorePackageReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreVersionReference clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreVersionReference copyWith(
          void Function(ThunderstoreVersionReference) updates) =>
      super.copyWith(
              (message) => updates(message as ThunderstoreVersionReference))
          as ThunderstoreVersionReference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreVersionReference create() =>
      ThunderstoreVersionReference._();
  @$core.override
  ThunderstoreVersionReference createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreVersionReference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreVersionReference>(create);
  static ThunderstoreVersionReference? _defaultInstance;

  @$pb.TagNumber(1)
  ThunderstorePackageReference get package => $_getN(0);
  @$pb.TagNumber(1)
  set package(ThunderstorePackageReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => $_clearField(1);
  @$pb.TagNumber(1)
  ThunderstorePackageReference ensurePackage() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);
}

class ThunderstoreFailure extends $pb.GeneratedMessage {
  factory ThunderstoreFailure({
    $core.String? message,
    $fixnum.Int64? retryAtUnixMs,
  }) {
    final result = create();
    if (message != null) result.message = message;
    if (retryAtUnixMs != null) result.retryAtUnixMs = retryAtUnixMs;
    return result;
  }

  ThunderstoreFailure._();

  factory ThunderstoreFailure.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreFailure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreFailure',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..aInt64(2, _omitFieldNames ? '' : 'retryAtUnixMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreFailure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreFailure copyWith(void Function(ThunderstoreFailure) updates) =>
      super.copyWith((message) => updates(message as ThunderstoreFailure))
          as ThunderstoreFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreFailure create() => ThunderstoreFailure._();
  @$core.override
  ThunderstoreFailure createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreFailure getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreFailure>(create);
  static ThunderstoreFailure? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get retryAtUnixMs => $_getI64(1);
  @$pb.TagNumber(2)
  set retryAtUnixMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRetryAtUnixMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearRetryAtUnixMs() => $_clearField(2);
}

class ThunderstoreInstalled extends $pb.GeneratedMessage {
  factory ThunderstoreInstalled({
    ThunderstoreVersionReference? reference,
    $core.String? modId,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (modId != null) result.modId = modId;
    return result;
  }

  ThunderstoreInstalled._();

  factory ThunderstoreInstalled.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreInstalled.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreInstalled',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ThunderstoreVersionReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: ThunderstoreVersionReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'modId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreInstalled clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreInstalled copyWith(
          void Function(ThunderstoreInstalled) updates) =>
      super.copyWith((message) => updates(message as ThunderstoreInstalled))
          as ThunderstoreInstalled;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreInstalled create() => ThunderstoreInstalled._();
  @$core.override
  ThunderstoreInstalled createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreInstalled getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreInstalled>(create);
  static ThunderstoreInstalled? _defaultInstance;

  @$pb.TagNumber(1)
  ThunderstoreVersionReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(ThunderstoreVersionReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  ThunderstoreVersionReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get modId => $_getSZ(1);
  @$pb.TagNumber(2)
  set modId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModId() => $_has(1);
  @$pb.TagNumber(2)
  void clearModId() => $_clearField(2);
}

class ThunderstorePackagePreview extends $pb.GeneratedMessage {
  factory ThunderstorePackagePreview({
    ThunderstorePackageReference? package,
    $core.String? description,
    $core.String? iconUrl,
    $core.bool? deprecated,
    $core.Iterable<ThunderstoreInstalled>? installed,
  }) {
    final result = create();
    if (package != null) result.package = package;
    if (description != null) result.description = description;
    if (iconUrl != null) result.iconUrl = iconUrl;
    if (deprecated != null) result.deprecated = deprecated;
    if (installed != null) result.installed.addAll(installed);
    return result;
  }

  ThunderstorePackagePreview._();

  factory ThunderstorePackagePreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstorePackagePreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstorePackagePreview',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ThunderstorePackageReference>(1, _omitFieldNames ? '' : 'package',
        subBuilder: ThunderstorePackageReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOS(3, _omitFieldNames ? '' : 'iconUrl')
    ..aOB(4, _omitFieldNames ? '' : 'deprecated')
    ..pPM<ThunderstoreInstalled>(5, _omitFieldNames ? '' : 'installed',
        subBuilder: ThunderstoreInstalled.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackagePreview clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackagePreview copyWith(
          void Function(ThunderstorePackagePreview) updates) =>
      super.copyWith(
              (message) => updates(message as ThunderstorePackagePreview))
          as ThunderstorePackagePreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstorePackagePreview create() => ThunderstorePackagePreview._();
  @$core.override
  ThunderstorePackagePreview createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstorePackagePreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstorePackagePreview>(create);
  static ThunderstorePackagePreview? _defaultInstance;

  @$pb.TagNumber(1)
  ThunderstorePackageReference get package => $_getN(0);
  @$pb.TagNumber(1)
  set package(ThunderstorePackageReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => $_clearField(1);
  @$pb.TagNumber(1)
  ThunderstorePackageReference ensurePackage() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get iconUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set iconUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIconUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearIconUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get deprecated => $_getBF(3);
  @$pb.TagNumber(4)
  set deprecated($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDeprecated() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeprecated() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<ThunderstoreInstalled> get installed => $_getList(4);
}

class ThunderstoreSearchRequest extends $pb.GeneratedMessage {
  factory ThunderstoreSearchRequest({
    $core.String? workspaceId,
    $core.String? community,
    $core.String? query,
    $core.String? ordering,
    $core.int? page,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (community != null) result.community = community;
    if (query != null) result.query = query;
    if (ordering != null) result.ordering = ordering;
    if (page != null) result.page = page;
    return result;
  }

  ThunderstoreSearchRequest._();

  factory ThunderstoreSearchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreSearchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreSearchRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'community')
    ..aOS(3, _omitFieldNames ? '' : 'query')
    ..aOS(4, _omitFieldNames ? '' : 'ordering')
    ..aI(5, _omitFieldNames ? '' : 'page')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreSearchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreSearchRequest copyWith(
          void Function(ThunderstoreSearchRequest) updates) =>
      super.copyWith((message) => updates(message as ThunderstoreSearchRequest))
          as ThunderstoreSearchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreSearchRequest create() => ThunderstoreSearchRequest._();
  @$core.override
  ThunderstoreSearchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreSearchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreSearchRequest>(create);
  static ThunderstoreSearchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get community => $_getSZ(1);
  @$pb.TagNumber(2)
  set community($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommunity() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommunity() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get query => $_getSZ(2);
  @$pb.TagNumber(3)
  set query($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQuery() => $_has(2);
  @$pb.TagNumber(3)
  void clearQuery() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get ordering => $_getSZ(3);
  @$pb.TagNumber(4)
  set ordering($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOrdering() => $_has(3);
  @$pb.TagNumber(4)
  void clearOrdering() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get page => $_getIZ(4);
  @$pb.TagNumber(5)
  set page($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPage() => $_has(4);
  @$pb.TagNumber(5)
  void clearPage() => $_clearField(5);
}

class ThunderstorePackages extends $pb.GeneratedMessage {
  factory ThunderstorePackages({
    $core.Iterable<ThunderstorePackagePreview>? entries,
    $core.int? count,
    $core.int? nextPage,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    if (count != null) result.count = count;
    if (nextPage != null) result.nextPage = nextPage;
    return result;
  }

  ThunderstorePackages._();

  factory ThunderstorePackages.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstorePackages.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstorePackages',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPM<ThunderstorePackagePreview>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: ThunderstorePackagePreview.create)
    ..aI(2, _omitFieldNames ? '' : 'count')
    ..aI(3, _omitFieldNames ? '' : 'nextPage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackages clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackages copyWith(void Function(ThunderstorePackages) updates) =>
      super.copyWith((message) => updates(message as ThunderstorePackages))
          as ThunderstorePackages;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstorePackages create() => ThunderstorePackages._();
  @$core.override
  ThunderstorePackages createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstorePackages getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstorePackages>(create);
  static ThunderstorePackages? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ThunderstorePackagePreview> get entries => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get count => $_getIZ(1);
  @$pb.TagNumber(2)
  set count($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get nextPage => $_getIZ(2);
  @$pb.TagNumber(3)
  set nextPage($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNextPage() => $_has(2);
  @$pb.TagNumber(3)
  void clearNextPage() => $_clearField(3);
}

enum ThunderstoreSearchReply_Outcome { packages, failure, notSet }

class ThunderstoreSearchReply extends $pb.GeneratedMessage {
  factory ThunderstoreSearchReply({
    ThunderstorePackages? packages,
    ThunderstoreFailure? failure,
  }) {
    final result = create();
    if (packages != null) result.packages = packages;
    if (failure != null) result.failure = failure;
    return result;
  }

  ThunderstoreSearchReply._();

  factory ThunderstoreSearchReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreSearchReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ThunderstoreSearchReply_Outcome>
      _ThunderstoreSearchReply_OutcomeByTag = {
    1: ThunderstoreSearchReply_Outcome.packages,
    2: ThunderstoreSearchReply_Outcome.failure,
    0: ThunderstoreSearchReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreSearchReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ThunderstorePackages>(1, _omitFieldNames ? '' : 'packages',
        subBuilder: ThunderstorePackages.create)
    ..aOM<ThunderstoreFailure>(2, _omitFieldNames ? '' : 'failure',
        subBuilder: ThunderstoreFailure.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreSearchReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreSearchReply copyWith(
          void Function(ThunderstoreSearchReply) updates) =>
      super.copyWith((message) => updates(message as ThunderstoreSearchReply))
          as ThunderstoreSearchReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreSearchReply create() => ThunderstoreSearchReply._();
  @$core.override
  ThunderstoreSearchReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreSearchReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreSearchReply>(create);
  static ThunderstoreSearchReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ThunderstoreSearchReply_Outcome whichOutcome() =>
      _ThunderstoreSearchReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ThunderstorePackages get packages => $_getN(0);
  @$pb.TagNumber(1)
  set packages(ThunderstorePackages value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPackages() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackages() => $_clearField(1);
  @$pb.TagNumber(1)
  ThunderstorePackages ensurePackages() => $_ensure(0);

  @$pb.TagNumber(2)
  ThunderstoreFailure get failure => $_getN(1);
  @$pb.TagNumber(2)
  set failure(ThunderstoreFailure value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFailure() => $_has(1);
  @$pb.TagNumber(2)
  void clearFailure() => $_clearField(2);
  @$pb.TagNumber(2)
  ThunderstoreFailure ensureFailure() => $_ensure(1);
}

class ThunderstoreDependency extends $pb.GeneratedMessage {
  factory ThunderstoreDependency({
    ThunderstoreVersionReference? reference,
    $core.bool? available,
    $core.Iterable<ThunderstoreInstalled>? installed,
    $core.String? iconUrl,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (available != null) result.available = available;
    if (installed != null) result.installed.addAll(installed);
    if (iconUrl != null) result.iconUrl = iconUrl;
    return result;
  }

  ThunderstoreDependency._();

  factory ThunderstoreDependency.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreDependency.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreDependency',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ThunderstoreVersionReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: ThunderstoreVersionReference.create)
    ..aOB(2, _omitFieldNames ? '' : 'available')
    ..pPM<ThunderstoreInstalled>(3, _omitFieldNames ? '' : 'installed',
        subBuilder: ThunderstoreInstalled.create)
    ..aOS(4, _omitFieldNames ? '' : 'iconUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreDependency clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreDependency copyWith(
          void Function(ThunderstoreDependency) updates) =>
      super.copyWith((message) => updates(message as ThunderstoreDependency))
          as ThunderstoreDependency;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreDependency create() => ThunderstoreDependency._();
  @$core.override
  ThunderstoreDependency createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreDependency getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreDependency>(create);
  static ThunderstoreDependency? _defaultInstance;

  @$pb.TagNumber(1)
  ThunderstoreVersionReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(ThunderstoreVersionReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  ThunderstoreVersionReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get available => $_getBF(1);
  @$pb.TagNumber(2)
  set available($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAvailable() => $_has(1);
  @$pb.TagNumber(2)
  void clearAvailable() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<ThunderstoreInstalled> get installed => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get iconUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set iconUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIconUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearIconUrl() => $_clearField(4);
}

class ThunderstorePackageRequest extends $pb.GeneratedMessage {
  factory ThunderstorePackageRequest({
    $core.String? workspaceId,
    ThunderstorePackageReference? package,
    $core.String? version,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (package != null) result.package = package;
    if (version != null) result.version = version;
    return result;
  }

  ThunderstorePackageRequest._();

  factory ThunderstorePackageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstorePackageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstorePackageRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOM<ThunderstorePackageReference>(2, _omitFieldNames ? '' : 'package',
        subBuilder: ThunderstorePackageReference.create)
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackageRequest copyWith(
          void Function(ThunderstorePackageRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ThunderstorePackageRequest))
          as ThunderstorePackageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstorePackageRequest create() => ThunderstorePackageRequest._();
  @$core.override
  ThunderstorePackageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstorePackageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstorePackageRequest>(create);
  static ThunderstorePackageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  ThunderstorePackageReference get package => $_getN(1);
  @$pb.TagNumber(2)
  set package(ThunderstorePackageReference value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPackage() => $_has(1);
  @$pb.TagNumber(2)
  void clearPackage() => $_clearField(2);
  @$pb.TagNumber(2)
  ThunderstorePackageReference ensurePackage() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);
}

class ThunderstorePackageDetails extends $pb.GeneratedMessage {
  factory ThunderstorePackageDetails({
    ThunderstoreVersionReference? reference,
    $core.String? latestVersion,
    $core.String? description,
    $core.String? iconUrl,
    $core.bool? deprecated,
    $core.Iterable<$core.String>? categories,
    $fixnum.Int64? bytes,
    $core.Iterable<$core.String>? versions,
    $core.Iterable<ThunderstoreDependency>? dependencies,
    $core.Iterable<ThunderstoreInstalled>? installed,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (latestVersion != null) result.latestVersion = latestVersion;
    if (description != null) result.description = description;
    if (iconUrl != null) result.iconUrl = iconUrl;
    if (deprecated != null) result.deprecated = deprecated;
    if (categories != null) result.categories.addAll(categories);
    if (bytes != null) result.bytes = bytes;
    if (versions != null) result.versions.addAll(versions);
    if (dependencies != null) result.dependencies.addAll(dependencies);
    if (installed != null) result.installed.addAll(installed);
    return result;
  }

  ThunderstorePackageDetails._();

  factory ThunderstorePackageDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstorePackageDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstorePackageDetails',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ThunderstoreVersionReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: ThunderstoreVersionReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'latestVersion')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aOS(4, _omitFieldNames ? '' : 'iconUrl')
    ..aOB(5, _omitFieldNames ? '' : 'deprecated')
    ..pPS(6, _omitFieldNames ? '' : 'categories')
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPS(8, _omitFieldNames ? '' : 'versions')
    ..pPM<ThunderstoreDependency>(9, _omitFieldNames ? '' : 'dependencies',
        subBuilder: ThunderstoreDependency.create)
    ..pPM<ThunderstoreInstalled>(10, _omitFieldNames ? '' : 'installed',
        subBuilder: ThunderstoreInstalled.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackageDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackageDetails copyWith(
          void Function(ThunderstorePackageDetails) updates) =>
      super.copyWith(
              (message) => updates(message as ThunderstorePackageDetails))
          as ThunderstorePackageDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstorePackageDetails create() => ThunderstorePackageDetails._();
  @$core.override
  ThunderstorePackageDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstorePackageDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstorePackageDetails>(create);
  static ThunderstorePackageDetails? _defaultInstance;

  @$pb.TagNumber(1)
  ThunderstoreVersionReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(ThunderstoreVersionReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  ThunderstoreVersionReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get latestVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set latestVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLatestVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatestVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get iconUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set iconUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIconUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearIconUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get deprecated => $_getBF(4);
  @$pb.TagNumber(5)
  set deprecated($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeprecated() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeprecated() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get categories => $_getList(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get bytes => $_getI64(6);
  @$pb.TagNumber(7)
  set bytes($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearBytes() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get versions => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbList<ThunderstoreDependency> get dependencies => $_getList(8);

  @$pb.TagNumber(10)
  $pb.PbList<ThunderstoreInstalled> get installed => $_getList(9);
}

enum ThunderstorePackageReply_Outcome { package, failure, notSet }

class ThunderstorePackageReply extends $pb.GeneratedMessage {
  factory ThunderstorePackageReply({
    ThunderstorePackageDetails? package,
    ThunderstoreFailure? failure,
  }) {
    final result = create();
    if (package != null) result.package = package;
    if (failure != null) result.failure = failure;
    return result;
  }

  ThunderstorePackageReply._();

  factory ThunderstorePackageReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstorePackageReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ThunderstorePackageReply_Outcome>
      _ThunderstorePackageReply_OutcomeByTag = {
    1: ThunderstorePackageReply_Outcome.package,
    2: ThunderstorePackageReply_Outcome.failure,
    0: ThunderstorePackageReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstorePackageReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ThunderstorePackageDetails>(1, _omitFieldNames ? '' : 'package',
        subBuilder: ThunderstorePackageDetails.create)
    ..aOM<ThunderstoreFailure>(2, _omitFieldNames ? '' : 'failure',
        subBuilder: ThunderstoreFailure.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackageReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstorePackageReply copyWith(
          void Function(ThunderstorePackageReply) updates) =>
      super.copyWith((message) => updates(message as ThunderstorePackageReply))
          as ThunderstorePackageReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstorePackageReply create() => ThunderstorePackageReply._();
  @$core.override
  ThunderstorePackageReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstorePackageReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstorePackageReply>(create);
  static ThunderstorePackageReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ThunderstorePackageReply_Outcome whichOutcome() =>
      _ThunderstorePackageReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ThunderstorePackageDetails get package => $_getN(0);
  @$pb.TagNumber(1)
  set package(ThunderstorePackageDetails value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => $_clearField(1);
  @$pb.TagNumber(1)
  ThunderstorePackageDetails ensurePackage() => $_ensure(0);

  @$pb.TagNumber(2)
  ThunderstoreFailure get failure => $_getN(1);
  @$pb.TagNumber(2)
  set failure(ThunderstoreFailure value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFailure() => $_has(1);
  @$pb.TagNumber(2)
  void clearFailure() => $_clearField(2);
  @$pb.TagNumber(2)
  ThunderstoreFailure ensureFailure() => $_ensure(1);
}

class ThunderstoreAcquireRequest extends $pb.GeneratedMessage {
  factory ThunderstoreAcquireRequest({
    $core.String? workspaceId,
    ThunderstoreVersionReference? reference,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (reference != null) result.reference = reference;
    return result;
  }

  ThunderstoreAcquireRequest._();

  factory ThunderstoreAcquireRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreAcquireRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreAcquireRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOM<ThunderstoreVersionReference>(2, _omitFieldNames ? '' : 'reference',
        subBuilder: ThunderstoreVersionReference.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreAcquireRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreAcquireRequest copyWith(
          void Function(ThunderstoreAcquireRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ThunderstoreAcquireRequest))
          as ThunderstoreAcquireRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreAcquireRequest create() => ThunderstoreAcquireRequest._();
  @$core.override
  ThunderstoreAcquireRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreAcquireRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreAcquireRequest>(create);
  static ThunderstoreAcquireRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  ThunderstoreVersionReference get reference => $_getN(1);
  @$pb.TagNumber(2)
  set reference(ThunderstoreVersionReference value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasReference() => $_has(1);
  @$pb.TagNumber(2)
  void clearReference() => $_clearField(2);
  @$pb.TagNumber(2)
  ThunderstoreVersionReference ensureReference() => $_ensure(1);
}

class ThunderstoreAcquisition extends $pb.GeneratedMessage {
  factory ThunderstoreAcquisition({
    ThunderstoreVersionReference? reference,
    $core.String? stage,
    $fixnum.Int64? bytes,
    $fixnum.Int64? total,
    $core.int? completed,
    $core.int? packages,
    $core.String? modId,
    ThunderstoreFailure? failure,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (stage != null) result.stage = stage;
    if (bytes != null) result.bytes = bytes;
    if (total != null) result.total = total;
    if (completed != null) result.completed = completed;
    if (packages != null) result.packages = packages;
    if (modId != null) result.modId = modId;
    if (failure != null) result.failure = failure;
    return result;
  }

  ThunderstoreAcquisition._();

  factory ThunderstoreAcquisition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreAcquisition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreAcquisition',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<ThunderstoreVersionReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: ThunderstoreVersionReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'stage')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'total', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(5, _omitFieldNames ? '' : 'completed')
    ..aI(6, _omitFieldNames ? '' : 'packages')
    ..aOS(7, _omitFieldNames ? '' : 'modId')
    ..aOM<ThunderstoreFailure>(8, _omitFieldNames ? '' : 'failure',
        subBuilder: ThunderstoreFailure.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreAcquisition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreAcquisition copyWith(
          void Function(ThunderstoreAcquisition) updates) =>
      super.copyWith((message) => updates(message as ThunderstoreAcquisition))
          as ThunderstoreAcquisition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreAcquisition create() => ThunderstoreAcquisition._();
  @$core.override
  ThunderstoreAcquisition createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreAcquisition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreAcquisition>(create);
  static ThunderstoreAcquisition? _defaultInstance;

  @$pb.TagNumber(1)
  ThunderstoreVersionReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(ThunderstoreVersionReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  ThunderstoreVersionReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get stage => $_getSZ(1);
  @$pb.TagNumber(2)
  set stage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStage() => $_has(1);
  @$pb.TagNumber(2)
  void clearStage() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get bytes => $_getI64(2);
  @$pb.TagNumber(3)
  set bytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get total => $_getI64(3);
  @$pb.TagNumber(4)
  set total($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotal() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotal() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get completed => $_getIZ(4);
  @$pb.TagNumber(5)
  set completed($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCompleted() => $_has(4);
  @$pb.TagNumber(5)
  void clearCompleted() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get packages => $_getIZ(5);
  @$pb.TagNumber(6)
  set packages($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPackages() => $_has(5);
  @$pb.TagNumber(6)
  void clearPackages() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get modId => $_getSZ(6);
  @$pb.TagNumber(7)
  set modId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasModId() => $_has(6);
  @$pb.TagNumber(7)
  void clearModId() => $_clearField(7);

  @$pb.TagNumber(8)
  ThunderstoreFailure get failure => $_getN(7);
  @$pb.TagNumber(8)
  set failure(ThunderstoreFailure value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasFailure() => $_has(7);
  @$pb.TagNumber(8)
  void clearFailure() => $_clearField(8);
  @$pb.TagNumber(8)
  ThunderstoreFailure ensureFailure() => $_ensure(7);
}

class ThunderstoreOpened extends $pb.GeneratedMessage {
  factory ThunderstoreOpened() => create();

  ThunderstoreOpened._();

  factory ThunderstoreOpened.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ThunderstoreOpened.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThunderstoreOpened',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreOpened clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThunderstoreOpened copyWith(void Function(ThunderstoreOpened) updates) =>
      super.copyWith((message) => updates(message as ThunderstoreOpened))
          as ThunderstoreOpened;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ThunderstoreOpened create() => ThunderstoreOpened._();
  @$core.override
  ThunderstoreOpened createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ThunderstoreOpened getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThunderstoreOpened>(create);
  static ThunderstoreOpened? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
