// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_organization.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'mod_library.pb.dart' as $1;
import 'mod_organization.pbenum.dart';
import 'profile_mods.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'mod_organization.pbenum.dart';

class ModCategory extends $pb.GeneratedMessage {
  factory ModCategory({
    $core.String? categoryId,
    $core.String? workspaceId,
    $core.String? parentId,
    $core.String? label,
    $core.bool? missing,
    $core.int? assignedCount,
    $core.bool? hasChildren,
  }) {
    final result = create();
    if (categoryId != null) result.categoryId = categoryId;
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (parentId != null) result.parentId = parentId;
    if (label != null) result.label = label;
    if (missing != null) result.missing = missing;
    if (assignedCount != null) result.assignedCount = assignedCount;
    if (hasChildren != null) result.hasChildren = hasChildren;
    return result;
  }

  ModCategory._();

  factory ModCategory.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModCategory.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModCategory',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'categoryId')
    ..aOS(2, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(3, _omitFieldNames ? '' : 'parentId')
    ..aOS(4, _omitFieldNames ? '' : 'label')
    ..aOB(5, _omitFieldNames ? '' : 'missing')
    ..aI(6, _omitFieldNames ? '' : 'assignedCount',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(7, _omitFieldNames ? '' : 'hasChildren')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModCategory clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModCategory copyWith(void Function(ModCategory) updates) =>
      super.copyWith((message) => updates(message as ModCategory))
          as ModCategory;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModCategory create() => ModCategory._();
  @$core.override
  ModCategory createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModCategory getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModCategory>(create);
  static ModCategory? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get categoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set categoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCategoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategoryId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get parentId => $_getSZ(2);
  @$pb.TagNumber(3)
  set parentId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasParentId() => $_has(2);
  @$pb.TagNumber(3)
  void clearParentId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get label => $_getSZ(3);
  @$pb.TagNumber(4)
  set label($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLabel() => $_has(3);
  @$pb.TagNumber(4)
  void clearLabel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get missing => $_getBF(4);
  @$pb.TagNumber(5)
  set missing($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMissing() => $_has(4);
  @$pb.TagNumber(5)
  void clearMissing() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get assignedCount => $_getIZ(5);
  @$pb.TagNumber(6)
  set assignedCount($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAssignedCount() => $_has(5);
  @$pb.TagNumber(6)
  void clearAssignedCount() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get hasChildren => $_getBF(6);
  @$pb.TagNumber(7)
  set hasChildren($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHasChildren() => $_has(6);
  @$pb.TagNumber(7)
  void clearHasChildren() => $_clearField(7);
}

class ReadCategoriesRequest extends $pb.GeneratedMessage {
  factory ReadCategoriesRequest({
    $core.String? workspaceId,
    $core.String? parentId,
    $core.String? afterId,
    $fixnum.Int64? expectedRevision,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (parentId != null) result.parentId = parentId;
    if (afterId != null) result.afterId = afterId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    return result;
  }

  ReadCategoriesRequest._();

  factory ReadCategoriesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReadCategoriesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadCategoriesRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..aOS(2, _omitFieldNames ? '' : 'parentId')
    ..aOS(3, _omitFieldNames ? '' : 'afterId')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadCategoriesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadCategoriesRequest copyWith(
          void Function(ReadCategoriesRequest) updates) =>
      super.copyWith((message) => updates(message as ReadCategoriesRequest))
          as ReadCategoriesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReadCategoriesRequest create() => ReadCategoriesRequest._();
  @$core.override
  ReadCategoriesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReadCategoriesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadCategoriesRequest>(create);
  static ReadCategoriesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get parentId => $_getSZ(1);
  @$pb.TagNumber(2)
  set parentId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParentId() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get afterId => $_getSZ(2);
  @$pb.TagNumber(3)
  set afterId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAfterId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAfterId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get expectedRevision => $_getI64(3);
  @$pb.TagNumber(4)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExpectedRevision() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpectedRevision() => $_clearField(4);
}

class CategoriesPage extends $pb.GeneratedMessage {
  factory CategoriesPage({
    $fixnum.Int64? revision,
    $core.Iterable<ModCategory>? entries,
    $core.Iterable<ModCategory>? ancestors,
    $core.String? nextId,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    if (entries != null) result.entries.addAll(entries);
    if (ancestors != null) result.ancestors.addAll(ancestors);
    if (nextId != null) result.nextId = nextId;
    return result;
  }

  CategoriesPage._();

  factory CategoriesPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CategoriesPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CategoriesPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..pPM<ModCategory>(2, _omitFieldNames ? '' : 'entries',
        subBuilder: ModCategory.create)
    ..pPM<ModCategory>(3, _omitFieldNames ? '' : 'ancestors',
        subBuilder: ModCategory.create)
    ..aOS(4, _omitFieldNames ? '' : 'nextId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoriesPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoriesPage copyWith(void Function(CategoriesPage) updates) =>
      super.copyWith((message) => updates(message as CategoriesPage))
          as CategoriesPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CategoriesPage create() => CategoriesPage._();
  @$core.override
  CategoriesPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CategoriesPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CategoriesPage>(create);
  static CategoriesPage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get revision => $_getI64(0);
  @$pb.TagNumber(1)
  set revision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ModCategory> get entries => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<ModCategory> get ancestors => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get nextId => $_getSZ(3);
  @$pb.TagNumber(4)
  set nextId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNextId() => $_has(3);
  @$pb.TagNumber(4)
  void clearNextId() => $_clearField(4);
}

enum CategoriesReply_Outcome { page, fault, notSet }

class CategoriesReply extends $pb.GeneratedMessage {
  factory CategoriesReply({
    CategoriesPage? page,
    $1.ModLibraryFault? fault,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (fault != null) result.fault = fault;
    return result;
  }

  CategoriesReply._();

  factory CategoriesReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CategoriesReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, CategoriesReply_Outcome>
      _CategoriesReply_OutcomeByTag = {
    1: CategoriesReply_Outcome.page,
    2: CategoriesReply_Outcome.fault,
    0: CategoriesReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CategoriesReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<CategoriesPage>(1, _omitFieldNames ? '' : 'page',
        subBuilder: CategoriesPage.create)
    ..aOM<$1.ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: $1.ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoriesReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoriesReply copyWith(void Function(CategoriesReply) updates) =>
      super.copyWith((message) => updates(message as CategoriesReply))
          as CategoriesReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CategoriesReply create() => CategoriesReply._();
  @$core.override
  CategoriesReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CategoriesReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CategoriesReply>(create);
  static CategoriesReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  CategoriesReply_Outcome whichOutcome() =>
      _CategoriesReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  CategoriesPage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(CategoriesPage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  CategoriesPage ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault($1.ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLibraryFault ensureFault() => $_ensure(1);
}

class CategoryDefinition extends $pb.GeneratedMessage {
  factory CategoryDefinition({
    $core.String? categoryId,
    $core.String? parentId,
    $core.String? label,
  }) {
    final result = create();
    if (categoryId != null) result.categoryId = categoryId;
    if (parentId != null) result.parentId = parentId;
    if (label != null) result.label = label;
    return result;
  }

  CategoryDefinition._();

  factory CategoryDefinition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CategoryDefinition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CategoryDefinition',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'categoryId')
    ..aOS(2, _omitFieldNames ? '' : 'parentId')
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoryDefinition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoryDefinition copyWith(void Function(CategoryDefinition) updates) =>
      super.copyWith((message) => updates(message as CategoryDefinition))
          as CategoryDefinition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CategoryDefinition create() => CategoryDefinition._();
  @$core.override
  CategoryDefinition createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CategoryDefinition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CategoryDefinition>(create);
  static CategoryDefinition? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get categoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set categoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCategoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategoryId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get parentId => $_getSZ(1);
  @$pb.TagNumber(2)
  set parentId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParentId() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);
}

enum EditCategoryRequest_Edit { create_3, update, deleteId, notSet }

class EditCategoryRequest extends $pb.GeneratedMessage {
  factory EditCategoryRequest({
    $core.String? workspaceId,
    $fixnum.Int64? expectedRevision,
    CategoryDefinition? create_3,
    CategoryDefinition? update,
    $core.String? deleteId,
  }) {
    final result = create();
    if (workspaceId != null) result.workspaceId = workspaceId;
    if (expectedRevision != null) result.expectedRevision = expectedRevision;
    if (create_3 != null) result.create_3 = create_3;
    if (update != null) result.update = update;
    if (deleteId != null) result.deleteId = deleteId;
    return result;
  }

  EditCategoryRequest._();

  factory EditCategoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EditCategoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, EditCategoryRequest_Edit>
      _EditCategoryRequest_EditByTag = {
    3: EditCategoryRequest_Edit.create_3,
    4: EditCategoryRequest_Edit.update,
    5: EditCategoryRequest_Edit.deleteId,
    0: EditCategoryRequest_Edit.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditCategoryRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [3, 4, 5])
    ..aOS(1, _omitFieldNames ? '' : 'workspaceId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'expectedRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<CategoryDefinition>(3, _omitFieldNames ? '' : 'create',
        subBuilder: CategoryDefinition.create)
    ..aOM<CategoryDefinition>(4, _omitFieldNames ? '' : 'update',
        subBuilder: CategoryDefinition.create)
    ..aOS(5, _omitFieldNames ? '' : 'deleteId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditCategoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditCategoryRequest copyWith(void Function(EditCategoryRequest) updates) =>
      super.copyWith((message) => updates(message as EditCategoryRequest))
          as EditCategoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EditCategoryRequest create() => EditCategoryRequest._();
  @$core.override
  EditCategoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EditCategoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditCategoryRequest>(create);
  static EditCategoryRequest? _defaultInstance;

  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  EditCategoryRequest_Edit whichEdit() =>
      _EditCategoryRequest_EditByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearEdit() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expectedRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set expectedRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpectedRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpectedRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  CategoryDefinition get create_3 => $_getN(2);
  @$pb.TagNumber(3)
  set create_3(CategoryDefinition value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCreate_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreate_3() => $_clearField(3);
  @$pb.TagNumber(3)
  CategoryDefinition ensureCreate_3() => $_ensure(2);

  @$pb.TagNumber(4)
  CategoryDefinition get update => $_getN(3);
  @$pb.TagNumber(4)
  set update(CategoryDefinition value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasUpdate() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdate() => $_clearField(4);
  @$pb.TagNumber(4)
  CategoryDefinition ensureUpdate() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get deleteId => $_getSZ(4);
  @$pb.TagNumber(5)
  set deleteId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeleteId() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeleteId() => $_clearField(5);
}

class OrganizationRevision extends $pb.GeneratedMessage {
  factory OrganizationRevision({
    $fixnum.Int64? revision,
  }) {
    final result = create();
    if (revision != null) result.revision = revision;
    return result;
  }

  OrganizationRevision._();

  factory OrganizationRevision.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OrganizationRevision.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OrganizationRevision',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'revision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrganizationRevision clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrganizationRevision copyWith(void Function(OrganizationRevision) updates) =>
      super.copyWith((message) => updates(message as OrganizationRevision))
          as OrganizationRevision;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OrganizationRevision create() => OrganizationRevision._();
  @$core.override
  OrganizationRevision createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OrganizationRevision getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OrganizationRevision>(create);
  static OrganizationRevision? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get revision => $_getI64(0);
  @$pb.TagNumber(1)
  set revision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearRevision() => $_clearField(1);
}

enum OrganizationChangeReply_Outcome { changed, fault, notSet }

class OrganizationChangeReply extends $pb.GeneratedMessage {
  factory OrganizationChangeReply({
    OrganizationRevision? changed,
    $1.ModLibraryFault? fault,
  }) {
    final result = create();
    if (changed != null) result.changed = changed;
    if (fault != null) result.fault = fault;
    return result;
  }

  OrganizationChangeReply._();

  factory OrganizationChangeReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OrganizationChangeReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OrganizationChangeReply_Outcome>
      _OrganizationChangeReply_OutcomeByTag = {
    1: OrganizationChangeReply_Outcome.changed,
    2: OrganizationChangeReply_Outcome.fault,
    0: OrganizationChangeReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OrganizationChangeReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<OrganizationRevision>(1, _omitFieldNames ? '' : 'changed',
        subBuilder: OrganizationRevision.create)
    ..aOM<$1.ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: $1.ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrganizationChangeReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrganizationChangeReply copyWith(
          void Function(OrganizationChangeReply) updates) =>
      super.copyWith((message) => updates(message as OrganizationChangeReply))
          as OrganizationChangeReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OrganizationChangeReply create() => OrganizationChangeReply._();
  @$core.override
  OrganizationChangeReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OrganizationChangeReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OrganizationChangeReply>(create);
  static OrganizationChangeReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  OrganizationChangeReply_Outcome whichOutcome() =>
      _OrganizationChangeReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OrganizationRevision get changed => $_getN(0);
  @$pb.TagNumber(1)
  set changed(OrganizationRevision value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasChanged() => $_has(0);
  @$pb.TagNumber(1)
  void clearChanged() => $_clearField(1);
  @$pb.TagNumber(1)
  OrganizationRevision ensureChanged() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault($1.ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLibraryFault ensureFault() => $_ensure(1);
}

class ModCategoryFilter extends $pb.GeneratedMessage {
  factory ModCategoryFilter({
    $1.ModCategoryReference? category,
    $core.bool? descendants,
  }) {
    final result = create();
    if (category != null) result.category = category;
    if (descendants != null) result.descendants = descendants;
    return result;
  }

  ModCategoryFilter._();

  factory ModCategoryFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModCategoryFilter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModCategoryFilter',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$1.ModCategoryReference>(1, _omitFieldNames ? '' : 'category',
        subBuilder: $1.ModCategoryReference.create)
    ..aOB(2, _omitFieldNames ? '' : 'descendants')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModCategoryFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModCategoryFilter copyWith(void Function(ModCategoryFilter) updates) =>
      super.copyWith((message) => updates(message as ModCategoryFilter))
          as ModCategoryFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModCategoryFilter create() => ModCategoryFilter._();
  @$core.override
  ModCategoryFilter createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModCategoryFilter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModCategoryFilter>(create);
  static ModCategoryFilter? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ModCategoryReference get category => $_getN(0);
  @$pb.TagNumber(1)
  set category($1.ModCategoryReference value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCategory() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategory() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ModCategoryReference ensureCategory() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get descendants => $_getBF(1);
  @$pb.TagNumber(2)
  set descendants($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescendants() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescendants() => $_clearField(2);
}

enum ModFilterPredicate_Predicate {
  category,
  kind,
  status,
  enabled,
  uncategorized,
  missingCategory,
  notSet
}

class ModFilterPredicate extends $pb.GeneratedMessage {
  factory ModFilterPredicate({
    ModCategoryFilter? category,
    $1.InventoryModKind? kind,
    $1.ModInventoryStatus? status,
    ModEnabledFilter? enabled,
    $core.bool? uncategorized,
    $core.bool? missingCategory,
  }) {
    final result = create();
    if (category != null) result.category = category;
    if (kind != null) result.kind = kind;
    if (status != null) result.status = status;
    if (enabled != null) result.enabled = enabled;
    if (uncategorized != null) result.uncategorized = uncategorized;
    if (missingCategory != null) result.missingCategory = missingCategory;
    return result;
  }

  ModFilterPredicate._();

  factory ModFilterPredicate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModFilterPredicate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModFilterPredicate_Predicate>
      _ModFilterPredicate_PredicateByTag = {
    1: ModFilterPredicate_Predicate.category,
    2: ModFilterPredicate_Predicate.kind,
    3: ModFilterPredicate_Predicate.status,
    4: ModFilterPredicate_Predicate.enabled,
    5: ModFilterPredicate_Predicate.uncategorized,
    6: ModFilterPredicate_Predicate.missingCategory,
    0: ModFilterPredicate_Predicate.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModFilterPredicate',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6])
    ..aOM<ModCategoryFilter>(1, _omitFieldNames ? '' : 'category',
        subBuilder: ModCategoryFilter.create)
    ..aE<$1.InventoryModKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: $1.InventoryModKind.values)
    ..aE<$1.ModInventoryStatus>(3, _omitFieldNames ? '' : 'status',
        enumValues: $1.ModInventoryStatus.values)
    ..aE<ModEnabledFilter>(4, _omitFieldNames ? '' : 'enabled',
        enumValues: ModEnabledFilter.values)
    ..aOB(5, _omitFieldNames ? '' : 'uncategorized')
    ..aOB(6, _omitFieldNames ? '' : 'missingCategory')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModFilterPredicate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModFilterPredicate copyWith(void Function(ModFilterPredicate) updates) =>
      super.copyWith((message) => updates(message as ModFilterPredicate))
          as ModFilterPredicate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModFilterPredicate create() => ModFilterPredicate._();
  @$core.override
  ModFilterPredicate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModFilterPredicate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModFilterPredicate>(create);
  static ModFilterPredicate? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  ModFilterPredicate_Predicate whichPredicate() =>
      _ModFilterPredicate_PredicateByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  void clearPredicate() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModCategoryFilter get category => $_getN(0);
  @$pb.TagNumber(1)
  set category(ModCategoryFilter value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCategory() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategory() => $_clearField(1);
  @$pb.TagNumber(1)
  ModCategoryFilter ensureCategory() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.InventoryModKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind($1.InventoryModKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.ModInventoryStatus get status => $_getN(2);
  @$pb.TagNumber(3)
  set status($1.ModInventoryStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  ModEnabledFilter get enabled => $_getN(3);
  @$pb.TagNumber(4)
  set enabled(ModEnabledFilter value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnabled() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get uncategorized => $_getBF(4);
  @$pb.TagNumber(5)
  set uncategorized($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUncategorized() => $_has(4);
  @$pb.TagNumber(5)
  void clearUncategorized() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get missingCategory => $_getBF(5);
  @$pb.TagNumber(6)
  set missingCategory($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMissingCategory() => $_has(5);
  @$pb.TagNumber(6)
  void clearMissingCategory() => $_clearField(6);
}

class ModQueryDefinition extends $pb.GeneratedMessage {
  factory ModQueryDefinition({
    $core.String? text,
    ModFilterMode? mode,
    $core.Iterable<ModFilterPredicate>? filters,
    ModQueryView? view,
    ModQuerySort? sort,
  }) {
    final result = create();
    if (text != null) result.text = text;
    if (mode != null) result.mode = mode;
    if (filters != null) result.filters.addAll(filters);
    if (view != null) result.view = view;
    if (sort != null) result.sort = sort;
    return result;
  }

  ModQueryDefinition._();

  factory ModQueryDefinition.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModQueryDefinition.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModQueryDefinition',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aE<ModFilterMode>(2, _omitFieldNames ? '' : 'mode',
        enumValues: ModFilterMode.values)
    ..pPM<ModFilterPredicate>(3, _omitFieldNames ? '' : 'filters',
        subBuilder: ModFilterPredicate.create)
    ..aE<ModQueryView>(4, _omitFieldNames ? '' : 'view',
        enumValues: ModQueryView.values)
    ..aE<ModQuerySort>(5, _omitFieldNames ? '' : 'sort',
        enumValues: ModQuerySort.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModQueryDefinition clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModQueryDefinition copyWith(void Function(ModQueryDefinition) updates) =>
      super.copyWith((message) => updates(message as ModQueryDefinition))
          as ModQueryDefinition;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModQueryDefinition create() => ModQueryDefinition._();
  @$core.override
  ModQueryDefinition createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModQueryDefinition getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModQueryDefinition>(create);
  static ModQueryDefinition? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  ModFilterMode get mode => $_getN(1);
  @$pb.TagNumber(2)
  set mode(ModFilterMode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<ModFilterPredicate> get filters => $_getList(2);

  @$pb.TagNumber(4)
  ModQueryView get view => $_getN(3);
  @$pb.TagNumber(4)
  set view(ModQueryView value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasView() => $_has(3);
  @$pb.TagNumber(4)
  void clearView() => $_clearField(4);

  @$pb.TagNumber(5)
  ModQuerySort get sort => $_getN(4);
  @$pb.TagNumber(5)
  set sort(ModQuerySort value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSort() => $_has(4);
  @$pb.TagNumber(5)
  void clearSort() => $_clearField(5);
}

class ModQueryCursor extends $pb.GeneratedMessage {
  factory ModQueryCursor({
    $fixnum.Int64? catalogueRevision,
    $fixnum.Int64? selectionRevision,
    $core.String? queryIdentity,
    $core.int? offset,
  }) {
    final result = create();
    if (catalogueRevision != null) result.catalogueRevision = catalogueRevision;
    if (selectionRevision != null) result.selectionRevision = selectionRevision;
    if (queryIdentity != null) result.queryIdentity = queryIdentity;
    if (offset != null) result.offset = offset;
    return result;
  }

  ModQueryCursor._();

  factory ModQueryCursor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModQueryCursor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModQueryCursor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'catalogueRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'selectionRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'queryIdentity')
    ..aI(4, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModQueryCursor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModQueryCursor copyWith(void Function(ModQueryCursor) updates) =>
      super.copyWith((message) => updates(message as ModQueryCursor))
          as ModQueryCursor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModQueryCursor create() => ModQueryCursor._();
  @$core.override
  ModQueryCursor createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModQueryCursor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModQueryCursor>(create);
  static ModQueryCursor? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get catalogueRevision => $_getI64(0);
  @$pb.TagNumber(1)
  set catalogueRevision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCatalogueRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearCatalogueRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get selectionRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set selectionRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSelectionRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearSelectionRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get queryIdentity => $_getSZ(2);
  @$pb.TagNumber(3)
  set queryIdentity($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQueryIdentity() => $_has(2);
  @$pb.TagNumber(3)
  void clearQueryIdentity() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get offset => $_getIZ(3);
  @$pb.TagNumber(4)
  set offset($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => $_clearField(4);
}

class QueryModsRequest extends $pb.GeneratedMessage {
  factory QueryModsRequest({
    $core.String? profileId,
    ModQueryDefinition? query,
    ModQueryCursor? cursor,
    $core.String? inspectedModId,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (query != null) result.query = query;
    if (cursor != null) result.cursor = cursor;
    if (inspectedModId != null) result.inspectedModId = inspectedModId;
    return result;
  }

  QueryModsRequest._();

  factory QueryModsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QueryModsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryModsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOM<ModQueryDefinition>(2, _omitFieldNames ? '' : 'query',
        subBuilder: ModQueryDefinition.create)
    ..aOM<ModQueryCursor>(3, _omitFieldNames ? '' : 'cursor',
        subBuilder: ModQueryCursor.create)
    ..aOS(4, _omitFieldNames ? '' : 'inspectedModId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryModsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryModsRequest copyWith(void Function(QueryModsRequest) updates) =>
      super.copyWith((message) => updates(message as QueryModsRequest))
          as QueryModsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryModsRequest create() => QueryModsRequest._();
  @$core.override
  QueryModsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static QueryModsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryModsRequest>(create);
  static QueryModsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  ModQueryDefinition get query => $_getN(1);
  @$pb.TagNumber(2)
  set query(ModQueryDefinition value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuery() => $_clearField(2);
  @$pb.TagNumber(2)
  ModQueryDefinition ensureQuery() => $_ensure(1);

  @$pb.TagNumber(3)
  ModQueryCursor get cursor => $_getN(2);
  @$pb.TagNumber(3)
  set cursor(ModQueryCursor value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCursor() => $_has(2);
  @$pb.TagNumber(3)
  void clearCursor() => $_clearField(3);
  @$pb.TagNumber(3)
  ModQueryCursor ensureCursor() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get inspectedModId => $_getSZ(3);
  @$pb.TagNumber(4)
  set inspectedModId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInspectedModId() => $_has(3);
  @$pb.TagNumber(4)
  void clearInspectedModId() => $_clearField(4);
}

class SeparatorGroupSize extends $pb.GeneratedMessage {
  factory SeparatorGroupSize({
    $core.int? matching,
    $core.int? total,
  }) {
    final result = create();
    if (matching != null) result.matching = matching;
    if (total != null) result.total = total;
    return result;
  }

  SeparatorGroupSize._();

  factory SeparatorGroupSize.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SeparatorGroupSize.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SeparatorGroupSize',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'matching', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'total', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeparatorGroupSize clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeparatorGroupSize copyWith(void Function(SeparatorGroupSize) updates) =>
      super.copyWith((message) => updates(message as SeparatorGroupSize))
          as SeparatorGroupSize;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SeparatorGroupSize create() => SeparatorGroupSize._();
  @$core.override
  SeparatorGroupSize createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SeparatorGroupSize getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SeparatorGroupSize>(create);
  static SeparatorGroupSize? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get matching => $_getIZ(0);
  @$pb.TagNumber(1)
  set matching($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMatching() => $_has(0);
  @$pb.TagNumber(1)
  void clearMatching() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);
}

class OrganizedModView extends $pb.GeneratedMessage {
  factory OrganizedModView({
    $2.ProfileModView? entry,
    $core.String? groupId,
    SeparatorGroupSize? groupSize,
  }) {
    final result = create();
    if (entry != null) result.entry = entry;
    if (groupId != null) result.groupId = groupId;
    if (groupSize != null) result.groupSize = groupSize;
    return result;
  }

  OrganizedModView._();

  factory OrganizedModView.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OrganizedModView.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OrganizedModView',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOM<$2.ProfileModView>(1, _omitFieldNames ? '' : 'entry',
        subBuilder: $2.ProfileModView.create)
    ..aOS(2, _omitFieldNames ? '' : 'groupId')
    ..aOM<SeparatorGroupSize>(3, _omitFieldNames ? '' : 'groupSize',
        subBuilder: SeparatorGroupSize.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrganizedModView clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OrganizedModView copyWith(void Function(OrganizedModView) updates) =>
      super.copyWith((message) => updates(message as OrganizedModView))
          as OrganizedModView;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OrganizedModView create() => OrganizedModView._();
  @$core.override
  OrganizedModView createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OrganizedModView getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OrganizedModView>(create);
  static OrganizedModView? _defaultInstance;

  @$pb.TagNumber(1)
  $2.ProfileModView get entry => $_getN(0);
  @$pb.TagNumber(1)
  set entry($2.ProfileModView value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEntry() => $_has(0);
  @$pb.TagNumber(1)
  void clearEntry() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.ProfileModView ensureEntry() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => $_clearField(2);

  @$pb.TagNumber(3)
  SeparatorGroupSize get groupSize => $_getN(2);
  @$pb.TagNumber(3)
  set groupSize(SeparatorGroupSize value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGroupSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupSize() => $_clearField(3);
  @$pb.TagNumber(3)
  SeparatorGroupSize ensureGroupSize() => $_ensure(2);
}

class ModQueryPage extends $pb.GeneratedMessage {
  factory ModQueryPage({
    $fixnum.Int64? catalogueRevision,
    $fixnum.Int64? selectionRevision,
    $core.String? queryIdentity,
    $core.Iterable<OrganizedModView>? entries,
    $core.Iterable<OrganizedModView>? context,
    OrganizedModView? inspected,
    ModQueryCursor? next,
    $core.int? matchingMods,
    $core.int? matchingSeparators,
    $core.int? totalMods,
    $core.int? enabledCount,
    $core.int? matchingGroups,
  }) {
    final result = create();
    if (catalogueRevision != null) result.catalogueRevision = catalogueRevision;
    if (selectionRevision != null) result.selectionRevision = selectionRevision;
    if (queryIdentity != null) result.queryIdentity = queryIdentity;
    if (entries != null) result.entries.addAll(entries);
    if (context != null) result.context.addAll(context);
    if (inspected != null) result.inspected = inspected;
    if (next != null) result.next = next;
    if (matchingMods != null) result.matchingMods = matchingMods;
    if (matchingSeparators != null)
      result.matchingSeparators = matchingSeparators;
    if (totalMods != null) result.totalMods = totalMods;
    if (enabledCount != null) result.enabledCount = enabledCount;
    if (matchingGroups != null) result.matchingGroups = matchingGroups;
    return result;
  }

  ModQueryPage._();

  factory ModQueryPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModQueryPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModQueryPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'catalogueRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'selectionRevision', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'queryIdentity')
    ..pPM<OrganizedModView>(4, _omitFieldNames ? '' : 'entries',
        subBuilder: OrganizedModView.create)
    ..pPM<OrganizedModView>(5, _omitFieldNames ? '' : 'context',
        subBuilder: OrganizedModView.create)
    ..aOM<OrganizedModView>(6, _omitFieldNames ? '' : 'inspected',
        subBuilder: OrganizedModView.create)
    ..aOM<ModQueryCursor>(7, _omitFieldNames ? '' : 'next',
        subBuilder: ModQueryCursor.create)
    ..aI(8, _omitFieldNames ? '' : 'matchingMods',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(9, _omitFieldNames ? '' : 'matchingSeparators',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(10, _omitFieldNames ? '' : 'totalMods', fieldType: $pb.PbFieldType.OU3)
    ..aI(11, _omitFieldNames ? '' : 'enabledCount',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(12, _omitFieldNames ? '' : 'matchingGroups',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModQueryPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModQueryPage copyWith(void Function(ModQueryPage) updates) =>
      super.copyWith((message) => updates(message as ModQueryPage))
          as ModQueryPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModQueryPage create() => ModQueryPage._();
  @$core.override
  ModQueryPage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModQueryPage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModQueryPage>(create);
  static ModQueryPage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get catalogueRevision => $_getI64(0);
  @$pb.TagNumber(1)
  set catalogueRevision($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCatalogueRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearCatalogueRevision() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get selectionRevision => $_getI64(1);
  @$pb.TagNumber(2)
  set selectionRevision($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSelectionRevision() => $_has(1);
  @$pb.TagNumber(2)
  void clearSelectionRevision() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get queryIdentity => $_getSZ(2);
  @$pb.TagNumber(3)
  set queryIdentity($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQueryIdentity() => $_has(2);
  @$pb.TagNumber(3)
  void clearQueryIdentity() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<OrganizedModView> get entries => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<OrganizedModView> get context => $_getList(4);

  @$pb.TagNumber(6)
  OrganizedModView get inspected => $_getN(5);
  @$pb.TagNumber(6)
  set inspected(OrganizedModView value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasInspected() => $_has(5);
  @$pb.TagNumber(6)
  void clearInspected() => $_clearField(6);
  @$pb.TagNumber(6)
  OrganizedModView ensureInspected() => $_ensure(5);

  @$pb.TagNumber(7)
  ModQueryCursor get next => $_getN(6);
  @$pb.TagNumber(7)
  set next(ModQueryCursor value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasNext() => $_has(6);
  @$pb.TagNumber(7)
  void clearNext() => $_clearField(7);
  @$pb.TagNumber(7)
  ModQueryCursor ensureNext() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.int get matchingMods => $_getIZ(7);
  @$pb.TagNumber(8)
  set matchingMods($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMatchingMods() => $_has(7);
  @$pb.TagNumber(8)
  void clearMatchingMods() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get matchingSeparators => $_getIZ(8);
  @$pb.TagNumber(9)
  set matchingSeparators($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMatchingSeparators() => $_has(8);
  @$pb.TagNumber(9)
  void clearMatchingSeparators() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get totalMods => $_getIZ(9);
  @$pb.TagNumber(10)
  set totalMods($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasTotalMods() => $_has(9);
  @$pb.TagNumber(10)
  void clearTotalMods() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get enabledCount => $_getIZ(10);
  @$pb.TagNumber(11)
  set enabledCount($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasEnabledCount() => $_has(10);
  @$pb.TagNumber(11)
  void clearEnabledCount() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get matchingGroups => $_getIZ(11);
  @$pb.TagNumber(12)
  set matchingGroups($core.int value) => $_setUnsignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasMatchingGroups() => $_has(11);
  @$pb.TagNumber(12)
  void clearMatchingGroups() => $_clearField(12);
}

enum ModQueryReply_Outcome { page, fault, notSet }

class ModQueryReply extends $pb.GeneratedMessage {
  factory ModQueryReply({
    ModQueryPage? page,
    $1.ModLibraryFault? fault,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (fault != null) result.fault = fault;
    return result;
  }

  ModQueryReply._();

  factory ModQueryReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModQueryReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ModQueryReply_Outcome>
      _ModQueryReply_OutcomeByTag = {
    1: ModQueryReply_Outcome.page,
    2: ModQueryReply_Outcome.fault,
    0: ModQueryReply_Outcome.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModQueryReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ModQueryPage>(1, _omitFieldNames ? '' : 'page',
        subBuilder: ModQueryPage.create)
    ..aOM<$1.ModLibraryFault>(2, _omitFieldNames ? '' : 'fault',
        subBuilder: $1.ModLibraryFault.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModQueryReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModQueryReply copyWith(void Function(ModQueryReply) updates) =>
      super.copyWith((message) => updates(message as ModQueryReply))
          as ModQueryReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModQueryReply create() => ModQueryReply._();
  @$core.override
  ModQueryReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ModQueryReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModQueryReply>(create);
  static ModQueryReply? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ModQueryReply_Outcome whichOutcome() =>
      _ModQueryReply_OutcomeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOutcome() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ModQueryPage get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(ModQueryPage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  ModQueryPage ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ModLibraryFault get fault => $_getN(1);
  @$pb.TagNumber(2)
  set fault($1.ModLibraryFault value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFault() => $_has(1);
  @$pb.TagNumber(2)
  void clearFault() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ModLibraryFault ensureFault() => $_ensure(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
