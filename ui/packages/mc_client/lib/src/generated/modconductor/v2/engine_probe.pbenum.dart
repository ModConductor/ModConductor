// This is a generated file - do not edit.
//
// Generated from modconductor/v2/engine_probe.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class OperationPhase extends $pb.ProtobufEnum {
  static const OperationPhase OPERATION_PHASE_UNSPECIFIED =
      OperationPhase._(0, _omitEnumNames ? '' : 'OPERATION_PHASE_UNSPECIFIED');
  static const OperationPhase OPERATION_PHASE_RUNNING =
      OperationPhase._(1, _omitEnumNames ? '' : 'OPERATION_PHASE_RUNNING');
  static const OperationPhase OPERATION_PHASE_COMPLETED =
      OperationPhase._(2, _omitEnumNames ? '' : 'OPERATION_PHASE_COMPLETED');
  static const OperationPhase OPERATION_PHASE_CANCELLED =
      OperationPhase._(3, _omitEnumNames ? '' : 'OPERATION_PHASE_CANCELLED');
  static const OperationPhase OPERATION_PHASE_INTERRUPTED =
      OperationPhase._(4, _omitEnumNames ? '' : 'OPERATION_PHASE_INTERRUPTED');
  static const OperationPhase OPERATION_PHASE_STALE =
      OperationPhase._(5, _omitEnumNames ? '' : 'OPERATION_PHASE_STALE');

  static const $core.List<OperationPhase> values = <OperationPhase>[
    OPERATION_PHASE_UNSPECIFIED,
    OPERATION_PHASE_RUNNING,
    OPERATION_PHASE_COMPLETED,
    OPERATION_PHASE_CANCELLED,
    OPERATION_PHASE_INTERRUPTED,
    OPERATION_PHASE_STALE,
  ];

  static final $core.List<OperationPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static OperationPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OperationPhase._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
