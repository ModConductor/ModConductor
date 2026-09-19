// This is a generated file - do not edit.
//
// Generated from modconductor/v1/migration.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class MigrationManager extends $pb.ProtobufEnum {
  static const MigrationManager MIGRATION_MANAGER_UNSPECIFIED =
      MigrationManager._(
          0, _omitEnumNames ? '' : 'MIGRATION_MANAGER_UNSPECIFIED');
  static const MigrationManager MIGRATION_MANAGER_MOD_ORGANIZER =
      MigrationManager._(
          1, _omitEnumNames ? '' : 'MIGRATION_MANAGER_MOD_ORGANIZER');
  static const MigrationManager MIGRATION_MANAGER_VORTEX =
      MigrationManager._(2, _omitEnumNames ? '' : 'MIGRATION_MANAGER_VORTEX');

  static const $core.List<MigrationManager> values = <MigrationManager>[
    MIGRATION_MANAGER_UNSPECIFIED,
    MIGRATION_MANAGER_MOD_ORGANIZER,
    MIGRATION_MANAGER_VORTEX,
  ];

  static final $core.List<MigrationManager?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static MigrationManager? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MigrationManager._(super.value, super.name);
}

class MigrationErrorCode extends $pb.ProtobufEnum {
  static const MigrationErrorCode MIGRATION_ERROR_CODE_UNSPECIFIED =
      MigrationErrorCode._(
          0, _omitEnumNames ? '' : 'MIGRATION_ERROR_CODE_UNSPECIFIED');
  static const MigrationErrorCode MIGRATION_ERROR_CODE_INVALID_SOURCE =
      MigrationErrorCode._(
          1, _omitEnumNames ? '' : 'MIGRATION_ERROR_CODE_INVALID_SOURCE');
  static const MigrationErrorCode MIGRATION_ERROR_CODE_TARGET_NOT_EMPTY =
      MigrationErrorCode._(
          2, _omitEnumNames ? '' : 'MIGRATION_ERROR_CODE_TARGET_NOT_EMPTY');
  static const MigrationErrorCode MIGRATION_ERROR_CODE_UNSAFE_SOURCE =
      MigrationErrorCode._(
          3, _omitEnumNames ? '' : 'MIGRATION_ERROR_CODE_UNSAFE_SOURCE');
  static const MigrationErrorCode MIGRATION_ERROR_CODE_CASE_COLLISION =
      MigrationErrorCode._(
          4, _omitEnumNames ? '' : 'MIGRATION_ERROR_CODE_CASE_COLLISION');
  static const MigrationErrorCode MIGRATION_ERROR_CODE_UNSUPPORTED_DATA =
      MigrationErrorCode._(
          5, _omitEnumNames ? '' : 'MIGRATION_ERROR_CODE_UNSUPPORTED_DATA');
  static const MigrationErrorCode MIGRATION_ERROR_CODE_SOURCE_CHANGED =
      MigrationErrorCode._(
          6, _omitEnumNames ? '' : 'MIGRATION_ERROR_CODE_SOURCE_CHANGED');
  static const MigrationErrorCode MIGRATION_ERROR_CODE_CANCELLED =
      MigrationErrorCode._(
          7, _omitEnumNames ? '' : 'MIGRATION_ERROR_CODE_CANCELLED');
  static const MigrationErrorCode MIGRATION_ERROR_CODE_BUSY =
      MigrationErrorCode._(
          8, _omitEnumNames ? '' : 'MIGRATION_ERROR_CODE_BUSY');
  static const MigrationErrorCode MIGRATION_ERROR_CODE_UNAVAILABLE =
      MigrationErrorCode._(
          9, _omitEnumNames ? '' : 'MIGRATION_ERROR_CODE_UNAVAILABLE');

  static const $core.List<MigrationErrorCode> values = <MigrationErrorCode>[
    MIGRATION_ERROR_CODE_UNSPECIFIED,
    MIGRATION_ERROR_CODE_INVALID_SOURCE,
    MIGRATION_ERROR_CODE_TARGET_NOT_EMPTY,
    MIGRATION_ERROR_CODE_UNSAFE_SOURCE,
    MIGRATION_ERROR_CODE_CASE_COLLISION,
    MIGRATION_ERROR_CODE_UNSUPPORTED_DATA,
    MIGRATION_ERROR_CODE_SOURCE_CHANGED,
    MIGRATION_ERROR_CODE_CANCELLED,
    MIGRATION_ERROR_CODE_BUSY,
    MIGRATION_ERROR_CODE_UNAVAILABLE,
  ];

  static final $core.List<MigrationErrorCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static MigrationErrorCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MigrationErrorCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
