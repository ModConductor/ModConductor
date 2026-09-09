// This is a generated file - do not edit.
//
// Generated from modconductor/v1/executables.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ExecutableRunPhase extends $pb.ProtobufEnum {
  static const ExecutableRunPhase EXECUTABLE_RUN_PHASE_UNSPECIFIED =
      ExecutableRunPhase._(
          0, _omitEnumNames ? '' : 'EXECUTABLE_RUN_PHASE_UNSPECIFIED');
  static const ExecutableRunPhase EXECUTABLE_RUN_PHASE_STARTING =
      ExecutableRunPhase._(
          1, _omitEnumNames ? '' : 'EXECUTABLE_RUN_PHASE_STARTING');
  static const ExecutableRunPhase EXECUTABLE_RUN_PHASE_RUNNING =
      ExecutableRunPhase._(
          2, _omitEnumNames ? '' : 'EXECUTABLE_RUN_PHASE_RUNNING');
  static const ExecutableRunPhase EXECUTABLE_RUN_PHASE_WAITING_FOR_CHILDREN =
      ExecutableRunPhase._(
          3, _omitEnumNames ? '' : 'EXECUTABLE_RUN_PHASE_WAITING_FOR_CHILDREN');
  static const ExecutableRunPhase EXECUTABLE_RUN_PHASE_FINISHED =
      ExecutableRunPhase._(
          4, _omitEnumNames ? '' : 'EXECUTABLE_RUN_PHASE_FINISHED');
  static const ExecutableRunPhase EXECUTABLE_RUN_PHASE_FAILED =
      ExecutableRunPhase._(
          5, _omitEnumNames ? '' : 'EXECUTABLE_RUN_PHASE_FAILED');
  static const ExecutableRunPhase EXECUTABLE_RUN_PHASE_DETACHED =
      ExecutableRunPhase._(
          6, _omitEnumNames ? '' : 'EXECUTABLE_RUN_PHASE_DETACHED');
  static const ExecutableRunPhase EXECUTABLE_RUN_PHASE_TRACKING_UNAVAILABLE =
      ExecutableRunPhase._(
          7, _omitEnumNames ? '' : 'EXECUTABLE_RUN_PHASE_TRACKING_UNAVAILABLE');

  static const $core.List<ExecutableRunPhase> values = <ExecutableRunPhase>[
    EXECUTABLE_RUN_PHASE_UNSPECIFIED,
    EXECUTABLE_RUN_PHASE_STARTING,
    EXECUTABLE_RUN_PHASE_RUNNING,
    EXECUTABLE_RUN_PHASE_WAITING_FOR_CHILDREN,
    EXECUTABLE_RUN_PHASE_FINISHED,
    EXECUTABLE_RUN_PHASE_FAILED,
    EXECUTABLE_RUN_PHASE_DETACHED,
    EXECUTABLE_RUN_PHASE_TRACKING_UNAVAILABLE,
  ];

  static final $core.List<ExecutableRunPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static ExecutableRunPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ExecutableRunPhase._(super.value, super.name);
}

class ExecutableProblemCode extends $pb.ProtobufEnum {
  static const ExecutableProblemCode EXECUTABLE_PROBLEM_CODE_UNSPECIFIED =
      ExecutableProblemCode._(
          0, _omitEnumNames ? '' : 'EXECUTABLE_PROBLEM_CODE_UNSPECIFIED');
  static const ExecutableProblemCode EXECUTABLE_PROBLEM_CODE_NOT_FOUND =
      ExecutableProblemCode._(
          1, _omitEnumNames ? '' : 'EXECUTABLE_PROBLEM_CODE_NOT_FOUND');
  static const ExecutableProblemCode EXECUTABLE_PROBLEM_CODE_STALE_REVISION =
      ExecutableProblemCode._(
          2, _omitEnumNames ? '' : 'EXECUTABLE_PROBLEM_CODE_STALE_REVISION');
  static const ExecutableProblemCode EXECUTABLE_PROBLEM_CODE_IDENTITY_CONFLICT =
      ExecutableProblemCode._(
          3, _omitEnumNames ? '' : 'EXECUTABLE_PROBLEM_CODE_IDENTITY_CONFLICT');
  static const ExecutableProblemCode EXECUTABLE_PROBLEM_CODE_CAPACITY =
      ExecutableProblemCode._(
          4, _omitEnumNames ? '' : 'EXECUTABLE_PROBLEM_CODE_CAPACITY');
  static const ExecutableProblemCode EXECUTABLE_PROBLEM_CODE_INVALID =
      ExecutableProblemCode._(
          5, _omitEnumNames ? '' : 'EXECUTABLE_PROBLEM_CODE_INVALID');
  static const ExecutableProblemCode EXECUTABLE_PROBLEM_CODE_UNAVAILABLE =
      ExecutableProblemCode._(
          6, _omitEnumNames ? '' : 'EXECUTABLE_PROBLEM_CODE_UNAVAILABLE');

  static const $core.List<ExecutableProblemCode> values =
      <ExecutableProblemCode>[
    EXECUTABLE_PROBLEM_CODE_UNSPECIFIED,
    EXECUTABLE_PROBLEM_CODE_NOT_FOUND,
    EXECUTABLE_PROBLEM_CODE_STALE_REVISION,
    EXECUTABLE_PROBLEM_CODE_IDENTITY_CONFLICT,
    EXECUTABLE_PROBLEM_CODE_CAPACITY,
    EXECUTABLE_PROBLEM_CODE_INVALID,
    EXECUTABLE_PROBLEM_CODE_UNAVAILABLE,
  ];

  static final $core.List<ExecutableProblemCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static ExecutableProblemCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ExecutableProblemCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
