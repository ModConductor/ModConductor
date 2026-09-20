// This is a generated file - do not edit.
//
// Generated from modconductor/v1/skse.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SksePhase extends $pb.ProtobufEnum {
  static const SksePhase SKSE_PHASE_UNSPECIFIED =
      SksePhase._(0, _omitEnumNames ? '' : 'SKSE_PHASE_UNSPECIFIED');
  static const SksePhase SKSE_PHASE_UNAVAILABLE =
      SksePhase._(1, _omitEnumNames ? '' : 'SKSE_PHASE_UNAVAILABLE');
  static const SksePhase SKSE_PHASE_AVAILABLE =
      SksePhase._(2, _omitEnumNames ? '' : 'SKSE_PHASE_AVAILABLE');
  static const SksePhase SKSE_PHASE_WAITING_FOR_NEXUS =
      SksePhase._(3, _omitEnumNames ? '' : 'SKSE_PHASE_WAITING_FOR_NEXUS');
  static const SksePhase SKSE_PHASE_DOWNLOADING =
      SksePhase._(4, _omitEnumNames ? '' : 'SKSE_PHASE_DOWNLOADING');
  static const SksePhase SKSE_PHASE_INSTALLING =
      SksePhase._(5, _omitEnumNames ? '' : 'SKSE_PHASE_INSTALLING');
  static const SksePhase SKSE_PHASE_READY =
      SksePhase._(6, _omitEnumNames ? '' : 'SKSE_PHASE_READY');
  static const SksePhase SKSE_PHASE_FAILED =
      SksePhase._(7, _omitEnumNames ? '' : 'SKSE_PHASE_FAILED');
  static const SksePhase SKSE_PHASE_UPDATE_AVAILABLE =
      SksePhase._(8, _omitEnumNames ? '' : 'SKSE_PHASE_UPDATE_AVAILABLE');
  static const SksePhase SKSE_PHASE_INCOMPATIBLE =
      SksePhase._(9, _omitEnumNames ? '' : 'SKSE_PHASE_INCOMPATIBLE');
  static const SksePhase SKSE_PHASE_SOURCE_UNAVAILABLE =
      SksePhase._(10, _omitEnumNames ? '' : 'SKSE_PHASE_SOURCE_UNAVAILABLE');

  static const $core.List<SksePhase> values = <SksePhase>[
    SKSE_PHASE_UNSPECIFIED,
    SKSE_PHASE_UNAVAILABLE,
    SKSE_PHASE_AVAILABLE,
    SKSE_PHASE_WAITING_FOR_NEXUS,
    SKSE_PHASE_DOWNLOADING,
    SKSE_PHASE_INSTALLING,
    SKSE_PHASE_READY,
    SKSE_PHASE_FAILED,
    SKSE_PHASE_UPDATE_AVAILABLE,
    SKSE_PHASE_INCOMPATIBLE,
    SKSE_PHASE_SOURCE_UNAVAILABLE,
  ];

  static final $core.List<SksePhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static SksePhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SksePhase._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
