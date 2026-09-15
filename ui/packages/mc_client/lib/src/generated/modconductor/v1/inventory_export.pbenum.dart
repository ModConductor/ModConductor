// This is a generated file - do not edit.
//
// Generated from modconductor/v1/inventory_export.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class InventoryExportScope extends $pb.ProtobufEnum {
  static const InventoryExportScope INVENTORY_EXPORT_SCOPE_UNSPECIFIED =
      InventoryExportScope._(
          0, _omitEnumNames ? '' : 'INVENTORY_EXPORT_SCOPE_UNSPECIFIED');
  static const InventoryExportScope INVENTORY_EXPORT_SCOPE_SELECTED =
      InventoryExportScope._(
          1, _omitEnumNames ? '' : 'INVENTORY_EXPORT_SCOPE_SELECTED');
  static const InventoryExportScope INVENTORY_EXPORT_SCOPE_ENABLED =
      InventoryExportScope._(
          2, _omitEnumNames ? '' : 'INVENTORY_EXPORT_SCOPE_ENABLED');
  static const InventoryExportScope INVENTORY_EXPORT_SCOPE_CURRENT_QUERY =
      InventoryExportScope._(
          3, _omitEnumNames ? '' : 'INVENTORY_EXPORT_SCOPE_CURRENT_QUERY');
  static const InventoryExportScope INVENTORY_EXPORT_SCOPE_ALL =
      InventoryExportScope._(
          4, _omitEnumNames ? '' : 'INVENTORY_EXPORT_SCOPE_ALL');

  static const $core.List<InventoryExportScope> values = <InventoryExportScope>[
    INVENTORY_EXPORT_SCOPE_UNSPECIFIED,
    INVENTORY_EXPORT_SCOPE_SELECTED,
    INVENTORY_EXPORT_SCOPE_ENABLED,
    INVENTORY_EXPORT_SCOPE_CURRENT_QUERY,
    INVENTORY_EXPORT_SCOPE_ALL,
  ];

  static final $core.List<InventoryExportScope?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static InventoryExportScope? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InventoryExportScope._(super.value, super.name);
}

