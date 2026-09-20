// This is a generated file - do not edit.
//
// Generated from modconductor/v1/enb.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class EnbPhase extends $pb.ProtobufEnum {
  static const EnbPhase ENB_PHASE_UNSPECIFIED =
      EnbPhase._(0, _omitEnumNames ? '' : 'ENB_PHASE_UNSPECIFIED');
  static const EnbPhase ENB_PHASE_UNAVAILABLE =
      EnbPhase._(1, _omitEnumNames ? '' : 'ENB_PHASE_UNAVAILABLE');
  static const EnbPhase ENB_PHASE_BLOCKED =
      EnbPhase._(2, _omitEnumNames ? '' : 'ENB_PHASE_BLOCKED');
  static const EnbPhase ENB_PHASE_AVAILABLE =
      EnbPhase._(3, _omitEnumNames ? '' : 'ENB_PHASE_AVAILABLE');
  static const EnbPhase ENB_PHASE_WAITING_FOR_ARCHIVE =
      EnbPhase._(4, _omitEnumNames ? '' : 'ENB_PHASE_WAITING_FOR_ARCHIVE');
  static const EnbPhase ENB_PHASE_VALIDATING =
      EnbPhase._(5, _omitEnumNames ? '' : 'ENB_PHASE_VALIDATING');
  static const EnbPhase ENB_PHASE_ACQUIRING =
      EnbPhase._(6, _omitEnumNames ? '' : 'ENB_PHASE_ACQUIRING');
  static const EnbPhase ENB_PHASE_INSTALLING =
      EnbPhase._(7, _omitEnumNames ? '' : 'ENB_PHASE_INSTALLING');
  static const EnbPhase ENB_PHASE_READY =
      EnbPhase._(8, _omitEnumNames ? '' : 'ENB_PHASE_READY');
  static const EnbPhase ENB_PHASE_FAILED =
      EnbPhase._(9, _omitEnumNames ? '' : 'ENB_PHASE_FAILED');
  static const EnbPhase ENB_PHASE_CONFLICT =
      EnbPhase._(10, _omitEnumNames ? '' : 'ENB_PHASE_CONFLICT');

  static const $core.List<EnbPhase> values = <EnbPhase>[
    ENB_PHASE_UNSPECIFIED,
    ENB_PHASE_UNAVAILABLE,
    ENB_PHASE_BLOCKED,
    ENB_PHASE_AVAILABLE,
    ENB_PHASE_WAITING_FOR_ARCHIVE,
    ENB_PHASE_VALIDATING,
    ENB_PHASE_ACQUIRING,
    ENB_PHASE_INSTALLING,
    ENB_PHASE_READY,
    ENB_PHASE_FAILED,
    ENB_PHASE_CONFLICT,
  ];

  static final $core.List<EnbPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static EnbPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const EnbPhase._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
