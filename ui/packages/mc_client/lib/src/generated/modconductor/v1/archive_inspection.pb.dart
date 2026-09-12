// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_inspection.proto.

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

class InspectedArchive extends $pb.GeneratedMessage {
  factory InspectedArchive({
    $core.String? sha256,
    $core.String? format,
    $core.Iterable<InspectedArchiveEntry>? entries,
    $fixnum.Int64? totalSize,
  }) {
    final result = create();
    if (sha256 != null) result.sha256 = sha256;
    if (format != null) result.format = format;
    if (entries != null) result.entries.addAll(entries);
    if (totalSize != null) result.totalSize = totalSize;
    return result;
  }

  InspectedArchive._();

  factory InspectedArchive.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InspectedArchive.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InspectedArchive',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sha256')
    ..aOS(2, _omitFieldNames ? '' : 'format')
    ..pPM<InspectedArchiveEntry>(3, _omitFieldNames ? '' : 'entries',
        subBuilder: InspectedArchiveEntry.create)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'totalSize', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectedArchive clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectedArchive copyWith(void Function(InspectedArchive) updates) =>
      super.copyWith((message) => updates(message as InspectedArchive))
          as InspectedArchive;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InspectedArchive create() => InspectedArchive._();
  @$core.override
  InspectedArchive createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InspectedArchive getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InspectedArchive>(create);
  static InspectedArchive? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sha256 => $_getSZ(0);
  @$pb.TagNumber(1)
  set sha256($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSha256() => $_has(0);
  @$pb.TagNumber(1)
  void clearSha256() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get format => $_getSZ(1);
  @$pb.TagNumber(2)
  set format($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<InspectedArchiveEntry> get entries => $_getList(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get totalSize => $_getI64(3);
  @$pb.TagNumber(4)
  set totalSize($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalSize() => $_clearField(4);
}

class InspectedArchiveEntry extends $pb.GeneratedMessage {
  factory InspectedArchiveEntry({
    $core.int? index,
    $core.Iterable<$core.String>? components,
    $core.bool? directory,
    $fixnum.Int64? size,
    $fixnum.Int64? compressedSize,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (components != null) result.components.addAll(components);
    if (directory != null) result.directory = directory;
    if (size != null) result.size = size;
    if (compressedSize != null) result.compressedSize = compressedSize;
    return result;
  }

  InspectedArchiveEntry._();

  factory InspectedArchiveEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InspectedArchiveEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InspectedArchiveEntry',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'modconductor.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..pPS(2, _omitFieldNames ? '' : 'components')
    ..aOB(3, _omitFieldNames ? '' : 'directory')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'size', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'compressedSize', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectedArchiveEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InspectedArchiveEntry copyWith(
          void Function(InspectedArchiveEntry) updates) =>
      super.copyWith((message) => updates(message as InspectedArchiveEntry))
          as InspectedArchiveEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InspectedArchiveEntry create() => InspectedArchiveEntry._();
  @$core.override
  InspectedArchiveEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InspectedArchiveEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InspectedArchiveEntry>(create);
  static InspectedArchiveEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get components => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get directory => $_getBF(2);
  @$pb.TagNumber(3)
  set directory($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDirectory() => $_has(2);
  @$pb.TagNumber(3)
  void clearDirectory() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(4)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSize() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get compressedSize => $_getI64(4);
  @$pb.TagNumber(5)
  set compressedSize($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCompressedSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearCompressedSize() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
