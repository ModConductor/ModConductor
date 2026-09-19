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

class Manager extends $pb.ProtobufEnum {
  static const Manager MANAGER_UNSPECIFIED =
      Manager._(0, _omitEnumNames ? '' : 'MANAGER_UNSPECIFIED');
  static const Manager MANAGER_MOD_ORGANIZER =
      Manager._(1, _omitEnumNames ? '' : 'MANAGER_MOD_ORGANIZER');

  static const $core.List<Manager> values = <Manager>[
    MANAGER_UNSPECIFIED,
    MANAGER_MOD_ORGANIZER,
  ];

  static final $core.List<Manager?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static Manager? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Manager._(super.value, super.name);
}

class MigrateErrorCode extends $pb.ProtobufEnum {
  static const MigrateErrorCode MIGRATE_ERROR_CODE_UNSPECIFIED =
      MigrateErrorCode._(
          0, _omitEnumNames ? '' : 'MIGRATE_ERROR_CODE_UNSPECIFIED');
  static const MigrateErrorCode MIGRATE_ERROR_CODE_INVALID_SOURCE =
      MigrateErrorCode._(
          1, _omitEnumNames ? '' : 'MIGRATE_ERROR_CODE_INVALID_SOURCE');
  static const MigrateErrorCode MIGRATE_ERROR_CODE_TARGET_NOT_EMPTY =
      MigrateErrorCode._(
          2, _omitEnumNames ? '' : 'MIGRATE_ERROR_CODE_TARGET_NOT_EMPTY');
  static const MigrateErrorCode MIGRATE_ERROR_CODE_UNSAFE_SOURCE =
      MigrateErrorCode._(
          3, _omitEnumNames ? '' : 'MIGRATE_ERROR_CODE_UNSAFE_SOURCE');
  static const MigrateErrorCode MIGRATE_ERROR_CODE_CASE_COLLISION =
      MigrateErrorCode._(
          4, _omitEnumNames ? '' : 'MIGRATE_ERROR_CODE_CASE_COLLISION');
  static const MigrateErrorCode MIGRATE_ERROR_CODE_UNSUPPORTED_DATA =
      MigrateErrorCode._(
          5, _omitEnumNames ? '' : 'MIGRATE_ERROR_CODE_UNSUPPORTED_DATA');
  static const MigrateErrorCode MIGRATE_ERROR_CODE_SOURCE_CHANGED =
      MigrateErrorCode._(
          6, _omitEnumNames ? '' : 'MIGRATE_ERROR_CODE_SOURCE_CHANGED');
  static const MigrateErrorCode MIGRATE_ERROR_CODE_CANCELLED =
      MigrateErrorCode._(
          7, _omitEnumNames ? '' : 'MIGRATE_ERROR_CODE_CANCELLED');
  static const MigrateErrorCode MIGRATE_ERROR_CODE_BUSY =
      MigrateErrorCode._(8, _omitEnumNames ? '' : 'MIGRATE_ERROR_CODE_BUSY');
  static const MigrateErrorCode MIGRATE_ERROR_CODE_UNAVAILABLE =
      MigrateErrorCode._(
          9, _omitEnumNames ? '' : 'MIGRATE_ERROR_CODE_UNAVAILABLE');

  static const $core.List<MigrateErrorCode> values = <MigrateErrorCode>[
    MIGRATE_ERROR_CODE_UNSPECIFIED,
    MIGRATE_ERROR_CODE_INVALID_SOURCE,
    MIGRATE_ERROR_CODE_TARGET_NOT_EMPTY,
    MIGRATE_ERROR_CODE_UNSAFE_SOURCE,
    MIGRATE_ERROR_CODE_CASE_COLLISION,
    MIGRATE_ERROR_CODE_UNSUPPORTED_DATA,
    MIGRATE_ERROR_CODE_SOURCE_CHANGED,
    MIGRATE_ERROR_CODE_CANCELLED,
    MIGRATE_ERROR_CODE_BUSY,
    MIGRATE_ERROR_CODE_UNAVAILABLE,
  ];

  static final $core.List<MigrateErrorCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static MigrateErrorCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MigrateErrorCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
