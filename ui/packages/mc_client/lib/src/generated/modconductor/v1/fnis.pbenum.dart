// This is a generated file - do not edit.
//
// Generated from modconductor/v1/fnis.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class FnisPhase extends $pb.ProtobufEnum {
  static const FnisPhase FNIS_PHASE_UNSPECIFIED =
      FnisPhase._(0, _omitEnumNames ? '' : 'FNIS_PHASE_UNSPECIFIED');
  static const FnisPhase FNIS_PHASE_UNAVAILABLE =
      FnisPhase._(1, _omitEnumNames ? '' : 'FNIS_PHASE_UNAVAILABLE');
  static const FnisPhase FNIS_PHASE_AVAILABLE =
      FnisPhase._(2, _omitEnumNames ? '' : 'FNIS_PHASE_AVAILABLE');
  static const FnisPhase FNIS_PHASE_WAITING_FOR_NEXUS =
      FnisPhase._(3, _omitEnumNames ? '' : 'FNIS_PHASE_WAITING_FOR_NEXUS');
  static const FnisPhase FNIS_PHASE_DOWNLOADING =
      FnisPhase._(4, _omitEnumNames ? '' : 'FNIS_PHASE_DOWNLOADING');
  static const FnisPhase FNIS_PHASE_INSTALLING =
      FnisPhase._(5, _omitEnumNames ? '' : 'FNIS_PHASE_INSTALLING');
  static const FnisPhase FNIS_PHASE_READY =
      FnisPhase._(6, _omitEnumNames ? '' : 'FNIS_PHASE_READY');
  static const FnisPhase FNIS_PHASE_FAILED =
      FnisPhase._(7, _omitEnumNames ? '' : 'FNIS_PHASE_FAILED');
  static const FnisPhase FNIS_PHASE_UPDATE_AVAILABLE =
      FnisPhase._(8, _omitEnumNames ? '' : 'FNIS_PHASE_UPDATE_AVAILABLE');
  static const FnisPhase FNIS_PHASE_RECOVERY_REQUIRED =
      FnisPhase._(9, _omitEnumNames ? '' : 'FNIS_PHASE_RECOVERY_REQUIRED');
  static const FnisPhase FNIS_PHASE_SOURCE_UNAVAILABLE =
      FnisPhase._(10, _omitEnumNames ? '' : 'FNIS_PHASE_SOURCE_UNAVAILABLE');

  static const $core.List<FnisPhase> values = <FnisPhase>[
    FNIS_PHASE_UNSPECIFIED,
    FNIS_PHASE_UNAVAILABLE,
    FNIS_PHASE_AVAILABLE,
    FNIS_PHASE_WAITING_FOR_NEXUS,
    FNIS_PHASE_DOWNLOADING,
    FNIS_PHASE_INSTALLING,
    FNIS_PHASE_READY,
    FNIS_PHASE_FAILED,
    FNIS_PHASE_UPDATE_AVAILABLE,
    FNIS_PHASE_RECOVERY_REQUIRED,
    FNIS_PHASE_SOURCE_UNAVAILABLE,
  ];

  static final $core.List<FnisPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static FnisPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FnisPhase._(super.value, super.name);
}

class FnisOutputPhase extends $pb.ProtobufEnum {
  static const FnisOutputPhase FNIS_OUTPUT_PHASE_UNSPECIFIED =
      FnisOutputPhase._(
          0, _omitEnumNames ? '' : 'FNIS_OUTPUT_PHASE_UNSPECIFIED');
  static const FnisOutputPhase FNIS_OUTPUT_PHASE_UNAVAILABLE =
      FnisOutputPhase._(
          1, _omitEnumNames ? '' : 'FNIS_OUTPUT_PHASE_UNAVAILABLE');
  static const FnisOutputPhase FNIS_OUTPUT_PHASE_MISSING =
      FnisOutputPhase._(2, _omitEnumNames ? '' : 'FNIS_OUTPUT_PHASE_MISSING');
  static const FnisOutputPhase FNIS_OUTPUT_PHASE_STALE =
      FnisOutputPhase._(3, _omitEnumNames ? '' : 'FNIS_OUTPUT_PHASE_STALE');
  static const FnisOutputPhase FNIS_OUTPUT_PHASE_CURRENT =
      FnisOutputPhase._(4, _omitEnumNames ? '' : 'FNIS_OUTPUT_PHASE_CURRENT');
  static const FnisOutputPhase FNIS_OUTPUT_PHASE_RUNNING =
      FnisOutputPhase._(5, _omitEnumNames ? '' : 'FNIS_OUTPUT_PHASE_RUNNING');
  static const FnisOutputPhase FNIS_OUTPUT_PHASE_FAILED =
      FnisOutputPhase._(6, _omitEnumNames ? '' : 'FNIS_OUTPUT_PHASE_FAILED');
  static const FnisOutputPhase FNIS_OUTPUT_PHASE_CANCELLED =
      FnisOutputPhase._(7, _omitEnumNames ? '' : 'FNIS_OUTPUT_PHASE_CANCELLED');
  static const FnisOutputPhase FNIS_OUTPUT_PHASE_ABANDONED =
      FnisOutputPhase._(8, _omitEnumNames ? '' : 'FNIS_OUTPUT_PHASE_ABANDONED');

  static const $core.List<FnisOutputPhase> values = <FnisOutputPhase>[
    FNIS_OUTPUT_PHASE_UNSPECIFIED,
    FNIS_OUTPUT_PHASE_UNAVAILABLE,
    FNIS_OUTPUT_PHASE_MISSING,
    FNIS_OUTPUT_PHASE_STALE,
    FNIS_OUTPUT_PHASE_CURRENT,
    FNIS_OUTPUT_PHASE_RUNNING,
    FNIS_OUTPUT_PHASE_FAILED,
    FNIS_OUTPUT_PHASE_CANCELLED,
    FNIS_OUTPUT_PHASE_ABANDONED,
  ];

  static final $core.List<FnisOutputPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static FnisOutputPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const FnisOutputPhase._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
