// This is a generated file - do not edit.
//
// Generated from modconductor/v1/fomod.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'archive_installation.pb.dart' as $1;
import 'fomod.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'fomod.pbenum.dart';

class OpenFomodChoices extends $pb.GeneratedMessage {
  factory OpenFomodChoices({
    $1.InstallationDraftReference? draft,
    $core.String? profileId,
  }) {
    final result = create();
    if (draft != null) result.draft = draft;
    if (profileId != null) result.profileId = profileId;
    return result;
  }

  OpenFomodChoices._();

  factory OpenFomodChoices.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenFomodChoices.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenFomodChoices',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.InstallationDraftReference>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: $1.InstallationDraftReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenFomodChoices clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenFomodChoices copyWith(void Function(OpenFomodChoices) updates) =>
      super.copyWith((message) => updates(message as OpenFomodChoices))
          as OpenFomodChoices;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenFomodChoices create() => OpenFomodChoices._();
  @$core.override
  OpenFomodChoices createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenFomodChoices getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenFomodChoices>(create);
  static OpenFomodChoices? _defaultInstance;

  @$pb.TagNumber(1)
  $1.InstallationDraftReference get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft($1.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.InstallationDraftReference ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get profileId => $_getSZ(1);
  @$pb.TagNumber(2)
  set profileId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProfileId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProfileId() => $_clearField(2);
}

class FomodChoiceChange extends $pb.GeneratedMessage {
  factory FomodChoiceChange({
    $1.InstallationDraftReference? draft,
    $core.int? optionId,
    $core.bool? selected,
  }) {
    final result = create();
    if (draft != null) result.draft = draft;
    if (optionId != null) result.optionId = optionId;
    if (selected != null) result.selected = selected;
    return result;
  }

  FomodChoiceChange._();

  factory FomodChoiceChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FomodChoiceChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FomodChoiceChange',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.InstallationDraftReference>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: $1.InstallationDraftReference.create)
    ..aI(2, _omitFieldNames ? '' : 'optionId', fieldType: $pb.PbFieldType.OU3)
    ..aOB(3, _omitFieldNames ? '' : 'selected')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodChoiceChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodChoiceChange copyWith(void Function(FomodChoiceChange) updates) =>
      super.copyWith((message) => updates(message as FomodChoiceChange))
          as FomodChoiceChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FomodChoiceChange create() => FomodChoiceChange._();
  @$core.override
  FomodChoiceChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FomodChoiceChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FomodChoiceChange>(create);
  static FomodChoiceChange? _defaultInstance;

