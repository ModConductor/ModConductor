// This is a generated file - do not edit.
//
// Generated from modconductor/v1/mod_organization.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ModFilterMode extends $pb.ProtobufEnum {
  static const ModFilterMode MOD_FILTER_MODE_UNSPECIFIED =
      ModFilterMode._(0, _omitEnumNames ? '' : 'MOD_FILTER_MODE_UNSPECIFIED');
  static const ModFilterMode MOD_FILTER_MODE_ALL =
      ModFilterMode._(1, _omitEnumNames ? '' : 'MOD_FILTER_MODE_ALL');
  static const ModFilterMode MOD_FILTER_MODE_ANY =
      ModFilterMode._(2, _omitEnumNames ? '' : 'MOD_FILTER_MODE_ANY');

  static const $core.List<ModFilterMode> values = <ModFilterMode>[
    MOD_FILTER_MODE_UNSPECIFIED,
    MOD_FILTER_MODE_ALL,
    MOD_FILTER_MODE_ANY,
  ];

  static final $core.List<ModFilterMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ModFilterMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModFilterMode._(super.value, super.name);
}

class ModQueryView extends $pb.ProtobufEnum {
  static const ModQueryView MOD_QUERY_VIEW_UNSPECIFIED =
      ModQueryView._(0, _omitEnumNames ? '' : 'MOD_QUERY_VIEW_UNSPECIFIED');
  static const ModQueryView MOD_QUERY_VIEW_FLAT =
      ModQueryView._(1, _omitEnumNames ? '' : 'MOD_QUERY_VIEW_FLAT');
  static const ModQueryView MOD_QUERY_VIEW_GROUPS =
      ModQueryView._(2, _omitEnumNames ? '' : 'MOD_QUERY_VIEW_GROUPS');

  static const $core.List<ModQueryView> values = <ModQueryView>[
    MOD_QUERY_VIEW_UNSPECIFIED,
    MOD_QUERY_VIEW_FLAT,
    MOD_QUERY_VIEW_GROUPS,
  ];

  static final $core.List<ModQueryView?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ModQueryView? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModQueryView._(super.value, super.name);
}

class ModQuerySort extends $pb.ProtobufEnum {
  static const ModQuerySort MOD_QUERY_SORT_UNSPECIFIED =
      ModQuerySort._(0, _omitEnumNames ? '' : 'MOD_QUERY_SORT_UNSPECIFIED');
  static const ModQuerySort MOD_QUERY_SORT_PRIORITY =
      ModQuerySort._(1, _omitEnumNames ? '' : 'MOD_QUERY_SORT_PRIORITY');
  static const ModQuerySort MOD_QUERY_SORT_NAME =
      ModQuerySort._(2, _omitEnumNames ? '' : 'MOD_QUERY_SORT_NAME');

  static const $core.List<ModQuerySort> values = <ModQuerySort>[
    MOD_QUERY_SORT_UNSPECIFIED,
    MOD_QUERY_SORT_PRIORITY,
    MOD_QUERY_SORT_NAME,
  ];

  static final $core.List<ModQuerySort?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ModQuerySort? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModQuerySort._(super.value, super.name);
}

class ModEnabledFilter extends $pb.ProtobufEnum {
  static const ModEnabledFilter MOD_ENABLED_FILTER_UNSPECIFIED =
      ModEnabledFilter._(
          0, _omitEnumNames ? '' : 'MOD_ENABLED_FILTER_UNSPECIFIED');
  static const ModEnabledFilter MOD_ENABLED_FILTER_YES =
      ModEnabledFilter._(1, _omitEnumNames ? '' : 'MOD_ENABLED_FILTER_YES');
  static const ModEnabledFilter MOD_ENABLED_FILTER_NO =
      ModEnabledFilter._(2, _omitEnumNames ? '' : 'MOD_ENABLED_FILTER_NO');
  static const ModEnabledFilter MOD_ENABLED_FILTER_NOT_APPLICABLE =
      ModEnabledFilter._(
          3, _omitEnumNames ? '' : 'MOD_ENABLED_FILTER_NOT_APPLICABLE');

  static const $core.List<ModEnabledFilter> values = <ModEnabledFilter>[
    MOD_ENABLED_FILTER_UNSPECIFIED,
    MOD_ENABLED_FILTER_YES,
    MOD_ENABLED_FILTER_NO,
    MOD_ENABLED_FILTER_NOT_APPLICABLE,
  ];

  static final $core.List<ModEnabledFilter?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ModEnabledFilter? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ModEnabledFilter._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
