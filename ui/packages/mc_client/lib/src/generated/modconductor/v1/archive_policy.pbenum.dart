// This is a generated file - do not edit.
//
// Generated from modconductor/v1/archive_policy.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ArchivePolicyState extends $pb.ProtobufEnum {
  static const ArchivePolicyState ARCHIVE_POLICY_STATE_UNSPECIFIED =
      ArchivePolicyState._(
          0, _omitEnumNames ? '' : 'ARCHIVE_POLICY_STATE_UNSPECIFIED');
  static const ArchivePolicyState ARCHIVE_POLICY_STATE_ACTIVE =
      ArchivePolicyState._(
          1, _omitEnumNames ? '' : 'ARCHIVE_POLICY_STATE_ACTIVE');
  static const ArchivePolicyState ARCHIVE_POLICY_STATE_INACTIVE =
      ArchivePolicyState._(
          2, _omitEnumNames ? '' : 'ARCHIVE_POLICY_STATE_INACTIVE');
  static const ArchivePolicyState ARCHIVE_POLICY_STATE_UNAVAILABLE =
      ArchivePolicyState._(
          3, _omitEnumNames ? '' : 'ARCHIVE_POLICY_STATE_UNAVAILABLE');
  static const ArchivePolicyState ARCHIVE_POLICY_STATE_UNSUPPORTED =
      ArchivePolicyState._(
          4, _omitEnumNames ? '' : 'ARCHIVE_POLICY_STATE_UNSUPPORTED');

  static const $core.List<ArchivePolicyState> values = <ArchivePolicyState>[
    ARCHIVE_POLICY_STATE_UNSPECIFIED,
    ARCHIVE_POLICY_STATE_ACTIVE,
    ARCHIVE_POLICY_STATE_INACTIVE,
    ARCHIVE_POLICY_STATE_UNAVAILABLE,
    ARCHIVE_POLICY_STATE_UNSUPPORTED,
  ];

  static final $core.List<ArchivePolicyState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ArchivePolicyState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ArchivePolicyState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
