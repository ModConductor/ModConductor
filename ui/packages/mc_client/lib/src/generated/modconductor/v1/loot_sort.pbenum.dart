// This is a generated file - do not edit.
//
// Generated from modconductor/v1/loot_sort.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class LootProblemKind extends $pb.ProtobufEnum {
  static const LootProblemKind LOOT_PROBLEM_KIND_UNSPECIFIED =
      LootProblemKind._(
          0, _omitEnumNames ? '' : 'LOOT_PROBLEM_KIND_UNSPECIFIED');
  static const LootProblemKind LOOT_PROBLEM_KIND_BUSY =
      LootProblemKind._(1, _omitEnumNames ? '' : 'LOOT_PROBLEM_KIND_BUSY');
  static const LootProblemKind LOOT_PROBLEM_KIND_STALE =
      LootProblemKind._(2, _omitEnumNames ? '' : 'LOOT_PROBLEM_KIND_STALE');
  static const LootProblemKind LOOT_PROBLEM_KIND_CANCELLED =
      LootProblemKind._(3, _omitEnumNames ? '' : 'LOOT_PROBLEM_KIND_CANCELLED');
  static const LootProblemKind LOOT_PROBLEM_KIND_UNSUPPORTED =
      LootProblemKind._(
          4, _omitEnumNames ? '' : 'LOOT_PROBLEM_KIND_UNSUPPORTED');
  static const LootProblemKind LOOT_PROBLEM_KIND_METADATA =
      LootProblemKind._(5, _omitEnumNames ? '' : 'LOOT_PROBLEM_KIND_METADATA');
  static const LootProblemKind LOOT_PROBLEM_KIND_HELPER =
      LootProblemKind._(6, _omitEnumNames ? '' : 'LOOT_PROBLEM_KIND_HELPER');
  static const LootProblemKind LOOT_PROBLEM_KIND_RESPONSE =
      LootProblemKind._(7, _omitEnumNames ? '' : 'LOOT_PROBLEM_KIND_RESPONSE');

  static const $core.List<LootProblemKind> values = <LootProblemKind>[
    LOOT_PROBLEM_KIND_UNSPECIFIED,
    LOOT_PROBLEM_KIND_BUSY,
    LOOT_PROBLEM_KIND_STALE,
    LOOT_PROBLEM_KIND_CANCELLED,
    LOOT_PROBLEM_KIND_UNSUPPORTED,
    LOOT_PROBLEM_KIND_METADATA,
    LOOT_PROBLEM_KIND_HELPER,
    LOOT_PROBLEM_KIND_RESPONSE,
  ];

  static final $core.List<LootProblemKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static LootProblemKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LootProblemKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