  @$pb.TagNumber(1)
  $1.InstallationDraftReference get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft($1.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.InstallationDraftReference ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get optionId => $_getIZ(1);
  @$pb.TagNumber(2)
  set optionId($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOptionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get selected => $_getBF(2);
  @$pb.TagNumber(3)
  set selected($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSelected() => $_has(2);
  @$pb.TagNumber(3)
  void clearSelected() => $_clearField(3);
}

class FomodImageRequest extends $pb.GeneratedMessage {
  factory FomodImageRequest({
    $1.InstallationDraftReference? draft,
    $core.Iterable<$core.String>? path,
  }) {
    final result = create();
    if (draft != null) result.draft = draft;
    if (path != null) result.path.addAll(path);
    return result;
  }

  FomodImageRequest._();

  factory FomodImageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FomodImageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FomodImageRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.InstallationDraftReference>(1, _omitFieldNames ? '' : 'draft',
        subBuilder: $1.InstallationDraftReference.create)
    ..pPS(2, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodImageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodImageRequest copyWith(void Function(FomodImageRequest) updates) =>
      super.copyWith((message) => updates(message as FomodImageRequest))
          as FomodImageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FomodImageRequest create() => FomodImageRequest._();
  @$core.override
  FomodImageRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FomodImageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FomodImageRequest>(create);
  static FomodImageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.InstallationDraftReference get draft => $_getN(0);
  @$pb.TagNumber(1)
  set draft($1.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDraft() => $_has(0);
  @$pb.TagNumber(1)
  void clearDraft() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.InstallationDraftReference ensureDraft() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get path => $_getList(1);
}

class FomodImage extends $pb.GeneratedMessage {
  factory FomodImage({
    $core.List<$core.int>? content,
  }) {
    final result = create();
    if (content != null) result.content = content;
    return result;
  }

  FomodImage._();

  factory FomodImage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FomodImage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FomodImage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'content', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodImage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodImage copyWith(void Function(FomodImage) updates) =>
      super.copyWith((message) => updates(message as FomodImage)) as FomodImage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FomodImage create() => FomodImage._();
  @$core.override
  FomodImage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FomodImage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FomodImage>(create);
  static FomodImage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get content => $_getN(0);
  @$pb.TagNumber(1)
  set content($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);
}

class FomodOption extends $pb.GeneratedMessage {
  factory FomodOption({
    $core.int? id,
    $core.String? name,
    $core.String? description,
    FomodOptionKind? kind,
    $core.bool? selected,
    $core.bool? canChange,
    $core.Iterable<$core.String>? image,
    $core.String? problem,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (kind != null) result.kind = kind;
    if (selected != null) result.selected = selected;
    if (canChange != null) result.canChange = canChange;
    if (image != null) result.image.addAll(image);
    if (problem != null) result.problem = problem;
    return result;
  }

  FomodOption._();

  factory FomodOption.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FomodOption.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FomodOption',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..aE<FomodOptionKind>(4, _omitFieldNames ? '' : 'kind',
        enumValues: FomodOptionKind.values)
    ..aOB(5, _omitFieldNames ? '' : 'selected')
    ..aOB(6, _omitFieldNames ? '' : 'canChange')
    ..pPS(7, _omitFieldNames ? '' : 'image')
    ..aOS(8, _omitFieldNames ? '' : 'problem')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodOption clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodOption copyWith(void Function(FomodOption) updates) =>
      super.copyWith((message) => updates(message as FomodOption))
          as FomodOption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FomodOption create() => FomodOption._();
  @$core.override
  FomodOption createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FomodOption getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FomodOption>(create);
  static FomodOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
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
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  FomodOptionKind get kind => $_getN(3);
  @$pb.TagNumber(4)
  set kind(FomodOptionKind value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get selected => $_getBF(4);
  @$pb.TagNumber(5)
  set selected($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSelected() => $_has(4);
  @$pb.TagNumber(5)
  void clearSelected() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get canChange => $_getBF(5);
  @$pb.TagNumber(6)
  set canChange($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCanChange() => $_has(5);
  @$pb.TagNumber(6)
  void clearCanChange() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get image => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get problem => $_getSZ(7);
  @$pb.TagNumber(8)
  set problem($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasProblem() => $_has(7);
  @$pb.TagNumber(8)
  void clearProblem() => $_clearField(8);
}

class FomodGroup extends $pb.GeneratedMessage {
  factory FomodGroup({
    $core.String? name,
    FomodGroupKind? kind,
    $core.Iterable<FomodOption>? options,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (kind != null) result.kind = kind;
    if (options != null) result.options.addAll(options);
    return result;
  }

  FomodGroup._();

  factory FomodGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FomodGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FomodGroup',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aE<FomodGroupKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: FomodGroupKind.values)
    ..pPM<FomodOption>(3, _omitFieldNames ? '' : 'options',
        subBuilder: FomodOption.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodGroup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodGroup copyWith(void Function(FomodGroup) updates) =>
      super.copyWith((message) => updates(message as FomodGroup)) as FomodGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FomodGroup create() => FomodGroup._();
  @$core.override
  FomodGroup createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FomodGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FomodGroup>(create);
  static FomodGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  FomodGroupKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(FomodGroupKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<FomodOption> get options => $_getList(2);
}

class FomodSource extends $pb.GeneratedMessage {
  factory FomodSource({
    $core.Iterable<$core.String>? path,
  }) {
    final result = create();
    if (path != null) result.path.addAll(path);
    return result;
  }

  FomodSource._();

  factory FomodSource.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FomodSource.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FomodSource',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodSource clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodSource copyWith(void Function(FomodSource) updates) =>
      super.copyWith((message) => updates(message as FomodSource))
          as FomodSource;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FomodSource create() => FomodSource._();
  @$core.override
  FomodSource createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FomodSource getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FomodSource>(create);
  static FomodSource? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get path => $_getList(0);
}

class FomodPlannedFile extends $pb.GeneratedMessage {
  factory FomodPlannedFile({
    $core.int? index,
    $core.Iterable<$core.String>? destination,
    $core.Iterable<$core.String>? source,
    $core.String? choice,
    $fixnum.Int64? bytes,
    $core.Iterable<FomodSource>? replaces,
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

  FomodPlannedFile._();

  factory FomodPlannedFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FomodPlannedFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FomodPlannedFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..pPS(2, _omitFieldNames ? '' : 'destination')
    ..pPS(3, _omitFieldNames ? '' : 'source')
    ..aOS(4, _omitFieldNames ? '' : 'choice')
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<FomodSource>(6, _omitFieldNames ? '' : 'replaces',
        subBuilder: FomodSource.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodPlannedFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodPlannedFile copyWith(void Function(FomodPlannedFile) updates) =>
      super.copyWith((message) => updates(message as FomodPlannedFile))
          as FomodPlannedFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FomodPlannedFile create() => FomodPlannedFile._();
  @$core.override
  FomodPlannedFile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FomodPlannedFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FomodPlannedFile>(create);
  static FomodPlannedFile? _defaultInstance;

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
  $pb.PbList<FomodSource> get replaces => $_getList(5);
}

class FomodChoices extends $pb.GeneratedMessage {
  factory FomodChoices({
    $1.InstallationDraftReference? reference,
    $core.String? profileId,
    $core.String? name,
    $core.String? stepName,
    $core.int? stepNumber,
    $core.int? visibleSteps,
    $core.bool? canBack,
    $core.bool? hasStep,
    $core.Iterable<FomodGroup>? groups,
    $core.Iterable<FomodPlannedFile>? files,
    $core.bool? reviewReady,
    $core.String? problem,
    $1.ArchiveInstallationDraft? reviewedDraft,
  }) {
    final result = create();
    if (reference != null) result.reference = reference;
    if (profileId != null) result.profileId = profileId;
    if (name != null) result.name = name;
    if (stepName != null) result.stepName = stepName;
    if (stepNumber != null) result.stepNumber = stepNumber;
    if (visibleSteps != null) result.visibleSteps = visibleSteps;
    if (canBack != null) result.canBack = canBack;
    if (hasStep != null) result.hasStep = hasStep;
    if (groups != null) result.groups.addAll(groups);
    if (files != null) result.files.addAll(files);
    if (reviewReady != null) result.reviewReady = reviewReady;
    if (problem != null) result.problem = problem;
    if (reviewedDraft != null) result.reviewedDraft = reviewedDraft;
    return result;
  }

  FomodChoices._();

  factory FomodChoices.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FomodChoices.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FomodChoices',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.InstallationDraftReference>(1, _omitFieldNames ? '' : 'reference',
        subBuilder: $1.InstallationDraftReference.create)
    ..aOS(2, _omitFieldNames ? '' : 'profileId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'stepName')
    ..aI(5, _omitFieldNames ? '' : 'stepNumber', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'visibleSteps',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(7, _omitFieldNames ? '' : 'canBack')
    ..aOB(8, _omitFieldNames ? '' : 'hasStep')
    ..pPM<FomodGroup>(9, _omitFieldNames ? '' : 'groups',
        subBuilder: FomodGroup.create)
    ..pPM<FomodPlannedFile>(10, _omitFieldNames ? '' : 'files',
        subBuilder: FomodPlannedFile.create)
    ..aOB(11, _omitFieldNames ? '' : 'reviewReady')
    ..aOS(12, _omitFieldNames ? '' : 'problem')
    ..aOM<$1.ArchiveInstallationDraft>(
        13, _omitFieldNames ? '' : 'reviewedDraft',
        subBuilder: $1.ArchiveInstallationDraft.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodChoices clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FomodChoices copyWith(void Function(FomodChoices) updates) =>
      super.copyWith((message) => updates(message as FomodChoices))
          as FomodChoices;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FomodChoices create() => FomodChoices._();
  @$core.override
  FomodChoices createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FomodChoices getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FomodChoices>(create);
  static FomodChoices? _defaultInstance;

  @$pb.TagNumber(1)
  $1.InstallationDraftReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($1.InstallationDraftReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.InstallationDraftReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get profileId => $_getSZ(1);
  @$pb.TagNumber(2)
  set profileId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProfileId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProfileId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get stepName => $_getSZ(3);
  @$pb.TagNumber(4)
  set stepName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStepName() => $_has(3);
  @$pb.TagNumber(4)
  void clearStepName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get stepNumber => $_getIZ(4);
  @$pb.TagNumber(5)
  set stepNumber($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStepNumber() => $_has(4);
  @$pb.TagNumber(5)
  void clearStepNumber() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get visibleSteps => $_getIZ(5);
  @$pb.TagNumber(6)
  set visibleSteps($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVisibleSteps() => $_has(5);
  @$pb.TagNumber(6)
  void clearVisibleSteps() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get canBack => $_getBF(6);
  @$pb.TagNumber(7)
  set canBack($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCanBack() => $_has(6);
  @$pb.TagNumber(7)
  void clearCanBack() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get hasStep => $_getBF(7);
  @$pb.TagNumber(8)
  set hasStep($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHasStep() => $_has(7);
  @$pb.TagNumber(8)
  void clearHasStep() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<FomodGroup> get groups => $_getList(8);

  @$pb.TagNumber(10)
  $pb.PbList<FomodPlannedFile> get files => $_getList(9);

  @$pb.TagNumber(11)
  $core.bool get reviewReady => $_getBF(10);
  @$pb.TagNumber(11)
  set reviewReady($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasReviewReady() => $_has(10);
  @$pb.TagNumber(11)
  void clearReviewReady() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get problem => $_getSZ(11);
  @$pb.TagNumber(12)
  set problem($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasProblem() => $_has(11);
  @$pb.TagNumber(12)
  void clearProblem() => $_clearField(12);

  @$pb.TagNumber(13)
  $1.ArchiveInstallationDraft get reviewedDraft => $_getN(12);
  @$pb.TagNumber(13)
  set reviewedDraft($1.ArchiveInstallationDraft value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasReviewedDraft() => $_has(12);
  @$pb.TagNumber(13)
  void clearReviewedDraft() => $_clearField(13);
  @$pb.TagNumber(13)
  $1.ArchiveInstallationDraft ensureReviewedDraft() => $_ensure(12);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
