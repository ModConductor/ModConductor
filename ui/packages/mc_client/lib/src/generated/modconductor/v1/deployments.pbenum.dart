// This is a generated file - do not edit.
//
// Generated from modconductor/v1/deployments.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class DeploymentPhase extends $pb.ProtobufEnum {
  static const DeploymentPhase DEPLOYMENT_PHASE_UNSPECIFIED = DeploymentPhase._(
      0, _omitEnumNames ? '' : 'DEPLOYMENT_PHASE_UNSPECIFIED');
  static const DeploymentPhase DEPLOYMENT_PHASE_PREPARING =
      DeploymentPhase._(1, _omitEnumNames ? '' : 'DEPLOYMENT_PHASE_PREPARING');
  static const DeploymentPhase DEPLOYMENT_PHASE_APPLYING =
      DeploymentPhase._(2, _omitEnumNames ? '' : 'DEPLOYMENT_PHASE_APPLYING');
  static const DeploymentPhase DEPLOYMENT_PHASE_RESTORING =
      DeploymentPhase._(3, _omitEnumNames ? '' : 'DEPLOYMENT_PHASE_RESTORING');
  static const DeploymentPhase DEPLOYMENT_PHASE_COMPLETE =
      DeploymentPhase._(4, _omitEnumNames ? '' : 'DEPLOYMENT_PHASE_COMPLETE');
  static const DeploymentPhase DEPLOYMENT_PHASE_RESTORED =
      DeploymentPhase._(5, _omitEnumNames ? '' : 'DEPLOYMENT_PHASE_RESTORED');
  static const DeploymentPhase DEPLOYMENT_PHASE_BLOCKED =
      DeploymentPhase._(6, _omitEnumNames ? '' : 'DEPLOYMENT_PHASE_BLOCKED');

  static const $core.List<DeploymentPhase> values = <DeploymentPhase>[
    DEPLOYMENT_PHASE_UNSPECIFIED,
    DEPLOYMENT_PHASE_PREPARING,
    DEPLOYMENT_PHASE_APPLYING,
    DEPLOYMENT_PHASE_RESTORING,
    DEPLOYMENT_PHASE_COMPLETE,
    DEPLOYMENT_PHASE_RESTORED,
    DEPLOYMENT_PHASE_BLOCKED,
  ];

  static final $core.List<DeploymentPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static DeploymentPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DeploymentPhase._(super.value, super.name);
}

class DeploymentFaultCode extends $pb.ProtobufEnum {
  static const DeploymentFaultCode DEPLOYMENT_FAULT_UNSPECIFIED =
      DeploymentFaultCode._(
          0, _omitEnumNames ? '' : 'DEPLOYMENT_FAULT_UNSPECIFIED');
  static const DeploymentFaultCode DEPLOYMENT_FAULT_NOT_FOUND =
      DeploymentFaultCode._(
          1, _omitEnumNames ? '' : 'DEPLOYMENT_FAULT_NOT_FOUND');
  static const DeploymentFaultCode DEPLOYMENT_FAULT_BUSY =
      DeploymentFaultCode._(2, _omitEnumNames ? '' : 'DEPLOYMENT_FAULT_BUSY');
  static const DeploymentFaultCode DEPLOYMENT_FAULT_STALE =
      DeploymentFaultCode._(3, _omitEnumNames ? '' : 'DEPLOYMENT_FAULT_STALE');
  static const DeploymentFaultCode DEPLOYMENT_FAULT_CANCELLED =
      DeploymentFaultCode._(
          4, _omitEnumNames ? '' : 'DEPLOYMENT_FAULT_CANCELLED');
  static const DeploymentFaultCode DEPLOYMENT_FAULT_BLOCKED =
      DeploymentFaultCode._(
          5, _omitEnumNames ? '' : 'DEPLOYMENT_FAULT_BLOCKED');
  static const DeploymentFaultCode DEPLOYMENT_FAULT_UNAVAILABLE =
      DeploymentFaultCode._(
          6, _omitEnumNames ? '' : 'DEPLOYMENT_FAULT_UNAVAILABLE');

  static const $core.List<DeploymentFaultCode> values = <DeploymentFaultCode>[
    DEPLOYMENT_FAULT_UNSPECIFIED,
    DEPLOYMENT_FAULT_NOT_FOUND,
    DEPLOYMENT_FAULT_BUSY,
    DEPLOYMENT_FAULT_STALE,
    DEPLOYMENT_FAULT_CANCELLED,
    DEPLOYMENT_FAULT_BLOCKED,
    DEPLOYMENT_FAULT_UNAVAILABLE,
  ];

  static final $core.List<DeploymentFaultCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static DeploymentFaultCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DeploymentFaultCode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
