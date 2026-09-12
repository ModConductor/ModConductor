// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_updates.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ModUpdateMode extends $pb.ProtobufEnum {
  static const ModUpdateMode MOD_UPDATE_MODE_MERGE =
      ModUpdateMode._(0, _omitEnumNames ? '' : 'MOD_UPDATE_MODE_MERGE');
  static const ModUpdateMode MOD_UPDATE_MODE_REPLACE =
      ModUpdateMode._(1, _omitEnumNames ? '' : 'MOD_UPDATE_MODE_REPLACE');

  static const $core.List<ModUpdateMode> values = <ModUpdateMode>[
    MOD_UPDATE_MODE_MERGE,
    MOD_UPDATE_MODE_REPLACE,
  ];

  static final $core.List<ModUpdateMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static ModUpdateMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModUpdateMode._(super.value, super.name);
}

class ModUpdateChange extends $pb.ProtobufEnum {
  static const ModUpdateChange MOD_UPDATE_CHANGE_ADD =
      ModUpdateChange._(0, _omitEnumNames ? '' : 'MOD_UPDATE_CHANGE_ADD');
  static const ModUpdateChange MOD_UPDATE_CHANGE_REPLACE =
      ModUpdateChange._(1, _omitEnumNames ? '' : 'MOD_UPDATE_CHANGE_REPLACE');
  static const ModUpdateChange MOD_UPDATE_CHANGE_REMOVE =
      ModUpdateChange._(2, _omitEnumNames ? '' : 'MOD_UPDATE_CHANGE_REMOVE');
  static const ModUpdateChange MOD_UPDATE_CHANGE_KEEP =
      ModUpdateChange._(3, _omitEnumNames ? '' : 'MOD_UPDATE_CHANGE_KEEP');

  static const $core.List<ModUpdateChange> values = <ModUpdateChange>[
    MOD_UPDATE_CHANGE_ADD,
    MOD_UPDATE_CHANGE_REPLACE,
    MOD_UPDATE_CHANGE_REMOVE,
    MOD_UPDATE_CHANGE_KEEP,
  ];

  static final $core.List<ModUpdateChange?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ModUpdateChange? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModUpdateChange._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
