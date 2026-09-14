// This is a generated file - do not edit.
//
// Generated from modconductor/v1/diagnostics.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class DiagnosticSeverity extends $pb.ProtobufEnum {
  static const DiagnosticSeverity DIAGNOSTIC_SEVERITY_INFORMATION =
      DiagnosticSeverity._(
          0, _omitEnumNames ? '' : 'DIAGNOSTIC_SEVERITY_INFORMATION');
  static const DiagnosticSeverity DIAGNOSTIC_SEVERITY_WARNING =
      DiagnosticSeverity._(
          1, _omitEnumNames ? '' : 'DIAGNOSTIC_SEVERITY_WARNING');
  static const DiagnosticSeverity DIAGNOSTIC_SEVERITY_ERROR =
      DiagnosticSeverity._(
          2, _omitEnumNames ? '' : 'DIAGNOSTIC_SEVERITY_ERROR');

  static const $core.List<DiagnosticSeverity> values = <DiagnosticSeverity>[
    DIAGNOSTIC_SEVERITY_INFORMATION,
    DIAGNOSTIC_SEVERITY_WARNING,
    DIAGNOSTIC_SEVERITY_ERROR,
  ];

  static final $core.List<DiagnosticSeverity?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static DiagnosticSeverity? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DiagnosticSeverity._(super.value, super.name);
}

class DiagnosticFixability extends $pb.ProtobufEnum {
  static const DiagnosticFixability DIAGNOSTIC_FIXABILITY_NOT_FIXABLE =
      DiagnosticFixability._(
          0, _omitEnumNames ? '' : 'DIAGNOSTIC_FIXABILITY_NOT_FIXABLE');
  static const DiagnosticFixability DIAGNOSTIC_FIXABILITY_PREVIEW_AVAILABLE =
      DiagnosticFixability._(
          1, _omitEnumNames ? '' : 'DIAGNOSTIC_FIXABILITY_PREVIEW_AVAILABLE');
  static const DiagnosticFixability DIAGNOSTIC_FIXABILITY_READY =
      DiagnosticFixability._(
          2, _omitEnumNames ? '' : 'DIAGNOSTIC_FIXABILITY_READY');
  static const DiagnosticFixability DIAGNOSTIC_FIXABILITY_REFUSED =
      DiagnosticFixability._(
          3, _omitEnumNames ? '' : 'DIAGNOSTIC_FIXABILITY_REFUSED');

  static const $core.List<DiagnosticFixability> values = <DiagnosticFixability>[
    DIAGNOSTIC_FIXABILITY_NOT_FIXABLE,
    DIAGNOSTIC_FIXABILITY_PREVIEW_AVAILABLE,
    DIAGNOSTIC_FIXABILITY_READY,
    DIAGNOSTIC_FIXABILITY_REFUSED,
  ];

  static final $core.List<DiagnosticFixability?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static DiagnosticFixability? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DiagnosticFixability._(super.value, super.name);
}

class DiagnosticFault extends $pb.ProtobufEnum {
  static const DiagnosticFault DIAGNOSTIC_FAULT_NONE =
      DiagnosticFault._(0, _omitEnumNames ? '' : 'DIAGNOSTIC_FAULT_NONE');
  static const DiagnosticFault DIAGNOSTIC_FAULT_NOT_FOUND =
      DiagnosticFault._(1, _omitEnumNames ? '' : 'DIAGNOSTIC_FAULT_NOT_FOUND');
  static const DiagnosticFault DIAGNOSTIC_FAULT_EXPIRED =
      DiagnosticFault._(2, _omitEnumNames ? '' : 'DIAGNOSTIC_FAULT_EXPIRED');
  static const DiagnosticFault DIAGNOSTIC_FAULT_STALE =
      DiagnosticFault._(3, _omitEnumNames ? '' : 'DIAGNOSTIC_FAULT_STALE');
  static const DiagnosticFault DIAGNOSTIC_FAULT_FOREIGN =
      DiagnosticFault._(4, _omitEnumNames ? '' : 'DIAGNOSTIC_FAULT_FOREIGN');
  static const DiagnosticFault DIAGNOSTIC_FAULT_NOT_OWNED =
      DiagnosticFault._(5, _omitEnumNames ? '' : 'DIAGNOSTIC_FAULT_NOT_OWNED');
  static const DiagnosticFault DIAGNOSTIC_FAULT_BUSY =
      DiagnosticFault._(6, _omitEnumNames ? '' : 'DIAGNOSTIC_FAULT_BUSY');
  static const DiagnosticFault DIAGNOSTIC_FAULT_OVERSIZED =
      DiagnosticFault._(7, _omitEnumNames ? '' : 'DIAGNOSTIC_FAULT_OVERSIZED');
  static const DiagnosticFault DIAGNOSTIC_FAULT_UNSUPPORTED = DiagnosticFault._(
      8, _omitEnumNames ? '' : 'DIAGNOSTIC_FAULT_UNSUPPORTED');
  static const DiagnosticFault DIAGNOSTIC_FAULT_CANCELLED =
      DiagnosticFault._(9, _omitEnumNames ? '' : 'DIAGNOSTIC_FAULT_CANCELLED');

  static const $core.List<DiagnosticFault> values = <DiagnosticFault>[
    DIAGNOSTIC_FAULT_NONE,
    DIAGNOSTIC_FAULT_NOT_FOUND,
    DIAGNOSTIC_FAULT_EXPIRED,
    DIAGNOSTIC_FAULT_STALE,
    DIAGNOSTIC_FAULT_FOREIGN,
    DIAGNOSTIC_FAULT_NOT_OWNED,
    DIAGNOSTIC_FAULT_BUSY,
    DIAGNOSTIC_FAULT_OVERSIZED,
    DIAGNOSTIC_FAULT_UNSUPPORTED,
    DIAGNOSTIC_FAULT_CANCELLED,
  ];

  static final $core.List<DiagnosticFault?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static DiagnosticFault? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DiagnosticFault._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
