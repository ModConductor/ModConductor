// This is a generated file - do not edit.
//
// Generated from modconductor/v1/skyrim_setup.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SkyrimSetupPhase extends $pb.ProtobufEnum {
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_UNSPECIFIED =
      SkyrimSetupPhase._(
          0, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_UNSPECIFIED');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_UNAVAILABLE =
      SkyrimSetupPhase._(
          1, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_UNAVAILABLE');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_NEEDS_CONSENT =
      SkyrimSetupPhase._(
          2, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_NEEDS_CONSENT');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_PREPARING_DEPLOYMENT =
      SkyrimSetupPhase._(
          3, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_PREPARING_DEPLOYMENT');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_SETTING_UP_SKSE =
      SkyrimSetupPhase._(
          4, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_SETTING_UP_SKSE');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_WAITING_FOR_SKSE =
      SkyrimSetupPhase._(
          5, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_WAITING_FOR_SKSE');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_WAITING_FOR_ENB_ARCHIVE =
      SkyrimSetupPhase._(6,
          _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_WAITING_FOR_ENB_ARCHIVE');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_SETTING_UP_ENB =
      SkyrimSetupPhase._(
          7, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_SETTING_UP_ENB');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_SETTING_UP_FNIS =
      SkyrimSetupPhase._(
          8, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_SETTING_UP_FNIS');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_FNIS_STALE =
      SkyrimSetupPhase._(
          9, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_FNIS_STALE');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_FNIS_RUNNING =
      SkyrimSetupPhase._(
          10, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_FNIS_RUNNING');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_READY =
      SkyrimSetupPhase._(11, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_READY');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_RECOVERY_REQUIRED =
      SkyrimSetupPhase._(
          12, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_RECOVERY_REQUIRED');
  static const SkyrimSetupPhase SKYRIM_SETUP_PHASE_FAILED =
      SkyrimSetupPhase._(13, _omitEnumNames ? '' : 'SKYRIM_SETUP_PHASE_FAILED');

  static const $core.List<SkyrimSetupPhase> values = <SkyrimSetupPhase>[
    SKYRIM_SETUP_PHASE_UNSPECIFIED,
    SKYRIM_SETUP_PHASE_UNAVAILABLE,
    SKYRIM_SETUP_PHASE_NEEDS_CONSENT,
    SKYRIM_SETUP_PHASE_PREPARING_DEPLOYMENT,
    SKYRIM_SETUP_PHASE_SETTING_UP_SKSE,
    SKYRIM_SETUP_PHASE_WAITING_FOR_SKSE,
    SKYRIM_SETUP_PHASE_WAITING_FOR_ENB_ARCHIVE,
    SKYRIM_SETUP_PHASE_SETTING_UP_ENB,
    SKYRIM_SETUP_PHASE_SETTING_UP_FNIS,
    SKYRIM_SETUP_PHASE_FNIS_STALE,
    SKYRIM_SETUP_PHASE_FNIS_RUNNING,
    SKYRIM_SETUP_PHASE_READY,
    SKYRIM_SETUP_PHASE_RECOVERY_REQUIRED,
    SKYRIM_SETUP_PHASE_FAILED,
  ];

  static final $core.List<SkyrimSetupPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 13);
  static SkyrimSetupPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SkyrimSetupPhase._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
