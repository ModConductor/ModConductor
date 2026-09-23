// This is a generated file - do not edit.
//
// Generated from modconductor/v1/plugin_order.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PluginRequiredReason extends $pb.ProtobufEnum {
  static const PluginRequiredReason PLUGIN_REQUIRED_REASON_UNSPECIFIED =
      PluginRequiredReason._(
          0, _omitEnumNames ? '' : 'PLUGIN_REQUIRED_REASON_UNSPECIFIED');
  static const PluginRequiredReason PLUGIN_REQUIRED_REASON_ENGINE =
      PluginRequiredReason._(
          1, _omitEnumNames ? '' : 'PLUGIN_REQUIRED_REASON_ENGINE');
  static const PluginRequiredReason PLUGIN_REQUIRED_REASON_SKYRIM_INI =
      PluginRequiredReason._(
          2, _omitEnumNames ? '' : 'PLUGIN_REQUIRED_REASON_SKYRIM_INI');

  static const $core.List<PluginRequiredReason> values = <PluginRequiredReason>[
    PLUGIN_REQUIRED_REASON_UNSPECIFIED,
    PLUGIN_REQUIRED_REASON_ENGINE,
    PLUGIN_REQUIRED_REASON_SKYRIM_INI,
  ];

  static final $core.List<PluginRequiredReason?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PluginRequiredReason? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PluginRequiredReason._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
