// This is a generated file - do not edit.
//
// Generated from modconductor/v1/file_plans.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PlannedFileDisposition extends $pb.ProtobufEnum {
  static const PlannedFileDisposition PLANNED_FILE_DISPOSITION_UNSPECIFIED =
      PlannedFileDisposition._(
          0, _omitEnumNames ? '' : 'PLANNED_FILE_DISPOSITION_UNSPECIFIED');
  static const PlannedFileDisposition PLANNED_FILE_DISPOSITION_PLANNED =
      PlannedFileDisposition._(
          1, _omitEnumNames ? '' : 'PLANNED_FILE_DISPOSITION_PLANNED');
  static const PlannedFileDisposition PLANNED_FILE_DISPOSITION_ABSENT =
      PlannedFileDisposition._(
          2, _omitEnumNames ? '' : 'PLANNED_FILE_DISPOSITION_ABSENT');
  static const PlannedFileDisposition PLANNED_FILE_DISPOSITION_UNRESOLVED =
      PlannedFileDisposition._(
          3, _omitEnumNames ? '' : 'PLANNED_FILE_DISPOSITION_UNRESOLVED');
  static const PlannedFileDisposition PLANNED_FILE_DISPOSITION_WRITABLE =
      PlannedFileDisposition._(
          4, _omitEnumNames ? '' : 'PLANNED_FILE_DISPOSITION_WRITABLE');

  static const $core.List<PlannedFileDisposition> values =
      <PlannedFileDisposition>[
    PLANNED_FILE_DISPOSITION_UNSPECIFIED,
    PLANNED_FILE_DISPOSITION_PLANNED,
    PLANNED_FILE_DISPOSITION_ABSENT,
    PLANNED_FILE_DISPOSITION_UNRESOLVED,
    PLANNED_FILE_DISPOSITION_WRITABLE,
  ];

  static final $core.List<PlannedFileDisposition?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static PlannedFileDisposition? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlannedFileDisposition._(super.value, super.name);
}

class FilePlanFaultCode extends $pb.ProtobufEnum {
  static const FilePlanFaultCode FILE_PLAN_FAULT_UNSPECIFIED =
      FilePlanFaultCode._(
          0, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_UNSPECIFIED');
  static const FilePlanFaultCode FILE_PLAN_FAULT_NOT_FOUND =
      FilePlanFaultCode._(1, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_NOT_FOUND');
  static const FilePlanFaultCode FILE_PLAN_FAULT_BUSY =
      FilePlanFaultCode._(2, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_BUSY');
  static const FilePlanFaultCode FILE_PLAN_FAULT_EXPIRED =
      FilePlanFaultCode._(3, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_EXPIRED');
  static const FilePlanFaultCode FILE_PLAN_FAULT_STALE =
      FilePlanFaultCode._(4, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_STALE');
  static const FilePlanFaultCode FILE_PLAN_FAULT_CONTEXT_UNAVAILABLE =
      FilePlanFaultCode._(
          5, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_CONTEXT_UNAVAILABLE');
  static const FilePlanFaultCode FILE_PLAN_FAULT_FILE_UNAVAILABLE =
      FilePlanFaultCode._(
          6, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_FILE_UNAVAILABLE');
  static const FilePlanFaultCode FILE_PLAN_FAULT_LIMIT_EXCEEDED =
      FilePlanFaultCode._(
          7, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_LIMIT_EXCEEDED');
  static const FilePlanFaultCode FILE_PLAN_FAULT_CANCELLED =
      FilePlanFaultCode._(8, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_CANCELLED');
  static const FilePlanFaultCode FILE_PLAN_FAULT_INVALID_COPY =
      FilePlanFaultCode._(
          9, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_INVALID_COPY');
  static const FilePlanFaultCode FILE_PLAN_FAULT_BLOCKED =
      FilePlanFaultCode._(10, _omitEnumNames ? '' : 'FILE_PLAN_FAULT_BLOCKED');

  static const $core.List<FilePlanFaultCode> values = <FilePlanFaultCode>[
    FILE_PLAN_FAULT_UNSPECIFIED,
    FILE_PLAN_FAULT_NOT_FOUND,
    FILE_PLAN_FAULT_BUSY,
    FILE_PLAN_FAULT_EXPIRED,
    FILE_PLAN_FAULT_STALE,
    FILE_PLAN_FAULT_CONTEXT_UNAVAILABLE,
    FILE_PLAN_FAULT_FILE_UNAVAILABLE,
    FILE_PLAN_FAULT_LIMIT_EXCEEDED,
    FILE_PLAN_FAULT_CANCELLED,
    FILE_PLAN_FAULT_INVALID_COPY,
    FILE_PLAN_FAULT_BLOCKED,
  ];

  static final $core.List<FilePlanFaultCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static FilePlanFaultCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FilePlanFaultCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
