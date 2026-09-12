// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_installation.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class InstallationPhase extends $pb.ProtobufEnum {
  static const InstallationPhase INSTALLATION_PHASE_RUNNING =
      InstallationPhase._(
          0, _omitEnumNames ? '' : 'INSTALLATION_PHASE_RUNNING');
  static const InstallationPhase INSTALLATION_PHASE_STOPPED =
      InstallationPhase._(
          1, _omitEnumNames ? '' : 'INSTALLATION_PHASE_STOPPED');
  static const InstallationPhase INSTALLATION_PHASE_COMPLETE =
      InstallationPhase._(
          2, _omitEnumNames ? '' : 'INSTALLATION_PHASE_COMPLETE');
  static const InstallationPhase INSTALLATION_PHASE_DISCARDED =
      InstallationPhase._(
          3, _omitEnumNames ? '' : 'INSTALLATION_PHASE_DISCARDED');

  static const $core.List<InstallationPhase> values = <InstallationPhase>[
    INSTALLATION_PHASE_RUNNING,
    INSTALLATION_PHASE_STOPPED,
    INSTALLATION_PHASE_COMPLETE,
    INSTALLATION_PHASE_DISCARDED,
  ];

  static final $core.List<InstallationPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static InstallationPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const InstallationPhase._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
