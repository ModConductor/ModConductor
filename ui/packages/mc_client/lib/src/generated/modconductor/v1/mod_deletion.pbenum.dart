// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_deletion.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ModDeletionFileKind extends $pb.ProtobufEnum {
  static const ModDeletionFileKind MOD_DELETION_FILE_KIND_PAYLOAD =
      ModDeletionFileKind._(
          0, _omitEnumNames ? '' : 'MOD_DELETION_FILE_KIND_PAYLOAD');
  static const ModDeletionFileKind MOD_DELETION_FILE_KIND_ARCHIVE =
      ModDeletionFileKind._(
          1, _omitEnumNames ? '' : 'MOD_DELETION_FILE_KIND_ARCHIVE');
  static const ModDeletionFileKind MOD_DELETION_FILE_KIND_TEMPORARY =
      ModDeletionFileKind._(
          2, _omitEnumNames ? '' : 'MOD_DELETION_FILE_KIND_TEMPORARY');
  static const ModDeletionFileKind MOD_DELETION_FILE_KIND_GENERATION_LINK =
      ModDeletionFileKind._(
          3, _omitEnumNames ? '' : 'MOD_DELETION_FILE_KIND_GENERATION_LINK');

  static const $core.List<ModDeletionFileKind> values = <ModDeletionFileKind>[
    MOD_DELETION_FILE_KIND_PAYLOAD,
    MOD_DELETION_FILE_KIND_ARCHIVE,
    MOD_DELETION_FILE_KIND_TEMPORARY,
    MOD_DELETION_FILE_KIND_GENERATION_LINK,
  ];

  static final $core.List<ModDeletionFileKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ModDeletionFileKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModDeletionFileKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