class InventoryExportField extends $pb.ProtobufEnum {
  static const InventoryExportField INVENTORY_EXPORT_FIELD_UNSPECIFIED =
      InventoryExportField._(
          0, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_UNSPECIFIED');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_MOD_ID =
      InventoryExportField._(
          1, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_MOD_ID');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_NAME =
      InventoryExportField._(
          2, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_NAME');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_KIND =
      InventoryExportField._(
          3, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_KIND');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_STATUS =
      InventoryExportField._(
          4, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_STATUS');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_PRIORITY =
      InventoryExportField._(
          5, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_PRIORITY');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_ENABLED =
      InventoryExportField._(
          6, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_ENABLED');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_VERSION =
      InventoryExportField._(
          7, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_VERSION');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_SOURCE =
      InventoryExportField._(
          8, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_SOURCE');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_SOURCE_PATH =
      InventoryExportField._(
          9, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_SOURCE_PATH');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_NOTES =
      InventoryExportField._(
          10, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_NOTES');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_COMMENT =
      InventoryExportField._(
          11, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_COMMENT');
  static const InventoryExportField INVENTORY_EXPORT_FIELD_CATEGORIES =
      InventoryExportField._(
          12, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FIELD_CATEGORIES');

  static const $core.List<InventoryExportField> values = <InventoryExportField>[
    INVENTORY_EXPORT_FIELD_UNSPECIFIED,
    INVENTORY_EXPORT_FIELD_MOD_ID,
    INVENTORY_EXPORT_FIELD_NAME,
    INVENTORY_EXPORT_FIELD_KIND,
    INVENTORY_EXPORT_FIELD_STATUS,
    INVENTORY_EXPORT_FIELD_PRIORITY,
    INVENTORY_EXPORT_FIELD_ENABLED,
    INVENTORY_EXPORT_FIELD_VERSION,
    INVENTORY_EXPORT_FIELD_SOURCE,
    INVENTORY_EXPORT_FIELD_SOURCE_PATH,
    INVENTORY_EXPORT_FIELD_NOTES,
    INVENTORY_EXPORT_FIELD_COMMENT,
    INVENTORY_EXPORT_FIELD_CATEGORIES,
  ];

  static final $core.List<InventoryExportField?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 12);
  static InventoryExportField? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InventoryExportField._(super.value, super.name);
}

class InventoryExportFaultCode extends $pb.ProtobufEnum {
  static const InventoryExportFaultCode
      INVENTORY_EXPORT_FAULT_CODE_UNSPECIFIED = InventoryExportFaultCode._(
          0, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FAULT_CODE_UNSPECIFIED');
  static const InventoryExportFaultCode
      INVENTORY_EXPORT_FAULT_CODE_INVALID_REQUEST = InventoryExportFaultCode._(
          1,
          _omitEnumNames ? '' : 'INVENTORY_EXPORT_FAULT_CODE_INVALID_REQUEST');
  static const InventoryExportFaultCode INVENTORY_EXPORT_FAULT_CODE_NOT_FOUND =
      InventoryExportFaultCode._(
          2, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FAULT_CODE_NOT_FOUND');
  static const InventoryExportFaultCode INVENTORY_EXPORT_FAULT_CODE_STALE =
      InventoryExportFaultCode._(
          3, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FAULT_CODE_STALE');
  static const InventoryExportFaultCode INVENTORY_EXPORT_FAULT_CODE_BUSY =
      InventoryExportFaultCode._(
          4, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FAULT_CODE_BUSY');
  static const InventoryExportFaultCode
      INVENTORY_EXPORT_FAULT_CODE_LIMIT_EXCEEDED = InventoryExportFaultCode._(5,
          _omitEnumNames ? '' : 'INVENTORY_EXPORT_FAULT_CODE_LIMIT_EXCEEDED');
  static const InventoryExportFaultCode
      INVENTORY_EXPORT_FAULT_CODE_DESTINATION_UNAVAILABLE =
      InventoryExportFaultCode._(
          6,
          _omitEnumNames
              ? ''
              : 'INVENTORY_EXPORT_FAULT_CODE_DESTINATION_UNAVAILABLE');
  static const InventoryExportFaultCode
      INVENTORY_EXPORT_FAULT_CODE_DESTINATION_CHANGED =
      InventoryExportFaultCode._(
          7,
          _omitEnumNames
              ? ''
              : 'INVENTORY_EXPORT_FAULT_CODE_DESTINATION_CHANGED');
  static const InventoryExportFaultCode
      INVENTORY_EXPORT_FAULT_CODE_REPLACEMENT_REQUIRED =
      InventoryExportFaultCode._(
          8,
          _omitEnumNames
              ? ''
              : 'INVENTORY_EXPORT_FAULT_CODE_REPLACEMENT_REQUIRED');
  static const InventoryExportFaultCode INVENTORY_EXPORT_FAULT_CODE_CANCELLED =
      InventoryExportFaultCode._(
          9, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FAULT_CODE_CANCELLED');
  static const InventoryExportFaultCode
      INVENTORY_EXPORT_FAULT_CODE_WRITE_FAILED = InventoryExportFaultCode._(
          10, _omitEnumNames ? '' : 'INVENTORY_EXPORT_FAULT_CODE_WRITE_FAILED');

  static const $core.List<InventoryExportFaultCode> values =
      <InventoryExportFaultCode>[
    INVENTORY_EXPORT_FAULT_CODE_UNSPECIFIED,
    INVENTORY_EXPORT_FAULT_CODE_INVALID_REQUEST,
    INVENTORY_EXPORT_FAULT_CODE_NOT_FOUND,
    INVENTORY_EXPORT_FAULT_CODE_STALE,
    INVENTORY_EXPORT_FAULT_CODE_BUSY,
    INVENTORY_EXPORT_FAULT_CODE_LIMIT_EXCEEDED,
    INVENTORY_EXPORT_FAULT_CODE_DESTINATION_UNAVAILABLE,
    INVENTORY_EXPORT_FAULT_CODE_DESTINATION_CHANGED,
    INVENTORY_EXPORT_FAULT_CODE_REPLACEMENT_REQUIRED,
    INVENTORY_EXPORT_FAULT_CODE_CANCELLED,
    INVENTORY_EXPORT_FAULT_CODE_WRITE_FAILED,
  ];

  static final $core.List<InventoryExportFaultCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static InventoryExportFaultCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InventoryExportFaultCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
